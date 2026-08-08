extends RefCounted
class_name DamageInfo

var amount: int
var damage_type: String
var source: Node
var knockback: Vector3

func _init(value: int, type := "generic", attacker: Node = null, force := Vector3.ZERO) -> void:
	amount = value
	damage_type = type
	source = attacker
	knockback = force
