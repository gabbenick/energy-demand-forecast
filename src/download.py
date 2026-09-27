"""Baixa os Parquet anuais da Curva de Carga Horária do ONS para data/raw/."""

import sys
import urllib.request
from pathlib import Path

BASE_URL = "https://ons-aws-prod-opendata.s3.amazonaws.com/dataset/curva-carga-ho"
RAW_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"
YEARS = range(2021, 2026)


def download(year: int, force: bool = False) -> Path:
    dest = RAW_DIR / f"CURVA_CARGA_{year}.parquet"
    if dest.exists() and not force:
        print(f"{dest.name}: já existe, pulando")
        return dest
    tmp = dest.with_suffix(".part")
    urllib.request.urlretrieve(f"{BASE_URL}/{dest.name}", tmp)
    tmp.rename(dest)
    print(f"{dest.name}: {dest.stat().st_size / 1024:.0f} KB")
    return dest


if __name__ == "__main__":
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    for year in YEARS:
        download(year, force="--force" in sys.argv)
