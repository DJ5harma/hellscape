extends Node3D

const MOBILE_CONTROLS_SCRIPT := preload("res://mobile_controls.gd")
const FEEDBACK_AUDIO_SCRIPT := preload("res://systems/feedback_audio.gd")
const ACTOR_FACTORY_SCRIPT := preload("res://systems/actor_factory.gd")
const LEVEL_SCRIPT := preload("res://level/graybox_level.gd")
const LEVEL_TWO_SCRIPT := preload("res://level/level_2.gd")
const HUD_SCRIPT := preload("res://ui/game_hud.gd")
const PAUSE_MENU_SCRIPT := preload("res://ui/pause_menu.gd")
const JUGGERNAUT_CHARACTER_DATA := preload("res://data/juggernaut_character.tres")
const SCOUT_CHARACTER_DATA := preload("res://data/scout_character.tres")
const MARKSMAN_CHARACTER_DATA := preload("res://data/marksman_character.tres")
const BRUISER_ENEMY_DATA := preload("res://data/bruiser_enemy.tres")
const SNIPER_ENEMY_DATA := preload("res://data/sniper_enemy.tres")

var checkpoint := 0
var encounter_complete := false
var completion_shown := false
var player: CharacterBody3D
var remaining_enemies := 2
var feedback_audio
var actor_factory
var level
var hud
var mobile_controls
var pause_menu
var character_roster: Array[CharacterData] = []
var selected_character_index := 0
var settings := ConfigFile.new()
const SETTINGS_PATH := "user://hellscape.cfg"

@export var level_number := 1

