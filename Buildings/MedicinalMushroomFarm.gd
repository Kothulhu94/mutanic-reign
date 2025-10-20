# MedicinalMushroomFarm.gd
extends ProducerBuilding
class_name MedicinalMushroomFarm

@export var mushroom_texture: Texture2D

func _ready() -> void:
	product_item_id = &"MedicinalMushroom"
	var spr := $Sprite2D as Sprite2D
	if spr and mushroom_texture:
		spr.texture = mushroom_texture
	super._ready()
