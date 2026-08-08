extends Node3D

const PLAYER_SCRIPT := preload("res://player.gd")
const ENEMY_SCRIPT := preload("res://enemy.gd")
const RANGED_ENEMY_SCRIPT := preload("res://ranged_enemy.gd")
const ALLY_SCRIPT := preload("res://ally.gd")
const MOBILE_CONTROLS_SCRIPT := preload("res://mobile_controls.gd")

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

var colors := {
	"floor": Color("#38434a"),
	"wall": Color("#59636a"),
	"cover": Color("#a66b3f"),
	"hazard": Color("#d34e35"),
	"objective": Color("#47d7b0"),
	"checkpoint": Color("#4d8dff")
}

func _ready() -> void:
	_build_lighting()
	_build_level()
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

func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#10171c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8098aa")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_color = Color("#d9e7ff")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

func _build_level() -> void:
	# A single connected route: start room, corridor, combat yard, and extraction.
	add_box("StartFloor", Vector3(0, -0.25, 0), Vector3(18, 0.5, 18), colors.floor)
	add_box("StartLeftWall", Vector3(-9, 2.5, 0), Vector3(0.5, 5, 18), colors.wall)
	add_box("StartRightWall", Vector3(9, 2.5, 0), Vector3(0.5, 5, 18), colors.wall)
	add_box("StartBackWall", Vector3(0, 2.5, 9), Vector3(18, 5, 0.5), colors.wall)

	add_box("CorridorFloor", Vector3(0, -0.25, -16), Vector3(10, 0.5, 18), colors.floor)
	add_box("CorridorLeftWall", Vector3(-5, 2.5, -16), Vector3(0.5, 5, 18), colors.wall)
	add_box("CorridorRightWall", Vector3(5, 2.5, -16), Vector3(0.5, 5, 18), colors.wall)
	add_box("CorridorRoofBeam", Vector3(0, 5, -16), Vector3(10, 0.5, 18), colors.wall)

	add_box("CombatYardFloor", Vector3(0, -0.25, -32), Vector3(26, 0.5, 14), colors.floor)
	add_box("YardLeftWall", Vector3(-13, 2.5, -32), Vector3(0.5, 5, 14), colors.wall)
	add_box("YardRightWall", Vector3(13, 2.5, -32), Vector3(0.5, 5, 14), colors.wall)
	add_box("YardFarWall", Vector3(0, 2.5, -39), Vector3(26, 5, 0.5), colors.wall)

	add_box("ExitFloor", Vector3(0, -0.25, -47), Vector3(14, 0.5, 16), colors.floor)
	add_box("ExitLeftWall", Vector3(-7, 2.5, -47), Vector3(0.5, 5, 16), colors.wall)
	add_box("ExitRightWall", Vector3(7, 2.5, -47), Vector3(0.5, 5, 16), colors.wall)

	# Cover and navigation landmarks for future combat encounters.
	add_box("CoverA", Vector3(-4, 1, -29), Vector3(3, 2, 1.5), colors.cover)
	add_box("CoverB", Vector3(5, 1, -35), Vector3(3, 2, 1.5), colors.cover)
	add_box("BlockedPassage", Vector3(0, 1.5, -40), Vector3(5, 3, 1), colors.hazard)
	for position in [Vector3(-8, 2, -32), Vector3(8, 2, -32), Vector3(-4, 2, -44), Vector3(4, 2, -44)]:
		add_box("Pillar", position, Vector3(1, 4, 1), colors.wall)

	add_box("ExitGateLeft", Vector3(-4.5, 3, -54), Vector3(1, 6, 1), colors.objective)
	add_box("ExitGateRight", Vector3(4.5, 3, -54), Vector3(1, 6, 1), colors.objective)
	add_box("ExitGateTop", Vector3(0, 6, -54), Vector3(10, 1, 1), colors.objective)
	add_box("LockedGate", Vector3(0, 2.5, -50), Vector3(8, 5, 0.5), colors.hazard)
	add_box("SecondFloor", Vector3(0, -0.25, -66), Vector3(18, 0.5, 22), colors.floor)
	add_box("SecondLeftWall", Vector3(-9, 2.5, -66), Vector3(0.5, 5, 22), colors.wall)
	add_box("SecondRightWall", Vector3(9, 2.5, -66), Vector3(0.5, 5, 22), colors.wall)
	add_box("SecondFarWall", Vector3(0, 2.5, -77), Vector3(18, 5, 0.5), colors.wall)
	add_box("SecondCoverA", Vector3(-5, 1, -62), Vector3(3, 2, 1.5), colors.cover)
	add_box("SecondCoverB", Vector3(5, 1, -70), Vector3(3, 2, 1.5), colors.cover)
	add_box("FinalGate", Vector3(0, 2.5, -73), Vector3(8, 5, 0.5), colors.hazard)

	_add_checkpoint(Vector3(0, 0.2, -8), 1)
	_add_checkpoint(Vector3(0, 0.2, -25), 2)
	_add_checkpoint(Vector3(0, 0.2, -45), 3)
	_add_exit_trigger(Vector3(0, 1.5, -78))

