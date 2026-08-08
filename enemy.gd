extends CharacterBody3D

var target: CharacterBody3D
var health := 3
var attack_cooldown := 0.0
var speed := 2.3

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	if target.is_attacking and offset.length() < 3.0 and attack_cooldown == 0.0:
		take_damage(1)
		attack_cooldown = 0.35
		return
	if offset.length() > 1.7:
		velocity = offset.normalized() * speed
		look_at(global_position + Vector3(offset.x, 0.0, offset.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO
		if attack_cooldown == 0.0:
			target.take_damage(10)
			attack_cooldown = 1.0
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		get_parent().enemy_defeated()
		queue_free()
