class_name NodePool
extends Node

## Gestionnaire de piscines d'objets générique (Object Pooling Pattern).
## Recycle les nœuds récurrents (ennemis, billes, effets de jus) pour éliminer
## les allocations frame-par-frame et les saccades du Garbage Collector sur mobile.

var _pools: Dictionary = {} # StringName ou PackedScene -> Array[Node]
var _node_to_key: Dictionary = {} # Node -> Variant (clé de pool)

## Récupère une instance recyclée ou instancie une nouvelle si la réserve est vide
func acquire(scene: PackedScene, key: Variant = null) -> Node:
	if scene == null:
		return null

	var pool_key: Variant = key if key != null else scene
	if not _pools.has(pool_key):
		_pools[pool_key] = []

	var available_list: Array = _pools[pool_key]
	var node: Node = null

	while not available_list.is_empty():
		var candidate: Node = available_list.pop_back()
		if is_instance_valid(candidate):
			node = candidate
			break

	if node == null:
		node = scene.instantiate()
		_node_to_key[node] = pool_key

	_node_to_key[node] = pool_key
	_activate_node(node)
	return node

## Remet une instance dans la réserve au lieu de faire queue_free()
func release(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	var pool_key: Variant = _node_to_key.get(node, null)
	if pool_key == null:
		# Fallback de sécurité si le nœud ne venait pas du pool
		node.queue_free()
		return

	# 1. Neutralisation immédiate du gameplay (visibilité, process, position hors-champ)
	_deactivate_gameplay_immediate(node)

	# 2. Retrait physique et unparent différés pour respecter le PhysicsServer (interdiction pendant flushing queries)
	_deferred_cleanup_and_store.call_deferred(node, pool_key)

func prewarm(scene: PackedScene, count: int, parent: Node = null) -> void:
	if scene == null or count <= 0:
		return
	var target_parent: Node = parent if parent != null else self
	for i in range(count):
		var node: Node = acquire(scene)
		if node.get_parent() == null:
			target_parent.add_child(node)
		release(node)

func _activate_node(node: Node) -> void:
	node.visible = true
	node.set_process(true)
	node.set_physics_process(true)

	if node is RigidBody2D:
		var rb: RigidBody2D = node as RigidBody2D
		rb.freeze = false
		rb.linear_velocity = Vector2.ZERO
		rb.angular_velocity = 0.0

	if node is CollisionObject2D:
		var col_obj: CollisionObject2D = node as CollisionObject2D
		for owner_id in col_obj.get_shape_owners():
			col_obj.call_deferred(&"shape_owner_set_disabled", owner_id, false)

	if node.has_method(&"on_pool_acquire"):
		node.on_pool_acquire()

func _deactivate_gameplay_immediate(node: Node) -> void:
	node.visible = false
	node.set_process(false)
	node.set_physics_process(false)

	if node is Node2D:
		# Téléportation immédiate hors de l'écran pour éviter toute interaction physique résiduelle
		(node as Node2D).global_position = Vector2(-9999.0, -9999.0)

	if node is RigidBody2D:
		var rb: RigidBody2D = node as RigidBody2D
		rb.linear_velocity = Vector2.ZERO
		rb.angular_velocity = 0.0

	if node is CharacterBody2D:
		var cb: CharacterBody2D = node as CharacterBody2D
		cb.velocity = Vector2.ZERO

	if node.has_method(&"on_pool_release"):
		node.on_pool_release()

func _deferred_cleanup_and_store(node: Node, pool_key: Variant) -> void:
	if node == null or not is_instance_valid(node):
		return

	if node is RigidBody2D:
		(node as RigidBody2D).freeze = true

	if node is CollisionObject2D:
		var col_obj: CollisionObject2D = node as CollisionObject2D
		for owner_id in col_obj.get_shape_owners():
			col_obj.shape_owner_set_disabled(owner_id, true)

	# Retrait du parent différé pour ne jamais violer la règle du PhysicsServer
	if node.get_parent() != null:
		node.get_parent().remove_child(node)

	if not _pools.has(pool_key):
		_pools[pool_key] = []

	var available_list: Array = _pools[pool_key]
	if not available_list.has(node):
		available_list.append(node)

