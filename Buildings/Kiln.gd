# Kiln.gd
extends ProcessorBuilding
class_name Kiln

@export var kiln_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and kiln_texture:
		spr.texture = kiln_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"Brick"
