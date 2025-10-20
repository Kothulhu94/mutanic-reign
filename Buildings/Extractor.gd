# Extractor.gd
extends ProcessorBuilding
class_name Extractor

@export var extractor_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and extractor_texture:
		spr.texture = extractor_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"HempOil"
