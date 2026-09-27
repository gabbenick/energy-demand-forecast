-- Validações pós-carga de hourly_load. Todas as checagens de "problema" devem dar 0.
\pset footer off

\echo '== Total de linhas e intervalo (horário de Brasília) =='
SELECT count(*) AS rows,
       min(measured_at AT TIME ZONE 'America/Sao_Paulo') AS first_hour_brt,
       max(measured_at AT TIME ZONE 'America/Sao_Paulo') AS last_hour_brt
FROM hourly_load;

\echo '== Linhas por subsistema =='
SELECT subsystem_id, count(*) AS rows FROM hourly_load GROUP BY 1 ORDER BY 1;

\echo '== Nulos (esperado 0) =='
SELECT count(*) FILTER (WHERE subsystem_id IS NULL) AS null_subsystem,
       count(*) FILTER (WHERE measured_at IS NULL)  AS null_measured_at,
       count(*) FILTER (WHERE load_mwavg IS NULL)   AS null_load
FROM hourly_load;

\echo '== Duplicatas na PK (esperado 0) =='
SELECT count(*) AS duplicate_keys
FROM (SELECT 1 FROM hourly_load GROUP BY subsystem_id, measured_at HAVING count(*) > 1) d;

\echo '== Horas faltantes por subsistema, 2021-01-01 a 2025-12-31 (esperado 0) =='
WITH expected AS (
    SELECT s.subsystem_id, h AS measured_at
    FROM subsystem s
    CROSS JOIN generate_series(
        timestamp '2021-01-01 00:00' AT TIME ZONE 'America/Sao_Paulo',
        timestamp '2025-12-31 23:00' AT TIME ZONE 'America/Sao_Paulo',
        interval '1 hour') h
)
SELECT e.subsystem_id, count(*) FILTER (WHERE l.measured_at IS NULL) AS missing_hours
FROM expected e
LEFT JOIN hourly_load l USING (subsystem_id, measured_at)
GROUP BY 1 ORDER BY 1;

\echo '== Horas do SIN com subsistemas faltando (esperado 0) =='
SELECT count(*) AS incomplete_sin_hours FROM sin_hourly_load WHERE n_subsystems <> 4;
