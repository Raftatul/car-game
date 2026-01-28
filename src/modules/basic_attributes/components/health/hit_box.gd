class_name HitBox
extends Area3D

@export var damage_delta: float = -10.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	if area is HurtBox:
		area.health_component.modify(damage_delta)
