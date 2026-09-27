# CLAUDE.md

## Projeto
- energy-demand-forecast: análise end-to-end da demanda de energia do SIN (Sistema
  Interligado Nacional, Brasil).
- Objetivo: prever demanda horária por subsistema e identificar risco de sobrecarga.
- É um projeto de PORTFÓLIO. O objetivo pedagógico é o usuário aprender SQL e
  Power BI (as lacunas dele); ML ele já domina.

## Dados
- Fonte: ONS Portal de Dados Abertos, dataset "Curva de Carga Horária".
- Licença: CC-BY. Exige atribuição ao ONS e declaração de alterações feitas.
- Recorte: 2021–2025, 5 anos, formato Parquet, 4 subsistemas (N, NE, S, SE).
- Granularidade: horária, horário de Brasília. Sem horário de verão (fim em 2019).
- Peculiaridade da fonte: a carga vem como texto (até 8 casas) em 2021–2024 e
  double em 2025; a carga arredonda para numeric(10,3) (erro máx. 0,0005 MW).

## Ambiente
- WSL2, Python (projeto uv), PostgreSQL 16.
- Banco: energy_demand. Usuário: energy. Conecta via: psql -h localhost -U energy -d energy_demand
- Iniciar Postgres: sudo service postgresql start
- Power BI roda no Windows (não no WSL), conecta no Postgres via localhost, modo Import.

## Pipeline (boilerplate existente)
- `uv run python src/download.py` — baixa os Parquet para data/raw/.
- `psql -f sql/schema.sql` — DDL (tabelas + view sin_hourly_load).
- `uv run python src/load.py` — COPY bruto para staging; transformação em
  sql/load_hourly_load.sql. Idempotente (ON CONFLICT).
- `psql -f sql/validate.sql` — checagens pós-carga.
- Conexão via variáveis PG* do .env (ver .env.example).

## Decisões de arquitetura (já tomadas — NÃO reabrir)
- measured_at é timestamptz, interpretado como America/Sao_Paulo.
- Tabela hourly_load: PK composta (subsystem_id, measured_at), índice em measured_at.
- Tabela subsystem: (subsystem_id, name).
- View sin_hourly_load: soma dos 4 subsistemas por measured_at (carga total do SIN).
- PRINCÍPIO CENTRAL: a transformação pesada mora no SQL (views, agregações),
  não no pandas. As features temporais serão calculadas em SQL.
- Modelagem ML (quando chegar): split LEAVE-ONE-SUBJECT-OUT ou por bloco temporal,
  NUNCA train_test_split aleatório por amostra (causa vazamento temporal).
  Métrica: comparar contra baseline sazonal honesto.

## Regras invioláveis
- Dados NUNCA vão para o git (data/ e *.parquet no .gitignore).
- Nenhuma credencial no código. Só em .env (gitignored).
- Repo é público e limpo.

## DIVISÃO DE TRABALHO (importante)
- O SQL analítico (queries de análise, views de features, queries que respondem
  perguntas de negócio) é escrito PELO USUÁRIO À MÃO, para ele aprender SQL.
  NÃO escreva essas queries por ele. Quando ele pedir ajuda com SQL, explique o
  conceito e revise o que ele escreveu — não entregue a query pronta.
- Você (Claude Code) faz o boilerplate: setup, ingestão de dados, conexão,
  scripts de infraestrutura. Isso pode escrever normalmente.

## Estado atual (2026-09-27)
- Fases 0 e 1 concluídas: repo criado, Postgres configurado, schema aplicado.
- 5 anos (2021–2025) carregados e validados: 175.296 linhas, zero nulos, zero
  buracos, zero duplicatas, fuso conferido, carga idempotente.
- View sin_hourly_load criada e testada (média anual do SIN 68–80 GW, ordem de
  grandeza coerente; não foi cruzada com números oficiais do ONS).
- PRÓXIMO PASSO: o usuário vai escrever à mão a view de features temporais
  (hora, dia da semana, mês, ano, flag de fim de semana) sobre hourly_load.
  Não escreva essa view — ele está escrevendo.
