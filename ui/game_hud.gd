extends CanvasLayer
class_name GameHUD

var status_label: Label
var checkpoint_label: Label
var help_label: Label
var health_label: Label
var energy_label: Label
var ability_label: Label
var completion_label: Label

func build() -> void:
	get_viewport().size_changed.connect(_layout)
	status_label = _add_label(Vector2(28, 24), 24, Color.WHITE)
	status_label.text = "REACH EXTRACTION  |  WASD to move  |  Mouse to look"
	checkpoint_label = _add_label(Vector2(28, 58), 20, Color("#4d8dff"))
	checkpoint_label.text = "CHECKPOINT 0 / 4"
	help_label = _add_label(Vector2(28, 92), 18, Color("#f5c76b"))
	help_label.text = "1 attack  |  2 special  |  3 heavy  |  SPACE jump  |  SHIFT dodge  |  TAB switch  |  R reset"
	health_label = _add_label(Vector2(28, 126), 18, Color("#ff7777"))
	energy_label = _add_label(Vector2(28, 152), 18, Color("#bd8cff"))
	ability_label = _add_label(Vector2(28, 178), 18, Color("#d6c4ff"))
	completion_label = _add_label(Vector2(420, 300), 38, Color("#47d7b0"))
	completion_label.text = "LEVEL COMPLETE\nPress R to replay"
	completion_label.visible = false
	_layout()

func _layout() -> void:
	if not is_instance_valid(status_label):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var margin := clampf(viewport_size.x * 0.025, 18.0, 32.0)
	var scale := clampf(minf(viewport_size.x / 1280.0, viewport_size.y / 720.0), 0.72, 1.0)
	var line_height := 28.0 * scale
	var labels := [status_label, checkpoint_label, help_label, health_label, energy_label, ability_label]
	for index in labels.size():
		var label := labels[index] as Label
		label.position = Vector2(margin, 18.0 + index * line_height)
		label.scale = Vector2.ONE * scale
		label.size = Vector2(maxf(viewport_size.x - margin * 2.0, 180.0), line_height + 8.0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	completion_label.scale = Vector2.ONE * scale
	completion_label.size = Vector2(440.0, 110.0)
	completion_label.position = Vector2(
		maxf((viewport_size.x - completion_label.size.x * scale) * 0.5, margin),
		maxf((viewport_size.y - completion_label.size.y * scale) * 0.5, 120.0)
	)

func update_player(player: Node) -> void:
	if is_instance_valid(player):
		health_label.text = "HEALTH %d" % player.health
		energy_label.text = "ENERGY %d / 100" % roundi(player.energy)
		var special_state := "READY" if player.is_special_ready() else "WAIT"
		var heavy_state := "READY" if player.is_heavy_ready() else "WAIT"
		ability_label.text = "SPECIAL [2] %s  |  HEAVY [3] %s" % [special_state, heavy_state]

func set_status(message: String, color := Color.WHITE) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)

func set_checkpoint(number: int) -> void:
	checkpoint_label.text = "CHECKPOINT %d / 4" % number

func show_completion() -> void:
	completion_label.visible = true

func _add_label(position: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
