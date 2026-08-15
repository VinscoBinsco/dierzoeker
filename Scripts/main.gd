extends Node2D

# Animals
const BEE = preload("uid://r75ikkgmpjvn")
const CHICKEN = preload("uid://ctq85pm8nvf17")
const COW = preload("uid://bhor8b2wcegpo")
const DUCK = preload("uid://dmvi88b4xt1w6")
const FROG = preload("uid://irfclpxgogvy")
const GOOSE = preload("uid://duace61kyw3h2")
const HORSE = preload("uid://b0kdmt3bk35pi")
const PIG = preload("uid://nus2ckkhjqic")
const SHEEP = preload("uid://cvg5wnl2g7mc5")
const SWAN = preload("uid://2jg1h83xyb88")
const START_SCREEN = preload("uid://dn2ebvj0ahjs2")  

# Sounds
const CORRECT_SOUND = preload("res://chrisiex1-correct-156911.mp3")
const VICTORY_SOUND = preload("res://emand_edroff-victory-bell-success-fanfare-576275.mp3")

const ANIMAL_TEXTURES: Array[PackedScene] = [
	BEE, CHICKEN, COW, DUCK, FROG, GOOSE, HORSE, PIG, SHEEP, SWAN]

const EASY_MIN := 0
const EASY_MAX := 5
const HARD_MIN := -5
const HARD_MAX := 5

@export var cell_size: float = 75.0
@export var num_animals: int = 6
@export var side_margin: float = 40.0

@onready var axis_grid: Node2D = $AxisGrid
@onready var animals_root: Node2D = $Animals

# TopBar UI Nodes
@onready var top_bar_container: HBoxContainer = $UI/TopBar/TopBar
@onready var target_sprite: TextureRect = $UI/TopBar/TopBar/TargetSprite
@onready var x_value_label: Label = $UI/TopBar/TopBar/XValueLabel
@onready var y_value_label: Label = $UI/TopBar/TopBar/YValueLabel
@onready var feedback_label: Label = $UI/TopBar/TopBar/FeedbackLabel

# BottomBar UI Nodes
@onready var bottom_bar: HBoxContainer = $UI/BottomBar
@onready var sign_button: Button = $UI/BottomBar/SignButton
@onready var backspace_button: Button = $UI/BottomBar/BackspaceButton
@onready var enter_button: Button = $UI/BottomBar/EnterButton
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var min_val: int = EASY_MIN
var max_val: int = EASY_MAX
var origin: Vector2 = Vector2.ZERO

var spawned_animals: Array = []  
var unasked_animals: Array = []  
var target_animal: Dictionary = {}

var x_string: String = ""
var y_string: String = ""
var sign_x: bool = false
var sign_y: bool = false
var active_field: String = "x"

const ACTIVE_COLOR := Color(0.35, 0.95, 0.4)
const INACTIVE_COLOR := Color(0.541, 0.906, 0.216, 1.0)
const ACCENT_BLUE := Color("2e86de")
const ACCENT_ORANGE := Color("ff9f43")
const DARK_BG := Color("2d3436")
const LIGHT_TEXT := Color("f5f6fa")

# Nieuwe nodes (worden aangemaakt in _style_ui)
var back_button: Button
var fullscreen_button: Button
var feedback_bg: Panel
var victory_overlay: Panel
var victory_label: Label


func _ready() -> void:
	randomize()
	_setup_range()
	_create_victory_overlay()
	_layout_ui()
	_compute_origin()
	axis_grid.configure(min_val, max_val, cell_size, origin)
	_spawn_animals()
	_connect_buttons()
	_style_ui()
	pick_new_target()
	
	get_tree().root.size_changed.connect(_on_window_resized)


func _on_window_resized() -> void:
	_layout_ui()
	_compute_origin()
	axis_grid.configure(min_val, max_val, cell_size, origin)
	
	for animal in spawned_animals:
		var pos: Vector2i = animal["grid_pos"]
		var instance: Node2D = animal["instance"]
		if is_instance_valid(instance):
			instance.position = grid_to_pixel(pos)


# ═══════════════════════════════════════════════════════════════
#  STYLING
# ═══════════════════════════════════════════════════════════════

