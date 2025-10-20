# MushroomProcessor.gd
extends ProcessorBuilding
class_name MushroomProcessor

@export var mushroom_processor_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and mushroom_processor_texture:
		spr.texture = mushroom_processor_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"MushroomExtract"
