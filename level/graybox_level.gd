extends Node3D
class_name GrayboxLevel

const DOOR_SCENE := preload("res://assets/environment/kenney/kenney_factory-kit_3.0/Models/GLB format/door-wide-closed.glb")
const PIPE_SCENE := preload("res://assets/environment/kenney/kenney_factory-kit_3.0/Models/GLB format/pipe-large.glb")
const MACHINE_SCENE := preload("res://assets/environment/kenney/kenney_factory-kit_3.0/Models/GLB format/machine.glb")
const CATWALK_SCENE := preload("res://assets/environment/kenney/kenney_factory-kit_3.0/Models/GLB format/catwalk-straight.glb")
const BOX_SCENE := preload("res://assets/environment/kenney/kenney_factory-kit_3.0/Models/GLB format/box-large.glb")
const INDICATOR_SCENE := preload("res://assets/environment/kenney/kenney_factory-kit_3.0/Models/GLB format/indicator-special-area.glb")

signal checkpoint_reached(number: int)
signal exit_reached
signal encounter_entered(number: int)

var colors := {
	"ground": Color("#9b7652"),
	"mountain": Color("#63534b"),
	"grass": Color("#6f8b4e"),
	"rock": Color("#74675f"),
	"cover": Color("#8f6948"),
	"hazard": Color("#c94f3c"),
	"objective": Color("#e2b84d")
}

func build() -> void:
	_build_lighting()
	_build_geometry()
	_build_industrial_decoration()
	_add_checkpoint(Vector3(0, 0.2, -8), 1)
	_add_checkpoint(Vector3(0, 0.2, -25), 2)
	_add_checkpoint(Vector3(0, 0.2, -45), 3)
	_add_encounter_trigger(Vector3(0, 1.5, -25), 1)
	_add_encounter_trigger(Vector3(0, 1.5, -62), 2)
	_add_exit_trigger(Vector3(0, 1.5, -75.5))

func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#d29d73")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c5a98f")
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	sun.light_color = Color("#ffe0b0")
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

func _build_geometry() -> void:
	for segment in [
		[Vector3(0, -0.25, 0), Vector3(30, 0.5, 24)],
		[Vector3(0, -0.25, -20), Vector3(26, 0.5, 20)],
		[Vector3(0, -0.25, -36), Vector3(38, 0.5, 24)],
		[Vector3(0, -0.25, -52), Vector3(24, 0.5, 16)],
		[Vector3(0, -0.25, -68), Vector3(42, 0.5, 32)],
		[Vector3(0, -0.25, -96), Vector3(32, 0.5, 24)],
		[Vector3(0, -0.25, -122), Vector3(46, 0.5, 34)]
	]:
		add_box("OutdoorGround", segment[0], segment[1], colors.ground)
	_add_mountain_wall(Vector3(-18, 4, -10), Vector3(5, 8, 80))
	_add_mountain_wall(Vector3(18, 4, -10), Vector3(5, 8, 80))
	_add_mountain_wall(Vector3(-24, 5, -82), Vector3(6, 10, 70))
	_add_mountain_wall(Vector3(24, 5, -82), Vector3(6, 10, 70))
	_add_stairs(Vector3(10, 0, -72), 5, 2.4, 1.8)
	_add_stairs(Vector3(-11, 0, -102), 6, 2.2, 1.7)
	add_box("LockedGate", Vector3(0, 2.5, -50), Vector3(24, 5, 0.5), colors.hazard)
	add_box("FinalGate", Vector3(0, 2.5, -115), Vector3(42, 5, 0.5), colors.hazard)
	add_box("ArenaCoverA", Vector3(-7, 1, -34), Vector3(4, 2, 2), colors.cover)
	add_box("ArenaCoverB", Vector3(8, 1, -40), Vector3(4, 2, 2), colors.cover)
	add_box("BossCoverA", Vector3(-10, 1, -120), Vector3(5, 2, 2), colors.cover)
	add_box("BossCoverB", Vector3(10, 1, -126), Vector3(5, 2, 2), colors.cover)
	var navigation_region := NavigationRegion3D.new()
	navigation_region.name = "OutdoorNavigation"
	navigation_region.navigation_mesh = NavigationMesh.new()
	add_child(navigation_region)