func _style_ui() -> void:
	# ── TopBar achtergrond (als sibling) ──
	var top_bar_parent := top_bar_container.get_parent()
	var top_bg: Panel = top_bar_parent.get_node_or_null("TopBG") as Panel
	if not top_bg:
		top_bg = Panel.new()
		top_bg.name = "TopBG"
		top_bar_parent.add_child(top_bg)
		top_bar_parent.move_child(top_bg, top_bar_parent.get_children().find(top_bar_container))
	
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = ACCENT_ORANGE
	top_style.corner_radius_top_left = 16
	top_style.corner_radius_top_right = 16
	top_style.corner_radius_bottom_left = 16
	top_style.corner_radius_bottom_right = 16
	top_style.shadow_color = Color(0, 0, 0, 0.25)
	top_style.shadow_size = 8
	top_style.shadow_offset = Vector2(0, 3)
	top_bg.add_theme_stylebox_override("panel", top_style)
	
	# ── BottomBar achtergrond (als sibling) ──
	var bottom_bar_parent := bottom_bar.get_parent()
	var bottom_bg: Panel = bottom_bar_parent.get_node_or_null("BottomBG") as Panel
	if not bottom_bg:
		bottom_bg = Panel.new()
		bottom_bg.name = "BottomBG"
		bottom_bar_parent.add_child(bottom_bg)
		bottom_bar_parent.move_child(bottom_bg, bottom_bar_parent.get_children().find(bottom_bar))
	
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = ACCENT_BLUE
	bottom_style.corner_radius_top_left = 16
	bottom_style.corner_radius_top_right = 16
	bottom_style.corner_radius_bottom_left = 16
	bottom_style.corner_radius_bottom_right = 16
	bottom_style.shadow_color = Color(0, 0, 0, 0.25)
	bottom_style.shadow_size = 8
	bottom_style.shadow_offset = Vector2(0, -3)
	bottom_bg.add_theme_stylebox_override("panel", bottom_style)
	
	# ── Terug-knop (links boven de TopBar) ──
	_create_back_button(top_bar_parent)
	
	# ── Volledig-scherm-knop (naast de terug-knop) ──
	_create_fullscreen_button(top_bar_parent)
	
	# ── Feedback achtergrond (mooi paneel achter feedback tekst) ──
	_create_feedback_background(top_bar_parent)
	
	# ── Knoppen styling ──
	for child in bottom_bar.get_children():
		if child is Button:
			_style_button(child)
	
	# ── Invulvakjes X / Y ──
	_style_value_label(x_value_label)
	_style_value_label(y_value_label)
	
	# ── "Zoek:" label ──
	var search_label := top_bar_container.get_node_or_null("SearchLabel") as Label
	if search_label:
		search_label.add_theme_font_size_override("font_size", 28)
		search_label.add_theme_color_override("font_color", LIGHT_TEXT)
	
	# ── "X:" en "Y:" labels ──
	var x_label := top_bar_container.get_node_or_null("XLabelStatic") as Label
	var y_label := top_bar_container.get_node_or_null("YLabelStatic") as Label
	if x_label:
		x_label.add_theme_font_size_override("font_size", 26)
		x_label.add_theme_color_override("font_color", LIGHT_TEXT)
	if y_label:
		y_label.add_theme_font_size_override("font_size", 26)
		y_label.add_theme_color_override("font_color", LIGHT_TEXT)
	
	# ── Feedback label ──
	feedback_label.add_theme_font_size_override("font_size", 22)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# ── Doel-sprite 1.5× groter ──
	target_sprite.custom_minimum_size = Vector2(68, 68)
	target_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _create_back_button(parent: Node) -> void:
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Menu"
	back_button.custom_minimum_size = Vector2(90, 40)
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var style := StyleBoxFlat.new()
	style.bg_color = DARK_BG
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = LIGHT_TEXT
	back_button.add_theme_stylebox_override("normal", style)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = DARK_BG.lightened(0.2)
	hover.corner_radius_top_left = 10
	hover.corner_radius_top_right = 10
	hover.corner_radius_bottom_left = 10
	hover.corner_radius_bottom_right = 10
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = ACCENT_ORANGE
	back_button.add_theme_stylebox_override("hover", hover)
	
	back_button.add_theme_font_size_override("font_size", 16)
	back_button.add_theme_color_override("font_color", LIGHT_TEXT)
	
	parent.add_child(back_button)
	back_button.position = Vector2(15, 15)
	back_button.pressed.connect(_on_back_pressed)


