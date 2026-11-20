"""
Layanan LLM menggunakan Google Gemini API untuk menghasilkan rekomendasi
perawatan kulit yang personal berdasarkan data scan + quiz + riwayat check-in.
"""

import json
import logging
from typing import List

from google import genai
from google.genai import types as genai_types

from app.core.config import settings
from app.schemas.recommendation import (
    CheckinHistory,
    FindingEducation,
    RecommendationRequest,
    RecommendationResult,
    RoutineStep,
)

logger = logging.getLogger(__name__)

# ─── Label lokal ────────────────────────────────────────────────────
_FINDING_LABELS = {
    "Acne": "Jerawat",
    "PIH": "Noda (PIH)",
    "Dark Circle": "Lingkar mata",
    "Redness": "Kemerahan",
    "Wrinkle": "Garis halus",
}

_SKIN_TYPE_LABELS = {
    "Dry": "Kering",
    "Oily": "Berminyak",
    "Normal": "Normal",
    "Combination": "Kombinasi",
}


def _build_prompt(req: RecommendationRequest) -> str:
    """Menyusun system + user prompt dari data request."""
    scan = req.scan
    quiz = req.quiz
    lang = "Bahasa Indonesia" if req.language == "id" else "English"

    # ── Profil pengguna dari quiz ──
    quiz_lines = []
    if quiz.M01:
        quiz_lines.append(f"- Sedang menggunakan bahan aktif: {quiz.M01}")
        if quiz.regimen_name:
            quiz_lines.append(f"  Nama perawatan: {quiz.regimen_name}")
        if quiz.regimen_class:
            quiz_lines.append(f"  Untuk kondisi: {quiz.regimen_class}")
        if quiz.regimen_start:
            quiz_lines.append(f"  Sejak: {quiz.regimen_start}")
    if quiz.M02:
        quiz_lines.append(f"- Rutin perawatan 7 hari terakhir: {quiz.M02}")
    if quiz.M03:
        quiz_lines.append(f"- Keluhan saat ini (perih/gatal/panas/ruam): {quiz.M03}")
    if quiz.M04:
        quiz_lines.append(f"- Riwayat reaksi buruk terhadap produk: {quiz.M04}")
    if quiz.M05:
        quiz_lines.append(f"- Frekuensi pemakaian sunscreen: {quiz.M05}")
    if quiz.M06:
        quiz_lines.append(f"- Dalam perawatan dokter: {quiz.M06}")
    if quiz.M07:
        concerns = quiz.M07.replace("|", ", ")
        quiz_lines.append(f"- Fokus masalah yang diperhatikan: {concerns}")
    quiz_section = "\n".join(quiz_lines) if quiz_lines else "Tidak ada data kuesioner."

    # ── Temuan scan ──
    scan_lines = []
    skin_label = _SKIN_TYPE_LABELS.get(scan.skin_type, scan.skin_type)
    conf_pct = f"{scan.skin_type_confidence * 100:.0f}%" if scan.skin_type_confidence else "N/A"
    scan_lines.append(f"- Jenis kulit: {skin_label} (confidence: {conf_pct})")

    if scan.visual_findings:
        scan_lines.append(f"- Temuan visual terdeteksi: {', '.join(scan.visual_findings)}")
    else:
        scan_lines.append("- Tidak ada temuan visual yang terdeteksi.")

    for finding in scan.visual_findings:
        detail_parts = []
        if finding in scan.detection_counts:
            detail_parts.append(f"jumlah deteksi: {scan.detection_counts[finding]}")
        if finding in scan.segmentation_areas:
            area_pct = f"{scan.segmentation_areas[finding] * 100:.1f}%"
            detail_parts.append(f"luas area: {area_pct}")
        if finding in scan.class_confidences:
            conf = f"{scan.class_confidences[finding] * 100:.0f}%"
            detail_parts.append(f"confidence: {conf}")
        if detail_parts:
            label = _FINDING_LABELS.get(finding, finding)
            scan_lines.append(f"  · {label} ({finding}): {', '.join(detail_parts)}")
    scan_section = "\n".join(scan_lines)

    # ── Riwayat check-in ──
    checkin_section = "Belum ada riwayat check-in."
    if req.checkin_history:
        checkin_lines = []
        for ci in req.checkin_history:
            checkin_lines.append(f"  Minggu ke-{ci.week}:")
            for cls, status in ci.per_class.items():
                checkin_lines.append(f"    · {cls}: {status}")
            if ci.treatment:
                checkin_lines.append(f"    · Perawatan: {ci.treatment}")
            if ci.irritation:
                checkin_lines.append(f"    · Iritasi: {ci.irritation}")
        checkin_section = "\n".join(checkin_lines)

    # ── Medical flags ──
    medical_flags = []
    if quiz.M03 and quiz.M03.lower() in ("sedang-berat",):
        medical_flags.append("Pengguna melaporkan keluhan sedang-berat (perih/gatal/panas/ruam).")
    if quiz.M06 and quiz.M06.lower() in ("ya",):
        medical_flags.append("Pengguna sedang dalam perawatan dokter.")
    medical_section = "\n".join(f"⚠️ {f}" for f in medical_flags) if medical_flags else ""

    prompt = f"""Kamu adalah asisten perawatan kulit (skincare advisor) berbasis bukti ilmiah.
Tugasmu: memberikan edukasi dan rekomendasi perawatan kulit yang personal berdasarkan data berikut.

═══════════════════════════════════════
PROFIL PENGGUNA (dari kuesioner):
{quiz_section}

═══════════════════════════════════════
HASIL SCAN AI (deteksi on-device):
{scan_section}

═══════════════════════════════════════
RIWAYAT CHECK-IN MINGGUAN:
{checkin_section}
{'═══════════════════════════════════════' if medical_section else ''}
{medical_section}

═══════════════════════════════════════
INSTRUKSI:
1. Berikan ringkasan kondisi kulit dalam 2–3 kalimat.
2. Untuk SETIAP temuan visual yang terdeteksi, berikan:
   - Penjelasan apa itu dan mengapa terdeteksi
   - 2–4 langkah perawatan spesifik yang disesuaikan dengan profil pengguna
   - Estimasi timeline evaluasi
3. Susun rutinitas perawatan harian (pagi & malam) dengan langkah-langkah konkret.
4. Sebutkan bahan aktif yang disarankan DAN yang harus dihindari.
5. Berikan 2–3 tips gaya hidup yang relevan.
6. {"WAJIB berikan peringatan medis yang tegas untuk berkonsultasi ke dokter/dermatologis karena ada flag medis di atas." if medical_flags else "Tambahkan disclaimer bahwa ini bukan diagnosis medis."}
7. Pertimbangkan jawaban kuesioner: jika pengguna sudah memakai perawatan tertentu, sesuaikan saran; jika ada riwayat reaksi buruk, hindari bahan yang umum menyebabkan iritasi.
8. Jika ada riwayat check-in, sesuaikan saran dengan tren perubahan.

BAHASA OUTPUT: {lang}

FORMAT OUTPUT: Jawab HANYA dalam JSON valid (tanpa markdown fence) dengan struktur berikut:
{{
  "summary": "string",
  "skin_type_note": "string",
  "findings_education": [
    {{
      "finding": "nama kelas (e.g. Acne)",
      "finding_label": "label lokal (e.g. Jerawat)",
      "explanation": "string",
      "care_tips": ["string", ...],
      "timeline": "string"
    }}
  ],
  "routine": [
    {{
      "order": 1,
      "step_name": "e.g. Cleanser",
      "description": "string",
      "ingredient_highlights": ["string", ...],
      "when": "pagi | malam | pagi & malam"
    }}
  ],
  "recommended_ingredients": ["string", ...],
  "avoid_ingredients": ["string", ...],
  "lifestyle_tips": ["string", ...],
  "medical_warning": "string atau null",
  "disclaimer": "string"
}}"""
    return prompt


