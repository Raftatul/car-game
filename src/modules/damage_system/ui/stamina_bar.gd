extends ProgressBar

@export var stamina_component: StaminaComponent


func _ready() -> void:
	if stamina_component:
		stamina_component.stamina_changed.connect(_on_stamina_changed)


func _on_stamina_changed(percent: float) -> void:
	value = percent
