# Systems/UI/upgrade_menu.gd
extends CanvasLayer

signal start_round_pressed()

@onready var currency_label: Label = %CurrencyLabel
@onready var essence_label: Label = %EssenceLabel
@onready var corruption_label: Label = %CorruptionLabel
@onready var continue_game_button: Button = %ContinueButton


func _ready() -> void:
	# Process while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	continue_game_button.pressed.connect(_on_start_round_pressed)
	_update_currency_display()
	
	# Connect to GameManager currency signals
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.essence_changed.connect(_on_essence_changed)


func _update_currency_display() -> void:
	currency_label.text = "Currency: $%d" % GameManager.currency
	essence_label.text = "Essence: %d" % GameManager.essence
	corruption_label.text = "Corruption: %d" % GameManager.corruption_points


func _on_currency_changed(new_amount: int) -> void:
	_update_currency_display()


func _on_essence_changed(new_amount: int) -> void:
	_update_currency_display()


func _on_start_round_pressed() -> void:
	start_round_pressed.emit()
