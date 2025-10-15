extends CharacterBody2D
class_name Player

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var max_health: int = 100

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int = max_health
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	add_to_group("player")
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	# Gravité
	if not is_on_floor():
		velocity.y += gravity * delta

	# Saut
	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = jump_velocity

	# Mouvement horizontal
	var direction = Input.get_axis("player_move_left", "player_move_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	# Animation
	if velocity.x != 0:
		sprite.play("walk")
		sprite.flip_h = velocity.x < 0
	else:
		sprite.play("idle")

func take_damage(damage: int):
	health -= damage
	health_bar.value = health
	print("Player health: ", health)
	
	if health <= 0:
		die()

func die():
	print("Player died!")
	# Respawn ou game over
	global_position = Vector2(100, 100)
	health = max_health
	health_bar.value = health