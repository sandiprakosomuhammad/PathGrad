from pydantic import BaseModel, Field, field_validator, model_validator
from typing import List, Optional


class StudentPredictionRequest(BaseModel):
    kode_anonim: str = Field(
        default="MHS-ANON",
        description="Kode pencatatan anonim tanpa nama/NIM asli"
    )
    nim: Optional[str] = Field(
        default=None,
        description="NIM mahasiswa (opsional, otomatis diisi jika kosong saat simpan)"
    )
    simpan_riwayat: bool = Field(
        default=False,
        description="Apakah hasil skrining disimpan ke database SQLite"
    )
    ips_sem1: float = Field(
        ...,
        description="Indeks Prestasi Semester 1 (0.0 - 4.0)"
    )
    matkul_diambil_sem1: int = Field(
        ...,
        description="Jumlah mata kuliah yang diambil di Semester 1 (minimal 1)"
    )
    matkul_lulus_sem1: int = Field(
        ...,
        description="Jumlah mata kuliah yang lulus di Semester 1"
    )
    ips_sem2: float = Field(
        ...,
        description="Indeks Prestasi Semester 2 (0.0 - 4.0)"
    )
    matkul_diambil_sem2: int = Field(
        ...,
        description="Jumlah mata kuliah yang diambil di Semester 2 (minimal 1)"
    )
    matkul_lulus_sem2: int = Field(
        ...,
        description="Jumlah mata kuliah yang lulus di Semester 2"
    )
    ukt_lancar: int = Field(
        ...,
        description="Status pembayaran UKT: 0 = Menunggak, 1 = Lancar/Lunas"
    )

    @field_validator("matkul_diambil_sem1", "matkul_diambil_sem2")
    @classmethod
    def validate_matkul_diambil(cls, v: int) -> int:
        if v < 1:
            raise ValueError("Data belum cukup: jumlah mata kuliah diambil minimal 1.")
        return v

    @field_validator("matkul_lulus_sem1", "matkul_lulus_sem2")
    @classmethod
    def validate_matkul_lulus(cls, v: int) -> int:
        if v < 0:
            raise ValueError("Jumlah mata kuliah lulus tidak boleh bernilai negatif.")
        return v

    @field_validator("ips_sem1", "ips_sem2")
    @classmethod
    def validate_ips(cls, v: float) -> float:
        if not (0.0 <= v <= 4.0):
            raise ValueError("Nilai IPS harus berada di antara rentang 0.0 sampai 4.0.")
        return v

    @field_validator("ukt_lancar")
    @classmethod
    def validate_ukt(cls, v: int) -> int:
        if v not in (0, 1):
            raise ValueError("Status UKT harus 0 (Menunggak) atau 1 (Lancar/Lunas).")
        return v

    @model_validator(mode="after")
    def validate_cross_fields(self) -> "StudentPredictionRequest":
        if self.matkul_lulus_sem1 > self.matkul_diambil_sem1:
            raise ValueError(
                "Jumlah mata kuliah lulus Semester 1 tidak boleh melebihi "
                "jumlah mata kuliah yang diambil."
            )
        if self.matkul_lulus_sem2 > self.matkul_diambil_sem2:
            raise ValueError(
                "Jumlah mata kuliah lulus Semester 2 tidak boleh melebihi "
                "jumlah mata kuliah yang diambil."
            )
        return self


class PredictionResponse(BaseModel):
    kode_anonim: str = "MHS-ANON"
    kode_mhs: str = "MHS-ANON"
    nim: str = "-"
    risk_level: str          # "Indikasi Risiko Tinggi", "Indikasi Risiko Sedang", "Indikasi Risiko Rendah"
    risk_percentage: float   # e.g. 78.5 (tetap ada untuk uji fungsional & konsistensi)
    persentase_bulat: int    # e.g. 79 (pembulatan terdekat integer)
    prediction_label: str    # "Indikasi Berisiko Terlambat", "Indikasi Perlu Perhatian", "Indikasi Risiko Rendah"
    penyebab_utama: str      # Ringkasan pemicu risiko
    faktor_pemicu: List[str] # Observasi data faktual
    top_factors: List[str] = Field(default_factory=list) # Kompatibilitas mundur
    recommendations: List[str] = Field(default_factory=list) # Dikosongkan sesuai aturan Dosen PA
    # 6 Fitur Rekayasa Turunan
    rata_rata_ips: float = 0.0
    tren_ips: float = 0.0
    tren_ips_label: str = "0.00 (Stabil)"
    rasio_lulus_sem1_persen: int = 100
    matkul_gagal_sem1: int = 0
    rasio_lulus_sem2_persen: int = 100
    matkul_gagal_sem2: int = 0


class HistoryRecordItem(BaseModel):
    id: int
    kode_mhs: str
    nim: str
    ips_sem1: float
    matkul_diambil_sem1: int
    matkul_lulus_sem1: int
    ips_sem2: float
    matkul_diambil_sem2: int
    matkul_lulus_sem2: int
    ukt_lancar: int
    persentase_bulat: int
    kategori_risiko: str
    penyebab_utama: str
    faktor_pemicu: List[str]
    created_at: str
    # 6 Fitur Rekayasa Turunan
    rata_rata_ips: float = 0.0
    tren_ips: float = 0.0
    tren_ips_label: str = "0.00 (Stabil)"
    rasio_lulus_sem1_persen: int = 100
    matkul_gagal_sem1: int = 0
    rasio_lulus_sem2_persen: int = 100
    matkul_gagal_sem2: int = 0


class HistoryResponse(BaseModel):
    total_mahasiswa: int
    total_rendah: int
    total_sedang: int
    total_tinggi: int
    records: List[HistoryRecordItem]