func _build_industrial_decoration() -> void:
	for position in [Vector3(-8, 0.4, -8), Vector3(7, 0.4, -18), Vector3(-9, 0.4, -31), Vector3(10, 0.4, -39), Vector3(-14, 0.4, -66), Vector3(14, 0.4, -74), Vector3(-16, 0.4, -116), Vector3(15, 0.4, -128)]:
		_add_boulder(position)
	for position in [Vector3(-6, 0.0, -5), Vector3(8, 0.0, -23), Vector3(-12, 0.0, -35), Vector3(12, 0.0, -45), Vector3(-15, 0.0, -63), Vector3(15, 0.0, -82), Vector3(-17, 0.0, -110), Vector3(17, 0.0, -132)]:
		_add_grass(position)
	for position in [Vector3(0, 0.05, -8), Vector3(0, 0.05, -25), Vector3(0, 0.05, -52), Vector3(0, 0.05, -96), Vector3(0, 0.05, -132)]:
		_add_beacon(position, colors.objective)
	for position in [Vector3(0, 0.03, -25), Vector3(0, 0.03, -62), Vector3(0, 0.03, -102), Vector3(0, 0.03, -132)]:
		_add_encounter_marker(position, colors.hazard)

func _add_mountain_wall(position: Vector3, size: Vector3) -> void:
	add_box("MountainWall", position, size, colors.mountain)
	for index in 3:
		var offset := Vector3((index - 1) * size.x * 0.35, size.y * 0.45, (index % 2) * 3.0 - 1.5)
		_add_boulder(position + offset, Vector3(1.8, 1.4, 1.8))

func _add_stairs(position: Vector3, step_count: int, step_width: float, step_depth: float) -> void:
	for index in step_count:
		var step_position := position + Vector3(0.0, index * 0.35, -index * step_depth)
		add_box("MountainStair", step_position, Vector3(step_width, 0.35, step_depth * (index + 1)), colors.rock)

func _add_boulder(position: Vector3, scale := Vector3.ONE) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Boulder"
	mesh_instance.position = position + Vector3.UP * scale.y * 0.45
	mesh_instance.scale = scale
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 1.5
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colors.rock
	material.roughness = 1.0
	mesh.material = material
	add_child(mesh_instance)

func _add_grass(position: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "GrassPatch"
	mesh_instance.position = position + Vector3.UP * 0.15
	var mesh := PrismMesh.new()
	mesh.size = Vector3(1.4, 0.3, 0.8)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colors.grass
	material.roughness = 0.95
	mesh.material = material
	add_child(mesh_instance)

func _add_pipe(position: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.16
	mesh.bottom_radius = 0.16
	mesh.height = 8.0
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees.z = 90.0
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.7
	material.roughness = 0.35
	mesh.material = material
	add_child(mesh_instance)

func _add_lamp(position: Vector3, color: Color) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = position
	lamp.light_color = color
	lamp.light_energy = 1.4
	lamp.omni_range = 7.0
	lamp.shadow_enabled = false
	add_child(lamp)
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	mesh.material = material
	add_child(mesh_instance)

func _add_prop_box(prop_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = prop_name
	mesh_instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.4
	material.roughness = 0.7
	mesh.material = material
	add_child(mesh_instance)

func _add_beacon(position: Vector3, color: Color) -> void:
	var beacon := OmniLight3D.new()
	beacon.position = position + Vector3.UP * 0.4
	beacon.light_color = color
	beacon.light_energy = 0.8
	beacon.omni_range = 3.0
	beacon.shadow_enabled = false
	add_child(beacon)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.3
	mesh.height = 0.12
	mesh_instance.mesh = mesh
	mesh_instance.position = position + Vector3.UP * 0.08
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	mesh.material = material
	add_child(mesh_instance)

func _add_encounter_marker(position: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(10.0, 0.04, 0.12)
	marker.mesh = mesh
	marker.position = position + Vector3.UP * 0.04
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5
	mesh.material = material
	add_child(marker)

func _add_asset(scene: PackedScene, position: Vector3, rotation: Vector3, scale: Vector3, collision_size := Vector3.ZERO) -> void:
	var instance := scene.instantiate()
	instance.position = position
	instance.rotation = rotation
	instance.scale = scale
	add_child(instance)
	if collision_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.name = "%sCollision" % instance.name
		body.position = position
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = collision_size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)

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

func open_gate(gate_name: String) -> void:
	var gate := get_node_or_null(gate_name) as StaticBody3D
	if gate == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(gate, "scale:x", 0.05, 0.45)
	tween.tween_callback(gate.queue_free)

func _add_checkpoint(position: Vector3, number: int) -> void:
	var area := Area3D.new()
	area.name = "Checkpoint_%d" % number
	area.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 3, 2)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.name == "Player":
			checkpoint_reached.emit(number)
	)
	add_child(area)

func _add_encounter_trigger(position: Vector3, number: int) -> void:
	var area := Area3D.new()
	area.name = "EncounterTrigger_%d" % number
	area.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12, 3, 10)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.name == "Player":
			encounter_entered.emit(number)
	)
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
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.name == "Player":
			exit_reached.emit()
	)
	add_child(area)
