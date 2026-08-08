extends Resource
class_name EnemyData

@export var display_name := "Enemy"
@export_enum("melee", "ranged", "bruiser", "sniper") var archetype := "melee"
@export var max_health := 3
@export var move_speed := 2.3
@export var attack_damage := 10
@export var attack_range := 1.7
@export var attack_windup := 0.25
@export var attack_cooldown := 1.0
@export var projectile_damage := 15
@export var projectile_speed := 9.0
@export var projectile_lifetime := 4.0
@export var shot_cooldown := 2.0
@export var preferred_min_range := 7.0
@export var preferred_max_range := 13.0
@export_range(0.0, 360.0) var shield_arc_degrees := 100.0
@export_range(0.0, 1.0) var damage_resistance := 0.0
@export var visual_color := Color.WHITE
