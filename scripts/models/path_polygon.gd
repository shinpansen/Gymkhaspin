class_name PathPolygon
extends RefCounted

var path: Path3D
var polygon: CSGPolygon3D
var caller: Wheel

func _init(path_p: Path3D, polygon_p: CSGPolygon3D, caller_p: Wheel) -> void:
    path = path_p
    polygon = polygon_p
    caller = caller_p
