from fastapi import FastAPI, HTTPException, status
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from .database import engine
from .schemas import ClienteCreate

app = FastAPI(
    title="Gestão de Uniformes API",
    description="API interna de gestão empresarial",
    version="0.1.0"
)

@app.get("/")
def root():
    return {
        "message": "API Gestão de Uniformes",
        "version": "0.1.0"
    }

@app.get("/health")
def health():
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))

    return {
        "status": "online",
        "database": "connected"
    }

@app.get("/clientes", tags=["Clientes"])
def listar_clientes():
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT
                    id,
                    razao_social,
                    nome_fantasia,
                    nome_contato,
                    telefone,
                    email,
                    cidade,
                    uf,
                    ativo
                FROM clientes
                ORDER BY razao_social
            """)
        )

        clientes = [
            dict(row)
            for row in result.mappings()
        ]

    return clientes

@app.get("/clientes/{cliente_id}", tags=["Clientes"])
def buscar_cliente(cliente_id: int):

    query = text("""
        SELECT *
        FROM clientes
        WHERE id = :cliente_id
    """)

    with engine.connect() as conn:
        result = conn.execute(
            query,
            {"cliente_id": cliente_id}
        )

        cliente = result.mappings().one_or_none()

        if cliente is None:
            raise HTTPException(
                status_code=404,
                detail="Cliente não encontrado."
            )

        return dict(cliente)

@app.post("/clientes", tags=["Clientes"], status_code=status.HTTP_201_CREATED)
def criar_cliente(cliente: ClienteCreate):
    
    dados = cliente.model_dump()

    query = text("""
        INSERT INTO clientes (
            razao_social,
            nome_fantasia,
            cnpj,
            nome_contato,
            telefone,
            email,
            cep,
            logradouro,
            numero,
            complemento,
            bairro,
            cidade,
            uf,
            observacoes
        )
        VALUES (
            :razao_social,
            :nome_fantasia,
            :cnpj,
            :nome_contato,
            :telefone,
            :email,
            :cep,
            :logradouro,
            :numero,
            :complemento,
            :bairro,
            :cidade,
            :uf,
            :observacoes
        )
        RETURNING *
    """)

    try:
        with engine.begin() as conn:
            result = conn.execute(query, dados)

            novo_cliente = dict(
                result.mappings().one()
            )

    except IntegrityError as e:
        if "UNIQUE constraint failed: clientes.cnpj" in str(e.orig):
            raise HTTPException(
                status_code=409,
                detail="CNPJ já cadastrado."
            ) from e

        raise HTTPException(
            status_code=400,
            detail="Dados incompatíveis com as restrições do banco."
        ) from e

    return novo_cliente
