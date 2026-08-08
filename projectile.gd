extends Node3D

const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")

var target: CharacterBody3D
var speed := 9.0
var lifetime := 4.0
var damage := 15
var damage_type := "projectile"
var source: Node
var knockback_strength := 2.0
var direction := Vector3.ZERO
var projectile_color := Color.WHITE
var direction_initialized := false

func configure_target_shot(
	new_target: CharacterBody3D,
	new_damage: int,
	new_source: Node,
	new_damage_type: String,
	new_speed: float,
	new_lifetime: float,
	new_knockback: float,
	new_color: Color
) -> void:
	target = new_target
	direction = (target.global_position + Vector3.UP * 0.8 - global_position).normalized()
	direction_initialized = true
	_configure_properties(new_damage, new_source, new_damage_type, new_speed, new_lifetime, new_knockback, new_color)

func configure_shot(
	new_direction: Vector3,
	new_damage: int,
	new_source: Node,
	new_damage_type: String,
	new_speed: float,
	new_lifetime: float,
	new_knockback: float,
	new_color: Color
) -> void:
	target = null
	direction = new_direction.normalized()
	direction_initialized = true
	_configure_properties(new_damage, new_source, new_damage_type, new_speed, new_lifetime, new_knockback, new_color)

func _configure_properties(
	new_damage: int,
	new_source: Node,
	new_damage_type: String,
	new_speed: float,
	new_lifetime: float,
	new_knockback: float,
	new_color: Color
) -> void:
	damage = new_damage
	source = new_source
	damage_type = new_damage_type
	speed = new_speed
	lifetime = new_lifetime
	knockback_strength = new_knockback
	projectile_color = new_color
	var visual := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if visual:
		var material := StandardMaterial3D.new()
		material.albedo_color = projectile_color
		material.emission_enabled = true
		material.emission = projectile_color
		material.emission_energy_multiplier = 2.0
		visual.material_override = material

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if not direction_initialized:
		if not is_instance_valid(target):
			queue_free()
			return
		direction = (target.global_position + Vector3.UP * 0.8 - global_position).normalized()
		direction_initialized = true
	global_position += direction * speed * delta
	look_at(global_position + direction, Vector3.UP)
	if _try_hit_target():
		queue_free()

func _try_hit_target() -> bool:
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = 1
	if is_instance_valid(source):
		query.exclude = [source.get_rid()]
	for result in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var hit: Object = result.get("collider")
		if hit and hit.has_method("receive_damage"):
			var impact_direction := direction
			hit.receive_damage(DAMAGE_INFO_SCRIPT.new(
				damage,
				damage_type,
				source if source else self,
				impact_direction * knockback_strength
			))
			if is_instance_valid(source) and source.has_method("notify_attack_hit"):
				source.notify_attack_hit(damage_type)
			return true
	return false
