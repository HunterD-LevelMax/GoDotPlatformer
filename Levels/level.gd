extends Node3D

# Node references
@onready var player = $Player
@onready var score_text = $UI/ScoreText
@onready var platform_generator = $PlatformGenerator
@onready var plane = $Plane

func _ready() -> void:
	# Получаем размеры и позицию плоскости через генератор
	platform_generator._get_plane_size(plane)
	
	# Базовая сетка
	platform_generator.spawn_base_grid({
		"spacing": 10.0,
		"offset": 5.0,
		"scale": Vector3(4.0, 0.5, 3.0)
	}, _on_platform_destroyed)

	# Новый кластерный путь
	platform_generator.spawn_clustered_path({
		"layer_count": 2,
		"cluster_size": 6,
		"horizontal_spacing": 6,
		"vertical_spacing": 1.8,
		"chaos": 0.3,
		"difficulty": 1.7,
		"scale": Vector3(3.0, 0.5, 2.0)
	}, _on_platform_destroyed)
	# Генерируем платформу победы на последнем слое
	platform_generator.spawn_win_platform(_on_platform_win)

func _on_platform_destroyed() -> void:
	player._add_score()
	score_text.text = "Score: %s" % player.score
	
func _on_platform_win() -> void:
	print("Победа! Игрок наступил на платформу победы.")
	
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
