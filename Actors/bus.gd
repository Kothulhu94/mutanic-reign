extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@export var move_speed := 200.0

func _physics_process(_delta: float) -> void:
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
