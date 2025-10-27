extends Control
class_name LootUI

signal loot_closed(defeated_actor: Node2D)

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var player_name_label: Label = $MarginContainer/VBoxContainer/ContentContainer/LeftPanel/PlayerNameLabel
@onready var player_item_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/LeftPanel/PlayerScrollContainer/PlayerItemList
@onready var defeated_name_label: Label = $MarginContainer/VBoxContainer/ContentContainer/RightPanel/DefeatedNameLabel
@onready var defeated_item_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/RightPanel/DefeatedScrollContainer/DefeatedItemList
@onready var take_all_button: Button = $MarginContainer/VBoxContainer/FooterContainer/TakeAllButton
@onready var done_button: Button = $MarginContainer/VBoxContainer/FooterContainer/DoneButton

var player_actor: Node2D = null
var defeated_actor: Node2D = null

func _ready() -> void:
	hide()
	set_process_input(true)

	if take_all_button != null:
		take_all_button.pressed.connect(_on_take_all_pressed)

	if done_button != null:
		done_button.pressed.connect(_on_done_pressed)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_done_pressed()

func open(player_ref: Node2D, defeated_ref: Node2D) -> void:
	if player_ref == null or defeated_ref == null:
		return

	player_actor = player_ref
	defeated_actor = defeated_ref

	_populate_ui()
	show()

	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("pause"):
		timekeeper.pause()

func close_loot() -> void:
	hide()

	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("resume"):
		timekeeper.resume()

	loot_closed.emit(defeated_actor)
	player_actor = null
	defeated_actor = null

func _populate_ui() -> void:
	if player_actor == null or defeated_actor == null:
		return

	if title_label != null:
		title_label.text = "Victory! Take Your Loot"

	if player_name_label != null:
		player_name_label.text = player_actor.name if player_actor.has("name") else "Player"

	if defeated_name_label != null:
		defeated_name_label.text = defeated_actor.name if defeated_actor.has("name") else "Defeated"

	_populate_player_list()
	_populate_defeated_list()

func _populate_player_list() -> void:
	if player_item_list == null or player_actor == null:
		return

	for child in player_item_list.get_children():
		child.queue_free()

	if not player_actor.has("inventory"):
		return

	var sorted_items: Array[StringName] = []
	for k in player_actor.inventory.keys():
		sorted_items.append(k if k is StringName else StringName(str(k)))
	sorted_items.sort_custom(func(a: StringName, b: StringName): return str(a) < str(b))

	for item_id: StringName in sorted_items:
		var stock: int = player_actor.inventory.get(item_id, 0)
		if stock > 0:
			var label: Label = Label.new()
			label.text = "%s: %d" % [item_id, stock]
			player_item_list.add_child(label)

func _populate_defeated_list() -> void:
	if defeated_item_list == null or defeated_actor == null:
		return

	for child in defeated_item_list.get_children():
		child.queue_free()

	var defeated_inventory: Dictionary = _get_defeated_inventory()
	var sorted_items: Array[StringName] = []
	for k in defeated_inventory.keys():
		sorted_items.append(k if k is StringName else StringName(str(k)))
	sorted_items.sort_custom(func(a: StringName, b: StringName): return str(a) < str(b))

	for item_id: StringName in sorted_items:
		var stock: int = defeated_inventory.get(item_id, 0)
		if stock > 0:
			var button: Button = Button.new()
			button.text = "%s: %d" % [item_id, stock]
			button.pressed.connect(_on_loot_item_clicked.bind(item_id))
			defeated_item_list.add_child(button)

func _get_defeated_inventory() -> Dictionary:
	if defeated_actor == null:
		return {}

	if defeated_actor.has("inventory"):
		return defeated_actor.inventory
	elif defeated_actor.has("caravan_state") and defeated_actor.caravan_state != null:
		return defeated_actor.caravan_state.inventory

	return {}

func _on_loot_item_clicked(item_id: StringName) -> void:
	var defeated_inventory: Dictionary = _get_defeated_inventory()
	var amount: int = defeated_inventory.get(item_id, 0)

	if amount <= 0:
		return

	if player_actor.has_method("add_item"):
		if player_actor.add_item(item_id, amount):
			_remove_from_defeated(item_id, amount)
			_populate_player_list()
			_populate_defeated_list()

func _on_take_all_pressed() -> void:
	var defeated_inventory: Dictionary = _get_defeated_inventory()
	for item_id in defeated_inventory.keys():
		var amount: int = defeated_inventory.get(item_id, 0)
		if amount > 0 and player_actor.has_method("add_item"):
			if player_actor.add_item(item_id, amount):
				_remove_from_defeated(item_id, amount)

	_populate_player_list()
	_populate_defeated_list()

func _on_done_pressed() -> void:
	close_loot()

func _remove_from_defeated(item_id: StringName, amount: int) -> void:
	if defeated_actor == null:
		return

	if defeated_actor.has_method("remove_item"):
		defeated_actor.remove_item(item_id, amount)
	elif defeated_actor.has("caravan_state") and defeated_actor.caravan_state != null:
		defeated_actor.caravan_state.remove_item(item_id, amount)
