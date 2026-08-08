extends Node3D

const MOBILE_CONTROLS_SCRIPT := preload("res://mobile_controls.gd")
const FEEDBACK_AUDIO_SCRIPT := preload("res://systems/feedback_audio.gd")
const ACTOR_FACTORY_SCRIPT := preload("res://systems/actor_factory.gd")
const LEVEL_SCRIPT := preload("res://level/graybox_level.gd")

var status_label: Label
var checkpoint_label: Label
var health_label: Label
var energy_label: Label
var completion_label: Label
var checkpoint := 0
var encounter_complete := false
var player: CharacterBody3D
var encounter_stage := 1
var remaining_enemies := 2
var feedback_audio
var actor_factory
var level

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
	if is_instance_valid(player) and is_instance_valid(health_label):
		health_label.text = "HEALTH %d" % player.health
		energy_label.text = "ENERGY %d / 100" % roundi(player.energy)

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
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(28, 24)
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.text = "REACH EXTRACTION  |  WASD to move  |  Mouse to look"
	layer.add_child(status_label)
	checkpoint_label = Label.new()
	checkpoint_label.position = Vector2(28, 58)
	checkpoint_label.add_theme_color_override("font_color", colors.checkpoint)
	checkpoint_label.add_theme_font_size_override("font_size", 20)
	checkpoint_label.text = "CHECKPOINT 0 / 4"
	layer.add_child(checkpoint_label)
	var help_label := Label.new()
	help_label.position = Vector2(28, 92)
	help_label.add_theme_color_override("font_color", Color("#f5c76b"))
	help_label.add_theme_font_size_override("font_size", 18)
	help_label.text = "1 attack  |  2 special  |  3 heavy  |  SPACE jump  |  SHIFT dodge  |  R reset"
	layer.add_child(help_label)
	health_label = Label.new()
	health_label.position = Vector2(28, 126)
	health_label.add_theme_color_override("font_color", Color("#ff7777"))
	health_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(health_label)
	energy_label = Label.new()
	energy_label.position = Vector2(28, 152)
	energy_label.add_theme_color_override("font_color", Color("#bd8cff"))
	energy_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(energy_label)
	completion_label = Label.new()
	completion_label.position = Vector2(420, 300)
	completion_label.add_theme_font_size_override("font_size", 38)
	completion_label.add_theme_color_override("font_color", colors.objective)
	completion_label.text = "LEVEL COMPLETE\nPress R to replay"
	completion_label.visible = false
	layer.add_child(completion_label)

func _build_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileControlsLayer"
	add_child(layer)
	var controls := Control.new()
	controls.name = "MobileControls"
	controls.set_script(MOBILE_CONTROLS_SCRIPT)
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(controls)
	controls.movement_changed.connect(player.set_mobile_move)
	controls.look_changed.connect(player.apply_mobile_look)
	controls.attack_pressed.connect(player.mobile_attack)
	controls.special_pressed.connect(player.mobile_special)
	controls.dodge_pressed.connect(player.mobile_dodge)

func _on_checkpoint_entered(number: int) -> void:
	if number > checkpoint:
		checkpoint = number
		player.respawn_position = player.global_position
		checkpoint_label.text = "CHECKPOINT %d / 3" % checkpoint

func _on_exit_entered() -> void:
	if encounter_complete:
		status_label.text = "EXTRACTION REACHED  |  GRAYBOX COMPLETE"
		status_label.add_theme_color_override("font_color", colors.objective)
		completion_label.visible = true
	else:
		status_label.text = "GATE LOCKED  |  CLEAR BOTH ENCOUNTERS FIRST"

func enemy_defeated() -> void:
	remaining_enemies -= 1
	if remaining_enemies > 0:
		status_label.text = "ENEMY DEFEATED  |  %d REMAINING" % remaining_enemies
		return
	if encounter_stage == 1:
		encounter_stage = 2
		remaining_enemies = 2
		checkpoint = 4
		player.respawn_position = Vector3(0, 1.1, -56)
		checkpoint_label.text = "CHECKPOINT 4 / 4"
		status_label.text = "FIRST AREA CLEAR  |  SECOND ENCOUNTER STARTING"
		var locked_gate: Node = level.get_node_or_null("LockedGate")
		if locked_gate:
			locked_gate.queue_free()
		_spawn_melee_enemy("SecondMelee", Vector3(-4, 1.1, -66))
		_spawn_ranged_enemy("SecondRanged", Vector3(5, 1.1, -70))
	elif encounter_stage == 2:
		encounter_complete = true
		status_label.text = "ALL AREAS CLEAR  |  FINAL GATE UNLOCKED"
		status_label.add_theme_color_override("font_color", colors.objective)
		var final_gate: Node = level.get_node_or_null("FinalGate")
		if final_gate:
			final_gate.queue_free()

func play_feedback(frequency: float, duration: float) -> void:
	feedback_audio.play_tone(frequency, duration)
