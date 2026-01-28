class_name OxygenComponent
extends Node

signal oxygen_changed(percent: float)

@export var max_oxygen: float = 100.0 :
	set(v):
		if max_oxygen != v:
			max_oxygen = v
			oxygen_changed.emit(get_percent())

@export var regen_curve: Curve
@export var regen_amount: float = 1.0

@onready var current_oxygen: float = max_oxygen :
	set(v):
		if current_oxygen != v:
			current_oxygen = clamp(v, 0.0, max_oxygen)
			oxygen_changed.emit(get_percent())


func tick(delta: float) -> void:
	current_oxygen += regen_curve.sample(current_oxygen) * regen_amount * delta


func get_percent() -> float:
	return current_oxygen / max_oxygen


func has_amount(amount: float) -> bool:
	return current_oxygen >= abs(amount)


func modify(delta: float) -> void:
	current_oxygen += delta
