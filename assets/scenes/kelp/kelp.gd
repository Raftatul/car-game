@tool
extends Path3D

@export var spacing: float = 1.0


func _on_curve_changed() -> void:
	if !Engine.is_editor_hint():
		return
	
	var point_count: int = floor(curve.get_baked_length() / spacing)
	for i in range(point_count):
		print(i)
