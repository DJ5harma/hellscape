extends CharacterBody3D

const DAMAGEABLE_SCRIPT := preload("res://components/damageable.gd")
const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")

var target: CharacterBody3D
var health := 3
var attack_cooldown := 0.0
var attack_windup := 0.0
var attack_pending := false
var speed := 2.3
var visual: MeshInstance3D
var damageable
var hit_stun := 0.0
var health_label: Label3D

func _ready() -> void:
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
	_update_health_label()

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
	if offset.length() > 1.7:
		velocity = offset.normalized() * speed
		look_at(global_position + Vector3(offset.x, 0.0, offset.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO
		if attack_windup > 0.0:
			move_and_slide()
			return
		if attack_pending:
			attack_pending = false
			target.take_damage(10)
			_set_visual_color(Color("#d84c5c"))
		elif attack_cooldown == 0.0:
			attack_windup = 0.25
			attack_pending = true
			attack_cooldown = 1.0
			_set_visual_color(Color("#ffdf62"))
	move_and_slide()

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