func _create_fullscreen_button(parent: Node) -> void:
	fullscreen_button = Button.new()
	fullscreen_button.name = "FullscreenButton"
	fullscreen_button.text = "⛶"
	fullscreen_button.tooltip_text = "Volledig scherm"
	fullscreen_button.custom_minimum_size = Vector2(50, 40)
	fullscreen_button.focus_mode = Control.FOCUS_NONE
	fullscreen_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style := StyleBoxFlat.new()
	style.bg_color = DARK_BG
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = LIGHT_TEXT
	fullscreen_button.add_theme_stylebox_override("normal", style)

	var hover := StyleBoxFlat.new()
	hover.bg_color = DARK_BG.lightened(0.2)
	hover.corner_radius_top_left = 10
	hover.corner_radius_top_right = 10
	hover.corner_radius_bottom_left = 10
	hover.corner_radius_bottom_right = 10
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = ACCENT_ORANGE
	fullscreen_button.add_theme_stylebox_override("hover", hover)

	fullscreen_button.add_theme_font_size_override("font_size", 22)
	fullscreen_button.add_theme_color_override("font_color", LIGHT_TEXT)

	parent.add_child(fullscreen_button)
	# Rechts naast de Menu-knop (die staat op x=15, breedte 90)
	fullscreen_button.position = Vector2(15 + 90 + 10, 15)
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)


func _on_fullscreen_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _create_feedback_background(parent: Node) -> void:
	feedback_bg = Panel.new()
	feedback_bg.name = "FeedbackBG"
	feedback_bg.visible = false  # Alleen zichtbaar als er feedback is
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	feedback_bg.add_theme_stylebox_override("panel", style)
	
	parent.add_child(feedback_bg)
	
	# Positioneer achter de feedback_label (wordt bijgewerkt in _layout_ui)


func _create_victory_overlay() -> void:
	# Overlay voor "Goed gedaan!" scherm
	victory_overlay = Panel.new()
	victory_overlay.name = "VictoryOverlay"
	victory_overlay.visible = false
	victory_overlay.z_index = 100  # Boven alles

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	victory_overlay.add_theme_stylebox_override("panel", style)

	victory_label = Label.new()
	victory_label.name = "VictoryLabel"
	victory_label.text = "Goed gedaan!\n\nJe hebt alle dieren gevonden!"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 48)
	victory_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.4))

	victory_overlay.add_child(victory_label)
	add_child(victory_overlay)

	# Direct al een fatsoenlijke full-screen size/positie geven,
	# zodat het nooit linksboven blijft hangen ongeacht call-volgorde.
	_position_victory_overlay()


func _position_victory_overlay() -> void:
	if not victory_overlay or not victory_label:
		return
	var viewport_size := get_viewport_rect().size
	victory_overlay.size = viewport_size
	victory_overlay.position = Vector2.ZERO
	victory_label.size = Vector2(viewport_size.x, 200)
	victory_label.position = Vector2(0, viewport_size.y / 2 - 100)


func _style_value_label(lbl: Label) -> void:
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", LIGHT_TEXT)
	lbl.custom_minimum_size = Vector2(44, 44)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _style_button(btn: Button) -> void:
	var base_color := DARK_BG
	
	if btn == enter_button:
		base_color = Color("27ae60")
	elif btn == backspace_button:
		base_color = Color("c0392b")
	elif btn == sign_button:
		base_color = Color("8e44ad")
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = base_color.lightened(0.12)
	hover.corner_radius_top_left = 10
	hover.corner_radius_top_right = 10
	hover.corner_radius_bottom_left = 10
	hover.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = base_color.darkened(0.2)
	pressed.corner_radius_top_left = 10
	pressed.corner_radius_top_right = 10
	pressed.corner_radius_bottom_left = 10
	pressed.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", LIGHT_TEXT)


# ═══════════════════════════════════════════════════════════════
#  LAYOUT & GRID
# ═══════════════════════════════════════════════════════════════

