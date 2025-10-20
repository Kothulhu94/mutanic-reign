# Herbalist.gd
extends ProcessorBuilding
class_name Herbalist

@export var herbalist_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and herbalist_texture:
		spr.texture = herbalist_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"Salve"
