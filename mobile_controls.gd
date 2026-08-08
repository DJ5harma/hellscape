extends Control

signal movement_changed(value: Vector2)
signal look_changed(delta: Vector2)
signal attack_pressed
signal special_pressed
signal dodge_pressed
signal pause_pressed

var joystick_id := -1
var look_id := -1
var joystick_value := Vector2.ZERO
var joystick_center := Vector2.ZERO
var attack_center := Vector2.ZERO
var special_center := Vector2.ZERO
var dodge_center := Vector2.ZERO
var pause_center := Vector2.ZERO
var attack_label: Label
var special_label: Label
var dodge_label: Label
var pause_label: Label
var special_ready := true
var dodge_ready := true
var ui_scale := 1.0
var joystick_radius := JOYSTICK_RADIUS
var button_radius := ATTACK_RADIUS
const JOYSTICK_RADIUS := 86.0
const ATTACK_RADIUS := 64.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	attack_label = _create_button_label("ATTACK")
	special_label = _create_button_label("SPECIAL")
	dodge_label = _create_button_label("DODGE")
	pause_label = _create_button_label("II")
	get_viewport().size_changed.connect(_on_viewport_resized)
	_update_layout()
	_layout_labels()
	queue_redraw()

func _on_viewport_resized() -> void:
	_update_layout()
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
	attack_label.position = attack_center - Vector2(28.0, 10.0) * ui_scale
	special_label.position = special_center - Vector2(32.0, 10.0) * ui_scale
	dodge_label.position = dodge_center - Vector2(24.0, 10.0) * ui_scale
	pause_label.position = pause_center - Vector2(8.0, 10.0) * ui_scale
	for label in [attack_label, special_label, dodge_label, pause_label]:
		label.scale = Vector2.ONE * ui_scale

func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	ui_scale = clampf(minf(viewport_size.x / 1280.0, viewport_size.y / 720.0), 0.72, 1.0)
	joystick_radius = JOYSTICK_RADIUS * ui_scale
	button_radius = ATTACK_RADIUS * ui_scale
	var bottom_margin := 130.0 * ui_scale
	joystick_center = Vector2(130.0 * ui_scale, viewport_size.y - bottom_margin)
	attack_center = Vector2(viewport_size.x - 110.0 * ui_scale, viewport_size.y - 125.0 * ui_scale)
	special_center = Vector2(viewport_size.x - 235.0 * ui_scale, viewport_size.y - 115.0 * ui_scale)
	dodge_center = Vector2(viewport_size.x - 105.0 * ui_scale, viewport_size.y - 275.0 * ui_scale)
	var top_margin := 48.0 * ui_scale
	pause_center = Vector2(viewport_size.x - top_margin, top_margin)

func set_ability_state(is_special_ready: bool, is_dodge_ready: bool) -> void:
	special_ready = is_special_ready
	dodge_ready = is_dodge_ready
	if is_instance_valid(special_label):
		special_label.modulate = Color.WHITE if special_ready else Color(0.55, 0.55, 0.55)
	if is_instance_valid(dodge_label):
		dodge_label.modulate = Color.WHITE if dodge_ready else Color(0.55, 0.55, 0.55)
	queue_redraw()

func _input(event: InputEvent) -> void:
	_update_layout()
	var viewport_size := get_viewport_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(pause_center) <= 32.0 * ui_scale:
				pause_pressed.emit()
			elif event.position.distance_to(attack_center) <= button_radius:
				attack_pressed.emit()
			elif event.position.distance_to(special_center) <= button_radius:
				special_pressed.emit()
			elif event.position.distance_to(dodge_center) <= button_radius:
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
	joystick_value = offset.limit_length(joystick_radius) / joystick_radius
	movement_changed.emit(joystick_value)
	queue_redraw()

func _draw() -> void:
	_update_layout()
	_layout_labels()
	draw_circle(joystick_center, joystick_radius, Color(0.1, 0.15, 0.18, 0.45))
	draw_arc(joystick_center, joystick_radius, 0.0, TAU, 48, Color(0.5, 0.8, 1.0, 0.7), 3.0 * ui_scale)
	draw_circle(joystick_center + joystick_value * 48.0 * ui_scale, 48.0 * ui_scale, Color(0.35, 0.7, 1.0, 0.65))
	draw_circle(attack_center, button_radius, Color(0.85, 0.25, 0.3, 0.65))
	draw_arc(attack_center, button_radius, 0.0, TAU, 48, Color(1.0, 0.8, 0.7, 0.9), 3.0 * ui_scale)
	var special_color := Color(0.55, 0.3, 0.85, 0.65) if special_ready else Color(0.25, 0.2, 0.3, 0.5)
	draw_circle(special_center, button_radius, special_color)
	draw_arc(special_center, button_radius, 0.0, TAU, 48, Color(0.85, 0.75, 1.0, 0.9), 3.0 * ui_scale)
	var dodge_color := Color(0.85, 0.65, 0.25, 0.65) if dodge_ready else Color(0.3, 0.25, 0.15, 0.5)
	draw_circle(dodge_center, button_radius, dodge_color)
	draw_arc(dodge_center, button_radius, 0.0, TAU, 48, Color(1.0, 0.9, 0.6, 0.9), 3.0 * ui_scale)
	draw_circle(pause_center, 32.0 * ui_scale, Color(0.2, 0.25, 0.3, 0.75))
	draw_arc(pause_center, 32.0 * ui_scale, 0.0, TAU, 32, Color(0.75, 0.85, 0.95, 0.9), 2.0 * ui_scale)
