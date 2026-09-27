"""Carrega os Parquet de data/raw/ no Postgres.

O Python só faz o COPY das colunas brutas para uma staging temporária;
as conversões ficam em sql/load_hourly_load.sql.
Conexão via variáveis PG* do .env (ver .env.example).
"""

import io
from pathlib import Path

import pandas as pd
import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
LOAD_SQL = ROOT / "sql" / "load_hourly_load.sql"
COLUMNS = ["id_subsistema", "nom_subsistema", "din_instante", "val_cargaenergiahomwmed"]

STAGING_DDL = """
CREATE TEMP TABLE stg_curva_carga (
    id_subsistema text, nom_subsistema text,
    din_instante text, val_cargaenergiahomwmed text
) ON COMMIT DROP
"""


def copy_parquet(cur: psycopg.Cursor, path: Path) -> int:
    df = pd.read_parquet(path, columns=COLUMNS).astype(str)
    buf = io.StringIO()
    df.to_csv(buf, index=False, header=False)
    with cur.copy(f"COPY stg_curva_carga ({', '.join(COLUMNS)}) FROM STDIN (FORMAT csv)") as copy:
        copy.write(buf.getvalue())
    return len(df)


def main() -> None:
    load_dotenv(ROOT / ".env")
    files = sorted(RAW_DIR.glob("CURVA_CARGA_*.parquet"))
    with psycopg.connect() as conn, conn.cursor() as cur:
        cur.execute(STAGING_DDL)
        for path in files:
            print(f"{path.name}: {copy_parquet(cur, path)} linhas em staging")
        cur.execute(LOAD_SQL.read_text())
        print(f"hourly_load: {cur.rowcount} linhas inseridas/atualizadas")


if __name__ == "__main__":
    main()
