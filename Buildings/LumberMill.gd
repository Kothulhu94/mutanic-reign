# LumberMill.gd
extends ProducerBuilding
class_name LumberMill

@export var lumber_texture: Texture2D

func _ready() -> void:
	product_item_id = &"Lumber"
	var spr := $Sprite2D as Sprite2D
	if spr and lumber_texture:
		spr.texture = lumber_texture
	super._ready()
