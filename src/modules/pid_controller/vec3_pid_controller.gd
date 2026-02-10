class_name Vec3PIDController
extends Resource

@export var p_gain: float = 1.0
@export var i_gain: float = 1.0
@export var d_gain: float = 1.0

var _error_last: Vector3 = Vector3.ZERO
var _integration_stored: Vector3 = Vector3.ZERO

var _initialized: bool = false


func update(delta: float, target: Vector3, current: Vector3) -> Vector3:
	var error: Vector3 = target - current
	
	if !_initialized:
		_error_last = error
		_initialized = true
	
	_integration_stored += error * delta
	
	var error_derivative: Vector3 = (error - _error_last) / delta
	_error_last = error
	
	var p: Vector3 = p_gain * error
	var i: Vector3 = i_gain * _integration_stored
	var d: Vector3 = error_derivative * d_gain
	
	return p + i + d
