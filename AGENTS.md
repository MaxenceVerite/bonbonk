# Directives & Standards d'Architecture : Flip (Mobile-First Pinball Defense)

Ce document formalise les règles d'architecture, de conception logicielle, de performance et d'UX mobile pour le jeu **Flip** développé sous **Godot 4.x**.

---

## 1. Vue d'ensemble du Projet & Philosophie

- **Genre** : Flipper / Arcade Defense (empecher les ennemis d'atteindre la zone basse).
- **Plateforme cible** : Mobile-first (Portrait : base viewport `720x1280`, mode stretch `canvas_items` / `expand`).
- **Moteur & Langage** : Godot 4.x (GDScript statiquement typé).
- **Priorités fondamentales** :
  1. **Game Feel & Juiciness** (réactivité tactile immédiate, physique percutante, feedback haptique/visuel).
  2. **Performance mobile** (60/120 FPS constant, zéro allocation frame par frame, gestion rigoureuse des Draw Calls).
  3. **Maintenabilité & Modularité** (composition, découplage par signaux, Event Bus, Custom Resources).

---

## 2. Principes Fondamentaux Godot 4

### Règle d'or : "Call Down, Signal Up"
- Un nœud parent appelle directement les méthodes publiques de ses enfants directs : `flipper.activate()`.
- Un nœud enfant **ne référence jamais son parent directement**. Il émet un signal : `signal enemy_escaped(enemy: Enemy)`.
- Pour les communications inter-systèmes éloignées (ex: score, game over, sound trigger), utiliser un **EventBus** global (Autoload).

### Typage Statique Strict en GDScript
- Spécifier systématiquement les types de paramètres, types de retour et variables.
  ```gdscript
  var current_score: int = 0
  func take_damage(amount: int) -> void:
  ```
- Donner des classes explicites via `class_name` pour bénéficier de l'auto-complétion, du pattern matching et de l'inspecteur d'export.

### Composition plutôt qu'Héritage
- Préférer attacher des sous-composants dédiés :
  - `HealthComponent`
  - `HitboxComponent` / `HurtboxComponent`
  - `ScoreValueComponent`
- Éviter les hiérarchies d'héritage profondes (`Node2D` -> `Entity` -> `LivingEntity` -> `CombatEntity` -> `Enemy` -> `FastEnemy`).

### Utilisation des Resources (`Resource`) pour la Data
- Toutes les données de configuration (types d'ennemis, vagues, stats de flip, multiplicateurs de score) doivent être des `Resource` personnalisées (`EnemyData.tres`, `WaveConfig.tres`).
- Bénéfices : modifiable à chaud sans toucher au code, interchangeable, testable unitairement.

---

## 3. Structure du Projet

```text
res://
├── assets/
│   ├── audio/           # Musiques (Ogg) et SFX (Wav)
│   ├── fonts/           # Polices TTF / OTF lisibles sur mobile
│   ├── sprites/         # Textures et atlas
│   └── shaders/         # Shaders optimisés pour mobile
├── scenes/
│   ├── board/           # Table de flipper, bumpers, murs, flippers, outlanes
│   ├── ball/            # Bille et physique associée
│   ├── enemies/         # Différents types d'ennemis
│   ├── ui/              # HUD, menus, Game Over, pause
│   └── main.tscn        # Scène principale orchestratrice
├── scripts/
│   ├── autoload/        # EventBus, AudioManager, SaveManager, GameState
│   ├── components/      # Health, Hitbox, Hurtbox, DropOnDeath
│   ├── core/            # Boucle de jeu, Spawner, GameLoop
│   └── data/            # Classes Custom Resource (ex: EnemyData.gd)
└── resources/           # Instances de .tres (stats ennemis, configurations de niveaux)
```

---

## 4. Physique & Game Feel (Spécificités Flipper)

1. **Précision Physique (`physics_ticks_per_second`)** :
   - Pour un jeu de flipper, la physique standard à 60 Hz peut provoquer du tunneling (bille passant à travers un flipper rapide).
   - Ajuster `physics/common/physics_ticks_per_second` à **120** ou utiliser le Continuous Collision Detection (`continuous_cd`) sur le `RigidBody2D` de la bille.
2. **Couches de Collision (`Collision Layers & Masks`)** :
   - Toujours nommer explicitement les layers dans `Project Settings -> Layer Names -> 2D Physics` :
     - Layer 1 : `Ball`
     - Layer 2 : `Flippers`
     - Layer 3 : `Walls_Borders`
     - Layer 4 : `Enemies`
     - Layer 5 : `Bumpers_Targets`
     - Layer 6 : `Danger_Zone` (bas de l'écran)
3. **Réactivité des Flippers** :
   - Les flippers doivent réagir à la frame près (pas d'interpolation lente à l'input).
   - Décomposer l'input : écran divisé en 2 moitiés tactiles (gauche = flipper gauche, droite = flipper droit).

---

## 5. Ergonomie & UX Mobile-First

1. **Contrôles Tactiles** :
   - Écran séparé en 2 zones d'input invisibles larges (aucun bouton virtuel minuscule requis pour actionner les batteurs).
   - Prise en charge naturelle du jeu à 2 pouces en tenue portrait.
   - Support du multitouch fiable (pouvoir maintenir un batteur levé tout en activant l'autre).
2. **Safe Area & Encoches** :
   - Prendre en compte le safe area (`DisplayServer.get_display_safe_area()`) pour que le HUD (score, vies) ne soit pas masqué par une encoche ou la barre système.
3. **Taille des Cibles Tactiles & Typographie** :
   - Boutons de menus : minimum 48x48 dp (viser 64px+ pour confort).
   - Textes contrastés, grands et lisibles en jeu d'action rapide.
4. **Pause Automatique** :
   - Mettre en pause le jeu lors de la notification `NOTIFICATION_APPLICATION_FOCUS_OUT` ou `NOTIFICATION_WM_WINDOW_FOCUS_OUT`.

---

## 6. Performance & Optimisation Mobile

1. **Object Pools (Piscines d'objets)** :
   - **Interdiction formelle** de faire des `instantiate()` et `queue_free()` massifs à chaque tir, ennemi ou particule.
   - Utiliser un `NodePool` ou `ObjectPool` pour les ennemis, projectiles et effets visuels récurrents.
2. **Gestion de la Mémoire & Garbage Collection** :
   - Éviter d'allouer des dictionnaires ou tableaux temporaires dans `_process()` ou `_physics_process()`.
3. **Moteur de Rendu Mobile** :
   - Méthode de rendu : `mobile` (ou `gl_compatibility` pour les téléphones d'entrée de gamme).
   - Préférer `CPUParticles2D` ou `GPUParticles2D` avec des textures simples et émetteurs limités.
   - Regrouper les sprites dans des Atlas / Texture Sheets pour minimiser les draw calls.
4. **Vibrations / Haptics** :
   - Utiliser `Input.vibrate_handheld(ms)` lors des impacts forts (flipper, bumper, ennemi détruit) pour renforcer le punch tactile, avec une option de désactivation dans les paramètres.

---

## 7. Checklist Qualité de Code pour toute PR / Ajout

- [ ] Tout script GDScript utilise le typage statique (`: Type` et `-> void`).
- [ ] Aucune recherche coûteuse répétée (`get_node("../../../")` proscrit, utiliser des `@onready @export var` ou signaux).
- [ ] Les collisions utilisent les masques/layers nommés.
- [ ] Pas d'instanciation sauvage sans pooling pour les entités éphémères.
- [ ] Le code respecte le principe de responsabilité unique (SRP).
- [ ] L'input fonctionne aussi bien à la souris (émulation tactile) que sur véritable écran tactile multitouch.
