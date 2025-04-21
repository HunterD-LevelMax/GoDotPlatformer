extends Node3D

var box_scene = preload("res://Assets/Platform/box.tscn")

@onready var player = $Player
@onready var scoreText = $UI/ScoreText

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
	player._add_score()
	# print("Счёт: %s" % player.score)
	# Если есть Label для счёта:
	scoreText.text = "Score: %s" % player.score

func _on_timer_timeout() -> void:
	var x = randf_range(-10.0, 10.0)
	var y = 1.2
	var z = randf_range(-10.0, 10.0)
	spawn_box(Vector3(x, y, z))
	
func restart_level():
	# Перезагрузка сцены
	get_tree().reload_current_scene()

func _input(event):
	if event.is_action_pressed("restart"):
		restart_level()

func _on_teleport_body_entered(body: Node3D) -> void:
	var spawn_points = [$Spawn1, $Spawn2, $Spawn3]  # Массив точек спауна
  
	if body.name == "Player":
		# Выбираем случайную точку из массива
		var random_spawn = spawn_points[randi() % spawn_points.size()]
	  
		# Телепортируем игрока с небольшим смещением вверх (чтобы не застрять в полу)
		body.global_transform.origin = random_spawn.global_transform.origin + Vector3(0, 0.5, 0)
	
