extends CharacterBody3D

const ATTACK_COMPONENT_SCRIPT := preload("res://components/attack_component.gd")

var target: CharacterBody3D
var attack_cooldown := 0.0
var visual: MeshInstance3D
var attack_component
var gravity := 22.0
var jump_velocity := 7.0

func _ready() -> void:
	visual = get_node_or_null("MeshInstance3D")
	attack_component = ATTACK_COMPONENT_SCRIPT.new()
	attack_component.name = "AttackComponent"
	add_child(attack_component)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	var follow_position := target.global_position + Vector3(-2.0, 0.0, 2.0)
	var offset := follow_position - global_position
	var horizontal_offset := Vector3(offset.x, 0.0, offset.z)
	if horizontal_offset.length() > 1.5:
		var horizontal_velocity := horizontal_offset.normalized() * 4.0
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if target.global_position.y > global_position.y + 0.35 and is_on_floor():
		velocity.y = jump_velocity
	elif not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.2
	var nearest_enemy: Node3D
	var nearest_distance := 2.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var distance := global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_enemy = enemy
				nearest_distance = distance
	if nearest_enemy and attack_cooldown == 0.0:
		attack_component.perform_area_attack(self, 1.8, 1, "ally")
		attack_cooldown = 1.2
		if is_instance_valid(visual):
			var tween := create_tween()
			tween.tween_property(visual, "scale", Vector3(1.25, 1.25, 1.25), 0.08)
			tween.tween_property(visual, "scale", Vector3.ONE, 0.12)
	move_and_slide()
