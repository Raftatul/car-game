extends ProgressBar

@export var health_component: HealthComponent


func _ready() -> void:
	if health_component:
		health_component.health_changed.connect(_on_health_changed)


func _on_health_changed(percent: float) -> void:
	value = percent
