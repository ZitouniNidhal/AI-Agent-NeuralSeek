extends Node

# Signal émis quand le score change (utile pour d'autres noeuds)
signal score_changed(new_score: int)

# UI
@onready var score_label: Label = $UI/ScoreLabel

# Configuration exportée (modifiable depuis l'éditeur)
@export var start_score: int = 0
@export var save_highscore: bool = true

# Constantes
const HIGHSCORE_FILE: String = "user://highscore.cfg"

# État
var score: int = 0 setget set_score, get_score
var highscore: int = 0

func _ready() -> void:
	# Charge le highscore puis initialise la partie
	_load_highscore()
	start_game()

# Démarre une nouvelle partie (réinitialise le score au start_score)
func start_game() -> void:
	score = start_score
	_update_ui()

# Réinitialise le score (alias)
func reset() -> void:
	start_game()

# Ajoute des points (points peut être négatif)
func add_score(points: int) -> void:
	set_score(score + points)

# Setter avec contraintes et logique de highscore / notification
func set_score(value: int) -> void:
	# Toujours non-négatif
	value = max(0, value)
	if value == score:
		return
	score = value

	# Met à jour le highscore
	if score > highscore:
		highscore = score
		if save_highscore:
			_save_highscore()

	# Émet le signal et met à jour l'UI
	emit_signal("score_changed", score)
	_update_ui()

func get_score() -> int:
	return score

# Vide le highscore sauvegardé
func clear_highscore() -> void:
	highscore = 0
	if save_highscore:
		var cfg := ConfigFile.new()
		cfg.set_value("score", "highscore", highscore)
		cfg.save(HIGHSCORE_FILE)
	# Met à jour l'UI au cas où elle affiche le highscore
	_update_ui()

# Met à jour la partie affichage UI (séparé pour réutilisabilité)
func _update_ui() -> void:
	if not is_instance_valid(score_label):
		# Évite les erreurs si le chemin n'existe pas
		return
	# Affiche score et highscore de façon concise
	score_label.text = "Score: %d   Highscore: %d" % [score, highscore]

# Sauvegarde du highscore dans user:// (ConfigFile)
func _save_highscore() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "highscore", highscore)
	var err := cfg.save(HIGHSCORE_FILE)
	if err != OK:
		push_warning("Impossible de sauvegarder le highscore: %s" % str(err))

# Chargement du highscore (si présent)
func _load_highscore() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(HIGHSCORE_FILE)
	if err == OK:
		highscore = int(cfg.get_value("score", "highscore", 0))
	else:
		# fichier absent ou illisible -> on laisse highscore à 0
		highscore = 0
