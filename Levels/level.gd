extends Node3D

var box_scene = preload("res://box.tscn")

func _ready():
	# Для теста: спавним box при старте уровня
	spawn_box(Vector3(7.116, 1.715, 0))

func spawn_box(spawn_position: Vector3):
	if box_scene:
		var box_instance = box_scene.instantiate()
		box_instance.position = spawn_position
		add_child(box_instance)
	else:
		print("Ошибка: box_scene не назначена!")
