class_name PathPolygon
extends RefCounted

var path: Path3D
var polygon: CSGPolygon3D

func _init(path_p: Path3D, polygon_p: CSGPolygon3D) -> void:
    path = path_p
    polygon = polygon_p
