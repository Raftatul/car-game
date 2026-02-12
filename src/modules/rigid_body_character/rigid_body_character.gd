class_name RigidBodyCharacter
extends CharacterBody3D

@export var player_mass: float = 80.0
@export var push_force: float = 80.0

# CC0/public domain/use for whatever you want no need to credit
# Call this function directly before move_and_slide() on your CharacterBody3D script
func push_away_rigid_bodies() -> void:
	for i: int in get_slide_collision_count():
		var c: KinematicCollision3D = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir: Vector3 = -c.get_normal()
			# How much velocity the object needs to increase to match player velocity in the push direction
			var velocity_diff_in_push_dir: float = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			# Only count velocity towards push dir, away from character
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			var mass_ratio: float = min(1.0, player_mass / c.get_collider().mass)
			# Optional add: Don't push object at all if it's 4x heavier or more
			if mass_ratio < 0.25:
				continue
			# Don't push object from above/below
			push_dir.y = 0
			var push_force: float = mass_ratio * push_force * velocity_diff_in_push_dir
			c.get_collider().apply_impulse(push_dir * push_force, c.get_position() - c.get_collider().global_position)
