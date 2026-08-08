extends Node3D

const PLAYER_SCRIPT := preload("res://player.gd")
const ENEMY_SCRIPT := preload("res://enemy.gd")
const MOBILE_CONTROLS_SCRIPT := preload("res://mobile_controls.gd")

var status_label: Label
var checkpoint_label: Label
var checkpoint := 0
var encounter_complete := false
var player: CharacterBody3D

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
	_build_enemy()
	_build_hud()
	_build_mobile_controls()

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

	_add_checkpoint(Vector3(0, 0.2, -8), 1)
	_add_checkpoint(Vector3(0, 0.2, -25), 2)
	_add_checkpoint(Vector3(0, 0.2, -45), 3)
	_add_exit_trigger(Vector3(0, 1.5, -53))

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
	var enemy := CharacterBody3D.new()
	enemy.name = "TrainingEnemy"
	enemy.position = Vector3(0, 1.1, -31)
	enemy.set_script(ENEMY_SCRIPT)
	enemy.target = player
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
	checkpoint_label.text = "CHECKPOINT 0 / 3"
	layer.add_child(checkpoint_label)
	var help_label := Label.new()
	help_label.position = Vector2(28, 92)
	help_label.add_theme_color_override("font_color", Color("#f5c76b"))
	help_label.add_theme_font_size_override("font_size", 18)
	help_label.text = "SPACE to attack  |  Red enemy: 3 hits"
	layer.add_child(help_label)

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

func _on_checkpoint_entered(_body: Node3D, number: int) -> void:
	if number > checkpoint:
		checkpoint = number
		player.respawn_position = player.global_position
		checkpoint_label.text = "CHECKPOINT %d / 3" % checkpoint

func _on_exit_entered(_body: Node3D) -> void:
	if encounter_complete:
		status_label.text = "EXTRACTION REACHED  |  GRAYBOX COMPLETE"
		status_label.add_theme_color_override("font_color", colors.objective)
	else:
		status_label.text = "GATE LOCKED  |  DEFEAT THE RED ENEMY FIRST"

func enemy_defeated() -> void:
	encounter_complete = true
	status_label.text = "AREA CLEAR  |  EXTRACTION GATE UNLOCKED"
	status_label.add_theme_color_override("font_color", colors.objective)
	var locked_gate := get_node_or_null("LockedGate")
	if locked_gate:
		locked_gate.queue_free()
