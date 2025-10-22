## MarketUI - Interface for trading with hub inventory
## Displays hub inventory and allows player to buy/sell items
extends Control
class_name MarketUI

signal market_closed()

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var hub_money_label: Label = $Panel/MarginContainer/VBoxContainer/HubInfoContainer/HubMoneyLabel
@onready var inventory_list: ItemList = $Panel/MarginContainer/VBoxContainer/ScrollContainer/InventoryList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var current_hub: Hub = null

func _ready() -> void:
	# Hide by default
	hide()

	# Connect close button
	if close_button != null:
		close_button.pressed.connect(_on_close_pressed)

	# Connect inventory list item selection
	if inventory_list != null:
		inventory_list.item_selected.connect(_on_item_selected)

	# Make sure we process input
	set_process_input(true)

func _input(event: InputEvent) -> void:
	# Close market on ESC key
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_market()

## Opens the market for a specific hub
func open_market(hub: Hub) -> void:
	if hub == null:
		push_error("MarketUI: Cannot open market for null hub")
		return

	current_hub = hub

	# Update title
	if title_label != null and hub.state != null:
		title_label.text = "%s - Market" % hub.state.display_name

	# Update hub info
	_update_hub_info()

	# Populate inventory list
	_populate_inventory_list()

	# Show market and pause game
	show()
	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("pause"):
		timekeeper.pause()

## Closes the market and resumes game
func close_market() -> void:
	hide()

	# Resume game
	var timekeeper: Node = get_node_or_null("/root/Timekeeper")
	if timekeeper != null and timekeeper.has_method("resume"):
		timekeeper.resume()

	market_closed.emit()
	current_hub = null

func _on_close_pressed() -> void:
	close_market()

func _on_item_selected(index: int) -> void:
	# In the future, this could show item details or trading options
	if inventory_list == null:
		return
	var item_text: String = inventory_list.get_item_text(index)
	print("[MarketUI] Selected: %s" % item_text)

func _update_hub_info() -> void:
	if current_hub == null or current_hub.state == null:
		return

	if hub_money_label != null:
		hub_money_label.text = "Hub Money: %d" % current_hub.state.money

func _populate_inventory_list() -> void:
	if inventory_list == null or current_hub == null or current_hub.state == null:
		return

	inventory_list.clear()

	# Get sorted list of items from inventory
	var items: Array = []
	for item_id in current_hub.state.inventory.keys():
		var amount: int = current_hub.state.inventory.get(item_id, 0)
		if amount > 0:
			items.append({"id": item_id, "amount": amount})

	# Sort by item id
	items.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))

	# Add items to list
	for item_data in items:
		var item_id: StringName = item_data["id"]
		var amount: int = item_data["amount"]
		var price: float = 0.0

		# Get price if available
		if current_hub.item_prices.has(item_id):
			price = current_hub.item_prices[item_id]

		var item_text: String = "%s: %d units (%.0f per unit)" % [item_id, amount, price]
		inventory_list.add_item(item_text)
