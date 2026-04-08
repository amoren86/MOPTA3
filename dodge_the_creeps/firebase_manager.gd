extends Node

# --- Configuration Constants ---
const API_KEY: String = "AIzaSyDbRvZzVWviyy3Ox8Gd_gUwBeD9D5ZbgEU"
const PROJECT_ID: String = "dodge-the-creeps-36200"

# Base URLs for Firebase services
const AUTH_URL: String = "https://identitytoolkit.googleapis.com/v1/accounts:"
const FIRESTORE_URL: String = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents/"

# --- Session Data ---
var auth_token: String = ""
var user_id: String = ""
var player_name: String = ""

# Signal to notify when the leaderboard is ready to be displayed
signal leaderboard_received(data)

# --- Helper functions for Headers ---

# Common headers for any JSON request
func get_common_headers() -> Array:
	return ["Content-Type: application/json"]

# Headers requiring authentication for Firestore operations
func get_auth_headers() -> Array:
	return ["Content-Type: application/json", "Authorization: Bearer " + auth_token]

# --- Core Functions ---

# Fetches existing player data (like the name) from Firestore
func fetch_player_data() -> void:
	var url = FIRESTORE_URL + "leaderboard/" + user_id
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(func(_r, response_code, _h, body):
		if response_code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if data.has("fields") and data.fields.has("player_name"):
				player_name = data.fields.player_name.stringValue
				print("Player name retrieved: ", player_name)
		http_request.queue_free()
	)

	http_request.request(url, get_auth_headers(), HTTPClient.METHOD_GET)

# Saves the score only if it is higher than the existing one in Firestore
func save_score_with_name(new_p_score: int, new_p_name: String) -> void:
	player_name = new_p_name
	var url = FIRESTORE_URL + "leaderboard/" + user_id
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(func(_r, response_code, _h, body):
		var should_update = true
		
		# If the document exists, compare scores
		if response_code == 200:
			var existing_data = JSON.parse_string(body.get_string_from_utf8())
			if existing_data.has("fields") and existing_data.fields.has("score"):
				var old_score = int(existing_data.fields.score.integerValue)
				if new_p_score <= old_score:
					should_update = false
					print("New score is not higher than existing high score. Skipping update.")
					fetch_top_scores() # Still refresh to show the leaderboard
		
		if should_update:
			_upload_score_to_firestore(url, new_p_score, new_p_name)
			
		http_request.queue_free()
	)
	
	http_request.request(url, get_auth_headers(), HTTPClient.METHOD_GET)

# Internal helper to perform the actual PATCH request
func _upload_score_to_firestore(url: String, score_to_save: int, name_to_save: String) -> void:
	# Using updateMask to ensure we only overwrite the intended fields
	var mask = "?updateMask.fieldPaths=score&updateMask.fieldPaths=player_name"
	var payload = {
		"fields": {
			"player_name": {"stringValue": name_to_save},
			"score": {"integerValue": str(score_to_save)}
		}
	}
	
	var upload_request = HTTPRequest.new()
	add_child(upload_request)
	
	upload_request.request_completed.connect(func(_r, response_code, _h, _b):
		if response_code == 200:
			print("High score successfully updated.")
		else:
			print("Error updating high score: ", response_code)
		fetch_top_scores()
		upload_request.queue_free()
	)
	
	upload_request.request(url + mask, get_auth_headers(), HTTPClient.METHOD_PATCH, JSON.stringify(payload))

# Fetches the Top 10 scores using a structured query
func fetch_top_scores() -> void:
	# Note: 'runQuery' is a special endpoint for complex searches
	var url = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents:runQuery"

	var query = {
		"structuredQuery": {
			"from": [{"collectionId": "leaderboard"}],
			"orderBy": [{"field": {"fieldPath": "score"}, "direction": "DESCENDING"}],
			"limit": 10
		}
	}

	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(func(_r, response_code, _h, body):
		if response_code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			leaderboard_received.emit(data)
		else:
			# If you see error 400 here, you need to create the Index in Firebase console
			print("Error fetching leaderboard: ", body.get_string_from_utf8())
		http_request.queue_free()
	)

	http_request.request(url, get_auth_headers(), HTTPClient.METHOD_POST, JSON.stringify(query))
