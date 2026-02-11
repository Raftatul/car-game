extends RigidBuoyancy

@export var body: RigidBody3D
@export var liquid_density: float = 1.0


func get_buoyancy_force() -> Vector3:
	return -body.get_gravity() * buoyancy_material.buoyancy * liquid_density * get_submerged_ratio()
