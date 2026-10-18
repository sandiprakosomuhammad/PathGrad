from pydantic import BaseModel, Field, field_validator, model_validator
from typing import List


class StudentPredictionRequest(BaseModel):
    kode_anonim: str = Field(
        default="MHS-ANON",
        description="Kode pencatatan anonim tanpa nama/NIM asli"
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
    risk_level: str          # "Indikasi Risiko Tinggi", "Indikasi Risiko Sedang", "Indikasi Risiko Rendah"
    risk_percentage: float   # e.g. 78.5
    prediction_label: str    # "Indikasi Berisiko Terlambat", "Indikasi Perlu Perhatian", "Indikasi Sesuai Jalur (Aman)"
    top_factors: List[str]
    recommendations: List[str]
