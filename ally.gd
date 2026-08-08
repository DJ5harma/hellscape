extends CharacterBody3D

const ATTACK_COMPONENT_SCRIPT := preload("res://components/attack_component.gd")
const DAMAGEABLE_SCRIPT := preload("res://components/damageable.gd")
const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")
const WORLD_STATUS_BARS_SCRIPT := preload("res://components/world_status_bars.gd")

var target: CharacterBody3D
@export var ally_data: Resource
var attack_cooldown := 0.0
var visual: MeshInstance3D
var attack_component
var damageable
var health := 60
var gravity := 22.0
var jump_velocity := 7.0
var command_mode := "follow"
var focus_target: Node3D
var downed := false
var revive_timer := 0.0

func _ready() -> void:
	if ally_data:
		health = ally_data.max_health
	visual = get_node_or_null("MeshInstance3D")
	attack_component = ATTACK_COMPONENT_SCRIPT.new()
	attack_component.name = "AttackComponent"
	add_child(attack_component)
	damageable = DAMAGEABLE_SCRIPT.new()
	damageable.name = "Damageable"
	add_child(damageable)
	damageable.initialize(health)
	damageable.damaged.connect(_on_damaged)
	damageable.died.connect(_on_died)
	var status_bars = WORLD_STATUS_BARS_SCRIPT.new()
	status_bars.name = "WorldStatusBars"
	add_child(status_bars)
	status_bars.setup(self, health)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if downed:
		revive_timer -= delta
		if revive_timer <= 0.0:
			_revive()
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	var follow_distance: float = ally_data.follow_distance if ally_data else 2.0
	var move_speed: float = ally_data.move_speed if ally_data else 4.5
	var follow_position := target.global_position + target.transform.basis * Vector3(-follow_distance, 0.0, follow_distance)
	if command_mode == "hold":
		follow_position = global_position
	var offset := follow_position - global_position
	var horizontal_offset := Vector3(offset.x, 0.0, offset.z)
	if horizontal_offset.length() > 1.5:
		var horizontal_velocity := horizontal_offset.normalized() * move_speed
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
	var nearest_enemy := _choose_threat()
	var attack_range: float = ally_data.attack_range if ally_data else 2.8
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == nearest_enemy:
			var distance := global_position.distance_to(enemy.global_position)
			if distance <= attack_range and attack_cooldown == 0.0:
				var attack_damage: int = ally_data.attack_damage if ally_data else 2
				var knockback: float = ally_data.knockback if ally_data else 2.5
				attack_component.perform_area_attack(self, attack_range, attack_damage, "ally", -transform.basis.z * knockback, -transform.basis.z, 150.0)
				attack_cooldown = ally_data.attack_cooldown if ally_data else 0.9
				if is_instance_valid(visual):
					var tween := create_tween()
					tween.tween_property(visual, "scale", Vector3(1.25, 1.25, 1.25), 0.08)
					tween.tween_property(visual, "scale", Vector3.ONE, 0.12)
			break
	move_and_slide()

func _choose_threat() -> Node3D:
	if command_mode == "focus" and is_instance_valid(focus_target):
		return focus_target
	var best_enemy: Node3D
	var best_score := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var distance_to_player: float = enemy.global_position.distance_to(target.global_position)
		var distance_to_ally: float = enemy.global_position.distance_to(global_position)
		var score: float = distance_to_player + distance_to_ally * 0.35
		if score < best_score:
			best_score = score
			best_enemy = enemy
	return best_enemy

func set_command(mode: String, commanded_target: Node3D = null) -> void:
	if mode in ["follow", "hold", "focus"]:
		command_mode = mode
		focus_target = commanded_target

func receive_damage(info) -> void:
	if downed:
		return
	damageable.receive_damage(info, 0.12)

func _on_died() -> void:
	downed = true
	revive_timer = 6.0
	velocity = Vector3.ZERO
	if is_instance_valid(visual):
		_set_visual_color(Color("#6b7775"))

func _on_damaged(_info) -> void:
	health = damageable.health

func _revive() -> void:
	downed = false
	health = ally_data.max_health if ally_data else 60
	damageable.initialize(health)
	if is_instance_valid(visual):
		_set_visual_color(ally_data.visual_color if ally_data else Color("#4de0aa"))

func _set_visual_color(color: Color) -> void:
	if not is_instance_valid(visual):
		return
	var material := visual.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		visual.material_override = material
	material.albedo_color = color
