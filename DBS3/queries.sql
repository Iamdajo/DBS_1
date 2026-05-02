-- =============================================================
-- Premier League DB – Implementácia procesov (čisté SQL)
-- =============================================================


-- =============================================================
-- UC4 – Správa hráčov v tíme (Admin)
-- =============================================================
--
-- Popis:
--   Administrátor pridáva nového hráča do súpisky konkrétneho tímu
--   v prebiehajúcej sezóne. Proces pozostáva z:
--     1. validačného SELECT-u (overenie dostupnosti čísla dresu)
--     2. atómového INSERT-u cez CTE (HRAC + ZMLUVA v jednom príkaze)
--     3. potvrdzovacieho SELECT-u (zobrazenie výsledku)
--
-- Vstupné parametre (nahradiť konkrétnymi hodnotami):
--   :meno            – krstné meno hráča            napr. 'Lamine'
--   :priezvisko      – priezvisko hráča              napr. 'Yamal'
--   :datum_narodenia – dátum narodenia               napr. '2007-07-13'
--   :narodnost       – národnosť                     napr. 'Spanish'
--   :pozicia         – pozícia (ENUM)                napr. 'Útočník'
--   :tim_id          – ID tímu                       napr. 1  (Arsenal)
--   :sezona_id       – ID sezóny                     napr. 5  (2024/2025)
--   :cislo_dres      – požadované číslo dresu (1-99) napr. 19
--   :platnost_od     – dátum začiatku zmluvy         napr. '2025-01-01'
--
-- =============================================================


-- -------------------------------------------------------------
-- KROK 1 – Pohľad na aktuálnu súpisku tímu
--   Použitie: admin si pred pridaním overí, ktoré čísla dresov
--             sú už obsadené v danom tíme a sezóne.
-- -------------------------------------------------------------

CREATE OR REPLACE VIEW v_aktualna_supisku AS
SELECT
    z.tim_id,
    t.nazov                          AS tim,
    z.sezona_id,
    s.nazov                          AS sezona,
    z.cislo_dres,
    h.hrac_id,
    h.meno || ' ' || h.priezvisko    AS hrac,
    h.pozicia,
    h.narodnost,
    z.platnost_od,
    z.platnost_do,
    z.status
FROM ZMLUVA z
JOIN HRAC   h ON h.hrac_id   = z.hrac_id
JOIN TIM    t ON t.tim_id    = z.tim_id
JOIN SEZONA s ON s.sezona_id = z.sezona_id;

-- Príklad použitia pohľadu (zobraziť súpisku Arsenalu v sezóne 5):
-- SELECT cislo_dres, hrac, pozicia
-- FROM v_aktualna_supisku
-- WHERE tim_id = 1 AND sezona_id = 5
-- ORDER BY cislo_dres;


-- -------------------------------------------------------------
-- KROK 2 – Validačný SELECT
--   Overí, či je požadované číslo dresu v danom tíme a sezóne
--   voľné. Výsledok = 0 → číslo je dostupné, môžeme pokračovať.
--   Výsledok > 0 → číslo je obsadené, INSERT treba odmietnuť.
-- -------------------------------------------------------------

SELECT
    COUNT(*)                             AS pocet_konfliktov,
    CASE
        WHEN COUNT(*) = 0 THEN 'Číslo dresu je dostupné – pokračujte vložením.'
        ELSE                   'Číslo dresu je obsadené – zvoľte iné!'
    END                                  AS sprava
FROM ZMLUVA
WHERE tim_id     = 1          -- :tim_id
  AND sezona_id  = 5          -- :sezona_id
  AND cislo_dres = 19;        -- :cislo_dres


-- -------------------------------------------------------------
-- KROK 3 – Atómový INSERT: nový hráč + zmluva (CTE)
--   Oba INSERT-y bežia v jednom príkaze vďaka CTE s RETURNING.
--   Ak UNIQUE (tim_id, sezona_id, cislo_dres) zlyhá, celá
--   operácia sa automaticky rollbackne – žiadny "siroty" v HRAC.
-- -------------------------------------------------------------

WITH novy_hrac AS (
    INSERT INTO HRAC (meno, priezvisko, datum_narodenia, narodnost, pozicia)
    VALUES (
        'Lamine',       -- :meno
        'Yamal',        -- :priezvisko
        '2007-07-13',   -- :datum_narodenia
        'Spanish',      -- :narodnost
        'Útočník'       -- :pozicia
    )
    RETURNING hrac_id
)
INSERT INTO ZMLUVA (hrac_id, tim_id, sezona_id, cislo_dres, platnost_od, platnost_do, status)
SELECT
    hrac_id,
    1,              -- :tim_id
    5,              -- :sezona_id
    19,             -- :cislo_dres
    '2025-01-01',   -- :platnost_od
    NULL,           -- aktívna zmluva (platnost_do = NULL)
    'aktivna'
FROM novy_hrac;


-- -------------------------------------------------------------
-- KROK 4 – Potvrdzovací SELECT
--   Po úspešnom INSERT-e zobrazí práve pridaného hráča
--   so všetkými jeho údajmi zo súpisky.
-- -------------------------------------------------------------

SELECT
    h.hrac_id,
    h.meno || ' ' || h.priezvisko    AS hrac,
    h.pozicia,
    h.narodnost,
    h.datum_narodenia,
    t.nazov                          AS tim,
    s.nazov                          AS sezona,
    z.cislo_dres,
    z.platnost_od,
    z.status
FROM ZMLUVA z
JOIN HRAC   h ON h.hrac_id   = z.hrac_id
JOIN TIM    t ON t.tim_id    = z.tim_id
JOIN SEZONA s ON s.sezona_id = z.sezona_id
WHERE z.tim_id    = 1           -- :tim_id
  AND z.sezona_id = 5           -- :sezona_id
  AND z.cislo_dres = 19;        -- :cislo_dres


-- -------------------------------------------------------------
-- ALTERNATÍVNY TOK – Prestup hráča (transfer počas sezóny)
--   Ak hráč prechádza z jedného tímu do druhého:
--     a) ukončí sa stará zmluva (UPDATE)
--     b) vytvorí sa nová zmluva v novom tíme (INSERT)
--   Oba kroky patria do jednej transakcie.
-- -------------------------------------------------------------

BEGIN;

    -- a) Ukončenie starej zmluvy
    UPDATE ZMLUVA
    SET
        platnost_do = '2025-01-31',     -- :datum_prestupu
        status      = 'ukoncena'
    WHERE hrac_id   = 601               -- :hrac_id (novo vložený hráč)
      AND tim_id    = 1                 -- :stary_tim_id
      AND sezona_id = 5                 -- :sezona_id
      AND status    = 'aktivna';

    -- b) Nová zmluva v novom tíme (validácia čísla dresu pred INSERT-om)
    --    (Rovnaký vzor ako KROK 2 + KROK 3 vyššie, s :novy_tim_id)
    INSERT INTO ZMLUVA (hrac_id, tim_id, sezona_id, cislo_dres, platnost_od, platnost_do, status)
    VALUES (
        601,            -- :hrac_id
        12,             -- :novy_tim_id  (napr. Liverpool)
        5,              -- :sezona_id
        11,             -- :novy_cislo_dres
        '2025-02-01',   -- :novy_platnost_od
        NULL,
        'aktivna'
    );

COMMIT;
