import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/history_repository.dart';
import '../widgets/student_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  final void Function([ScreeningRecord? record]) onNavigateToPrediction;

  const HistoryScreen({super.key, required this.onNavigateToPrediction});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _repo = HistoryRepository();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';
  String _selectedSort = 'Risiko Tertinggi';

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

  int get _countTotal => _repo.records.length;
  int get _countRendah => _repo.records
      .where((r) => r.kategoriRisiko.contains('Rendah') || r.persentaseBulat < 40)
      .length;
  int get _countSedang => _repo.records
      .where((r) =>
          r.kategoriRisiko.contains('Sedang') ||
          (r.persentaseBulat >= 40 && r.persentaseBulat < 70))
      .length;
  int get _countTinggi => _repo.records
      .where((r) => r.kategoriRisiko.contains('Tinggi') || r.persentaseBulat >= 70)
      .length;

  List<ScreeningRecord> get _filteredRecords {
    final query = _searchController.text.toLowerCase().trim();
    final list = _repo.records.where((record) {
      final matchesQuery = query.isEmpty ||
          record.kodeMhs.toLowerCase().contains(query) ||
          record.nim.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'Risiko Rendah') {
        return record.kategoriRisiko.contains('Rendah') || record.persentaseBulat < 40;
      } else if (_selectedFilter == 'Risiko Sedang') {
        return record.kategoriRisiko.contains('Sedang') ||
            (record.persentaseBulat >= 40 && record.persentaseBulat < 70);
      } else if (_selectedFilter == 'Risiko Tinggi') {
        return record.kategoriRisiko.contains('Tinggi') || record.persentaseBulat >= 70;
      }
      return true;
    }).toList();

    switch (_selectedSort) {
      case 'Risiko Terendah':
        list.sort((a, b) => a.persentaseBulat.compareTo(b.persentaseBulat));
        break;
      case 'IPS Terendah':
        list.sort((a, b) => a.rataRataIps.compareTo(b.rataRataIps));
        break;
      case 'Kode MHS (A-Z)':
        list.sort((a, b) => a.kodeMhs.compareTo(b.kodeMhs));
        break;
      case 'Risiko Tertinggi':
      default:
        list.sort((a, b) => b.persentaseBulat.compareTo(a.persentaseBulat));
        break;
    }

    return list;
  }

  void _showRecordDetail(ScreeningRecord record) {
    StudentDetailSheet.show(
      context,
      record: record,
      onEdit: (rec) => widget.onNavigateToPrediction(rec),
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
          // Search, Filter, & Sorting Header
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
                // Deretan Chip Filter Kategori dengan Jumlah Data
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua ($_countTotal)', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Risiko Rendah ($_countRendah)', 'Risiko Rendah'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Risiko Sedang ($_countSedang)', 'Risiko Sedang'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Risiko Tinggi ($_countTinggi)', 'Risiko Tinggi'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Baris Kontrol: Menampilkan X Mahasiswa + Dropdown Sorting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Menampilkan ${filteredList.length} Mahasiswa',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          isDense: true,
                          icon: const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF1E3A8A)),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Risiko Tertinggi', child: Text('Risiko Tertinggi')),
                            DropdownMenuItem(value: 'Risiko Terendah', child: Text('Risiko Terendah')),
                            DropdownMenuItem(value: 'IPS Terendah', child: Text('IPS Terendah')),
                            DropdownMenuItem(value: 'Kode MHS (A-Z)', child: Text('Kode MHS (A-Z)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSort = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

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

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
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

    final totalLulus = record.matkulLulusSem1 + record.matkulLulusSem2;
    final totalDiambil = record.matkulDiambilSem1 + record.matkulDiambilSem2;
    final trenVal = record.trenIps;
    final trenStr = trenVal > 0 ? '+${trenVal.toStringAsFixed(2)}' : trenVal.toStringAsFixed(2);
    final isUktLancar = record.uktLancar == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRecordDetail(record),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header baris identitas, IPS, UKT, Pemicu Utama, dan Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'IPS Sem1: ${record.ipsSem1.toStringAsFixed(2)} • Sem2: ${record.ipsSem2.toStringAsFixed(2)} • UKT: ${isUktLancar ? "Lancar" : "Menunggak"}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Pemicu Utama: ${record.penyebabUtama}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      const SizedBox(height: 3),
                      Text(
                        record.kategoriRisiko.replaceAll('Indikasi ', ''),
                        style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              // Deretan 4 Mini-Chip Ringkas (Wrap Responsif)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildMiniChip(
                    icon: Icons.school_outlined,
                    label: 'Rata IPS: ${record.rataRataIps.toStringAsFixed(2)}',
                    color: const Color(0xFF475569),
                    bgColor: const Color(0xFFF1F5F9),
                  ),
                  _buildMiniChip(
                    icon: trenVal >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    label: 'Tren: $trenStr',
                    color: trenVal >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    bgColor: trenVal >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  ),
                  _buildMiniChip(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Lulus: $totalLulus/$totalDiambil Matkul',
                    color: totalLulus == totalDiambil ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    bgColor: totalLulus == totalDiambil ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                  ),
                  _buildMiniChip(
                    icon: isUktLancar ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    label: 'UKT: ${isUktLancar ? "Lancar" : "Menunggak"}',
                    color: isUktLancar ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    bgColor: isUktLancar ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
