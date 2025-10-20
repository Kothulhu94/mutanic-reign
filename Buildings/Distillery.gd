# Distillery.gd
extends ProcessorBuilding
class_name Distillery

@export var distillery_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and distillery_texture:
		spr.texture = distillery_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	# Corn → Ethanol, Wheat → Beer
	if picked == &"Corn":
		return &"Ethanol"
	elif picked == &"Wheat":
		return &"Beer"
	return StringName()
