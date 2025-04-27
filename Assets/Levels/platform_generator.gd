extends Node
class_name PlatformGenerator

var platform = preload("res://Assets/Platform/standart_platform.tscn") # Загрузка стандартной платформы
var win_platform_scene = preload("res://Assets/Platform/win_platform.tscn")  # Загрузка платформы победы
var jump_bonus = preload("res://Assets/BonusItems/Jump_bonus.tscn")  # Загрузка сцены бонуса
var pool_size: int = 50
var platform_pool: Array = []
var current_platforms: Array = []

# Spawn parameters
var plane_size: Vector2
var plane_position: Vector3
var last_platform_position: Vector3 = Vector3(0, 0, 0)  # Храним позицию последней платформы

# Default values
const DEFAULT_PLANE_SIZE: Vector2 = Vector2(50.0, 50.0)
const DEFAULT_PLANE_POSITION: Vector3 = Vector3(0, 0, 0)

func _get_plane_size(plane: Node) -> void:
	if not plane:
		plane_size = DEFAULT_PLANE_SIZE
		plane_position = DEFAULT_PLANE_POSITION
		push_warning("Plane node not found, using default size")
		return

	var collision_shape: CollisionShape3D = null
	for child in plane.get_children():
		if child is CollisionShape3D:
			collision_shape = child
			break
	
	if collision_shape and collision_shape.shape is BoxShape3D:
		var extents = collision_shape.shape.extents
		var plane_scale = plane.scale
		plane_size = Vector2(extents.x * 2 * plane_scale.x, extents.z * 2 * plane_scale.z)
		plane_position = plane.global_position + Vector3(0, extents.y * plane_scale.y, 0)
	else:
		plane_size = DEFAULT_PLANE_SIZE
		plane_position = DEFAULT_PLANE_POSITION
		push_warning("Invalid Plane collision shape, using default size")

func _init():
	_initialize_platform_pool()

func _initialize_platform_pool():
	for i in range(pool_size):
		var platform_instance = platform.instantiate()
		platform_instance.visible = false
		add_child(platform_instance)
		platform_pool.append(platform_instance)

func spawn_base_grid_with_coroutines(params: Dictionary, callback: Callable) -> void:
	var spacing: float = params.get("spacing", 6.0)
	var offset: float = params.get("offset", 2.0)
	var scale: Vector3 = params.get("scale", Vector3(1, 1, 1))

	var platforms_x: int = int(plane_size.x / spacing)
	var platforms_z: int = int(plane_size.y / spacing)
	var half_x: float = plane_size.x / 2
	var half_z: float = plane_size.y / 2

	for i in range(platforms_x):
		for j in range(platforms_z):
			var pos_x = plane_position.x - half_x + (i + 0.5) * spacing + randf_range(-offset, offset)
			var pos_z = plane_position.z - half_z + (j + 0.5) * spacing + randf_range(-offset, offset)
			
			# Поднимаем платформу на её собственную высоту (scale.y)
			var pos_y = plane_position.y 
			
			# Создаем платформу с задержкой
			await create_platform_with_delay(Vector3(pos_x, pos_y, pos_z), scale, callback, 0.1)

func spawn_clustered_path_with_coroutines(params: Dictionary, callback: Callable) -> void:
	var layer_count = params.get("layer_count", 5)
	var cluster_size = params.get("cluster_size", 6)
	var horizontal_spacing = params.get("horizontal_spacing", 3.0)
	var vertical_spacing = params.get("vertical_spacing", 2.0)
	var chaos = params.get("chaos", 0.5) # 0 - аккуратно, 1 - хаос
	var difficulty = params.get("difficulty", 1.0) # от 0.5 до 2.0
	var scale = params.get("scale", Vector3(4.0, 0.5, 3.0))

	var last_cluster_center = plane_position

	for layer in range(layer_count):
		var cluster_center = last_cluster_center + Vector3(
			randf_range(-horizontal_spacing, horizontal_spacing),
			vertical_spacing,
			randf_range(-horizontal_spacing, horizontal_spacing)
		)

		for i in range(cluster_size):
			var offset = Vector3(
				randf_range(-1, 1) * horizontal_spacing * (1 + chaos),
				0,
				randf_range(-1, 1) * horizontal_spacing * (1 + chaos)
			)
			var pos = cluster_center + offset * difficulty		

			await create_platform_with_delay(pos, scale, callback, 0.1)
			
		last_cluster_center = cluster_center

# Функция для спавна бонуса
func spawn_bonus(bonus_scene: PackedScene, position: Vector3) -> void:
	var bonus = bonus_scene.instantiate()
	bonus.position = position
	get_parent().add_child(bonus)

func create_platform_with_delay(position: Vector3, scale: Vector3, callback: Callable, delay: float) -> void:
	await get_tree().create_timer(delay).timeout  # Задержка перед созданием платформы
	_spawn_platform(position, scale, callback)  # Создаем платформу

# Метод для генерации платформы победы на самом верхнем слое
func spawn_win_platform(callback: Callable) -> void:
	# Платформа победы будет расположена дальше от последней платформы
	var win_platform_instance = win_platform_scene.instantiate()
	# Добавляем смещение: 5 единиц вверх и небольшое горизонтальное смещение
	var offset = Vector3(2.0, 1.0, 2.0)  # Смещение по X, Y, Z
	win_platform_instance.position = last_platform_position + offset
	get_parent().add_child(win_platform_instance)
	current_platforms.append(win_platform_instance)

	# Подключаем сигнал платформы победы
	win_platform_instance.connect("platform_win", callback)

func _spawn_platform(position: Vector3, scale: Vector3, callback: Callable) -> Node:
	var platform_instance = _get_platform_from_pool()
	platform_instance.position = position
	platform_instance.scale = scale
	if platform_instance.has_signal("platform_destroyed"):
		platform_instance.platform_destroyed.connect(callback)
	get_parent().add_child(platform_instance)
	current_platforms.append(platform_instance)
		
	# Обновляем последнюю платформу
	last_platform_position = position
	
	# Спавним бонус с 2% шансом
	if randf() < 0.02:
		spawn_bonus(jump_bonus, platform_instance.position + Vector3(0,1,0))
		
	return platform_instance

func _get_platform_from_pool() -> Node:
	for p in platform_pool:
		if not p.visible:
			p.visible = true
			return p
	var new_p = platform.instantiate()
	add_child(new_p)
	platform_pool.append(new_p)
	return new_p
