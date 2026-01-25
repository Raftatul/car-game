class_name Interactable
extends Area3D

const INTERACTION_PREVIEW = preload("uid://cmdgoj3a0fr5h")

signal interacted(node: Node)

@export var interaction_time: float = 1.0

var preview: InteractionPreview


func _ready() -> void:
	preview = INTERACTION_PREVIEW.instantiate()
	preview.visible = false
	add_child(preview)


func start_interacting() -> void:
	preview.start_progress(interaction_time)


func stop_interacting() -> void:
	preview.stop_progress()


func enable_preview() -> void:
	if !preview.visible:
		preview.visible = true


func disable_preview() -> void:
	preview.visible = false


func interact(node: Node) -> void:
	interacted.emit(node)


func get_can_be_interacted(_node: Node) -> bool:
	return true
