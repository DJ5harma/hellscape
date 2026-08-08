extends CharacterBody3D

const DAMAGEABLE_SCRIPT := preload("res://components/damageable.gd")
const DAMAGE_INFO_SCRIPT := preload("res://components/damage_info.gd")
const ATTACK_COMPONENT_SCRIPT := preload("res://components/attack_component.gd")

@export var look_sensitivity := 0.003
@export var character_data: Resource

var camera_pivot: Node3D
var camera: Camera3D
var visual: MeshInstance3D
var yaw := 0.0
var pitch := -0.22
var health := 100
var respawn_position := Vector3.ZERO
var attack_timer := 0.0
var is_attacking := false
var mobile_move := Vector2.ZERO
var energy := 100.0
var invulnerability_timer := 0.0
var dodge_timer := 0.0
var dodge_cooldown := 0.0
var special_cooldown := 0.0
var heavy_cooldown := 0.0
var jump_buffer_timer := 0.0
var jump_requested := false
var attack_damage := 1
var attack_range := 3.0
var damageable
var attack_component

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0.0, 1.65, 0.0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 1.0, 5.2)
	camera.look_at_from_position(camera.position, Vector3.ZERO)
	camera_pivot.add_child(camera)
	camera.current = true
	respawn_position = global_position
	visual = get_node_or_null("MeshInstance3D")
	if character_data == null:
		character_data = load("res://data/default_character.tres")
	set_character_data(character_data)
	damageable = DAMAGEABLE_SCRIPT.new()
	damageable.name = "Damageable"
	add_child(damageable)
	damageable.initialize(character_data.max_health)
	damageable.damaged.connect(_on_damaged)
	damageable.died.connect(_on_died)
	attack_component = ATTACK_COMPONENT_SCRIPT.new()
	attack_component.name = "AttackComponent"
	add_child(attack_component)

func set_character_data(new_data: Resource) -> void:
	character_data = new_data
	health = character_data.max_health
	energy = character_data.max_energy
	attack_damage = character_data.basic_damage
	attack_range = character_data.basic_range
	special_cooldown = 0.0
	heavy_cooldown = 0.0
	if is_instance_valid(visual):
		var material := StandardMaterial3D.new()
		material.albedo_color = character_data.visual_color
		visual.material_override = material
	if is_instance_valid(damageable):
		damageable.initialize(character_data.max_health)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * look_sensitivity
		pitch = clamp(pitch - event.relative.y * look_sensitivity, -0.8, 0.35)
		rotation.y = yaw
		camera_pivot.rotation.x = pitch
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_1:
		basic_attack()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_2:
		use_special()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_3:
		use_third_attack()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		request_jump()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SHIFT:
		dodge()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()

func set_mobile_move(value: Vector2) -> void:
	mobile_move = value

func apply_mobile_look(delta: Vector2) -> void:
	yaw -= delta.x * look_sensitivity * 0.7
	pitch = clamp(pitch - delta.y * look_sensitivity * 0.7, -0.8, 0.35)
	rotation.y = yaw
	camera_pivot.rotation.x = pitch

func mobile_attack() -> void:
	basic_attack()

func basic_attack() -> void:
	attack_timer = 0.25
	is_attacking = true
	attack_damage = character_data.basic_damage
	attack_range = character_data.basic_range
	attack_component.perform_area_attack(self, attack_range, attack_damage, "basic", Vector3(0.0, 0.0, 2.0))
	_play_action_animation(Color("#8ed8ff"), 1.2)

func use_special() -> void:
	if energy < character_data.special_cost or special_cooldown > 0.0:
		return
	energy -= character_data.special_cost
	special_cooldown = character_data.special_cooldown
	attack_damage = character_data.special_damage
	attack_range = character_data.special_range
	if character_data.special_style == "dash":
		velocity = -transform.basis.z * (character_data.dodge_speed + 4.0)
		dodge_timer = 0.22
		invulnerability_timer = 0.32
		attack_component.perform_area_attack(self, attack_range, character_data.special_damage, "dash", Vector3(0.0, 0.0, 4.0))
	else:
		attack_component.perform_area_attack(self, attack_range, character_data.special_damage, "shockwave", Vector3(0.0, 0.0, 4.0))
	_play_action_animation(Color("#cf9aff"), 1.35)

