class_name Vehicle
extends RigidBody3D

@export var cornering_force: float = 15.0
@export var max_torque: float = 120.0
@export var acceleration_force: float = 30.0
@export var friction_force: float = 6.0
@export var side_speed_drift: float = 6.0
@export var side_speed_grip: float = 3.0
@export var linear_damping: float = 1.0
@export var suspension_damping: float = 6.0
@export var tilt_ratio: float = 0.3
@export var wheels: Array[Wheel] = []

var speed : float:
	get: return abs(signed_speed)
	set(_value): assert(false, "speed is read-only")
var signed_speed: float:
	get: return linear_velocity.dot(-transform.basis.z)
	set(_value): assert(false, "signed_speed is read-only")
var side_speed: float:
	get: return linear_velocity.dot(_get_side_vector())
	set(_value): assert(false, "side_speed is read-only")
var current_acceleration: float:
	get: return _current_acceleration
	set(_value): assert(false, "current_acceleration is read-only")

var _front_raycast: RayCast3D
var _back_raycast: RayCast3D
var _left_raycast: RayCast3D
var _right_raycast: RayCast3D

var _floor_normal: Vector3
var _current_torque: float
var _acceleration_sign: float
var _current_friction: float
var _is_drifting: bool
var _current_acceleration: float
var _previous_speed: float

func _ready() -> void:
	_front_raycast = %FrontRayCast
	_back_raycast = %BackRayCast
	_left_raycast = %LeftRayCast
	_right_raycast = %RightRayCast

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		apply_force(Vector3.UP * 5000.0)

	_handle_inputs(delta)
	_calculate_floor_normal()
	_handle_acceleration()
	_handle_cornering()
	_add_side_friction_force(delta)
	_handle_drift()
	_apply_tilt_tweak()

func _physics_process(delta: float) -> void:
	var forward_speed: float = speed
	_current_acceleration = (forward_speed - _previous_speed) / delta
	_previous_speed = forward_speed
	print("acceleration: ", _current_acceleration)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if !_on_ground(): return
	
	var v: Vector3 = state.linear_velocity
	var up_axis: Vector3 = global_transform.basis.y.normalized()
	var up_velocity: Vector3 = up_axis * v.dot(up_axis)
	state.linear_velocity -= up_velocity * suspension_damping * state.step

func _handle_inputs(delta: float) -> void:
	_acceleration_sign = (
		1.0 if Input.is_action_pressed("ui_up")
		else -1.0 if Input.is_action_pressed("ui_down")
		else 0.0
	)
	_current_torque = lerpf(_current_torque, max_torque * _acceleration_sign, acceleration_force * delta)

func _handle_acceleration() -> void:
	# if _on_ground(): 
	# 	if speed > 0.5 || _acceleration_sign != 0.0: linear_damp = linear_damping
	# 	elif speed < 0.5 && _acceleration_sign == 0.0: linear_damp = 10.0 if speed > 0.25 else 30.0
	# else: linear_damp = 0.0
	linear_damp = linear_damping if _on_ground() else 0.0

	var forward_vector: Vector3 = _get_forward_vector().normalized()
	apply_central_force(forward_vector * _current_torque)

func _handle_cornering() -> void:
	var input_direction: Vector2 = Input.get_vector("ui_right", "ui_left", "ui_up", "ui_down", 0.2)
	var force: float = cornering_force
	if !_on_ground(): force /= 4.0
	elif speed < 8.0: force *= speed * 0.125
	apply_torque(Vector3(0.0, input_direction.x, 0.0) * deg_to_rad(90.0) * force)

func _add_side_friction_force(delta: float) -> void:
	if !_on_ground: return
	var friction_target: float = 0.0 if _is_drifting else friction_force

	# Increase friction at lower speed to limit slow drift
	if speed < 8.0:
		friction_target = (
			friction_target + (friction_target * (8.0 - speed))
			if !_is_drifting
			else friction_force * (8.0 - speed) / 10.0
		)

	_current_friction = lerpf(_current_friction, friction_target, delta * 10.0)
	apply_central_force(_get_side_vector() * -side_speed * mass * _current_friction)

func _handle_drift() -> void:
	if !_is_drifting && (abs(side_speed) > side_speed_drift || !_on_ground()):
		_is_drifting = true
	elif _is_drifting && abs(side_speed) < side_speed_grip:
		_is_drifting = false

func _apply_tilt_tweak() -> void:
	var input_direction: Vector2 = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up", 0.2)
	var tilt: float = tilt_ratio * speed * 0.125 if speed < 8.0 else tilt_ratio
	var drift_direction: float = sign(side_speed)
	var tilt_x: float = drift_direction if _is_drifting else -input_direction.x

	center_of_mass = Vector3(tilt_x * tilt / 2.0, center_of_mass.y, -_acceleration_sign * tilt)

func _get_forward_vector() -> Vector3:
	if !_front_raycast.is_colliding() && !_back_raycast.is_colliding():
		return Vector3.ZERO

	return _back_raycast.get_collision_point().direction_to(
		_front_raycast.get_collision_point()
	)

func _get_side_vector() -> Vector3:
	if !_left_raycast.is_colliding() && !_right_raycast.is_colliding():
		return Vector3.ZERO

	return _right_raycast.get_collision_point().direction_to(
		_left_raycast.get_collision_point()
	)

func _on_ground() -> bool:
	var wheels_on_ground_count: int = 0
	for w: Wheel in wheels: 
		if w.on_ground(): wheels_on_ground_count += 1
	return wheels_on_ground_count > 2

func _calculate_floor_normal() -> void:
	_floor_normal = Vector3.UP
	if _front_raycast.is_colliding():
		_floor_normal = _front_raycast.get_collision_normal()

