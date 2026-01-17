# Scenes/Menus/prestige_menu.gd
extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var points_label: Label = $MarginContainer/VBoxContainer/PointsLabel
@onready var tree_content: Control = $MarginContainer/VBoxContainer/TreeContainer/TreeContent
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton
@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/Footer/MainMenuButton

var current_tree_id: String = "friction"  # Default tree
var node_buttons: Dictionary = {}  # node_id -> Button
var came_from_game: bool = false  # Track where we came from


func _ready() -> void:
	# Connect buttons
	back_button.pressed.connect(_on_back_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Connect to PrestigeManager signals
	PrestigeManager.prestige_points_changed.connect(_on_prestige_points_changed)
	PrestigeManager.node_unlocked.connect(_on_node_unlocked)
	
	# Load and display the tree
	_load_tree(current_tree_id)


func _load_tree(tree_id: String) -> void:
	current_tree_id = tree_id
	var prestige_tree = PrestigeManager.get_prestige_tree(tree_id)
	
	if not prestige_tree:
		push_error("Cannot load tree: %s" % tree_id)
		return
	
	title_label.text = prestige_tree.tree_name
	_update_points_label()
	_build_tree_ui(prestige_tree)


func _build_tree_ui(prestige_tree: PrestigeTree) -> void:
	# Clear existing buttons
	for child in tree_content.get_children():
		child.queue_free()
	node_buttons.clear()
	
	# Create button for each node
	for node in prestige_tree.get_all_nodes():
		var button = _create_node_button(node)
		tree_content.add_child(button)
		node_buttons[node.id] = button


func _create_node_button(node: PrestigeNode) -> Button:
	var button = Button.new()
	button.name = node.id
	button.position = node.position
	button.custom_minimum_size = Vector2(150, 80)
	
	# Set text
	var status = ""
	if node.is_unlocked:
		status = "[UNLOCKED]"
	else:
		status = "Cost: %d" % node.cost
	
	button.text = "%s\n%s" % [node.display_name, status]
	
	# Set disabled state
	var prestige_tree = PrestigeManager.get_prestige_tree(current_tree_id)
	button.disabled = node.is_unlocked or not prestige_tree.can_unlock_node(node.id, PrestigeManager.prestige_points)
	
	# Connect signal
	button.pressed.connect(_on_node_button_pressed.bind(node.id))
	
	# Tooltip
	button.tooltip_text = node.description
	
	# Styling
	_style_node_button(button, node)
	
	return button


func _style_node_button(button: Button, node: PrestigeNode) -> void:
	# Font size
	button.add_theme_font_size_override("font_size", 14)
	
	# Normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.3, 0.5) if not node.is_unlocked else Color(0.3, 0.5, 0.3)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color.WHITE
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.4, 0.6) if not node.is_unlocked else Color(0.4, 0.6, 0.4)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color.YELLOW
	hover_style.corner_radius_top_left = 5
	hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_left = 5
	hover_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.15, 0.2, 0.4)
	pressed_style.border_width_left = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = Color.WHITE
	pressed_style.corner_radius_top_left = 5
	pressed_style.corner_radius_top_right = 5
	pressed_style.corner_radius_bottom_left = 5
	pressed_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("pressed", pressed_style)
	
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


func _on_node_button_pressed(node_id: String) -> void:
	PrestigeManager.try_unlock_node(current_tree_id, node_id)


func _on_node_unlocked(tree_id: String, node_id: String) -> void:
	if tree_id != current_tree_id:
		return
	
	# Refresh the tree display
	var prestige_tree = PrestigeManager.get_prestige_tree(tree_id)
	if prestige_tree:
		_build_tree_ui(prestige_tree)


func _on_prestige_points_changed(new_amount: int) -> void:
	_update_points_label()
	
	# Update button states
	if current_tree_id:
		var prestige_tree = PrestigeManager.get_prestige_tree(current_tree_id)
		if prestige_tree:
			for node in prestige_tree.get_all_nodes():
				var button = node_buttons.get(node.id)
				if button:
					button.disabled = node.is_unlocked or not prestige_tree.can_unlock_node(node.id, new_amount)


func _update_points_label() -> void:
	points_label.text = "Prestige Points: %d" % PrestigeManager.prestige_points


func _on_back_pressed() -> void:
	# Return to game
	GameManager.start_game()


func _on_main_menu_pressed() -> void:
	# Return to main menu
	GameManager.return_to_menu()