func _layout_ui() -> void:
	var viewport_size := get_viewport_rect().size

	# TopBar
	top_bar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar_container.position = Vector2(20, 15)
	top_bar_container.size = Vector2(viewport_size.x - 40, 75)
	top_bar_container.add_theme_constant_override("separation", 28)
	
	# TopBar achtergrond mee-schalen
	var top_bar_parent := top_bar_container.get_parent()
	var top_bg := top_bar_parent.get_node_or_null("TopBG") as Panel
	if top_bg:
		top_bg.position = top_bar_container.position - Vector2(8, 8)
		top_bg.size = top_bar_container.size + Vector2(16, 16)

	# BottomBar
	var bar_height := 80.0
	bottom_bar.position = Vector2(20, viewport_size.y - bar_height - 15)
	bottom_bar.size = Vector2(viewport_size.x - 40, bar_height)
	bottom_bar.add_theme_constant_override("separation", 10)
	
	# BottomBar achtergrond mee-schalen
	var bottom_bar_parent := bottom_bar.get_parent()
	var bottom_bg := bottom_bar_parent.get_node_or_null("BottomBG") as Panel
	if bottom_bg:
		bottom_bg.position = bottom_bar.position - Vector2(8, 8)
		bottom_bg.size = bottom_bar.size + Vector2(16, 16)

	for child in bottom_bar.get_children():
		if child is Button:
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.custom_minimum_size.y = bar_height - 16
	
	# Feedback achtergrond positioneren achter feedback_label
	if feedback_bg and feedback_label:
		var feedback_size := Vector2(feedback_label.size.x + 24, feedback_label.size.y + 16)
		feedback_bg.size = feedback_size
		feedback_bg.position = feedback_label.global_position - Vector2(12, 8)
	
	# Victory overlay full screen
	_position_victory_overlay()


func _setup_range() -> void:
	var difficulty := "easy"
	if "difficulty" in Global:
		difficulty = Global.difficulty
	if difficulty == "hard":
		min_val = HARD_MIN
		max_val = HARD_MAX
		cell_size = 45.0
	else:
		min_val = EASY_MIN
		max_val = EASY_MAX
		cell_size = 75.0
		
	sign_button.visible = difficulty == "hard"
	sign_button.disabled = difficulty != "hard"


func _compute_origin() -> void:
	var viewport_size := get_viewport_rect().size
	var span := float(max_val - min_val)
	var grid_width := span * cell_size
	var grid_height := span * cell_size
	
	var effective_top := top_bar_container.position.y + top_bar_container.size.y + 10.0
	var effective_bottom := bottom_bar.position.y - 40.0
	var usable_height := effective_bottom - effective_top
	var usable_width := viewport_size.x - side_margin * 2.0

	var start_x := side_margin + (usable_width - grid_width) / 2.0
	var start_y := effective_top + (usable_height + grid_height) / 2.0 - 30.0

	origin = Vector2(start_x - min_val * cell_size, start_y + min_val * cell_size)


func grid_to_pixel(v: Vector2i) -> Vector2:
	return origin + Vector2(v.x * cell_size, -v.y * cell_size)


# ═══════════════════════════════════════════════════════════════
#  GAMEPLAY
# ═══════════════════════════════════════════════════════════════

func _spawn_animals() -> void:
	for child in animals_root.get_children():
		child.queue_free()
	spawned_animals.clear()

	var used_positions: Dictionary = {}
	var available_scenes: Array = ANIMAL_TEXTURES.duplicate()
	available_scenes.shuffle()
	
	var count: int = min(num_animals, available_scenes.size())
	count = min(count, (max_val - min_val + 1) * (max_val - min_val + 1))

	for i in range(count):
		var pos := Vector2i(
			randi_range(min_val, max_val),
			randi_range(min_val, max_val)
		)
		# === GEEN DIEREN OP DE RANDEN VAN HET GRID ===
		while used_positions.has(pos) or pos.y == max_val or pos.y == min_val:
			pos = Vector2i(
				randi_range(min_val, max_val),
				randi_range(min_val, max_val)
			)
		used_positions[pos] = true

		var animal_scene: PackedScene = available_scenes[i]
		var animal_instance := animal_scene.instantiate() as Node2D
		animal_instance.position = grid_to_pixel(pos)
		animals_root.add_child(animal_instance)

		spawned_animals.append({
			"scene": animal_scene, 
			"instance": animal_instance, 
			"grid_pos": pos
		})

	unasked_animals = spawned_animals.duplicate()


func _connect_buttons() -> void:
	for child in bottom_bar.get_children():
		if child is Button and child.name.begins_with("Digit"):
			var digit := int(child.name.substr(5))
			if not child.pressed.is_connected(_on_digit_pressed):
				child.pressed.connect(_on_digit_pressed.bind(digit))

	if not sign_button.pressed.is_connected(_on_sign_pressed):
		sign_button.pressed.connect(_on_sign_pressed)
	if not backspace_button.pressed.is_connected(_on_backspace_pressed):
		backspace_button.pressed.connect(_on_backspace_pressed)
	if not enter_button.pressed.is_connected(_on_enter_pressed):
		enter_button.pressed.connect(_on_enter_pressed)


