# Systems/UI/sidebar.gd
extends CanvasLayer

## In-game sidebar for ball spawning and upgrades

@onready var currency_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CurrencyLabel
@onready var balls_tab_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TabButtons/BallsTabButton
@onready var upgrades_tab_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TabButtons/UpgradesTabButton
@onready var balls_tab: ScrollContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContent/BallsTab
@onready var upgrades_tab: ScrollContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContent/UpgradesTab
@onready var prestige_section: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/PrestigeSection
@onready var prestige_points_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PrestigeSection/PrestigePointsLabel
@onready var prestige_button: Button = $PanelContainer/MarginContainer/VBoxContainer/PrestigeSection/PrestigeButton

enum Tab { BALLS, UPGRADES }
var current_tab: Tab = Tab.BALLS
var prestige_points_available: int = 0


func _ready() -> void:
	# Connect tab buttons
	balls_tab_button.pressed.connect(_on_balls_tab_pressed)
	upgrades_tab_button.pressed.connect(_on_upgrades_tab_pressed)
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	
	# Connect to GameManager signals
	GameManager.bounce_currency_changed.connect(_on_bounce_currency_changed)
	GameManager.prestige_available.connect(_on_prestige_available)
	
	# Initialize display
	_update_currency_label()
	_switch_to_tab(Tab.BALLS)
	_update_prestige_display()
	
	# Create placeholder buttons
	_create_placeholder_buttons()


func _create_placeholder_buttons() -> void:
	# Balls tab placeholders
	var balls_container = balls_tab.get_node("VBoxContainer")
	for i in range(5):
		var button = _create_placeholder_button("Special Ball %d" % (i + 1))
		balls_container.add_child(button)
	
	# Upgrades tab placeholders
	var upgrades_container = upgrades_tab.get_node("VBoxContainer")
	for i in range(5):
		var button = _create_placeholder_button("Upgrade %d" % (i + 1))
		upgrades_container.add_child(button)


func _create_placeholder_button(label_text: String) -> Button:
	var button = Button.new()
	button.text = label_text
	button.disabled = true
	button.custom_minimum_size = Vector2(0, 50)
	
	# Style the button
	button.add_theme_font_size_override("font_size", 16)
	
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.2, 0.2, 0.2)
	disabled_style.border_width_left = 1
	disabled_style.border_width_top = 1
	disabled_style.border_width_right = 1
	disabled_style.border_width_bottom = 1
	disabled_style.border_color = Color(0.4, 0.4, 0.4)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	return button


func _switch_to_tab(tab: Tab) -> void:
	current_tab = tab
	
	# Update tab visibility
	balls_tab.visible = (tab == Tab.BALLS)
	upgrades_tab.visible = (tab == Tab.UPGRADES)
	
	# Update button states
	_update_tab_button_styles()


func _update_tab_button_styles() -> void:
	# Active tab style
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.3, 0.5, 0.7)
	active_style.border_width_bottom = 3
	active_style.border_color = Color(0.5, 0.7, 1.0)
	
	# Inactive tab style
	var inactive_style = StyleBoxFlat.new()
	inactive_style.bg_color = Color(0.2, 0.3, 0.4)
	inactive_style.border_width_bottom = 1
	inactive_style.border_color = Color(0.3, 0.3, 0.3)
	
	# Apply styles
	if current_tab == Tab.BALLS:
		balls_tab_button.add_theme_stylebox_override("normal", active_style)
		upgrades_tab_button.add_theme_stylebox_override("normal", inactive_style)
	else:
		balls_tab_button.add_theme_stylebox_override("normal", inactive_style)
		upgrades_tab_button.add_theme_stylebox_override("normal", active_style)


func _on_balls_tab_pressed() -> void:
	_switch_to_tab(Tab.BALLS)


func _on_upgrades_tab_pressed() -> void:
	_switch_to_tab(Tab.UPGRADES)


func _on_bounce_currency_changed(new_amount: int) -> void:
	_update_currency_label()


func _on_prestige_available(current_bounces: int, threshold: int) -> void:
	# Calculate prestige points that will be awarded
	prestige_points_available = int(current_bounces / 10.0)
	_update_prestige_display()


func _on_prestige_button_pressed() -> void:
	GameManager.trigger_prestige()


func _update_currency_label() -> void:
	currency_label.text = "Bounces: %d" % GameManager.bounce_currency


func _update_prestige_display() -> void:
	if prestige_points_available > 0:
		prestige_section.visible = true
		prestige_points_label.text = "Prestige Points: +%d" % prestige_points_available
		prestige_button.disabled = false
	else:
		prestige_section.visible = false