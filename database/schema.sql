-- GESTAO DE UNIFORMES | SQLite | esquema fisico candidato v0.1
-- Fonte: DER_Gestao_Uniformes.dbml (40 tabelas / 64 FKs).
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


-- ======================================================================
-- 02 | Catalogos e pedidos
-- ======================================================================

CREATE TABLE modelos_uniforme (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE CHECK (length(trim(nome)) > 0),
    descricao TEXT CHECK (length(trim(descricao)) > 0),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
) STRICT;


CREATE TABLE grades_tamanho (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE CHECK (length(trim(nome)) > 0),
    descricao TEXT CHECK (length(trim(descricao)) > 0),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
) STRICT;


CREATE TABLE tamanhos_grade (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    grade_id INTEGER NOT NULL,
    rotulo TEXT NOT NULL CHECK (length(trim(rotulo)) > 0),
    ordem INTEGER NOT NULL CHECK (ordem >= 0),
    UNIQUE (grade_id, rotulo),
    UNIQUE (grade_id, ordem),
    FOREIGN KEY (grade_id) REFERENCES grades_tamanho (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;


CREATE TABLE pedidos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id INTEGER NOT NULL,
    numero TEXT NOT NULL UNIQUE,
    data_aprovacao TEXT NOT NULL,
    entrega_prevista TEXT,
    status TEXT NOT NULL CHECK (length(trim(status)) > 0),
    liberado_em TEXT,
    concluido_em TEXT,
    observacoes TEXT,
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_pedidos_cliente_id ON pedidos (cliente_id);

CREATE TABLE itens_pedido (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    modelo_id INTEGER NOT NULL,
    grade_id INTEGER NOT NULL,
    modelo_snapshot TEXT NOT NULL CHECK (length(trim(modelo_snapshot)) > 0),
    genero TEXT NOT NULL CHECK (genero IN ('masculino', 'feminino', 'unissex')) CHECK (length(trim(genero)) > 0),
    cor TEXT,
    tecido TEXT,
    modelagem TEXT,
    manga TEXT,
    gola TEXT,
    detalhes TEXT,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unit_centavos INTEGER NOT NULL CHECK (preco_unit_centavos >= 0),
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (modelo_id) REFERENCES modelos_uniforme (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (grade_id) REFERENCES grades_tamanho (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_itens_pedido_pedido_id ON itens_pedido (pedido_id);
CREATE INDEX idx_itens_pedido_modelo_id ON itens_pedido (modelo_id);
CREATE INDEX idx_itens_pedido_grade_id ON itens_pedido (grade_id);

CREATE TABLE tamanhos_item (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    tamanho_id INTEGER NOT NULL,
    rotulo_snapshot TEXT NOT NULL CHECK (length(trim(rotulo_snapshot)) > 0),
    quantidade INTEGER NOT NULL CHECK (quantidade >= 0),
    UNIQUE (item_id, tamanho_id),
    FOREIGN KEY (item_id) REFERENCES itens_pedido (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (tamanho_id) REFERENCES tamanhos_grade (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_tamanhos_item_tamanho_id ON tamanhos_item (tamanho_id);

CREATE TABLE pedidos_anexos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    nome_original TEXT NOT NULL CHECK (length(trim(nome_original)) > 0),
    caminho TEXT NOT NULL UNIQUE CHECK (length(trim(caminho)) > 0),
    mime_type TEXT,
    tamanho_bytes INTEGER NOT NULL CHECK (tamanho_bytes >= 0),
    descricao TEXT CHECK (length(trim(descricao)) > 0),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_pedidos_anexos_pedido_id ON pedidos_anexos (pedido_id);

CREATE TABLE pedidos_historico (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    usuario_id INTEGER NOT NULL,
    evento TEXT NOT NULL CHECK (length(trim(evento)) > 0),
    antes_json TEXT,
    depois_json TEXT,
    motivo TEXT CHECK (length(trim(motivo)) > 0),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_pedidos_historico_pedido_id ON pedidos_historico (pedido_id);
CREATE INDEX idx_pedidos_historico_usuario_id ON pedidos_historico (usuario_id);


-- ======================================================================
-- 03 | Financeiro e estimativas
-- ======================================================================

CREATE TABLE formas_pagamento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE CHECK (length(trim(nome)) > 0),
    permite_receber INTEGER NOT NULL CHECK (permite_receber IN (0, 1)),
    permite_pagar INTEGER NOT NULL CHECK (permite_pagar IN (0, 1)),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
) STRICT;


CREATE TABLE categorias_despesa (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE CHECK (length(trim(nome)) > 0),
    grupo TEXT NOT NULL CHECK (length(trim(grupo)) > 0),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
) STRICT;


CREATE TABLE deslocamentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    data TEXT NOT NULL,
    descricao TEXT NOT NULL CHECK (length(trim(descricao)) > 0),
    distancia_m INTEGER NOT NULL CHECK (distancia_m >= 0),
    consumo_mil_km_l INTEGER CHECK (consumo_mil_km_l > 0),
    combustivel_centavos_l INTEGER CHECK (combustivel_centavos_l >= 0),
    desgaste_centavos_km INTEGER CHECK (desgaste_centavos_km >= 0),
    combustivel_estimado_centavos INTEGER CHECK (combustivel_estimado_centavos >= 0),
    desgaste_estimado_centavos INTEGER CHECK (desgaste_estimado_centavos >= 0)
) STRICT;


CREATE TABLE despesas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    categoria_id INTEGER NOT NULL,
    deslocamento_id INTEGER,
    descricao TEXT NOT NULL CHECK (length(trim(descricao)) > 0),
    credor TEXT,
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos >= 0),
    data_competencia TEXT NOT NULL,
    status TEXT NOT NULL CHECK (length(trim(status)) > 0),
    observacoes TEXT,
    FOREIGN KEY (categoria_id) REFERENCES categorias_despesa (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (deslocamento_id) REFERENCES deslocamentos (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_despesas_categoria_id ON despesas (categoria_id);
CREATE INDEX idx_despesas_deslocamento_id ON despesas (deslocamento_id);

CREATE TABLE parcelas_receber (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    numero INTEGER NOT NULL CHECK (numero > 0),
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
    vencimento TEXT,
    referencia TEXT NOT NULL CHECK (length(trim(referencia)) > 0),
    cancelado_em TEXT,
    UNIQUE (pedido_id, numero),
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;


CREATE TABLE recebimentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parcela_id INTEGER NOT NULL,
    forma_id INTEGER NOT NULL,
    usuario_id INTEGER NOT NULL,
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
    data TEXT NOT NULL,
    referencia TEXT CHECK (length(trim(referencia)) > 0),
    estornado_em TEXT,
    motivo_estorno TEXT,
    FOREIGN KEY (parcela_id) REFERENCES parcelas_receber (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (forma_id) REFERENCES formas_pagamento (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_recebimentos_parcela_id ON recebimentos (parcela_id);
CREATE INDEX idx_recebimentos_forma_id ON recebimentos (forma_id);
CREATE INDEX idx_recebimentos_usuario_id ON recebimentos (usuario_id);

CREATE TABLE parcelas_pagar (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    despesa_id INTEGER NOT NULL,
    numero INTEGER NOT NULL CHECK (numero > 0),
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
    vencimento TEXT,
    forma_prevista_id INTEGER,
    cancelado_em TEXT,
    UNIQUE (despesa_id, numero),
    FOREIGN KEY (despesa_id) REFERENCES despesas (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (forma_prevista_id) REFERENCES formas_pagamento (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_parcelas_pagar_forma_prevista_id ON parcelas_pagar (forma_prevista_id);

CREATE TABLE pagamentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parcela_id INTEGER NOT NULL,
    forma_id INTEGER NOT NULL,
    usuario_id INTEGER NOT NULL,
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
    data TEXT NOT NULL,
    referencia TEXT CHECK (length(trim(referencia)) > 0),
    estornado_em TEXT,
    motivo_estorno TEXT,
    FOREIGN KEY (parcela_id) REFERENCES parcelas_pagar (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (forma_id) REFERENCES formas_pagamento (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_pagamentos_parcela_id ON pagamentos (parcela_id);
CREATE INDEX idx_pagamentos_forma_id ON pagamentos (forma_id);
CREATE INDEX idx_pagamentos_usuario_id ON pagamentos (usuario_id);

CREATE TABLE rateios_despesa (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    despesa_id INTEGER NOT NULL,
    pedido_id INTEGER NOT NULL,
    item_id INTEGER,
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos >= 0),
    criterio TEXT,
    FOREIGN KEY (despesa_id) REFERENCES despesas (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (item_id) REFERENCES itens_pedido (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_rateios_despesa_despesa_id ON rateios_despesa (despesa_id);
CREATE INDEX idx_rateios_despesa_pedido_id ON rateios_despesa (pedido_id);
CREATE INDEX idx_rateios_despesa_item_id ON rateios_despesa (item_id);

CREATE TABLE movimentacoes_capital (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id INTEGER NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('aporte', 'retirada')) CHECK (length(trim(tipo)) > 0),
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
    data TEXT NOT NULL,
    observacoes TEXT,
    estornado_em TEXT,
    motivo_estorno TEXT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_movimentacoes_capital_usuario_id ON movimentacoes_capital (usuario_id);

CREATE TABLE estimativas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    versao INTEGER NOT NULL CHECK (versao > 0),
    status TEXT NOT NULL CHECK (length(trim(status)) > 0),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    UNIQUE (pedido_id, versao),
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;


CREATE TABLE itens_estimativa (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    estimativa_id INTEGER NOT NULL,
    item_id INTEGER,
    categoria_id INTEGER NOT NULL,
    descricao TEXT NOT NULL CHECK (length(trim(descricao)) > 0),
    unidade TEXT NOT NULL CHECK (length(trim(unidade)) > 0),
    quantidade_milesimos INTEGER NOT NULL CHECK (quantidade_milesimos >= 0),
    preco_unit_centavos INTEGER NOT NULL CHECK (preco_unit_centavos >= 0),
    total_centavos INTEGER NOT NULL CHECK (total_centavos >= 0),
    FOREIGN KEY (estimativa_id) REFERENCES estimativas (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (item_id) REFERENCES itens_pedido (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (categoria_id) REFERENCES categorias_despesa (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_itens_estimativa_estimativa_id ON itens_estimativa (estimativa_id);
CREATE INDEX idx_itens_estimativa_item_id ON itens_estimativa (item_id);
CREATE INDEX idx_itens_estimativa_categoria_id ON itens_estimativa (categoria_id);


-- ======================================================================
-- 04 | Materiais, servicos e producao
-- ======================================================================

CREATE TABLE materiais_pedido (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    item_id INTEGER,
    tamanho_item_id INTEGER,
    descricao TEXT NOT NULL CHECK (length(trim(descricao)) > 0),
    unidade TEXT NOT NULL CHECK (length(trim(unidade)) > 0),
    cor TEXT,
    largura_mm INTEGER CHECK (largura_mm > 0),
    consumo_unit_milesimos INTEGER CHECK (consumo_unit_milesimos > 0),
    perda_bp INTEGER NOT NULL DEFAULT 0 CHECK (perda_bp BETWEEN 0 AND 10000),
    quantidade_prevista_milesimos INTEGER NOT NULL CHECK (quantidade_prevista_milesimos >= 0),
    preco_previsto_centavos INTEGER CHECK (preco_previsto_centavos >= 0),
    observacoes TEXT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (item_id) REFERENCES itens_pedido (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (tamanho_item_id) REFERENCES tamanhos_item (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (tamanho_item_id IS NULL OR item_id IS NOT NULL)
) STRICT;

CREATE INDEX idx_materiais_pedido_pedido_id ON materiais_pedido (pedido_id);
CREATE INDEX idx_materiais_pedido_item_id ON materiais_pedido (item_id);
CREATE INDEX idx_materiais_pedido_tamanho_item_id ON materiais_pedido (tamanho_item_id);

CREATE TABLE compras_materiais (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    despesa_id INTEGER NOT NULL UNIQUE,
    fornecedor TEXT,
    data_compra TEXT NOT NULL,
    documento TEXT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (despesa_id) REFERENCES despesas (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_compras_materiais_pedido_id ON compras_materiais (pedido_id);

CREATE TABLE itens_compra (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    compra_id INTEGER NOT NULL,
    descricao TEXT NOT NULL CHECK (length(trim(descricao)) > 0),
    unidade TEXT NOT NULL CHECK (length(trim(unidade)) > 0),
    cor TEXT,
    largura_mm INTEGER CHECK (largura_mm > 0),
    quantidade_milesimos INTEGER NOT NULL CHECK (quantidade_milesimos > 0),
    valor_total_centavos INTEGER NOT NULL CHECK (valor_total_centavos >= 0),
    FOREIGN KEY (compra_id) REFERENCES compras_materiais (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_itens_compra_compra_id ON itens_compra (compra_id);

CREATE TABLE consumos_material (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_compra_id INTEGER NOT NULL,
    material_pedido_id INTEGER NOT NULL,
    data TEXT NOT NULL,
    quantidade_milesimos INTEGER NOT NULL CHECK (quantidade_milesimos > 0),
    tipo TEXT NOT NULL CHECK (length(trim(tipo)) > 0),
    valor_centavos INTEGER NOT NULL CHECK (valor_centavos >= 0),
    FOREIGN KEY (item_compra_id) REFERENCES itens_compra (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (material_pedido_id) REFERENCES materiais_pedido (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_consumos_material_item_compra_id ON consumos_material (item_compra_id);
CREATE INDEX idx_consumos_material_material_pedido_id ON consumos_material (material_pedido_id);

CREATE TABLE prestadores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL CHECK (length(trim(nome)) > 0),
    telefone TEXT,
    email TEXT,
    observacoes TEXT,
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
) STRICT;


CREATE TABLE tipos_servico (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE CHECK (length(trim(nome)) > 0),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
) STRICT;


CREATE TABLE servicos_producao (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    prestador_id INTEGER NOT NULL,
    tipo_servico_id INTEGER NOT NULL,
    despesa_id INTEGER UNIQUE,
    data_inicio TEXT,
    prazo TEXT,
    concluido_em TEXT,
    status TEXT NOT NULL CHECK (length(trim(status)) > 0),
    observacoes TEXT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (prestador_id) REFERENCES prestadores (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (tipo_servico_id) REFERENCES tipos_servico (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (despesa_id) REFERENCES despesas (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_servicos_producao_pedido_id ON servicos_producao (pedido_id);
CREATE INDEX idx_servicos_producao_prestador_id ON servicos_producao (prestador_id);
CREATE INDEX idx_servicos_producao_tipo_servico_id ON servicos_producao (tipo_servico_id);

CREATE TABLE lotes_producao (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tamanho_item_id INTEGER NOT NULL,
    codigo TEXT NOT NULL UNIQUE CHECK (length(trim(codigo)) > 0),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    FOREIGN KEY (tamanho_item_id) REFERENCES tamanhos_item (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_lotes_producao_tamanho_item_id ON lotes_producao (tamanho_item_id);

CREATE TABLE itens_servico (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    servico_id INTEGER NOT NULL,
    lote_id INTEGER NOT NULL,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unit_centavos INTEGER NOT NULL CHECK (preco_unit_centavos >= 0),
    FOREIGN KEY (servico_id) REFERENCES servicos_producao (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (lote_id) REFERENCES lotes_producao (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_itens_servico_servico_id ON itens_servico (servico_id);
CREATE INDEX idx_itens_servico_lote_id ON itens_servico (lote_id);

CREATE TABLE posicoes_peca (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL CHECK (length(trim(nome)) > 0),
    tipo TEXT NOT NULL CHECK (length(trim(tipo)) > 0),
    etapa TEXT NOT NULL CHECK (length(trim(etapa)) > 0),
    prestador_id INTEGER,
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
    FOREIGN KEY (prestador_id) REFERENCES prestadores (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_posicoes_peca_prestador_id ON posicoes_peca (prestador_id);

CREATE TABLE modelos_tarefa (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo TEXT NOT NULL CHECK (length(trim(titulo)) > 0),
    categoria TEXT,
    ordem INTEGER NOT NULL CHECK (ordem >= 0),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
) STRICT;


CREATE TABLE tarefas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    modelo_tarefa_id INTEGER,
    responsavel_id INTEGER,
    titulo TEXT NOT NULL CHECK (length(trim(titulo)) > 0),
    categoria TEXT,
    prazo TEXT,
    status TEXT NOT NULL CHECK (length(trim(status)) > 0),
    concluido_em TEXT,
    observacoes TEXT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (modelo_tarefa_id) REFERENCES modelos_tarefa (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (responsavel_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_tarefas_pedido_id ON tarefas (pedido_id);
CREATE INDEX idx_tarefas_modelo_tarefa_id ON tarefas (modelo_tarefa_id);
CREATE INDEX idx_tarefas_responsavel_id ON tarefas (responsavel_id);

CREATE TABLE ocorrencias_producao (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lote_id INTEGER NOT NULL,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    descricao TEXT NOT NULL CHECK (length(trim(descricao)) > 0),
    solucao TEXT,
    responsabilidade_custo TEXT CHECK (length(trim(responsabilidade_custo)) > 0),
    status TEXT NOT NULL CHECK (length(trim(status)) > 0),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lote_id) REFERENCES lotes_producao (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_ocorrencias_producao_lote_id ON ocorrencias_producao (lote_id);

CREATE TABLE rateios_deslocamento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deslocamento_id INTEGER NOT NULL,
    pedido_id INTEGER NOT NULL,
    proporcao_bp INTEGER NOT NULL CHECK (proporcao_bp BETWEEN 1 AND 10000),
    UNIQUE (deslocamento_id, pedido_id),
    FOREIGN KEY (deslocamento_id) REFERENCES deslocamentos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_rateios_deslocamento_pedido_id ON rateios_deslocamento (pedido_id);


-- ======================================================================
-- 05 | Entregas, ajustes e movimentos
-- ======================================================================

CREATE TABLE entregas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    data TEXT NOT NULL,
    destino TEXT,
    observacoes TEXT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_entregas_pedido_id ON entregas (pedido_id);

CREATE TABLE ajustes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lote_id INTEGER NOT NULL,
    entrega_id INTEGER,
    prestador_id INTEGER,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    motivo TEXT NOT NULL CHECK (length(trim(motivo)) > 0),
    referencia TEXT CHECK (length(trim(referencia)) > 0),
    responsabilidade_custo TEXT NOT NULL CHECK (length(trim(responsabilidade_custo)) > 0),
    prazo TEXT,
    status TEXT NOT NULL CHECK (length(trim(status)) > 0),
    criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lote_id) REFERENCES lotes_producao (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (entrega_id) REFERENCES entregas (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (prestador_id) REFERENCES prestadores (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX idx_ajustes_lote_id ON ajustes (lote_id);
CREATE INDEX idx_ajustes_entrega_id ON ajustes (entrega_id);
CREATE INDEX idx_ajustes_prestador_id ON ajustes (prestador_id);

CREATE TABLE movimentacoes_lote (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lote_id INTEGER NOT NULL,
    origem_id INTEGER,
    destino_id INTEGER,
    item_servico_id INTEGER,
    entrega_id INTEGER,
    ajuste_id INTEGER,
    ocorrencia_id INTEGER,
    usuario_id INTEGER NOT NULL,
    tipo TEXT NOT NULL CHECK (length(trim(tipo)) > 0),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    data TEXT NOT NULL,
    observacoes TEXT,
    FOREIGN KEY (lote_id) REFERENCES lotes_producao (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (origem_id) REFERENCES posicoes_peca (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (destino_id) REFERENCES posicoes_peca (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (item_servico_id) REFERENCES itens_servico (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (entrega_id) REFERENCES entregas (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (ajuste_id) REFERENCES ajustes (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (ocorrencia_id) REFERENCES ocorrencias_producao (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (origem_id IS NOT NULL OR destino_id IS NOT NULL),
    CHECK (origem_id IS NULL OR destino_id IS NULL OR origem_id <> destino_id)
) STRICT;

CREATE INDEX idx_movimentacoes_lote_lote_id ON movimentacoes_lote (lote_id);
CREATE INDEX idx_movimentacoes_lote_origem_id ON movimentacoes_lote (origem_id);
CREATE INDEX idx_movimentacoes_lote_destino_id ON movimentacoes_lote (destino_id);
CREATE INDEX idx_movimentacoes_lote_item_servico_id ON movimentacoes_lote (item_servico_id);
CREATE INDEX idx_movimentacoes_lote_entrega_id ON movimentacoes_lote (entrega_id);
CREATE INDEX idx_movimentacoes_lote_ajuste_id ON movimentacoes_lote (ajuste_id);
CREATE INDEX idx_movimentacoes_lote_ocorrencia_id ON movimentacoes_lote (ocorrencia_id);
CREATE INDEX idx_movimentacoes_lote_usuario_id ON movimentacoes_lote (usuario_id);

COMMIT;

-- REGRAS QUE EXIGEM VALIDACAO TRANSACIONAL (nao implementadas aqui)
-- 1. Tamanho da mesma grade do item; soma da grade <= quantidade contratada.
-- 2. Todas as referencias opcionais devem pertencer ao mesmo pedido/lote.
-- 3. Parcelas ativas somam o valor contratado ou o valor da despesa;
--    recebimentos/pagamentos validos nao excedem saldo; formas compativeis.
-- 4. Liberacao de producao somente apos quitacao integral da entrada.
-- 5. Movimentos de lote: saldo nao negativo por posicao; reposicao e descarte
--    nao alteram quantidade comercial; entrega/recolhimento usam o mesmo livro.
-- 6. Consumo de material nao excede saldo comprado; sobras a custo historico;
--    nao contar compra e consumo duas vezes. Rateios sem duplicidade.
-- 7. Servico concluido gera obrigacao, nao pagamento. Despesas de transporte
--    reais e estimadas devem ser analisadas separadamente.
-- 8. Estimativas/versionamento, estornos, cancelamentos e historico de mudancas;
--    atualizado_em deve ser atualizado pela aplicacao. Sem delecao financeira.
-- 9. Validar CNPJ, UF, formatos ISO, caminhos de anexos e transicoes de status.
-- 10. Relatorios, saldos e indicadores serao consultas/views em etapa posterior.
