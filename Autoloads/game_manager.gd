# Autoloads/game_manager.gd
extends Node

## Handles game state, progression tracking, and save/load

signal game_started()
signal game_paused(paused: bool)
signal prestige_available(current_bounces: int, threshold: int)
signal prestige_triggered(new_level: int)
signal bounce_currency_changed(new_amount: int)

# Persistent progression
var prestige_level: int = 0
var total_lifetime_bounces: int = 0
var unlocked_upgrades: Array[String] = []

# Current run tracking
var current_run_bounces: int = 0
var bounce_threshold: int = 100

# Bounce currency (separate from run bounces)
var bounce_currency: int = 0
var bounce_currency_per_bounce: int = 1

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
	game_started.emit()


func return_to_menu() -> void:
	save_game()
	in_game = false
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")


func open_prestige_menu() -> void:
	in_game = false
	get_tree().change_scene_to_file("res://Scenes/Menus/prestige_menu.tscn")


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


## Bounce tracking
func register_bounce() -> void:
	current_run_bounces += 1
	bounce_currency += bounce_currency_per_bounce
	bounce_currency_changed.emit(bounce_currency)
	
	print("[GameManager] Bounce registered! Total: %d / %d, Currency: %d" % 
		[current_run_bounces, bounce_threshold, bounce_currency])
	
	# Check if prestige threshold reached
	if current_run_bounces >= bounce_threshold:
		print("[GameManager] Threshold reached! Prestige available")
		prestige_available.emit(current_run_bounces, bounce_threshold)


## Prestige system
func trigger_prestige() -> void:
	prestige_level += 1
	total_lifetime_bounces += current_run_bounces
	
	# Award prestige points (1 point per 10 bounces)
	var points = current_run_bounces / 10.0
	PrestigeManager.add_prestige_points(int(points))
	
	current_run_bounces = 0
	
	save_game()
	prestige_triggered.emit(prestige_level)
	
	print("[GameManager] Prestige! Level: %d, Lifetime Bounces: %d, Points Awarded: %d" % 
		[prestige_level, total_lifetime_bounces, int(points)])
	
	# Reset barriers
	var barrier_manager = get_tree().get_first_node_in_group("barrier_manager")
	if barrier_manager:
		barrier_manager.reset_barriers()
	
	# Open prestige menu
	open_prestige_menu()


## Add prestige points from barriers or other sources
func add_prestige_points(amount: int) -> void:
	PrestigeManager.add_prestige_points(amount)
	print("[GameManager] Added %d prestige points" % amount)


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
		
		print("[GameManager] Loaded barrier state: tier %d, bounces %d/%d" % 
			[tier, bounces, required])


## Save/Load
func save_game() -> void:
	var save_data = {
		"prestige_level": prestige_level,
		"total_lifetime_bounces": total_lifetime_bounces,
		"unlocked_upgrades": unlocked_upgrades,
		"bounce_currency": bounce_currency,
		"barrier_data": get_barrier_save_data(),
		"version": "1.0"
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[GameManager] Game saved (Prestige: %d, Lifetime Bounces: %d, Currency: %d)" % 
			[prestige_level, total_lifetime_bounces, bounce_currency])
	else:
		push_error("[GameManager] Failed to save game!")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[GameManager] No save file found, starting fresh")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var save_data = JSON.parse_string(json_string)
		
		if save_data:
			prestige_level = save_data.get("prestige_level", 0)
			total_lifetime_bounces = save_data.get("total_lifetime_bounces", 0)
			bounce_currency = save_data.get("bounce_currency", 0)
			
			# Handle array conversion for typed arrays
			var loaded_upgrades = save_data.get("unlocked_upgrades", [])
			unlocked_upgrades.clear()
			for upgrade in loaded_upgrades:
				if upgrade is String:
					unlocked_upgrades.append(upgrade)
			
			# Load barrier state (deferred to ensure BarrierManager is ready)
			var barrier_data = save_data.get("barrier_data", {})
			if not barrier_data.is_empty():
				call_deferred("load_barrier_save_data", barrier_data)
			
			print("[GameManager] Game loaded - Prestige: %d, Lifetime Bounces: %d, Currency: %d" % 
				[prestige_level, total_lifetime_bounces, bounce_currency])
		else:
			push_error("[GameManager] Failed to parse save file!")
	else:
		push_error("[GameManager] Failed to open save file!")


func reset_save() -> void:
	prestige_level = 0
	total_lifetime_bounces = 0
	unlocked_upgrades.clear()
	current_run_bounces = 0
	bounce_currency = 0
	
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	save_game()
	print("[GameManager] Save reset!")


func _notification(what: int) -> void:
	# Save when closing game
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()