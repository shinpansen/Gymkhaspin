class_name Wheel
extends Node3D

@export var parent_vehicle: Vehicle
@export var suspension_length: float = 0.7
@export var suspension_force: float = 150.0
@export var wheel_min_offset_y: float = -0.2

var _raycast: RayCast3D
var _wheel_mesh: MeshInstance3D
var _wheel_radius: float
var _wheel_distance_to_raycast: float

func _ready() -> void:
	_raycast = %RayCast3D
	_wheel_mesh = %Wheel_FL
	_wheel_radius = _wheel_mesh.get_aabb().size.y / 2.0
	_wheel_distance_to_raycast = _raycast.global_position.distance_to(_wheel_mesh.global_position)

func _process(delta: float) -> void:
	if parent_vehicle == null: return
	
	if on_ground(): _apply_suspension_force(delta)
	_update_wheel_offset(delta)
	
func on_ground() -> bool:
	if !_raycast.is_colliding(): return false
	elif _get_suspension_distance_to_collision() > suspension_length: return false
	return true

func _apply_suspension_force(delta: float) -> void:
	var collision_distance: float = _get_suspension_distance_to_collision()

	var collision_point: Vector3 = _raycast.get_collision_point()
	var force_ratio: float = 1.0 - (collision_distance / suspension_length)

	var direction: Vector3 = collision_point.direction_to(
		_raycast.global_position).normalized()

	parent_vehicle.apply_force(
		direction * force_ratio * suspension_force,
		_raycast.global_position - parent_vehicle.global_position
	)
 
func _get_suspension_distance_to_collision() -> float:
	if !_raycast.is_colliding(): return suspension_length;
	return _raycast.global_position.distance_to(_raycast.get_collision_point())
	
func _update_wheel_offset(delta: float) -> void:
	if !on_ground():
		_wheel_mesh.position.y = lerpf(_wheel_mesh.position.y, wheel_min_offset_y, delta * 20.0)
	else:
		var distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
		distance -= _wheel_distance_to_raycast
		_wheel_mesh.position.y = lerpf(_wheel_mesh.position.y, -distance + _wheel_radius / 2.0, delta * 20.0)
		# _wheel_mesh.global_position.y = lerpf(_wheel_mesh.global_position.y, target_y, delta * 30.0)
