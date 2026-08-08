extends Node3D

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
		target.take_damage(15)
		queue_free()
