extends Node

@export var mob_scene: PackedScene
var score: int = 0

func _ready():
	# Connect signals from Firebase and HUD
	FirebaseManager.leaderboard_received.connect(_on_leaderboard_data_received)
	$HUD.save_score.connect(_on_hud_save_score)

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$Music.stop()
	$DeathSound.play()
	
	# Show the Save Score Panel instead of the standard Game Over message
	$HUD/SaveScorePanel.show()
	$HUD/SaveScorePanel/CenterContainer/VBoxContainer/NameInput.text = FirebaseManager.player_name

func new_game():
	# Clean up previous mobs
	get_tree().call_group("mobs", "queue_free")
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Music.play()

func _on_MobTimer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = get_node(^"MobPath/MobSpawnLocation")
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to a random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)

func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
	
# Callback: Triggered when the player clicks 'Save' in the HUD
func _on_hud_save_score(new_name: String):
	FirebaseManager.save_score_with_name(score, new_name)
	
func _on_leaderboard_data_received(data):
	print("Leaderboard data arrived from Firebase")

	# Instead of going back to menu immediately, show the list
	if data is Array:
		$HUD.display_leaderboard(data)
	else:
		# If data is empty or error, just go back
		$HUD.return_to_main_menu()
