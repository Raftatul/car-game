class_name InventorySlot
extends AspectRatioContainer

@export var default_icon: Texture

@onready var slot_focus: TextureRect = $SlotFocus
@onready var slot_icon: TextureRect = $SlotIcon


func _ready() -> void:
	slot_icon.texture = default_icon


func set_active(active: bool) -> void:
	slot_focus.visible = active


func set_texture(texture: Texture) -> void:
	if texture:
		slot_icon.texture = texture
	else:
		slot_icon.texture = default_icon