func pick_new_target() -> void:
	if unasked_animals.is_empty():
		_game_over()
		return

	var random_index := randi_range(0, unasked_animals.size() - 1)
	target_animal = unasked_animals[random_index]
	unasked_animals.remove_at(random_index)

	var inst := target_animal["instance"] as Node2D
	var anim_sprite: AnimatedSprite2D = null
	
	if inst is AnimatedSprite2D:
		anim_sprite = inst as AnimatedSprite2D
	elif inst.has_node("AnimatedSprite2D"):
		anim_sprite = inst.get_node("AnimatedSprite2D") as AnimatedSprite2D
	else:
		anim_sprite = inst.find_child("*", true, false) as AnimatedSprite2D

	if anim_sprite and anim_sprite.sprite_frames:
		var current_anim := anim_sprite.animation
		target_sprite.texture = anim_sprite.sprite_frames.get_frame_texture(current_anim, 0)

	x_string = ""
	y_string = ""
	sign_x = false
	sign_y = false
	active_field = "x"
	feedback_label.text = ""
	_update_display()


func _game_over() -> void:
	target_sprite.texture = null
	x_string = ""
	y_string = ""
	_update_display()
	
	# Toon victory overlay in plaats van alleen feedback
	_show_victory_screen()


func _show_victory_screen() -> void:
	if victory_overlay:
		_position_victory_overlay()
		victory_overlay.visible = true
		victory_overlay.modulate = Color(1, 1, 1, 0)

		audio_stream_player_2d.stream = VICTORY_SOUND
		audio_stream_player_2d.play()
		
		# Fade in animatie
		var tween := create_tween()
		tween.tween_property(victory_overlay, "modulate", Color(1, 1, 1, 1), 0.5)
		
		# Na 5 seconden terug naar menu
		await get_tree().create_timer(5.0).timeout
		_return_to_menu()


func _return_to_menu() -> void:
	print("menu")
	if START_SCREEN:
		get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	else:
		push_error("Start screen kon niet worden geladen!")


func _on_back_pressed() -> void:
	_return_to_menu()


func _on_digit_pressed(digit: int) -> void:
	if active_field == "x":
		x_string = str(digit)
		active_field = "y"
	else:
		y_string = str(digit)
	_update_display()


func _on_backspace_pressed() -> void:
	if active_field == "y":
		if y_string != "":
			y_string = ""
		else:
			active_field = "x"
			x_string = ""
	else:
		x_string = ""
	_update_display()


func _on_sign_pressed() -> void:
	if not sign_button.visible:
		return
	if active_field == "x":
		sign_x = not sign_x
	else:
		sign_y = not sign_y
	_update_display()


func _on_enter_pressed() -> void:
	if x_string == "" or y_string == "":
		_show_feedback("Vul zowel X als Y in!", Color.ORANGE)
		return

	var val_x := int(x_string) * (-1 if sign_x else 1)
	var val_y := int(y_string) * (-1 if sign_y else 1)

	if Vector2i(val_x, val_y) == target_animal["grid_pos"]:
		_show_feedback("Goed zo!", Color(0.2, 0.9, 0.2))
		audio_stream_player_2d.stream = CORRECT_SOUND
		audio_stream_player_2d.play()
		enter_button.disabled = true
		await get_tree().create_timer(1.0).timeout
		enter_button.disabled = false
		pick_new_target()
	else:
		_show_feedback("Nog niet helemaal goed, probeer opnieuw!", Color(0.9, 0.2, 0.2))
		x_string = ""
		y_string = ""
		sign_x = false
		sign_y = false
		active_field = "x"
		_update_display()


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	
	# Toon achtergrond paneel
	if feedback_bg:
		feedback_bg.visible = true
		feedback_bg.modulate = Color(1, 1, 1, 1)
	
	# Verberg na 2 seconden
	await get_tree().create_timer(2.0).timeout
	if feedback_bg:
		feedback_bg.visible = false
	feedback_label.text = ""


func _update_display() -> void:
	var x_display := x_string if x_string != "" else "_"
	var y_display := y_string if y_string != "" else "_"
	
	x_value_label.text = ("-" if sign_x else "") + x_display
	y_value_label.text = ("-" if sign_y else "") + y_display

	x_value_label.modulate = ACTIVE_COLOR if active_field == "x" else INACTIVE_COLOR
	y_value_label.modulate = ACTIVE_COLOR if active_field == "y" else INACTIVE_COLOR
