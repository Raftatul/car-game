class_name InventorySlot
extends Control

@export var default_icon: Texture
@export var slot_focus: TextureRect
@export var slot_icon: TextureRect
@export var progress_bar: ProgressBar

var _item: Item


func _ready() -> void:
	slot_icon.texture = default_icon


func set_active(active: bool) -> void:
	slot_focus.visible = active


func set_item(item: Item) -> void:
	if _item and _item.energy_changed.is_connected(_on_energy_changed):
		_item.energy_changed.disconnect(_on_energy_changed)
	
	_item = item
	if _item:
		if _item.energy > 0.0:
			progress_bar.value = _item.get_energy_percent()
			progress_bar.visibility_layer = 1
			_item.energy_changed.connect(_on_energy_changed)
		else:
			progress_bar.visibility_layer = 0
		
		if item.texture:
			slot_icon.texture = item.texture
		else:
			slot_icon.texture = default_icon
	else:
		progress_bar.visibility_layer = 0
		slot_icon.texture = default_icon


func _on_energy_changed(percent: float) -> void:
	progress_bar.value = percent
