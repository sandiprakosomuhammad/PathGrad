import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../services/history_repository.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToPrediction;
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
    Color statusColor;
    if (record.kategoriRisiko.contains('Tinggi') || record.persentaseBulat >= 70) {
      statusColor = const Color(0xFFDC2626);
    } else if (record.kategoriRisiko.contains('Sedang') || record.persentaseBulat >= 40) {
      statusColor = const Color(0xFFD97706);
    } else {
      statusColor = const Color(0xFF16A34A);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.kodeMhs} • NIM: ${record.nim}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IPS Sem1: ${record.ipsSem1.toStringAsFixed(2)} • Sem2: ${record.ipsSem2.toStringAsFixed(2)} • UKT: ${record.uktLancar == 1 ? "Lancar" : "Menunggak"}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.kategoriRisiko,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Probabilitas Keterlambatan:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  '${record.persentaseBulat}%',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pemicu Utama: ${record.penyebabUtama}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Faktor Pemicu Risiko (Observasi Data):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (record.faktorPemicu.isEmpty)
              const Text('• Tidak ada faktor pemicu kritis.', style: TextStyle(fontSize: 13, color: Colors.black87))
            else
              ...record.faktorPemicu.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• $f', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Sistem Skrining Dosen PA',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                radius: 4,
                                backgroundColor: _isApiOnline == true ? Colors.greenAccent : Colors.redAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isApiOnline == true ? 'API Online' : 'API Offline',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Indikasi Risiko Rendah',
                      count: _repo.rendahCount.toString(),
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Indikasi Risiko Sedang',
                      count: _repo.sedangCount.toString(),
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Indikasi Risiko Tinggi',
                      count: _repo.tinggiCount.toString(),
                      icon: Icons.error_outline_rounded,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Screening Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Skrining Terkini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
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
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IPS Sem1: ${record.ipsSem1.toStringAsFixed(2)} • Sem2: ${record.ipsSem2.toStringAsFixed(2)} • UKT: ${record.uktLancar == 1 ? "Lancar" : "Menunggak"}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pemicu Utama: ${record.penyebabUtama}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
