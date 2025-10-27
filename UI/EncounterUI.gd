extends Control
class_name EncounterUI

## Emitted when combat concludes (win, loss, or retreat)
signal combat_ended(attacker: Node2D, defender: Node2D, winner: Node2D)
## Emitted when retreat button is pressed
signal retreat_pressed()

@onready var retreat_button: Button = $Panel/VBoxContainer/RetreatButton

var _attacker: Node2D = null
var _defender: Node2D = null
var _combat_active: bool = false

func _ready() -> void:
	hide()
	if retreat_button != null:
		retreat_button.pressed.connect(_on_retreat_pressed)

## Opens the encounter UI and starts automatic combat
func open_encounter(attacker: Node2D, defender: Node2D) -> void:
	print("[EncounterUI] Opening encounter between %s and %s" % [attacker.name, defender.name])
	_attacker = attacker
	_defender = defender
	_combat_active = true
	show()
	print("[EncounterUI] UI shown, pausing game...")

	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("pause"):
		timekeeper.pause()
		print("[EncounterUI] Game paused")

	print("[EncounterUI] Starting combat loop...")
	_start_combat_loop()

## Closes the encounter UI
func close_ui() -> void:
	_combat_active = false
	hide()

	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("resume"):
		timekeeper.resume()

func _on_retreat_pressed() -> void:
	_combat_active = false
	retreat_pressed.emit()
	close_ui()

## Automatic combat loop - runs rounds until one actor is defeated
func _start_combat_loop() -> void:
	while _combat_active:
		await get_tree().create_timer(0.5).timeout

		if not _combat_active:
			break

		var combat_manager: Node = get_node_or_null("/root/CombatManager")
		if combat_manager != null and combat_manager.has_method("resolve_combat_round"):
			combat_manager.resolve_combat_round(_attacker, _defender)

		if not _check_combat_continues():
			break

## Checks if combat should continue or if someone has been defeated
func _check_combat_continues() -> bool:
	if _attacker == null or _defender == null:
		_combat_active = false
		return false

	var attacker_sheet: CharacterSheet = _attacker.charactersheet if _attacker.has("charactersheet") else null
	var defender_sheet: CharacterSheet = _defender.charactersheet if _defender.has("charactersheet") else null

	if attacker_sheet == null or defender_sheet == null:
		_combat_active = false
		return false

	if attacker_sheet.current_health <= 0:
		_combat_active = false
		combat_ended.emit(_attacker, _defender, _defender)
		return false

	if defender_sheet.current_health <= 0:
		_combat_active = false
		combat_ended.emit(_attacker, _defender, _attacker)
		return false

	return true
