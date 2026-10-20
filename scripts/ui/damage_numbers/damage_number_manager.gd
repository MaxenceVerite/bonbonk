class_name DamageNumberManager
extends Node

## Gestionnaire d'affichage des chiffres de dégâts et de soins (Damage Numbers).
## - Object Pooling strict (zéro allocation en combat).
## - Système Anti-Flood avec agrégation (stacking) sur les cibles rapides.
## - Couleurs sémantiques : Blanc (Directs), Orange (DoT Brûlure), Rouge (Joueur), Vert (Soin).

const DamageNumberLabelScript = preload("res://scripts/ui/damage_numbers/damage_number_label.gd")

# Couleurs conformes aux directives
const COLOR_DIRECT: Color = Color(1.0, 1.0, 1.0, 1.0)        # Blanc éclatant pour dégâts directs (billes, parades, explosions)
const COLOR_DOT: Color = Color(1.0, 0.55, 0.15, 1.0)         # Orange chaud pour DoT / Brûlure
const COLOR_PLAYER_DAMAGE: Color = Color(1.0, 0.22, 0.28, 1.0) # Rouge vif alarme pour le joueur (-X)
const COLOR_PLAYER_HEAL: Color = Color(0.28, 0.95, 0.45, 1.0)   # Vert menthe éclatant pour le soin (+X)

# Capacité de la réserve d'instances
const POOL_PREWARM_SIZE: int = 24
const MAX_ACTIVE_LABELS: int = 32

var _pool: Array = []
var _active_labels: Array = []

var _board_container: Node2D = null
var _hud_container: Node2D = null
var _player_hp_bar: Control = null

func setup(board_node: Node2D, hud_node: Control, hp_bar_node: Control) -> void:
	_player_hp_bar = hp_bar_node

	# 1. Conteneur dédié dans le plateau (pour les ennemis en coordonnées monde)
	if board_node != null:
		_board_container = Node2D.new()
		_board_container.name = "DamageNumbersContainer"
		_board_container.z_index = 60
		board_node.add_child(_board_container)

	# 2. Conteneur dédié dans le HUD (pour les dégâts/soins du joueur en coordonnées Canvas)
	if hud_node != null:
		_hud_container = Node2D.new()
		_hud_container.name = "HUDDamageNumbersContainer"
		_hud_container.z_index = 70
		hud_node.add_child(_hud_container)

	# 3. Pré-remplissage du pool
	_prewarm_pool()

	# 4. Connexion aux signaux de l'EventBus
	_connect_events()

func _prewarm_pool() -> void:
	for i in range(POOL_PREWARM_SIZE):
		var inst: Node2D = DamageNumberLabelScript.new()
		inst.animation_finished.connect(_on_label_finished)
		_pool.append(inst)

func _connect_events() -> void:
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_escaped.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)

func _acquire_label(parent_node: Node) -> Node2D:
	var label_inst: Node2D = null

	while not _pool.is_empty():
		var candidate: Variant = _pool.pop_back()
		if is_instance_valid(candidate) and candidate is Node2D:
			label_inst = candidate as Node2D
			break

	# Si le pool est temporairement vide, on recycle la plus ancienne active pour ne pas dépasser la limite
	if label_inst == null and not _active_labels.is_empty():
		label_inst = _active_labels.pop_front() as Node2D
		label_inst.reset_state()

	if label_inst == null:
		label_inst = DamageNumberLabelScript.new()
		label_inst.animation_finished.connect(_on_label_finished)

	if label_inst.get_parent() != parent_node:
		if label_inst.get_parent() != null:
			label_inst.get_parent().remove_child(label_inst)
		if parent_node != null:
			parent_node.add_child(label_inst)

	_active_labels.append(label_inst)
	return label_inst

func _on_label_finished(label_inst: Node2D) -> void:
	_active_labels.erase(label_inst)
	label_inst.reset_state()
	if not _pool.has(label_inst):
		_pool.append(label_inst)

# ==============================================================================
# GESTION DES IMPACTS SUR LES ENNEMIS
# ==============================================================================

func _on_enemy_damaged(enemy: Node2D, context: HitContext) -> void:
	if enemy == null or not is_instance_valid(enemy) or context == null:
		return
	if _board_container == null:
		return

	var dmg: int = context.final_damage
	if dmg <= 0:
		return

	# Détection du type de dégât (DoT vs Direct)
	var is_dot: bool = (context.damage_type == HitContext.DamageType.FIRE or context.damage_type == HitContext.DamageType.DOT)
	var color: Color = COLOR_DOT if is_dot else COLOR_DIRECT

	var is_crit: bool = context.is_parry or context.is_critical
	var font_size: int = 26 if is_crit else 22

	# Anti-Flood : vérification si un chiffre récent est déjà actif sur cet ennemi
	var stackable_label: Node2D = _find_stackable_label(enemy)
	if stackable_label != null:
		stackable_label.stack_damage(dmg)
		return

	# Point d'ancrage visuel flottant juste au-dessus de l'ennemi
	var spawn_pos: Vector2 = enemy.global_position + Vector2(0.0, -32.0)

	var label_inst: Node2D = _acquire_label(_board_container)
	label_inst.play_number(enemy, dmg, "", color, spawn_pos, font_size, is_crit)

func _find_stackable_label(target: Node) -> Node2D:
	for lbl in _active_labels:
		if is_instance_valid(lbl) and lbl.can_stack_with(target):
			return lbl as Node2D
	return null

# ==============================================================================
# GESTION DE LA BARRE DE VIE DU JOUEUR
# ==============================================================================

func _on_player_damaged(damage: int) -> void:
	if damage <= 0:
		return
	if _hud_container == null or _player_hp_bar == null:
		return

	# Ancrage juste au-dessus du centre de la barre de PV du joueur
	var bar_rect: Rect2 = _player_hp_bar.get_global_rect()
	var spawn_pos: Vector2 = bar_rect.position + Vector2(bar_rect.size.x * 0.5, -16.0)

	var label_inst: Node2D = _acquire_label(_hud_container)
	label_inst.play_number(null, damage, "-", COLOR_PLAYER_DAMAGE, spawn_pos, 28, true)

func _on_player_healed(amount: int) -> void:
	if amount <= 0:
		return
	if _hud_container == null or _player_hp_bar == null:
		return

	var bar_rect: Rect2 = _player_hp_bar.get_global_rect()
	var spawn_pos: Vector2 = bar_rect.position + Vector2(bar_rect.size.x * 0.5, -16.0)

	var label_inst: Node2D = _acquire_label(_hud_container)
	label_inst.play_number(null, amount, "+", COLOR_PLAYER_HEAL, spawn_pos, 26, false)

func clear_all() -> void:
	for lbl in _active_labels.duplicate():
		if is_instance_valid(lbl):
			_on_label_finished(lbl)

func _exit_tree() -> void:
	clear_all()
	for inst in _pool:
		if is_instance_valid(inst) and inst.get_parent() == null:
			inst.free()
	_pool.clear()
	_active_labels.clear()
