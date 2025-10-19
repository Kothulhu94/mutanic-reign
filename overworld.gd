extends Node2D

@export var bus_scene: PackedScene = preload("res://Actors/Bus.tscn")
@export var camera_scene: PackedScene = preload("res://Actors/PlayerCamera.tscn")
@export var caravan_scene: PackedScene = preload("res://Actors/Caravan.tscn")

@export var map_origin: Vector2 = Vector2.ZERO
@export var chunk_size: Vector2i = Vector2i(512, 512)
@export var bus_spawn_point: Vector2 = Vector2(125, 125)

# Caravan system
@export var item_db: ItemDB
@export var caravan_types: Array[CaravanType] = []
@export var caravan_spawn_interval: float = 30.0  # Check for spawning every 30 seconds
var caravan_spawn_timer: float = 0.0
var active_caravans: Array[Caravan] = []

var bus: CharacterBody2D
var cam: Camera2D
@onready var path_line: Line2D = get_node_or_null("PathLine")

func _ready() -> void:
	await _await_nav_ready()
	if path_line == null:
		path_line = Line2D.new()
		path_line.name = "PathLine"
		path_line.width = 3.0
		add_child(path_line)
	bus = bus_scene.instantiate() as CharacterBody2D
	add_child(bus)
	var spawn_base: Vector2 = map_origin + bus_spawn_point
	var snapped_pos: Vector2 = _snap_to_nav(spawn_base)
	var final_position: Vector2
	if snapped_pos == Vector2.ZERO and spawn_base != Vector2.ZERO:
		final_position = spawn_base
	else:
		final_position = snapped_pos
	bus.global_position = final_position
	var agent := bus.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if agent:
		agent.navigation_layers = 1
		agent.target_position = final_position
	cam = camera_scene.instantiate() as Camera2D
	add_child(cam)
	cam.global_position = final_position
	cam.set("bus", bus)
	cam.set("map_origin", Vector2.ZERO)
	cam.set("map_size", Vector2(8192, 8192))
	cam.enabled = true

	# Load default ItemDB if not set
	if item_db == null:
		item_db = load("res://data/Items/ItemsCatalog.tres")

	# Load default caravan types if not set
	if caravan_types.is_empty():
		caravan_types = [
			load("res://data/Caravans/FoodTrader.tres"),
			load("res://data/Caravans/MaterialTrader.tres"),
			load("res://data/Caravans/LuxuryTrader.tres"),
			load("res://data/Caravans/MedicalTrader.tres")
		]

func _process(delta: float) -> void:
	# Update caravan spawn timer
	caravan_spawn_timer += delta
	if caravan_spawn_timer >= caravan_spawn_interval:
		caravan_spawn_timer = 0.0
		_try_spawn_caravans()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if bus == null:
			return
		var click_pos: Vector2 = get_global_mouse_position()
		var safe_target: Vector2 = _snap_to_nav(click_pos)
		var nav_map := get_world_2d().navigation_map
		var nav_path: PackedVector2Array = NavigationServer2D.map_get_path(nav_map, bus.global_position, safe_target, false)
		_set_path_line(nav_path)
		var agent := bus.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
		if agent:
			agent.target_position = safe_target

func _snap_to_nav(p: Vector2) -> Vector2:
	var nav_map := get_world_2d().navigation_map
	return NavigationServer2D.map_get_closest_point(nav_map, p)

func _set_path_line(points_world: PackedVector2Array) -> void:
	if path_line == null:
		return
	var local := PackedVector2Array()
	local.resize(points_world.size())
	for i in points_world.size():
		local[i] = to_local(points_world[i])
	path_line.points = local

func _await_nav_ready() -> void:
	var nav_map := get_world_2d().navigation_map
	var guard: int = 0
	while NavigationServer2D.map_get_iteration_id(nav_map) == 0 and guard < 30:
		await get_tree().process_frame
		guard += 1

# ============================================================
# Caravan Spawning System
# ============================================================
func _try_spawn_caravans() -> void:
	if item_db == null:
		print("[Caravan Spawner] ItemDB is null - cannot spawn caravans")
		return

	if caravan_types.is_empty():
		print("[Caravan Spawner] No caravan types configured")
		return

	var hubs: Array[Hub] = _get_all_hubs()
	if hubs.is_empty():
		print("[Caravan Spawner] No hubs found in scene")
		return

	print("[Caravan Spawner] Checking %d hubs for caravan spawning..." % hubs.size())

	# Try to spawn a caravan from each hub
	for hub in hubs:
		_try_spawn_caravan_from_hub(hub, hubs)

