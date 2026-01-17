# Systems/UI/pause_menu.gd
extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	# Start hidden
	hide()
	
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect to GameManager signals
	GameManager.game_paused.connect(_on_game_paused)
	
	# Set process mode so it works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	# Toggle pause with Escape key
	if event.is_action_pressed("ui_cancel"):
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_game_paused(paused: bool) -> void:
	if paused:
		show()
		resume_button.grab_focus()
	else:
		hide()


func _on_resume_pressed() -> void:
	GameManager.unpause()


func _on_main_menu_pressed() -> void:
	GameManager.unpause()  # Unpause before changing scene
	GameManager.return_to_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
