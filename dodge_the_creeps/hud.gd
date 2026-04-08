extends CanvasLayer

signal start_game
signal save_score(new_name) # Signal to notify Main that the player wants to save

func _ready():
	# Ensure the panel is hidden when the game starts
	$SaveScorePanel.hide()
	$LeaderboardPanel.hide()

func show_message(text):
	$MessageLabel.text = text
	$MessageLabel.show()
	$MessageTimer.timeout.connect(func(): $MessageLabel.hide())
	$MessageTimer.start()

func show_game_over():
	show_message("Game Over")
	await get_tree().create_timer(2).timeout
	$MessageLabel.text = "Dodge the\nCreeps"
	$MessageLabel.show()
	$StartButton.show()

func update_score(score):
	$ScoreLabel.text = str(score)

func _on_StartButton_pressed():
	$StartButton.hide()
	start_game.emit()

# Triggered when the user clicks the save button in the SaveScorePanel
func _on_save_score_button_pressed():
	var chosen_name = $SaveScorePanel/CenterContainer/VBoxContainer/NameInput.text
	$SaveScorePanel.hide()
	save_score.emit(chosen_name) # This triggers the function in main.gd

# This function resets the UI to the initial state
func return_to_main_menu():
	$SaveScorePanel.hide()
	$MessageLabel.text = "Dodge the\nCreeps"
	$MessageLabel.show()
	# Optional: a small delay before showing the start button
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()

# This function takes the raw data from Firebase and puts it into the ItemList
# Displays the leaderboard data received from Firebase
func display_leaderboard(records):
	$LeaderboardPanel.show()
	var list = $LeaderboardPanel/CenterContainer/VBoxContainer/ScoreList
	list.clear()
	
	if not records is Array:
		print("Leaderboard is not an Array")
		return
		
	var i = 1
	for entry in records:
		# Important: runQuery results are wrapped in a "document" key
		if entry.has("document") and entry.document.has("fields"):
			var fields = entry.document.fields
			if fields.has("player_name") and fields.has("score"):
				var p_name = fields.player_name.stringValue
				var p_score = fields.score.integerValue
				var row = str(i) + ". " + p_name + ": " + str(p_score)
				print(row)
				list.add_item(row)
				i += 1

# Connect this to the "pressed" signal of your CloseButton
func _on_close_button_pressed():
	$LeaderboardPanel.hide()
	return_to_main_menu() # The function we created before
