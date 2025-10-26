# MarketPanel.gd — Godot 4.5 (typed, no Variant warnings)
extends MarginContainer
class_name MarketPanel

# ---------- Assign in Inspector ----------
@export var player_list: ItemList
@export var hub_list: ItemList
@export var player_money_label: Label
@export var hub_money_label: Label

# ---------- Tunables ----------
@export_range(0.1, 5.0, 0.05) var buy_markup: float = 1.0
@export_range(0.1, 5.0, 0.05) var sell_markdown: float = 1.0
@export var allow_shift_max: bool = true

# ---------- Simple DB / state ----------
var ITEM_DB: Dictionary = {
	"medkit":   {"name": "Medkit",      "price": 50, "desc": "Heals 50 HP."},
	"ammo_9mm": {"name": "9mm Ammo",    "price": 1,  "desc": "Standard pistol ammo."},
	"scrap":    {"name": "Scrap Metal", "price": 5,  "desc": "Crafting material."}
}

var player_money: int = 120
var hub_money: int = 1000
var player_inv: Dictionary = {"medkit": 2, "ammo_9mm": 30}
var hub_inv: Dictionary = {"medkit": 10, "ammo_9mm": 500, "scrap": 40}

# ---------- Internals ----------
var _trade_dialog: ConfirmationDialog
var _qty_spin: SpinBox
var _total_label: Label
var _unit_price: int = 0
var _trade_mode: String = ""      # "buy" | "sell"
var _trade_item_id: String = ""
var _hub_menu: PopupMenu
var _player_menu: PopupMenu
var _last_item_id: String = ""

func _ready() -> void:
	_build_trade_dialog()
	_build_context_menus()

	if is_instance_valid(player_list):
		player_list.allow_rmb_select = true
		player_list.item_clicked.connect(_on_player_clicked)
		player_list.item_activated.connect(_on_player_activated)

	if is_instance_valid(hub_list):
		hub_list.allow_rmb_select = true
		hub_list.item_clicked.connect(_on_hub_clicked)
		hub_list.item_activated.connect(_on_hub_activated)

	_qty_spin.value_changed.connect(_on_qty_changed)
	_trade_dialog.confirmed.connect(_on_trade_confirmed)

	_refresh_all()

# ================= UI BUILDERS =================
func _build_trade_dialog() -> void:
	_trade_dialog = ConfirmationDialog.new()
	_trade_dialog.title = "Trade"
	_trade_dialog.min_size = Vector2(360.0, 150.0)
	add_child(_trade_dialog)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.custom_minimum_size = Vector2(340.0, 0.0)
	_trade_dialog.add_child(vb)

	var row: HBoxContainer = HBoxContainer.new()
	vb.add_child(row)

	var qty_label: Label = Label.new()
	qty_label.text = "Quantity"
	qty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(qty_label)

	_qty_spin = SpinBox.new()
	_qty_spin.step = 1.0
	_qty_spin.min_value = 0.0
	_qty_spin.max_value = 0.0
	_qty_spin.value = 0.0
	_qty_spin.allow_greater = false
	row.add_child(_qty_spin)

	_total_label = Label.new()
	_total_label.text = "Total: 0"
	vb.add_child(_total_label)

func _build_context_menus() -> void:
	_hub_menu = PopupMenu.new()
	add_child(_hub_menu)
	_hub_menu.add_item("Buy…", 0)
	_hub_menu.add_item("Buy Max", 1)
	_hub_menu.id_pressed.connect(_on_hub_menu_pressed)

	_player_menu = PopupMenu.new()
	add_child(_player_menu)
	_player_menu.add_item("Sell…", 0)
	_player_menu.add_item("Sell Max", 1)
	_player_menu.id_pressed.connect(_on_player_menu_pressed)

# ================= REFRESH =================
func _refresh_all() -> void:
	if is_instance_valid(player_money_label):
		player_money_label.text = "Money: %d" % player_money
	if is_instance_valid(hub_money_label):
		hub_money_label.text = "Hub: %d" % hub_money

	_fill_list(player_list, player_inv, true)
	_fill_list(hub_list, hub_inv, false)

func _fill_list(list: ItemList, inv: Dictionary, is_player: bool) -> void:
	if not is_instance_valid(list):
		return
	list.clear()

	var keys: Array = inv.keys()
	for i: int in keys.size():
		var id_variant: Variant = keys[i]
		var item_id: String = String(id_variant)

		var count: int = int(inv.get(item_id, 0))
		if count <= 0:
			continue

		var default_meta: Dictionary = {"name": item_id, "price": 1, "desc": ""}
		var meta_any: Variant = ITEM_DB.get(item_id, default_meta)
		var meta: Dictionary = meta_any as Dictionary

		var name: String = String(meta.get("name", item_id))
		var base_price: int = int(meta.get("price", 1))
		var unit: int = _unit_for_side(is_player, base_price)

		var idx: int = list.add_item("%s  x%d   —  %d" % [name, count, unit])
		list.set_item_metadata(idx, item_id)
		list.set_item_tooltip(idx, "%s\nUnit: %d" % [String(meta.get("desc", "")), unit])

# ================= HELPERS =================
func _base_price(item_id: String) -> int:
	var meta: Dictionary = (ITEM_DB.get(item_id, {"price": 1}) as Dictionary)
	return int(meta.get("price", 1))

