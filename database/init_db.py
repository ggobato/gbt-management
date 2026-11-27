import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "gestao_teste.db"
SCHEMA_PATH = BASE_DIR / "schema.sql"


def init_db():
    conn = sqlite3.connect(DB_PATH)

    try:
        conn.execute("PRAGMA foreign_keys = ON")
        conn.execute("PRAGMA journal_mode = WAL")
        conn.execute("PRAGMA busy_timeout = 5000")

        schema = SCHEMA_PATH.read_text(encoding="utf-8")

        conn.executescript(schema)
        conn.commit()

        print("Banco de dados criado com sucesso!")
        print(f"Local: {DB_PATH}")

    finally:
        conn.close()


if __name__ == "__main__":
    init_db()
