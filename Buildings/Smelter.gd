# Smelter.gd
extends ProcessorBuilding
class_name Smelter

@export var smelter_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and smelter_texture:
		spr.texture = smelter_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"IronBar"
