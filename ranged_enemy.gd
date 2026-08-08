extends CharacterBody3D

const PROJECTILE_SCRIPT := preload("res://projectile.gd")

var target: CharacterBody3D
var health := 4
var shot_cooldown := 1.0
var hit_cooldown := 0.0
var visual: MeshInstance3D

func _ready() -> void:
	visual = get_node_or_null("MeshInstance3D")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	shot_cooldown = maxf(shot_cooldown - delta, 0.0)
	hit_cooldown = maxf(hit_cooldown - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	if target.is_attacking and offset.length() < 3.0 and hit_cooldown == 0.0:
		take_damage(1)
		hit_cooldown = 0.35
		return
	if offset.length() < 7.0:
		velocity = -offset.normalized() * 1.8
	elif offset.length() > 13.0:
		velocity = offset.normalized() * 1.8
	else:
		velocity = Vector3.ZERO
	if offset.length() < 20.0:
		look_at(global_position + Vector3(offset.x, 0.0, offset.z), Vector3.UP)
		if shot_cooldown == 0.0:
			if is_instance_valid(visual):
				visual.modulate = Color("#ffdf62")
			_shoot()
			shot_cooldown = 2.0
	move_and_slide()

func _shoot() -> void:
	var projectile := Node3D.new()
	projectile.name = "EnemyProjectile"
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.target = target
	projectile.position = global_position + Vector3.UP * 0.8
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#ff9b4a")
	material.emission_enabled = true
	material.emission = Color("#ff522e")
	material.emission_energy_multiplier = 3.0
	sphere.material = material
	projectile.add_child(mesh)
	get_parent().add_child(projectile)
	if is_instance_valid(visual):
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color("#a65de0"), 0.2)

func take_damage(amount: int) -> void:
	health -= amount
	get_parent().play_feedback(420.0, 0.08)
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color("#a65de0"), 0.18)
	if health <= 0:
		get_parent().enemy_defeated()
		queue_free()
