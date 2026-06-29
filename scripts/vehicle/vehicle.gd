class_name Vehicle
extends RigidBody3D

@export var cornering_force: float = 12.0
@export var max_torque: float = 90.0
@export var acceleration_force: float = 2.0
@export var deceleration_force: float = 2.0
@export var friction_force: float = 6.0
@export var side_speed_drift: float = 5.0
@export var side_speed_grip: float = 2.0
@export var linear_damping: float = 0.5
@export var suspension_damping: float = 8.0
@export var tilt_ratio: float = 0.3
@export var wheels: Array[Wheel] = []
@export var gears: Array[float] = []
@export var idle_rpm: float = 713.0
@export var rpm_multiplier: float = 160.0
@export var drift_rpm_multiplier: float = 1.25
@export var max_rpm: float = 6100.0

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
var current_gear: String:
	get: return "N" if (!_on_ground() || speed < 0.5 || _rev_test) else ("R" if _current_gear < 0 else str(_current_gear + 1))
	set(_value): assert(false, "current_gear is read-only")
var rpm: float:
	get: return _rpm
	set(_value): assert(false, "rpm is read-only")
var is_idle_reving: bool:
	get: return _rev_test && speed < 2.0
	set(_value): assert(false, "is_idle_reving is read-only")
var is_burning: bool:
	get: return int(_rev_burn_time) > 0
	set(_value): assert(false, "is_burning is read-only")
var forward_vector: Vector3:
	get: return _get_forward_vector()
	set(_value): assert(false, "forward_vector is read-only")
var input_direction: Vector2:
	get: return Input.get_vector("cmd_right", "cmd_left", "cmd_brake", "cmd_throttle", 0.2)
	set(_value): assert(false, "input_direction is read-only")
var is_throttling: bool:
	get: return Input.is_action_pressed("cmd_throttle", 0.2)
	set(_value): assert(false, "is_braking is read-only")
var is_on_ground: bool:
	get: return _on_ground()
	set(_value): assert(false, "is_on_ground is read-only")
var is_braking: bool:
	get: return Input.is_action_pressed("cmd_brake", 0.2) && signed_speed < 1 && _acceleration_sign == -1.0
	set(_value): assert(false, "is_braking is read-only")
var is_drifting: bool:
	get: return _is_drifting
	set(_value): assert(false, "is_drifting is read-only")
var is_drawing_skid_marks: bool:
	get: return _is_drawing_skid_marks
	set(_value): assert(false, "is_drawing_skid_marks is read-only")

var _front_raycast: RayCast3D
var _back_raycast: RayCast3D
var _left_raycast: RayCast3D
var _right_raycast: RayCast3D
var _brake_lights_material: StandardMaterial3D

var _floor_normal: Vector3
var _current_torque: float
var _acceleration_sign: float
var _current_friction: float
var _is_drifting: bool
var _hand_brake: bool
var _current_gear: int
var _rpm: float
var _rev_test: bool
var _rev_burn_time: float
var _current_acceleration: float
var _current_suspension_damping: float
var _previous_speed: float
var _has_just_landed_duration: float = 0.0
var _is_drawing_skid_marks: bool
var _in_the_air_time: float = 0.0

func _ready() -> void:
	_front_raycast = %FrontRayCast
	_back_raycast = %BackRayCast
	_left_raycast = %LeftRayCast
	_right_raycast = %RightRayCast
	
	var light_fl: MeshInstance3D = get_node("Van/Body/Headlights_FL")
	var mat: StandardMaterial3D = light_fl.get_active_material(1).duplicate()
	light_fl.set_surface_override_material(1, mat)
	var light_fr: MeshInstance3D = get_node("Van/Body/Headlights_FR")
	light_fr.set_surface_override_material(1, mat)
	var brake_light: MeshInstance3D = get_node("Van/Body/Lights_RL")
	_brake_lights_material = brake_light.get_active_material(1)

