extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 5
const GRAVITY = 9.8  

var run = false
var is_jumping = false
var jump_time = 0.0  # Таймер для прыжка

@onready var camera: Camera3D = $SpringArmPivot/Camera
@onready var skin: Node3D = $Skin
@onready var animation_player: AnimationPlayer = $Skin/AnimationPlayer

func _physics_process(delta: float) -> void:
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y -= GRAVITY * delta  
	else:
		velocity.y = 0  # Обнуляем вертикальную скорость, если персонаж на земле
	
	# Обрабатываем прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_time = 0.5  # Фиксируем время прыжка
		animation_player.play("Jump/mixamo_com")

	# Обновляем таймер прыжка
	if is_jumping:
		jump_time -= delta
		if jump_time <= 0 and is_on_floor():
			is_jumping = false  # После таймера переключаемся обратно

	# Получаем направление движения от игрока
	var input_dir := Input.get_vector("left", "right", "down", "up")
	if input_dir.length() > 0:
		run = true
	else:
		run = false

	# Преобразуем направление движения в пространство камеры
	var direction := Vector3.ZERO
	if camera:
		# Создаем направление относительно камеры
		var forward = -camera.global_transform.basis.z  # Направление "вперед" камеры
		var right = camera.global_transform.basis.x     # Направление "вправо" камеры
		
		# Обнуляем компоненты по оси Y, чтобы избежать наклона
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		direction = (forward * input_dir.y + right * input_dir.x).normalized()
	else:
		# Если камера не назначена, используем локальное направление персонажа
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Если направление движения существует, применяем его
	if direction.length() > 0:
		# Поворачиваем модельку персонажа
		skin.look_at(global_transform.origin - direction, Vector3.UP)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Замедляем движение, если нет входных данных
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Управление анимациями
	if run and not is_jumping:
		animation_player.play("Running/mixamo_com")
	elif not is_jumping:
		animation_player.play("mixamo_com")

	# Перемещаем персонажа
	move_and_slide()
