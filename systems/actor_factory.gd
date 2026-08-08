extends Node
class_name ActorFactory

const PLAYER_SCENE := preload("res://player.tscn")
const ALLY_SCENE := preload("res://ally.tscn")
const MELEE_ENEMY_SCENE := preload("res://melee_enemy.tscn")
const RANGED_ENEMY_SCENE := preload("res://ranged_enemy.tscn")

func create_player(parent: Node, spawn_position: Vector3) -> CharacterBody3D:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = spawn_position
	_set_visual_color(player, Color("#55b7ff"))
	parent.add_child(player)
	return player

func create_ally(parent: Node, target: CharacterBody3D, spawn_position: Vector3) -> CharacterBody3D:
	var ally: CharacterBody3D = ALLY_SCENE.instantiate()
	ally.name = "Companion"
	ally.position = spawn_position
	ally.target = target
	_set_visual_color(ally, Color("#4de0aa"))
	parent.add_child(ally)
	return ally

func create_melee_enemy(parent: Node, enemy_name: String, target: CharacterBody3D, spawn_position: Vector3) -> CharacterBody3D:
	var enemy: CharacterBody3D = MELEE_ENEMY_SCENE.instantiate()
	enemy.name = enemy_name
	enemy.position = spawn_position
	enemy.target = target
	enemy.add_to_group("enemies")
	_set_visual_color(enemy, Color("#d84c5c"))
	parent.add_child(enemy)
	return enemy

func create_ranged_enemy(parent: Node, enemy_name: String, target: CharacterBody3D, spawn_position: Vector3) -> CharacterBody3D:
	var enemy: CharacterBody3D = RANGED_ENEMY_SCENE.instantiate()
	enemy.name = enemy_name
	enemy.position = spawn_position
	enemy.target = target
	enemy.add_to_group("enemies")
	_set_visual_color(enemy, Color("#a65de0"))
	parent.add_child(enemy)
	return enemy

func _set_visual_color(character: CharacterBody3D, color: Color) -> void:
	var mesh_instance := character.get_node("MeshInstance3D") as MeshInstance3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
