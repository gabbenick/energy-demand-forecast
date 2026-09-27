-- Sanidade: carga média anual do SIN (MWmed) e pico horário.
SELECT extract(year FROM measured_at AT TIME ZONE 'America/Sao_Paulo')::int AS year,
       count(*)                  AS hours,
       round(avg(load_mwavg), 1) AS avg_sin_mwavg,
       round(max(load_mwavg), 1) AS peak_sin_mwavg,
       round(min(load_mwavg), 1) AS min_sin_mwavg
FROM sin_hourly_load
GROUP BY 1
ORDER BY 1;
