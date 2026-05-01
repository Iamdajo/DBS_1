# Seed data – Premier League DB

## Reprodukovanie

```bash
python3 seed.py        # vytvorí seed.sql v aktuálnom adresári
psql -U <user> -d <db> -f ../schema.sql
psql -U <user> -d <db> -f seed.sql
```

## Počty záznamov

| Tabuľka          | Počet  |
|------------------|--------|
| SEZONA           |      5 |
| STADION          |     20 |
| TIM              |     20 |
| HRAC             |    600 |
| ZMLUVA           |  2 140 |
| KOLO             |    190 |
| ZAPAS            |  1 900 |
| UDALOST_ZAPASU   | 12 653 |
| **Spolu**        | **17 528** |

## Distribúcia

- **Sezóny**: 2020/2021 – 2024/2025 (5 ročníkov)
- **Hráči**: 30 na tím, vekové rozloženie 18–36 rokov
- **Zmluvy**: 20–23 hráčov na tím na sezónu; `status = 'ukoncena'` pre sezóny 1–4, `'aktivna'` pre 5.
- **Zápasy**: Každý tím hrá raz doma a raz vonku – 380 zápasov/sezóna.
  Sezóny 1–4 plne odohrané; sezóna 5: prvých 340 odohrané, zvyšok `'planovany'`.
- **Udalosti**: Priemer ~4,3 gólov a ~3,5 žltých kariet na zápas; červená karta v ~10 % zápasov.

## Konzistencia

- `UNIQUE (tim_id, sezona_id, cislo_dres)` – čísla dresov generované `random.sample` per tím+sezóna
- `domaci_tim_id <> hostujuci_tim_id` – zaručené generátorom dvojíc
- `skore >= 0` – `random.choices` vracia len nezáporné hodnoty
- `minuta BETWEEN 1 AND 120` – `random.randint(1, 90)`
- FK referencie – vkladanie v správnom poradí (SEZONA → STADION → TIM → HRAC → ZMLUVA → KOLO → ZAPAS → UDALOST_ZAPASU)
