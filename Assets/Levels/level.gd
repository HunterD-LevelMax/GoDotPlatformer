extends Node3D

# Ноды
@onready var player = $Player
@onready var score_text = $UI/ScoreText
@onready var platform_generator = $PlatformGenerator
@onready var plane = $Plane

func _ready() -> void:
	# Получаем размеры и позицию плоскости через генератор
	platform_generator._get_plane_size(plane)
	
	# Генерация базовой сетки с задержкой
	await platform_generator.spawn_base_grid_with_coroutines({
		"spacing": 8.0,
		"offset": 5.0,
		"scale": Vector3(1.2, 0.4, 1.9)
	}, _on_platform_destroyed)

	# Генерация кластерного пути с задержкой
	await platform_generator.spawn_clustered_path_with_coroutines({
		"layer_count": 40,
		"cluster_size": 5.0,
		"horizontal_spacing": 7.0,
		"vertical_spacing": 1.9,
		"chaos": 0.6, # 0 - аккуратно, 1 - хаос
		"difficulty": 1.4, # от 0.5 до 2.0
		"scale": Vector3(1.2, 0.4, 1.9)
	}, _on_platform_destroyed)

	# Генерируем платформу победы на последнем слое
	platform_generator.spawn_win_platform(_on_platform_win)

func _on_platform_destroyed() -> void:
	player.add_score()
	score_text.text = "Score: %s" % player.score
	
func _on_platform_win() -> void:
	print("Победа! Игрок наступил на платформу победы.")
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "Выход"
	dialog.dialog_text = "Ты молодец!"
	add_child(dialog)
	dialog.popup_centered()

		
func _restart_level() -> void:
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart_level()

func _on_teleport_body_entered(body: Node3D) -> void:
	var spawn_points = [$Spawn1, $Spawn2, $Spawn3]
	if body.name == "Player" and spawn_points.size() > 0:
		var random_spawn = spawn_points[randi() % spawn_points.size()]
		body.global_transform.origin = random_spawn.global_transform.origin + Vector3(0, 0.5, 0)

func player_fell() -> void:
	_restart_level()
