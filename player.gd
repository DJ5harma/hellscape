extends CharacterBody3D

@export var move_speed := 7.0
@export var acceleration := 24.0
@export var gravity := 22.0
@export var look_sensitivity := 0.003

var camera_pivot: Node3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.22
var health := 100
var respawn_position := Vector3.ZERO
var attack_timer := 0.0
var is_attacking := false
var mobile_move := Vector2.ZERO

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * look_sensitivity
		pitch = clamp(pitch - event.relative.y * look_sensitivity, -0.8, 0.35)
		rotation.y = yaw
		camera_pivot.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		attack_timer = 0.25
		is_attacking = true

func set_mobile_move(value: Vector2) -> void:
	mobile_move = value

func apply_mobile_look(delta: Vector2) -> void:
	yaw -= delta.x * look_sensitivity * 0.7
	pitch = clamp(pitch - delta.y * look_sensitivity * 0.7, -0.8, 0.35)
	rotation.y = yaw
	camera_pivot.rotation.x = pitch

func mobile_attack() -> void:
	attack_timer = 0.25
	is_attacking = true

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	else:
		is_attacking = false
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
	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.2
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		global_position = respawn_position
		velocity = Vector3.ZERO
		health = 100
