import 'package:flutter/material.dart';
import '../data/skin_journey_store.dart';
import '../theme/skin_theme.dart';
import '../widgets/skin_page_header.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_ui.dart';
import 'skin_initial_scan_page.dart';
import 'skin_progress_page.dart';

/// Kuesioner pra-scan M01–M07. Semua pertanyaan berada dalam satu halaman.
class SkinQuizPage extends StatefulWidget {
  final bool enableCamera;
  const SkinQuizPage({super.key, this.enableCamera = true});

  @override
  State<SkinQuizPage> createState() => _SkinQuizPageState();
}

class _SkinQuizPageState extends State<SkinQuizPage> {
  static const questions = <(String, String, List<String>)>[
    (
      'M01',
      'Sedang menggunakan bahan aktif atau obat perawatan wajah?',
      ['Ya', 'Tidak', 'Tidak tahu']
    ),
    (
      'M02',
      'Seberapa rutin kamu memakai perawatan dalam 7 hari terakhir?',
      ['Rutin', 'Kadang', 'Tidak', 'Tidak memakai', 'Tidak tahu']
    ),
    (
      'M03',
      'Apakah wajah sedang perih, gatal, panas, ruam, atau mengelupas?',
      ['Tidak', 'Ringan', 'Sedang-berat', 'Tidak yakin']
    ),
    (
      'M04',
      'Pernah ada produk atau bahan yang menimbulkan reaksi buruk?',
      ['Tidak', 'Ya', 'Tidak tahu']
    ),
    (
      'M05',
      'Seberapa sering memakai sunscreen saat terpapar matahari?',
      ['Rutin', 'Kadang', 'Tidak', 'Tidak tahu']
    ),
    (
      'M06',
      'Sedang dalam perawatan dokter untuk masalah kulit ini?',
      ['Ya', 'Tidak', 'Tidak yakin']
    ),
    (
      'M07',
      'Masalah mana yang ingin kamu perhatikan? (Boleh lebih dari satu)',
      ['Acne', 'PIH', 'Dark Circle', 'Redness', 'Wrinkle', 'Belum yakin']
    ),
  ];

