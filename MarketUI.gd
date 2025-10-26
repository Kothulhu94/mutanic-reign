## MarketUI - Interface for trading with hub inventory
## Displays hub inventory and allows player to buy/sell items
extends Control
class_name MarketUI

signal market_closed()

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/HSplitContainer/HubVbox/TitleLabel
@onready var hub_money_label: Label = $Panel/MarginContainer/HSplitContainer/HubVbox/HubInfoContainer/HubMoneyLabel
@onready var inventory_list: ItemList = $Panel/MarginContainer/HSplitContainer/HubVbox/ScrollContainer/InventoryList
@onready var close_button: Button = $Panel/MarginContainer/HSplitContainer/HubVbox/CloseButton
@onready var player_list: ItemList = $Panel/MarginContainer/HSplitContainer/PlayerVBox/ScrollContainer/PlayerList
@onready var player_money_label: Label = $Panel/MarginContainer/HSplitContainer/PlayerVBox/PlayerMoneyLabel
@onready var player_title_label: Label = $Panel/MarginContainer/HSplitContainer/PlayerVBox/PlayerTitleLabel
@onready var player_inventory_label: Label = $Panel/MarginContainer/HSplitContainer/PlayerVBox/PLayerInventory

var current_hub: Hub = null
var current_bus: Bus = null

# Quantity selector popup (will be created dynamically)
var quantity_popup: Window = null
var quantity_spinbox: SpinBox = null
var quantity_line_edit: LineEdit = null
var pending_transaction: Dictionary = {}  # {type: "buy"/"sell", item_id: StringName, max_qty: int, price: float}

func _ready() -> void:
	# Hide by default
	hide()

	# Connect close button
	if close_button != null:
		close_button.pressed.connect(_on_close_pressed)

	# Connect inventory lists
	if inventory_list != null:
		inventory_list.item_clicked.connect(_on_hub_item_clicked)

	if player_list != null:
		player_list.item_clicked.connect(_on_player_item_clicked)

	# Set labels
	if player_title_label != null:
		player_title_label.text = "Player Inventory"
	if player_inventory_label != null:
		player_inventory_label.text = "Your Items:"

	# Make sure we process input
	set_process_input(true)

	# Create quantity selector popup
	_create_quantity_popup()

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

	# Find the player bus in the scene
	current_bus = _find_player_bus()
	if current_bus == null:
		push_warning("MarketUI: Could not find player Bus in scene")

	# Update title
	if title_label != null and hub.state != null:
		title_label.text = "%s - Market" % hub.state.display_name

	# Update both inventories
	_update_all_displays()

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
	current_bus = null

func _on_close_pressed() -> void:
	close_market()

## Find the player Bus in the scene tree
func _find_player_bus() -> Bus:
	# Look for any node of type Bus in the scene
	var root := get_tree().root
	return _search_for_bus(root)

func _search_for_bus(node: Node) -> Bus:
	if node is Bus:
		return node as Bus
	for child in node.get_children():
		var result := _search_for_bus(child)
		if result != null:
			return result
	return null

## Update all displays (both player and hub)
func _update_all_displays() -> void:
	_update_player_display()
	_update_hub_display()

## Update player inventory and money display
func _update_player_display() -> void:
	if current_bus == null:
		return

	# Update player money
	if player_money_label != null:
		player_money_label.text = "Your Money: %d" % current_bus.money

	# Populate player inventory list
	if player_list != null:
		player_list.clear()

		var items: Array = []
		for item_id in current_bus.inventory.keys():
			var amount: int = current_bus.inventory.get(item_id, 0)
			if amount > 0:
				items.append({"id": item_id, "amount": amount})

		# Sort by item id
		items.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))

		# Add items to list
		for item_data in items:
			var item_id: StringName = item_data["id"]
			var amount: int = item_data["amount"]
			var price: float = 0.0

			# Get sell price (hub buy price)
			if current_hub != null and current_hub.item_prices.has(item_id):
				price = current_hub.item_prices[item_id]

			var item_text: String = "%s: %d units (%.0f per unit)" % [item_id, amount, price]
			player_list.add_item(item_text)
			# Store metadata for easy access
			player_list.set_item_metadata(player_list.item_count - 1, {"item_id": item_id, "amount": amount, "price": price})

