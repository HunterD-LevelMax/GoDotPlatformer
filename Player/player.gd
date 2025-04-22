extends CharacterBody3D

# Настройки движения
@export var speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 9.8
@export var rotation_speed: float = 10.0
@export var sprint_stamina: float = 100.0
@export var stamina_drain_rate: float = 20.0
@export var stamina_regen_rate: float = 15.0

# Настройки анимаций
@export var run_animation: String = "running/mixamo_com"
@export var idle_animation: String = "Global/idle"
@export var jump_animation: String = "jump/mixamo_com"
@export var fall_animation: String = "fall/mixamo_com"

# Ноды
@onready var camera: Camera3D = $SpringArmPivot/Camera
@onready var skin: Node3D = $Skin
@onready var animation_player: AnimationPlayer = $Skin/AnimationPlayer
@onready var stamina_bar: ProgressBar = $"../UI/Stamina"

# Состояния
var is_running: bool = false
var is_jumping: bool = false
var is_falling: bool = false
var is_sprinting: bool = false
var current_speed: float = speed
var score: int = 0

func _ready() -> void:
	# Connect animation finished signal
	animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		is_jumping = false
		is_falling = false

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
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
	var direction := Vector3.ZERO
	
	# Преобразование ввода
	if camera:
		var forward = -camera.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		
		var right = camera.global_transform.basis.x
		right.y = 0
		right = right.normalized()
		
		direction = (forward * input_dir.y + right * input_dir.x).normalized()

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

	# Применение движения
	move_and_slide()

func handle_sprint(delta: float) -> void:
	var can_sprint = Input.is_action_pressed("sprint") and is_running and not is_jumping and sprint_stamina > 0
	
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

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == jump_animation:
		is_jumping = false  # Allow falling animation to trigger after jump animation finishes

func _add_score() -> void:
	score += 1

func _on_floor_entered(body):
	if body.name == "Player":
		get_tree().call_group("level", "player_fell")
