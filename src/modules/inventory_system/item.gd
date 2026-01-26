@abstract
class_name Item
extends Node3D

enum ATTACH_POINTS {HAND, BACK}

@export var icon: Texture2D
@export var attach_point: ATTACH_POINTS = ATTACH_POINTS.HAND

@abstract
func pre_use(node: Node) -> void

@abstract
func use(delta: float, node: Node) -> void

@abstract
func post_use(node: Node) -> void

@abstract
func dropped() -> void
