extends Control

const MAIN = preload("uid://bq0fi1xc3y0lt")


# Paden relatief aan de root Control node
@onready var easy_button: Button = $CenterContainer/VBoxContainer/EasyButton
@onready var hard_button: Button = $CenterContainer/VBoxContainer/HardButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel

const ACCENT_ORANGE := Color("ff9f43")
const ACCENT_BLUE := Color("2e86de")
const DARK_BG := Color("2d3436")
const LIGHT_TEXT := Color("f5f6fa")
const EASY_GREEN := Color("27ae60")
const HARD_RED := Color("c0392b")


func _ready() -> void:
	print("=== START SCREEN READY ===")
	
	# Check of nodes bestaan
	if easy_button == null:
		push_error("EasyButton niet gevonden!")
	else:
		print("EasyButton gevonden: ", easy_button.name)
		
	if hard_button == null:
		push_error("HardButton niet gevonden!")
	else:
		print("HardButton gevonden: ", hard_button.name)
	
	_style_ui()
	_connect_buttons()


func _style_ui() -> void:
	# Title styling
	if title_label:
		title_label.add_theme_font_size_override("font_size", 64)
		title_label.add_theme_color_override("font_color", ACCENT_ORANGE)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Subtitle styling
	if subtitle_label:
		subtitle_label.add_theme_font_size_override("font_size", 24)
		subtitle_label.add_theme_color_override("font_color", LIGHT_TEXT)
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Easy button
	if easy_button:
		_style_difficulty_button(easy_button, EASY_GREEN, "Makkelijk", "")
	
	# Hard button  
	if hard_button:
		_style_difficulty_button(hard_button, HARD_RED, "Moeilijk", "")


func _style_difficulty_button(btn: Button, accent_color: Color, title: String, subtitle: String) -> void:
	btn.custom_minimum_size = Vector2(300, 100)
	
	# Maak een eigen donkerdere achtergrond gebaseerd op de accentkleur
	var custom_dark_bg := accent_color.darkened(0.2)
	
	# Normal state
	var normal := StyleBoxFlat.new()
	normal.bg_color = custom_dark_bg
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("normal", normal)
	
	# Hover state (iets lichter dan normal, maar nog steeds gedimd)
	var hover := StyleBoxFlat.new()
	hover.bg_color = accent_color.darkened(0.05)
	hover.corner_radius_top_left = 16
	hover.corner_radius_top_right = 16
	hover.corner_radius_bottom_left = 16
	hover.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("hover", hover)
	
	# Pressed state (extra donker)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = accent_color.darkened(0.4)
	pressed.corner_radius_top_left = 16
	pressed.corner_radius_top_right = 16
	pressed.corner_radius_bottom_left = 16
	pressed.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("pressed", pressed)
	
	# Font
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", LIGHT_TEXT)
	
	# Text opbouwen met newline
	btn.text = title + "\n" + subtitle


func _connect_buttons() -> void:
	if easy_button:
		# Eerst disconnecten als er al een connectie is (voor de zekerheid)
		if easy_button.pressed.is_connected(_on_easy_pressed):
			easy_button.pressed.disconnect(_on_easy_pressed)
		easy_button.pressed.connect(_on_easy_pressed)
		print("EasyButton connected")
	
	if hard_button:
		if hard_button.pressed.is_connected(_on_hard_pressed):
			hard_button.pressed.disconnect(_on_hard_pressed)
		hard_button.pressed.connect(_on_hard_pressed)
		print("HardButton connected")


func _on_easy_pressed() -> void:
	print(">>> EASY BUTTON PRESSED <<<")
	Global.difficulty = "easy"
	_start_game()


func _on_hard_pressed() -> void:
	print(">>> HARD BUTTON PRESSED <<<")
	Global.difficulty = "hard"
	_start_game()


func _start_game() -> void:
	print("Starting game with difficulty: ", Global.difficulty)
	
	# Check of Main.tscn bestaat
	if ResourceLoader.exists("res://scenes/main.tscn"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		push_error("Main.tscn niet gevonden! Zorg dat het bestand in de root staat.")
