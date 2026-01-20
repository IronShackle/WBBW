# Scenes/Menus/main_menu.gd
extends Control

@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton
@onready var prestige_button: Button = $MarginContainer/VBoxContainer/PrestigeButton
@onready var reset_save_button: Button = $MarginContainer/BottomRightCorner/ResetSaveButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	prestige_button.pressed.connect(_on_prestige_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	reset_save_button.pressed.connect(_on_reset_save_pressed)
	
	# Focus play button for keyboard navigation
	play_button.grab_focus()


func _on_play_pressed() -> void:
	GameManager.start_game()


func _on_settings_pressed() -> void:
	# TODO: Open settings menu
	print("[MainMenu] Settings not implemented yet")


func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_prestige_pressed() -> void:
	GameManager.open_prestige_menu()

func _on_reset_save_pressed() -> void:
	GameManager.reset_save()
	get_tree().reload_current_scene()