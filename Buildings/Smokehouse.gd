# Smokehouse.gd
extends ProcessorBuilding
class_name Smokehouse

@export var smokehouse_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and smokehouse_texture:
		spr.texture = smokehouse_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"SmokedFish"
