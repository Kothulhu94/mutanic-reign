# FishFarm.gd
extends ProducerBuilding
class_name FishFarm

@export var fish_texture: Texture2D

func _ready() -> void:
	product_item_id = &"Fish"
	var spr := $Sprite2D as Sprite2D
	if spr and fish_texture:
		spr.texture = fish_texture
	super._ready()
