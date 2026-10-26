class StudentPredictionRequest {
  final String kodeAnonim;
  final String? nim;
  final bool simpanRiwayat;
  final double ipsSem1;
  final int matkulDiambilSem1;
  final int matkulLulusSem1;
  final double ipsSem2;
  final int matkulDiambilSem2;
  final int matkulLulusSem2;
  final int uktLancar; // 0 = Menunggak, 1 = Lancar

  StudentPredictionRequest({
    this.kodeAnonim = 'MHS-ANON',
    this.nim,
    this.simpanRiwayat = true,
    required this.ipsSem1,
    required this.matkulDiambilSem1,
    required this.matkulLulusSem1,
    required this.ipsSem2,
    required this.matkulDiambilSem2,
    required this.matkulLulusSem2,
    required this.uktLancar,
  });

  Map<String, dynamic> toJson() {
    return {
      'kode_anonim':         kodeAnonim,
      'nim':                 nim,
      'simpan_riwayat':      simpanRiwayat,
      'ips_sem1':            ipsSem1,
      'matkul_diambil_sem1': matkulDiambilSem1,
      'matkul_lulus_sem1':   matkulLulusSem1,
      'ips_sem2':            ipsSem2,
      'matkul_diambil_sem2': matkulDiambilSem2,
      'matkul_lulus_sem2':   matkulLulusSem2,
      'ukt_lancar':          uktLancar,
    };
  }
}

class PredictionResponse {
  final String kodeMhs;
  final String nim;
  final String riskLevel;
  final double riskPercentage;
  final int persentaseBulat;
  final String predictionLabel;
  final String penyebabUtama;
  final List<String> faktorPemicu;
  // 6 Fitur Rekayasa
  final double rataRataIps;
  final double trenIps;
  final String trenIpsLabel;
  final int rasioLulusSem1Persen;
  final int matkulGagalSem1;
  final int rasioLulusSem2Persen;
  final int matkulGagalSem2;

  PredictionResponse({
    required this.kodeMhs,
    required this.nim,
    required this.riskLevel,
    required this.riskPercentage,
    required this.persentaseBulat,
    required this.predictionLabel,
    required this.penyebabUtama,
    required this.faktorPemicu,
    this.rataRataIps = 0.0,
    this.trenIps = 0.0,
    this.trenIpsLabel = '0.00 (Stabil)',
    this.rasioLulusSem1Persen = 100,
    this.matkulGagalSem1 = 0,
    this.rasioLulusSem2Persen = 100,
    this.matkulGagalSem2 = 0,
  });

  // Kompatibilitas jika ada kode lama yang memanggil kodeAnonim / topFactors
  String get kodeAnonim => kodeMhs;
  List<String> get topFactors => faktorPemicu;
  List<String> get recommendations => const [];

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    final pDouble = (json['risk_percentage'] as num?)?.toDouble() ?? 0.0;
    final pBulat = json['persentase_bulat'] != null
        ? (json['persentase_bulat'] as num).toInt()
        : pDouble.round();

    final pemicu = json['faktor_pemicu'] != null
        ? List<String>.from(json['faktor_pemicu'])
        : (json['top_factors'] != null
            ? List<String>.from(json['top_factors'])
            : <String>[]);

    final dTren = (json['tren_ips'] as num?)?.toDouble() ?? 0.0;
    final String dTrenLabel = json['tren_ips_label'] ??
        (dTren > 0 ? '+${dTren.toStringAsFixed(2)} (Naik)' : dTren < 0 ? '${dTren.toStringAsFixed(2)} (Turun)' : '0.00 (Stabil)');