func _process(delta: float) -> void:
	_handle_inputs(delta)
	_handle_damping(delta)
	_calculate_floor_normal()
	_handle_acceleration(delta)
	_handle_cornering()
	_add_side_friction_force(delta)
	_handle_drift(delta)
	_apply_tilt_tweak()
	_apply_visual_tweaks(delta)
	_draw_skid_marks()
	_compute_fake_gears_and_rpm(delta)

	########### DEBUG ##############
	%LabelSpeed.text = str(round(speed * 6.0)) + " km/h"
	%LabelSpeed.text += "\n" + str(round(_current_torque)) + " nm"
	%LabelSpeed.text += "\n" + str(int(rpm)) + " rpm"
	%LabelSpeed.text += "\n" + "Gear " + current_gear
	%LabelSpeed.text += "\n" + "_rev_burn_time " + str(_rev_burn_time)
	%LabelSpeed.text += "\n" + "is_drifting " + str(is_drifting)

func _physics_process(delta: float) -> void:
	var forward_speed: float = speed
	_current_acceleration = (forward_speed - _previous_speed) / delta
	_previous_speed = forward_speed

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _current_suspension_damping == 0.0: return
	
	var v: Vector3 = state.linear_velocity
	var up_axis: Vector3 = global_transform.basis.y.normalized()
	var up_velocity: Vector3 = up_axis * v.dot(up_axis)
	state.linear_velocity -= up_velocity * _current_suspension_damping * state.step

func _handle_inputs(delta: float) -> void:
	# Torque
	_rev_test = Input.is_action_pressed("cmd_throttle") && Input.is_action_pressed("cmd_brake")
	_acceleration_sign = (
		0.0 if _rev_test
		else -1.0 if Input.is_action_pressed("cmd_brake")
		else 1.0 if Input.is_action_pressed("cmd_throttle")
		else 0.0
	)
	var weight: float = deceleration_force if _acceleration_sign == 0.0 else acceleration_force
	if is_burning: weight *= 3.0
	var torque_target: float = max_torque if is_on_ground else max_torque / 2.0
	_current_torque = lerpf(_current_torque, torque_target * _acceleration_sign, weight * delta)

	# Hand brake
	if Input.is_action_pressed("cmd_hand_brake"):
		_current_torque /= 2.0
		_is_drifting = true
		_hand_brake = true
	else:
		_hand_brake = false

func _handle_damping(delta) -> void:
	if _on_ground(): _current_suspension_damping = suspension_damping
	else:
		_current_suspension_damping = lerpf(_current_suspension_damping, 0.0, delta * 10.0)

func _handle_acceleration(delta: float) -> void:
	apply_central_force(forward_vector.normalized() * _current_torque)

	var idle_stop: bool = !is_throttling && !is_braking && speed < 1.0
	if _on_ground() && (idle_stop || is_idle_reving):
		linear_damp = lerpf(linear_damp, 30.0, delta)
	else:
		linear_damp = linear_damping if _on_ground() else 0.0

	if is_idle_reving && rpm > max_rpm * 0.8:
		_rev_burn_time = 3.0
	else:
		_rev_burn_time = lerpf(_rev_burn_time, 0.0, delta)

func _handle_cornering() -> void:
	var force: float = cornering_force
	if !_on_ground(): force /= 4.0
	elif speed < 6.0: force *= speed * 0.125

	force *= -sign(signed_speed)
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
	_current_friction = lerpf(_current_friction, friction_target, delta * 5.0)
	apply_central_force(_get_side_vector() * -side_speed * mass * _current_friction)

func _handle_drift(delta: float) -> void:
	if _on_ground(): _has_just_landed_duration += delta 
	else: _has_just_landed_duration = 0.0

	var grip_speed: float = side_speed_grip * 1.2 if !is_throttling else side_speed_grip
	if (_has_just_landed_duration > 0.0 &&_has_just_landed_duration < 1.0) || _hand_brake:
		_is_drifting = true
	elif !_is_drifting && (abs(side_speed) > side_speed_drift || !_on_ground()):
		_is_drifting = true
	elif _is_drifting && abs(side_speed) < grip_speed:
		_is_drifting = false

