extends Node
class_name AimResolver

var camera: Camera3D
var fallback_direction := Vector3.FORWARD

func setup(source_camera: Camera3D) -> void:
	camera = source_camera

func get_direction(horizontal_only := false) -> Vector3:
	var direction := fallback_direction
	if is_instance_valid(camera):
		direction = -camera.global_transform.basis.z
	if horizontal_only:
		direction.y = 0.0
	if direction.length_squared() < 0.001:
		return fallback_direction
	return direction.normalized()

func get_point(distance: float) -> Vector3:
	if is_instance_valid(camera):
		return camera.global_position + get_direction() * distance
	return get_direction() * distance
