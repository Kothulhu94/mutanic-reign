# CornFarm.gd
extends ProducerBuilding
class_name CornFarm

@export var corn_texture: Texture2D

func _ready() -> void:
	product_item_id = &"Corn"
	var spr := $Sprite2D as Sprite2D
	if spr and corn_texture:
		spr.texture = corn_texture
	super._ready()
