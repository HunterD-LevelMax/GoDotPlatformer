extends CharacterBody3D

# = Настройки движения =
@export var speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 9.4
@export var rotation_speed: float = 10.0
@export var sprint_stamina: float = 100.0
@export var stamina_drain_rate: float = 20.0
@export var stamina_regen_rate: float = 15.0
@export var sprint_jump_multiplier: float = 1.2  # Множитель для прыжка при спринте

# = Настройки анимаций =
@export var run_animation: String = "running/mixamo_com"
@export var idle_animation: String = "Global/idle"
@export var jump_animation: String = "jump/mixamo_com"
@export var fall_animation: String = "fall/mixamo_com"

# = Ноды =
@onready var camera: Camera3D = $SpringArmPivot/Camera
@onready var skin: Node3D = $Skin
@onready var animation_player: AnimationPlayer = $Skin/AnimationPlayer
@onready var stamina_bar: ProgressBar = $"../UI/Stamina"

# = Состояния =
var is_running: bool = false
var is_jumping: bool = false
var is_falling: bool = false
var is_sprinting: bool = false
var current_speed: float = speed
var score: int = 0

# Переменные для бонуса прыжка
var is_jump_bonus_active: bool = false  # Активен ли бонус прыжка
var original_jump_velocity: float = jump_velocity  # Оригинальная высота прыжка
var jump_bonus_timer: SceneTreeTimer = null  # Таймер бонуса

# = Режим бога =
var is_god_mode: bool = false
const GOD_MODE_SPEED: float = 8.0

# = Инициализация =
func _ready() -> void:
	# Подключаем сигнал завершения анимации
	animation_player.animation_finished.connect(_on_animation_finished)
	# Сохраняем оригинальное значение прыжка
	original_jump_velocity = jump_velocity

# = Основной цикл =
func _physics_process(delta: float) -> void:
	if is_god_mode:
		_handle_god_mode_movement(delta)
	else:
		_handle_normal_movement(delta)
	# Применяем движение
	move_and_slide()

# = Обработка обычного движения =

func _handle_normal_movement(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		is_jumping = false
		is_falling = false

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		# Увеличиваем высоту прыжка, если спринтим
		var effective_jump_velocity = jump_velocity
		if is_sprinting:
			effective_jump_velocity *= sprint_jump_multiplier
		velocity.y = effective_jump_velocity
		is_jumping = true
		is_falling = false
		animation_player.play(jump_animation)

	# Падение
	if not is_on_floor() and velocity.y < 0:
		is_falling = true

	# Обработка спринта
	handle_sprint(delta)

	# Получение ввода
	var input_dir := Input.get_vector("left", "right", "down", "up")
	var direction := _get_direction_from_input(input_dir)

	# Управление движением
	if direction.length() > 0:
		var target_angle = atan2(direction.x, direction.z)
		skin.rotation.y = lerp_angle(skin.rotation.y, target_angle, rotation_speed * delta)
		
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		is_running = true
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		is_running = false

	# Управление анимациями
	update_animations()

# = Обработка режима бога =
func _handle_god_mode_movement(delta: float) -> void:
	# Получение ввода
	var input_dir := Input.get_vector("left", "right", "down", "up")
	var direction := _get_direction_from_input(input_dir)

	# Управление движением
	velocity.x = direction.x * GOD_MODE_SPEED
	velocity.z = direction.z * GOD_MODE_SPEED

	# Управление высотой (вверх/вниз)
	if Input.is_action_pressed("move_up"):  # E для подъема
		velocity.y = GOD_MODE_SPEED
	elif Input.is_action_pressed("move_down"):  # Q для спуска
		velocity.y = -GOD_MODE_SPEED
	else:
		velocity.y = 0

# = Обработка ввода =
func _get_direction_from_input(input_dir: Vector2) -> Vector3:
	if camera:
		var forward = -camera.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		
		var right = camera.global_transform.basis.x
		right.y = 0
		right = right.normalized()
		
		return (forward * input_dir.y + right * input_dir.x).normalized()
	return Vector3.ZERO

# = Обработка спринта =
func handle_sprint(delta: float) -> void:
	var can_sprint = Input.is_action_pressed("sprint") and is_running and not is_jumping and sprint_stamina > 0 and is_on_floor()
	
	if can_sprint:
		animation_player.speed_scale = 1.5
		is_sprinting = true
		current_speed = sprint_speed
		sprint_stamina = max(0, sprint_stamina - stamina_drain_rate * delta)
	else:
		animation_player.speed_scale = 1.0
		is_sprinting = false
		current_speed = speed
		sprint_stamina = min(100.0, sprint_stamina + stamina_regen_rate * delta)
	
	if stamina_bar:
		stamina_bar.value = sprint_stamina

# = Управление анимациями =
func update_animations() -> void:
	if is_jumping and animation_player.current_animation == jump_animation:
		return  # Let the jump animation finish
	if is_falling:
		animation_player.play(fall_animation)
	elif is_sprinting:
		animation_player.play(run_animation)
	elif is_running:
		animation_player.play(run_animation)
	else:
		animation_player.play(idle_animation)

# = Обработка завершения анимации =
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == jump_animation:
		is_jumping = false  # Allow falling animation to trigger after jump animation finishes
			
# = Добавление очков =
func add_score() -> void:
	score += 1

# = Обработка падения =
func _on_floor_entered(body):
	if body.name == "Player":
		get_tree().call_group("level", "player_fell")

# = Включение/выключение режима бога =
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_god_mode"):  # P для переключения режима бога
		is_god_mode = not is_god_mode
		if is_god_mode:
			print("Режим бога включен")
			velocity = Vector3.ZERO  # Обнуляем скорость
		else:
			print("Режим бога выключен")

# = Управление бонусом прыжка =
func apply_jump_bonus(boost_multiplier: float, duration: float) -> void:
	# Если бонус уже активен, завершаем его
	if is_jump_bonus_active:
		end_jump_bonus()
	
	# Применяем новый бонус
	is_jump_bonus_active = true
	jump_velocity = original_jump_velocity * boost_multiplier
	
	# Запускаем таймер
	jump_bonus_timer = get_tree().create_timer(duration)
	jump_bonus_timer.timeout.connect(end_jump_bonus)

func end_jump_bonus() -> void:
	if is_jump_bonus_active:
		# Возвращаем оригинальное значение прыжка
		jump_velocity = original_jump_velocity
		is_jump_bonus_active = false
		jump_bonus_timer = null
