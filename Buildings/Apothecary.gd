# Apothecary.gd
extends ProcessorBuilding
class_name Apothecary

@export var apothecary_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and apothecary_texture:
		spr.texture = apothecary_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"Potion"
