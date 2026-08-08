extends CharacterBody3D

const PROJECTILE_SCENE := preload("res://projectile.tscn")
const DAMAGEABLE_SCRIPT := preload("res://components/damageable.gd")
const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")
const WORLD_STATUS_BARS_SCRIPT := preload("res://components/world_status_bars.gd")

@export var enemy_data: Resource

var target: CharacterBody3D
var health := 4
var shot_cooldown := 0.8
var telegraph_timer := 0.0
var shot_pending := false
var visual: MeshInstance3D
var damageable
var hit_stun := 0.0
var health_label: Label3D
var telegraph_label: Label3D

func _ready() -> void:
	_apply_enemy_data()
	visual = get_node_or_null("MeshInstance3D")
	damageable = DAMAGEABLE_SCRIPT.new()
	damageable.name = "Damageable"
	add_child(damageable)
	damageable.initialize(health)
	damageable.damaged.connect(_on_damaged)
	damageable.died.connect(_on_died)
	health_label = Label3D.new()
	health_label.name = "HealthLabel"
	health_label.position = Vector3(0.0, 2.1, 0.0)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 32
	health_label.outline_size = 8
	health_label.modulate = Color("#e4b9ff")
	health_label.visible = false
	add_child(health_label)
	var status_bars = WORLD_STATUS_BARS_SCRIPT.new()
	status_bars.name = "WorldStatusBars"
	add_child(status_bars)
	status_bars.setup(self, health)
	telegraph_label = Label3D.new()
	telegraph_label.name = "TelegraphLabel"
	telegraph_label.position = Vector3(0.0, 2.7, 0.0)
	telegraph_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	telegraph_label.font_size = 28
	telegraph_label.outline_size = 8
	telegraph_label.modulate = Color("#ff344f")
	telegraph_label.text = "TARGETING"
	telegraph_label.visible = false
	add_child(telegraph_label)
	_update_health_label()

func _apply_enemy_data() -> void:
	if enemy_data == null:
		return
	health = enemy_data.max_health

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if hit_stun > 0.0:
		hit_stun -= delta
		move_and_slide()
		return
	shot_cooldown = maxf(shot_cooldown - delta, 0.0)
	telegraph_timer = maxf(telegraph_timer - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var preferred_min: float = enemy_data.preferred_min_range if enemy_data else 7.0
	var preferred_max: float = enemy_data.preferred_max_range if enemy_data else 13.0
	if offset.length() < preferred_min:
		velocity = -offset.normalized() * 2.4
	elif offset.length() > preferred_max:
		velocity = offset.normalized() * 2.4
	else:
		velocity = Vector3.ZERO
	if offset.length() < 20.0:
		look_at(global_position + Vector3(offset.x, 0.0, offset.z), Vector3.UP)
		if shot_pending and telegraph_timer == 0.0:
			shot_pending = false
			telegraph_label.visible = false
			_set_visual_color(Color("#ffdf62"))
			_shoot()
			shot_cooldown = enemy_data.shot_cooldown if enemy_data else 1.4
		elif not shot_pending and shot_cooldown == 0.0:
			shot_pending = true
			telegraph_timer = 0.45
			telegraph_label.visible = true
			_set_visual_color(Color("#ffdf62"))
	move_and_slide()

func _shoot() -> void:
	var projectile: Node3D = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 0.8
	var shot_speed: float = enemy_data.projectile_speed if enemy_data else 9.0
	var shot_lifetime: float = enemy_data.projectile_lifetime if enemy_data else 4.0
	var shot_damage: int = enemy_data.projectile_damage if enemy_data else 15
	projectile.configure_target_shot(target, shot_damage, self, "enemy_projectile", shot_speed, shot_lifetime, 2.0, Color("#ff9b4a"))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#ff9b4a")
	material.emission_enabled = true
	material.emission = Color("#ff522e")
	material.emission_energy_multiplier = 3.0
	var mesh := projectile.get_node("MeshInstance3D") as MeshInstance3D
	mesh.material_override = material
	if is_instance_valid(visual):
		var tween := create_tween()
		tween.tween_method(_set_visual_color, Color("#ffdf62"), Color("#a65de0"), 0.2)

func take_damage(amount: int) -> void:
	receive_damage(DAMAGE_INFO_SCRIPT.new(amount, "combat", null))

func receive_damage(info) -> void:
	damageable.receive_damage(info, 0.12)

func _on_damaged(info) -> void:
	health = damageable.health
	_update_health_label()
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

func _update_health_label() -> void:
	if is_instance_valid(health_label):
		health_label.text = "HP %d" % health

func _set_visual_color(color: Color) -> void:
	if not is_instance_valid(visual):
		return
	var material := visual.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		visual.material_override = material
	material.albedo_color = color
