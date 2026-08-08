extends Resource
class_name ActionData

@export var action_id := "action"
@export var display_name := "Action"
@export_enum("melee", "shockwave", "dash", "projectile", "guard") var style := "melee"
@export var damage := 1
@export var range := 3.0
@export_range(0.0, 360.0) var arc_degrees := 360.0
@export var energy_cost := 0.0
@export var cooldown := 0.0
@export var knockback := 2.0
@export var projectile_speed := 18.0
@export var projectile_lifetime := 2.5
@export var projectile_color := Color.WHITE
