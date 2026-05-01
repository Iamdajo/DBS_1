#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Seed data generator for the Premier League database.

Generates seed.sql with realistic-looking data:
  - 5 seasons  (2020/2021 – 2024/2025)
  - 20 stadiums / 20 clubs
  - 600 players  (30 per team)
  - ~2 100 contracts
  - 190 rounds
  - 1 900 matches
  - ~12 000 match events  (goals + cards)
  Total: well above the required 10 000 records.

Usage:
    python seed.py          # writes seed.sql in the current directory
"""

import random
from datetime import date, timedelta, datetime

random.seed(42)

lines: list[str] = []


def w(s: str) -> None:
    lines.append(s)


def esc(s: str) -> str:
    return s.replace("'", "''")


# ============================================================
# SEZONA
# ============================================================
w("-- ============================================================")
w("-- SEZONA  (5 records)")
w("-- ============================================================")

SEASONS = [
    (1, "2020/2021", date(2020, 9, 12), date(2021, 5, 23)),
    (2, "2021/2022", date(2021, 8, 13), date(2022, 5, 22)),
    (3, "2022/2023", date(2022, 8,  5), date(2023, 5, 28)),
    (4, "2023/2024", date(2023, 8, 11), date(2024, 5, 19)),
    (5, "2024/2025", date(2024, 8, 16), date(2025, 5, 25)),
]

for _sid, nazov, zac, kon in SEASONS:
    w(f"INSERT INTO SEZONA (nazov, datum_zaciatok, datum_koniec) "
      f"VALUES ('{nazov}', '{zac}', '{kon}');")

# ============================================================
# STADION
# ============================================================
w("\n-- ============================================================")
w("-- STADION  (20 records)")
w("-- ============================================================")

STADIUMS = [
    (1,  "Emirates Stadium",           "London",          60260),
    (2,  "Villa Park",                 "Birmingham",      42785),
    (3,  "Vitality Stadium",           "Bournemouth",     11379),
    (4,  "Gtech Community Stadium",    "London",          17250),
    (5,  "Amex Stadium",               "Brighton",        31800),
    (6,  "Stamford Bridge",            "London",          40834),
    (7,  "Selhurst Park",              "London",          25486),
    (8,  "Goodison Park",              "Liverpool",       39414),
    (9,  "Craven Cottage",             "London",          25700),
    (10, "Portman Road",               "Ipswich",         29477),
    (11, "King Power Stadium",         "Leicester",       32261),
    (12, "Anfield",                    "Liverpool",       61276),
    (13, "Etihad Stadium",             "Manchester",      53400),
    (14, "Old Trafford",               "Manchester",      74310),
    (15, "St James'' Park",            "Newcastle",       52305),
    (16, "City Ground",                "Nottingham",      30445),
    (17, "St Mary''s Stadium",         "Southampton",     32384),
    (18, "Tottenham Hotspur Stadium",  "London",          62850),
    (19, "London Stadium",             "London",          60000),
    (20, "Molineux Stadium",           "Wolverhampton",   32050),
]

for _sid, nazov, mesto, kap in STADIUMS:
    w(f"INSERT INTO STADION (nazov, mesto, kapacita) "
      f"VALUES ('{nazov}', '{mesto}', {kap});")

# ============================================================
# TIM
# ============================================================
w("\n-- ============================================================")
w("-- TIM  (20 records)")
w("-- ============================================================")

TEAMS = [
    (1,  "Arsenal",                  1886, "ARS",  1),
    (2,  "Aston Villa",              1874, "AVL",  2),
    (3,  "Bournemouth",              1899, "BOU",  3),
    (4,  "Brentford",                1889, "BRE",  4),
    (5,  "Brighton",                 1901, "BHA",  5),
    (6,  "Chelsea",                  1905, "CHE",  6),
    (7,  "Crystal Palace",           1905, "CRY",  7),
    (8,  "Everton",                  1878, "EVE",  8),
    (9,  "Fulham",                   1879, "FUL",  9),
    (10, "Ipswich Town",             1878, "IPS", 10),
    (11, "Leicester City",           1884, "LEI", 11),
    (12, "Liverpool",                1892, "LIV", 12),
    (13, "Manchester City",          1880, "MCI", 13),
    (14, "Manchester United",        1878, "MUN", 14),
    (15, "Newcastle United",         1892, "NEW", 15),
    (16, "Nottingham Forest",        1865, "NFO", 16),
    (17, "Southampton",              1885, "SOU", 17),
    (18, "Tottenham Hotspur",        1882, "TOT", 18),
    (19, "West Ham United",          1895, "WHU", 19),
    (20, "Wolverhampton Wanderers",  1877, "WOL", 20),
]

for tid, nazov, rok, skr, stad in TEAMS:
    w(f"INSERT INTO TIM (nazov, rok_zalozenia, skratka, stadion_id) "
      f"VALUES ('{nazov}', {rok}, '{skr}', {stad});")

# ============================================================
# HRAC  – 30 per team = 600 total
# ============================================================
w("\n-- ============================================================")
w("-- HRAC  (600 records)")
w("-- ============================================================")

FIRST_NAMES = [
    "James", "John", "Robert", "Michael", "William", "David", "Richard",
    "Thomas", "Christopher", "Daniel", "Matthew", "Anthony", "Mark",
    "Lucas", "Oliver", "Jack", "Harry", "George", "Noah", "Ethan", "Mason",
    "Liam", "Jacob", "Alexander", "Benjamin", "Henry", "Samuel", "Mateo",
    "Mohamed", "Bukayo", "Declan", "Erling", "Kevin", "Bruno", "Virgil",
    "Marcus", "Raheem", "Trent", "Jordan", "Phil", "Jadon", "Ruben",
    "Bernardo", "Rodri", "Ilkay", "Riyad", "Gabriel", "Emile", "Pierre",
    "Youri", "Andreas", "Conor", "Richarlison", "Fabinho", "Alisson",
    "Ederson", "Hugo", "Aaron", "Reece", "Ben", "Kyle", "Ivan", "Carlos",
    "Luis", "Sergio", "Marcos", "Roberto", "Paulo", "Diego", "Alejandro",
    "Federico", "Lautaro", "Santiago", "Francisco", "Pedro", "Alexis",
]

LAST_NAMES = [
    "Smith", "Jones", "Williams", "Taylor", "Brown", "Davies", "Evans",
    "Wilson", "Thomas", "Roberts", "Johnson", "Lewis", "Walker", "Robinson",
    "Wood", "Thompson", "White", "Watson", "Jackson", "Wright", "Green",
    "Harris", "Cooper", "King", "Lee", "Martin", "Clarke", "James",
    "Morgan", "Hughes", "Sterling", "Rashford", "Rice", "Haaland",
    "de Bruyne", "Fernandes", "van Dijk", "Salah", "Kane", "Henderson",
    "Phillips", "Foden", "Sancho", "Dias", "Silva", "Gundogan", "Mahrez",
    "Jesus", "Saka", "Nketiah", "Firmino", "Jota", "Nunez", "Elliott",
    "Carvalho", "Trippier", "Botman", "Guimaraes", "Willock", "Anderson",
    "Martinez", "Gonzalez", "Rodriguez", "Hernandez", "Lopez", "Garcia",
    "Perez", "Sanchez", "Romero", "Castro", "Vargas", "Morales", "Jimenez",
    "Torres", "Flores", "Reyes", "Munoz", "Diaz", "Alvarez", "Ramirez",
    "Cruz", "Ortega", "Mendez", "Guerrero", "Nascimento", "Oliveira",
]

NATIONALITIES = [
    "English", "English", "English", "English", "English",
    "French", "French", "French", "Spanish", "Spanish",
    "German", "German", "Brazilian", "Brazilian", "Brazilian",
    "Portuguese", "Portuguese", "Dutch", "Belgian", "Argentine",
    "Norwegian", "Senegalese", "Ivorian", "Ghanaian", "Nigerian",
    "Algerian", "Moroccan", "Japanese", "South Korean", "Scottish",
    "Welsh", "Irish", "Swiss", "Croatian", "Serbian", "Polish",
    "Italian", "Colombian", "Uruguayan", "Chilean",
]

POSITIONS = ["Brankár", "Obranca", "Stredopoliar", "Útočník"]
POSITION_WEIGHTS = [0.08, 0.30, 0.37, 0.25]

PLAYERS_PER_TEAM = 30

# players[i] = (hrac_id, meno, priezvisko, dnar, narodnost, pozicia)
players: list[tuple] = []
hrac_counter = 1

for _team_idx in range(20):
    for _ in range(PLAYERS_PER_TEAM):
        meno = random.choice(FIRST_NAMES)
        priezvisko = random.choice(LAST_NAMES)
        age_days = random.randint(18 * 365, 36 * 365)
        dnar = date(2025, 1, 1) - timedelta(days=age_days)
        narodnost = random.choice(NATIONALITIES)
        pozicia = random.choices(POSITIONS, weights=POSITION_WEIGHTS)[0]
        players.append((hrac_counter, meno, priezvisko, dnar, narodnost, pozicia))
        w(f"INSERT INTO HRAC (meno, priezvisko, datum_narodenia, narodnost, pozicia) "
          f"VALUES ('{esc(meno)}', '{esc(priezvisko)}', '{dnar}', '{narodnost}', '{pozicia}');")
        hrac_counter += 1

# ============================================================
# ZMLUVA  – 20-23 players per team per season ≈ 2 100 records
# ============================================================
w("\n-- ============================================================")
w("-- ZMLUVA  (~2 100 records)")
w("-- ============================================================")

# team_season_squad[tim_id][sezona_id] = [hrac_id, ...]
team_season_squad: dict[int, dict[int, list[int]]] = {}

for tim_idx, (tid, _tn, _rok, _skr, _stad) in enumerate(TEAMS):
    team_season_squad[tid] = {}
    base_ids = [p[0] for p in players[tim_idx * PLAYERS_PER_TEAM:(tim_idx + 1) * PLAYERS_PER_TEAM]]

    for sid, _sn, szac, skon in SEASONS:
        squad_size = random.randint(20, 23)
        squad = random.sample(base_ids, squad_size)

        # Unique jersey numbers for this (tim_id, sezona_id) – satisfies UNIQUE constraint
        jersey_pool = random.sample(range(1, 99), squad_size)

        status = "ukoncena" if sid < 5 else "aktivna"
        team_season_squad[tid][sid] = squad

        for idx, hp_id in enumerate(squad):
            cislo = jersey_pool[idx]
            w(f"INSERT INTO ZMLUVA (hrac_id, tim_id, sezona_id, cislo_dres, platnost_od, platnost_do, status) "
              f"VALUES ({hp_id}, {tid}, {sid}, {cislo}, '{szac}', '{skon}', '{status}');")

# ============================================================
# KOLO  – 38 rounds × 5 seasons = 190 records
# ============================================================
w("\n-- ============================================================")
w("-- KOLO  (190 records)")
w("-- ============================================================")

# season_rounds[sid] = [(kolo_id, datum_od, datum_do), ...]
season_rounds: dict[int, list[tuple]] = {}
kolo_counter = 1

for sid, _sn, szac, skon in SEASONS:
    season_rounds[sid] = []
    total_days = (skon - szac).days
    round_span = total_days // 38

    for kr in range(1, 39):
        datum_od = szac + timedelta(days=(kr - 1) * round_span)
        datum_do = datum_od + timedelta(days=6)
        w(f"INSERT INTO KOLO (sezona_id, cislo_kola, datum_od, datum_do) "
          f"VALUES ({sid}, {kr}, '{datum_od}', '{datum_do}');")
        season_rounds[sid].append((kolo_counter, datum_od, datum_do))
        kolo_counter += 1

# ============================================================
# ZAPAS  – 380 per season × 5 = 1 900 records
# ============================================================
w("\n-- ============================================================")
w("-- ZAPAS  (1 900 records)")
w("-- ============================================================")

team_ids = [t[0] for t in TEAMS]

# all_matches: (zapas_id, kolo_id, domaci, hostujuci, sid, status, sg_d, sg_h)
all_matches: list[tuple] = []
zapas_counter = 1

for sid, _sn, szac, skon in SEASONS:
    rounds = season_rounds[sid]

    # All 380 unique home-away pairs
    matchups = [(h, a) for h in team_ids for a in team_ids if h != a]
    random.shuffle(matchups)

    for match_idx, (home, away) in enumerate(matchups):
        round_idx = match_idx // 10          # 10 matches per round, 38 rounds
        if round_idx >= 38:
            break

        kolo_id_val, datum_od, _datum_do = rounds[round_idx]

        day_offset = random.randint(0, 6)
        match_date = min(datum_od + timedelta(days=day_offset), skon)
        hour = random.choice([12, 15, 17, 20])
        datum_cas = datetime(match_date.year, match_date.month, match_date.day, hour, 0, 0)

        # Season 1-4 fully played; season 5 first 340 played, rest planned
        if sid < 5 or match_idx < 340:
            status = "odohrany"
            sg_d = random.choices([0, 1, 2, 3, 4, 5], weights=[20, 30, 25, 15, 7, 3])[0]
            sg_h = random.choices([0, 1, 2, 3, 4, 5], weights=[25, 30, 22, 13, 7, 3])[0]
        else:
            status = "planovany"
            sg_d = 0
            sg_h = 0

        w(f"INSERT INTO ZAPAS "
          f"(kolo_id, domaci_tim_id, hostujuci_tim_id, datum_cas, "
          f"skore_domaci_tim, skore_hostujuci_tim, status) "
          f"VALUES ({kolo_id_val}, {home}, {away}, '{datum_cas}', "
          f"{sg_d}, {sg_h}, '{status}');")
        all_matches.append((zapas_counter, kolo_id_val, home, away, sid, status, sg_d, sg_h))
        zapas_counter += 1

# ============================================================
# UDALOST_ZAPASU  – goals + cards for every played match
# Average ~6-7 events per match × 1 860 played = ~12 000 records
# ============================================================
w("\n-- ============================================================")
w("-- UDALOST_ZAPASU  (~12 000 records)")
w("-- ============================================================")

for zapas_id_val, _kolo, home, away, sid, status, sg_d, sg_h in all_matches:
    if status != "odohrany":
        continue

    home_squad = team_season_squad.get(home, {}).get(sid, [])
    away_squad = team_season_squad.get(away, {}).get(sid, [])
    if not home_squad or not away_squad:
        continue

    # Goals – home
    for _ in range(sg_d):
        scorer = random.choice(home_squad)
        minuta = random.randint(1, 90)
        w(f"INSERT INTO UDALOST_ZAPASU (zapas_id, hrac_id, tim_id, typ, minuta) "
          f"VALUES ({zapas_id_val}, {scorer}, {home}, 'gol', {minuta});")

    # Goals – away
    for _ in range(sg_h):
        scorer = random.choice(away_squad)
        minuta = random.randint(1, 90)
        w(f"INSERT INTO UDALOST_ZAPASU (zapas_id, hrac_id, tim_id, typ, minuta) "
          f"VALUES ({zapas_id_val}, {scorer}, {away}, 'gol', {minuta});")

    # Yellow cards  (2-5 per match on average)
    for _ in range(random.randint(2, 5)):
        is_home = random.random() < 0.5
        squad = home_squad if is_home else away_squad
        team  = home      if is_home else away
        player = random.choice(squad)
        minuta = random.randint(1, 90)
        w(f"INSERT INTO UDALOST_ZAPASU (zapas_id, hrac_id, tim_id, typ, minuta) "
          f"VALUES ({zapas_id_val}, {player}, {team}, 'zlta_karta', {minuta});")

    # Red card  (~10 % of matches)
    if random.random() < 0.10:
        is_home = random.random() < 0.5
        squad = home_squad if is_home else away_squad
        team  = home      if is_home else away
        player = random.choice(squad)
        minuta = random.randint(1, 90)
        w(f"INSERT INTO UDALOST_ZAPASU (zapas_id, hrac_id, tim_id, typ, minuta) "
          f"VALUES ({zapas_id_val}, {player}, {team}, 'cervena_karta', {minuta});")

# ============================================================
# Write output
# ============================================================
content = "\n".join(lines)
out_path = "seed.sql"
with open(out_path, "w", encoding="utf-8") as f:
    f.write(content)

insert_count = sum(1 for line in lines if line.startswith("INSERT"))
print(f"seed.sql written — {insert_count} INSERT statements")
