# Scenes/Menus/main_menu.gd
extends Control

@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton
@onready var prestige_button: Button = $MarginContainer/VBoxContainer/PrestigeButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	prestige_button.pressed.connect(_on_prestige_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
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
