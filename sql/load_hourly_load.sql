-- Transforma a staging (colunas brutas do ONS, tudo texto) nas tabelas finais.
-- Executado por src/load.py após o COPY para stg_curva_carga. Idempotente.
--
-- Conversões:
--   din_instante: timestamp sem fuso do ONS, interpretado como America/Sao_Paulo.
--   val_cargaenergiahomwmed: texto em 2021–2024 (até 8 casas), double em 2025;
--     arredondado para 3 casas (erro máx. 0,0005 MW).

INSERT INTO subsystem (subsystem_id, name)
SELECT DISTINCT id_subsistema, nom_subsistema
FROM stg_curva_carga
ON CONFLICT (subsystem_id) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO hourly_load (subsystem_id, measured_at, load_mwavg)
SELECT id_subsistema,
       din_instante::timestamp AT TIME ZONE 'America/Sao_Paulo',
       round(val_cargaenergiahomwmed::numeric, 3)
FROM stg_curva_carga
ON CONFLICT (subsystem_id, measured_at) DO UPDATE SET load_mwavg = EXCLUDED.load_mwavg;
