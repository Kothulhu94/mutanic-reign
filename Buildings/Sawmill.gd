# Sawmill.gd
extends ProcessorBuilding
class_name Sawmill

@export var sawmill_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and sawmill_texture:
		spr.texture = sawmill_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"Plank"
