import pandas as pd, numpy as np
from app.ml_model import make_features, model_instance
df = pd.read_csv("sampel_uji_konsistensi.csv")
cols = [c for c in df.columns if c != "skor_notebook"]
p = model_instance.predict_proba(make_features(df[cols]))[:, 1]
d = np.abs(p - df["skor_notebook"].values)
print("selisih maks langsung dari model:", d.max())
print(df.assign(skor_model=p, selisih=d).loc[d > 1e-6])