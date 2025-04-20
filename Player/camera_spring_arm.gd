extends Node3D

@export var mouse_sensitivity: float = 0.005  # Чувствительность мыши
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI / 2  # Минимальный угол наклона
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI / 2     # Максимальный угол наклона

@onready var spring_arm := $SpringArm3D

func _ready() -> void:
	# Устанавливаем режим захвата мыши при старте
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Вращение по горизонтали (ось Y)
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.y = wrapf(rotation.y, 0.0, TAU)  # Оборачиваем угол в пределах [0, 2π]

		# Вращение по вертикали (ось X)
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)  # Ограничиваем угол наклона

	if event.is_action_pressed("wheel_up"):
		# Приближение камеры
		spring_arm.spring_length -= 1
	if event.is_action_pressed("wheel_down"):
		# Отдаление камеры
		spring_arm.spring_length += 1

	if event.is_action_pressed("toggle_mouse_captured"):
		# Переключение режима захвата мыши
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
