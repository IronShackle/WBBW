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

# References
var spawn_manager: SpawnManager
var ball_spawn_buttons: Array[Button] = []


func _ready() -> void:
	# Connect tab buttons
	balls_tab_button.pressed.connect(_on_balls_tab_pressed)
	upgrades_tab_button.pressed.connect(_on_upgrades_tab_pressed)
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	
	# Connect to GameManager signals
	GameManager.bounce_currency_changed.connect(_on_bounce_currency_changed)
	GameManager.prestige_available.connect(_on_prestige_available)
	
	# Find SpawnManager FIRST
	await _find_spawn_manager()  # Add await here!
	
	# Initialize display
	_update_currency_label()
	_switch_to_tab(Tab.BALLS)
	_update_prestige_display()
	
	# Create buttons AFTER we have spawn_manager
	_create_ball_buttons()
	_create_upgrade_placeholders()
	_update_ball_button_states()



func _find_spawn_manager() -> void:
	await get_tree().process_frame
	spawn_manager = get_tree().get_first_node_in_group("spawn_manager")
	if not spawn_manager:
		push_warning("No SpawnManager found in scene")


func _create_ball_buttons() -> void:
	if not spawn_manager:
		return
	
	var balls_container = balls_tab.get_node("VBoxContainer")
	
	# Create a button for each spawnable ball type
	for ball_config in spawn_manager.spawnable_balls:
		var button = _create_ball_spawn_button(ball_config)
		button.pressed.connect(_on_spawn_ball_pressed.bind(ball_config))
		balls_container.add_child(button)
		ball_spawn_buttons.append(button)


func _create_ball_spawn_button(config: BallConfig) -> Button:
	var button = Button.new()
	button.text = "%s\nCost: %d Bounces" % [config.display_name, config.cost]
	button.custom_minimum_size = Vector2(0, 60)
	button.add_theme_font_size_override("font_size", 16)
	
	_style_spawn_button(button)
	
	return button


func _style_spawn_button(button: Button) -> void:
	# Normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.5, 0.3)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.3, 0.7, 0.4)
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.6, 0.4)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.4, 0.8, 0.5)
	hover_style.corner_radius_top_left = 5
	hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_left = 5
	hover_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Disabled style
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.2, 0.2, 0.2)
	disabled_style.border_width_left = 2
	disabled_style.border_width_top = 2
	disabled_style.border_width_right = 2
	disabled_style.border_width_bottom = 2
	disabled_style.border_color = Color(0.4, 0.4, 0.4)
	disabled_style.corner_radius_top_left = 5
	disabled_style.corner_radius_top_right = 5
	disabled_style.corner_radius_bottom_left = 5
	disabled_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("disabled", disabled_style)


func _create_upgrade_placeholders() -> void:
	var upgrades_container = upgrades_tab.get_node("VBoxContainer")
	for i in range(5):
		var button = _create_placeholder_button("Upgrade %d" % (i + 1))
		upgrades_container.add_child(button)


func _create_placeholder_button(label_text: String) -> Button:
	var button = Button.new()
	button.text = label_text
	button.disabled = true
	button.custom_minimum_size = Vector2(0, 50)
	
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


func _on_spawn_ball_pressed(config: BallConfig) -> void:
	if not spawn_manager:
		push_warning("No SpawnManager available")
		return
	
	# Check if can afford
	if GameManager.bounce_currency >= config.cost:
		if spawn_manager.spawn_ball(config):
			# Deduct cost
			GameManager.bounce_currency -= config.cost
			GameManager.bounce_currency_changed.emit(GameManager.bounce_currency)
			print("[Sidebar] Spawned %s for %d bounces" % [config.display_name, config.cost])
		else:
			print("[Sidebar] Cannot spawn - at max capacity or failed")
	else:
		print("[Sidebar] Cannot afford %s (need %d, have %d)" % 
			[config.display_name, config.cost, GameManager.bounce_currency])


func _switch_to_tab(tab: Tab) -> void:
	current_tab = tab
	
	balls_tab.visible = (tab == Tab.BALLS)
	upgrades_tab.visible = (tab == Tab.UPGRADES)
	
	_update_tab_button_styles()


func _update_tab_button_styles() -> void:
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.3, 0.5, 0.7)
	active_style.border_width_bottom = 3
	active_style.border_color = Color(0.5, 0.7, 1.0)
	
	var inactive_style = StyleBoxFlat.new()
	inactive_style.bg_color = Color(0.2, 0.3, 0.4)
	inactive_style.border_width_bottom = 1
	inactive_style.border_color = Color(0.3, 0.3, 0.3)
	
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
	_update_ball_button_states()


func _on_prestige_available(current_bounces: int, threshold: int) -> void:
	prestige_points_available = int(current_bounces / 10.0)
	_update_prestige_display()


func _on_prestige_button_pressed() -> void:
	GameManager.trigger_prestige()


func _update_currency_label() -> void:
	currency_label.text = "Bounces: %d" % GameManager.bounce_currency


func _update_ball_button_states() -> void:
	if not spawn_manager:
		return
	
	for i in range(ball_spawn_buttons.size()):
		var button = ball_spawn_buttons[i]
		var config = spawn_manager.spawnable_balls[i]
		
		var can_afford = GameManager.bounce_currency >= config.cost
		var can_spawn = spawn_manager.can_spawn_ball_type(config)
		
		button.disabled = not (can_afford and can_spawn)


func _update_prestige_display() -> void:
	if prestige_points_available > 0:
		prestige_section.visible = true
		prestige_points_label.text = "Prestige Points: +%d" % prestige_points_available
		prestige_button.disabled = false
	else:
		prestige_section.visible = false