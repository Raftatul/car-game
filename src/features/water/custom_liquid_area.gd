extends LiquidArea

@export var target_mesh: MeshInstance3D

var noise: Image
var wave_speed: float
var noise_scale: float
var height_scale: float

var time: float = 0.0


func _ready() -> void:
	noise = target_mesh.material_override.get("shader_parameter/wave").noise.get_seamless_image(512, 512)
	wave_speed = target_mesh.material_override.get("shader_parameter/wave_speed")
	noise_scale = target_mesh.material_override.get("shader_parameter/noise_scale")
	height_scale = target_mesh.material_override.get("shader_parameter/height_scale")


func _process(delta: float) -> void:
	time += delta
	target_mesh.material_override.set("shader_parameter/wave_time", time)


func update_transforms_for_points(global_points: PackedVector3Array, transforms: Array[Transform3D]) -> void:
	transforms.resize(global_points.size())
	for idx in global_points.size():
		transforms[idx] = compute_wave_height(global_points[idx])


func compute_wave_height(point_pos: Vector3) -> Transform3D:
	var uv_x: float = wrapf(point_pos.x / noise_scale + time * wave_speed, 0.0, 1.0)
	var uv_y: float = wrapf(point_pos.z / noise_scale + time * wave_speed, 0.0, 1.0)
	
	var pixel_pos: Vector2 = Vector2(uv_x * noise.get_width(), uv_y * noise.get_height())
	var height: float = target_mesh.global_position.y + noise.get_pixelv(pixel_pos).r * height_scale
	return Transform3D(Basis.IDENTITY, Vector3(point_pos.x, height, point_pos.z)) 
