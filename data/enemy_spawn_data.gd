extends Resource
class_name EnemySpawnData

@export var enemy_name := "Enemy"
@export_enum("melee", "ranged", "bruiser", "sniper") var archetype := "melee"
@export var spawn_position := Vector3.ZERO
@export var enemy_data: Resource