## Update hub inventory and money display
func _update_hub_display() -> void:
	if current_hub == null or current_hub.state == null:
		return

	# Update hub money
	if hub_money_label != null:
		hub_money_label.text = "Hub Money: %d" % current_hub.state.money

	# Populate hub inventory list
	if inventory_list != null:
		inventory_list.clear()

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

			# Get buy price
			if current_hub.item_prices.has(item_id):
				price = current_hub.item_prices[item_id]

			var item_text: String = "%s: %d units (%.0f per unit)" % [item_id, amount, price]
			inventory_list.add_item(item_text)
			# Store metadata for easy access
			inventory_list.set_item_metadata(inventory_list.item_count - 1, {"item_id": item_id, "amount": amount, "price": price})

## Create the quantity selector popup
func _create_quantity_popup() -> void:
	# Create popup window
	quantity_popup = Window.new()
	quantity_popup.title = "Select Quantity"
	quantity_popup.size = Vector2i(300, 150)
	quantity_popup.transient = true
	quantity_popup.exclusive = true
	quantity_popup.unresizable = true
	quantity_popup.popup_window = true

	# Create main container
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)

	# Add margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_child(vbox)
	quantity_popup.add_child(margin)

	# Title label
	var title_lbl := Label.new()
	title_lbl.text = "Quantity:"
	vbox.add_child(title_lbl)

	# SpinBox
	quantity_spinbox = SpinBox.new()
	quantity_spinbox.min_value = 1
	quantity_spinbox.max_value = 9999
	quantity_spinbox.value = 1
	quantity_spinbox.step = 1
	quantity_spinbox.allow_greater = false
	quantity_spinbox.allow_lesser = false
	quantity_spinbox.editable = true
	quantity_spinbox.update_on_text_changed = true
	vbox.add_child(quantity_spinbox)

	# Get the LineEdit from SpinBox for direct text input
	quantity_line_edit = quantity_spinbox.get_line_edit()

	# Button container
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	# Confirm button
	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.pressed.connect(_on_quantity_confirmed)
	hbox.add_child(confirm_btn)

	# Cancel button
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_on_quantity_cancelled)
	hbox.add_child(cancel_btn)

	# Don't add to tree yet, will be added when shown
	quantity_popup.close_requested.connect(_on_quantity_cancelled)

## Show quantity selector for a transaction
func _show_quantity_selector(transaction_type: String, item_id: StringName, max_qty: int, price: float) -> void:
	if quantity_popup == null:
		push_error("Quantity popup not created")
		return

	pending_transaction = {
		"type": transaction_type,
		"item_id": item_id,
		"max_qty": max_qty,
		"price": price
	}

	# Update spinbox limits
	quantity_spinbox.max_value = max_qty
	quantity_spinbox.value = 1

	# Update title
	var action_text := "Buy" if transaction_type == "buy" else "Sell"
	quantity_popup.title = "%s %s" % [action_text, str(item_id)]

	# Add to tree if not already
	if not quantity_popup.is_inside_tree():
		add_child(quantity_popup)

	# Center popup
	var screen_center := DisplayServer.screen_get_size() / 2
	var popup_size := quantity_popup.size
	quantity_popup.position = Vector2i(screen_center.x - popup_size.x / 2, screen_center.y - popup_size.y / 2)

	# Show popup
	quantity_popup.show()

## Handle hub item click (player wants to buy)
func _on_hub_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if current_hub == null or current_bus == null:
		return

	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	var metadata: Variant = inventory_list.get_item_metadata(index)
	if metadata == null or not metadata is Dictionary:
		return

	var data := metadata as Dictionary
	var item_id: StringName = data.get("item_id", &"")
	var available: int = data.get("amount", 0)
	var price: float = data.get("price", 0.0)

	if available <= 0:
		return

	# Check if shift is pressed for full stack purchase
	if Input.is_key_pressed(KEY_SHIFT):
		_execute_buy(item_id, available, price)
	else:
		_show_quantity_selector("buy", item_id, available, price)

