extends Node

@onready var email_input = $MarginContainer/VBoxContainer/EmailInput
@onready var password_input = $MarginContainer/VBoxContainer/PasswordInput
@onready var login_button = $MarginContainer/VBoxContainer/LoginButton
@onready var error_label = $MarginContainer/VBoxContainer/ErrorLabel
@onready var http_request = $HTTPRequest

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	http_request.request_completed.connect(_on_request_completed)

func _on_login_pressed():
	var email = email_input.text
	var password = password_input.text
	
	if email.is_empty() or password.is_empty():
		error_label.text = "Please fill in all fields."
		return

	# Build the auth URL using the Manager's constants
	var url = FirebaseManager.AUTH_URL + "signInWithPassword?key=" + FirebaseManager.API_KEY

	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	
	# Send the request using the Manager's common headers
	http_request.request(
		url, 
		FirebaseManager.get_common_headers(), 
		HTTPClient.METHOD_POST, 
		JSON.stringify(body)
	)

func _on_request_completed(_result, response_code, _headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())

	if response_code == 200:
		# Store session data in the Singleton
		FirebaseManager.auth_token = data["idToken"]
		FirebaseManager.user_id = data["localId"]

		# Fetch existing user data (like name) before switching scenes
		FirebaseManager.fetch_player_data()
		
		print("Login successful. Moving to Main scene.")
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		# Display detailed error message from Firebase if available
		var error_message;
		if data and data.has("error"):
			error_message = data["error"]["message"]
			# Replace underscores with spaces and capitalize for better look
			error_message = error_message.replace("_", " ").capitalize()
		else:
			error_message = "Login failed. Check your connection."
		error_label.text = error_message
