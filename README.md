# energy-demand-forecast

Análise end-to-end da demanda de energia elétrica do SIN (Brasil), 2021–2025,
com dados abertos do ONS, PostgreSQL e Power BI.

## Dados

- **Fonte:** [ONS — Portal de Dados Abertos](https://dados.ons.org.br/), dataset
  *Curva de Carga Horária*. Licença CC-BY — dados © ONS.
- Os arquivos **não são versionados**: ficam em `data/` (gitignored) e são
  baixados pelos scripts em `src/`.

## Estrutura

```
data/       dados brutos e intermediários (gitignored)
sql/        DDL e consultas
src/        scripts Python (download, carga)
notebooks/  análises exploratórias
results/    figuras e tabelas geradas
```

## Setup

```bash
uv sync                  # dependências Python
cp .env.example .env     # preencha a senha do Postgres
sudo service postgresql start
```
