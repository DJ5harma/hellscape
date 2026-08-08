extends Control

signal movement_changed(value: Vector2)
signal look_changed(delta: Vector2)
signal attack_pressed
signal special_pressed
signal dodge_pressed

var joystick_id := -1
var look_id := -1
var joystick_value := Vector2.ZERO
var joystick_center := Vector2.ZERO
var attack_center := Vector2.ZERO
var special_center := Vector2.ZERO
var dodge_center := Vector2.ZERO
var attack_label: Label
var special_label: Label
var dodge_label: Label
const JOYSTICK_RADIUS := 86.0
const ATTACK_RADIUS := 64.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	attack_label = _create_button_label("ATTACK")
	special_label = _create_button_label("SPECIAL")
	dodge_label = _create_button_label("DODGE")
	_layout_labels()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()

func _create_button_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	return label

func _layout_labels() -> void:
	if not is_instance_valid(attack_label):
		return
	attack_label.position = attack_center - Vector2(28.0, 10.0)
	special_label.position = special_center - Vector2(32.0, 10.0)
	dodge_label.position = dodge_center - Vector2(24.0, 10.0)

func _input(event: InputEvent) -> void:
	var viewport_size := get_viewport_rect().size
	joystick_center = Vector2(130.0, viewport_size.y - 130.0)
	attack_center = Vector2(viewport_size.x - 110.0, viewport_size.y - 125.0)
	special_center = Vector2(viewport_size.x - 235.0, viewport_size.y - 115.0)
	dodge_center = Vector2(viewport_size.x - 105.0, viewport_size.y - 275.0)
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(attack_center) <= ATTACK_RADIUS:
				attack_pressed.emit()
			elif event.position.distance_to(special_center) <= ATTACK_RADIUS:
				special_pressed.emit()
			elif event.position.distance_to(dodge_center) <= ATTACK_RADIUS:
				dodge_pressed.emit()
			elif event.position.x < viewport_size.x * 0.5 and event.position.y > viewport_size.y * 0.45:
				joystick_id = event.index
				_update_joystick(event.position)
			elif event.position.x >= viewport_size.x * 0.5:
				look_id = event.index
		else:
			if event.index == joystick_id:
				joystick_id = -1
				joystick_value = Vector2.ZERO
				movement_changed.emit(Vector2.ZERO)
			elif event.index == look_id:
				look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == joystick_id:
			_update_joystick(event.position)
		elif event.index == look_id:
			look_changed.emit(event.relative)

func _update_joystick(position: Vector2) -> void:
	var offset := position - joystick_center
	joystick_value = offset.limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
	movement_changed.emit(joystick_value)
	queue_redraw()

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	joystick_center = Vector2(130.0, viewport_size.y - 130.0)
	attack_center = Vector2(viewport_size.x - 110.0, viewport_size.y - 125.0)
	special_center = Vector2(viewport_size.x - 235.0, viewport_size.y - 115.0)
	dodge_center = Vector2(viewport_size.x - 105.0, viewport_size.y - 275.0)
	_layout_labels()
	draw_circle(joystick_center, JOYSTICK_RADIUS, Color(0.1, 0.15, 0.18, 0.45))
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 48, Color(0.5, 0.8, 1.0, 0.7), 3.0)
	draw_circle(joystick_center + joystick_value * 48.0, 48.0, Color(0.35, 0.7, 1.0, 0.65))
	draw_circle(attack_center, ATTACK_RADIUS, Color(0.85, 0.25, 0.3, 0.65))
	draw_arc(attack_center, ATTACK_RADIUS, 0.0, TAU, 48, Color(1.0, 0.8, 0.7, 0.9), 3.0)
	draw_circle(special_center, ATTACK_RADIUS, Color(0.55, 0.3, 0.85, 0.65))
	draw_arc(special_center, ATTACK_RADIUS, 0.0, TAU, 48, Color(0.85, 0.75, 1.0, 0.9), 3.0)
	draw_circle(dodge_center, ATTACK_RADIUS, Color(0.85, 0.65, 0.25, 0.65))
	draw_arc(dodge_center, ATTACK_RADIUS, 0.0, TAU, 48, Color(1.0, 0.9, 0.6, 0.9), 3.0)
