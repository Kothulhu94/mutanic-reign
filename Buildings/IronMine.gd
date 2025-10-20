# IronMine.gd
extends ProducerBuilding
class_name IronMine

@export var iron_texture: Texture2D

func _ready() -> void:
	product_item_id = &"Iron"
	var spr := $Sprite2D as Sprite2D
	if spr and iron_texture:
		spr.texture = iron_texture
	super._ready()
