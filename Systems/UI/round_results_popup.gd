# Systems/UI/round_results_popup.gd
extends CanvasLayer

## Shows round results and allows player to continue or go to upgrades

signal go_again_pressed()
signal go_to_upgrades_pressed()

@onready var currency_earned_label: Label = %CurrencyEarnedLabel
@onready var essence_earned_label: Label = %EssenceEarnedLabel
@onready var total_currency_label: Label = %TotalCurrencyLabel
@onready var total_essence_label: Label = %TotalEssenceLabel
@onready var round_number_label: Label = %RoundNumberLabel
@onready var go_again_button: Button = %GoAgainButton
@onready var upgrades_button: Button = %UpgradesButton


func _ready() -> void:
	hide()
	
	go_again_button.pressed.connect(_on_go_again_pressed)
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	
	# Always process even when paused (in case we pause on round end)
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_results(stats: Dictionary) -> void:
	round_number_label.text = "Round Complete!"
	currency_earned_label.text = "Currency Earned: +$%d" % stats.get("currency_earned", 0)
	essence_earned_label.text = "Essence Earned: +%d" % stats.get("essence_earned", 0)
	total_currency_label.text = "Total Currency: $%d" % stats.get("total_currency", 0)
	total_essence_label.text = "Total Essence: %d" % stats.get("total_essence", 0)
	
	show()
	go_again_button.grab_focus()


func _on_go_again_pressed() -> void:
	hide()
	go_again_pressed.emit()


func _on_upgrades_pressed() -> void:
	hide()
	go_to_upgrades_pressed.emit()

func _on_round_manager_round_ended(stats: Dictionary) -> void:
	pass # Replace with function body.
