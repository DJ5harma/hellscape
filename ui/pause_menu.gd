extends CanvasLayer
class_name PauseMenu

signal restart_requested
signal sensitivity_changed(value: float)

var overlay: ColorRect
var panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	set_open(false)

func _build() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.04, 0.06, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	panel = PanelContainer.new()
	panel.position = Vector2(460, 180)
	panel.size = Vector2(360, 360)
	overlay.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var resume_button := Button.new()
	resume_button.text = "RESUME"
	resume_button.custom_minimum_size.y = 48
	resume_button.pressed.connect(func() -> void: set_open(false))
	content.add_child(resume_button)

	var sensitivity_label := Label.new()
	sensitivity_label.text = "Camera sensitivity"
	content.add_child(sensitivity_label)
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.001
	sensitivity.max_value = 0.008
	sensitivity.step = 0.0005
	sensitivity.value = 0.003
	sensitivity.value_changed.connect(sensitivity_changed.emit)
	content.add_child(sensitivity)

	var restart_button := Button.new()
	restart_button.text = "RESTART LEVEL"
	restart_button.custom_minimum_size.y = 48
	restart_button.pressed.connect(restart_requested.emit)
	content.add_child(restart_button)

func set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle() -> void:
	set_open(not visible)
