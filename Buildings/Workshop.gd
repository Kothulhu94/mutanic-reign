# Workshop.gd
extends ProcessorBuilding
class_name Workshop

@export var workshop_texture: Texture2D

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if spr and workshop_texture:
		spr.texture = workshop_texture
	super._ready()

func _compute_output_id(picked: StringName) -> StringName:
	# Scrap → ScrapPart, Iron → IronPart
	return StringName(String(picked) + "Part")
