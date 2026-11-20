"""
SkinSight - Gradio Prototype dengan Model YOLO (.pt) dan LLM OpenAI (GPT-4o-mini).
"""

import os
from pathlib import Path
from PIL import Image
import cv2
import gradio as gr
from ultralytics import YOLO
from openai import OpenAI
from dotenv import load_dotenv

# ─── Load Environment & Path ──────────────────────────────────────────
BASE_DIR = Path(__file__).resolve().parent
ROOT_DIR = BASE_DIR.parent

env_paths = [
    ROOT_DIR / "backend" / ".env",
    ROOT_DIR / ".env",
    BASE_DIR / ".env"
]
for p in env_paths:
    if p.exists():
        load_dotenv(p, override=True)
        break

# Setup OpenAI API
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

# ─── Load YOLO Checkpoint (.pt) ──────────────────────────────────────
CHECKPOINT_PATH = BASE_DIR / "SkinSight_Checkpoints" / "best.pt"
if not CHECKPOINT_PATH.exists():
    CHECKPOINT_PATH = ROOT_DIR / "machine-learning" / "SkinSight_Checkpoints" / "best.pt"

print(f"Loading YOLO Checkpoint from: {CHECKPOINT_PATH}")
yolo_model = YOLO(str(CHECKPOINT_PATH))
CLASS_NAMES = yolo_model.names

LABEL_INDONESIA = {
    "Acne": "Jerawat (Acne)",
    "PIH": "Bekas Noda / Flek (PIH)",
    "DarkCircle": "Mata Panda (Dark Circle)",
    "Skin-Redness": "Kemerahan (Redness)",
    "Wrinkles": "Garis Halus (Wrinkles)",
}