var colors := {
	"floor": Color("#38434a"),
	"wall": Color("#59636a"),
	"cover": Color("#a66b3f"),
	"hazard": Color("#d34e35"),
	"objective": Color("#47d7b0"),
	"checkpoint": Color("#4d8dff")
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	character_roster = [JUGGERNAUT_CHARACTER_DATA, SCOUT_CHARACTER_DATA, MARKSMAN_CHARACTER_DATA]
	feedback_audio = FEEDBACK_AUDIO_SCRIPT.new()
	feedback_audio.name = "FeedbackAudio"
	add_child(feedback_audio)
	actor_factory = ACTOR_FACTORY_SCRIPT.new()
	actor_factory.name = "ActorFactory"
	add_child(actor_factory)
	var level_script = LEVEL_TWO_SCRIPT if level_number == 2 else LEVEL_SCRIPT
	level = level_script.new()
	level.name = "GrayboxLevel"
	add_child(level)
	level.checkpoint_reached.connect(_on_checkpoint_entered)
	level.exit_reached.connect(_on_exit_entered)
	level.build()
	_build_player()
	player.combat_feedback.connect(_on_combat_feedback)
	_build_ally()
	_build_enemy()
	_build_ranged_enemy()
	_build_hud()
	_build_pause_menu()
	_build_mobile_controls()
	hud.next_level_requested.connect(_load_level_two)
	hud.set_status("LEVEL %d  |  %s  |  CLEAR THE ENCOUNTER" % [level_number, player.character_data.display_name])

func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(hud):
		hud.update_player(player)
		if is_instance_valid(mobile_controls):
			mobile_controls.set_ability_state(
				player.is_special_ready(),
				player.is_dodge_ready(),
				player.is_heavy_ready()
			)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		pause_menu.toggle()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		selected_character_index = (selected_character_index + 1) % character_roster.size()
		var selected_data: CharacterData = character_roster[selected_character_index]
		player.set_character_data(selected_data)
		mobile_controls.configure_actions(selected_data.mobile_actions, selected_data)
		hud.set_status("CHARACTER: %s" % selected_data.display_name, selected_data.visual_color)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_N:
		_load_level_two()

func _build_pause_menu() -> void:
	pause_menu = PAUSE_MENU_SCRIPT.new()
	pause_menu.name = "PauseMenu"
	pause_menu.layer = 10
	add_child(pause_menu)
	pause_menu.restart_requested.connect(_restart_level)
	pause_menu.sensitivity_changed.connect(_set_camera_sensitivity)
	pause_menu.volume_changed.connect(_set_master_volume)
	_load_settings()

func _build_player() -> void:
	var spawn_position := Vector3(0, 1.1, 5) if level_number == 1 else Vector3(0, 1.1, -56)
	player = actor_factory.create_player(self, spawn_position)

func _build_enemy() -> void:
	var spawn_position := Vector3(0, 1.1, -31) if level_number == 1 else Vector3(-4, 1.1, -66)
	var data := null if level_number == 1 else BRUISER_ENEMY_DATA
	_spawn_melee_enemy("Level%dMelee" % level_number, spawn_position, data)

func _build_ally() -> void:
	actor_factory.create_ally(self, player, Vector3(-2.0, 1.1, 5.5))

func _spawn_melee_enemy(enemy_name: String, spawn_position: Vector3, enemy_data: Resource = null) -> void:
	actor_factory.create_melee_enemy(self, enemy_name, player, spawn_position, enemy_data)

func _build_ranged_enemy() -> void:
	var spawn_position := Vector3(8, 1.1, -35) if level_number == 1 else Vector3(5, 1.1, -70)
	var data := null if level_number == 1 else SNIPER_ENEMY_DATA
	_spawn_ranged_enemy("Level%dRanged" % level_number, spawn_position, data)

func _spawn_ranged_enemy(enemy_name: String, spawn_position: Vector3, enemy_data: Resource = null) -> void:
	actor_factory.create_ranged_enemy(self, enemy_name, player, spawn_position, enemy_data)

func _build_hud() -> void:
	hud = HUD_SCRIPT.new()
	hud.name = "GameHUD"
	hud.layer = 5
	add_child(hud)
	hud.build()

func _load_level_two() -> void:
	if level_number == 1 and encounter_complete:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://level_2.tscn")

func _build_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileControlsLayer"
	layer.layer = 3
	add_child(layer)
	var controls := Control.new()
	controls.name = "MobileControls"
	controls.set_script(MOBILE_CONTROLS_SCRIPT)
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(controls)
	mobile_controls = controls
	controls.configure_actions(player.character_data.mobile_actions, player.character_data)
	controls.movement_changed.connect(player.set_mobile_move)
	controls.look_changed.connect(player.apply_mobile_look)
	controls.attack_pressed.connect(player.mobile_attack)
	controls.special_pressed.connect(player.mobile_special)
	controls.dodge_pressed.connect(player.mobile_dodge)
	controls.jump_pressed.connect(player.request_jump)
	controls.heavy_pressed.connect(player.mobile_heavy)
	controls.pause_pressed.connect(pause_menu.toggle)

func _set_camera_sensitivity(value: float) -> void:
	player.look_sensitivity = value
	settings.set_value("controls", "sensitivity", value)
	settings.save(SETTINGS_PATH)

func _set_master_volume(value: float) -> void:
	var decibels := -80.0 if value <= 0.0 else linear_to_db(value)
	AudioServer.set_bus_volume_db(0, decibels)
	settings.set_value("audio", "master_volume", value)
	settings.save(SETTINGS_PATH)

func _load_settings() -> void:
	settings.load(SETTINGS_PATH)
	var sensitivity: float = settings.get_value("controls", "sensitivity", 0.003)
	var volume: float = settings.get_value("audio", "master_volume", 1.0)
	player.look_sensitivity = sensitivity
	_set_master_volume(volume)
	pause_menu.set_settings(sensitivity, volume)

func _restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_checkpoint_entered(number: int) -> void:
	if number > checkpoint:
		checkpoint = number
		player.respawn_position = player.global_position
		hud.set_checkpoint(checkpoint)

func _on_combat_feedback(message: String, color: Color) -> void:
	hud.set_status(message, color)

func _on_exit_entered() -> void:
	if completion_shown:
		return
	completion_shown = true
	if encounter_complete:
		var completion_text := "EXTRACTION REACHED  |  LEVEL %d COMPLETE" % level_number
		hud.set_status(completion_text, colors.objective)
		hud.show_completion(level_number == 1)
	else:
		hud.set_status("GATE LOCKED  |  CLEAR BOTH ENCOUNTERS FIRST")

func enemy_defeated() -> void:
	remaining_enemies -= 1
	if remaining_enemies > 0:
		hud.set_status("ENEMY DEFEATED  |  %d REMAINING" % remaining_enemies)
		return
	encounter_complete = true
	completion_shown = true
	if level_number == 1:
		hud.set_status("LEVEL 1 COMPLETE  |  SELECT NEXT LEVEL", colors.objective)
		level.open_gate("LockedGate")
		hud.show_completion(true)
	else:
		hud.set_status("LEVEL 2 COMPLETE  |  EXTRACTION AVAILABLE", colors.objective)
		level.open_gate("FinalGate")
		hud.show_completion(false)

func play_feedback(frequency: float, duration: float) -> void:
	feedback_audio.play_tone(frequency, duration)
