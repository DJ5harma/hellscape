extends Node
class_name Damageable

signal damaged(info)
signal died

var max_health := 1
var health := 1
var invulnerability_time := 0.0

func initialize(value: int) -> void:
	max_health = value
	health = value

func _physics_process(delta: float) -> void:
	invulnerability_time = maxf(invulnerability_time - delta, 0.0)

func receive_damage(info, invulnerability := 0.0) -> void:
	if info == null or invulnerability_time > 0.0 or health <= 0:
		return
	health = maxi(health - info.amount, 0)
	invulnerability_time = invulnerability
	damaged.emit(info)
	if health == 0:
		died.emit()