def analyze_and_recommend(
    image: Image.Image,
    conf_threshold: float,
    skin_type: str,
    active_used: str,
    active_name: str,
    routine_freq: str,
    irritation: str,
    allergy_history: str,
    sunscreen_freq: str,
    doctor_care: str,
    concerns: list,
    openai_key_input: str,
):
    if image is None:
        return None, "⚠️ Harap upload atau ambil foto wajah terlebih dahulu.", ""

    # 1. Optimasi Gambar: Resize agar inferensi secepat kilat (max dimensi 1024px)
    max_dim = 1024
    w, h = image.size
    if max(w, h) > max_dim:
        scale = max_dim / max(w, h)
        image = image.resize((int(w * scale), int(h * scale)), Image.Resampling.BILINEAR)

    # 2. Jalankan Inferensi YOLO (.pt)
    results = yolo_model(image, conf=conf_threshold, verbose=False)
    first_res = results[0]

    # Render gambar beranotasi
    annotated_bgr = first_res.plot()
    annotated_rgb = cv2.cvtColor(annotated_bgr, cv2.COLOR_BGR2RGB)
    annotated_pil = Image.fromarray(annotated_rgb)

    # Hitung jumlah temuan
    detection_counts = {}
    class_confidences = {}
    total_detections = len(first_res.boxes)

    for box in first_res.boxes:
        cls_id = int(box.cls.item())
        cls_name = CLASS_NAMES.get(cls_id, f"Class {cls_id}")
        conf = float(box.conf.item())

        detection_counts[cls_name] = detection_counts.get(cls_name, 0) + 1
        if cls_name not in class_confidences or conf > class_confidences[cls_name]:
            class_confidences[cls_name] = conf

    # Ringkasan Deteksi
    summary_lines = [f"### 📊 Ringkasan Deteksi Model YOLO ({total_detections} Temuan)"]
    if total_detections == 0:
        summary_lines.append("✅ Tidak terdeteksi masalah kulit visual yang signifikan pada ambang batas saat ini.")
    else:
        for cname, count in detection_counts.items():
            label = LABEL_INDONESIA.get(cname, cname)
            highest_conf = class_confidences.get(cname, 0) * 100
            summary_lines.append(f"- **{label}**: **{count} titik** (Keyakinan: {highest_conf:.1f}%)")

    detection_summary_md = "\n".join(summary_lines)

    # 3. Siapkan Prompt LLM
    findings_str = ", ".join([f"{k}: {v} titik" for k, v in detection_counts.items()]) if detection_counts else "Tidak ada temuan visual"
    concerns_str = ", ".join(concerns) if concerns else "Semua kondisi"
    active_str = f"Ya ({active_name})" if active_used == "Ya" and active_name.strip() else active_used

    system_prompt = "Kamu adalah asisten ahli dermatologi untuk SkinSight. Berikan rekomendasi perawatan kulit personal dalam Bahasa Indonesia yang singkat, padat, dan berbasis bukti ilmiah."
    user_prompt = f"""
DATA DETEKSI ML YOLO (.pt):
- Total temuan: {total_detections}
- Rincian: {findings_str}

PROFIL PENGGUNA:
- Jenis Kulit: {skin_type}
- Bahan aktif dipakai: {active_str}
- Rutinitas 7 hari: {routine_freq}
- Keluhan (perih/gatal/ruam): {irritation}
- Riwayat alergi: {allergy_history}
- Sunscreen: {sunscreen_freq}
- Perawatan dokter: {doctor_care}
- Prioritas: {concerns_str}

FORMAT JAWABAN (Markdown rapi):
1. **Analisis Singkat Kondisi Kulit**
2. **Rutinitas Perawatan (Pagi & Malam)**: Langkah-langkah konkret & bahan aktif utama.
3. **Bahan Aktif yang Disarankan vs Dihindari**
4. **Peringatan Medis** (wajib tebalkan jika keluhan Sedang-berat atau dalam perawatan dokter)
5. **Disclaimer**: Bukan pengganti diagnosis medis resmi.
"""

    # 4. Panggil OpenAI API
    # Prioritaskan API Key dari input UI, jika kosong baca dari file .env
    active_api_key = openai_key_input.strip() if openai_key_input.strip() else os.getenv("OPENAI_API_KEY", OPENAI_API_KEY).strip()
    
    llm_output_md = ""
    if active_api_key and active_api_key.startswith("sk-"):
        try:
            client = OpenAI(api_key=active_api_key, timeout=20.0)
            response = client.chat.completions.create(
                model=OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                max_tokens=1000,
            )
            llm_output_md = response.choices[0].message.content
        except Exception as e:
            print(f"OpenAI API Error: {e}")
            llm_output_md = f"⚠️ *Error OpenAI API ({e}). Menampilkan rekomendasi cerdas lokal:*\n\n" + _offline_fallback(skin_type, detection_counts, irritation, doctor_care)
    else:
        llm_output_md = "ℹ️ *Catatan: `OPENAI_API_KEY` belum diisi di kolom input atau file `.env`. Menampilkan rekomendasi berbasis aturan lokal:*\n\n" + _offline_fallback(skin_type, detection_counts, irritation, doctor_care)

    return annotated_pil, detection_summary_md, llm_output_md


def _offline_fallback(skin_type, detection_counts, irritation, doctor_care):
    return f"""### 🌿 Rekomendasi Perawatan Personal (Mode Standar)

**Jenis Kulit**: {skin_type}
**Temuan Model**: {', '.join(detection_counts.keys()) if detection_counts else 'Kondisi kulit relatif stabil'}

#### 🌞 Rutinitas Pagi:
1. **Gentle Cleanser**: Pembersih wajah ber-pH seimbang (5.5).
2. **Hydrating Serum**: Kandungan *Hyaluronic Acid* atau *Centella Asiatica*.
3. **Lightweight Moisturizer**: Menjaga kelembapan skin barrier.
4. **Sunscreen SPF 30+ / PA++++**: Wajib digunakan setiap pagi.

#### 🌙 Rutinitas Malam:
1. **Double Cleansing**: Bersihkan sisa sunscreen & kotoran.
2. **Active Treatment**: Gunakan bahan aktif sesuai kondisi kulit (misal *Niacinamide* / *Salicylic Acid*).
3. **Barrier Moisturizer**: Mengandung *Ceramide* dan *Squalane*.

{"⚠️ **PERINGATAN MEDIS**: Anda menandai keluhan sedang-berat atau sedang dalam perawatan dokter. Segera konsultasikan ke dokter spesialis kulit." if irritation == 'Sedang-berat' or doctor_care == 'Ya' else ""}

---
*Disclaimer: Hasil analisis ini berbasis kecerdasan buatan untuk tujuan edukasi, bukan diagnosis medis formal.*
"""


