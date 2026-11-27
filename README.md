
# GBT Management

Sistema interno de gestão para uma empresa de
confecção de uniformes corporativos.

## Objetivo

Centralizar informações comerciais, operacionais
e financeiras da empresa.

## Tecnologias

- Python
- FastAPI
- SQLAlchemy
- Pydantic
- SQLite
- Uvicorn

## Módulos

- [x] Clientes — consulta e cadastro inicial
- [ ] Pedidos
- [ ] Produção
- [ ] Entregas e ajustes
- [ ] Financeiro
- [ ] Agenda
- [ ] Dashboard

## Configuração do ambiente

Criar o ambiente virtual:

    python -m venv .venv

Ativar no Windows (PowerShell):

    .\.venv\Scripts\Activate.ps1

Instalar as dependências:

    python -m pip install -r backend/requirements.txt

## Banco de dados

Criar um banco de dados de teste vazio:

    python -c "import sqlite3; from pathlib import Path; c = sqlite3.connect('database/gestao_teste.db'); c.executescript(Path('database/schema_01_clientes.sql').read_text(encoding='utf-8')); c.close()"

O banco de dados local não é versionado.
Utilizar SQLite 3.37.0 ou superior.

## Executar a API

Na raiz do projeto:

    python -m uvicorn app.main:app --app-dir backend --reload

## Documentação da API

Swagger UI:

http://127.0.0.1:8000/docs

## Endpoints implementados

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | / | Informações da API |
| GET | /health | Verificação da conexão |
| GET | /clientes | Listar clientes |
| POST | /clientes | Cadastrar cliente |

## Documentação técnica

Consultar o diretório `docs/` para acessar:

- Especificação de requisitos
- Diagrama entidade-relacionamento
- Modelo de dados DBML

## Status

Projeto em desenvolvimento — versão 0.1.0.

A API ainda não possui autenticação.
Utilizar apenas localmente com dados fictícios.

## Licença

Software proprietário de uso interno.