func _unit_price_for(mode: String, base_price: int) -> int:
	if mode == "buy":
		return int(round(float(base_price) * buy_markup))
	return int(round(float(base_price) * sell_markdown))

func _unit_for_side(is_player_side: bool, base_price: int) -> int:
	if is_player_side:
		return int(round(float(base_price) * sell_markdown))
	return int(round(float(base_price) * buy_markup))

func _wallet_limit(mode: String, unit_price: int) -> int:
	var money: int = player_money if mode == "buy" else hub_money
	var divisor: int = max(unit_price, 1)
	return int(floor(float(money) / float(divisor)))

func _max_trade_qty(mode: String, item_id: String, unit_price: int) -> int:
	var available_any: Variant = hub_inv.get(item_id, 0) if mode == "buy" else player_inv.get(item_id, 0)
	var available: int = int(available_any)
	var limit: int = _wallet_limit(mode, unit_price)
	return int(max(0, min(available, limit)))

# ================= CLICKS =================
func _on_hub_clicked(index: int, at_pos: Vector2, button: int) -> void:
	var meta: Variant = hub_list.get_item_metadata(index)
	_last_item_id = String(meta)
	if button == MOUSE_BUTTON_RIGHT:
		_hub_menu.position = get_viewport().get_mouse_position()
		_hub_menu.popup()

func _on_player_clicked(index: int, at_pos: Vector2, button: int) -> void:
	var meta: Variant = player_list.get_item_metadata(index)
	_last_item_id = String(meta)
	if button == MOUSE_BUTTON_RIGHT:
		_player_menu.position = get_viewport().get_mouse_position()
		_player_menu.popup()

func _on_hub_activated(index: int) -> void:
	var id_meta: Variant = hub_list.get_item_metadata(index)
	var id: String = String(id_meta)
	if allow_shift_max and Input.is_key_pressed(KEY_SHIFT):
		_quick_trade_max("buy", id)
	else:
		_open_trade("buy", id)

func _on_player_activated(index: int) -> void:
	var id_meta: Variant = player_list.get_item_metadata(index)
	var id: String = String(id_meta)
	if allow_shift_max and Input.is_key_pressed(KEY_SHIFT):
		_quick_trade_max("sell", id)
	else:
		_open_trade("sell", id)

func _on_hub_menu_pressed(id: int) -> void:
	if _last_item_id.is_empty():
		return
	if id == 0:
		_open_trade("buy", _last_item_id)
	elif id == 1:
		_quick_trade_max("buy", _last_item_id)

func _on_player_menu_pressed(id: int) -> void:
	if _last_item_id.is_empty():
		return
	if id == 0:
		_open_trade("sell", _last_item_id)
	elif id == 1:
		_quick_trade_max("sell", _last_item_id)

# ================= TRADE FLOW =================
func _open_trade(mode: String, item_id: String) -> void:
	_trade_mode = mode
	_trade_item_id = item_id

	var base_price: int = _base_price(item_id)
	_unit_price = _unit_price_for(mode, base_price)

	var max_qty: int = _max_trade_qty(mode, item_id, _unit_price)
	var nice_name: String = String((ITEM_DB.get(item_id, {"name": item_id}) as Dictionary).get("name", item_id))

	_trade_dialog.title = "%s %s" % [mode.capitalize(), nice_name]
	_qty_spin.max_value = float(max_qty)
	_qty_spin.min_value = 1.0 if max_qty > 0 else 0.0
	_qty_spin.value = 1.0 if max_qty > 0 else 0.0
	_update_total()

	_trade_dialog.get_ok_button().disabled = (max_qty <= 0)
	_trade_dialog.popup_centered()

func _on_qty_changed(_v: float) -> void:
	_update_total()

func _update_total() -> void:
	var q: int = int(_qty_spin.value)
	_total_label.text = "Total: %d" % (q * _unit_price)

func _on_trade_confirmed() -> void:
	var qty: int = int(_qty_spin.value)
	if qty <= 0:
		return
	_execute_trade(_trade_mode, _trade_item_id, qty)

func _quick_trade_max(mode: String, item_id: String) -> void:
	var base_price: int = _base_price(item_id)
	var unit: int = _unit_price_for(mode, base_price)
	var qty: int = _max_trade_qty(mode, item_id, unit)
	if qty > 0:
		_execute_trade(mode, item_id, qty)

func _execute_trade(mode: String, item_id: String, qty: int) -> void:
	var base_price: int = _base_price(item_id)
	var unit: int = _unit_price_for(mode, base_price)
	var total: int = unit * qty

	if mode == "buy":
		if int(hub_inv.get(item_id, 0)) < qty:
			return
		if player_money < total:
			return
		player_money -= total
		hub_money += total
		hub_inv[item_id] = int(hub_inv.get(item_id, 0)) - qty
		player_inv[item_id] = int(player_inv.get(item_id, 0)) + qty
	else:
		if int(player_inv.get(item_id, 0)) < qty:
			return
		if hub_money < total:
			return
		player_money += total
		hub_money -= total
		player_inv[item_id] = int(player_inv.get(item_id, 0)) - qty
		hub_inv[item_id] = int(hub_inv.get(item_id, 0)) + qty

	_refresh_all()
