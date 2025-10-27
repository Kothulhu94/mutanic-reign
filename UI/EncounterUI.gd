extends Control
class_name EncounterUI

## Emitted when combat concludes (win, loss, or retreat)
signal combat_ended(attacker: Node2D, defender: Node2D, winner: Node2D)
## Emitted when exit button is pressed
signal exit_pressed()

@onready var attack_button: Button = $Panel/VBoxContainer/AttackButton
@onready var exit_button: Button = $Panel/VBoxContainer/ExitButton

var _attacker: Node2D = null
var _defender: Node2D = null

func _ready() -> void:
	hide()
	if attack_button != null:
		attack_button.pressed.connect(_on_attack_pressed)
	if exit_button != null:
		exit_button.pressed.connect(_on_exit_pressed)

## Opens the encounter UI for manual combat
func open_encounter(attacker: Node2D, defender: Node2D) -> void:
	print("[EncounterUI] Opening encounter between %s and %s" % [attacker.name, defender.name])
	_attacker = attacker
	_defender = defender
	show()
	print("[EncounterUI] UI shown, pausing game...")

	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("pause"):
		timekeeper.pause()
		print("[EncounterUI] Game paused, waiting for player action...")

## Closes the encounter UI
func close_ui() -> void:
	hide()

	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("resume"):
		timekeeper.resume()

func _on_attack_pressed() -> void:
	if _attacker == null or _defender == null:
		return

	print("[EncounterUI] Player chose Attack")

	# Resolve one combat round
	var combat_manager: Node = get_node_or_null("/root/CombatManager")
	if combat_manager != null and combat_manager.has_method("resolve_combat_round"):
		combat_manager.resolve_combat_round(_attacker, _defender)

	# Check if combat is over
	var attacker_sheet: CharacterSheet = _attacker.get("charactersheet")
	var defender_sheet: CharacterSheet = _defender.get("charactersheet")

	if attacker_sheet == null or defender_sheet == null:
		return

	if attacker_sheet.current_health <= 0:
		print("[EncounterUI] Attacker defeated!")
		combat_ended.emit(_attacker, _defender, _defender)
		close_ui()
	elif defender_sheet.current_health <= 0:
		print("[EncounterUI] Defender defeated!")
		combat_ended.emit(_attacker, _defender, _attacker)
		close_ui()

func _on_exit_pressed() -> void:
	print("[EncounterUI] Player chose Exit")
	exit_pressed.emit()
	close_ui()
