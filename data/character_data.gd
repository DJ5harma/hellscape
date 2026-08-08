extends Resource
class_name CharacterData

@export_category("Identity")
@export var display_name := "Character"
@export var visual_color := Color.WHITE

@export_category("Movement")
@export var move_speed := 7.0
@export var acceleration := 24.0
@export var gravity := 22.0
@export var jump_velocity := 9.0
@export var dodge_speed := 13.0
@export var dodge_duration := 0.28
@export var dodge_cooldown := 1.0

@export_category("Survivability")
@export var max_health := 100
@export var dodge_invulnerability := 0.38
@export_range(0.0, 1.0) var knockback_resistance := 0.0

@export_category("Energy")
@export var max_energy := 100.0
@export var energy_regeneration := 10.0

@export_category("Abilities")
@export var mobile_actions: Array[String] = ["special", "heavy"]
@export var basic_action: Resource
@export var special_action: Resource
@export var heavy_action: Resource
@export var basic_damage := 1
@export var basic_range := 3.0
@export var special_cost := 35.0
@export var special_cooldown := 0.8
@export_enum("shockwave", "dash", "projectile", "guard") var special_style := "shockwave"
@export var special_damage := 2
@export var special_range := 5.0
@export var heavy_cost := 60.0
@export var heavy_cooldown := 1.4
@export var heavy_damage := 3
@export var heavy_range := 7.0
