import 'package:flutter/material.dart';
import '../models/prediction_model.dart';

class StudentDetailSheet extends StatelessWidget {
  final ScreeningRecord record;
  final ValueChanged<ScreeningRecord> onEdit;

  const StudentDetailSheet({
    super.key,
    required this.record,
    required this.onEdit,
  });

  static void show(
    BuildContext context, {
    required ScreeningRecord record,
    required ValueChanged<ScreeningRecord> onEdit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (ctx) => StudentDetailSheet(
        record: record,
        onEdit: onEdit,
      ),
    );
  }

  Color _getStatusColor() {
    if (record.kategoriRisiko.contains('Tinggi') || record.persentaseBulat >= 70) {
      return const Color(0xFFDC2626);
    } else if (record.kategoriRisiko.contains('Sedang') || record.persentaseBulat >= 40) {
      return const Color(0xFFD97706);
    } else {
      return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      constraints: BoxConstraints(
        maxWidth: 430,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 14),

          // Header Mahasiswa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.kodeMhs} • NIM: ${record.nim}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IPS S1: ${record.ipsSem1.toStringAsFixed(2)} • S2: ${record.ipsSem2.toStringAsFixed(2)} • UKT: ${record.uktLancar == 1 ? "Lancar" : "Menunggak"}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  record.kategoriRisiko.replaceAll('Indikasi ', ''),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Probabilitas Keterlambatan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Probabilitas Keterlambatan:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '${record.persentaseBulat}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Pemicu Utama Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: statusColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pemicu Utama: ${record.penyebabUtama}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── SEKSI 6 FITUR REKAYASA (FEATURE ENGINEERING BREAKDOWN) ──
                  const Row(
                    children: [
                      Icon(Icons.hub_outlined, size: 16, color: Color(0xFF1E40AF)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Rincian Indikator Rekayasa Fitur',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 2x2 Grid Kotak Ringkas
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          title: 'Rata-rata IPS',
                          value: record.rataRataIps.toStringAsFixed(2),
                          subtitle: 'Semester 1 & 2',
                          valueColor: const Color(0xFF1E293B),
                          icon: Icons.analytics_outlined,
                          bgColor: const Color(0xFFF8FAFC),
                          borderColor: const Color(0xFFE2E8F0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTrenCard(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPassRatioCard(
                          title: 'Rasio Lulus S1',
                          percent: record.rasioLulusSem1Persen,
                          gagal: record.matkulGagalSem1,
                          diambil: record.matkulDiambilSem1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPassRatioCard(
                          title: 'Rasio Lulus S2',
                          percent: record.rasioLulusSem2Persen,
                          gagal: record.matkulGagalSem2,
                          diambil: record.matkulDiambilSem2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Faktor Pemicu Risiko (Observasi Data)
                  const Text(
                    'Faktor Pemicu Risiko (Observasi Data):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (record.faktorPemicu.isEmpty)
                    const Text(
                      '• Tidak ada faktor pemicu kritis.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    )
                  else
                    ...record.faktorPemicu.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
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

          const SizedBox(height: 16),

          // Action Buttons: Tutup & Evaluasi / Perbarui Data
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit(record);
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text(
                    'Evaluasi Data',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
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
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrenCard() {
    Color trenColor;
    IconData trenIcon;
    String sign = '';

    if (record.trenIps > 0) {
      trenColor = const Color(0xFF16A34A);
      trenIcon = Icons.trending_up_rounded;
      sign = '+';
    } else if (record.trenIps < 0) {
      trenColor = const Color(0xFFDC2626);
      trenIcon = Icons.trending_down_rounded;
    } else {
      trenColor = const Color(0xFF64748B);
      trenIcon = Icons.trending_flat_rounded;
    }

    final trenText = '$sign${record.trenIps.toStringAsFixed(2)} ${record.trenIps > 0 ? "Naik" : record.trenIps < 0 ? "Turun" : "Stabil"}';

    return _buildFeatureCard(
      title: 'Tren IPS',
      value: trenText,
      subtitle: 'Sem 1 ke Sem 2',
      valueColor: trenColor,
      icon: trenIcon,
      bgColor: trenColor.withValues(alpha: 0.05),
      borderColor: trenColor.withValues(alpha: 0.25),
    );
  }

  Widget _buildPassRatioCard({
    required String title,
    required int percent,
    required int gagal,
    required int diambil,
  }) {
    Color color;
    if (gagal == 0) {
      color = const Color(0xFF16A34A);
    } else if (gagal == 1) {
      color = const Color(0xFFD97706);
    } else {
      color = const Color(0xFFDC2626);
    }

    return _buildFeatureCard(
      title: title,
      value: '$percent% • $gagal Gagal',
      subtitle: 'dari $diambil matkul diambil',
      valueColor: color,
      icon: Icons.fact_check_outlined,
      bgColor: color.withValues(alpha: 0.05),
      borderColor: color.withValues(alpha: 0.25),
    );
  }
}