    return PredictionResponse(
      kodeMhs:              json['kode_mhs'] ?? json['kode_anonim'] ?? 'MHS-001',
      nim:                  json['nim'] ?? '-',
      riskLevel:            json['risk_level'] ?? json['kategori_risiko'] ?? 'Indikasi Risiko Rendah',
      riskPercentage:       pDouble,
      persentaseBulat:      pBulat,
      predictionLabel:      json['prediction_label'] ?? json['risk_level'] ?? 'Indikasi Risiko Rendah',
      penyebabUtama:        json['penyebab_utama'] ?? 'Akademik stabil & mata kuliah tuntas',
      faktorPemicu:         pemicu,
      rataRataIps:          (json['rata_rata_ips'] as num?)?.toDouble() ?? 0.0,
      trenIps:              dTren,
      trenIpsLabel:         dTrenLabel,
      rasioLulusSem1Persen: (json['rasio_lulus_sem1_persen'] as num?)?.toInt() ?? 100,
      matkulGagalSem1:      (json['matkul_gagal_sem1'] as num?)?.toInt() ?? 0,
      rasioLulusSem2Persen: (json['rasio_lulus_sem2_persen'] as num?)?.toInt() ?? 100,
      matkulGagalSem2:      (json['matkul_gagal_sem2'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScreeningRecord {
  final int id;
  final String kodeMhs;
  final String nim;
  final DateTime date;
  final double ipsSem1;
  final int matkulDiambilSem1;
  final int matkulLulusSem1;
  final double ipsSem2;
  final int matkulDiambilSem2;
  final int matkulLulusSem2;
  final int uktLancar;
  final int persentaseBulat;
  final String kategoriRisiko;
  final String penyebabUtama;
  final List<String> faktorPemicu;
  // 6 Fitur Rekayasa
  final double rataRataIps;
  final double trenIps;
  final String trenIpsLabel;
  final int rasioLulusSem1Persen;
  final int matkulGagalSem1;
  final int rasioLulusSem2Persen;
  final int matkulGagalSem2;

  ScreeningRecord({
    required this.id,
    required this.kodeMhs,
    required this.nim,
    required this.date,
    required this.ipsSem1,
    this.matkulDiambilSem1 = 6,
    this.matkulLulusSem1 = 6,
    required this.ipsSem2,
    this.matkulDiambilSem2 = 6,
    this.matkulLulusSem2 = 6,
    required this.uktLancar,
    required this.persentaseBulat,
    required this.kategoriRisiko,
    required this.penyebabUtama,
    required this.faktorPemicu,
    double? rataRataIps,
    double? trenIps,
    String? trenIpsLabel,
    int? rasioLulusSem1Persen,
    int? matkulGagalSem1,
    int? rasioLulusSem2Persen,
    int? matkulGagalSem2,
  })  : rataRataIps = rataRataIps ?? double.parse(((ipsSem1 + ipsSem2) / 2.0).toStringAsFixed(2)),
        trenIps = trenIps ?? double.parse((ipsSem2 - ipsSem1).toStringAsFixed(2)),
        trenIpsLabel = trenIpsLabel ??
            ((ipsSem2 - ipsSem1) > 0
                ? '+${(ipsSem2 - ipsSem1).toStringAsFixed(2)} (Naik)'
                : (ipsSem2 - ipsSem1) < 0
                    ? '${(ipsSem2 - ipsSem1).toStringAsFixed(2)} (Turun)'
                    : '0.00 (Stabil)'),
        rasioLulusSem1Persen = rasioLulusSem1Persen ??
            (matkulDiambilSem1 > 0 ? ((matkulLulusSem1 / matkulDiambilSem1) * 100).round() : 0),
        matkulGagalSem1 = matkulGagalSem1 ?? (matkulDiambilSem1 - matkulLulusSem1 < 0 ? 0 : matkulDiambilSem1 - matkulLulusSem1),
        rasioLulusSem2Persen = rasioLulusSem2Persen ??
            (matkulDiambilSem2 > 0 ? ((matkulLulusSem2 / matkulDiambilSem2) * 100).round() : 0),
        matkulGagalSem2 = matkulGagalSem2 ?? (matkulDiambilSem2 - matkulLulusSem2 < 0 ? 0 : matkulDiambilSem2 - matkulLulusSem2);

  // Getter pembantu agar kompatibel dengan widget yang mengakses record.result
  PredictionResponse get result => PredictionResponse(
    kodeMhs: kodeMhs,
    nim: nim,
    riskLevel: kategoriRisiko,
    riskPercentage: persentaseBulat.toDouble(),
    persentaseBulat: persentaseBulat,
    predictionLabel: kategoriRisiko,
    penyebabUtama: penyebabUtama,
    faktorPemicu: faktorPemicu,
    rataRataIps: rataRataIps,
    trenIps: trenIps,
    trenIpsLabel: trenIpsLabel,
    rasioLulusSem1Persen: rasioLulusSem1Persen,
    matkulGagalSem1: matkulGagalSem1,
    rasioLulusSem2Persen: rasioLulusSem2Persen,
    matkulGagalSem2: matkulGagalSem2,
  );

  String get kodeAnonim => kodeMhs;

  factory ScreeningRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'] ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final pemicu = json['faktor_pemicu'] != null
        ? List<String>.from(json['faktor_pemicu'])
        : <String>[];

    final ips1 = (json['ips_sem1'] as num?)?.toDouble() ?? 0.0;
    final ips2 = (json['ips_sem2'] as num?)?.toDouble() ?? 0.0;
    final ambil1 = (json['matkul_diambil_sem1'] as num?)?.toInt() ?? 6;
    final lulus1 = (json['matkul_lulus_sem1'] as num?)?.toInt() ?? 6;
    final ambil2 = (json['matkul_diambil_sem2'] as num?)?.toInt() ?? 6;
    final lulus2 = (json['matkul_lulus_sem2'] as num?)?.toInt() ?? 6;

    final avgIps = (json['rata_rata_ips'] as num?)?.toDouble() ?? double.parse(((ips1 + ips2) / 2.0).toStringAsFixed(2));
    final dTren = (json['tren_ips'] as num?)?.toDouble() ?? double.parse((ips2 - ips1).toStringAsFixed(2));
    final dTrenLabel = json['tren_ips_label'] ??
        (dTren > 0 ? '+${dTren.toStringAsFixed(2)} (Naik)' : dTren < 0 ? '${dTren.toStringAsFixed(2)} (Turun)' : '0.00 (Stabil)');
    final r1 = (json['rasio_lulus_sem1_persen'] as num?)?.toInt() ??
        (ambil1 > 0 ? ((lulus1 / ambil1) * 100).round() : 0);
    final g1 = (json['matkul_gagal_sem1'] as num?)?.toInt() ??
        (ambil1 - lulus1 < 0 ? 0 : ambil1 - lulus1);
    final r2 = (json['rasio_lulus_sem2_persen'] as num?)?.toInt() ??
        (ambil2 > 0 ? ((lulus2 / ambil2) * 100).round() : 0);
    final g2 = (json['matkul_gagal_sem2'] as num?)?.toInt() ??
        (ambil2 - lulus2 < 0 ? 0 : ambil2 - lulus2);

    return ScreeningRecord(
      id:                   json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      kodeMhs:              json['kode_mhs'] ?? 'MHS-001',
      nim:                  json['nim'] ?? '-',
      date:                 parsedDate,
      ipsSem1:              ips1,
      matkulDiambilSem1:    ambil1,
      matkulLulusSem1:      lulus1,
      ipsSem2:              ips2,
      matkulDiambilSem2:    ambil2,
      matkulLulusSem2:      lulus2,
      uktLancar:            (json['ukt_lancar'] as num?)?.toInt() ?? 1,
      persentaseBulat:      (json['persentase_bulat'] as num?)?.toInt() ?? 0,
      kategoriRisiko:       json['kategori_risiko'] ?? json['risk_level'] ?? 'Indikasi Risiko Rendah',
      penyebabUtama:        json['penyebab_utama'] ?? 'Akademik stabil & mata kuliah tuntas',
      faktorPemicu:         pemicu,
      rataRataIps:          avgIps,
      trenIps:              dTren,
      trenIpsLabel:         dTrenLabel,
      rasioLulusSem1Persen: r1,
      matkulGagalSem1:      g1,
      rasioLulusSem2Persen: r2,
      matkulGagalSem2:      g2,
    );
  }
}

class HistoryStats {
  final int totalMahasiswa;
  final int totalRendah;
  final int totalSedang;
  final int totalTinggi;
  final List<ScreeningRecord> records;

  HistoryStats({
    required this.totalMahasiswa,
    required this.totalRendah,
    required this.totalSedang,
    required this.totalTinggi,
    required this.records,
  });

  factory HistoryStats.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List<dynamic>?) ?? [];
    return HistoryStats(
      totalMahasiswa: (json['total_mahasiswa'] as num?)?.toInt() ?? list.length,
      totalRendah:    (json['total_rendah'] as num?)?.toInt() ?? 0,
      totalSedang:    (json['total_sedang'] as num?)?.toInt() ?? 0,
      totalTinggi:    (json['total_tinggi'] as num?)?.toInt() ?? 0,
      records:        list.map((e) => ScreeningRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