func _try_spawn_caravan_from_hub(home_hub: Hub, all_hubs: Array[Hub]) -> void:
	if home_hub == null:
		print("[Caravan Spawner] Hub is null")
		return

	if home_hub.item_db == null:
		print("[Caravan Spawner] Hub '%s' has no ItemDB assigned" % home_hub.name)
		return

	print("[Caravan Spawner] Checking hub '%s' (inventory: %d items)" % [home_hub.name, home_hub.state.inventory.size()])

	# Check each caravan type to see if hub has surplus of preferred items
	for caravan_type: CaravanType in caravan_types:
		if caravan_type == null:
			continue

		# Check if this hub has surplus of this type's preferred items
		var has_surplus: bool = _hub_has_surplus_for_type(home_hub, caravan_type)
		if not has_surplus:
			print("  - %s: No surplus" % caravan_type.type_id)
			continue

		# Check if there's already an active caravan of this type from this hub
		var already_has_caravan: bool = false
		for caravan in active_caravans:
			if caravan.home_hub == home_hub and caravan.caravan_state.caravan_type == caravan_type:
				already_has_caravan = true
				break

		if already_has_caravan:
			print("  - %s: Already has active caravan" % caravan_type.type_id)
			continue

		# Spawn the caravan
		print("  - %s: SPAWNING CARAVAN!" % caravan_type.type_id)
		_spawn_caravan(home_hub, caravan_type, all_hubs)
		break  # Only spawn one caravan per hub per check

func _hub_has_surplus_for_type(hub: Hub, caravan_type: CaravanType) -> bool:
	if hub == null or hub.item_db == null or caravan_type == null:
		return false

	var preferred_tags: Array[StringName] = caravan_type.preferred_tags
	if preferred_tags.is_empty():
		return false

	var surplus_threshold: float = 200.0
	if hub.economy_config != null:
		surplus_threshold = hub.economy_config.caravan_surplus_threshold

	for item_id: StringName in hub.state.inventory.keys():
		var stock: int = hub.state.inventory.get(item_id, 0)
		if stock <= surplus_threshold:
			continue

		# Check if item has any preferred tag
		for tag: StringName in preferred_tags:
			if hub.item_db.has_tag(item_id, tag):
				# Check if hub has positive surplus level
				var has_positive_surplus: bool = false
				if hub.item_db.has_tag(item_id, &"food"):
					has_positive_surplus = hub.food_level > 0.0
				elif hub.item_db.has_tag(item_id, &"material"):
					has_positive_surplus = hub.infrastructure_level > 0.0
				else:
					# For other types (luxury, medical), just check stock
					has_positive_surplus = true

				if has_positive_surplus:
					return true

	return false

func _spawn_caravan(home_hub: Hub, caravan_type: CaravanType, all_hubs: Array[Hub]) -> void:
	if caravan_scene == null:
		return

	var caravan: Caravan = caravan_scene.instantiate() as Caravan
	if caravan == null:
		return

	# Create caravan state
	var starting_money: int = caravan_type.get_starting_money(home_hub.state.base_population_cap)
	var state: CaravanState = CaravanState.new(home_hub.state.hub_id, StringName(), starting_money, caravan_type)

	# Set surplus threshold from config
	if home_hub.economy_config != null:
		caravan.surplus_threshold = home_hub.economy_config.caravan_surplus_threshold
		caravan.home_tax_rate = home_hub.economy_config.caravan_home_tax_rate

	# Set sprite texture from caravan type
	var sprite: Sprite2D = caravan.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null and caravan_type.sprite != null:
		sprite.texture = caravan_type.sprite

	# Setup and add to scene
	caravan.setup(home_hub, state, item_db, all_hubs)
	add_child(caravan)
	active_caravans.append(caravan)

	# Connect cleanup signal when caravan is freed
	caravan.tree_exited.connect(_on_caravan_removed.bind(caravan))

func _on_caravan_removed(caravan: Caravan) -> void:
	active_caravans.erase(caravan)

func _get_all_hubs() -> Array[Hub]:
	var hubs: Array[Hub] = []
	for child in get_children():
		if child is Hub:
			hubs.append(child as Hub)
	return hubs
