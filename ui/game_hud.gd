extends CanvasLayer
class_name GameHUD

var status_label: Label
var checkpoint_label: Label
var health_label: Label
var energy_label: Label
var ability_label: Label
var completion_label: Label

func build() -> void:
	status_label = _add_label(Vector2(28, 24), 24, Color.WHITE)
	status_label.text = "REACH EXTRACTION  |  WASD to move  |  Mouse to look"
	checkpoint_label = _add_label(Vector2(28, 58), 20, Color("#4d8dff"))
	checkpoint_label.text = "CHECKPOINT 0 / 4"
	var help_label := _add_label(Vector2(28, 92), 18, Color("#f5c76b"))
	help_label.text = "1 attack  |  2 special  |  3 heavy  |  SPACE jump  |  SHIFT dodge  |  TAB switch  |  R reset"
	health_label = _add_label(Vector2(28, 126), 18, Color("#ff7777"))
	energy_label = _add_label(Vector2(28, 152), 18, Color("#bd8cff"))
	ability_label = _add_label(Vector2(28, 178), 18, Color("#d6c4ff"))
	completion_label = _add_label(Vector2(420, 300), 38, Color("#47d7b0"))
	completion_label.text = "LEVEL COMPLETE\nPress R to replay"
	completion_label.visible = false

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
