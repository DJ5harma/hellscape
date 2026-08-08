extends CharacterBody3D

const DAMAGEABLE_SCRIPT := preload("res://components/damageable.gd")
const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")

@export var enemy_data: Resource

var target: CharacterBody3D
var health := 3
var attack_cooldown := 0.0
var attack_windup := 0.0
var attack_pending := false
var speed := 3.2
var visual: MeshInstance3D
var damageable
var hit_stun := 0.0
var health_label: Label3D
var shield_label: Label3D

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
	health_label.modulate = Color("#ffb3b3")
	add_child(health_label)
	if enemy_data and enemy_data.archetype == "bruiser":
		shield_label = Label3D.new()
		shield_label.name = "ShieldLabel"
		shield_label.position = Vector3(0.0, 2.7, 0.0)
		shield_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		shield_label.font_size = 24
		shield_label.outline_size = 8
		shield_label.modulate = Color("#ffd36b")
		shield_label.text = "SHIELD FRONT"
		add_child(shield_label)
	_update_health_label()

func _apply_enemy_data() -> void:
	if enemy_data == null:
		return
	health = enemy_data.max_health
	speed = enemy_data.move_speed

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if hit_stun > 0.0:
		hit_stun -= delta
		move_and_slide()
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	attack_windup = maxf(attack_windup - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > _attack_range():
		velocity = offset.normalized() * speed
		look_at(global_position + Vector3(offset.x, 0.0, offset.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO
		if attack_windup > 0.0:
			move_and_slide()
			return
		if attack_pending:
			attack_pending = false
			target.take_damage(_attack_damage())
			_set_visual_color(Color("#d84c5c"))
		elif attack_cooldown == 0.0:
			attack_windup = _attack_windup()
			attack_pending = true
			attack_cooldown = _attack_cooldown()
			_set_visual_color(Color("#ffdf62"))
	move_and_slide()

func take_damage(amount: int) -> void:
	receive_damage(DAMAGE_INFO_SCRIPT.new(amount, "combat", null))

func receive_damage(info) -> void:
	var adjusted_info = info
	if _is_shielded_from(info):
		adjusted_info = DAMAGE_INFO_SCRIPT.new(
			maxi(1, roundi(info.amount * (1.0 - enemy_data.damage_resistance))),
			info.damage_type,
			info.source,
			info.knockback * 0.25
		)
	damageable.receive_damage(adjusted_info, 0.12)

func _is_shielded_from(info) -> bool:
	if enemy_data == null or enemy_data.archetype != "bruiser" or not is_instance_valid(info.source):
		return false
	if not info.source is Node3D:
		return false
	var to_source := (info.source as Node3D).global_position - global_position
	to_source.y = 0.0
	var forward := -global_transform.basis.z
	forward.y = 0.0
	return forward.normalized().dot(to_source.normalized()) >= cos(deg_to_rad(enemy_data.shield_arc_degrees * 0.5))

func _attack_range() -> float:
	return enemy_data.attack_range if enemy_data else 1.7

func _attack_damage() -> int:
	return enemy_data.attack_damage if enemy_data else 12

func _attack_windup() -> float:
	return enemy_data.attack_windup if enemy_data else 0.25

func _attack_cooldown() -> float:
	return enemy_data.attack_cooldown if enemy_data else 0.75

func _on_damaged(info) -> void:
	health = damageable.health
	_update_health_label()
	if info.knockback != Vector3.ZERO:
		velocity = info.knockback
		hit_stun = 0.18
	get_parent().play_feedback(220.0, 0.08)
	if is_instance_valid(visual):
		_set_visual_color(Color.WHITE)
		var tween := create_tween()
		tween.tween_method(_set_visual_color, Color.WHITE, Color("#d84c5c"), 0.18)

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