  final Map<String, String> _answers = {...SkinJourneyStore.instance.answers};
  final TextEditingController _regimenName = TextEditingController();
  final Set<String> _concerns = {};
  final List<GlobalKey> _questionKeys = List.generate(7, (_) => GlobalKey());
  String? _regimenClass;
  DateTime? _regimenStart;
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    _regimenName.text = _answers['regimen_name'] ?? '';
    _regimenClass = _answers['regimen_class'];
    _regimenStart = DateTime.tryParse(_answers['regimen_start'] ?? '');
    _concerns.addAll(
      (_answers['M07'] ?? '').split('|').where((answer) => answer.isNotEmpty),
    );
    _consent = SkinJourneyStore.instance.consent == true;
  }

  @override
  void dispose() {
    _regimenName.dispose();
    super.dispose();
  }

  void _choose(String id, String answer) {
    setState(() {
      if (id != 'M07') {
        _answers[id] = answer;
        return;
      }
      if (answer == 'Belum yakin') {
        _concerns
          ..clear()
          ..add(answer);
      } else {
        _concerns.remove('Belum yakin');
        if (!_concerns.add(answer)) _concerns.remove(answer);
      }
    });
  }

  void _showMissing(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Jawab pertanyaan ${index + 1} terlebih dahulu.')),
    );
    final target = _questionKeys[index].currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
  }

  Future<void> _submit() async {
    for (var i = 0; i < questions.length; i++) {
      final id = questions[i].$1;
      if (id == 'M07'
          ? _concerns.isEmpty
          : (_answers[id] == null || _answers[id]!.isEmpty)) {
        _showMissing(i);
        return;
      }
    }
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Setujui pemrosesan foto untuk melanjutkan scan.'),
      ));
      return;
    }

    _answers['M07'] = _concerns.join('|');
    if (_answers['M01'] == 'Ya') {
      _answers['regimen_name'] = _regimenName.text.trim();
      if (_regimenClass != null) {
        _answers['regimen_class'] = _regimenClass!;
      } else {
        _answers.remove('regimen_class');
      }
      if (_regimenStart != null) {
        _answers['regimen_start'] = _regimenStart!.toIso8601String();
      } else {
        _answers.remove('regimen_start');
      }
    } else {
      // Jangan gunakan perawatan lama bila pengguna sekarang menjawab tidak.
      _answers.remove('regimen_name');
      _answers.remove('regimen_class');
      _answers.remove('regimen_start');
    }

    SkinJourneyStore.instance
        .saveQuestionnaire(_answers, photoConsent: _consent);
    if (_answers['M03'] == 'Sedang-berat') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Jika iritasi cukup berat, periksakan ke tenaga kesehatan sebelum mencoba bahan aktif baru.'),
      ));
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SkinInitialScanPage(
          enableCamera: widget.enableCamera,
          autoStartScan: true,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SkinProgressPage()),
    );
  }

  int get _answeredCount => questions.where((q) {
        final id = q.$1;
        return id == 'M07'
            ? _concerns.isNotEmpty
            : (_answers[id]?.isNotEmpty ?? false);
      }).length;

  Widget _option(String id, String answer) {
    final selected =
        id == 'M07' ? _concerns.contains(answer) : _answers[id] == answer;
    return _OptionPill(
      label: answer,
      selected: selected,
      multi: id == 'M07',
      onTap: () => _choose(id, answer),
    );
  }

  Widget _question(int index) {
    final q = questions[index];
    final answered =
        q.$1 == 'M07' ? _concerns.isNotEmpty : _answers[q.$1] != null;
    return Container(
      key: _questionKeys[index],
      margin: const EdgeInsets.only(bottom: 14),
      child: SkinReveal.staggered(
        index: index,
        child: AnimatedContainer(
          duration: SkinTokens.medium,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
            border: Border.all(
              color: answered ? SkinTokens.mintStrong : SkinTokens.border,
            ),
            boxShadow: SkinTokens.shadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: SkinTokens.medium,
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: answered ? SkinTokens.brandGradient : null,
                      color: answered ? null : SkinTokens.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: answered
                        ? const Icon(Icons.check_rounded,
                            size: 17, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: SkinTokens.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PERTANYAAN ${index + 1}',
                      style: SkinTokens.eyebrow.copyWith(
                        color: answered ? SkinTokens.primary : SkinTokens.muted,
                      ),
                    ),
                  ),
                  if (q.$1 == 'M07')
                    const SkinPill(
                      label: 'Pilih beberapa',
                      tone: SkinTone.info,
                      dense: true,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                q.$2,
                style: const TextStyle(
                  color: SkinTokens.ink,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: q.$3.map((answer) => _option(q.$1, answer)).toList(),
              ),
              if (q.$1 == 'M01' && _answers['M01'] == 'Ya') ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                TextField(
                  controller: _regimenName,
                  decoration: const InputDecoration(
                    labelText: 'Nama perawatan (opsional)',
                    hintText: 'Produk atau bahan yang sedang dipakai',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _regimenClass,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  decoration: const InputDecoration(
                    labelText: 'Perawatan ini untuk kondisi apa? (opsional)',
                  ),
                  items: SkinJourneyStore.visualClasses
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _regimenClass = value),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2010),
                      lastDate: DateTime.now(),
                      initialDate: _regimenStart ?? DateTime.now(),
                    );
                    if (picked != null) setState(() => _regimenStart = picked);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_regimenStart == null
                      ? 'Sejak kapan digunakan? (opsional)'
                      : 'Sejak ${SkinFormat.date(_regimenStart!)}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answered = _answeredCount;
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
          child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
            child: Column(
              children: [
                SkinPageHeader(
                  title: 'Kuesioner Awal',
                  subtitle: '${questions.length} pertanyaan · sekitar 1 menit',
                  backKey: const Key('quiz-back'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$answered dari ${questions.length} terjawab',
                              style: const TextStyle(
                                color: SkinTokens.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${(answered / questions.length * 100).round()}%',
                            style: const TextStyle(
                              color: SkinTokens.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SkinProgressBar(
                        value: answered / questions.length,
                        gradient: SkinTokens.brandGradient,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jawab tujuh pertanyaan berikut sesuai kondisimu.',
                          style: SkinTokens.caption,
                        ),
                        const SizedBox(height: 14),
                        ...List.generate(questions.length, _question),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: SkinTokens.medium,
                          padding: const EdgeInsets.fromLTRB(6, 6, 14, 8),
                          decoration: BoxDecoration(
                            color: _consent
                                ? SkinTokens.mint
                                : SkinTokens.peachSoft,
                            borderRadius:
                                BorderRadius.circular(SkinTokens.radiusLg),
                            border: Border.all(
                              color: _consent
                                  ? SkinTokens.mintStrong
                                  : const Color(0xFFF0DCD2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Material(
                                type: MaterialType.transparency,
                                child: CheckboxListTile(
                                  value: _consent,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (value) =>
                                      setState(() => _consent = value ?? false),
                                  title: const Text(
                                    'Saya mengizinkan foto diproses untuk analisis dan pemantauan.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                      color: SkinTokens.ink,
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.lock_outline_rounded,
                                        size: 14, color: SkinTokens.muted),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Foto hanya dipakai untuk hasil dan pemantauan milikmu.',
                                        style: TextStyle(
                                          color: SkinTokens.muted,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SkinBottomBar(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _consent ? _submit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 20),
                          SizedBox(width: 8),
                          Flexible(child: Text('Lanjut ke Scan')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: SkinTokens.fast,
        decoration: BoxDecoration(
          color: selected ? SkinTokens.mint : SkinTokens.surfaceAlt,
          borderRadius: radius,
          border: Border.all(
            color: selected ? SkinTokens.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: SkinTokens.fast,
                    child: Icon(
                      selected
                          ? (multi
                              ? Icons.check_box_rounded
                              : Icons.radio_button_checked_rounded)
                          : (multi
                              ? Icons.check_box_outline_blank_rounded
                              : Icons.radio_button_unchecked_rounded),
                      key: ValueKey(selected),
                      size: 18,
                      color: selected ? SkinTokens.primary : SkinTokens.subtle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color:
                            selected ? SkinTokens.primaryDark : SkinTokens.ink,
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
