# Scenes/Game/game_controller.gd
extends Node2D

@onready var round_manager: RoundManager = $RoundManager
@onready var results_popup: CanvasLayer = $RoundResultsPopup
@onready var upgrade_menu: CanvasLayer = $UpgradeMenu

func _ready() -> void:
	# Connect signals
	round_manager.round_ended.connect(_on_round_ended)
	results_popup.go_again_pressed.connect(_on_go_again)
	results_popup.go_to_upgrades_pressed.connect(_on_show_upgrades)
	upgrade_menu.start_round_pressed.connect(_on_start_round_from_upgrades)
	
	# Hide UI initially
	results_popup.hide()
	upgrade_menu.hide()


func _on_round_ended(stats: Dictionary) -> void:
	results_popup.show_results(stats)


func _on_go_again() -> void:
	round_manager.start_round()


func _on_show_upgrades() -> void:
	upgrade_menu.show()


func _on_start_round_from_upgrades() -> void:
	upgrade_menu.hide()
	round_manager.start_round()