def _parse_llm_response(text: str) -> RecommendationResult:
    """Parse respons teks dari LLM menjadi RecommendationResult terstruktur."""
    # Bersihkan markdown fence jika ada
    cleaned = text.strip()
    if cleaned.startswith("```"):
        # Hapus baris pertama (```json) dan terakhir (```)
        lines = cleaned.split("\n")
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        cleaned = "\n".join(lines)

    data = json.loads(cleaned)

    findings_edu = []
    for f in data.get("findings_education", []):
        findings_edu.append(FindingEducation(
            finding=f.get("finding", ""),
            finding_label=f.get("finding_label", ""),
            explanation=f.get("explanation", ""),
            care_tips=f.get("care_tips", []),
            timeline=f.get("timeline", ""),
        ))

    routine = []
    for r in data.get("routine", []):
        routine.append(RoutineStep(
            order=r.get("order", 0),
            step_name=r.get("step_name", ""),
            description=r.get("description", ""),
            ingredient_highlights=r.get("ingredient_highlights", []),
            when=r.get("when", "pagi & malam"),
        ))

    return RecommendationResult(
        summary=data.get("summary", ""),
        skin_type_note=data.get("skin_type_note", ""),
        findings_education=findings_edu,
        routine=routine,
        recommended_ingredients=data.get("recommended_ingredients", []),
        avoid_ingredients=data.get("avoid_ingredients", []),
        lifestyle_tips=data.get("lifestyle_tips", []),
        medical_warning=data.get("medical_warning"),
        disclaimer=data.get(
            "disclaimer",
            "Hasil ini bukan diagnosis medis. Konsultasikan dengan dokter atau dermatologis untuk penanganan klinis.",
        ),
    )


