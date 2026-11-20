"""
Runs the whole project end to end with DuckDB (no database server needed):

  1. creates the table and loads data/instagram_posts.csv
  2. runs the data quality checks        -> outputs/data_quality/*.csv
  3. builds the star schema views
  4. runs the analysis queries           -> outputs/analysis/*.csv
  5. exports the model for Power BI      -> powerbi/data/*.csv

Usage (from the repo root):
    python scripts/run_pipeline.py
"""

import os
import re
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "sql"
DB_PATH = ROOT / "instagram.duckdb"

# which SQL file writes its query results to which folder
OUTPUT_DIRS = {
    "02_load_data.sql": None,
    "03_data_quality_checks.sql": ROOT / "outputs" / "data_quality",
    "04_data_model.sql": None,
    "05_analysis.sql": ROOT / "outputs" / "analysis",
}
POWERBI_DIR = ROOT / "powerbi" / "data"


def split_statements(sql_text):
    """Split a SQL file into (name, statement) pairs.

    A statement gets a name when it is preceded by a '-- @name: xxx' comment.
    Comments are kept inside the statement, DuckDB ignores them.
    """
    statements = []
    name = None
    buffer = []

    for line in sql_text.splitlines():
        tag = re.match(r"^\s*--\s*@name:\s*(\w+)", line)
        if tag:
            name = tag.group(1)
            continue
        buffer.append(line)
        if line.rstrip().endswith(";"):
            statement = "\n".join(buffer).strip()
            # skip chunks that are only comments
            if any(l.strip() and not l.strip().startswith("--") for l in buffer):
                statements.append((name, statement))
            buffer = []
            name = None

    return statements


def run_file(con, path):
    out_dir = OUTPUT_DIRS.get(path.name)
    print(f"\n== {path.name}")

    for name, statement in split_statements(path.read_text(encoding="utf-8")):
        if name is None:
            con.execute(statement)
            continue

        result = con.sql(statement.rstrip(";"))
        rows = result.fetchall()
        print(f"   {name:<40} {len(rows):>5} rows")

        if out_dir is not None:
            out_dir.mkdir(parents=True, exist_ok=True)
            result.write_csv(str(out_dir / f"{name}.csv"))
        elif len(rows) == 1:
            print(f"   -> {dict(zip(result.columns, rows[0]))}")


def export_powerbi_tables(con):
    POWERBI_DIR.mkdir(parents=True, exist_ok=True)
    print("\n== Power BI export")
    for table in ["fact_posts", "dim_account"]:
        out = POWERBI_DIR / f"{table}.csv"
        con.sql(f"SELECT * FROM {table}").write_csv(str(out))
        print(f"   {table:<40} -> {out.relative_to(ROOT)}")


def main():
    # SQL files use paths relative to the repo root
    os.chdir(ROOT)

    if DB_PATH.exists():
        DB_PATH.unlink()
    con = duckdb.connect(str(DB_PATH))

    for path in sorted(SQL_DIR.glob("*.sql")):
        run_file(con, path)

    export_powerbi_tables(con)
    con.close()
    print(f"\nDone. Database saved to {DB_PATH.name} (open it with the DuckDB CLI to explore).")


if __name__ == "__main__":
    main()