func add_box(box_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = position
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	box_mesh.material = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.1, 5)
	player.set_script(PLAYER_SCRIPT)
	var mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = 1.8
	capsule_mesh.radius = 0.4
	mesh_instance.mesh = capsule_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#55b7ff")
	capsule_mesh.material = material
	player.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = 1.8
	capsule_shape.radius = 0.4
	collision.shape = capsule_shape
	player.add_child(collision)
	add_child(player)

func _build_enemy() -> void:
	_spawn_melee_enemy("TrainingEnemy", Vector3(0, 1.1, -31))

func _build_ally() -> void:
	var ally := CharacterBody3D.new()
	ally.name = "Companion"
	ally.position = Vector3(-2.0, 1.1, 5.5)
	ally.set_script(ALLY_SCRIPT)
	ally.target = player
	var mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = 1.6
	capsule_mesh.radius = 0.35
	mesh_instance.mesh = capsule_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#4de0aa")
	capsule_mesh.material = material
	ally.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = 1.6
	capsule_shape.radius = 0.35
	collision.shape = capsule_shape
	ally.add_child(collision)
	add_child(ally)

func _spawn_melee_enemy(enemy_name: String, spawn_position: Vector3) -> void:
	var enemy := CharacterBody3D.new()
	enemy.name = enemy_name
	enemy.position = spawn_position
	enemy.set_script(ENEMY_SCRIPT)
	enemy.target = player
	enemy.add_to_group("enemies")
	var mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = 1.8
	capsule_mesh.radius = 0.45
	mesh_instance.mesh = capsule_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#d84c5c")
	capsule_mesh.material = material
	enemy.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = 1.8
	capsule_shape.radius = 0.45
	collision.shape = capsule_shape
	enemy.add_child(collision)
	add_child(enemy)

func _build_ranged_enemy() -> void:
	_spawn_ranged_enemy("RangedEnemy", Vector3(8, 1.1, -35))

func _spawn_ranged_enemy(enemy_name: String, spawn_position: Vector3) -> void:
	var enemy := CharacterBody3D.new()
	enemy.name = enemy_name
	enemy.position = spawn_position
	enemy.set_script(RANGED_ENEMY_SCRIPT)
	enemy.target = player
	enemy.add_to_group("enemies")
	var mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = 1.8
	capsule_mesh.radius = 0.4
	mesh_instance.mesh = capsule_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#a65de0")
	capsule_mesh.material = material
	enemy.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = 1.8
	capsule_shape.radius = 0.4
	collision.shape = capsule_shape
	enemy.add_child(collision)
	add_child(enemy)

func _add_checkpoint(position: Vector3, number: int) -> void:
	var area := Area3D.new()
	area.name = "Checkpoint_%d" % number
	area.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 3, 2)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_checkpoint_entered.bind(number))
	add_child(area)

func _add_exit_trigger(position: Vector3) -> void:
	var area := Area3D.new()
	area.name = "ExtractionTrigger"
	area.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 4, 2)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_exit_entered)
	add_child(area)

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

func _on_checkpoint_entered(_body: Node3D, number: int) -> void:
	if number > checkpoint:
		checkpoint = number
		player.respawn_position = player.global_position
		checkpoint_label.text = "CHECKPOINT %d / 3" % checkpoint

func _on_exit_entered(_body: Node3D) -> void:
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
		var locked_gate := get_node_or_null("LockedGate")
		if locked_gate:
			locked_gate.queue_free()
		_spawn_melee_enemy("SecondMelee", Vector3(-4, 1.1, -66))
		_spawn_ranged_enemy("SecondRanged", Vector3(5, 1.1, -70))
	elif encounter_stage == 2:
		encounter_complete = true
		status_label.text = "ALL AREAS CLEAR  |  FINAL GATE UNLOCKED"
		status_label.add_theme_color_override("font_color", colors.objective)
		var final_gate := get_node_or_null("FinalGate")
		if final_gate:
			final_gate.queue_free()

func play_feedback(frequency: float, duration: float) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var samples := PackedByteArray()
	var sample_count := int(stream.mix_rate * duration)
	for index in sample_count:
		var envelope := 1.0 - (float(index) / float(sample_count))
		var sample := int(sin(float(index) * TAU * frequency / stream.mix_rate) * 11000.0 * envelope)
		samples.append(sample & 255)
		samples.append((sample >> 8) & 255)
	stream.data = samples
	var player_audio := AudioStreamPlayer.new()
	player_audio.stream = stream
	player_audio.volume_db = -12.0
	add_child(player_audio)
	player_audio.finished.connect(player_audio.queue_free)
	player_audio.play()
