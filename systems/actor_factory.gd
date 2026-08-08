extends Node
class_name ActorFactory

const PLAYER_SCRIPT := preload("res://player.gd")
const ENEMY_SCRIPT := preload("res://enemy.gd")
const RANGED_ENEMY_SCRIPT := preload("res://ranged_enemy.gd")
const ALLY_SCRIPT := preload("res://ally.gd")

func create_player(parent: Node, spawn_position: Vector3) -> CharacterBody3D:
	var player := _create_character(parent, "Player", spawn_position, PLAYER_SCRIPT, 1.8, 0.4, Color("#55b7ff"))
	return player

func create_ally(parent: Node, target: CharacterBody3D, spawn_position: Vector3) -> CharacterBody3D:
	var ally := _create_character(parent, "Companion", spawn_position, ALLY_SCRIPT, 1.6, 0.35, Color("#4de0aa"))
	ally.target = target
	return ally

func create_melee_enemy(parent: Node, enemy_name: String, target: CharacterBody3D, spawn_position: Vector3) -> CharacterBody3D:
	var enemy := _create_character(parent, enemy_name, spawn_position, ENEMY_SCRIPT, 1.8, 0.45, Color("#d84c5c"))
	enemy.target = target
	enemy.add_to_group("enemies")
	return enemy

func create_ranged_enemy(parent: Node, enemy_name: String, target: CharacterBody3D, spawn_position: Vector3) -> CharacterBody3D:
	var enemy := _create_character(parent, enemy_name, spawn_position, RANGED_ENEMY_SCRIPT, 1.8, 0.4, Color("#a65de0"))
	enemy.target = target
	enemy.add_to_group("enemies")
	return enemy

func _create_character(parent: Node, character_name: String, spawn_position: Vector3, script: Script, height: float, radius: float, color: Color) -> CharacterBody3D:
	var character := CharacterBody3D.new()
	character.name = character_name
	character.position = spawn_position
	character.set_script(script)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = height
	capsule_mesh.radius = radius
	mesh_instance.mesh = capsule_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	capsule_mesh.material = material
	character.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = height
	capsule_shape.radius = radius
	collision.shape = capsule_shape
	character.add_child(collision)
	parent.add_child(character)
	return character
