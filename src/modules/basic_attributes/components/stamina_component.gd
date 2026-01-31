class_name StaminaComponent
extends Node

signal stamina_changed(percent: float)

@export var max_stamina: float = 100.0 :
	set(v):
		if max_stamina != v:
			max_stamina = v
			stamina_changed.emit(get_percent())

@export var regen_curve: Curve
@export var regen_amount: float = 1.0
@export var regen_delay: float = 1.0

@onready var current_stamina: float = max_stamina :
	set(v):
		if current_stamina != v:
			current_stamina = clamp(v, 0.0, max_stamina)
			stamina_changed.emit(get_percent())


@onready var timer: Timer = Timer.new()


func _ready() -> void:
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = regen_delay


func tick(delta: float) -> void:
	if timer.time_left == 0.0:
		current_stamina += regen_curve.sample(current_stamina) * regen_amount * delta


func get_percent() -> float:
	return current_stamina / max_stamina


func has_amount(amount: float) -> bool:
	return current_stamina >= abs(amount)


func modify(delta: float) -> void:
	if is_multiplayer_authority():
		timer.start()
		current_stamina += delta
