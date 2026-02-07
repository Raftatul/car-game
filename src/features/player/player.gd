class_name PlayerCharacter
extends CharacterBody3D

signal jumped
signal death

enum MOVEMENT_STATE {WALKING, SWIMMING, FALLING, DIVING}

@export var sensitivity: float = 0.5
@export var rotation_speed: float = 1.0
@export var run_speed: float = 10.0
@export var jump_force: float = 10.0
@export var water_jump_force: float = 10.0

@export var gravity_scale: float = 1.0

@export_group("Config/Walking", "walking_")
@export var walking_acceleration: float = 5.0
@export var walking_speed: float = 10.0

@export_group("Config/Falling", "falling_")
@export var falling_acceleration: float = 5.0

@export_group("Config/Swimming", "swimming_")
@export var swimming_speed: float = 1.0
@export var swimming_fast_speed: float = 1.0
@export var swimming_acceleration: float = 0.05
@export var swimming_rotation_speed: float = 0.05

@export_group("Config/Values")
@export var stamina_consume_rate: float = -10.0
@export var oxygen_consume_rate: float = -10.0
@export var no_oxy_health_consume_rate: float = -10.0

@export_group("Nodes")
@export var model: Node3D

var speed: float = walking_speed
var movement_state: MOVEMENT_STATE = MOVEMENT_STATE.FALLING

var masked: bool = false
var dead: bool = false

var diving_right_axis: Vector3 = Vector3.ZERO

@onready var dead_focus: Node3D = self

@onready var camera_pivot: Node3D = %CameraPivot
@onready var spring_arm: SpringArm3D = %SpringArm3D
@onready var camera: Camera3D = %Camera3D

@onready var godot_plush_model: Node3D = $Visual/godot_plush_model
@onready var dead_mesh: MeshInstance3D = %DeadMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@onready var pause_menu: Control = %PauseMenu
@onready var canvas_layer: CanvasLayer = $CanvasLayer

##Components
@onready var inputs_component: InputsComponent = $InputsComponent
@onready var interactor: Interactor = $Interactor
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var item_manager_component: ItemManagerComponent = $ItemManagerComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var oxygen_component: OxygenComponent = $OxygenComponent
@onready var buoyancy: CharacterBuoyancy = $CharacterBuoyancy


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
		
		buoyancy.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		camera.current = true
		buoyancy.submerged_changed.connect(_on_buoyancy_submerged_changed)
		health_component.health_changed.connect(_on_health_component_health_changed)


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
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		inputs_component.update()
	
	if dead:
		if dead_focus:
			global_position = dead_focus.global_position
		return
	
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
	
	DebugDraw3D.draw_text(global_position + Vector3.UP, str(buoyancy.get_submerged_ratio()))
	DebugDraw3D.draw_text(global_position + Vector3.UP * 1.25, str(MOVEMENT_STATE.find_key(movement_state)))
	
	item_manager_component.wants_scroll_up = inputs_component.scroll_up_pressed
	item_manager_component.wants_scroll_down = inputs_component.scroll_down_pressed
	
	item_manager_component.wants_item_use = inputs_component.use_item_pressed
	item_manager_component.wants_item_drop = inputs_component.drop_pressed
	item_manager_component.tick(delta)
	
	if !inputs_component.run_pressed:
		stamina_component.tick(delta)
	
	move_and_slide()


func jump(force: float) -> void:
	jumped.emit()
	velocity.y = force


@rpc("any_peer", "call_local", "reliable")
func revive() -> void:
	dead = false
	health_component.current_health = health_component.max_health
	collision_shape.set_deferred("disabled", false)
	godot_plush_model.visible = true
	dead_mesh.visible = false
	dead_focus = null
	spring_arm.collision_mask = 1


@rpc("any_peer", "call_local", "reliable")
func kill() -> void:
	dead = true
	death.emit()
	collision_shape.set_deferred("disabled", true)
	godot_plush_model.visible = false
	model.global_rotation = Vector3.ZERO
	dead_mesh.visible = true
	spring_arm.collision_mask = 0
	
	var other_players: Array = get_tree().get_nodes_in_group("players").filter(func(a): return a != self)
	if other_players.is_empty():
		return
	
	var other_player: Node3D = other_players[0]
	if is_instance_valid(other_player):
		dead_focus = other_player


func _process_walking_state(delta: float) -> void:
	if not is_on_floor():
		movement_state = MOVEMENT_STATE.FALLING
		return
	
	oxygen_component.tick(delta)
	
	if inputs_component.run_pressed and stamina_component.has_amount(delta * stamina_consume_rate):
		stamina_component.modify(delta * stamina_consume_rate)
		speed = run_speed
	else:
		speed = walking_speed
	
	if inputs_component.jump_pressed:
		jump(jump_force)
	
	_process_movement(delta, speed, walking_acceleration)


