class_name HealthComponent
extends Node

signal health_changed(percent: float)

@export var max_health: float = 100.0 :
	set(v):
		if max_health != v:
			max_health = v
			health_changed.emit(get_percent())

@onready var current_health: float = max_health :
	set(v):
		if current_health != v:
			current_health = v
			health_changed.emit(get_percent())


func get_percent() -> float:
	return current_health / max_health


func has_amount(amount: float) -> bool:
	return current_health >= abs(amount)


func modify(delta: float) -> void:
	current_health += delta
