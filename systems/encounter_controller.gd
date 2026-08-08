extends Node
class_name EncounterController

signal objective_changed(message: String, color: Color)
signal wave_started(number: int, total: int)
signal wave_cleared(number: int)
signal encounter_completed

var encounter_name := ""
var objective := ""
var objective_type := "eliminate"
var remaining_enemies := 0
var wave_index := 0
var waves: Array[Resource] = []
var actor_factory
var encounter_parent: Node
var target: CharacterBody3D
var active := false

func start(data: Resource, actor_factory: Node, parent: Node, target: CharacterBody3D) -> void:
	self.actor_factory = actor_factory
	encounter_parent = parent
	self.target = target
	waves = data.waves
	objective_type = data.objective_type
	if waves.is_empty():
		waves = [_create_legacy_wave(data.enemy_spawns)]
	wave_index = 0
	begin(data.display_name, data.objective)
	_spawn_current_wave()

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
	elif wave_index + 1 < waves.size():
		wave_cleared.emit(wave_index + 1)
		_advance_wave()
	else:
		active = false
		encounter_completed.emit()

func _spawn_current_wave() -> void:
	remaining_enemies = 0
	var wave: Resource = waves[wave_index]
	wave_started.emit(wave_index + 1, waves.size())
	for spawn in wave.enemy_spawns:
		var enemy_data: Resource = spawn.enemy_data
		if spawn.spawn_mode != "direct" and encounter_parent.level.has_method("show_spawn_portal"):
			encounter_parent.level.show_spawn_portal(spawn.spawn_position)
		if spawn.archetype == "boss":
			actor_factory.create_boss(encounter_parent, spawn.enemy_name, target, spawn.spawn_position, enemy_data)
		elif spawn.archetype == "ranged" or spawn.archetype == "sniper":
			actor_factory.create_ranged_enemy(encounter_parent, spawn.enemy_name, target, spawn.spawn_position, enemy_data)
		else:
			actor_factory.create_melee_enemy(encounter_parent, spawn.enemy_name, target, spawn.spawn_position, enemy_data)
		register_enemy()
	_emit_objective()

func _advance_wave() -> void:
	var previous_wave: Resource = waves[wave_index]
	var delay: float = previous_wave.inter_wave_delay
	if delay > 0.0:
		objective_changed.emit("WAVE CLEARED  |  PREPARE FOR THE NEXT WAVE", Color("#f5c76b"))
		await get_tree().create_timer(delay).timeout
	wave_index += 1
	_spawn_current_wave()

func _emit_objective() -> void:
	objective_changed.emit(
		"%s  |  %s  |  WAVE %d / %d  |  %d REMAINING" % [
			encounter_name, objective, wave_index + 1, waves.size(), remaining_enemies
		],
		Color.WHITE
	)

func _create_legacy_wave(spawns: Array[Resource]) -> Resource:
	var wave = preload("res://data/encounter_wave_data.gd").new()
	wave.display_name = "WAVE 1"
	wave.enemy_spawns = spawns
	return wave
