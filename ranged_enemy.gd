extends CharacterBody3D

const PROJECTILE_SCENE := preload("res://projectile.tscn")
const DAMAGEABLE_SCRIPT := preload("res://components/damageable.gd")
const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")

var target: CharacterBody3D
var health := 4
var shot_cooldown := 1.0
var visual: MeshInstance3D
var damageable
var hit_stun := 0.0

func _ready() -> void:
	visual = get_node_or_null("MeshInstance3D")
	damageable = DAMAGEABLE_SCRIPT.new()
	damageable.name = "Damageable"
	add_child(damageable)
	damageable.initialize(health)
	damageable.damaged.connect(_on_damaged)
	damageable.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if hit_stun > 0.0:
		hit_stun -= delta
		move_and_slide()
		return
	shot_cooldown = maxf(shot_cooldown - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() < 7.0:
		velocity = -offset.normalized() * 1.8
	elif offset.length() > 13.0:
		velocity = offset.normalized() * 1.8
	else:
		velocity = Vector3.ZERO
	if offset.length() < 20.0:
		look_at(global_position + Vector3(offset.x, 0.0, offset.z), Vector3.UP)
		if shot_cooldown == 0.0:
			_set_visual_color(Color("#ffdf62"))
			_shoot()
			shot_cooldown = 2.0
	move_and_slide()

func _shoot() -> void:
	var projectile: Node3D = PROJECTILE_SCENE.instantiate()
	projectile.target = target
	projectile.position = global_position + Vector3.UP * 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#ff9b4a")
	material.emission_enabled = true
	material.emission = Color("#ff522e")
	material.emission_energy_multiplier = 3.0
	var mesh := projectile.get_node("MeshInstance3D") as MeshInstance3D
	mesh.material_override = material
	get_parent().add_child(projectile)
	if is_instance_valid(visual):
		var tween := create_tween()
		tween.tween_method(_set_visual_color, Color("#ffdf62"), Color("#a65de0"), 0.2)

func take_damage(amount: int) -> void:
	receive_damage(DAMAGE_INFO_SCRIPT.new(amount, "combat", null))

func receive_damage(info) -> void:
	damageable.receive_damage(info, 0.12)

func _on_damaged(info) -> void:
	health = damageable.health
	if info.knockback != Vector3.ZERO:
		velocity = info.knockback
		hit_stun = 0.18
	get_parent().play_feedback(420.0, 0.08)
	if is_instance_valid(visual):
		_set_visual_color(Color.WHITE)
		var tween := create_tween()
		tween.tween_method(_set_visual_color, Color.WHITE, Color("#a65de0"), 0.18)

func _on_died() -> void:
	get_parent().enemy_defeated()
	queue_free()

func _set_visual_color(color: Color) -> void:
	if not is_instance_valid(visual):
		return
	var material := visual.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		visual.material_override = material
	material.albedo_color = color
