# SpiceGrinder.gd
extends ProcessorBuilding
class_name SpiceGrinder

@export var spice_grinder_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and spice_grinder_texture:
		spr.texture = spice_grinder_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	return &"GroundSpice"