func _process_swimming_state(delta: float) -> void:
	if inputs_component.jump_pressed:
		jump(water_jump_force)
	
	oxygen_component.tick(delta)
	
	velocity += get_gravity() * delta * gravity_scale
	
	if inputs_component.run_pressed and stamina_component.has_amount(delta * stamina_consume_rate):
		stamina_component.modify(delta * stamina_consume_rate)
		speed = swimming_fast_speed
	else:
		speed = swimming_speed
	
	if inputs_component.dive_pressed or buoyancy.get_average_depth() < -3.5:
		buoyancy.apply_forces = false
		if abs(velocity.y) < 3.0:
			velocity.y += -3.0
		gravity_scale = 0.0
		movement_state = MOVEMENT_STATE.DIVING
	
	_process_movement(delta, swimming_speed, swimming_acceleration)


func _process_falling_state(delta: float) -> void:
	if is_on_floor():
		movement_state = MOVEMENT_STATE.WALKING
		return
	
	oxygen_component.tick(delta)
	
	velocity += get_gravity() * delta * gravity_scale
	
	_process_movement(delta, walking_speed, falling_acceleration)


func _process_diving_state(delta: float) -> void:
	var input: Vector2 = inputs_component.flat_input
	var up_input: float = inputs_component.vertical_input
	
	if oxygen_component.get_percent() > 0.0:
		oxygen_component.modify(delta * oxygen_consume_rate)
	else:
		health_component.modify(delta * no_oxy_health_consume_rate)
	
	if inputs_component.run_pressed and stamina_component.has_amount(delta * stamina_consume_rate):
		stamina_component.modify(delta * stamina_consume_rate)
		speed = swimming_fast_speed
	else:
		speed = swimming_speed
	
	if !inputs_component.dive_pressed and buoyancy.get_average_depth() > -2.0:
		buoyancy.apply_forces = true
		gravity_scale = 1.0
		movement_state = MOVEMENT_STATE.SWIMMING
	
	if input or up_input:
		var vel_dir: Vector3 = (camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * up_input).normalized()
		var target_vel: Vector3 = vel_dir * speed
		
		velocity = velocity.move_toward(target_vel, swimming_acceleration)
		
		var right_vec: Vector3 = Vector3.UP.cross(vel_dir).normalized()
		if vel_dir.abs() == Vector3.UP:
			if diving_right_axis == Vector3.ZERO:
				diving_right_axis = -model.global_basis.x
			right_vec = diving_right_axis
		else:
			diving_right_axis = Vector3.ZERO
		
		var forward_vec: Vector3 = vel_dir.normalized().cross(right_vec).normalized()
		var target_basis: Basis = Basis(-right_vec, vel_dir.normalized(), forward_vec).orthonormalized()
		
		var quat_target: Quaternion = target_basis.get_rotation_quaternion()
		model.quaternion = model.quaternion.slerp(quat_target, delta * swimming_rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, 0.0, 0.0), swimming_acceleration / 2.0)


func _process_movement(delta: float, max_speed: float, acceleration: float) -> void:
	if inputs_component.move_dir:
		var target_vel: Vector3 = camera_pivot.global_basis * inputs_component.move_dir * max_speed
		velocity = velocity.move_toward(Vector3(target_vel.x, velocity.y, target_vel.z), acceleration)
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-target_vel.x, -target_vel.z), delta * rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, velocity.y, 0.0), acceleration)
	
	model.rotation.x = lerp_angle(model.rotation.x, 0.0, delta * rotation_speed)
	model.rotation.z = lerp_angle(model.rotation.z, 0.0, delta * rotation_speed)


func is_in_water() -> bool:
	return buoyancy.get_submerged_ratio() == 1.0


func _on_buoyancy_submerged_changed() -> void:
	var is_submerged: bool = buoyancy.get_submerged_ratio() > 0.0
	if is_submerged and movement_state != MOVEMENT_STATE.SWIMMING:
		movement_state = MOVEMENT_STATE.SWIMMING
	if !is_submerged and movement_state == MOVEMENT_STATE.SWIMMING:
		movement_state = MOVEMENT_STATE.FALLING
		gravity_scale = 1.0
		buoyancy.apply_forces = true


func _on_health_component_health_changed(percent: float) -> void:
	if percent == 0.0:
		kill.rpc()
