extends Node3D

const MOBILE_CONTROLS_SCRIPT := preload("res://mobile_controls.gd")
const FEEDBACK_AUDIO_SCRIPT := preload("res://systems/feedback_audio.gd")
const ACTOR_FACTORY_SCRIPT := preload("res://systems/actor_factory.gd")
const LEVEL_SCRIPT := preload("res://level/graybox_level.gd")
const HUD_SCRIPT := preload("res://ui/game_hud.gd")
const DEFAULT_CHARACTER_DATA := preload("res://data/default_character.tres")
const SCOUT_CHARACTER_DATA := preload("res://data/scout_character.tres")

var checkpoint := 0
var encounter_complete := false
var player: CharacterBody3D
var encounter_stage := 1
var remaining_enemies := 2
var feedback_audio
var actor_factory
var level
var hud
var mobile_controls
var using_scout := false

var colors := {
	"floor": Color("#38434a"),
	"wall": Color("#59636a"),
	"cover": Color("#a66b3f"),
	"hazard": Color("#d34e35"),
	"objective": Color("#47d7b0"),
	"checkpoint": Color("#4d8dff")
}

func _ready() -> void:
	feedback_audio = FEEDBACK_AUDIO_SCRIPT.new()
	feedback_audio.name = "FeedbackAudio"
	add_child(feedback_audio)
	actor_factory = ACTOR_FACTORY_SCRIPT.new()
	actor_factory.name = "ActorFactory"
	add_child(actor_factory)
	level = LEVEL_SCRIPT.new()
	level.name = "GrayboxLevel"
	add_child(level)
	level.checkpoint_reached.connect(_on_checkpoint_entered)
	level.exit_reached.connect(_on_exit_entered)
	level.build()
	_build_player()
	_build_ally()
	_build_enemy()
	_build_ranged_enemy()
	_build_hud()
	_build_mobile_controls()

func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(hud):
		hud.update_player(player)
		if is_instance_valid(mobile_controls):
			mobile_controls.set_ability_state(player.is_special_ready(), player.is_dodge_ready())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		using_scout = not using_scout
		var selected_data = SCOUT_CHARACTER_DATA if using_scout else DEFAULT_CHARACTER_DATA
		player.set_character_data(selected_data)
		hud.set_status("CHARACTER: %s" % selected_data.display_name, selected_data.visual_color)

func _build_player() -> void:
	player = actor_factory.create_player(self, Vector3(0, 1.1, 5))

func _build_enemy() -> void:
	_spawn_melee_enemy("TrainingEnemy", Vector3(0, 1.1, -31))

func _build_ally() -> void:
	actor_factory.create_ally(self, player, Vector3(-2.0, 1.1, 5.5))

func _spawn_melee_enemy(enemy_name: String, spawn_position: Vector3) -> void:
	actor_factory.create_melee_enemy(self, enemy_name, player, spawn_position)

func _build_ranged_enemy() -> void:
	_spawn_ranged_enemy("RangedEnemy", Vector3(8, 1.1, -35))

func _spawn_ranged_enemy(enemy_name: String, spawn_position: Vector3) -> void:
	actor_factory.create_ranged_enemy(self, enemy_name, player, spawn_position)

func _build_hud() -> void:
	hud = HUD_SCRIPT.new()
	hud.name = "GameHUD"
	add_child(hud)
	hud.build()

func _build_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileControlsLayer"
	add_child(layer)
	var controls := Control.new()
	controls.name = "MobileControls"
	controls.set_script(MOBILE_CONTROLS_SCRIPT)
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(controls)
	mobile_controls = controls
	controls.movement_changed.connect(player.set_mobile_move)
	controls.look_changed.connect(player.apply_mobile_look)
	controls.attack_pressed.connect(player.mobile_attack)
	controls.special_pressed.connect(player.mobile_special)
	controls.dodge_pressed.connect(player.mobile_dodge)

func _on_checkpoint_entered(number: int) -> void:
	if number > checkpoint:
		checkpoint = number
		player.respawn_position = player.global_position
		hud.set_checkpoint(checkpoint)

func _on_exit_entered() -> void:
	if encounter_complete:
		hud.set_status("EXTRACTION REACHED  |  GRAYBOX COMPLETE", colors.objective)
		hud.show_completion()
	else:
		hud.set_status("GATE LOCKED  |  CLEAR BOTH ENCOUNTERS FIRST")

func enemy_defeated() -> void:
	remaining_enemies -= 1
	if remaining_enemies > 0:
		hud.set_status("ENEMY DEFEATED  |  %d REMAINING" % remaining_enemies)
		return
	if encounter_stage == 1:
		encounter_stage = 2
		remaining_enemies = 2
		checkpoint = 4
		player.respawn_position = Vector3(0, 1.1, -56)
		hud.set_checkpoint(4)
		hud.set_status("FIRST AREA CLEAR  |  SECOND ENCOUNTER STARTING")
		var locked_gate: Node = level.get_node_or_null("LockedGate")
		if locked_gate:
			locked_gate.queue_free()
		_spawn_melee_enemy("SecondMelee", Vector3(-4, 1.1, -66))
		_spawn_ranged_enemy("SecondRanged", Vector3(5, 1.1, -70))
	elif encounter_stage == 2:
		encounter_complete = true
		hud.set_status("ALL AREAS CLEAR  |  FINAL GATE UNLOCKED", colors.objective)
		var final_gate: Node = level.get_node_or_null("FinalGate")
		if final_gate:
			final_gate.queue_free()

func play_feedback(frequency: float, duration: float) -> void:
	feedback_audio.play_tone(frequency, duration)
