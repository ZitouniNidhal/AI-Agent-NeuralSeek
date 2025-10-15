extends CharacterBody2D
class_name AIAgent

@export var speed: float = 150.0
@export var attack_range: float = 50.0
@export var detection_range: float = 200.0
@export var max_health: float = 100.0
@export var attack_damage: int = 25

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var raycast_sight: RayCast2D = $SightRayCast
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: float = max_health
var player: Node2D
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var is_player_detected: bool = false
var last_known_player_pos: Vector2 = Vector2.ZERO

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	FLEE
}

var current_state: AIState = AIState.IDLE
var state_weights: Dictionary = {
	AIState.IDLE: 0.1,
	AIState.PATROL: 0.3,
	AIState.CHASE: 0.8,
	AIState.ATTACK: 1.0,
	AIState.FLEE: 0.0
}

func _ready():
	nav_agent.path_desired_distance = 10.0
	nav_agent.target_desired_distance = 10.0
	health_bar.max_value = max_health
	health_bar.value = health
	
	# Connecter les signaux
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	
	# Générer des points de patrouille
	_generate_patrol_points()
	
	# Trouver le joueur
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	_update_state()
	_execute_state(delta)
	_update_facing_direction()
	_update_health_bar()

func _update_state():
	var new_state = _calculate_best_state()
	if new_state != current_state:
		_transition_to_state(new_state)

func _calculate_best_state() -> AIState:
	# Utility AI : calculer les scores pour chaque état
	var scores: Dictionary = {}
	
	# État FLEE (priorité haute si santé faible)
	if health < max_health * 0.3:
		return AIState.FLEE
	
	# État ATTACK (si joueur à portée d'attaque)
	if is_player_detected and global_position.distance_to(player.global_position) <= attack_range:
		return AIState.ATTACK
	
	# État CHASE (si joueur détecté)
	if is_player_detected:
		return AIState.CHASE
	
	# État PATROL (sinon)
	return AIState.PATROL

func _transition_to_state(new_state: AIState):
	current_state = new_state
	print("AI State: ", AIState.keys()[new_state])

func _execute_state(delta):
	match current_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
		AIState.PATROL:
			_navigate_to_patrol_point()
		AIState.CHASE:
			if player:
				last_known_player_pos = player.global_position
				nav_agent.set_target_position(last_known_player_pos)
				_move_to_target()
		AIState.ATTACK:
			nav_agent.set_target_position(player.global_position)
			_move_to_target()
		AIState.FLEE:
			var flee_direction = (global_position - player.global_position).normalized()
			nav_agent.set_target_position(global_position + flee_direction * 300)
			_move_to_target()

func _navigate_to_patrol_point():
	if patrol_points.is_empty():
		return
	
	var target_pos = patrol_points[current_patrol_index]
	nav_agent.set_target_position(target_pos)
	_move_to_target()
	
	if global_position.distance_to(target_pos) < 20:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func _move_to_target():
	if nav_agent.is_navigation_finished():
		return
		
	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos).normalized()
	velocity = direction * speed
	move_and_slide()

func _update_facing_direction():
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _can_see_player() -> bool:
	if not player:
		return false
	
	raycast_sight.target_position = player.global_position - global_position
	raycast_sight.force_raycast_update()
	return raycast_sight.is_colliding() and raycast_sight.get_collider() == player

func _generate_patrol_points():
	# Générer 4 points de patrouille autour de l'agent
	for i in range(4):
		var angle = i * PI / 2
		var point = global_position + Vector2(cos(angle), sin(angle)) * 150
		patrol_points.append(point)

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		is_player_detected = true

func _on_detection_area_exited(body):
	if body.is_in_group("player"):
		is_player_detected = false

func _on_attack_area_entered(body):
	if body.is_in_group("player") and current_state == AIState.ATTACK:
		body.take_damage(attack_damage)
		# Recul après attaque
		velocity = -global_position.direction_to(body.global_position) * 100

func take_damage(damage: int):
	health -= damage
	if health <= 0:
		die()

func die():
	queue_free()

func _update_health_bar():
	health_bar.value = health