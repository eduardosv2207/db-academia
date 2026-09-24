CREATE TABLE aluno(
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
------------------------------------------------------------------------

CREATE TABLE planos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) UNIQUE NOT NULL,
    valor_mensal_base DECIMAL(10,2) CHECK (valor_mensal_base > 0) NOT NULL
);

------------------------------------------------------------------------

CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    plano_id INT REFERENCES planos(id),
    nome VARCHAR(150) NOT NULL,
    sala VARCHAR(20) NOT NULL,
    capacidade_maxima INT CHECK (capacidade_maxima > 0) NOT NULL,
    disponivel BOOLEAN DEFAULT TRUE
);
------------------------------------------------------------------------
CREATE TABLE matriculas (
    id SERIAL PRIMARY KEY,
    aluno_id INT REFERENCES aluno(id),
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Ativa' CHECK (status IN ('Ativa', 'Cancelada', 'Trancada'))
);
------------------------------------------------------------------------
CREATE TABLE itens_matricula (
    id SERIAL PRIMARY KEY,
    matricula_id INT REFERENCES matriculas(id),
    modalidade_id INT REFERENCES modalidades(id),
    duracao_meses INT CHECK (duracao_meses > 0) NOT NULL,
    valor_mensal_aplicado DECIMAL(10,2) CHECK (valor_mensal_aplicado > 0) NOT NULL,
    taxa_adesao DECIMAL(10,2) CHECK (taxa_adesao >= 0) DEFAULT 0.00
);
------------------------------------------------------------------------
INSERT INTO planos (nome, valor_mensal_base) VALUES 
('VIP Premium', 220.00), 
('Fitness Standard', 140.00), 
('Basic Fit', 90.00);
------------------------------------------------------------------------
INSERT INTO modalidades (plano_id, nome, sala, capacidade_maxima, disponivel) VALUES 
(1, 'Crossfit Pro', 'Arena 01', 15, TRUE),
(2, 'Pilates Avançado', 'Studio 02', 10, TRUE),
(3, 'Musculação Livre', 'Salão Principal', 50, TRUE);
------------------------------------------------------------------------
INSERT INTO aluno (nome, email, cpf, telefone) VALUES 
('Carlos Silva', 'carlos@email.com', '11122233344', '11999990000'),
('Ana Lima', 'ana@email.com', '22233344455', '11988880000'),
('Beatriz Costa', 'bea@email.com', '33344455566', '11977770000');
------------------------------------------------------------------------
INSERT INTO matriculas (aluno_id, status) VALUES 
(1, 'Ativa'), 
(1, 'Ativa'), 
(2, 'Ativa'), 
(3, 'Cancelada');
------------------------------------------------------------------------
INSERT INTO itens_matricula (matricula_id, modalidade_id, duracao_meses, valor_mensal_aplicado, taxa_adesao) VALUES 
(1, 1, 6, 220.00, 50.00),
(2, 2, 3, 140.00, 30.00),
(3, 3, 12, 90.00, 0.00),
(4, 1, 1, 220.00, 50.00);
------------------------------------------------------------------------
-- Q1
CREATE VIEW  vw_modalidades_custo_estimado as 
	SELECT
	modalidades.nome as modalidade,
	modalidades.sala,
	planos.nome as plano,
	planos.valor_mensal_base * 1.10 as valor_ajustado
	FROM modalidades
	JOIN planos ON modalidades.plano_id = planos.id
	ORDER BY valor_ajustado DESC
------------------------------------------------------------------------
-- Q2
	SELECT
	aluno.nome as nome,
	aluno.cpf,
	modalidades.nome as modalidade,
	modalidades.sala,
	itens_matricula.duracao_meses,
	matriculas.data_inicio
	from matriculas
	join aluno on aluno.id = matriculas.aluno_id
	join itens_matricula on itens_matricula.id = matriculas.id
	join modalidades on itens_matricula.modalidade_id = modalidades.id
	WHERE matriculas.status = 'Ativa';
------------------------------------------------------------------------
-- Q3
	CREATE  VIEW vw_alunos_vip as
	SELECT
	aluno.nome as nome,
	COUNT(matriculas.id) AS contratos_ativos,
	  SUM(
        (itens_matricula.valor_mensal_aplicado * itens_matricula.duracao_meses)
        + itens_matricula.taxa_adesao) AS valor_total
	from aluno
	JOIN matriculas ON matriculas.aluno_id = aluno.id
	JOIN itens_matricula on itens_matricula.id = aluno.id
	WHERE matriculas.status = 'Ativa'
	GROUP BY aluno.id, aluno.nome
	HAVING SUM(
    (itens_matricula.valor_mensal_aplicado * itens_matricula.duracao_meses)
    + itens_matricula.taxa_adesao) > 1000
------------------------------------------------------------------------
-- Q4
	SELECT 
    modalidades.*,
    planos.nome AS plano,
    planos.valor_mensal_base
	FROM modalidades
	JOIN planos ON modalidades.plano_id = planos.id
	WHERE modalidades.capacidade_maxima >= 15
	AND planos.valor_mensal_base > 100.00
	AND modalidades.disponivel = TRUE;
------------------------------------------------------------------------
-- Q5
    CREATE VIEW vw_faturamento_medio_plano AS
    SELECT
    planos.nome AS plano,
    SUM(
        (itens_matricula.valor_mensal_aplicado * itens_matricula.duracao_meses)
        + itens_matricula.taxa_adesao) AS faturamento_total,
    AVG(itens_matricula.duracao_meses) AS media_duracao_meses
    FROM planos
    JOIN modalidades ON modalidades.plano_id = planos.id
    JOIN itens_matricula ON itens_matricula.modalidade_id = modalidades.id
    JOIN matriculas ON itens_matricula.matricula_id = matriculas.id
    WHERE matriculas.status = 'Ativa'
    GROUP BY planos.id, planos.nome;