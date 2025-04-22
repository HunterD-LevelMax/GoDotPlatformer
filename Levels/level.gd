extends Node3D

# Node references
@onready var player = $Player
@onready var score_text = $UI/ScoreText
@onready var plane = $Plane
@onready var platform_generator = $PlatformGenerator

# Spawn parameters
var plane_size: Vector2
var plane_position: Vector3

# Default values
const DEFAULT_PLANE_SIZE: Vector2 = Vector2(80.0, 80.0)
const DEFAULT_PLANE_POSITION: Vector3 = Vector3(0, -0.073, 0.427)

func _ready() -> void:
	_get_plane_size()
	platform_generator.spawn_base_grid(plane_position, plane_size, {
		"spacing": 10.0,
		"offset": 5.0,
		"scale": Vector3(4.0, 0.5, 3.0)
	}, _on_platform_destroyed)
	platform_generator.spawn_vertical_path(plane_position, plane_size, {
		"start_position": Vector3(plane_position.x, plane_position.y + 1.8, plane_position.z),
		"layer_count": 5,
		"platforms_per_layer": 20,
		"vertical_spacing": 1.8,
		"spacing": 3.0,
		"offset": 3.0,
		"scale": Vector3(4.0, 0.5, 3.0)
	}, _on_platform_destroyed)

func _get_plane_size() -> void:
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

func _on_platform_destroyed() -> void:
	player._add_score()
	score_text.text = "Score: %s" % player.score

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