func _apply_tilt_tweak() -> void:
	var tilt: float = tilt_ratio * speed * 0.125 if speed < 8.0 else tilt_ratio
	var drift_direction: float = sign(side_speed)
	var tilt_x: float = drift_direction if _is_drifting else -input_direction.x
	var tilt_dir := Vector3(tilt_x * tilt / 2.0, center_of_mass.y, -_acceleration_sign * tilt + 0.1)
	if is_idle_reving: tilt_dir.z = -tilt_ratio / 2.0
	center_of_mass = tilt_dir

func _apply_visual_tweaks(delta: float) -> void:
	# Wheels rotation
	var speed_rotation_target: float = signed_speed * 1.5
	var steering_target: float = input_direction.x * 50.0
	for w: Wheel in wheels:
		# Rotation with speed
		w.wheel_mesh.rotation_degrees.x -= speed_rotation_target
		if !w.steering_wheel && _is_drifting: 
			w.wheel_mesh.rotation_degrees.x -= speed_rotation_target
		
		var rotation_x: float = w.wheel_mesh.rotation_degrees.x
		if abs(rotation_x) > 360.0:
			w.wheel_mesh.rotation_degrees.x -= 360.0 * sign(rotation_x)
		
		# Rotation with steering
		if !w.steering_wheel: continue
		w.wheel_boxing.rotation_degrees.y = lerpf(
			w.wheel_boxing.rotation_degrees.y, 
			steering_target * sign(w.scale.y), 
			delta * 10.0)
			
	# Braking lights
	var energy_target: float = 2.0 if is_braking else 1.0
	_brake_lights_material.emission_energy_multiplier = lerpf(
		_brake_lights_material.emission_energy_multiplier,
		energy_target,
		delta * 10.0
	)
	
func _draw_skid_marks() -> void:
	var must_draw: bool = _is_drifting || is_braking || is_burning
	for w: Wheel in wheels:
		if must_draw || (current_acceleration > 10 && !w.steering_wheel):
			if !w.skid_mark_started: w.start_skid_mark()
			w.draw_skid_mark()
			_is_drawing_skid_marks = true
		else:
			w.end_skid_mark()
			_is_drawing_skid_marks = false

func _compute_fake_gears_and_rpm(delta: float) -> void:
	_current_gear = 0 if signed_speed <= 0 else -1
	for i in range(gears.size()):
		if -signed_speed > gears[i]:
			_current_gear = i + 1

	if !is_on_ground: _in_the_air_time += delta
	else: _in_the_air_time = 0.0
	
	var rpm_target: float
	var delta_weight: float = 5.0 if rpm_target > _rpm else 10.0
	if _in_the_air_time > 0.2:
		rpm_target = (max_rpm if is_throttling else idle_rpm)
	elif is_idle_reving:
		rpm_target = max_rpm
	else:
		var speed_base: float = speed
		if _current_gear >= 0 && _current_gear < 3:
			var max_speed_gear: float = gears[_current_gear]
			speed_base = speed * (30.0 / max_speed_gear)
		rpm_target = speed_base * rpm_multiplier
		if is_drifting && is_throttling: rpm_target *= drift_rpm_multiplier
		elif is_burning: rpm_target += 3000.0
		rpm_target = min(rpm_target + idle_rpm, max_rpm)
	_rpm = lerpf(_rpm, rpm_target, delta * delta_weight)

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
	var wheel_count: int = 0
	for w: Wheel in wheels: 
		if w.on_ground(): wheel_count += 1
	return wheel_count >= 3

func _calculate_floor_normal() -> void:
	_floor_normal = Vector3.UP
	if _front_raycast.is_colliding():
		_floor_normal = _front_raycast.get_collision_normal()
