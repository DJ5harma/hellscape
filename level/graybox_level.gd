extends Node3D
class_name GrayboxLevel

signal checkpoint_reached(number: int)
signal exit_reached

var colors := {
	"floor": Color("#38434a"),
	"wall": Color("#59636a"),
	"cover": Color("#a66b3f"),
	"hazard": Color("#d34e35"),
	"objective": Color("#47d7b0")
}

func build() -> void:
	_build_lighting()
	_build_geometry()
	_add_checkpoint(Vector3(0, 0.2, -8), 1)
	_add_checkpoint(Vector3(0, 0.2, -25), 2)
	_add_checkpoint(Vector3(0, 0.2, -45), 3)
	_add_exit_trigger(Vector3(0, 1.5, -78))

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

func _build_geometry() -> void:
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

func _add_checkpoint(position: Vector3, number: int) -> void:
	var area := Area3D.new()
	area.name = "Checkpoint_%d" % number
	area.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 3, 2)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(_body: Node3D) -> void: checkpoint_reached.emit(number))
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
	area.body_entered.connect(func(_body: Node3D) -> void: exit_reached.emit())
	add_child(area)
