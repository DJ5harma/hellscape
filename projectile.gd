extends Node3D

const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")

var target: CharacterBody3D
var speed := 9.0
var lifetime := 4.0

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(target):
		queue_free()
		return
	var direction := (target.global_position + Vector3.UP * 0.8 - global_position).normalized()
	global_position += direction * speed * delta
	look_at(global_position + direction, Vector3.UP)
	if global_position.distance_to(target.global_position + Vector3.UP * 0.8) < 0.8:
		if target.has_method("receive_damage"):
			var impact_direction: Vector3 = (target.global_position - global_position).normalized()
			target.receive_damage(DAMAGE_INFO_SCRIPT.new(15, "projectile", self, impact_direction * 2.0))
		else:
			target.take_damage(15)
		queue_free()
