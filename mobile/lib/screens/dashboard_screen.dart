import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../services/history_repository.dart';
import '../widgets/student_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final void Function([ScreeningRecord? record]) onNavigateToPrediction;
  final VoidCallback onNavigateToHistory;

  const DashboardScreen({
    super.key,
    required this.onNavigateToPrediction,
    required this.onNavigateToHistory,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final HistoryRepository _repo = HistoryRepository();
  bool? _isApiOnline;
  bool _isCheckingApi = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _checkApiStatus();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  int get _avgKolektifPersen {
    if (_repo.records.isEmpty) return 0;
    final sum = _repo.records.fold<int>(0, (prev, r) => prev + r.persentaseBulat);
    return (sum / _repo.records.length).round();
  }

  double get _avgIpsKolektif {
    if (_repo.records.isEmpty) return 0.0;
    final sum = _repo.records.fold<double>(0.0, (prev, r) => prev + ((r.ipsSem1 + r.ipsSem2) / 2.0));
    return sum / _repo.records.length;
  }

  int get _rasioLulusKolektifPersen {
    if (_repo.records.isEmpty) return 0;
    final totalDiambil = _repo.records.fold<int>(0, (prev, r) => prev + r.matkulDiambilSem1 + r.matkulDiambilSem2);
    final totalLulus = _repo.records.fold<int>(0, (prev, r) => prev + r.matkulLulusSem1 + r.matkulLulusSem2);
    if (totalDiambil == 0) return 0;
    return ((totalLulus / totalDiambil) * 100).round();
  }

  int get _totalUktMenunggak {
    return _repo.records.where((r) => r.uktLancar == 0).length;
  }

  Future<void> _checkApiStatus() async {
    setState(() => _isCheckingApi = true);
    final isHealthy = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _isApiOnline = isHealthy;
        _isCheckingApi = false;
      });
      if (isHealthy) {
        _repo.refreshFromApi();
      }
    }
  }

  void _showRecordDetail(ScreeningRecord record) {
    StudentDetailSheet.show(
      context,
      record: record,
      onEdit: (rec) => widget.onNavigateToPrediction(rec),
    );
  }

  void _showSettingsDialog() {
    final ipController = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan API Backend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah IP / Host Backend jika menjalankan di HP fisik:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'Base URL API',
                hintText: 'http://192.168.1.xxx:8000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tips:\n• Emulator Android: http://10.0.2.2:8000\n• HP Fisik: http://<IP_LAPTOP>:8000\n• Web / Windows: http://127.0.0.1:8000',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final newUrl = ipController.text.trim();
              if (newUrl.isNotEmpty) {
                ApiService.baseUrl = newUrl;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Base URL diubah: ${ApiService.baseUrl}')),
              );
              _checkApiStatus();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: Color(0xFF1E40AF), size: 24),
            SizedBox(width: 8),
            Text(
              'PathGrad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isCheckingApi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Cek Status API',
            onPressed: _checkApiStatus,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan API',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkApiStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Sistem Skrining Dosen PA',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isApiOnline == true
                                ? Colors.green.withValues(alpha: 0.25)
                                : Colors.red.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isApiOnline == true ? Colors.lightGreenAccent : Colors.redAccent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3.5,
                                backgroundColor: _isApiOnline == true ? Colors.greenAccent : Colors.redAccent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isApiOnline == true ? 'API Online' : 'API Offline',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Prediksi Risiko Keterlambatan Kelulusan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Instrumen skrining preventif berbasis LightGBM (13 Fitur Akademik) dari dataset UCI 697.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: widget.onNavigateToPrediction,
                        icon: const Icon(Icons.add_chart_rounded, size: 18),
                        label: const Text(
                          'Buat Prediksi Baru',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Title
              const Text(
                'Statistik Skrining Mahasiswa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),

              // Card Utama: Indikasi Risiko Keseluruhan Mahasiswa Bimbingan
              _buildOverallRiskCard(),

              const SizedBox(height: 12),

              // Metrics Grid (4 Kategori Seragam)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Mahasiswa',
                      count: _repo.totalCount.toString(),
                      icon: Icons.group_outlined,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Risiko Rendah',
                      count: _repo.rendahCount.toString(),
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Risiko Sedang',
                      count: _repo.sedangCount.toString(),
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Risiko Tinggi',
                      count: _repo.tinggiCount.toString(),
                      icon: Icons.error_outline_rounded,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Seksi Baru: Prioritas Perwalian (Top 3 Indikasi Risiko Tertinggi)
              _buildTop3PrioritySection(),

              // Recent Screening Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Riwayat Skrining Terkini',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNavigateToHistory,
                    child: Text(
                      'Lihat Semua (${_repo.records.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recent Screening List
              if (_repo.records.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada riwayat skrining mahasiswa.',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._repo.records.take(5).map((r) => _buildRecordCard(r)),

              const SizedBox(height: 16),

              // Info Card Model
              Card(
                color: const Color(0xFFF1F5F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF475569), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Model LightGBM dilatih pada Dataset UCI ID-697 dengan 13 fitur akademik (IPS, rasio lulus, tren, dan status UKT) untuk instrumen observasi Dosen PA.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallRiskCard() {
    final count = _repo.totalCount;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    final avgRisk = _avgKolektifPersen;
    final Color riskColor;
    final String riskLabel;
    if (avgRisk >= 70) {
      riskColor = const Color(0xFFDC2626);
      riskLabel = 'Indikasi Risiko Tinggi';
    } else if (avgRisk >= 40) {
      riskColor = const Color(0xFFD97706);
      riskLabel = 'Indikasi Risiko Sedang';
    } else {
      riskColor = const Color(0xFF16A34A);
      riskLabel = 'Indikasi Risiko Rendah';
    }

    final pctRendah = (_repo.rendahCount / count * 100).round();
    final pctSedang = (_repo.sedangCount / count * 100).round();
    final pctTinggi = (_repo.tinggiCount / count * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Indikasi Risiko Keseluruhan Mahasiswa Bimbingan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$avgRisk%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: riskColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Rata-rata Probabilitas Kolektif',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stacked Progress Bar 3 Kategori (Bulat)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (_repo.rendahCount > 0)
                    Expanded(
                      flex: _repo.rendahCount,
                      child: Container(color: const Color(0xFF16A34A)),
                    ),
                  if (_repo.sedangCount > 0)
                    Expanded(
                      flex: _repo.sedangCount,
                      child: Container(color: const Color(0xFFD97706)),
                    ),
                  if (_repo.tinggiCount > 0)
                    Expanded(
                      flex: _repo.tinggiCount,
                      child: Container(color: const Color(0xFFDC2626)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Rendah: $pctRendah%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ]),
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Sedang: $pctSedang%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ]),
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Tinggi: $pctTinggi%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          // Ringkasan 3 Indikator Kolektif
          Row(
            children: [
              Expanded(
                child: _buildCollectiveStatItem(
                  label: 'Rata-rata IPS',
                  value: _avgIpsKolektif.toStringAsFixed(2),
                  icon: Icons.school_outlined,
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildCollectiveStatItem(
                  label: 'Rasio Lulus',
                  value: '$_rasioLulusKolektifPersen%',
                  icon: Icons.check_circle_outline,
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildCollectiveStatItem(
                  label: 'UKT Menunggak',
                  value: '$_totalUktMenunggak Mhs',
                  icon: Icons.payment_outlined,
                  isAlert: _totalUktMenunggak > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectiveStatItem({
    required String label,
    required String value,
    required IconData icon,
    bool isAlert = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          softWrap: true,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.1),
        ),
      ],
    );
  }

  Widget _buildTop3PrioritySection() {
    // Ambil seluruh data lalu urutkan berdasarkan persentase_bulat tertinggi
    final sortedRecords = [..._repo.records]
      ..sort((a, b) => b.persentaseBulat.compareTo(a.persentaseBulat));

    final top3 = sortedRecords.take(3).toList();
    final highRiskCount = _repo.records
        .where((r) => r.kategoriRisiko.contains('Tinggi') || r.persentaseBulat >= 70)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.priority_high_rounded, color: Color(0xFFDC2626), size: 16),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Prioritas Perwalian (Top 3 Indikasi Risiko Tertinggi)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (highRiskCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$highRiskCount Mahasiswa',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (top3.isEmpty)
          Card(
            elevation: 0,
            color: const Color(0xFFF0FDF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFBBF7D0)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada data riwayat skrining mahasiswa.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...top3.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final record = entry.value;
            return _buildPriorityCard(record, rank: index);
          }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPriorityCard(ScreeningRecord record, {required int rank}) {
    const badgeColor = Color(0xFFDC2626);
    final isUktLancar = record.uktLancar == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFECACA), width: 1),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFFDC2626), width: 5),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRecordDetail(record),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: badgeColor,
                  child: Text(
                    '#$rank',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record.kodeMhs} • NIM: ${record.nim}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'IPS Sem1: ${record.ipsSem1.toStringAsFixed(2)} • Sem2: ${record.ipsSem2.toStringAsFixed(2)} • UKT: ${isUktLancar ? "Lancar" : "Menunggak"}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pemicu Utama: ${record.penyebabUtama}',
                        maxLines: 2,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${record.persentaseBulat}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(ScreeningRecord record) {
    Color badgeColor;
    if (record.kategoriRisiko.contains('Tinggi') || record.persentaseBulat >= 70) {
      badgeColor = const Color(0xFFDC2626);
    } else if (record.kategoriRisiko.contains('Sedang') || record.persentaseBulat >= 40) {
      badgeColor = const Color(0xFFD97706);
    } else {
      badgeColor = const Color(0xFF16A34A);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRecordDetail(record),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: badgeColor.withValues(alpha: 0.12),
                foregroundColor: badgeColor,
                child: Text(
                  record.kodeMhs.replaceAll('MHS-', ''),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.kodeMhs} • NIM: ${record.nim}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IPS Sem1: ${record.ipsSem1.toStringAsFixed(2)} • Sem2: ${record.ipsSem2.toStringAsFixed(2)} • UKT: ${record.uktLancar == 1 ? "Lancar" : "Menunggak"}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pemicu Utama: ${record.penyebabUtama}',
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${record.persentaseBulat}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
