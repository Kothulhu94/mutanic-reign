# Jeweler.gd
extends ProcessorBuilding
class_name Jeweler

@export var jeweler_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and jeweler_texture:
		spr.texture = jeweler_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"Jewelry"
