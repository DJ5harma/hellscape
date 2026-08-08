extends Resource
class_name EnemySpawnData

@export var enemy_name := "Enemy"
@export_enum("melee", "ranged", "bruiser", "sniper", "boss") var archetype := "melee"
@export_enum("direct", "portal", "drop_in", "ambush") var spawn_mode := "direct"
@export var spawn_position := Vector3.ZERO
@export var enemy_data: Resource
