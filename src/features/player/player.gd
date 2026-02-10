class_name PlayerCharacter
extends RigidBody3D

signal jumped
signal death

enum MOVEMENT_STATE {WALKING, SWIMMING, FALLING, DIVING}

@export var sensitivity: float = 0.5
@export var rotation_speed: float = 1.0
@export var run_speed: float = 10.0
@export var water_jump_force: float = 10.0

@export_group("Jump")
@export var jump_velocity : float = 1.0

@export_group("Config/Walking", "walking_")
@export var walking_acceleration: float = 5.0
@export var walking_speed: float = 10.0
@export var ground_friction: float = 0.8

@export_group("Config/Falling", "falling_")
@export var falling_acceleration: float = 5.0
@export var falling_damping: float = 0.05

@export_group("Config/Swimming", "swimming_")
@export var swimming_speed: float = 1.0
@export var swimming_fast_speed: float = 1.0
@export var swimming_acceleration: float = 0.05
@export var swimming_rotation_speed: float = 0.05
@export var swimming_damping: float = 0.05

@export_group("Config/Diving", "diving_")
@export var diving_damping: float = 0.05

@export_group("Config/Values")
@export var stamina_consume_rate: float = -10.0
@export var oxygen_consume_rate: float = -10.0
@export var no_oxy_health_consume_rate: float = -10.0

@export_group("Camera")
@export var alive_arm_length: float = 1.0
@export var dead_arm_length: float = 1.0

@export_group("Nodes")
@export var model: Node3D

var speed: float = walking_speed
var movement_state: MOVEMENT_STATE = MOVEMENT_STATE.FALLING

var masked: bool = false
var dead: bool = false

var diving_right_axis: Vector3 = Vector3.ZERO

var is_on_floor: bool = false

var is_on_floor_buffer: bool = false


@onready var dead_focus: Node3D = self

@onready var camera_pivot: Node3D = %CameraPivot
@onready var spring_arm: SpringArm3D = %SpringArm3D
@onready var camera: Camera3D = %Camera3D
@onready var ground_check: RayCast3D = %GroundCheck

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
@onready var buoyancy: RigidBuoyancy = $RigidBuoyancy


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
		model.rotate_y(deg_to_rad(motion.x))
		camera_pivot.rotate_y(deg_to_rad(motion.x))
		spring_arm.rotate_x(deg_to_rad(motion.y))
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -70.0, 70.0)


func _integrate_forces(state: PhysicsDirectBodyState3D):
	if dead: return
	
	var delta: float = state.step
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		inputs_component.update()
	
	var is_moving: bool = inputs_component.move_dir != Vector3.ZERO
	
	physics_material_override.friction = 0.0 if is_moving else ground_friction
	
	match movement_state:
		MOVEMENT_STATE.WALKING:
			_process_walking_state(state, delta)
		MOVEMENT_STATE.SWIMMING:
			_process_swimming_state(state, delta)
		MOVEMENT_STATE.FALLING:
			_process_falling_state(state, delta)
		MOVEMENT_STATE.DIVING:
			_process_diving_state(state, delta)
	
	is_on_floor = _get_is_on_floor(state)


func _get_is_on_floor(state : PhysicsDirectBodyState3D) -> bool:
	for col_idx in state.get_contact_count():
		var col_normal = state.get_contact_local_normal(col_idx)
		return col_normal.dot(Vector3.UP) > -0.5 or ground_check.is_colliding()
	return false


func _physics_process(delta: float) -> void:
	if dead:
		if dead_focus:
			global_position = dead_focus.global_position
		return
	
	interactor.wants_interact = inputs_component.interaction_pressed
	interactor.update()
	
	DebugDraw3D.draw_text(global_position + Vector3.UP, str(buoyancy.get_submerged_ratio()))
	DebugDraw3D.draw_text(global_position + Vector3.UP * 1.25, str(MOVEMENT_STATE.find_key(movement_state)))
	
	item_manager_component.wants_scroll_up = inputs_component.scroll_up_pressed
	item_manager_component.wants_scroll_down = inputs_component.scroll_down_pressed
	
	item_manager_component.wants_item_use = inputs_component.use_item_pressed
	item_manager_component.wants_item_drop = inputs_component.drop_pressed
	item_manager_component.tick(delta)
	
	if !inputs_component.run_pressed:
		stamina_component.tick(delta)


func jump(force: float) -> void:
	jumped.emit()
	linear_velocity.y = force


@rpc("any_peer", "call_local", "reliable")
func revive() -> void:
	dead = false
	health_component.current_health = health_component.max_health
	collision_shape.set_deferred("disabled", false)
	model.visible = true
	dead_mesh.visible = false
	dead_focus = null
	spring_arm.collision_mask = 1
	spring_arm.spring_length = alive_arm_length


