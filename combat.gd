extends Node

## Resolves a single combat round between two actors
func resolve_combat_round(actor_a: Node2D, actor_b: Node2D) -> void:
	if actor_a == null or actor_b == null:
		return

	var a_sheet: CharacterSheet = actor_a.get("charactersheet")
	var b_sheet: CharacterSheet = actor_b.get("charactersheet")

	if a_sheet == null or b_sheet == null:
		return

	var a_atk: int = a_sheet.get_effective_damage()
	var a_def: int = a_sheet.get_effective_defense()
	var b_atk: int = b_sheet.get_effective_damage()
	var b_def: int = b_sheet.get_effective_defense()

	var a_atk_roll: int = 10 + a_atk + randi_range(0, 49)
	var a_def_roll: int = 10 + a_def + randi_range(0, 49)
	var b_atk_roll: int = 10 + b_atk + randi_range(0, 49)
	var b_def_roll: int = 10 + b_def + randi_range(0, 49)

	var damage_to_b: int = maxi(0, a_atk_roll - b_def_roll)
	var damage_to_a: int = maxi(0, b_atk_roll - a_def_roll)

	print("[CombatManager] Round: %s dealt %d dmg, %s dealt %d dmg" % [actor_a.name, damage_to_b, actor_b.name, damage_to_a])

	a_sheet.apply_damage(damage_to_a)
	b_sheet.apply_damage(damage_to_b)
