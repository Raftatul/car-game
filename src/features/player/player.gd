class_name PlayerCharacter
extends CharacterBody3D

signal jumped
signal death

enum MOVEMENT_STATE {WALKING, SWIMMING, FALLING, DIVING}

@export var sensitivity: float = 0.5

@export_group("Config/Walking", "walking_")
@export var walking_speed: float = 10.0
@export var run_speed: float = 10.0
@export var walking_acceleration: float = 10.0
@export var walking_damping: float = 0.05
@export var ground_friction: float = 0.8

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
@onready var buoyancy: CharacterBuoyancy = $RigidBuoyancy

@onready var ground_movement: Movement = %GroundMovement
@onready var air_movement: Movement = %AirMovement
@onready var swimming_movement: Movement = %SwimmingMovement
@onready var diving_movement: Movement = %DivingMovement


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


func _get_active_movement() -> Movement:
	match movement_state:
		MOVEMENT_STATE.WALKING:
			return ground_movement
		MOVEMENT_STATE.FALLING:
			return air_movement
		MOVEMENT_STATE.SWIMMING:
			return swimming_movement
		MOVEMENT_STATE.DIVING:
			return diving_movement
	return ground_movement


func _physics_process(delta: float) -> void:
	if dead:
		if dead_focus:
			global_position = dead_focus.global_position
		return
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		inputs_component.update()
	
	var move_dir: Vector3 = camera_pivot.global_basis * inputs_component.move_dir
	var run_pressed: bool = inputs_component.run_pressed
	var can_run: bool = run_pressed && stamina_component.has_amount(1.0)
	
	if run_pressed:
		stamina_component.tick(delta)
		stamina_component.modify(stamina_consume_rate * delta)
	
	if movement_state == MOVEMENT_STATE.DIVING:
		var input: Vector2 = inputs_component.flat_input
		var up_input: float = inputs_component.vertical_input
		move_dir = (camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * up_input).normalized()
	
	var active_movement: Movement = _get_active_movement()
	active_movement.desired_move_dir = move_dir
	active_movement.wants_jump = inputs_component.jump_pressed
	active_movement.wants_to_move_fast = can_run
	active_movement.tick(delta)
	
	if buoyancy.get_average_depth() < -3.5 || (movement_state == MOVEMENT_STATE.SWIMMING && inputs_component.dive_pressed):
		movement_state = MOVEMENT_STATE.DIVING
		_on_diving_entered()
	elif is_on_floor():
		movement_state = MOVEMENT_STATE.WALKING
	elif buoyancy.get_average_depth() > -2.0 && !inputs_component.dive_pressed && !is_zero_approx(buoyancy.get_submerged_ratio()):
		movement_state = MOVEMENT_STATE.SWIMMING
		_on_swimming_entered()
	elif is_zero_approx(buoyancy.get_submerged_ratio()):
		movement_state = MOVEMENT_STATE.FALLING
	
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


func _on_swimming_entered() -> void:
	buoyancy.apply_forces = true
	movement_state = MOVEMENT_STATE.SWIMMING


func _on_diving_entered() -> void:
	buoyancy.apply_forces = false
	movement_state = MOVEMENT_STATE.DIVING


func is_in_water() -> bool:
	return buoyancy.get_submerged_ratio() == 1.0


func _on_buoyancy_submerged_changed() -> void:
	var is_submerged: bool = buoyancy.get_submerged_ratio() > 0.0
	if is_submerged and movement_state != MOVEMENT_STATE.SWIMMING:
		movement_state = MOVEMENT_STATE.SWIMMING
		_on_swimming_entered()
	if !is_submerged and movement_state != MOVEMENT_STATE.FALLING:
		movement_state = MOVEMENT_STATE.FALLING
		buoyancy.apply_forces = true


func _on_health_component_health_changed(percent: float) -> void:
	if percent == 0.0:
		kill.rpc()
