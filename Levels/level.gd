extends Node3D

var box_scene = preload("res://box.tscn")

@onready var player = $Player

func _ready():
	spawn_box(Vector3(7.116, 1.715, 0))
	_on_timer_timeout()

func spawn_box(spawn_position: Vector3):
	if box_scene:
		var box_instance = box_scene.instantiate()
		box_instance.position = spawn_position
		# Подключаем сигнал box_destroyed к функции _on_box_destroyed
		box_instance.box_destroyed.connect(_on_box_destroyed)
		add_child(box_instance)
	else:
		print("Ошибка: box_scene не назначена!")

func _on_box_destroyed():
	player.score += 1
	print("Счёт: %s" % player.score)
	# Если есть Label для счёта:
	$UserInterface/ScoreText.text = "Score: %s" % player.score

func _on_timer_timeout() -> void:
	var x = randf_range(-10.0, 10.0)
	var y = 1.2
	var z = randf_range(-10.0, 10.0)
	spawn_box(Vector3(x, y, z))
