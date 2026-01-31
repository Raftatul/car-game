class_name HitBox
extends Area3D

@export var active: bool = true
@export var damage_delta: float = -10.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func force_update() -> void:
	var areas: Array[Area3D] = get_overlapping_areas().filter(_filter_areas)
	for area in areas:
		area.health_component.modify(damage_delta)


func _filter_areas(a: Area3D) -> bool:
	return a is HurtBox


func _on_area_entered(area: Area3D) -> void:
	if !active:
		return
	if area is HurtBox:
		area.health_component.modify(damage_delta)
