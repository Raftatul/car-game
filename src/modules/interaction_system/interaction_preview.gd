class_name InteractionPreview
extends Node3D

var tween: Tween

@onready var progress_bar: TextureProgressBar = $SubViewport/TextureProgressBar


func start_progress(duration: float) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(progress_bar, "value", 1.0, duration)


func stop_progress() -> void:
	if tween:
		tween.kill()
	progress_bar.value = 0.0
