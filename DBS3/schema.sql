-- =============================================================
-- Premier League Database - Physical Model (DDL)
-- PostgreSQL
-- =============================================================

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS UDALOST_ZAPASU CASCADE;
DROP TABLE IF EXISTS ZAPAS        CASCADE;
DROP TABLE IF EXISTS KOLO         CASCADE;
DROP TABLE IF EXISTS ZMLUVA       CASCADE;
DROP TABLE IF EXISTS HRAC         CASCADE;
DROP TABLE IF EXISTS TIM          CASCADE;
DROP TABLE IF EXISTS STADION      CASCADE;
DROP TABLE IF EXISTS SEZONA       CASCADE;

-- Drop custom ENUM types
DROP TYPE IF EXISTS pozicia_typ    CASCADE;
DROP TYPE IF EXISTS zmluva_status  CASCADE;
DROP TYPE IF EXISTS zapas_status   CASCADE;
DROP TYPE IF EXISTS udalost_typ    CASCADE;

-- =============================================================
-- ENUM types
-- =============================================================
CREATE TYPE pozicia_typ   AS ENUM ('Brankár', 'Obranca', 'Stredopoliar', 'Útočník');
CREATE TYPE zmluva_status AS ENUM ('aktivna', 'ukoncena');
CREATE TYPE zapas_status  AS ENUM ('planovany', 'odohrany', 'zruseny');
CREATE TYPE udalost_typ   AS ENUM ('gol', 'zlta_karta', 'cervena_karta', 'vlastny_gol');

-- =============================================================
-- SEZONA
-- Represents one league year (e.g. 2024/2025).
-- Anchor for contracts, rounds and match statistics.
-- =============================================================
CREATE TABLE SEZONA (
    sezona_id     SERIAL       PRIMARY KEY,
    nazov         VARCHAR(20)  NOT NULL UNIQUE,          -- '2024/2025'
    datum_zaciatok DATE        NOT NULL,
    datum_koniec   DATE        NOT NULL,
    CONSTRAINT chk_sezona_dates CHECK (datum_zaciatok < datum_koniec)
);

-- =============================================================
-- STADION
-- Home stadium of a club (separate entity – several clubs can
-- share a ground, and a stadium has its own attributes).
-- =============================================================
CREATE TABLE STADION (
    stadion_id SERIAL        PRIMARY KEY,
    nazov      VARCHAR(100)  NOT NULL UNIQUE,
    mesto      VARCHAR(50)   NOT NULL,
    kapacita   INT           CHECK (kapacita > 0)
);

