extends CharacterBody2D
class_name AIAgent

@export var speed: float = 150.0
@export var attack_range: float = 50.0
@export var detection_range: float = 200.0
@export var max_health: float = 100.0
@export var attack_damage: int = 25
@export var attack_cooldown: float = 1.0
@export var patrol_count: int = 4
@export var patrol_radius: float = 150.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var raycast_sight: RayCast2D = $SightRayCast
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

# Etat et données
var health: float
var player: Node2D = null
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var is_player_detected: bool = false
var last_known_player_pos: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	FLEE
}

const STATE_NAMES: Array = ["IDLE", "PATROL", "CHASE", "ATTACK", "FLEE"]
var current_state: AIState = AIState.PATROL

func _ready():
	# Initialise la santé en runtime (garantit la valeur exportée)
	health = max_health
	nav_agent.path_desired_distance = 10.0
	nav_agent.target_desired_distance = 10.0
	
	# Bar de vie
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	
	# Connecter les signaux (utiliser Callable pour Godot 4)
	detection_area.body_entered.connect(Callable(self, "_on_detection_area_entered"))
	detection_area.body_exited.connect(Callable(self, "_on_detection_area_exited"))
	attack_area.body_entered.connect(Callable(self, "_on_attack_area_entered"))
	
	# Générer des points de patrouille
	_generate_patrol_points()
	
	# Trouver le joueur (prend le premier dans le groupe "player")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Configurer le RayCast pour la portée de détection
	if raycast_sight:
		raycast_sight.collision_mask = raycast_sight.collision_mask  # placeholder si tu veux modifier
	
func _physics_process(delta):
	# Timer d'attaque
	attack_timer = max(0.0, attack_timer - delta)
	
	_update_state()
	_execute_state(delta)
	_update_facing_direction()
	_update_health_bar()

func _update_state():
	var new_state = _calculate_best_state()
	if new_state != current_state:
		_transition_to_state(new_state)

func _calculate_best_state() -> AIState:
	# Priorité FLEE si santé faible
	if health <= 0:
		return AIState.IDLE
	if health < max_health * 0.3:
		return AIState.FLEE
	
	# Si on détecte un joueur et qu'on peut le voir, on choisit ATTACK/CHASE selon la distance
	if is_player_detected and player:
		if _can_see_player():
			var dist = global_position.distance_to(player.global_position)
			if dist <= attack_range:
				return AIState.ATTACK
			else:
				return AIState.CHASE
		else:
			# Perte de la ligne de vue : garder la position connue et patrouiller vers elle (ou PATROL)
			return AIState.PATROL
	
	# Par défaut, patrouille
	return AIState.PATROL

func _transition_to_state(new_state: AIState):
	current_state = new_state
	print("AI State:", STATE_NAMES[new_state])

func _execute_state(delta):
	match current_state:
		AIState.IDLE:
			_stop_movement()
		AIState.PATROL:
			_navigate_to_patrol_point()
		AIState.CHASE:
			if player:
				last_known_player_pos = player.global_position
				nav_agent.set_target_position(last_known_player_pos)
				_move_to_target()
		AIState.ATTACK:
			if player:
				# Rester à portée de l'ennemi et attaquer si possible
				if global_position.distance_to(player.global_position) > attack_range:
					nav_agent.set_target_position(player.global_position)
					_move_to_target()
				else:
					_stop_movement()
					_try_attack(player)
		AIState.FLEE:
			# Si pas de joueur connu, reculer dans une direction aléatoire
			if player:
				var flee_dir = (global_position - player.global_position)
				if flee_dir.length() == 0:
					flee_dir = Vector2.RIGHT
				flee_dir = flee_dir.normalized()
				nav_agent.set_target_position(global_position + flee_dir * 300.0)
				_move_to_target()
			else:
				# Fuite simple : bouger vers un point aléatoire loin
				var random_dir = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()
				nav_agent.set_target_position(global_position + random_dir * 300.0)
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
		_stop_movement()
		return
	
	var next_pos: Vector2 = nav_agent.get_next_path_position()
	# direction_to renvoie un vecteur normalisé si la distance > 0
	var direction = global_position.direction_to(next_pos)
	if direction.length() == 0:
		_stop_movement()
		return
	velocity = direction * speed
	# CharacterBody2D::move_and_slide() utilise `velocity` automatiquement
	move_and_slide()

func _stop_movement():
	velocity = Vector2.ZERO
	# CharacterBody2D::move_and_slide() pour appliquer l'arrêt
	move_and_slide()

func _update_facing_direction():
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _can_see_player() -> bool:
	if not player or not raycast_sight:
		return false
	
	# Positionner le rayon vers le joueur, mais le limiter à detection_range
	var to_player = player.global_position - global_position
	var target = to_player.clamped(detection_range)
	raycast_sight.target_position = target
	raycast_sight.force_raycast_update()
	
	if not raycast_sight.is_colliding():
		# Aucun obstacle détecté sur la ligne, mais si la longueur du rayon < distance au player, alors out of range
		return to_player.length() <= detection_range
	else:
		var c = raycast_sight.get_collider()
		# Le collider peut être le noeud joueur ou un enfant; vérifier le groupe est plus robuste
		if c == player:
			return true
		if typeof(c) == TYPE_OBJECT and c.has_method("is_in_group") and c.is_in_group("player"):
			return true
		return false

func _generate_patrol_points():
	patrol_points.clear()
	for i in range(patrol_count):
		var angle = i * TAU / patrol_count
		var point = global_position + Vector2(cos(angle), sin(angle)) * patrol_radius
		patrol_points.append(point)

func _on_detection_area_entered(body):
	if body and typeof(body) == TYPE_OBJECT and body.is_in_group("player"):
		is_player_detected = true
		player = body

func _on_detection_area_exited(body):
	if body and typeof(body) == TYPE_OBJECT and body.is_in_group("player"):
		# si c'est le joueur courant qui sort, on marque la perte
		if body == player:
			is_player_detected = false

func _on_attack_area_entered(body):
	# garde compatibilité si d'autres choses entrent dans l'aire d'attaque
	if body and typeof(body) == TYPE_OBJECT and body.is_in_group("player"):
		_try_attack(body)

func _try_attack(target):
	if attack_timer > 0.0:
		return
	if not target:
		return
	# Vérifier que la cible accepte les dégâts
	if typeof(target) == TYPE_OBJECT and target.has_method("take_damage"):
		target.take_damage(attack_damage)
	attack_timer = attack_cooldown
	# Reculer légèrement après attaque (effet visuel)
	if target and target is Node2D:
		var push_dir = (global_position - target.global_position).normalized()
		velocity = push_dir * 100
		move_and_slide()

func take_damage(damage: int):
	health = clamp(health - damage, 0, max_health)
	if health <= 0:
		die()
	else:
		# Si la santé tombe sous le seuil, forcer l'état FLEE
		if health < max_health * 0.3:
			_transition_to_state(AIState.FLEE)

func die():
	# TODO: ajouter animation de mort, sons, etc.
	queue_free()

func _update_health_bar():
	if health_bar:
		health_bar.value = clamp(health, 0, max_health)
