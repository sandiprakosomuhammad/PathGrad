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

  PredictionResponse({
    required this.kodeMhs,
    required this.nim,
    required this.riskLevel,
    required this.riskPercentage,
    required this.persentaseBulat,
    required this.predictionLabel,
    required this.penyebabUtama,
    required this.faktorPemicu,
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

    return PredictionResponse(
      kodeMhs:         json['kode_mhs'] ?? json['kode_anonim'] ?? 'MHS-001',
      nim:             json['nim'] ?? '-',
      riskLevel:       json['risk_level'] ?? json['kategori_risiko'] ?? 'Indikasi Risiko Rendah',
      riskPercentage:  pDouble,
      persentaseBulat: pBulat,
      predictionLabel: json['prediction_label'] ?? json['risk_level'] ?? 'Indikasi Risiko Rendah',
      penyebabUtama:   json['penyebab_utama'] ?? 'Akademik stabil & mata kuliah tuntas',
      faktorPemicu:    pemicu,
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
  });

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

    return ScreeningRecord(
      id:                 json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      kodeMhs:            json['kode_mhs'] ?? 'MHS-001',
      nim:                json['nim'] ?? '-',
      date:               parsedDate,
      ipsSem1:            (json['ips_sem1'] as num?)?.toDouble() ?? 0.0,
      matkulDiambilSem1:  (json['matkul_diambil_sem1'] as num?)?.toInt() ?? 6,
      matkulLulusSem1:    (json['matkul_lulus_sem1'] as num?)?.toInt() ?? 6,
      ipsSem2:            (json['ips_sem2'] as num?)?.toDouble() ?? 0.0,
      matkulDiambilSem2:  (json['matkul_diambil_sem2'] as num?)?.toInt() ?? 6,
      matkulLulusSem2:    (json['matkul_lulus_sem2'] as num?)?.toInt() ?? 6,
      uktLancar:          (json['ukt_lancar'] as num?)?.toInt() ?? 1,
      persentaseBulat:    (json['persentase_bulat'] as num?)?.toInt() ?? 0,
      kategoriRisiko:     json['kategori_risiko'] ?? json['risk_level'] ?? 'Indikasi Risiko Rendah',
      penyebabUtama:      json['penyebab_utama'] ?? 'Akademik stabil & mata kuliah tuntas',
      faktorPemicu:       pemicu,
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
