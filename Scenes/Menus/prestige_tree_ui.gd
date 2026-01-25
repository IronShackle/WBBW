# Systems/UI/prestige_tree_ui.gd
extends Control

@onready var pannable_canvas: Control = $PannableCanvas
@onready var content: Control = $PannableCanvas/Content
@onready var points_label: Label = $BottomBar/MarginContainer/HBoxContainer/PointsLabel
@onready var continue_button: Button = $BottomBar/MarginContainer/HBoxContainer/ContinueButton

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

var current_zoom: float = 1.0
var is_panning: bool = false
var pan_start_pos: Vector2
var canvas_start_pos: Vector2


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	content.pivot_offset = content.size / 2
	_update_points_display()


func _input(event: InputEvent) -> void:
	if not pannable_canvas.get_global_rect().has_point(get_global_mouse_position()):
		return

	# Left-click drag
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_panning = true
			pan_start_pos = event.position
			canvas_start_pos = content.position
		else:
			is_panning = false
	
	if event is InputEventMouseMotion and is_panning:
		var delta = event.position - pan_start_pos
		content.position = canvas_start_pos + delta
	
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(zoom_speed, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-zoom_speed, event.position)


func _zoom(delta: float, mouse_pos: Vector2) -> void:
	var old_zoom = current_zoom
	current_zoom = clamp(current_zoom + delta, min_zoom, max_zoom)
	
	# Zoom toward mouse position
	var zoom_center = mouse_pos - content.position
	content.scale = Vector2(current_zoom, current_zoom)
	content.position += zoom_center * (1.0 - current_zoom / old_zoom)


func _update_points_display() -> void:
	var allocated = 0  # TODO: Calculate from allocated nodes
	var total = PrestigeManager.prestige_points
	points_label.text = "Points: %d / %d" % [allocated, total]


func _on_continue_pressed() -> void:
	GameManager.start_game()