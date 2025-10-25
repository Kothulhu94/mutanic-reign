# CharacterSheetUI.gd
extends Control

# Get references to your UI labels/elements using @onready or %UniqueName
@onready var name_label: Label = %CharacterNameLabel # Example
@onready var level_label: Label = %LevelLabel     # Example
# ... other labels for attributes, skill container, etc.
@onready var close_button: Button = %CloseButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	hide() # Start hidden


# Function to populate the UI with data from a CharacterSheet resource
func display_sheet(sheet: CharacterSheet) -> void:
	if not sheet:
		push_error("Invalid CharacterSheet passed to display_sheet")
		return

	name_label.text = "Name: %s" % sheet.character_name
	level_label.text = "Level: %d" % sheet.level

	# --- Populate Attributes ---
	if sheet.attributes:
		# Assuming attributes has simple properties like strength, agility, etc.
		# Replace with your actual attribute names and access methods
		# e.g., get_node("%StrengthLabel").text = "Strength: %d" % sheet.attributes.strength
		pass # Placeholder




func _on_close_pressed() -> void:
	hide()
