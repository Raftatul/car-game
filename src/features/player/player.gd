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


func _enter_tree() -> void:
	set_multiplayer_authority(int(name))


func _ready() -> void:
	if get_multiplayer_authority() != 0 and not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		camera.current = false
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
	match movement_state:
		MOVEMENT_STATE.WALKING:
			_process_walking_state(delta)
		MOVEMENT_STATE.SWIMMING:
			_process_swimming_state(delta)
		MOVEMENT_STATE.FALLING:
			_process_falling_state(delta)
		MOVEMENT_STATE.DIVING:
			_process_diving_state(delta)
	
	move_and_slide()
	label_3d.text = str(MOVEMENT_STATE.find_key(movement_state))


func jump(force: float) -> void:
	jumped.emit()
	velocity.y = force


func _process_walking_state(delta: float) -> void:
	if not is_on_floor():
		movement_state = MOVEMENT_STATE.FALLING
		return
	
	if Input.is_action_pressed("run"):
		speed = run_speed
	else:
		speed = walk_speed
	
	if Input.is_action_just_pressed("ui_accept"):
		jump(jump_force)
	
	_process_movement(delta, speed, walking_acceleration)


func _process_swimming_state(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		jump(water_jump_force)
	
	if Input.is_action_pressed("dive") or buoyancy.get_depth() > 3.5:
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
	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var up_input: float = Input.get_axis("dive", "ui_accept")
	
	if input or up_input:
		var vel_dir: Vector3 = (camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * up_input).normalized()
		var target_vel: Vector3 = vel_dir * swimming_speed
		
		velocity = velocity.move_toward(target_vel, swimming_acceleration)
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-target_vel.x, -target_vel.z), delta * rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, 0.0, 0.0), swimming_acceleration / 2.0)


func _process_movement(delta: float, max_speed: float, acceleration: float) -> void:
	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input:
		var target_vel: Vector3 = camera_pivot.global_basis * Vector3(input.x, 0.0, input.y) * max_speed
		velocity = velocity.move_toward(Vector3(target_vel.x, velocity.y, target_vel.z), acceleration)
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-target_vel.x, -target_vel.z), delta * rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, velocity.y, 0.0), acceleration)


func _on_buoyancy_water_entered() -> void:
	movement_state = MOVEMENT_STATE.SWIMMING


func _on_buoyancy_water_exited() -> void:
	movement_state = MOVEMENT_STATE.FALLING
	gravity_scale = 1.0
	buoyancy.active = true
