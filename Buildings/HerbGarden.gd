# HerbGarden.gd
extends ProducerBuilding
class_name HerbGarden

@export var herbs_texture: Texture2D

func _ready() -> void:
	product_item_id = &"Herbs"
	var spr := $Sprite2D as Sprite2D
	if spr and herbs_texture:
		spr.texture = herbs_texture
	super._ready()
