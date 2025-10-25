# PauseMenu.gd
extends CanvasLayer

@onready var resume_button: Button = %ResumeButton # Use %UniqueName syntax if you set it up
@onready var character_sheet_button: Button = %CharacterSheetButton # Or use get_node("path/to/button")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide the menu initially
	hide()
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	character_sheet_button.pressed.connect(_on_character_sheet_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event: InputEvent) -> void:
	# Toggle pause menu on input action
	if event.is_action_pressed("pause"): # Use the action name you defined
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		# Mark the event as handled to prevent further processing
		get_tree().root.set_input_as_handled()


func _pause_game() -> void:
	# Pause the scene tree
	get_tree().paused = true
	# Show the pause menu
	show()


func _resume_game() -> void:
	# Resume the scene tree
	get_tree().paused = false
	# Hide the pause menu
	hide()
	# TODO: Hide the Character Sheet UI if it's open


func _on_resume_pressed() -> void:
	_resume_game()


func _on_character_sheet_pressed() -> void:
	print("Character Sheet button pressed") # Placeholder
	# TODO: Instantiate/Show CharacterSheetUI
	# TODO: Get player character sheet data
	# TODO: Pass data to CharacterSheetUI
