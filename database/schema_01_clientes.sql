-- GESTAO DE UNIFORMES | SQLite | recorte inicial v0.1 (3 tabelas)
-- Fonte: DER_Gestao_Uniformes.dbml (recorte de fundacao e clientes).
-- Requer SQLite >= 3.37.0 (STRICT). Executar somente em banco NOVO de teste.
-- Nao e migracao de banco existente. Sem dados iniciais, API ou interface.
-- Dinheiro: centavos; quantidades fracionarias: milesimos da unidade;
-- distancias: metros; larguras: milimetros; *_bp: pontos-base (10000 = 100%).
-- Datas: ISO 8601 em TEXT; timestamps automaticos em UTC.
-- PRAGMA foreign_keys e busy_timeout devem ser configurados a cada conexao.
-- Estados de fluxo, formatos de datas e regras entre registros: validar na API.
-- Nao sincronizar o arquivo .db ativo com a nuvem ou rede compartilhada.

PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 5000;
PRAGMA journal_mode = WAL;

BEGIN IMMEDIATE;


-- ======================================================================
-- 01 | Fundacao e clientes
-- ======================================================================

CREATE TABLE usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL CHECK (length(trim(nome)) > 0),
    login TEXT NOT NULL UNIQUE CHECK (length(trim(login)) > 0),
    senha_hash TEXT NOT NULL CHECK (length(trim(senha_hash)) > 0),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
) STRICT;


CREATE TABLE clientes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    razao_social TEXT NOT NULL CHECK (length(trim(razao_social)) > 0),
    nome_fantasia TEXT,
    cnpj TEXT UNIQUE CHECK (length(cnpj) = 14 AND cnpj NOT GLOB '*[^0-9A-Z]*' AND substr(cnpj, 13, 2) NOT GLOB '*[^0-9]*'),
    nome_contato TEXT,
    telefone TEXT,
    email TEXT,
    cep TEXT CHECK (length(cep) = 8 AND cep NOT GLOB '*[^0-9]*'),
    logradouro TEXT,
    numero TEXT,
    complemento TEXT,
    bairro TEXT,
    cidade TEXT,
    uf TEXT CHECK (uf IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO')),
    observacoes TEXT,
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
) STRICT;

CREATE INDEX idx_clientes_razao_social ON clientes (razao_social);
CREATE INDEX idx_clientes_nome_fantasia ON clientes (nome_fantasia);

CREATE TABLE clientes_anexos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id INTEGER NOT NULL,
    nome_original TEXT NOT NULL CHECK (length(trim(nome_original)) > 0),
    caminho TEXT NOT NULL UNIQUE CHECK (length(trim(caminho)) > 0),
    mime_type TEXT,
    tamanho_bytes INTEGER NOT NULL CHECK (tamanho_bytes >= 0),
    descricao TEXT CHECK (length(trim(descricao)) > 0),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_clientes_anexos_cliente_id ON clientes_anexos (cliente_id);

COMMIT;
