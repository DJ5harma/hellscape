extends CharacterBody3D

var target: CharacterBody3D
var health := 3
var attack_cooldown := 0.0
var attack_windup := 0.0
var attack_pending := false
var speed := 2.3
var visual: MeshInstance3D

func _ready() -> void:
	visual = get_node_or_null("MeshInstance3D")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	attack_windup = maxf(attack_windup - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	if target.is_attacking and offset.length() < target.attack_range and attack_cooldown == 0.0:
		take_damage(target.attack_damage)
		attack_cooldown = 0.35
		return
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
			if is_instance_valid(visual):
				visual.modulate = Color.WHITE
		elif attack_cooldown == 0.0:
			attack_windup = 0.25
			attack_pending = true
			attack_cooldown = 1.0
			if is_instance_valid(visual):
				visual.modulate = Color("#ffdf62")
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	get_parent().play_feedback(220.0, 0.08)
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color("#d84c5c"), 0.18)
	if health <= 0:
		get_parent().enemy_defeated()
		queue_free()
