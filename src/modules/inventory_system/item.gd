@abstract
class_name Item
extends Node3D

@export var icon: Texture2D


@abstract
func use(_node: Node) -> void


@abstract
func dropped() -> void
