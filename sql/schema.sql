-- Schema do projeto energy-demand-forecast.
-- Fonte: ONS, dataset "Curva de Carga Horária" (CC-BY).
-- Colunas de origem -> destino:
--   id_subsistema           -> subsystem.subsystem_id / hourly_load.subsystem_id
--   nom_subsistema          -> subsystem.name
--   din_instante            -> hourly_load.measured_at
--   val_cargaenergiahomwmed -> hourly_load.load_mwavg

BEGIN;

-- Dimensão: 4 subsistemas (N, NE, S, SE). O dado não traz linha do SIN total;
-- o SIN é derivado na view sin_hourly_load.
CREATE TABLE subsystem (
    subsystem_id varchar(2)  PRIMARY KEY,           -- 'N', 'NE', 'S', 'SE'
    name         varchar(20) NOT NULL UNIQUE        -- 'NORTE', 'NORDESTE', ...
);

-- Fato: carga horária por subsistema.
-- measured_at: início da hora. O ONS publica o instante sem fuso, em horário de
-- Brasília; na ingestão ele é interpretado como America/Sao_Paulo e gravado como
-- timestamptz, para que clientes em fusos diferentes (Power BI no Windows,
-- Postgres no WSL) vejam o mesmo instante. Sem horário de verão desde 2019,
-- não há horas ambíguas em 2021–2025.
CREATE TABLE hourly_load (
    subsystem_id varchar(2)    NOT NULL REFERENCES subsystem (subsystem_id),
    measured_at  timestamptz   NOT NULL,
    load_mwavg   numeric(10,3) NOT NULL CHECK (load_mwavg >= 0),  -- MWmed, 3 casas como na fonte
    PRIMARY KEY (subsystem_id, measured_at)
);

-- A PK já cobre filtros/joins por subsistema (+ intervalo de tempo).
-- Este índice cobre agregações por período sobre todos os subsistemas (ex.: SIN).
CREATE INDEX hourly_load_measured_at_idx ON hourly_load (measured_at);

-- Carga total do SIN por hora.
-- Somar MWmed entre subsistemas no mesmo instante é válido: cada valor é a
-- potência média do subsistema naquela mesma hora, e potências médias
-- simultâneas de partes disjuntas do sistema se somam na potência média do todo.
-- (Somar MWmed ao longo do TEMPO não é válido — aí se usa média, ou MWh.)
-- n_subsystems permite detectar horas incompletas (esperado: 4).
CREATE VIEW sin_hourly_load AS
SELECT measured_at,
       sum(load_mwavg) AS load_mwavg,
       count(*)        AS n_subsystems
FROM hourly_load
GROUP BY measured_at;

COMMIT;
