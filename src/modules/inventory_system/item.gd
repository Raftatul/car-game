class_name Item
extends Node3D

enum USE_MODES {DURATION, CHARGES}
enum ATTACH_POINTS {HAND, BACK, HEAD}

signal picked_up
signal energy_changed(percent: float)

@export var texture: Texture2D
@export var attach_point: ATTACH_POINTS = ATTACH_POINTS.HAND

@export var is_two_handed: bool = false

@export var use_mode: USE_MODES = USE_MODES.DURATION
@export var energy: float = 1.0
@export var use_count: int = 1

var actor: Node

var pre_visible: bool = true

@onready var current_energy: float = energy :
	set(v):
		if v != current_energy:
			current_energy = clamp(v, 0.0, energy)
			if current_energy == 0.0:
				_energy_drained()
			energy_changed.emit(get_energy_percent())

@onready var offset: Marker3D = $Offset
@onready var remote_transform: ItemTrans = $RemoteTransform3D


func _ready() -> void:
	remote_transform.freed.connect(queue_free)
	remote_transform.visibility_changed.connect(_on_remote_visibility_changed)


func pick() -> void:
	picked_up.emit()


func pre_use() -> void:
	if can_be_used():
		_pre_use()


func use(delta: float) -> void:
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
	return !is_zero_approx(get_energy_percent())


func get_energy_percent() -> float:
	return current_energy / energy


func consume_energy(delta: float) -> void:
	_rpc_modify_energy.rpc(-delta)

## Rpc

@rpc("any_peer", "call_local", "reliable")
func _rpc_modify_energy(delta: float) -> void:
	current_energy += delta

## Virtuals

func _pre_use() -> void: pass

func _use(_delta: float) -> void: pass

func _post_use() -> void: pass

func _energy_drained() -> void: pass

func _can_consume_energy() -> bool: return true


## On signals

func _on_remote_visibility_changed() -> void:
	if !remote_transform.is_visible_in_tree():
		pre_visible = visible
		visible = false
	else:
		visible = pre_visible
