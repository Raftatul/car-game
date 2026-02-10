extends LiquidArea

@export var target_mesh: MeshInstance3D
@export var wave_speed: float = 1.0

var time: float = 0.0

var waves_data: PackedVector4Array
var gravity: float = 9.8


func _ready() -> void:
	if target_mesh:
		waves_data = target_mesh.material_override.get("shader_parameter/waves")
		gravity = target_mesh.material_override.get("shader_parameter/gravity")


func _process(delta: float) -> void:
	time += delta * wave_speed
	target_mesh.material_override.set("shader_parameter/wave_time", time)


func update_transforms_for_points(global_points: PackedVector3Array, transforms: Array[Transform3D]) -> void:
	transforms.resize(global_points.size())
	for idx in global_points.size():
		transforms[idx] = compute_wave_height(global_points[idx])


func compute_wave_height(point_pos: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, sample_gerstner_surface(point_pos)) 


func sample_gerstner_surface(world_pos: Vector3, iterations := 4) -> Vector3:
	var p := world_pos

	for i in iterations:
		var disp := Vector3.ZERO

		for wave in waves_data:
			if wave == Vector4.ZERO: continue
			
			var steep := wave.z
			var length := wave.w
			var k := TAU / length
			var c := sqrt(gravity / k)
			var d := Vector2(wave.x, wave.y).normalized()
			var f := k * (d.dot(Vector2(p.x, p.z)) - c * time)
			var a := steep / k

			disp.x += d.x * a * cos(f)
			disp.y += a * sin(f)
			disp.z += d.y * a * cos(f)

		# Remove horizontal displacement only
		p.x = world_pos.x - disp.x
		p.z = world_pos.z - disp.z

	# Final evaluation for Y
	var final_disp := Vector3.ZERO
	for wave in waves_data:
		if wave == Vector4.ZERO: continue
		
		var steep := wave.z
		var length := wave.w
		var k := TAU / length
		var c := sqrt(gravity / k)
		var d := Vector2(wave.x, wave.y).normalized()
		var f := k * (d.dot(Vector2(p.x, p.z)) - c * time)
		var a := steep / k

		final_disp.y += a * sin(f)

	return Vector3(world_pos.x, final_disp.y + target_mesh.global_position.y, world_pos.z)