func use_third_attack() -> void:
	if energy < character_data.heavy_cost or heavy_cooldown > 0.0:
		return
	energy -= character_data.heavy_cost
	heavy_cooldown = character_data.heavy_cooldown
	attack_timer = 0.4
	is_attacking = true
	attack_damage = character_data.heavy_damage
	attack_range = character_data.heavy_range
	attack_component.perform_area_attack(self, attack_range, character_data.heavy_damage, "heavy", Vector3(0.0, 0.0, 8.0))
	_play_action_animation(Color("#ffd36b"), 1.5)

func request_jump() -> void:
	jump_requested = true

func jump() -> void:
	request_jump()

func dodge() -> void:
	if dodge_cooldown > 0.0 or dodge_timer > 0.0:
		return
	dodge_timer = character_data.dodge_duration
	dodge_cooldown = character_data.dodge_cooldown
	invulnerability_timer = character_data.dodge_invulnerability
	var dodge_direction := -transform.basis.z
	if mobile_move.length() > 0.05:
		dodge_direction = (transform.basis * Vector3(mobile_move.x, 0.0, mobile_move.y)).normalized()
	velocity = dodge_direction * character_data.dodge_speed
	_play_action_animation(Color("#fff0a1"), 0.8)

func _play_action_animation(action_color: Color, scale_amount: float) -> void:
	if not is_instance_valid(visual):
		return
	_set_visual_color(action_color)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector3(scale_amount, 2.0 - scale_amount * 0.4, scale_amount), 0.08)
	tween.tween_method(_set_visual_color, action_color, character_data.visual_color, 0.22)
	tween.chain().tween_property(visual, "scale", Vector3.ONE, 0.12)

func _set_visual_color(color: Color) -> void:
	var material := visual.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		visual.material_override = material
	material.albedo_color = color

func mobile_special() -> void:
	use_special()

func mobile_dodge() -> void:
	dodge()

func mobile_jump() -> void:
	request_jump()

func mobile_heavy() -> void:
	use_third_attack()

func is_special_ready() -> bool:
	return special_cooldown <= 0.0 and energy >= character_data.special_cost

func is_heavy_ready() -> bool:
	return heavy_cooldown <= 0.0 and energy >= character_data.heavy_cost

func is_dodge_ready() -> bool:
	return dodge_cooldown <= 0.0

func _physics_process(delta: float) -> void:
	invulnerability_timer = maxf(invulnerability_timer - delta, 0.0)
	dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
	special_cooldown = maxf(special_cooldown - delta, 0.0)
	heavy_cooldown = maxf(heavy_cooldown - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	energy = minf(energy + character_data.energy_regeneration * delta, character_data.max_energy)
	if attack_timer > 0.0:
		attack_timer -= delta
	else:
		is_attacking = false
	if jump_requested:
		jump_requested = false
		jump_buffer_timer = 0.15
	if dodge_timer > 0.0:
		dodge_timer -= delta
		move_and_slide()
		return
	var jumped_this_frame := false
	if jump_buffer_timer > 0.0 and is_on_floor():
		jump_buffer_timer = 0.0
		if dodge_timer <= 0.0:
			velocity.y = character_data.jump_velocity
			jumped_this_frame = true
	var input_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if mobile_move.length() > 0.05:
		input_2d = mobile_move
	var input_direction := Vector3(input_2d.x, 0.0, input_2d.y)
	if Input.is_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_direction.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_direction.z += 1.0
	input_direction = input_direction.normalized()
	var direction := (transform.basis * input_direction).normalized()
	var target_velocity: Vector3 = direction * float(character_data.move_speed)
	velocity.x = move_toward(velocity.x, target_velocity.x, character_data.acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, character_data.acceleration * delta)
	if jumped_this_frame or not is_on_floor():
		velocity.y -= character_data.gravity * delta
	else:
		velocity.y = -0.2
	move_and_slide()

func take_damage(amount: int) -> void:
	receive_damage(DAMAGE_INFO_SCRIPT.new(amount, "combat", null))

func receive_damage(info) -> void:
	damageable.receive_damage(info, invulnerability_timer)

func _on_damaged(info) -> void:
	health = damageable.health
	if info.knockback != Vector3.ZERO:
		velocity = info.knockback
	get_parent().play_feedback(110.0, 0.12)
	_play_action_animation(Color("#ff6464"), 0.85)

func _on_died() -> void:
	global_position = respawn_position
	velocity = Vector3.ZERO
	damageable.initialize(character_data.max_health)
	health = character_data.max_health
