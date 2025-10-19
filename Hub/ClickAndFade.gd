extends Area2D
class_name ClickAndFade

signal actor_entered(actor: Node)
signal actor_exited(actor: Node)

# Whitelist of actor scenes that should vanish while inside
@export var actor_scene_paths: Array[String] = [
	"res://Actors/Bus.tscn",
	"res://Actors/NPC.tscn" # add more as needed
]

var _prev_visible: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	var p := body.get_scene_file_path()
	if actor_scene_paths.has(p):
		_prev_visible[body] = (body as CanvasItem).visible if body is CanvasItem else true
		if body is CanvasItem:
			(body as CanvasItem).visible = false
		emit_signal("actor_entered", body)

func _on_body_exited(body: Node) -> void:
	if _prev_visible.has(body):
		if body is CanvasItem:
			(body as CanvasItem).visible = _prev_visible[body]
		_prev_visible.erase(body)
		emit_signal("actor_exited", body)
