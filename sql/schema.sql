-- Schema PROPOSTO — ainda não executado.
-- Fonte: ONS, dataset "Curva de Carga Horária" (CC-BY).
-- Colunas de origem -> destino:
--   id_subsistema           -> subsystem.subsystem_id / hourly_load.subsystem_id
--   nom_subsistema          -> subsystem.name
--   din_instante            -> hourly_load.measured_at
--   val_cargaenergiahomwmed -> hourly_load.load_mwavg

BEGIN;

-- Dimensão: 4 subsistemas (N, NE, S, SE). O dado não traz linha do SIN total;
-- o SIN é a soma dos quatro.
CREATE TABLE subsystem (
    subsystem_id varchar(2)  PRIMARY KEY,           -- 'N', 'NE', 'S', 'SE'
    name         varchar(20) NOT NULL UNIQUE        -- 'NORTE', 'NORDESTE', ...
);

-- Fato: carga horária por subsistema.
-- measured_at: início da hora, horário de Brasília (o dado vem sem fuso;
-- sem horário de verão desde 2019, então não há horas ambíguas em 2021–2025).
CREATE TABLE hourly_load (
    subsystem_id varchar(2)    NOT NULL REFERENCES subsystem (subsystem_id),
    measured_at  timestamp     NOT NULL,
    load_mwavg   numeric(10,3) NOT NULL CHECK (load_mwavg >= 0),  -- MWmed, 3 casas como na fonte
    PRIMARY KEY (subsystem_id, measured_at)
);

-- A PK já cobre filtros/joins por subsistema (+ intervalo de tempo).
-- Este índice cobre agregações por período sobre todos os subsistemas (ex.: SIN).
CREATE INDEX hourly_load_measured_at_idx ON hourly_load (measured_at);

COMMIT;
