# GemMine.gd
extends ProducerBuilding
class_name GemMine

@export var gemmine_texture: Texture2D

func _ready() -> void:
	product_item_id = &"Gemstone"
	var spr := $Sprite2D as Sprite2D
	if spr and gemmine_texture:
		spr.texture = gemmine_texture
	super._ready()
