class_name ItemTrans
extends RemoteTransform3D

signal freed


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		freed.emit()
