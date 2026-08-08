extends "res://level/graybox_level.gd"
class_name LevelTwo

func build() -> void:
	colors["floor"] = Color("#303b48")
	colors["wall"] = Color("#46576b")
	colors["cover"] = Color("#3f8c82")
	colors["hazard"] = Color("#c84f78")
	colors["objective"] = Color("#62d5e8")
	super.build()
	_add_level_two_geometry()

func _add_level_two_geometry() -> void:
	add_box("LevelTwoBridgeA", Vector3(-5.0, 1.0, -20.0), Vector3(2.0, 2.0, 3.0), colors.cover)
	add_box("LevelTwoBridgeB", Vector3(5.0, 1.0, -31.0), Vector3(2.0, 2.0, 3.0), colors.cover)
	add_box("LevelTwoTerminal", Vector3(0.0, 1.0, -68.0), Vector3(3.0, 2.0, 1.5), colors.objective)
