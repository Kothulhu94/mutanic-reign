# Brewery.gd
extends ProcessorBuilding
class_name Brewery

@export var brewery_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and brewery_texture:
		spr.texture = brewery_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"BrewedCoffee"
