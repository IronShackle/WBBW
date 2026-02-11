# Autoloads/game_manager.gd
extends Node

## Handles game state, progression tracking, and save/load

signal game_started()
signal game_paused(paused: bool)
signal currency_changed(new_amount: int)
signal essence_changed(new_amount: int)
signal bounce_registered()


# Persistent progression
var total_lifetime_bounces: int = 0
var unlocked_upgrades: Array[String] = []

# Current run tracking
var current_run_bounces: int = 0

# Currency
var currency: int = 0
var essence: int = 0
var corruption_points: int = 0

# Game state
var is_paused: bool = false
var in_game: bool = false

# Autosave
var autosave_interval: float = 30.0
var autosave_timer: float = 0.0

const SAVE_PATH = "user://save_game.json"


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	# Autosave timer (only when in game)
	if not is_paused and in_game:
		autosave_timer += delta
		if autosave_timer >= autosave_interval:
			autosave_timer = 0.0
			save_game()


## Scene transitions
func start_game() -> void:
	current_run_bounces = 0
	in_game = true
	get_tree().change_scene_to_file("res://Scenes/Game/Game.tscn")
	
	# Wait for scene to load, then restore barrier state
	await get_tree().process_frame
	await get_tree().process_frame
	
	var barrier_data = get("_pending_barrier_data")
	if barrier_data and not barrier_data.is_empty():
		load_barrier_save_data(barrier_data)
	
	game_started.emit()


func return_to_menu() -> void:
	save_game()
	in_game = false
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")


## Pause system
func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)


func pause() -> void:
	if not is_paused:
		toggle_pause()


func unpause() -> void:
	if is_paused:
		toggle_pause()


## Bounce tracking (for barriers only)
func register_bounce() -> void:
	current_run_bounces += 1
	bounce_registered.emit()


## Currency system
func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)


func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		currency_changed.emit(currency)
		return true
	return false


func add_essence(amount: int) -> void:
	essence += amount
	essence_changed.emit(essence)


func spend_essence(amount: int) -> bool:
	if essence >= amount:
		essence -= amount
		essence_changed.emit(essence)
		return true
	return false


func add_corruption_points(amount: int) -> void:
	corruption_points += amount


func spend_corruption_points(amount: int) -> bool:
	if corruption_points >= amount:
		corruption_points -= amount
		return true
	return false


## Barrier save/load helpers
func get_barrier_save_data() -> Dictionary:
	var barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	if barrier_manager:
		return {
			"current_tier": barrier_manager.current_barrier_tier,
			"barrier_bounces": barrier_manager.barrier_bounces
		}
	return {}


func load_barrier_save_data(data: Dictionary) -> void:
	var barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	if barrier_manager and data:
		var tier = data.get("current_tier", 0)
		var bounces = data.get("barrier_bounces", 0)
		
		barrier_manager.current_barrier_tier = tier
		barrier_manager.barrier_bounces = bounces
		
		# Remove broken barriers
		for i in range(tier):
			if i < barrier_manager.barriers.size() and is_instance_valid(barrier_manager.barriers[i]):
				barrier_manager.barriers[i].queue_free()
		
		# Update UI
		var required = barrier_manager.get_current_barrier_requirement()
		barrier_manager.barrier_damage_changed.emit(bounces, required)


## Save/Load
func save_game() -> void:
	var save_data = {
		"total_lifetime_bounces": total_lifetime_bounces,
		"unlocked_upgrades": unlocked_upgrades,
		"currency": currency,
		"essence": essence,
		"corruption_points": corruption_points,
		"barrier_data": get_barrier_save_data(),
		"version": "1.0"
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
	else:
		push_error("[GameManager] Failed to save game!")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var save_data = JSON.parse_string(json_string)
		
		if save_data:
			total_lifetime_bounces = save_data.get("total_lifetime_bounces", 0)
			currency = save_data.get("currency", 0)
			essence = save_data.get("essence", 0)
			corruption_points = save_data.get("corruption_points", 0)
			
			# Handle array conversion for typed arrays
			var loaded_upgrades = save_data.get("unlocked_upgrades", [])
			unlocked_upgrades.clear()
			for upgrade in loaded_upgrades:
				if upgrade is String:
					unlocked_upgrades.append(upgrade)
			
			# Store barrier data for later loading (after scene loads)
			var barrier_data = save_data.get("barrier_data", {})
			if not barrier_data.is_empty():
				set("_pending_barrier_data", barrier_data)
		else:
			push_error("[GameManager] Failed to parse save file!")
	else:
		push_error("[GameManager] Failed to open save file!")


func reset_save() -> void:
	total_lifetime_bounces = 0
	unlocked_upgrades.clear()
	current_run_bounces = 0
	currency = 0
	essence = 0
	corruption_points = 0
	
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	save_game()


func _notification(what: int) -> void:
	# Save when closing game
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()