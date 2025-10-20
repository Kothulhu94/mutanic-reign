# Loom.gd
extends ProcessorBuilding
class_name Loom

@export var loom_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and loom_texture:
		spr.texture = loom_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"Fabric"
