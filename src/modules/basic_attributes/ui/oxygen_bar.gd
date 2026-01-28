extends ProgressBar

@export var oxygen_component: OxygenComponent


func _ready() -> void:
	if oxygen_component:
		oxygen_component.oxygen_changed.connect(_on_oxygen_changed)


func _on_oxygen_changed(percent: float) -> void:
	value = percent
