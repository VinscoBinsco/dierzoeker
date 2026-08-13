extends Node2D

var min_val: int = 0
var max_val: int = 5
var cell_size: float = 64.0
var origin: Vector2 = Vector2.ZERO

var grid_color := Color(0, 0, 0, 0.15)
var axis_color := Color(0, 0, 0, 0.7)
var font_size := 16


func configure(p_min: int, p_max: int, p_cell_size: float, p_origin: Vector2) -> void:
	min_val = p_min
	max_val = p_max
	cell_size = p_cell_size
	origin = p_origin
	queue_redraw()


func grid_to_pixel(v: Vector2i) -> Vector2:
	return origin + Vector2(v.x * cell_size, -v.y * cell_size)


func _draw() -> void:
	var font := ThemeDB.fallback_font

	# Verticale lijnen + X-as cijfers (onderaan)
	for x in range(min_val, max_val + 1):
		var top := grid_to_pixel(Vector2i(x, max_val))
		var bottom := grid_to_pixel(Vector2i(x, min_val))
		draw_line(top, bottom, grid_color, 1.0)
		
		# Cijfer verder naar beneden (was +20, nu +36)
		var label_pos := grid_to_pixel(Vector2i(x, min_val)) + Vector2(-6, 36)
		draw_string(font, label_pos, str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	# Horizontale lijnen + Y-as cijfers (links)
	for y in range(min_val, max_val + 1):
		var left := grid_to_pixel(Vector2i(min_val, y))
		var right := grid_to_pixel(Vector2i(max_val, y))
		draw_line(left, right, grid_color, 1.0)
		
		# Cijfer verder naar links (was -24, nu -40)
		var label_pos := grid_to_pixel(Vector2i(min_val, y)) + Vector2(-40, 4)
		draw_string(font, label_pos, str(y), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	# Dikke assen...
	if min_val <= 0 and 0 <= max_val:
		draw_line(
			grid_to_pixel(Vector2i(min_val, 0)),
			grid_to_pixel(Vector2i(max_val, 0)),
			axis_color, 3.0
		)
		draw_line(
			grid_to_pixel(Vector2i(0, min_val)),
			grid_to_pixel(Vector2i(0, max_val)),
			axis_color, 3.0
		)
