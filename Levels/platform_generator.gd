extends Node

# Preloaded platform scenes
var platform = preload("res://Assets/Platform/platform.tscn")

# Spawn parameters
var current_platforms: Array = []

func spawn_base_grid(plane_position: Vector3, plane_size: Vector2, params: Dictionary, platform_destroyed_callback: Callable) -> void:
	var spacing: float = params.get("spacing", 6.0)
	var offset: float = params.get("offset", 2.0)
	var platform_scale: Vector3 = params.get("scale", Vector3(1.0, 1.0, 1.0))

	var platforms_x: int = int(plane_size.x / spacing)
	var platforms_z: int = int(plane_size.y / spacing)
	var half_plane_x: float = plane_size.x / 2
	var half_plane_z: float = plane_size.y / 2

	for i in range(platforms_x):
		for j in range(platforms_z):
			var pos_x: float = plane_position.x - half_plane_x + (i + 0.5) * spacing + randf_range(-offset, offset)
			var pos_z: float = plane_position.z - half_plane_z + (j + 0.5) * spacing + randf_range(-offset, offset)
			_spawn_platform(Vector3(pos_x, plane_position.y, pos_z), platform_scale, platform_destroyed_callback)

func spawn_vertical_path(plane_position: Vector3, plane_size: Vector2, params: Dictionary, platform_destroyed_callback: Callable) -> void:
	var start_position: Vector3 = params.get("start_position", Vector3(plane_position.x, plane_position.y + 1.8, plane_position.z))
	var layer_count: int = params.get("layer_count", 10)
	var platforms_per_layer: int = params.get("platforms_per_layer", 2)
	var vertical_spacing: float = params.get("vertical_spacing", 1.8)
	var spacing: float = params.get("spacing", 5.0)
	var offset: float = params.get("offset", 2.0)
	var platform_scale: Vector3 = params.get("scale", Vector3(4.0, 0.5, 3.0))

	var platforms_x: int = int(plane_size.x / spacing)
	var platforms_z: int = int(plane_size.y / spacing)
	var half_plane_x: float = plane_size.x / 2
	var half_plane_z: float = plane_size.y / 2
	var total_slots: int = platforms_x * platforms_z
	var used_slots: Array = []
	var last_platform_pos: Vector3 = start_position

	for layer in range(layer_count):
		var pos_y: float = start_position.y + layer * vertical_spacing
		var layer_slots: Array = used_slots.duplicate()
		var platforms_spawned: int = 0

		while platforms_spawned < platforms_per_layer:
			var grid_x: int
			var grid_z: int

			if platforms_spawned == 0 and layer > 0:
				grid_x = int((last_platform_pos.x - (plane_position.x - half_plane_x)) / spacing)
				grid_z = int((last_platform_pos.z - (plane_position.z - half_plane_z)) / spacing)
				var closest_slot: Vector2i = _find_nearest_available_slot(grid_x, grid_z, layer_slots, platforms_x, platforms_z)
				grid_x = closest_slot.x
				grid_z = closest_slot.y
			else:
				var attempts: int = 0
				var max_attempts: int = total_slots * 2
				while attempts < max_attempts:
					grid_x = randi() % platforms_x
					grid_z = randi() % platforms_z
					var slot: Vector2i = Vector2i(grid_x, grid_z)
					if slot not in layer_slots:
						break
					attempts += 1
				if attempts >= max_attempts:
					push_warning("Could not find available slot for platform in layer " + str(layer))
					break

			var slot: Vector2i = Vector2i(grid_x, grid_z)
			if slot in layer_slots:
				continue

			var base_x: float = plane_position.x - half_plane_x + (grid_x + 0.5) * spacing
			var base_z: float = plane_position.z - half_plane_z + (grid_z + 0.5) * spacing
			var offset_x: float = randf_range(-offset, offset)
			var offset_z: float = randf_range(-offset, offset)
			var pos_x: float = base_x + offset_x
			var pos_z: float = base_z + offset_z

			pos_x = clamp(pos_x, plane_position.x - half_plane_x, plane_position.x + half_plane_x)
			pos_z = clamp(pos_z, plane_position.z - half_plane_z, plane_position.z + half_plane_z)

			var spawn_pos: Vector3 = Vector3(pos_x, pos_y, pos_z)
			_spawn_platform(spawn_pos, platform_scale, platform_destroyed_callback)
			last_platform_pos = spawn_pos
			layer_slots.append(slot)
			used_slots.append(slot)
			platforms_spawned += 1


func _find_nearest_available_slot(grid_x: int, grid_z: int, used_slots: Array, max_x: int, max_z: int) -> Vector2i:
	var best_slot: Vector2i = Vector2i(grid_x, grid_z)
	var min_dist: float = INF
	var search_radius: int = 1
	var max_attempts: int = max_x * max_z

	while search_radius < max_attempts:
		for dx in range(-search_radius, search_radius + 1):
			for dz in range(-search_radius, search_radius + 1):
				var new_x: int = grid_x + dx
				var new_z: int = grid_z + dz
				if new_x < 0 or new_x >= max_x or new_z < 0 or new_z >= max_z:
					continue
				var slot: Vector2i = Vector2i(new_x, new_z)
				if slot in used_slots:
					continue
				var dist: float = sqrt(dx * dx + dz * dz)
				if dist < min_dist:
					min_dist = dist
					best_slot = slot
		if min_dist != INF:
			break
		search_radius += 1

	return best_slot

func _spawn_platform(position: Vector3, scale: Vector3, platform_destroyed_callback: Callable) -> void:
	var platform_instance = platform.instantiate()
	platform_instance.position = position
	platform_instance.scale = scale
	if platform_instance.has_signal("platform_destroyed"):
		platform_instance.platform_destroyed.connect(platform_destroyed_callback)
	else:
		push_warning("platform.tscn missing platform_destroyed signal")
	get_parent().add_child(platform_instance)
	current_platforms.append(platform_instance)
