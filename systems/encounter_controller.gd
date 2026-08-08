extends Node
class_name EncounterController

signal objective_changed(message: String, color: Color)
signal encounter_completed

var encounter_name := ""
var objective := ""
var remaining_enemies := 0
var active := false

func begin(name: String, objective_text: String) -> void:
	encounter_name = name
	objective = objective_text
	active = true
	_emit_objective()

func register_enemy() -> void:
	remaining_enemies += 1

func enemy_defeated() -> void:
	if not active or remaining_enemies <= 0:
		return
	remaining_enemies -= 1
	if remaining_enemies > 0:
		_emit_objective()
	else:
		active = false
		encounter_completed.emit()

func _emit_objective() -> void:
	objective_changed.emit(
		"%s  |  %s  |  %d REMAINING" % [encounter_name, objective, remaining_enemies],
		Color.WHITE
	)