@rpc("any_peer", "call_local", "reliable")
func kill() -> void:
	dead = true
	death.emit()
	collision_shape.set_deferred("disabled", true)
	model.visible = false
	global_rotation = Vector3.ZERO
	model.global_rotation = Vector3.ZERO
	dead_mesh.visible = true
	spring_arm.collision_mask = 0
	spring_arm.spring_length = dead_arm_length
	
	var other_players: Array = get_tree().get_nodes_in_group("players").filter(func(a): return a != self)
	if other_players.is_empty():
		return
	
	var other_player: Node3D = other_players[0]
	if is_instance_valid(other_player):
		dead_focus = other_player


func _apply_h_damping(state: PhysicsDirectBodyState3D, damp: float) -> void:
	state.linear_velocity.x -= state.linear_velocity.x * damp
	state.linear_velocity.z -= state.linear_velocity.z * damp


func _process_walking_state(state: PhysicsDirectBodyState3D, delta: float) -> void:
	if not is_on_floor:
		movement_state = MOVEMENT_STATE.FALLING
		return
	
	oxygen_component.tick(delta)
	
	if inputs_component.run_pressed and stamina_component.has_amount(delta * stamina_consume_rate):
		stamina_component.modify(delta * stamina_consume_rate)
		speed = run_speed
	else:
		speed = walking_speed
	
	if inputs_component.jump_pressed:
		jump(jump_velocity)
	
	var movement_dir: Vector3 = camera_pivot.global_basis * inputs_component.move_dir
	_process_movement(state, movement_dir, speed, walking_acceleration)


func _process_swimming_state(state: PhysicsDirectBodyState3D, delta: float) -> void:
	if inputs_component.jump_pressed:
		jump(water_jump_force)
	
	oxygen_component.tick(delta)
	
	if inputs_component.run_pressed and stamina_component.has_amount(delta * stamina_consume_rate):
		stamina_component.modify(delta * stamina_consume_rate)
		speed = swimming_fast_speed
	else:
		speed = swimming_speed
	
	if inputs_component.dive_pressed or buoyancy.get_submerged_ratio() == 1.0:
		buoyancy.apply_forces = false
		gravity_scale = 0.0
		movement_state = MOVEMENT_STATE.DIVING
	
	var movement_dir: Vector3 = camera_pivot.global_basis * inputs_component.move_dir
	if movement_dir: _process_movement(state, movement_dir, swimming_speed, swimming_acceleration)
	else: _apply_h_damping(state, swimming_damping)


func _process_falling_state(state: PhysicsDirectBodyState3D, delta: float) -> void:
	if is_on_floor:
		movement_state = MOVEMENT_STATE.WALKING
		return
	
	oxygen_component.tick(delta)
	
	var movement_dir: Vector3 = camera_pivot.global_basis * inputs_component.move_dir
	if movement_dir: _process_movement(state, movement_dir, walking_speed, falling_acceleration)
	else: _apply_h_damping(state, falling_damping)


func _process_diving_state(state: PhysicsDirectBodyState3D, delta: float) -> void:
	if oxygen_component.get_percent() > 0.0:
		oxygen_component.modify(delta * oxygen_consume_rate)
	else:
		health_component.modify(delta * no_oxy_health_consume_rate)
	
	if inputs_component.run_pressed and stamina_component.has_amount(delta * stamina_consume_rate):
		stamina_component.modify(delta * stamina_consume_rate)
		speed = swimming_fast_speed
	else:
		speed = swimming_speed
	
	if !inputs_component.dive_pressed and buoyancy.get_submerged_ratio() < 1.0:
		buoyancy.apply_forces = true
		gravity_scale = 1.0
		movement_state = MOVEMENT_STATE.SWIMMING
	
	var input: Vector2 = inputs_component.flat_input
	var up_input: float = inputs_component.vertical_input
	var movement_dir: Vector3 = (camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * up_input).normalized()
	if movement_dir: _process_movement(state, movement_dir, speed, swimming_acceleration)
	else: state.linear_velocity -= state.linear_velocity * diving_damping


func _process_movement(state: PhysicsDirectBodyState3D, movement_input: Vector3, max_speed: float, acceleration: float) -> void:
	var target_vel: Vector3 = state.linear_velocity
	target_vel += movement_input * max_speed * state.step * acceleration
	
	if is_zero_approx(movement_input.y):
		target_vel.y = 0.0
	
	target_vel = target_vel.limit_length(max_speed)
	
	if is_zero_approx(movement_input.y):
		target_vel.y = state.linear_velocity.y
	
	state.linear_velocity = target_vel


func is_in_water() -> bool:
	return buoyancy.get_submerged_ratio() == 1.0


func _on_buoyancy_submerged_changed() -> void:
	var is_submerged: bool = buoyancy.get_submerged_ratio() > 0.0
	if is_submerged and movement_state != MOVEMENT_STATE.SWIMMING:
		movement_state = MOVEMENT_STATE.SWIMMING
	if !is_submerged and movement_state != MOVEMENT_STATE.FALLING:
		movement_state = MOVEMENT_STATE.FALLING
		buoyancy.apply_forces = true


func _on_health_component_health_changed(percent: float) -> void:
	if percent == 0.0:
		kill.rpc()