-- =============================================================
-- TIM
-- A football club competing in the league.
-- =============================================================
CREATE TABLE TIM (
    tim_id        SERIAL       PRIMARY KEY,
    nazov         VARCHAR(100) NOT NULL UNIQUE,
    rok_zalozenia INT          CHECK (rok_zalozenia > 1800),
    skratka       VARCHAR(3)   UNIQUE,                   -- 'ARS', 'LIV', ...
    stadion_id    INT          NOT NULL,
    CONSTRAINT fk_tim_stadion
        FOREIGN KEY (stadion_id) REFERENCES STADION(stadion_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =============================================================
-- HRAC
-- Individual footballer, independent of any club.
-- Club membership is tracked via ZMLUVA (allows transfers).
-- =============================================================
CREATE TABLE HRAC (
    hrac_id         SERIAL       PRIMARY KEY,
    meno            VARCHAR(50)  NOT NULL,
    priezvisko      VARCHAR(50)  NOT NULL,
    datum_narodenia DATE         NOT NULL,
    narodnost       VARCHAR(50)  NOT NULL,
    pozicia         pozicia_typ  NOT NULL
);

-- =============================================================
-- ZMLUVA
-- Junction table between HRAC and TIM within a SEZONA.
-- Models jersey assignment and transfers (overlapping seasons).
-- Business rule: UNIQUE (tim_id, sezona_id, cislo_dres) prevents
-- two active players from wearing the same number in one season.
-- =============================================================
CREATE TABLE ZMLUVA (
    zmluva_id   SERIAL         PRIMARY KEY,
    hrac_id     INT            NOT NULL,
    tim_id      INT            NOT NULL,
    sezona_id   INT            NOT NULL,
    cislo_dres  INT            NOT NULL CHECK (cislo_dres BETWEEN 1 AND 99),
    platnost_od DATE           NOT NULL,
    platnost_do DATE,                                    -- NULL = currently active
    status      zmluva_status  NOT NULL DEFAULT 'aktivna',
    CONSTRAINT fk_zmluva_hrac
        FOREIGN KEY (hrac_id)   REFERENCES HRAC(hrac_id)   ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_zmluva_tim
        FOREIGN KEY (tim_id)    REFERENCES TIM(tim_id)     ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_zmluva_sezona
        FOREIGN KEY (sezona_id) REFERENCES SEZONA(sezona_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_dres_tim_sezona
        UNIQUE (tim_id, sezona_id, cislo_dres),
    CONSTRAINT chk_zmluva_dates
        CHECK (platnost_do IS NULL OR platnost_od < platnost_do)
);

-- =============================================================
-- KOLO
-- A matchday/round within a season (38 rounds per PL season).
-- =============================================================
CREATE TABLE KOLO (
    kolo_id    SERIAL  PRIMARY KEY,
    sezona_id  INT     NOT NULL,
    cislo_kola INT     NOT NULL,
    datum_od   DATE,
    datum_do   DATE,
    CONSTRAINT fk_kolo_sezona
        FOREIGN KEY (sezona_id) REFERENCES SEZONA(sezona_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_kolo_sezona
        UNIQUE (sezona_id, cislo_kola),
    CONSTRAINT chk_kolo_dates
        CHECK (datum_od IS NULL OR datum_do IS NULL OR datum_od <= datum_do)
);

-- =============================================================
-- ZAPAS
-- A match between two different clubs in a specific round.
-- Core entity for league-table calculation and head-to-head.
-- =============================================================
CREATE TABLE ZAPAS (
    zapas_id           SERIAL        PRIMARY KEY,
    kolo_id            INT           NOT NULL,
    domaci_tim_id      INT           NOT NULL,
    hostujuci_tim_id   INT           NOT NULL,
    datum_cas          TIMESTAMP     NOT NULL,
    skore_domaci_tim   INT           NOT NULL DEFAULT 0,
    skore_hostujuci_tim INT          NOT NULL DEFAULT 0,
    status             zapas_status  NOT NULL DEFAULT 'planovany',
    CONSTRAINT fk_zapas_kolo
        FOREIGN KEY (kolo_id)          REFERENCES KOLO(kolo_id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_zapas_domaci
        FOREIGN KEY (domaci_tim_id)    REFERENCES TIM(tim_id)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_zapas_hostujuci
        FOREIGN KEY (hostujuci_tim_id) REFERENCES TIM(tim_id)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_rozne_timy
        CHECK (domaci_tim_id <> hostujuci_tim_id),
    CONSTRAINT chk_skore_domaci
        CHECK (skore_domaci_tim >= 0),
    CONSTRAINT chk_skore_hostujuci
        CHECK (skore_hostujuci_tim >= 0)
);

-- =============================================================
-- UDALOST_ZAPASU
-- Match events: goals, yellow cards, red cards, own goals.
-- Links a player and their club to a specific minute of a match.
-- Essential for top-scorer list (UC5) and player stats (UC2).
-- =============================================================
CREATE TABLE UDALOST_ZAPASU (
    udalost_id SERIAL       PRIMARY KEY,
    zapas_id   INT          NOT NULL,
    hrac_id    INT          NOT NULL,
    tim_id     INT          NOT NULL,
    typ        udalost_typ  NOT NULL,
    minuta     INT          CHECK (minuta BETWEEN 1 AND 120),
    CONSTRAINT fk_udalost_zapas
        FOREIGN KEY (zapas_id) REFERENCES ZAPAS(zapas_id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_udalost_hrac
        FOREIGN KEY (hrac_id)  REFERENCES HRAC(hrac_id)  ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_udalost_tim
        FOREIGN KEY (tim_id)   REFERENCES TIM(tim_id)    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =============================================================
-- Indexes (beyond PK/UNIQUE auto-indexes)
-- Documented here; justified in queries.sql and report.
-- =============================================================

-- UC1 – match overview filtered by round or date
CREATE INDEX idx_zapas_kolo     ON ZAPAS (kolo_id);
CREATE INDEX idx_zapas_datum    ON ZAPAS (datum_cas);

-- UC2 / UC5 – player stats and top scorers
CREATE INDEX idx_udalost_hrac_typ ON UDALOST_ZAPASU (hrac_id, typ);

-- UC3 / UC6 – league table and head-to-head (filter by both teams)
CREATE INDEX idx_zapas_domaci       ON ZAPAS (domaci_tim_id);
CREATE INDEX idx_zapas_hostujuci    ON ZAPAS (hostujuci_tim_id);

-- ZMLUVA – lookup active squad for a team+season
CREATE INDEX idx_zmluva_tim_sezona ON ZMLUVA (tim_id, sezona_id);
