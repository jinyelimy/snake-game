extends Node2D

const GRID_SIZE := 20
const GRID_WIDTH := 24
const GRID_HEIGHT := 24
const BOARD_OFFSET := Vector2i(80, 140)
const START_LENGTH := 3
const BASE_STEP_TIME := 0.15
const MIN_STEP_TIME := 0.07
const SPEED_UP_PER_POINT := 0.008

enum GameState {
	TITLE,
	PLAYING,
	GAME_OVER,
}

var snake: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var pending_direction := Vector2i.RIGHT
var food := Vector2i.ZERO
var score := 0
var best_score := 0
var state := GameState.TITLE
var move_accumulator := 0.0
var rng := RandomNumberGenerator.new()
var should_capture_readme := false


func _ready() -> void:
	rng.randomize()
	should_capture_readme = OS.get_cmdline_user_args().has("--capture-readme")
	if should_capture_readme:
		prepare_readme_capture()
		capture_readme_screenshot.call_deferred()
		return
	queue_redraw()


func reset_game() -> void:
	snake.clear()
	for index in range(START_LENGTH):
		snake.append(Vector2i(5 - index, 8))

	direction = Vector2i.RIGHT
	pending_direction = direction
	score = 0
	state = GameState.PLAYING
	move_accumulator = 0.0
	spawn_food()
	queue_redraw()


func spawn_food() -> void:
	while true:
		var candidate := Vector2i(
			rng.randi_range(0, GRID_WIDTH - 1),
			rng.randi_range(0, GRID_HEIGHT - 1)
		)
		if not snake.has(candidate):
			food = candidate
			return


func _process(delta: float) -> void:
	handle_input()

	if state != GameState.PLAYING:
		queue_redraw()
		return

	move_accumulator += delta
	if move_accumulator >= current_step_time():
		move_accumulator = 0.0
		step()

	queue_redraw()


func handle_input() -> void:
	if Input.is_action_just_pressed("ui_accept") and state != GameState.PLAYING:
		reset_game()
		return

	if state != GameState.PLAYING:
		return

	if Input.is_action_just_pressed("ui_up") and direction != Vector2i.DOWN:
		pending_direction = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down") and direction != Vector2i.UP:
		pending_direction = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left") and direction != Vector2i.RIGHT:
		pending_direction = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right") and direction != Vector2i.LEFT:
		pending_direction = Vector2i.RIGHT


func step() -> void:
	direction = pending_direction
	var next_head := snake[0] + direction
	var will_grow := next_head == food
	var body_to_check := snake.slice(0, snake.size() if will_grow else snake.size() - 1)

	if hit_wall(next_head) or body_to_check.has(next_head):
		best_score = max(best_score, score)
		state = GameState.GAME_OVER
		return

	snake.push_front(next_head)

	if will_grow:
		score += 1
		best_score = max(best_score, score)
		spawn_food()
	else:
		snake.pop_back()


func current_step_time() -> float:
	return max(MIN_STEP_TIME, BASE_STEP_TIME - score * SPEED_UP_PER_POINT)


func prepare_readme_capture() -> void:
	snake = [
		Vector2i(11, 12),
		Vector2i(10, 12),
		Vector2i(9, 12),
		Vector2i(8, 12),
		Vector2i(8, 11),
		Vector2i(8, 10),
	]
	direction = Vector2i.RIGHT
	pending_direction = direction
	food = Vector2i(15, 12)
	score = 7
	best_score = 12
	state = GameState.PLAYING
	move_accumulator = 0.0
	queue_redraw()


func capture_readme_screenshot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://screenshots/gameplay.png")
	get_tree().quit()


func hit_wall(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 or cell.x >= GRID_WIDTH or cell.y >= GRID_HEIGHT


func _draw() -> void:
	draw_background()
	draw_board()
	if state != GameState.TITLE:
		draw_food()
		draw_snake()
	draw_hud()


func draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("f6f1e8"), true)


func draw_board() -> void:
	var board_size := Vector2(GRID_WIDTH * GRID_SIZE, GRID_HEIGHT * GRID_SIZE)
	var board_rect := Rect2(BOARD_OFFSET, board_size)
	draw_rect(board_rect, Color("d9e4c7"), true)
	draw_rect(board_rect, Color("31473a"), false, 4.0)

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var is_even := (x + y) % 2 == 0
			if is_even:
				var cell_pos := BOARD_OFFSET + Vector2i(x * GRID_SIZE, y * GRID_SIZE)
				draw_rect(Rect2(cell_pos, Vector2(GRID_SIZE, GRID_SIZE)), Color("c8d6b3"), true)


func draw_snake() -> void:
	for index in range(snake.size()):
		var segment := snake[index]
		var pos := Vector2(BOARD_OFFSET + segment * GRID_SIZE)
		var color := Color("2f6f4f") if index == 0 else Color("4b9b6e")
		draw_rect(Rect2(pos + Vector2(2, 2), Vector2(GRID_SIZE - 4, GRID_SIZE - 4)), color, true)


func draw_food() -> void:
	var center := BOARD_OFFSET + food * GRID_SIZE + Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)
	draw_circle(center, GRID_SIZE * 0.35, Color("d94f3d"))


func draw_hud() -> void:
	var text_color := Color("1c2b22")
	draw_string(
		ThemeDB.fallback_font,
		Vector2(80, 72),
		"SNAKE GAME",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		32,
		text_color
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(80, 108),
		"Score: %d" % score,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		22,
		text_color
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(240, 108),
		"Best: %d" % best_score,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		22,
		text_color
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(80, 650),
		"Arrow keys to move",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		text_color
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(360, 650),
		"Enter to start",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		text_color
	)

	if state == GameState.TITLE:
		draw_overlay(
			"Ready?",
			"Press Enter to start",
			"Eat apples, avoid walls, and don't hit your tail."
		)
	elif state == GameState.GAME_OVER:
		draw_overlay(
			"Game Over",
			"Press Enter to restart",
			"Your snake reached %d points." % score
		)


func draw_overlay(title: String, subtitle: String, detail: String) -> void:
	draw_rect(Rect2(Vector2(95, 260), Vector2(450, 150)), Color(0, 0, 0, 0.18), true)
	draw_rect(Rect2(Vector2(105, 250), Vector2(430, 160)), Color("f6f1e8"), true)
	draw_rect(Rect2(Vector2(105, 250), Vector2(430, 160)), Color("31473a"), false, 3.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(215, 302),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		32,
		Color("274536")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(170, 340),
		subtitle,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		22,
		Color("1c2b22")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(120, 378),
		detail,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color("47604e")
	)
