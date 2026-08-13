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

const ANIMAL_TEXTURES: Array[PackedScene] = [
	BEE, CHICKEN, COW, DUCK, FROG, GOOSE, HORSE, PIG, SHEEP, SWAN]

const EASY_MIN := 0
const EASY_MAX := 5
const HARD_MIN := -5
const HARD_MAX := 5

@export var cell_size: float = 90.0
@export var num_animals: int = 6
@export var top_margin: float = 100.0
@export var bottom_margin: float = 160.0
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

const ACTIVE_COLOR := Color(0.3, 0.75, 0.3)
const INACTIVE_COLOR := Color(0.6, 0.6, 0.6)


func _ready() -> void:
	randomize()
	_setup_range()
	_compute_origin()
	_layout_ui()
	axis_grid.configure(min_val, max_val, cell_size, origin)
	_spawn_animals()
	_connect_buttons()
	pick_new_target()


func _layout_ui() -> void:
	var viewport_size := get_viewport_rect().size

	# === TOPBAR POSITIE & ACHTERGROND (ORANJE) ===
	top_bar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar_container.position = Vector2(20, 15)
	top_bar_container.size = Vector2(viewport_size.x - 40, 55)
	top_bar_container.add_theme_constant_override("separation", 20)
	
	# Maak oranje achtergrondvlak aan
	var top_bg: ColorRect = top_bar_container.get_node_or_null("TopBG") as ColorRect
	if not top_bg:
		top_bg = ColorRect.new()
		top_bg.name = "TopBG"
		top_bar_container.add_child(top_bg)
		top_bar_container.move_child(top_bg, 0)
	top_bg.show_behind_parent = true
	top_bg.color = Color("ff9f43") # Warm oranje
	top_bg.size = top_bar_container.size

	target_sprite.custom_minimum_size = Vector2(45, 45)
	target_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	for child in top_bar_container.get_children():
		if child is Label:
			child.add_theme_font_size_override("font_size", 22)

	# === BOTTOMBAR POSITIE & ACHTERGROND (BLAUW) ===
	var bar_height := 65.0
	bottom_bar.position = Vector2(20, viewport_size.y - bar_height - 15)
	bottom_bar.size = Vector2(viewport_size.x - 40, bar_height)
	bottom_bar.add_theme_constant_override("separation", 8)
	
	# Maak blauw achtergrondvlak aan
	var bottom_bg: ColorRect = bottom_bar.get_node_or_null("BottomBG") as ColorRect
	if not bottom_bg:
		bottom_bg = ColorRect.new()
		bottom_bg.name = "BottomBG"
		bottom_bar.add_child(bottom_bg)
		bottom_bar.move_child(bottom_bg, 0)
	bottom_bg.show_behind_parent = true
	bottom_bg.color = Color("2e86de") # Speels blauw
	bottom_bg.size = bottom_bar.size

	for child in bottom_bar.get_children():
		if child is Button:
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.custom_minimum_size.y = bar_height - 10
			child.add_theme_font_size_override("font_size", 20)


func _setup_range() -> void:
	var difficulty := "easy"
	if "difficulty" in Global:
		difficulty = Global.difficulty
	if difficulty == "hard":
		min_val = HARD_MIN
		max_val = HARD_MAX
		cell_size = 50.0
	else:
		min_val = EASY_MIN
		max_val = EASY_MAX
		cell_size = 90.0
		
	sign_button.visible = difficulty == "hard"
	sign_button.disabled = difficulty != "hard"


func _compute_origin() -> void:
	var viewport_size := get_viewport_rect().size
	var span := float(max_val - min_val)
	var grid_width := span * cell_size
	var grid_height := span * cell_size
	
	# Verhoogde top_margin zodat het raster onder de TopBar begint
	var custom_top_margin := 110.0
	var custom_bottom_margin := 100.0
	
	var usable_width := viewport_size.x - side_margin * 2.0
	var usable_height := viewport_size.y - custom_top_margin - custom_bottom_margin

	var start_x := side_margin + (usable_width - grid_width) / 2.0
	var start_y := custom_top_margin + (usable_height + grid_height) / 2.0

	origin = Vector2(start_x - min_val * cell_size, start_y + min_val * cell_size)


func grid_to_pixel(v: Vector2i) -> Vector2:
	return origin + Vector2(v.x * cell_size, -v.y * cell_size)


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
		while used_positions.has(pos):
			pos = Vector2i(
				randi_range(min_val, max_val),
				randi_range(min_val, max_val)
			)
		used_positions[pos] = true

		var animal_scene: PackedScene = available_scenes[i]
		var animal_instance := animal_scene.instantiate() as Node2D
		animal_instance.position = grid_to_pixel(pos)
		animals_root.add_child(animal_instance)

		spawned_animals.append({"scene": animal_scene, "instance": animal_instance, "grid_pos": pos})

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
	_show_feedback("Gefeliciteerd! Je hebt alle dieren gevonden!", Color(0.2, 0.8, 0.2))
	enter_button.disabled = true


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
		_show_feedback("Goed zo!", Color(0.2, 0.7, 0.2))
		enter_button.disabled = true
		await get_tree().create_timer(1.0).timeout
		enter_button.disabled = false
		pick_new_target()
	else:
		_show_feedback("Nog niet helemaal goed, probeer opnieuw!", Color(0.8, 0.2, 0.2))
		x_string = ""
		y_string = ""
		sign_x = false
		sign_y = false
		active_field = "x"
		_update_display()


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color


func _update_display() -> void:
	var x_display := x_string if x_string != "" else "_"
	var y_display := y_string if y_string != "" else "_"
	
	x_value_label.text = ("-" if sign_x else "") + x_display
	y_value_label.text = ("-" if sign_y else "") + y_display

	x_value_label.modulate = ACTIVE_COLOR if active_field == "x" else INACTIVE_COLOR
	y_value_label.modulate = ACTIVE_COLOR if active_field == "y" else INACTIVE_COLOR
