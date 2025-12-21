extends CharacterBody2D
class_name Player

# Signaux utiles pour connecter le gameplay (UI, son, manager, etc.)
signal died
signal damaged(amount)

@export var speed: float = 200.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0
@export var jump_velocity: float = -400.0

# Aides au saut (coyote time / jump buffer)
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.12

@export var max_health: int = 100
@export var respawn_position: Vector2 = Vector2(100, 100)

# Invincibilité après dégâts (frames + clignotement)
@export var invincibility_time: float = 0.8
@export var blink_frequency: float = 0.12

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Timers internes
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var invincible_timer: float = 0.0
var blink_timer: float = 0.0
var is_blink_visible: bool = true

func _ready():
	add_to_group("player")
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	# Timers (coyote, jump buffer, invincibilité)
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	if invincible_timer > 0.0:
		invincible_timer = max(invincible_timer - delta, 0.0)
		blink_timer += delta
		if blink_timer >= blink_frequency:
			blink_timer = 0.0
			is_blink_visible = not is_blink_visible
			sprite.visible = is_blink_visible
		if invincible_timer == 0.0:
			# Fin de l'invincibilité : s'assurer que le sprite est visible
			sprite.visible = true

	# Gravité
	if not is_on_floor():
		velocity.y += gravity * delta

	# Mouvement horizontal avec accélération / friction
	var direction := Input.get_axis("player_move_left", "player_move_right")
	var target_speed := direction * speed
	if abs(target_speed) > 0.001:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# Jump buffer : stocke la pression juste avant d'atterrir
	if Input.is_action_just_pressed("player_jump"):
		jump_buffer_timer = jump_buffer_time

	# Si on a encore du coyote time ET un jump buffer actif -> sauter
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Déplacement via CharacterBody2D (Godot 4)
	move_and_slide()

	# Animation
	if velocity.x != 0:
		if not sprite.is_playing() or sprite.animation != "walk":
			sprite.play("walk")
		sprite.flip_h = velocity.x < 0
	else:
		if not sprite.is_playing() or sprite.animation != "idle":
			sprite.play("idle")

func take_damage(damage: int) -> void:
	# Si invincible, ignorer le dégât
	if invincible_timer > 0.0:
		return

	# Appliquer dégâts, clamp et update UI
	health = clamp(health - damage, 0, max_health)
	health_bar.value = health
	emit_signal("damaged", damage)

	if health <= 0:
		die()
	else:
		# Déclencher invincibilité temporaire et visuel (clignotement)
		invincible_timer = invincibility_time
		blink_timer = 0.0
		is_blink_visible = false
		sprite.visible = is_blink_visible

func heal(amount: int) -> void:
	health = clamp(health + amount, 0, max_health)
	health_bar.value = health

func set_max_health(new_max: int) -> void:
	max_health = new_max
	health = clamp(health, 0, max_health)
	health_bar.max_value = max_health
	health_bar.value = health

func die() -> void:
	emit_signal("died")
	print("Player died!")
	# Respawn simple
	global_position = respawn_position
	health = max_health
	health_bar.value = health
	velocity = Vector2.ZERO
	invincible_timer = 0.0
	sprite.visible = true