## Handle player item click (player wants to sell)
func _on_player_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if current_hub == null or current_bus == null:
		return

	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	var metadata: Variant = player_list.get_item_metadata(index)
	if metadata == null or not metadata is Dictionary:
		return

	var data := metadata as Dictionary
	var item_id: StringName = data.get("item_id", &"")
	var available: int = data.get("amount", 0)
	var price: float = data.get("price", 0.0)

	if available <= 0:
		return

	# Check if shift is pressed for full stack sale
	if Input.is_key_pressed(KEY_SHIFT):
		_execute_sell(item_id, available, price)
	else:
		_show_quantity_selector("sell", item_id, available, price)

## Quantity selector confirmed
func _on_quantity_confirmed() -> void:
	if pending_transaction.is_empty():
		return

	var qty: int = int(quantity_spinbox.value)
	var trans_type: String = pending_transaction.get("type", "")
	var item_id: StringName = pending_transaction.get("item_id", &"")
	var price: float = pending_transaction.get("price", 0.0)

	# Close popup
	if quantity_popup != null:
		quantity_popup.hide()

	# Execute transaction
	if trans_type == "buy":
		_execute_buy(item_id, qty, price)
	elif trans_type == "sell":
		_execute_sell(item_id, qty, price)

	pending_transaction.clear()

## Quantity selector cancelled
func _on_quantity_cancelled() -> void:
	if quantity_popup != null:
		quantity_popup.hide()
	pending_transaction.clear()

## Execute a buy transaction (player buys from hub)
func _execute_buy(item_id: StringName, quantity: int, unit_price: float) -> void:
	if current_hub == null or current_bus == null:
		return

	var total_cost: int = int(ceil(unit_price * quantity))

	# Check if player has enough money
	if current_bus.money < total_cost:
		print("[MarketUI] Not enough money to buy %d %s (need %d, have %d)" % [quantity, item_id, total_cost, current_bus.money])
		return

	# Check if hub has enough items
	var hub_amount: int = current_hub.state.inventory.get(item_id, 0)
	if hub_amount < quantity:
		print("[MarketUI] Hub doesn't have enough %s (want %d, have %d)" % [item_id, quantity, hub_amount])
		return

	# Perform transaction
	current_bus.money -= total_cost
	current_hub.state.money += total_cost

	# Transfer items
	current_hub.state.inventory[item_id] = hub_amount - quantity
	if current_hub.state.inventory[item_id] <= 0:
		current_hub.state.inventory.erase(item_id)

	current_bus.inventory[item_id] = current_bus.inventory.get(item_id, 0) + quantity

	print("[MarketUI] Bought %d %s for %d" % [quantity, item_id, total_cost])

	# Update displays
	_update_all_displays()

## Execute a sell transaction (player sells to hub)
func _execute_sell(item_id: StringName, quantity: int, unit_price: float) -> void:
	if current_hub == null or current_bus == null:
		return

	var total_value: int = int(ceil(unit_price * quantity))

	# Check if hub has enough money
	if current_hub.state.money < total_value:
		print("[MarketUI] Hub doesn't have enough money to buy %d %s (need %d, have %d)" % [quantity, item_id, total_value, current_hub.state.money])
		return

	# Check if player has enough items
	var player_amount: int = current_bus.inventory.get(item_id, 0)
	if player_amount < quantity:
		print("[MarketUI] You don't have enough %s (want %d, have %d)" % [item_id, quantity, player_amount])
		return

	# Perform transaction
	current_bus.money += total_value
	current_hub.state.money -= total_value

	# Transfer items
	current_bus.inventory[item_id] = player_amount - quantity
	if current_bus.inventory[item_id] <= 0:
		current_bus.inventory.erase(item_id)

	current_hub.state.inventory[item_id] = current_hub.state.inventory.get(item_id, 0) + quantity

	print("[MarketUI] Sold %d %s for %d" % [quantity, item_id, total_value])

	# Update displays
	_update_all_displays()
