extends Area3D

signal add_coin

@export var rotation_speed: float = 2.0  # Скорость вращения в радианах/секунду

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Вращаем бонус вокруг оси Y
	rotation.y += rotation_speed * delta

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		var player = body as CharacterBody3D
		emit_signal("add_coin") 
		
		print("взяли монету")
		# Удаляем бонус
		queue_free()
