extends Node 

const POINTS_COUNT_LIMIT: int = 150
const PATHS_COUNT_LIMIT: int = 20
const SKID_MATERIAL = preload("res://assets/materials/skid_mark.tres")

var _marks: Array[PathPolygon] = []
var _time_elapsed: float = 0.0

func _process(delta: float) -> void:
	# Clear old marks
	_time_elapsed += delta
	if _time_elapsed < 0.5: return

	_time_elapsed = 0.0
	for p: PathPolygon in _marks:
		while p.path.curve.point_count > POINTS_COUNT_LIMIT:
			p.path.curve.remove_point(0)

	while _marks.size() > PATHS_COUNT_LIMIT:
		_marks[0].path.curve.clear_points()
		_marks[0].path.queue_free()
		_marks[0].polygon.queue_free()
		_marks.remove_at(0)
		get_tree().current_scene.remove_child(_marks[0].path)
		get_tree().current_scene.remove_child(_marks[0].polygon)

func request_path() -> Path3D:
	var path := Path3D.new()
	path.curve = Curve3D.new()
	get_tree().current_scene.add_child(path)
	
	var csgPoly := CSGPolygon3D.new()
	csgPoly.mode = CSGPolygon3D.MODE_PATH
	csgPoly.path_node = path.get_path()
	csgPoly.path_interval = 0.5
	csgPoly.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	csgPoly.polygon = [
		Vector2(-0.08, -0.02),
		Vector2(0.08, -0.02),
		Vector2(0.08, 0.02),
		Vector2(-0.08, 0.02)
	]
	csgPoly.material = SKID_MATERIAL
	get_tree().current_scene.add_child(csgPoly)

	_marks.append(PathPolygon.new(path, csgPoly))
	return path
