extends Node
class_name AttackComponent

const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")

@export_flags_3d_physics var collision_mask := 1

func perform_area_attack(
	source: Node3D,
	radius: float,
	damage: int,
	damage_type := "generic",
	knockback := Vector3.ZERO,
	aim_direction := Vector3.ZERO,
	arc_degrees := 360.0
) -> int:
	if not is_instance_valid(source) or source.get_world_3d() == null:
		return 0
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, source.global_position)
	query.collision_mask = collision_mask
	query.exclude = [source.get_rid()]
	var results := source.get_world_3d().direct_space_state.intersect_shape(query, 32)
	var hit_count := 0
	for result in results:
		var target: Object = result.get("collider")
		if target is Node3D and arc_degrees < 360.0:
			var offset: Vector3 = (target as Node3D).global_position - source.global_position
			offset.y = 0.0
			var flat_aim := aim_direction
			flat_aim.y = 0.0
			if offset.length_squared() > 0.001 and flat_aim.length_squared() > 0.001:
				if flat_aim.normalized().dot(offset.normalized()) < cos(deg_to_rad(arc_degrees * 0.5)):
					continue
		if target and target.has_method("receive_damage"):
			var direction: Vector3 = (target.global_position - source.global_position).normalized()
			var info = DAMAGE_INFO_SCRIPT.new(damage, damage_type, source, direction * knockback.length())
			target.receive_damage(info)
			hit_count += 1
		elif target and target.has_method("take_damage"):
			target.take_damage(damage)
			hit_count += 1
	return hit_count
