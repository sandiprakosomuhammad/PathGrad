import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../services/history_repository.dart';

class PredictionScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const PredictionScreen({super.key, this.onBackToDashboard});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers (Identitas NIM & 7 Parameter Akademik) ─────────────────
  final _nimController           = TextEditingController();
  final _ipsSem1Controller       = TextEditingController(text: '2.50');
  final _mkDiambilSem1Controller = TextEditingController(text: '6');
  final _mkLulusSem1Controller   = TextEditingController(text: '4');
  final _ipsSem2Controller       = TextEditingController(text: '2.00');
  final _mkDiambilSem2Controller = TextEditingController(text: '6');
  final _mkLulusSem2Controller   = TextEditingController(text: '3');
  int _uktLancar = 1; // 0 = Menunggak, 1 = Lancar

  bool _isLoading = false;
  PredictionResponse? _predictionResult;

  @override
  void dispose() {
    _nimController.dispose();
    _ipsSem1Controller.dispose();
    _mkDiambilSem1Controller.dispose();
    _mkLulusSem1Controller.dispose();
    _ipsSem2Controller.dispose();
    _mkDiambilSem2Controller.dispose();
    _mkLulusSem2Controller.dispose();
    super.dispose();
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
        kodeAnonim:          'MHS-ANON',
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              size: 18,
              color: isSelected ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : const Color(0xFF334155),
              ),
            ),
          ],
        ),
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
                          helperText: 'Otomatis di-generate jika dikosongkan',
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
                              labelText: 'Jumlah Matkul Diambil',
                              hintText: '≥ 1',
                              helperText: 'Bukan SKS (jml matkul)',
                              prefixIcon: Icon(Icons.book_outlined, size: 20),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Jumlah mata kuliah diambil Sem 1', min: 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _mkLulusSem1Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah Matkul Lulus',
                              hintText: '≥ 0',
                              helperText: 'Bukan SKS',
                              prefixIcon: Icon(Icons.check_outlined, size: 20),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Jumlah mata kuliah lulus Sem 1', min: 0),
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
                              labelText: 'Jumlah Matkul Diambil',
                              hintText: '≥ 1',
                              helperText: 'Bukan SKS (jml matkul)',
                              prefixIcon: Icon(Icons.book_outlined, size: 20),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Jumlah mata kuliah diambil Sem 2', min: 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _mkLulusSem2Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah Matkul Lulus',
                              hintText: '≥ 0',
                              helperText: 'Bukan SKS',
                              prefixIcon: Icon(Icons.check_outlined, size: 20),
                            ),
                            validator: (v) => _validateMatkul(v,
                                label: 'Jumlah mata kuliah lulus Sem 2', min: 0),
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
                            label: 'Lancar / Lunas',
                            value: 1,
                            activeColor: const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(width: 10),
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
              children: [
                const Text('Probabilitas Risiko Keterlambatan:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
              Text('Faktor Pemicu Risiko (Observasi Data):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
