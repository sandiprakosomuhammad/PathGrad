import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../services/history_repository.dart';

class PredictionScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  final ScreeningRecord? initialRecord;

  const PredictionScreen({
    super.key,
    this.onBackToDashboard,
    this.initialRecord,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _editingKodeMhs;

  // ── Controllers (Identitas NIM & 7 Parameter Akademik) ─────────────────
  late final TextEditingController _nimController;
  late final TextEditingController _ipsSem1Controller;
  late final TextEditingController _mkDiambilSem1Controller;
  late final TextEditingController _mkLulusSem1Controller;
  late final TextEditingController _ipsSem2Controller;
  late final TextEditingController _mkDiambilSem2Controller;
  late final TextEditingController _mkLulusSem2Controller;
  int _uktLancar = 1; // 0 = Menunggak, 1 = Lancar

  bool _isLoading = false;
  PredictionResponse? _predictionResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecord != null) {
      final rec = widget.initialRecord!;
      _editingKodeMhs = rec.kodeMhs;
      _nimController = TextEditingController(text: rec.nim != '-' ? rec.nim : '');
      _ipsSem1Controller = TextEditingController(text: rec.ipsSem1.toStringAsFixed(2));
      _mkDiambilSem1Controller = TextEditingController(text: rec.matkulDiambilSem1.toString());
      _mkLulusSem1Controller = TextEditingController(text: rec.matkulLulusSem1.toString());
      _ipsSem2Controller = TextEditingController(text: rec.ipsSem2.toStringAsFixed(2));
      _mkDiambilSem2Controller = TextEditingController(text: rec.matkulDiambilSem2.toString());
      _mkLulusSem2Controller = TextEditingController(text: rec.matkulLulusSem2.toString());
      _uktLancar = rec.uktLancar;
    } else {
      _nimController = TextEditingController();
      _ipsSem1Controller = TextEditingController(text: '2.50');
      _mkDiambilSem1Controller = TextEditingController(text: '6');
      _mkLulusSem1Controller = TextEditingController(text: '4');
      _ipsSem2Controller = TextEditingController(text: '2.00');
      _mkDiambilSem2Controller = TextEditingController(text: '6');
      _mkLulusSem2Controller = TextEditingController(text: '3');
      _uktLancar = 1;
    }

    _ipsSem1Controller.addListener(_onInputChanged);
    _ipsSem2Controller.addListener(_onInputChanged);
    _mkDiambilSem1Controller.addListener(_onInputChanged);
    _mkLulusSem1Controller.addListener(_onInputChanged);
    _mkDiambilSem2Controller.addListener(_onInputChanged);
    _mkLulusSem2Controller.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ipsSem1Controller.removeListener(_onInputChanged);
    _ipsSem2Controller.removeListener(_onInputChanged);
    _mkDiambilSem1Controller.removeListener(_onInputChanged);
    _mkLulusSem1Controller.removeListener(_onInputChanged);
    _mkDiambilSem2Controller.removeListener(_onInputChanged);
    _mkLulusSem2Controller.removeListener(_onInputChanged);

    _nimController.dispose();
    _ipsSem1Controller.dispose();
    _mkDiambilSem1Controller.dispose();
    _mkLulusSem1Controller.dispose();
    _ipsSem2Controller.dispose();
    _mkDiambilSem2Controller.dispose();
    _mkLulusSem2Controller.dispose();
    super.dispose();
  }

  // ── Getter Real-Time 6 Fitur Rekayasa ───────────────────────────────────
  double get _liveIps1 => double.tryParse(_ipsSem1Controller.text.trim()) ?? 0.0;
  double get _liveIps2 => double.tryParse(_ipsSem2Controller.text.trim()) ?? 0.0;
  int get _liveAmbil1 => int.tryParse(_mkDiambilSem1Controller.text.trim()) ?? 0;
  int get _liveLulus1 => int.tryParse(_mkLulusSem1Controller.text.trim()) ?? 0;
  int get _liveAmbil2 => int.tryParse(_mkDiambilSem2Controller.text.trim()) ?? 0;
  int get _liveLulus2 => int.tryParse(_mkLulusSem2Controller.text.trim()) ?? 0;

  double get _liveAvgIps => (_liveIps1 + _liveIps2) / 2.0;
  double get _liveTrenIps => _liveIps2 - _liveIps1;
  int get _liveGagal1 => _liveAmbil1 >= _liveLulus1 ? _liveAmbil1 - _liveLulus1 : 0;
  int get _liveGagal2 => _liveAmbil2 >= _liveLulus2 ? _liveAmbil2 - _liveLulus2 : 0;
  int get _liveRasio1 => _liveAmbil1 > 0 ? ((_liveLulus1 / _liveAmbil1) * 100).round() : 0;
  int get _liveRasio2 => _liveAmbil2 > 0 ? ((_liveLulus2 / _liveAmbil2) * 100).round() : 0;

  void _applyPreset({
    required double ips1,
    required int ambil1,
    required int lulus1,
    required double ips2,
    required int ambil2,
    required int lulus2,
    required int ukt,
  }) {
    setState(() {
      _ipsSem1Controller.text = ips1.toStringAsFixed(2);
      _mkDiambilSem1Controller.text = ambil1.toString();
      _mkLulusSem1Controller.text = lulus1.toString();
      _ipsSem2Controller.text = ips2.toStringAsFixed(2);
      _mkDiambilSem2Controller.text = ambil2.toString();
      _mkLulusSem2Controller.text = lulus2.toString();
      _uktLancar = ukt;
      _predictionResult = null;
    });
  }

  // ── Validasi Helper ─────────────────────────────────────────────────────
  String? _validateIps(String? val) {
    final n = double.tryParse(val ?? '');
    if (n == null || n < 0.0 || n > 4.0) return 'Nilai IPS: 0.00 – 4.00';
    return null;
  }

  String? _validateMatkul(String? val, {String label = 'Mata kuliah', int min = 1}) {
    final n = int.tryParse(val ?? '');
    if (n == null || n < min) return '$label minimal $min';
    return null;
  }

  // ── Submit & Inferensi ──────────────────────────────────────────────────
  Future<void> _submitPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    final mkDiambilSem1 = int.parse(_mkDiambilSem1Controller.text.trim());
    final mkLulusSem1   = int.parse(_mkLulusSem1Controller.text.trim());
    final mkDiambilSem2 = int.parse(_mkDiambilSem2Controller.text.trim());
    final mkLulusSem2   = int.parse(_mkLulusSem2Controller.text.trim());

    // Validasi lintas-field di sisi Flutter sebelum kirim ke API
    if (mkLulusSem1 > mkDiambilSem1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mata kuliah lulus Sem 1 tidak boleh melebihi yang diambil.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (mkLulusSem2 > mkDiambilSem2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mata kuliah lulus Sem 2 tidak boleh melebihi yang diambil.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      final inputNim = _nimController.text.trim();
      final req = StudentPredictionRequest(
        kodeAnonim:          _editingKodeMhs ?? 'MHS-ANON',
        nim:                 inputNim.isNotEmpty ? inputNim : null,
        simpanRiwayat:      true,
        ipsSem1:             double.parse(_ipsSem1Controller.text.trim()),
        matkulDiambilSem1:   mkDiambilSem1,
        matkulLulusSem1:     mkLulusSem1,
        ipsSem2:             double.parse(_ipsSem2Controller.text.trim()),
        matkulDiambilSem2:   mkDiambilSem2,
        matkulLulusSem2:     mkLulusSem2,
        uktLancar:           _uktLancar,
      );

      final result = await ApiService.predict(req);

      // Refresh data di HistoryRepository agar langsung tersinkron dari SQLite
      await HistoryRepository().refreshFromApi();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingKodeMhs != null
                  ? 'Data ${result.kodeMhs} berhasil diperbarui di database.'
                  : 'Hasil skrining ${result.kodeMhs} berhasil disimpan.',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }

      setState(() => _predictionResult = result);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Gagal Terhubung / Error'),
            ]),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helper UI: UKT Choice Button ────────────────────────────────────────
  Widget _buildUktChoice({
    required String label,
    required int value,
    required Color activeColor,
  }) {
    final isSelected = _uktLancar == value;
    return InkWell(
      onTap: () => setState(() => _uktLancar = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeStatItem({
    required String label,
    required String value,
    required String sublabel,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Data Prediksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_editingKodeMhs != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: Color(0xFF1D4ED8), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Evaluasi / Perbarui Data: $_editingKodeMhs',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                            const Text(
                              'Data baru akan memperbarui data mahasiswa ini di database SQLite.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _editingKodeMhs = null;
                            _nimController.clear();
                          });
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // ── Banner Informasi 13 Fitur Otomatis ──
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Transformasi Otomatis 13 Fitur: 7 input dasar KHS & UKT di bawah ini akan diekstraksi secara otomatis menjadi 13 fitur prediktor model LightGBM.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Seksi Isi Cepat Skenario Demo (Quick Preset) ──
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Isi Cepat Skenario Demo',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(
                          label: 'Skenario Aman',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF16A34A),
                          bgColor: const Color(0xFFF0FDF4),
                          borderColor: const Color(0xFFBBF7D0),
                          onTap: () => _applyPreset(
                            ips1: 3.45, ambil1: 6, lulus1: 6,
                            ips2: 3.60, ambil2: 6, lulus2: 6,
                            ukt: 1,
                          ),
                        ),
                        _buildPresetChip(
                          label: 'Skenario Sedang',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFFFBEB),
                          borderColor: const Color(0xFFFDE68A),
                          onTap: () => _applyPreset(
                            ips1: 2.60, ambil1: 6, lulus1: 5,
                            ips2: 2.40, ambil2: 6, lulus2: 4,
                            ukt: 1,
                          ),
                        ),
                        _buildPresetChip(
                          label: 'Skenario Risiko Tinggi',
                          icon: Icons.error_outline_rounded,
                          color: const Color(0xFFDC2626),
                          bgColor: const Color(0xFFFEF2F2),
                          borderColor: const Color(0xFFFECACA),
                          onTap: () => _applyPreset(
                            ips1: 2.10, ambil1: 6, lulus1: 3,
                            ips2: 1.80, ambil2: 6, lulus2: 2,
                            ukt: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Card: Identitas & Semester 1 ──────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identitas & Akademik Semester 1',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // NIM Mahasiswa
                      TextFormField(
                        controller: _nimController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'NIM Mahasiswa',
                          hintText: 'Masukkan NIM, misal: 2410511042',
                          helperText: 'Otomatis dibuat jika dikosongkan',
                          helperMaxLines: 2,
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // IPS Sem 1
                      TextFormField(
                        controller: _ipsSem1Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'IPS Semester 1',
                          hintText: '0.00 – 4.00',
                          prefixIcon: Icon(Icons.grade_outlined, size: 20),
                        ),
                        validator: _validateIps,
                      ),
                      const SizedBox(height: 14),

                      // Matkul Diambil & Lulus Sem 1
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mkDiambilSem1Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Diambil',
                              labelStyle: TextStyle(fontSize: 12),
                              hintText: '≥ 1',
                              helperText: 'Bukan SKS',
                              prefixIcon: Icon(Icons.book_outlined, size: 18),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Matkul diambil Sem 1', min: 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _mkLulusSem1Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Lulus',
                              labelStyle: TextStyle(fontSize: 12),
                              hintText: '≥ 0',
                              helperText: 'Bukan SKS',
                              prefixIcon: Icon(Icons.check_outlined, size: 18),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Matkul lulus Sem 1', min: 0),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Card: Semester 2 ──────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Akademik Semester 2',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // IPS Sem 2
                      TextFormField(
                        controller: _ipsSem2Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'IPS Semester 2',
                          hintText: '0.00 – 4.00',
                          prefixIcon: Icon(Icons.grade_outlined, size: 20),
                        ),
                        validator: _validateIps,
                      ),
                      const SizedBox(height: 14),

                      // Matkul Diambil & Lulus Sem 2
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mkDiambilSem2Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Diambil',
                              labelStyle: TextStyle(fontSize: 12),
                              hintText: '≥ 1',
                              helperText: 'Bukan SKS',
                              prefixIcon: Icon(Icons.book_outlined, size: 18),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Matkul diambil Sem 2', min: 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _mkLulusSem2Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Lulus',
                              labelStyle: TextStyle(fontSize: 12),
                              hintText: '≥ 0',
                              helperText: 'Bukan SKS',
                              prefixIcon: Icon(Icons.check_outlined, size: 18),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Matkul lulus Sem 2', min: 0),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Card: Status UKT ──────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Pembayaran UKT',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _buildUktChoice(
                            label: 'Lancar',
                            value: 1,
                            activeColor: const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildUktChoice(
                            label: 'Menunggak',
                            value: 0,
                            activeColor: Colors.red,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // ── Card: Pratinjau Real-Time 6 Fitur Rekayasa (Otomatis) ──
              Card(
                margin: const EdgeInsets.only(top: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                color: const Color(0xFFF8FAFC),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.hub_outlined, color: Color(0xFF1E40AF), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pratinjau Real-Time 6 Fitur Rekayasa (Otomatis)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRealtimeStatItem(
                              label: 'Rata-rata IPS',
                              value: _liveAvgIps.toStringAsFixed(2),
                              sublabel: 'Tahun Pertama',
                              icon: Icons.school_outlined,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRealtimeStatItem(
                              label: 'Tren IPS (Δ)',
                              value: _liveTrenIps > 0 ? '+${_liveTrenIps.toStringAsFixed(2)}' : _liveTrenIps.toStringAsFixed(2),
                              sublabel: _liveTrenIps > 0 ? 'Meningkat' : (_liveTrenIps < 0 ? 'Menurun' : 'Stabil'),
                              icon: _liveTrenIps >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              color: _liveTrenIps >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRealtimeStatItem(
                              label: 'Rasio Lulus S1',
                              value: '$_liveRasio1%',
                              sublabel: '$_liveGagal1 Matkul Gagal',
                              icon: Icons.assessment_outlined,
                              color: _liveGagal1 == 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRealtimeStatItem(
                              label: 'Rasio Lulus S2',
                              value: '$_liveRasio2%',
                              sublabel: '$_liveGagal2 Matkul Gagal',
                              icon: Icons.assessment_outlined,
                              color: _liveGagal2 == 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Tombol Prediksi ───────────────────────────────────────
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitPrediction,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(
                    _isLoading ? 'Menganalisis dengan LightGBM...' : 'Analisis Risiko Kelulusan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Hasil Prediksi ────────────────────────────────────────
              if (_predictionResult != null) _buildResultSection(_predictionResult!),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget Hasil ────────────────────────────────────────────────────────
  Widget _buildResultSection(PredictionResponse res) {
    final Color statusColor;
    final IconData statusIcon;

    if (res.riskLevel.contains('Tinggi') || res.persentaseBulat >= 70) {
      statusColor = const Color(0xFFDC2626);
      statusIcon  = Icons.error_outline_rounded;
    } else if (res.riskLevel.contains('Sedang') || res.persentaseBulat >= 40) {
      statusColor = const Color(0xFFD97706);
      statusIcon  = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF16A34A);
      statusIcon  = Icons.check_circle_outline_rounded;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.riskLevel,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${res.kodeMhs} • NIM: ${res.nim}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            // Progress Bar Probabilitas (Angka Bulat)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Probabilitas Risiko Keterlambatan:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${res.persentaseBulat}%',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: res.persentaseBulat / 100,
                minHeight: 10,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pemicu Utama: ${res.penyebabUtama}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Faktor Pemicu Risiko (Observasi Data)
            const Row(children: [
              Icon(Icons.rule_folder_outlined, size: 18, color: Color(0xFF1E40AF)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Faktor Pemicu Risiko (Observasi Data):',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            ...res.faktorPemicu.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: Colors.black87))),
              ]),
            )),

            if (widget.onBackToDashboard != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onBackToDashboard,
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Lihat di Dashboard'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
