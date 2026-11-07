"""
Membuang rekaman uji (MHS-999 / NIM 2026999001) dari pathgrad.db.
Jalankan dari folder backend/:  python cleanup_uji.py
"""
import os
import sqlite3

DB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pathgrad.db")
if not os.path.exists(DB):
    raise SystemExit(f"pathgrad.db tidak ditemukan di {DB}")

c = sqlite3.connect(DB)
sebelum = c.execute("SELECT COUNT(*) FROM riwayat_skrining").fetchone()[0]
c.execute("DELETE FROM riwayat_skrining WHERE nim = ?", ("2026999001",))
c.commit()
sesudah = c.execute("SELECT COUNT(*) FROM riwayat_skrining").fetchone()[0]
c.close()
print(f"Rekaman sebelum: {sebelum} | sesudah: {sesudah} | dihapus: {sebelum - sesudah}")
