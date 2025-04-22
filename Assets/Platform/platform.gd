extends StaticBody3D

signal platform_destroyed

const COLOR_A = Color(0.6, 0.8, 1)    # Светло-голубой
const COLOR_B = Color(1, 0.8, 0.6)    # Светло-оранжевый

var is_blinking = false

func _ready():
	var mesh = $MeshInstance3D
	# Делаем уникальный материал для каждого box
	if mesh.material_override:
		mesh.material_override = mesh.material_override.duplicate()
	else:
		mesh.set_surface_override_material(0, mesh.get_active_material(0).duplicate())

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player" and not is_blinking:
		is_blinking = true
		blink_and_destroy()

func blink_and_destroy() -> void:
	var mesh = $MeshInstance3D
	var mat = mesh.material_override if mesh.material_override else mesh.get_active_material(0)
	var blink_time := 3.0
	var interval := 0.5
	var t := 0.0
	var color_toggle := false

	while t < blink_time:
		mat.albedo_color = COLOR_A if color_toggle else COLOR_B
		color_toggle = not color_toggle
		await get_tree().create_timer(interval).timeout
		t += interval
	
	emit_signal("platform_destroyed")  # Сигнал о разрушении
	
	queue_free()
