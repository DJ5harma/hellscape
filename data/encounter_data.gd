extends Resource
class_name EncounterData

@export var display_name := "Encounter"
@export var objective := "DEFEAT ALL HOSTILES"
@export_enum("eliminate", "survive", "defend", "priority_target", "boss") var objective_type := "eliminate"
@export var arena_gate_name := ""
@export var side_route_available := false
@export var waves: Array[Resource] = []
@export var enemy_spawns: Array[Resource] = []
