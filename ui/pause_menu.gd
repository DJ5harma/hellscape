extends CanvasLayer
class_name PauseMenu

signal restart_requested
signal sensitivity_changed(value: float)
signal volume_changed(value: float)

var overlay: ColorRect
var panel: PanelContainer
var sensitivity_slider: HSlider
var volume_slider: HSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_layout)
	_build()
	set_open(false)

func _build() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.04, 0.06, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	panel = PanelContainer.new()
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
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.001
	sensitivity_slider.max_value = 0.008
	sensitivity_slider.step = 0.0005
	sensitivity_slider.value = 0.003
	sensitivity_slider.value_changed.connect(sensitivity_changed.emit)
	content.add_child(sensitivity_slider)

	var volume_label := Label.new()
	volume_label.text = "Master volume"
	content.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = 1.0
	volume_slider.value_changed.connect(volume_changed.emit)
	content.add_child(volume_slider)

	var restart_button := Button.new()
	restart_button.text = "RESTART LEVEL"
	restart_button.custom_minimum_size.y = 48
	restart_button.pressed.connect(restart_requested.emit)
	content.add_child(restart_button)
	_layout()

func _layout() -> void:
	if not is_instance_valid(panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	panel.size.x = minf(360.0, maxf(viewport_size.x - 32.0, 260.0))
	panel.position = Vector2(
		(viewport_size.x - panel.size.x) * 0.5,
		maxf((viewport_size.y - panel.size.y) * 0.5, 16.0)
	)

func set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle() -> void:
	set_open(not visible)

func set_settings(sensitivity: float, volume: float) -> void:
	sensitivity_slider.value = sensitivity
	volume_slider.value = volume
