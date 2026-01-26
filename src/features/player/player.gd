class_name PlayerCharacter
extends CharacterBody3D

signal jumped

enum MOVEMENT_STATE {WALKING, SWIMMING, FALLING, DIVING}

@export var sensitivity: float = 0.5
@export var rotation_speed: float = 1.0
@export var walk_speed: float = 10.0
@export var run_speed: float = 10.0
@export var jump_force: float = 10.0
@export var water_jump_force: float = 10.0

@export var gravity_scale: float = 1.0

@export_group("Config/Walking", "walking_")
@export var walking_acceleration: float = 5.0

@export_group("Config/Falling", "falling_")
@export var falling_acceleration: float = 5.0

@export_group("Config/Swimming", "swimming_")
@export var swimming_speed: float = 1.0
@export var swimming_acceleration: float = 0.05
@export var swimming_rotation_speed: float = 0.05

@export_group("")

var speed: float = walk_speed
var movement_state: MOVEMENT_STATE = MOVEMENT_STATE.FALLING

@onready var camera_pivot: Node3D = %CameraPivot
@onready var spring_arm: SpringArm3D = %SpringArm3D
@onready var camera: Camera3D = %Camera3D
@onready var visual: Node3D = %Visual

@onready var pause_menu: Control = %PauseMenu
@onready var buoyancy: Buoyancy = $Buoyancy
@onready var label_3d: Label3D = $Label3D
@onready var right_hand_socket: Marker3D = %RightHandSocket
@onready var canvas_layer: CanvasLayer = $CanvasLayer

##Components
@onready var inputs_component: InputsComponent = $InputsComponent
@onready var interactor: Interactor = $Interactor
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var item_manager_component: ItemManagerComponent = $ItemManagerComponent


func _enter_tree() -> void:
	set_multiplayer_authority(int(name))


func _ready() -> void:
	if get_multiplayer_authority() != 0 and not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		camera.current = false
		canvas_layer.visible = false
	else:
		camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MouseMode.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton:
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
				Input.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
		pause_menu.visible = true
	elif event is InputEventMouseMotion:
		var motion: Vector2 = -event.relative * sensitivity
		camera_pivot.rotate_y(deg_to_rad(motion.x))
		spring_arm.rotate_x(deg_to_rad(motion.y))
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -70.0, 70.0)


func _physics_process(delta: float) -> void:
	inputs_component.update()
	
	interactor.wants_interact = inputs_component.interaction_pressed
	interactor.update()
	
	match movement_state:
		MOVEMENT_STATE.WALKING:
			_process_walking_state(delta)
		MOVEMENT_STATE.SWIMMING:
			_process_swimming_state(delta)
		MOVEMENT_STATE.FALLING:
			_process_falling_state(delta)
		MOVEMENT_STATE.DIVING:
			_process_diving_state(delta)
	
	item_manager_component.wants_scroll_up = inputs_component.scroll_up_pressed
	item_manager_component.wants_scroll_down = inputs_component.scroll_down_pressed
	
	item_manager_component.wants_item_use = inputs_component.use_item_pressed
	item_manager_component.wants_item_drop = inputs_component.drop_pressed
	item_manager_component.update()
	
	move_and_slide()
	label_3d.text = str(MOVEMENT_STATE.find_key(movement_state))


func jump(force: float) -> void:
	jumped.emit()
	velocity.y = force


func _process_walking_state(delta: float) -> void:
	if not is_on_floor():
		movement_state = MOVEMENT_STATE.FALLING
		return
	
	if inputs_component.run_pressed:
		speed = run_speed
	else:
		speed = walk_speed
	
	if inputs_component.jump_pressed:
		jump(jump_force)
	
	_process_movement(delta, speed, walking_acceleration)


func _process_swimming_state(delta: float) -> void:
	if inputs_component.jump_pressed:
		jump(water_jump_force)
	
	if inputs_component.dive_pressed or buoyancy.get_depth() > 3.5:
		buoyancy.active = false
		if abs(velocity.y) < 3.0:
			velocity.y += -3.0
		gravity_scale = 0.0
		movement_state = MOVEMENT_STATE.DIVING
	
	_process_movement(delta, swimming_speed, swimming_acceleration)


func _process_falling_state(delta: float) -> void:
	if is_on_floor():
		movement_state = MOVEMENT_STATE.WALKING
		return
	
	velocity += get_gravity() * delta * gravity_scale
	
	_process_movement(delta, walk_speed, falling_acceleration)


func _process_diving_state(delta: float) -> void:
	var input: Vector2 = inputs_component.flat_input
	var up_input: float = inputs_component.vertical_input
	
	if !inputs_component.dive_pressed and buoyancy.get_depth() < 2.0:
		movement_state = MOVEMENT_STATE.SWIMMING
		gravity_scale = 1.0
		buoyancy.active = true
	
	if input or up_input:
		var vel_dir: Vector3 = (camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * up_input).normalized()
		var target_vel: Vector3 = vel_dir * swimming_speed
		
		velocity = velocity.move_toward(target_vel, swimming_acceleration)
		
		var right_vec: Vector3 = Vector3.UP.cross(velocity.normalized()).normalized()
		var forward_vec: Vector3 = velocity.normalized().cross(right_vec).normalized()
		var target_basis: Basis = Basis(-right_vec, velocity.normalized(), forward_vec).orthonormalized()
		
		if target_basis.is_conformal():
			var quat_target: Quaternion = target_basis.get_rotation_quaternion()
			visual.quaternion = visual.quaternion.slerp(quat_target, delta * swimming_rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, 0.0, 0.0), swimming_acceleration / 2.0)


func _process_movement(delta: float, max_speed: float, acceleration: float) -> void:
	if inputs_component.move_dir:
		var target_vel: Vector3 = camera_pivot.global_basis * inputs_component.move_dir * max_speed
		velocity = velocity.move_toward(Vector3(target_vel.x, velocity.y, target_vel.z), acceleration)
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-target_vel.x, -target_vel.z), delta * rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, velocity.y, 0.0), acceleration)
	
	visual.rotation.x = lerp_angle(visual.rotation.x, 0.0, delta * rotation_speed)
	visual.rotation.z = lerp_angle(visual.rotation.z, 0.0, delta * rotation_speed)


@rpc("any_peer", "call_local")
func _rpc_set_item_in_hand(node_path: NodePath, should_be_visible: bool) -> void:
	var item: Item = get_tree().root.get_node(node_path)
	if item:
		item.visible = should_be_visible
		item.reparent.call_deferred(right_hand_socket)
		item.set_deferred("position", Vector3.ZERO)
		item.set_deferred("rotation", Vector3.ZERO)


func _on_buoyancy_water_entered() -> void:
	movement_state = MOVEMENT_STATE.SWIMMING


func _on_buoyancy_water_exited() -> void:
	movement_state = MOVEMENT_STATE.FALLING
	gravity_scale = 1.0
	buoyancy.active = true


func _on_inventory_component_item_added(_idx: int, item: Item) -> void:
	_rpc_set_item_in_hand.rpc(item.get_path(), item == inventory_component.get_selected_item())
