extends CharacterBody2D
class_name Bus

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@export var move_speed := 200.0
var charactersheet: CharacterSheet
var _is_paused: bool = false

func _ready() -> void:
	charactersheet = CharacterSheet.new()
	# Connect to Timekeeper pause/resume signals
	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null:
		if timekeeper.has_signal("paused"):
			timekeeper.paused.connect(_on_timekeeper_paused)
		if timekeeper.has_signal("resumed"):
			timekeeper.resumed.connect(_on_timekeeper_resumed)

func _physics_process(_delta: float) -> void:
	# Don't move if paused
	if _is_paused:
		velocity = Vector2.ZERO
		return

	if agent:
		var next := agent.get_next_path_position()
		var to_next := next - global_position
		if to_next.length() > 1.0:
			velocity = to_next.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _on_timekeeper_paused() -> void:
	_is_paused = true

func _on_timekeeper_resumed() -> void:
	_is_paused = false
