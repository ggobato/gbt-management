from pathlib import Path
from sqlalchemy import create_engine, event, URL

BASE_DIR = Path(__file__).resolve().parents[2]

DB_PATH = BASE_DIR / "database" / "gestao_teste.db"

if not DB_PATH.is_file():
    raise FileNotFoundError(
        f"Banco de dados não encontrado: {DB_PATH}"
    )

DATABASE_URL = URL.create(
    drivername="sqlite+pysqlite",
    database=str(DB_PATH)
)

engine = create_engine(
    DATABASE_URL,
    connect_args={
        "check_same_thread": False,
        "timeout": 5
    }
)


@event.listens_for(engine, "connect")
def configure_sqlite(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()

    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute("PRAGMA busy_timeout = 5000")

    cursor.close()
