extends Node

signal fuel_changed(value: float)
signal rations_changed(value: float)

var is_time_running: bool = false

# Backing storage
var _fuel: float = 100.0
var _rations: float = 100.0

# Public properties that emit signals when changed
var fuel: float:
	get:
		return _fuel
	set(value):
		_fuel = clamp(value, 0.0, 9999.0)
		fuel_changed.emit(_fuel)

var rations: float:
	get:
		return _rations
	set(value):
		_rations = clamp(value, 0.0, 9999.0)
		rations_changed.emit(_rations)

func _ready() -> void:
	print("GameState ready")
	Timekeeper.tick.connect(_on_tick)  # hook Timekeeper's signal to our handler


func _on_tick(step: float) -> void:
	if !is_time_running: return
	# ~0.2 fuel/sec and ~0.1 rations/sec (tweak later)
	fuel    -= 0.2 * step * 10.0
	rations -= 0.1 * step * 10.0
