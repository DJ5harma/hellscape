extends CharacterBody3D

const DAMAGEABLE_SCRIPT := preload("res://components/damageable.gd")
const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")

@export var boss_data: Resource
var target: CharacterBody3D
var damageable
var health := 250
var phase_index := 0
var attack_cooldown := 0.0
var telegraph_timer := 0.0
var attack_pending := false
var telegraph_label: Label3D

func _ready() -> void:
	if boss_data:
		health = boss_data.max_health
	damageable = DAMAGEABLE_SCRIPT.new()
	damageable.name = "Damageable"
	add_child(damageable)
	damageable.initialize(health)
	damageable.damaged.connect(_on_damaged)
	damageable.died.connect(_on_died)
	telegraph_label = Label3D.new()
	telegraph_label.position = Vector3(0.0, 3.0, 0.0)
	telegraph_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	telegraph_label.font_size = 30
	telegraph_label.outline_size = 8
	telegraph_label.visible = false
	add_child(telegraph_label)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or boss_data == null or boss_data.phases.is_empty():
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	telegraph_timer = maxf(telegraph_timer - delta, 0.0)
	var phase: Resource = boss_data.phases[phase_index]
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > phase.attack_range:
		velocity = offset.normalized() * phase.move_speed
		look_at(global_position + offset, Vector3.UP)
	else:
		velocity = Vector3.ZERO
		if attack_cooldown == 0.0 and telegraph_timer == 0.0 and not attack_pending:
			attack_pending = true
			telegraph_timer = 0.45
			telegraph_label.text = phase.telegraph_text
			telegraph_label.visible = true
		elif attack_pending and telegraph_timer == 0.0:
			attack_pending = false
			telegraph_label.visible = false
			target.take_damage(phase.attack_damage)
			attack_cooldown = phase.attack_cooldown
	move_and_slide()

func receive_damage(info) -> void:
	damageable.receive_damage(info, 0.12)

func _on_damaged(_info) -> void:
	health = damageable.health
	if phase_index + 1 < boss_data.phases.size():
		var next_phase: Resource = boss_data.phases[phase_index + 1]
		if float(health) / float(boss_data.max_health) <= next_phase.health_threshold:
			phase_index += 1

func _on_died() -> void:
	if get_parent().has_method("enemy_defeated"):
		get_parent().enemy_defeated()
	queue_free()
