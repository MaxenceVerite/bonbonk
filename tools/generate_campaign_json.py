import json
import os

def create_spawn(unit, delay, x):
    return {
        "unit": unit,
        "delay": round(delay, 2),
        "x": round(x, 2)
    }

def build_levels():
    worlds = []

    # =========================================================================
    # MONDE 1 : FORÊT DRAGÉE
    # =========================================================================
    w1_levels = []

    # Niveau 1 : Premiers Pas Croquants (~2 min, 4 sous-vagues, 26 mobs)
    w1_levels.append({
        "number": 1,
        "title": "Premiers Pas Croquants",
        "description": "Repousse les premières colonnes maraîchères le long du sentier.",
        "star_thresholds": [3000, 6500, 11000],
        "rewards": { "gold": 120, "diamonds": 5, "booster": "silver_pop" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.35),
                    create_spawn("tomato", 3.0, 0.65),
                    create_spawn("tomato", 6.5, 0.20),
                    create_spawn("tomato", 10.0, 0.80),
                    create_spawn("tomato", 14.0, 0.50),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.25),
                    create_spawn("tomato", 2.5, 0.75),
                    create_spawn("tomato", 5.5, 0.40),
                    create_spawn("tomato", 8.5, 0.60),
                    create_spawn("tomato", 12.0, 0.20),
                    create_spawn("tomato", 15.5, 0.80),
                    create_spawn("tomato", 19.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.30),
                    create_spawn("tomato", 2.5, 0.70),
                    create_spawn("ananas", 5.5, 0.50),
                    create_spawn("tomato", 8.5, 0.20),
                    create_spawn("tomato", 11.5, 0.80),
                    create_spawn("tomato", 15.0, 0.40),
                    create_spawn("ananas", 18.5, 0.65),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.20),
                    create_spawn("tomato", 2.5, 0.80),
                    create_spawn("ananas", 5.5, 0.35),
                    create_spawn("tomato", 8.5, 0.65),
                    create_spawn("tomato", 12.0, 0.50),
                    create_spawn("ananas", 15.5, 0.75),
                    create_spawn("tomato", 19.0, 0.25),
                ]
            }
        ]
    })

    # Niveau 2 : Sauts d'Ananas (~2 min, 4 sous-vagues, 30 mobs)
    w1_levels.append({
        "number": 2,
        "title": "Sauts d'Ananas",
        "description": "Les ananas bondissants sautent au-dessus de la bille pour surprendre tes flippers.",
        "star_thresholds": [3500, 7500, 12500],
        "rewards": { "gold": 140, "diamonds": 5, "booster": "silver_pop" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.30),
                    create_spawn("ananas", 2.8, 0.70),
                    create_spawn("tomato", 6.0, 0.50),
                    create_spawn("tomato", 9.5, 0.20),
                    create_spawn("ananas", 13.0, 0.80),
                    create_spawn("tomato", 16.5, 0.40),
                    create_spawn("tomato", 20.0, 0.60),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("ananas", 0.5, 0.25),
                    create_spawn("tomato", 2.5, 0.75),
                    create_spawn("tomato", 5.5, 0.45),
                    create_spawn("ananas", 8.5, 0.65),
                    create_spawn("tomato", 12.0, 0.30),
                    create_spawn("ananas", 15.5, 0.50),
                    create_spawn("tomato", 19.0, 0.85),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.20),
                    create_spawn("tomato", 2.5, 0.80),
                    create_spawn("ananas", 5.5, 0.35),
                    create_spawn("ananas", 8.5, 0.65),
                    create_spawn("tomato", 12.0, 0.50),
                    create_spawn("tomato", 15.5, 0.25),
                    create_spawn("ananas", 18.5, 0.75),
                    create_spawn("tomato", 22.0, 0.40),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("ananas", 0.5, 0.50),
                    create_spawn("tomato", 2.8, 0.20),
                    create_spawn("tomato", 5.5, 0.80),
                    create_spawn("ananas", 8.5, 0.35),
                    create_spawn("ananas", 12.0, 0.65),
                    create_spawn("tomato", 15.5, 0.50),
                    create_spawn("ananas", 18.5, 0.25),
                    create_spawn("tomato", 22.0, 0.75),
                ]
            }
        ]
    })

    # Niveau 3 : Le Panier Maraîcher (~2 min, 4 sous-vagues, 32 mobs)
    w1_levels.append({
        "number": 3,
        "title": "Le Panier Maraîcher",
        "description": "Des escouades denses de tomates soutenues par une imposante pastèque en fin de niveau.",
        "star_thresholds": [4000, 8500, 14000],
        "rewards": { "gold": 160, "diamonds": 6, "booster": "silver_pop" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.20),
                    create_spawn("tomato", 2.5, 0.50),
                    create_spawn("tomato", 5.0, 0.80),
                    create_spawn("ananas", 8.0, 0.35),
                    create_spawn("tomato", 11.5, 0.65),
                    create_spawn("tomato", 15.0, 0.25),
                    create_spawn("ananas", 18.5, 0.75),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.40),
                    create_spawn("tomato", 2.5, 0.60),
                    create_spawn("ananas", 5.5, 0.25),
                    create_spawn("ananas", 8.5, 0.75),
                    create_spawn("tomato", 12.0, 0.50),
                    create_spawn("tomato", 15.0, 0.20),
                    create_spawn("tomato", 18.5, 0.80),
                    create_spawn("ananas", 22.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.25),
                    create_spawn("tomato", 2.5, 0.75),
                    create_spawn("tomato", 5.0, 0.50),
                    create_spawn("ananas", 8.0, 0.30),
                    create_spawn("ananas", 11.5, 0.70),
                    create_spawn("tomato", 15.0, 0.40),
                    create_spawn("tomato", 18.5, 0.60),
                    create_spawn("ananas", 22.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("tomato", 3.0, 0.20),
                    create_spawn("tomato", 6.0, 0.80),
                    create_spawn("ananas", 9.0, 0.35),
                    create_spawn("ananas", 12.5, 0.65),
                    create_spawn("tomato", 16.0, 0.25),
                    create_spawn("tomato", 19.5, 0.75),
                    create_spawn("tomato", 23.0, 0.50),
                ]
            }
        ]
    })

    # Niveau 4 : Grappes Gourmandes (~2 min, 4 sous-vagues, 34 mobs)
    w1_levels.append({
        "number": 4,
        "title": "Grappes Gourmandes",
        "description": "Les grappes de raisin éclatent en une myriade de baies lors des impacts !",
        "star_thresholds": [4500, 9500, 15500],
        "rewards": { "gold": 180, "diamonds": 7, "booster": "golden_crush" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.30),
                    create_spawn("grape_bunch", 2.8, 0.50),
                    create_spawn("tomato", 6.5, 0.70),
                    create_spawn("ananas", 10.0, 0.25),
                    create_spawn("tomato", 13.5, 0.85),
                    create_spawn("grape_bunch", 17.0, 0.50),
                    create_spawn("tomato", 20.5, 0.35),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("grape_bunch", 0.5, 0.35),
                    create_spawn("tomato", 3.0, 0.65),
                    create_spawn("ananas", 6.0, 0.20),
                    create_spawn("ananas", 9.0, 0.80),
                    create_spawn("tomato", 12.5, 0.50),
                    create_spawn("grape_bunch", 16.0, 0.65),
                    create_spawn("tomato", 19.5, 0.30),
                    create_spawn("tomato", 22.5, 0.70),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.20),
                    create_spawn("grape_bunch", 2.8, 0.50),
                    create_spawn("tomato", 6.0, 0.80),
                    create_spawn("ananas", 9.5, 0.35),
                    create_spawn("grape_bunch", 13.0, 0.65),
                    create_spawn("tomato", 16.5, 0.25),
                    create_spawn("ananas", 19.5, 0.75),
                    create_spawn("tomato", 22.5, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("grape_bunch", 0.5, 0.25),
                    create_spawn("grape_bunch", 2.5, 0.75),
                    create_spawn("tomato", 6.0, 0.50),
                    create_spawn("ananas", 9.5, 0.30),
                    create_spawn("ananas", 13.0, 0.70),
                    create_spawn("tomato", 16.5, 0.20),
                    create_spawn("grape_bunch", 19.5, 0.50),
                    create_spawn("tomato", 23.0, 0.80),
                ]
            }
        ]
    })

    # Niveau 5 : Le Mur de Pastèques (~2 min, 4 sous-vagues, 36 mobs)
    w1_levels.append({
        "number": 5,
        "title": "Le Mur de Pastèques",
        "description": "Des pastèques massives et résistantes absorbent les tirs et protègent la vague.",
        "star_thresholds": [5000, 10500, 17000],
        "rewards": { "gold": 200, "diamonds": 8, "booster": "golden_crush" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("tomato", 3.0, 0.25),
                    create_spawn("tomato", 6.0, 0.75),
                    create_spawn("ananas", 9.5, 0.40),
                    create_spawn("tomato", 13.0, 0.60),
                    create_spawn("watermelon", 16.5, 0.30),
                    create_spawn("tomato", 20.0, 0.80),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("tomato", 3.0, 0.65),
                    create_spawn("ananas", 6.0, 0.20),
                    create_spawn("grape_bunch", 9.0, 0.80),
                    create_spawn("watermelon", 12.5, 0.65),
                    create_spawn("tomato", 16.0, 0.35),
                    create_spawn("ananas", 19.0, 0.50),
                    create_spawn("tomato", 22.0, 0.75),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 3.0, 0.75),
                    create_spawn("tomato", 6.5, 0.50),
                    create_spawn("ananas", 9.5, 0.30),
                    create_spawn("ananas", 13.0, 0.70),
                    create_spawn("grape_bunch", 16.5, 0.50),
                    create_spawn("tomato", 19.5, 0.20),
                    create_spawn("tomato", 22.5, 0.80),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("ananas", 3.0, 0.25),
                    create_spawn("ananas", 6.0, 0.75),
                    create_spawn("watermelon", 9.5, 0.30),
                    create_spawn("watermelon", 12.5, 0.70),
                    create_spawn("grape_bunch", 16.0, 0.50),
                    create_spawn("tomato", 19.0, 0.20),
                    create_spawn("tomato", 22.5, 0.80),
                ]
            }
        ]
    })

    # Niveau 6 : Pluie de Grenades (~2 min, 4 sous-vagues, 38 mobs)
    w1_levels.append({
        "number": 6,
        "title": "Pluie de Grenades",
        "description": "Les grenades explosives bombardent l'arène de pépins vifs lors des frappes.",
        "star_thresholds": [5500, 11500, 18500],
        "rewards": { "gold": 220, "diamonds": 9, "booster": "golden_crush" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.35),
                    create_spawn("tomato", 3.0, 0.65),
                    create_spawn("ananas", 6.0, 0.20),
                    create_spawn("pomegranate", 9.5, 0.75),
                    create_spawn("tomato", 13.0, 0.40),
                    create_spawn("tomato", 16.5, 0.60),
                    create_spawn("ananas", 20.0, 0.50),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.50),
                    create_spawn("tomato", 2.8, 0.25),
                    create_spawn("tomato", 5.5, 0.75),
                    create_spawn("pomegranate", 8.5, 0.30),
                    create_spawn("ananas", 12.0, 0.70),
                    create_spawn("watermelon", 15.5, 0.50),
                    create_spawn("tomato", 19.0, 0.20),
                    create_spawn("tomato", 22.0, 0.80),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.25),
                    create_spawn("pomegranate", 3.0, 0.75),
                    create_spawn("grape_bunch", 6.5, 0.50),
                    create_spawn("tomato", 9.5, 0.35),
                    create_spawn("ananas", 13.0, 0.65),
                    create_spawn("watermelon", 16.5, 0.50),
                    create_spawn("tomato", 19.5, 0.25),
                    create_spawn("tomato", 22.5, 0.75),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.30),
                    create_spawn("watermelon", 3.0, 0.70),
                    create_spawn("pomegranate", 6.5, 0.50),
                    create_spawn("ananas", 9.5, 0.20),
                    create_spawn("ananas", 13.0, 0.80),
                    create_spawn("pomegranate", 16.0, 0.35),
                    create_spawn("pomegranate", 19.0, 0.65),
                    create_spawn("grape_bunch", 22.5, 0.50),
                ]
            }
        ]
    })

    # Niveau 7 : Le Bosquet des Saveurs (~2 min, 4 sous-vagues, 40 mobs)
    w1_levels.append({
        "number": 7,
        "title": "Le Bosquet des Saveurs",
        "description": "Une alliance féroce de pastèques protectrices, grenades et ananas bondissants.",
        "star_thresholds": [6000, 12500, 20000],
        "rewards": { "gold": 250, "diamonds": 10, "booster": "golden_crush" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("tomato", 2.8, 0.70),
                    create_spawn("ananas", 5.5, 0.20),
                    create_spawn("pomegranate", 8.5, 0.80),
                    create_spawn("grape_bunch", 12.0, 0.50),
                    create_spawn("tomato", 15.5, 0.30),
                    create_spawn("ananas", 19.0, 0.70),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.30),
                    create_spawn("watermelon", 3.0, 0.65),
                    create_spawn("ananas", 6.0, 0.25),
                    create_spawn("grape_bunch", 9.0, 0.75),
                    create_spawn("tomato", 12.5, 0.50),
                    create_spawn("pomegranate", 15.5, 0.80),
                    create_spawn("ananas", 18.5, 0.20),
                    create_spawn("tomato", 22.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 2.8, 0.75),
                    create_spawn("pomegranate", 6.0, 0.50),
                    create_spawn("ananas", 9.0, 0.35),
                    create_spawn("grape_bunch", 12.5, 0.65),
                    create_spawn("tomato", 15.5, 0.20),
                    create_spawn("ananas", 18.5, 0.80),
                    create_spawn("pomegranate", 22.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("pomegranate", 3.0, 0.25),
                    create_spawn("pomegranate", 6.0, 0.75),
                    create_spawn("ananas", 9.0, 0.35),
                    create_spawn("ananas", 12.5, 0.65),
                    create_spawn("grape_bunch", 16.0, 0.20),
                    create_spawn("grape_bunch", 19.0, 0.80),
                    create_spawn("watermelon", 22.5, 0.50),
                ]
            }
        ]
    })

    # Niveau 8 : Tornade Végétale (~2 min, 5 sous-vagues, 44 mobs)
    w1_levels.append({
        "number": 8,
        "title": "Tornade Végétale",
        "description": "Cinq vagues d'assaut ininterrompues pour tester tes réflexes de flipper.",
        "star_thresholds": [7000, 14000, 22000],
        "rewards": { "gold": 280, "diamonds": 11, "booster": "golden_crush" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.30),
                    create_spawn("ananas", 2.8, 0.70),
                    create_spawn("pomegranate", 5.5, 0.50),
                    create_spawn("tomato", 8.5, 0.20),
                    create_spawn("tomato", 11.5, 0.80),
                    create_spawn("ananas", 15.0, 0.40),
                    create_spawn("watermelon", 18.5, 0.65),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("grape_bunch", 2.8, 0.65),
                    create_spawn("ananas", 5.8, 0.25),
                    create_spawn("tomato", 9.0, 0.75),
                    create_spawn("pomegranate", 12.0, 0.50),
                    create_spawn("tomato", 15.0, 0.20),
                    create_spawn("ananas", 18.5, 0.80),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.30),
                    create_spawn("pomegranate", 2.8, 0.70),
                    create_spawn("watermelon", 5.8, 0.50),
                    create_spawn("ananas", 9.0, 0.25),
                    create_spawn("grape_bunch", 12.0, 0.75),
                    create_spawn("tomato", 15.5, 0.35),
                    create_spawn("tomato", 18.5, 0.65),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 3.0, 0.75),
                    create_spawn("ananas", 6.0, 0.50),
                    create_spawn("pomegranate", 9.0, 0.35),
                    create_spawn("grape_bunch", 12.5, 0.65),
                    create_spawn("tomato", 15.5, 0.20),
                    create_spawn("ananas", 18.5, 0.80),
                ]
            },
            {
                "subwave": 5,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("pomegranate", 2.8, 0.25),
                    create_spawn("pomegranate", 5.5, 0.75),
                    create_spawn("ananas", 8.5, 0.35),
                    create_spawn("ananas", 11.5, 0.65),
                    create_spawn("grape_bunch", 15.0, 0.50),
                    create_spawn("watermelon", 18.5, 0.30),
                    create_spawn("watermelon", 21.5, 0.70),
                ]
            }
        ]
    })

    # Niveau 9 : L'Antichambre de Brocolino (~2 min, 5 sous-vagues, 48 mobs)
    w1_levels.append({
        "number": 9,
        "title": "L'Antichambre de Brocolino",
        "description": "La garde d'élite du seigneur végétal bloque l'accès au trône avec férocité.",
        "star_thresholds": [8000, 16000, 25000],
        "rewards": { "gold": 320, "diamonds": 12, "booster": "golden_crush" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("pomegranate", 2.8, 0.70),
                    create_spawn("ananas", 5.5, 0.20),
                    create_spawn("ananas", 8.5, 0.80),
                    create_spawn("grape_bunch", 12.0, 0.50),
                    create_spawn("tomato", 15.0, 0.35),
                    create_spawn("tomato", 18.0, 0.65),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.25),
                    create_spawn("watermelon", 2.8, 0.65),
                    create_spawn("ananas", 5.5, 0.50),
                    create_spawn("pomegranate", 8.5, 0.75),
                    create_spawn("grape_bunch", 12.0, 0.30),
                    create_spawn("ananas", 15.0, 0.85),
                    create_spawn("tomato", 18.5, 0.40),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.30),
                    create_spawn("watermelon", 2.8, 0.70),
                    create_spawn("pomegranate", 5.8, 0.50),
                    create_spawn("ananas", 8.8, 0.25),
                    create_spawn("grape_bunch", 12.0, 0.75),
                    create_spawn("pomegranate", 15.0, 0.40),
                    create_spawn("ananas", 18.5, 0.60),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("pomegranate", 2.8, 0.25),
                    create_spawn("pomegranate", 5.5, 0.75),
                    create_spawn("ananas", 8.5, 0.35),
                    create_spawn("ananas", 11.5, 0.65),
                    create_spawn("grape_bunch", 15.0, 0.50),
                    create_spawn("watermelon", 18.0, 0.20),
                    create_spawn("watermelon", 21.0, 0.80),
                ]
            },
            {
                "subwave": 5,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 2.5, 0.75),
                    create_spawn("pomegranate", 5.5, 0.50),
                    create_spawn("pomegranate", 8.5, 0.30),
                    create_spawn("pomegranate", 11.5, 0.70),
                    create_spawn("grape_bunch", 14.5, 0.50),
                    create_spawn("ananas", 17.5, 0.20),
                    create_spawn("ananas", 20.5, 0.80),
                ]
            }
        ]
    })

    # Niveau 10 : Le Trône de Brocolino (~5 min Boss Encounter !)
    # Subwaves 1 à 3 : Gauntlet d'avant-garde (~2 min total)
    # Subwave 4 : Boss Brocolino (300 PV, 3 phases, bouclier bumpers) (~3 min duel)
    w1_levels.append({
        "number": 10,
        "title": "Le Trône de Brocolino",
        "description": "Affronte Brocolino, le colosse végétal de la Forêt Dragée, dans un duel épique !",
        "star_thresholds": [12000, 25000, 42000],
        "rewards": { "gold": 600, "diamonds": 30, "booster": "golden_crush" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("tomato", 3.0, 0.70),
                    create_spawn("ananas", 6.0, 0.20),
                    create_spawn("ananas", 9.0, 0.80),
                    create_spawn("pomegranate", 12.5, 0.50),
                    create_spawn("tomato", 16.0, 0.30),
                    create_spawn("tomato", 19.5, 0.70),
                    create_spawn("watermelon", 23.0, 0.50),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.30),
                    create_spawn("pomegranate", 3.0, 0.70),
                    create_spawn("grape_bunch", 6.5, 0.50),
                    create_spawn("ananas", 9.5, 0.25),
                    create_spawn("ananas", 13.0, 0.75),
                    create_spawn("watermelon", 16.5, 0.50),
                    create_spawn("tomato", 19.5, 0.20),
                    create_spawn("tomato", 22.5, 0.80),
                    create_spawn("pomegranate", 26.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 3.0, 0.75),
                    create_spawn("pomegranate", 6.5, 0.50),
                    create_spawn("pomegranate", 9.5, 0.35),
                    create_spawn("pomegranate", 13.0, 0.65),
                    create_spawn("grape_bunch", 16.5, 0.50),
                    create_spawn("ananas", 19.5, 0.20),
                    create_spawn("ananas", 22.5, 0.80),
                    create_spawn("watermelon", 26.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("boss_brocolino", 1.0, 0.50)
                ]
            }
        ]
    })

    worlds.append({
        "id": "world_1",
        "world_number": 1,
        "display_name": "Forêt Dragée",
        "subtitle": "Un sous-bois féerique aux racines de réglisse et dragées pastel",
        "completion_reward_booster_id": "golden_crush",
        "levels": w1_levels
    })

    # =========================================================================
    # MONDE 2 : PLAGE SUCRÉE
    # =========================================================================
    w2_levels = []

    # Niveau 1 : Arrivée sur la Plage (~2 min, 4 sous-vagues, 30 mobs)
    w2_levels.append({
        "number": 1,
        "title": "Arrivée sur la Plage",
        "description": "Bienvenue sur le rivage de sucre rose ! Les grenades de mer ouvrent la voie.",
        "star_thresholds": [3500, 7500, 13000],
        "rewards": { "gold": 160, "diamonds": 6, "booster": "silver_pop" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.30),
                    create_spawn("pomegranate", 3.0, 0.70),
                    create_spawn("tomato", 6.5, 0.50),
                    create_spawn("tomato", 10.0, 0.20),
                    create_spawn("pomegranate", 13.5, 0.80),
                    create_spawn("tomato", 17.0, 0.40),
                    create_spawn("tomato", 20.5, 0.60),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.35),
                    create_spawn("tomato", 2.8, 0.65),
                    create_spawn("ananas", 5.8, 0.20),
                    create_spawn("tomato", 9.0, 0.80),
                    create_spawn("pomegranate", 12.5, 0.50),
                    create_spawn("tomato", 16.0, 0.30),
                    create_spawn("ananas", 19.5, 0.70),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("tomato", 0.5, 0.25),
                    create_spawn("pomegranate", 2.8, 0.75),
                    create_spawn("ananas", 5.8, 0.50),
                    create_spawn("tomato", 9.0, 0.30),
                    create_spawn("pomegranate", 12.0, 0.70),
                    create_spawn("tomato", 15.5, 0.20),
                    create_spawn("ananas", 19.0, 0.80),
                    create_spawn("tomato", 22.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.50),
                    create_spawn("tomato", 2.8, 0.20),
                    create_spawn("tomato", 5.8, 0.80),
                    create_spawn("ananas", 9.0, 0.35),
                    create_spawn("pomegranate", 12.5, 0.65),
                    create_spawn("tomato", 16.0, 0.50),
                    create_spawn("ananas", 19.0, 0.25),
                    create_spawn("tomato", 22.5, 0.75),
                ]
            }
        ]
    })

    # Niveau 2 : Noix de Coco Sauvages (~2 min, 4 sous-vagues, 32 mobs)
    w2_levels.append({
        "number": 2,
        "title": "Noix de Coco Sauvages",
        "description": "Les noix de coco à coque blindée exigent plusieurs rebonds de flipper pour céder.",
        "star_thresholds": [4200, 9000, 15000],
        "rewards": { "gold": 180, "diamonds": 7, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.50),
                    create_spawn("tomato", 3.0, 0.25),
                    create_spawn("tomato", 6.5, 0.75),
                    create_spawn("coconut", 10.0, 0.35),
                    create_spawn("ananas", 13.5, 0.65),
                    create_spawn("tomato", 17.0, 0.20),
                    create_spawn("tomato", 20.5, 0.80),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("coconut", 3.0, 0.70),
                    create_spawn("tomato", 6.5, 0.50),
                    create_spawn("ananas", 9.5, 0.25),
                    create_spawn("pomegranate", 13.0, 0.75),
                    create_spawn("tomato", 16.5, 0.40),
                    create_spawn("coconut", 20.0, 0.60),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.35),
                    create_spawn("tomato", 3.0, 0.65),
                    create_spawn("ananas", 6.0, 0.20),
                    create_spawn("coconut", 9.5, 0.80),
                    create_spawn("pomegranate", 13.0, 0.50),
                    create_spawn("tomato", 16.5, 0.30),
                    create_spawn("ananas", 19.5, 0.70),
                    create_spawn("coconut", 23.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.25),
                    create_spawn("coconut", 3.0, 0.75),
                    create_spawn("pomegranate", 6.5, 0.50),
                    create_spawn("ananas", 9.5, 0.35),
                    create_spawn("ananas", 13.0, 0.65),
                    create_spawn("tomato", 16.5, 0.20),
                    create_spawn("coconut", 19.5, 0.50),
                    create_spawn("tomato", 23.0, 0.80),
                ]
            }
        ]
    })

    # Niveau 3 : Châteaux de Sucre (~2 min, 4 sous-vagues, 34 mobs)
    w2_levels.append({
        "number": 3,
        "title": "Châteaux de Sucre",
        "description": "Des remparts de noix de coco protégeant des ananas bondissants.",
        "star_thresholds": [4800, 10000, 16500],
        "rewards": { "gold": 200, "diamonds": 7, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("ananas", 3.0, 0.70),
                    create_spawn("tomato", 6.5, 0.50),
                    create_spawn("coconut", 10.0, 0.25),
                    create_spawn("pomegranate", 13.5, 0.75),
                    create_spawn("tomato", 17.0, 0.35),
                    create_spawn("ananas", 20.5, 0.65),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.40),
                    create_spawn("coconut", 3.0, 0.60),
                    create_spawn("ananas", 6.5, 0.20),
                    create_spawn("tomato", 9.5, 0.80),
                    create_spawn("pomegranate", 13.0, 0.50),
                    create_spawn("tomato", 16.5, 0.30),
                    create_spawn("ananas", 19.5, 0.70),
                    create_spawn("coconut", 23.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.25),
                    create_spawn("coconut", 3.0, 0.75),
                    create_spawn("pomegranate", 6.5, 0.50),
                    create_spawn("ananas", 9.5, 0.35),
                    create_spawn("ananas", 13.0, 0.65),
                    create_spawn("tomato", 16.5, 0.20),
                    create_spawn("coconut", 19.5, 0.80),
                    create_spawn("tomato", 23.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("coconut", 2.8, 0.70),
                    create_spawn("watermelon", 6.0, 0.50),
                    create_spawn("ananas", 9.5, 0.25),
                    create_spawn("pomegranate", 13.0, 0.75),
                    create_spawn("ananas", 16.5, 0.50),
                    create_spawn("coconut", 19.5, 0.30),
                    create_spawn("coconut", 23.0, 0.70),
                ]
            }
        ]
    })

    # Niveau 4 : Ballet Aquatique (~2 min, 4 sous-vagues, 36 mobs)
    w2_levels.append({
        "number": 4,
        "title": "Ballet Aquatique",
        "description": "Grappes de raisin et grenades s'entrelacent autour des récifs de noix de coco.",
        "star_thresholds": [5400, 11500, 18500],
        "rewards": { "gold": 220, "diamonds": 8, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.50),
                    create_spawn("grape_bunch", 3.0, 0.25),
                    create_spawn("pomegranate", 6.5, 0.75),
                    create_spawn("tomato", 10.0, 0.35),
                    create_spawn("ananas", 13.5, 0.65),
                    create_spawn("coconut", 17.0, 0.20),
                    create_spawn("grape_bunch", 20.5, 0.80),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("grape_bunch", 0.5, 0.35),
                    create_spawn("coconut", 3.0, 0.65),
                    create_spawn("ananas", 6.0, 0.20),
                    create_spawn("pomegranate", 9.5, 0.80),
                    create_spawn("tomato", 13.0, 0.50),
                    create_spawn("coconut", 16.5, 0.30),
                    create_spawn("grape_bunch", 19.5, 0.70),
                    create_spawn("ananas", 23.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("coconut", 3.0, 0.70),
                    create_spawn("grape_bunch", 6.5, 0.50),
                    create_spawn("pomegranate", 9.5, 0.25),
                    create_spawn("ananas", 13.0, 0.75),
                    create_spawn("tomato", 16.5, 0.40),
                    create_spawn("coconut", 19.5, 0.60),
                    create_spawn("grape_bunch", 23.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.25),
                    create_spawn("coconut", 2.8, 0.75),
                    create_spawn("watermelon", 6.0, 0.50),
                    create_spawn("grape_bunch", 9.5, 0.35),
                    create_spawn("pomegranate", 13.0, 0.65),
                    create_spawn("ananas", 16.5, 0.20),
                    create_spawn("ananas", 19.5, 0.80),
                    create_spawn("coconut", 23.0, 0.50),
                ]
            }
        ]
    })

    # Niveau 5 : Marée de Pastèques (~2 min, 4 sous-vagues, 38 mobs)
    w2_levels.append({
        "number": 5,
        "title": "Marée de Pastèques",
        "description": "Les pastèques s'échouent par grappes le long de la plage de sucre.",
        "star_thresholds": [6000, 12800, 20500],
        "rewards": { "gold": 250, "diamonds": 9, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("coconut", 3.0, 0.70),
                    create_spawn("tomato", 6.5, 0.20),
                    create_spawn("ananas", 10.0, 0.80),
                    create_spawn("pomegranate", 13.5, 0.50),
                    create_spawn("tomato", 17.0, 0.35),
                    create_spawn("watermelon", 20.5, 0.65),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("coconut", 3.0, 0.25),
                    create_spawn("coconut", 6.0, 0.75),
                    create_spawn("pomegranate", 9.5, 0.35),
                    create_spawn("ananas", 13.0, 0.65),
                    create_spawn("grape_bunch", 16.5, 0.50),
                    create_spawn("tomato", 19.5, 0.20),
                    create_spawn("watermelon", 23.0, 0.80),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.30),
                    create_spawn("watermelon", 3.0, 0.70),
                    create_spawn("coconut", 6.5, 0.50),
                    create_spawn("pomegranate", 9.5, 0.25),
                    create_spawn("ananas", 13.0, 0.75),
                    create_spawn("grape_bunch", 16.5, 0.50),
                    create_spawn("coconut", 19.5, 0.35),
                    create_spawn("coconut", 23.0, 0.65),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 2.8, 0.75),
                    create_spawn("coconut", 6.0, 0.50),
                    create_spawn("pomegranate", 9.5, 0.30),
                    create_spawn("pomegranate", 13.0, 0.70),
                    create_spawn("ananas", 16.5, 0.50),
                    create_spawn("grape_bunch", 19.5, 0.20),
                    create_spawn("watermelon", 23.0, 0.80),
                ]
            }
        ]
    })

    # Niveau 6 : Bombardement Fruité (~2 min, 4 sous-vagues, 40 mobs)
    w2_levels.append({
        "number": 6,
        "title": "Bombardement Fruité",
        "description": "Une escouade de grenades et noix de coco pilonne les deux flippers.",
        "star_thresholds": [6800, 14000, 22500],
        "rewards": { "gold": 280, "diamonds": 10, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.30),
                    create_spawn("pomegranate", 3.0, 0.70),
                    create_spawn("coconut", 6.5, 0.50),
                    create_spawn("ananas", 10.0, 0.20),
                    create_spawn("tomato", 13.5, 0.80),
                    create_spawn("coconut", 17.0, 0.35),
                    create_spawn("pomegranate", 20.5, 0.65),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.25),
                    create_spawn("coconut", 3.0, 0.75),
                    create_spawn("watermelon", 6.0, 0.50),
                    create_spawn("ananas", 9.5, 0.35),
                    create_spawn("pomegranate", 13.0, 0.65),
                    create_spawn("tomato", 16.5, 0.20),
                    create_spawn("coconut", 19.5, 0.80),
                    create_spawn("grape_bunch", 23.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("coconut", 3.0, 0.70),
                    create_spawn("pomegranate", 6.5, 0.50),
                    create_spawn("pomegranate", 9.5, 0.25),
                    create_spawn("ananas", 13.0, 0.75),
                    create_spawn("watermelon", 16.5, 0.50),
                    create_spawn("pomegranate", 19.5, 0.35),
                    create_spawn("coconut", 23.0, 0.65),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("watermelon", 3.0, 0.65),
                    create_spawn("coconut", 6.5, 0.20),
                    create_spawn("coconut", 9.5, 0.80),
                    create_spawn("pomegranate", 13.0, 0.50),
                    create_spawn("ananas", 16.5, 0.30),
                    create_spawn("ananas", 19.5, 0.70),
                    create_spawn("pomegranate", 23.0, 0.50),
                ]
            }
        ]
    })

    # Niveau 7 : Les Dunes Scintillantes (~2 min, 4 sous-vagues, 42 mobs)
    w2_levels.append({
        "number": 7,
        "title": "Les Dunes Scintillantes",
        "description": "Les forces sucrées se regroupent en colonnes serrées sur les dunes.",
        "star_thresholds": [7500, 15500, 24500],
        "rewards": { "gold": 310, "diamonds": 11, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.35),
                    create_spawn("watermelon", 3.0, 0.70),
                    create_spawn("ananas", 6.0, 0.20),
                    create_spawn("pomegranate", 9.5, 0.80),
                    create_spawn("grape_bunch", 13.0, 0.50),
                    create_spawn("coconut", 16.5, 0.30),
                    create_spawn("ananas", 20.0, 0.70),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.30),
                    create_spawn("coconut", 3.0, 0.65),
                    create_spawn("pomegranate", 6.0, 0.25),
                    create_spawn("grape_bunch", 9.5, 0.75),
                    create_spawn("ananas", 13.0, 0.50),
                    create_spawn("coconut", 16.5, 0.85),
                    create_spawn("tomato", 19.5, 0.20),
                    create_spawn("watermelon", 23.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.25),
                    create_spawn("coconut", 2.8, 0.75),
                    create_spawn("watermelon", 6.0, 0.50),
                    create_spawn("pomegranate", 9.0, 0.35),
                    create_spawn("ananas", 12.5, 0.65),
                    create_spawn("grape_bunch", 16.0, 0.50),
                    create_spawn("pomegranate", 19.5, 0.20),
                    create_spawn("coconut", 22.5, 0.80),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 2.8, 0.75),
                    create_spawn("coconut", 6.0, 0.50),
                    create_spawn("pomegranate", 9.0, 0.30),
                    create_spawn("pomegranate", 12.5, 0.70),
                    create_spawn("ananas", 16.0, 0.50),
                    create_spawn("coconut", 19.0, 0.20),
                    create_spawn("coconut", 22.5, 0.80),
                ]
            }
        ]
    })

    # Niveau 8 : Tempête de Nectar (~2 min, 5 sous-vagues, 46 mobs)
    w2_levels.append({
        "number": 8,
        "title": "Tempête de Nectar",
        "description": "Cinq vagues impitoyables avant d'approcher le palais côtier de Carambine.",
        "star_thresholds": [8500, 17500, 27000],
        "rewards": { "gold": 350, "diamonds": 12, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("ananas", 2.8, 0.70),
                    create_spawn("pomegranate", 5.5, 0.50),
                    create_spawn("tomato", 8.5, 0.20),
                    create_spawn("coconut", 11.5, 0.80),
                    create_spawn("ananas", 15.0, 0.35),
                    create_spawn("watermelon", 18.5, 0.65),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.35),
                    create_spawn("coconut", 2.8, 0.65),
                    create_spawn("pomegranate", 5.8, 0.25),
                    create_spawn("ananas", 9.0, 0.75),
                    create_spawn("grape_bunch", 12.0, 0.50),
                    create_spawn("tomato", 15.0, 0.20),
                    create_spawn("coconut", 18.5, 0.80),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("coconut", 2.8, 0.70),
                    create_spawn("watermelon", 5.8, 0.50),
                    create_spawn("pomegranate", 9.0, 0.25),
                    create_spawn("ananas", 12.0, 0.75),
                    create_spawn("grape_bunch", 15.5, 0.35),
                    create_spawn("pomegranate", 18.5, 0.65),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 3.0, 0.75),
                    create_spawn("coconut", 6.0, 0.50),
                    create_spawn("pomegranate", 9.0, 0.35),
                    create_spawn("ananas", 12.5, 0.65),
                    create_spawn("grape_bunch", 15.5, 0.50),
                    create_spawn("coconut", 18.5, 0.20),
                ]
            },
            {
                "subwave": 5,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.50),
                    create_spawn("coconut", 2.8, 0.25),
                    create_spawn("coconut", 5.5, 0.75),
                    create_spawn("pomegranate", 8.5, 0.35),
                    create_spawn("ananas", 11.5, 0.65),
                    create_spawn("grape_bunch", 15.0, 0.50),
                    create_spawn("watermelon", 18.0, 0.20),
                    create_spawn("watermelon", 21.0, 0.80),
                ]
            }
        ]
    })

    # Niveau 9 : L'Ultime Rempart Côtier (~2 min, 5 sous-vagues, 50 mobs)
    w2_levels.append({
        "number": 9,
        "title": "L'Ultime Rempart Côtier",
        "description": "La garde personnelle de Carambine déploie ses blindages les plus solides.",
        "star_thresholds": [9500, 19500, 30000],
        "rewards": { "gold": 400, "diamonds": 15, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.35),
                    create_spawn("watermelon", 2.8, 0.70),
                    create_spawn("pomegranate", 5.5, 0.20),
                    create_spawn("ananas", 8.5, 0.80),
                    create_spawn("grape_bunch", 12.0, 0.50),
                    create_spawn("coconut", 15.0, 0.35),
                    create_spawn("tomato", 18.0, 0.65),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("coconut", 2.8, 0.65),
                    create_spawn("pomegranate", 5.5, 0.50),
                    create_spawn("ananas", 8.5, 0.75),
                    create_spawn("grape_bunch", 12.0, 0.30),
                    create_spawn("coconut", 15.0, 0.85),
                    create_spawn("pomegranate", 18.5, 0.40),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.30),
                    create_spawn("coconut", 2.8, 0.70),
                    create_spawn("watermelon", 5.8, 0.50),
                    create_spawn("pomegranate", 8.8, 0.25),
                    create_spawn("ananas", 12.0, 0.75),
                    create_spawn("grape_bunch", 15.0, 0.40),
                    create_spawn("pomegranate", 18.5, 0.60),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 2.8, 0.75),
                    create_spawn("coconut", 5.5, 0.50),
                    create_spawn("pomegranate", 8.5, 0.35),
                    create_spawn("pomegranate", 11.5, 0.65),
                    create_spawn("ananas", 15.0, 0.20),
                    create_spawn("grape_bunch", 18.0, 0.80),
                ]
            },
            {
                "subwave": 5,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 2.5, 0.75),
                    create_spawn("coconut", 5.5, 0.50),
                    create_spawn("pomegranate", 8.5, 0.30),
                    create_spawn("pomegranate", 11.5, 0.70),
                    create_spawn("grape_bunch", 14.5, 0.50),
                    create_spawn("ananas", 17.5, 0.20),
                    create_spawn("coconut", 20.5, 0.80),
                ]
            }
        ]
    })

    # Niveau 10 : L'Étoile du Rivage : Carambine (~5 min Boss Encounter !)
    # Subwaves 1 à 3 : Gauntlet d'avant-garde (~2 min total)
    # Subwave 4 : Boss Carambine (240 PV, dashs, étoiles, danse d'invocation, squat laser) (~3 min duel)
    w2_levels.append({
        "number": 10,
        "title": "L'Étoile du Rivage : Carambine",
        "description": "La bondissante Carambine s'abat sur la Plage Sucrée ! Neutralise son laser et surmonte ses danses d'invocation !",
        "star_thresholds": [14000, 28000, 48000],
        "rewards": { "gold": 800, "diamonds": 40, "booster": "diamond_dust" },
        "waves": [
            {
                "subwave": 1,
                "spawns": [
                    create_spawn("coconut", 0.5, 0.35),
                    create_spawn("watermelon", 3.0, 0.70),
                    create_spawn("pomegranate", 6.0, 0.20),
                    create_spawn("ananas", 9.0, 0.80),
                    create_spawn("tomato", 12.5, 0.50),
                    create_spawn("coconut", 16.0, 0.30),
                    create_spawn("ananas", 19.5, 0.70),
                    create_spawn("watermelon", 23.0, 0.50),
                ]
            },
            {
                "subwave": 2,
                "spawns": [
                    create_spawn("pomegranate", 0.5, 0.30),
                    create_spawn("pomegranate", 3.0, 0.70),
                    create_spawn("coconut", 6.5, 0.50),
                    create_spawn("ananas", 9.5, 0.25),
                    create_spawn("grape_bunch", 13.0, 0.75),
                    create_spawn("watermelon", 16.5, 0.50),
                    create_spawn("tomato", 19.5, 0.20),
                    create_spawn("coconut", 22.5, 0.80),
                    create_spawn("pomegranate", 26.0, 0.50),
                ]
            },
            {
                "subwave": 3,
                "spawns": [
                    create_spawn("watermelon", 0.5, 0.25),
                    create_spawn("watermelon", 3.0, 0.75),
                    create_spawn("coconut", 6.5, 0.50),
                    create_spawn("pomegranate", 9.5, 0.35),
                    create_spawn("pomegranate", 13.0, 0.65),
                    create_spawn("grape_bunch", 16.5, 0.50),
                    create_spawn("ananas", 19.5, 0.20),
                    create_spawn("coconut", 22.5, 0.80),
                    create_spawn("watermelon", 26.0, 0.50),
                ]
            },
            {
                "subwave": 4,
                "spawns": [
                    create_spawn("boss_carambine", 1.0, 0.50)
                ]
            }
        ]
    })

    worlds.append({
        "id": "world_2",
        "world_number": 2,
        "display_name": "Plage Sucrée",
        "subtitle": "Le rivage de sucre rose et d'océan pétillant",
        "completion_reward_booster_id": "diamond_dust",
        "levels": w2_levels
    })

    return { "worlds": worlds }

if __name__ == "__main__":
    catalog = build_levels()
    output_path = os.path.join(os.path.dirname(__file__), "..", "data", "campaign_levels.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    print("Fichier généré avec succès dans:", output_path)