# ─── Antarmuka Gradio ────────────────────────────────────────────────
with gr.Blocks(title="SkinSight - YOLO .pt & OpenAI Skincare Prototype", theme=gr.themes.Soft()) as demo:
    gr.Markdown("""
    # 🔬 SkinSight: Face Detection (.pt) & OpenAI Skincare Advisor
    Prototype penggabungan model **YOLOv8 Detection (`best.pt`)** untuk mendeteksi 5 kondisi kulit wajah dan **OpenAI (GPT-4o-mini)** untuk merancang rutinitas perawatan.
    """)

    with gr.Row():
        with gr.Column(scale=5):
            gr.Markdown("### 🔑 1. Pengaturan API Key")
            openai_key_box = gr.Textbox(
                type="password",
                placeholder="Masukkan OpenAI API Key (sk-...) atau isi di file backend/.env",
                label="OpenAI API Key"
            )

            gr.Markdown("### 📷 2. Unggah Foto Wajah")
            input_image = gr.Image(type="pil", label="Foto Wajah (Selfie / Galeri)")
            conf_slider = gr.Slider(minimum=0.1, maximum=0.9, value=0.25, step=0.05, label="Ambang Batas Keyakinan Model (Confidence Threshold)")

            gr.Markdown("### 📋 3. Kuesioner Pra-Scan (M01 - M07)")
            skin_type_input = gr.Radio(
                ["Normal", "Berminyak (Oily)", "Kering (Dry)", "Kombinasi (Combination)"],
                value="Kombinasi (Combination)",
                label="Estimasi Jenis Kulit"
            )
            with gr.Row():
                active_used_input = gr.Radio(["Tidak", "Ya", "Tidak tahu"], value="Tidak", label="M01: Sedang pakai obat/bahan aktif?")
                active_name_input = gr.Textbox(placeholder="Contoh: Salicylic Acid 2%", label="Nama Bahan/Obat (jika ada)")

            routine_freq_input = gr.Radio(["Rutin", "Kadang", "Tidak", "Tidak tahu"], value="Rutin", label="M02: Rutinitas 7 hari terakhir")
            irritation_input = gr.Radio(["Tidak", "Ringan", "Sedang-berat"], value="Tidak", label="M03: Keluhan perih / gatal / panas")
            allergy_input = gr.Radio(["Tidak", "Ya", "Tidak tahu"], value="Tidak", label="M04: Riwayat reaksi buruk produk")
            sunscreen_input = gr.Radio(["Rutin", "Kadang", "Tidak"], value="Rutin", label="M05: Frekuensi pemakaian sunscreen")
            doctor_care_input = gr.Radio(["Tidak", "Ya", "Tidak yakin"], value="Tidak", label="M06: Sedang perawatan dokter kulit?")
            concerns_input = gr.CheckboxGroup(
                ["Acne (Jerawat)", "PIH (Noda Hitam)", "DarkCircle (Mata Panda)", "Skin-Redness (Kemerahan)", "Wrinkles (Garis Halus)"],
                value=["Acne (Jerawat)"],
                label="M07: Masalah yang ingin diperhatikan"
            )

            btn_submit = gr.Button("🔍 Jalankan Deteksi (.pt) & Rekomendasi OpenAI", variant="primary", size="lg")

        with gr.Column(scale=6):
            gr.Markdown("### 🎯 4. Hasil Deteksi Visual YOLO")
            output_image = gr.Image(type="pil", label="Hasil Deteksi Bounding Box (.pt)")
            detection_summary = gr.Markdown(label="Statistik Deteksi")

            gr.Markdown("### 🤖 5. Rekomendasi Perawatan Personal (OpenAI)")
            output_llm = gr.Markdown(label="Rekomendasi Skincare")

    btn_submit.click(
        fn=analyze_and_recommend,
        inputs=[
            input_image,
            conf_slider,
            skin_type_input,
            active_used_input,
            active_name_input,
            routine_freq_input,
            irritation_input,
            allergy_input,
            sunscreen_input,
            doctor_care_input,
            concerns_input,
            openai_key_box,
        ],
        outputs=[output_image, detection_summary, output_llm],
    )

if __name__ == "__main__":
    demo.launch(server_name="127.0.0.1", server_port=7860, share=False)
