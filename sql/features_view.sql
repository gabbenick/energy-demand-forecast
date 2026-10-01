-- View materializada hourly_load_features:
-- features temporais (hora, mês, ano, dia da semana, fim de semana) derivadas
-- de measured_at, sobre hourly_load.
-- MATERIALIZED: resultado guardado (dados-base estáticos, leitura frequente).
-- IMPORTANTE: rodar REFRESH MATERIALIZED VIEW hourly_load_features
-- sempre que hourly_load receber dados novos.

DROP MATERIALIZED VIEW IF EXISTS hourly_load_features;

CREATE MATERIALIZED VIEW hourly_load_features AS
SELECT
    *,
    EXTRACT(HOUR FROM measured_at)::integer AS hour_of_day,
    EXTRACT(MONTH FROM measured_at)::integer AS month_of_year,
    EXTRACT(YEAR FROM measured_at)::integer AS year,
    EXTRACT(DOW FROM measured_at)::integer AS day_of_week,
    CASE WHEN EXTRACT(DOW FROM measured_at) IN (0, 6) THEN true ELSE false END AS is_weekend
FROM hourly_load;