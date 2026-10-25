import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/history_repository.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onNavigateToPrediction;

  const HistoryScreen({super.key, required this.onNavigateToPrediction});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _repo = HistoryRepository();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _searchController.addListener(_onSearchChanged);
    _repo.refreshFromApi();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<ScreeningRecord> get _filteredRecords {
    final query = _searchController.text.toLowerCase().trim();
    return _repo.records.where((record) {
      final matchesQuery = query.isEmpty ||
          record.kodeMhs.toLowerCase().contains(query) ||
          record.nim.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'Indikasi Risiko Rendah') {
        return record.kategoriRisiko.contains('Rendah') || record.persentaseBulat < 40;
      } else if (_selectedFilter == 'Indikasi Risiko Sedang') {
        return record.kategoriRisiko.contains('Sedang') ||
            (record.persentaseBulat >= 40 && record.persentaseBulat < 70);
      } else if (_selectedFilter == 'Indikasi Risiko Tinggi') {
        return record.kategoriRisiko.contains('Tinggi') || record.persentaseBulat >= 70;
      }
      return true;
    }).toList();
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
        padding: const EdgeInsets.all(22),
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
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record.kodeMhs} • NIM: ${record.nim}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'IPS Sem1: ${record.ipsSem1.toStringAsFixed(2)} • Sem2: ${record.ipsSem2.toStringAsFixed(2)} • UKT: ${record.uktLancar == 1 ? "Lancar" : "Menunggak"}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
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
                const Text(
                  'Probabilitas Keterlambatan:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
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
            const SizedBox(height: 22),
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

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Skrining Mahasiswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Riwayat',
            onPressed: () => _repo.refreshFromApi(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari Kode Mahasiswa atau NIM...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Indikasi Risiko Rendah'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Indikasi Risiko Sedang'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Indikasi Risiko Tinggi'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List of Records
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _repo.refreshFromApi(),
              child: filteredList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada data yang cocok',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Coba ubah kata kunci pencarian (Kode/NIM) atau filter status risiko.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: widget.onNavigateToPrediction,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Buat Skrining Baru'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final record = filteredList[index];
                        return _buildRecordCard(record);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = label);
      },
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRecordDetail(record),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: badgeColor.withValues(alpha: 0.12),
                foregroundColor: badgeColor,
                child: Text(
                  record.kodeMhs.replaceAll('MHS-', ''),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.kodeMhs} • NIM: ${record.nim}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${record.persentaseBulat}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.kategoriRisiko.replaceAll('Indikasi ', ''),
                    style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