class LLMService:
    """Wrapper service untuk Google Gemini API (SDK google-genai)."""

    def __init__(self):
        self._client = None
        self._configure()

    def _configure(self):
        """Konfigurasi Gemini API client."""
        api_key = (settings.GEMINI_API_KEY or "").strip()
        if not api_key or api_key.startswith("YOUR_"):
            logger.warning("GEMINI_API_KEY tidak dikonfigurasi. LLM service akan menggunakan fallback.")
            self._client = None
            return

        self._client = genai.Client(api_key=api_key)

    async def generate_recommendation(
        self, request: RecommendationRequest
    ) -> RecommendationResult:
        """Hasilkan rekomendasi perawatan kulit menggunakan Gemini."""
        if self._client is None:
            logger.info("LLM client tidak tersedia, menggunakan fallback statis.")
            return self._fallback_recommendation(request)

        prompt = _build_prompt(request)

        try:
            response = await self._client.aio.models.generate_content(
                model=settings.GEMINI_MODEL,
                contents=prompt,
                config=genai_types.GenerateContentConfig(
                    temperature=0.7,
                    top_p=0.9,
                    top_k=40,
                    max_output_tokens=4096,
                    response_mime_type="application/json",
                ),
            )

            text = getattr(response, "text", None)
            if not text:
                logger.warning("Gemini mengembalikan respons kosong.")
                return self._fallback_recommendation(request)

            return _parse_llm_response(text)

        except json.JSONDecodeError as e:
            logger.error(f"Gagal parse JSON dari Gemini: {e}")
            return self._fallback_recommendation(request)
        except Exception as e:
            logger.error(f"Error memanggil Gemini API: {e}")
            return self._fallback_recommendation(request)

    def _fallback_recommendation(
        self, request: RecommendationRequest
    ) -> RecommendationResult:
        """Fallback statis jika Gemini tidak tersedia."""
        scan = request.scan
        quiz = request.quiz

        _STATIC_EDUCATION = {
            "Acne": (
                "Jerawat",
                "Bersihkan wajah dengan lembut. Benzoyl peroxide, retinoid, dan azelaic acid merupakan contoh bahan yang punya dasar bukti, tetapi pilihan bergantung pada toleransi dan kondisi kulit.",
                ["Gunakan pembersih lembut 2× sehari", "Hindari menyentuh wajah", "Pertimbangkan produk dengan salicylic acid atau benzoyl peroxide", "Jangan memencet jerawat"],
                "Efek sebagian terapi mulai dinilai setelah 6–8 minggu; evaluasi sekitar 12 minggu.",
            ),
            "PIH": (
                "Noda (PIH)",
                "Prioritaskan perlindungan UV dan pencegahan peradangan baru. Azelaic acid termasuk bahan yang diteliti untuk hiperpigmentasi.",
                ["Gunakan sunscreen SPF 30+ setiap hari", "Pertimbangkan produk dengan niacinamide atau vitamin C", "Hindari memencet atau menggaruk area yang meradang"],
                "Pemudaran noda dapat memerlukan berbulan-bulan.",
            ),
            "Dark Circle": (
                "Lingkar mata",
                "Lingkar gelap bisa berkaitan dengan pigmen, pembuluh darah, atau struktur wajah. Jangan mencoba bahan aktif dekat mata tanpa mempertimbangkan risikonya.",
                ["Tidur cukup 7–9 jam", "Gunakan eye cream dengan kafein atau peptida", "Kompres dingin dapat membantu sementara"],
                "Tidak ada estimasi durasi pemulihan yang universal.",
            ),
            "Redness": (
                "Kemerahan",
                "Gunakan perawatan lembut, perhatikan pemicu iritasi, dan gunakan perlindungan matahari yang sesuai.",
                ["Hindari produk dengan alkohol atau parfum", "Gunakan pelembap dengan ceramide", "Pertimbangkan produk dengan centella asiatica"],
                "Kemerahan pada foto tidak otomatis berarti rosacea.",
            ),
            "Wrinkle": (
                "Garis halus",
                "Perlindungan UV penting. Retinoid mempunyai penelitian pendukung, tetapi perlu memperhatikan iritasi serta batas keamanannya.",
                ["Gunakan sunscreen setiap hari", "Pertimbangkan retinol dengan konsentrasi rendah", "Jaga hidrasi kulit"],
                "Sebagian penelitian menilai perubahan setelah 3–6 bulan atau lebih.",
            ),
        }

        findings_edu = []
        for finding in scan.visual_findings:
            if finding in _STATIC_EDUCATION:
                label, explanation, tips, timeline = _STATIC_EDUCATION[finding]
                findings_edu.append(FindingEducation(
                    finding=finding,
                    finding_label=label,
                    explanation=explanation,
                    care_tips=tips,
                    timeline=timeline,
                ))

        skin_label = _SKIN_TYPE_LABELS.get(scan.skin_type, scan.skin_type)

        medical_warning = None
        if quiz.M03 and quiz.M03.lower() == "sedang-berat":
            medical_warning = "Anda melaporkan keluhan sedang–berat. Sebaiknya konsultasikan ke dermatologis sebelum mencoba bahan aktif baru."
        elif quiz.M06 and quiz.M06.lower() == "ya":
            medical_warning = "Anda sedang dalam perawatan dokter. Utamakan arahan tenaga kesehatan Anda."

        return RecommendationResult(
            summary=f"Kulit Anda terdeteksi bertipe {skin_label} dengan {len(scan.visual_findings)} temuan visual. Rekomendasi berikut disusun berdasarkan jawaban kuesioner dan hasil scan AI.",
            skin_type_note=f"Kulit {skin_label} — sesuaikan rutinitas dengan kebutuhan spesifik tipe kulit ini.",
            findings_education=findings_edu,
            routine=[
                RoutineStep(order=1, step_name="Cleanser", description="Bersihkan wajah dengan pembersih lembut, pijat 30–60 detik.", ingredient_highlights=["Ceramide", "Glycerin"], when="pagi & malam"),
                RoutineStep(order=2, step_name="Toner (opsional)", description="Gunakan toner hydrating untuk menyeimbangkan pH kulit.", ingredient_highlights=["Hyaluronic Acid", "Centella Asiatica"], when="pagi & malam"),
                RoutineStep(order=3, step_name="Serum / Treatment", description="Aplikasikan serum sesuai masalah kulit utama.", ingredient_highlights=["Niacinamide", "Vitamin C"], when="pagi & malam"),
                RoutineStep(order=4, step_name="Pelembap", description="Kunci kelembapan dengan moisturizer yang sesuai tipe kulit.", ingredient_highlights=["Ceramide", "Squalane"], when="pagi & malam"),
                RoutineStep(order=5, step_name="Sunscreen", description="Gunakan sunscreen SPF 30+ sebagai langkah terakhir di pagi hari.", ingredient_highlights=["Zinc Oxide", "Titanium Dioxide"], when="pagi"),
            ],
            recommended_ingredients=["Niacinamide", "Hyaluronic Acid", "Ceramide", "Centella Asiatica"],
            avoid_ingredients=["Alcohol Denat konsentrasi tinggi", "Scrub kasar", "Parfum kuat"],
            lifestyle_tips=[
                "Minum air putih minimal 2 liter per hari.",
                "Tidur 7–9 jam untuk regenerasi kulit optimal.",
                "Ganti sarung bantal minimal sekali seminggu.",
            ],
            medical_warning=medical_warning,
        )


# Singleton instance
llm_service = LLMService()
