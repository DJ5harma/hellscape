extends Node
class_name EncounterController

signal objective_changed(message: String, color: Color)
signal encounter_completed

var encounter_name := ""
var objective := ""
var remaining_enemies := 0
var active := false

func start(data: Resource, actor_factory: Node, parent: Node, target: CharacterBody3D) -> void:
	remaining_enemies = 0
	for spawn in data.enemy_spawns:
		var enemy_data: Resource = spawn.enemy_data
		if spawn.archetype == "ranged" or spawn.archetype == "sniper":
			actor_factory.create_ranged_enemy(parent, spawn.enemy_name, target, spawn.spawn_position, enemy_data)
		else:
			actor_factory.create_melee_enemy(parent, spawn.enemy_name, target, spawn.spawn_position, enemy_data)
		register_enemy()
	begin(data.display_name, data.objective)

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
