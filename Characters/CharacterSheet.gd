extends Resource
class_name CharacterSheet

## Universal character data container for player, NPCs, caravan leaders, and enemies.
## Stores dynamic progression data including attributes, skills, and character metadata.
## Uses CharacterAttributes for attribute management and SkillSpec instances for skill tracking.

## Character metadata
@export var character_name: String = "Nameless"
@export var character_description: String = ""
@export var level: int = 1

## Core progression components
@export var attributes: CharacterAttributes
## Dictionary of learned skills: { skill_id (StringName) -> SkillSpec instance }
var skills: Dictionary = {}


func _init() -> void:
	attributes = CharacterAttributes.new()


## Adds a new skill to the character's skill list.
## Skills start at rank 1 with 0 XP (rank 0 would mean "not learned").
func add_skill(skill_id: StringName, skill_db: SkillDatabase) -> void:
	# Check if skill already exists
	if skills.has(skill_id):
		push_warning("CharacterSheet.add_skill: Skill '%s' already exists for character '%s'" % [skill_id, character_name])
		return

	# Validate skill database
	if not skill_db:
		push_error("CharacterSheet.add_skill: Invalid SkillDatabase provided")
		return

	# Verify skill exists in database
	var skill_definition: Skill = skill_db.get_skill_by_id(skill_id)
	if not skill_definition:
		push_error("CharacterSheet.add_skill: Skill '%s' not found in SkillDatabase" % skill_id)
		return

	# Create new skill instance
	var new_skill_spec: SkillSpec = SkillSpec.new()
	new_skill_spec.skill_id = skill_id
	new_skill_spec.current_rank = 1  # Skills start at rank 1 (learned)
	new_skill_spec.current_xp = 0.0

	# Store in skills dictionary
	skills[skill_id] = new_skill_spec


## Gets the current level of a specific attribute.
func get_attribute_level(attribute_id: StringName) -> int:
	if not attributes:
		push_warning("CharacterSheet.get_attribute_level: No attributes instance")
		return 0
	return attributes.get_attribute_level(attribute_id)


## Gets the current rank of a specific skill.
## Returns 0 if the skill is not learned.
func get_skill_rank(skill_id: StringName) -> int:
	if not skills.has(skill_id):
		return 0

	var skill_spec: SkillSpec = skills[skill_id]
	return skill_spec.current_rank


## Gets the SkillSpec instance for a specific skill.
## Returns null if the skill is not learned.
func get_skill_spec(skill_id: StringName) -> SkillSpec:
	if not skills.has(skill_id):
		return null
	return skills[skill_id]


## Serializes character sheet data to a Dictionary for save games.
func to_dict() -> Dictionary:
	var save_data: Dictionary = {}

	# Store basic character data
	save_data["character_name"] = character_name
	save_data["character_description"] = character_description
	save_data["level"] = level

	# Store attributes
	if attributes:
		save_data["attributes"] = attributes.to_dict()
	else:
		save_data["attributes"] = {}

	# Store skills as array of dictionaries
	var skills_list: Array = []
	for skill_id in skills.keys():
		var skill_spec: SkillSpec = skills[skill_id]
		if skill_spec:
			skills_list.append(skill_spec.to_dict())
	save_data["skills"] = skills_list

	return save_data


## Loads character sheet data from a Dictionary (for save games).
func from_dict(data: Dictionary) -> void:
	# Load basic character data
	character_name = data.get("character_name", "Nameless")
	character_description = data.get("character_description", "")
	level = data.get("level", 1)

	# Load attributes
	if data.has("attributes"):
		if not attributes:
			attributes = CharacterAttributes.new()
		attributes.from_dict(data["attributes"])

	# Clear existing skills
	skills.clear()

	# Load skills
	if data.has("skills") and data["skills"] is Array:
		var skills_list: Array = data["skills"]
		for skill_data in skills_list:
			if skill_data is Dictionary:
				var new_skill_spec: SkillSpec = SkillSpec.new()
				new_skill_spec.from_dict(skill_data)
				# Use the loaded skill_id as the key
				skills[new_skill_spec.skill_id] = new_skill_spec
