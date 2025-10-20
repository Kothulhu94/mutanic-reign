# SpiceFarm.gd
extends ProducerBuilding
class_name SpiceFarm

@export var spice_texture: Texture2D

func _ready() -> void:
	product_item_id = &"Spice"
	var spr := $Sprite2D as Sprite2D
	if spr and spice_texture:
		spr.texture = spice_texture
	super._ready()
