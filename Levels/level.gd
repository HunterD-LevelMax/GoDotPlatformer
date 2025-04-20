extends Node3D

var box_scene = preload("res://box.tscn")

func _ready():
	# Для теста: спавним box при старте уровня
	spawn_box(Vector3(7.116, 1.715, 0))
	_on_timer_timeout()

func spawn_box(spawn_position: Vector3):
	if box_scene:
		var box_instance = box_scene.instantiate()
		box_instance.position = spawn_position
		add_child(box_instance)
	else:
		print("Ошибка: box_scene не назначена!")

func _on_timer_timeout() -> void:
	var x = randf_range(-10.0, 10.0)   # Замените диапазон на свой
	var y =  0.5                     # Например, высота над землёй
	var z = randf_range(-10.0, 10.0)   # Замените диапазон на свой
	spawn_box(Vector3(x,y,z))
