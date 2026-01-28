class_name Item
extends Node3D

enum ATTACH_POINTS {HAND, BACK, HEAD}

signal picked_up
signal lifetime_changed(percent: float)

@export var texture: Texture2D
@export var attach_point: ATTACH_POINTS = ATTACH_POINTS.HAND

@export var lifetime: float = 0.0

var actor: Node

@onready var current_lifetime: float = lifetime :
	set(v):
		if v != current_lifetime:
			current_lifetime = clamp(v, 0.0, lifetime)
			if current_lifetime == 0.0:
				_lifetime_drained()
			lifetime_changed.emit(get_lifetime_percent())

@onready var offset: Marker3D = $Offset


func pick() -> void:
	picked_up.emit()


func pre_use() -> void:
	if can_be_used():
		_pre_use()


func use(delta: float) -> void:
	if _can_consume_lifetime():
		current_lifetime -= delta
		if can_be_used():
			_use(delta)


func post_use() -> void:
	if can_be_used():
		_post_use()


func dropped() -> void: pass

func selected() -> void: pass

func unselected() -> void: pass

func sold() -> void: pass


func can_be_used() -> bool:
	return get_lifetime_percent() > 0.0


func get_lifetime_percent() -> float:
	return current_lifetime / lifetime


## Virtuals

func _pre_use() -> void: pass

func _use(_delta: float) -> void: pass

func _post_use() -> void: pass

func _lifetime_drained() -> void: pass

func _can_consume_lifetime() -> bool: return true
