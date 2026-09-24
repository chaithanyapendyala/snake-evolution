extends Node2D

const CELL_SIZE = 24
const GRID_WIDTH = 30
const GRID_HEIGHT = 21
const HUD_HEIGHT = 40

# Starting speed
# Bigger number = slower snake
const START_MOVE_INTERVAL = 0.25

# Fastest speed the snake can reach
const MIN_MOVE_INTERVAL = 0.08

# Speed increase after eating food
const SPEED_INCREASE = 0.01


var snake = []
var direction = Vector2i.RIGHT
var next_direction = Vector2i.RIGHT

var food = Vector2i.ZERO

var score = 0

var move_timer = 0.0
var move_interval = START_MOVE_INTERVAL

var game_over = false
var paused = false

var rng = RandomNumberGenerator.new()

var score_label
var message_label


func _ready():
	rng.randomize()

	score_label = Label.new()
	score_label.position = Vector2(15, 8)
	score_label.add_theme_font_size_override("font_size", 20)
	add_child(score_label)

	message_label = Label.new()
	message_label.position = Vector2(0, 240)
	message_label.size = Vector2(GRID_WIDTH * CELL_SIZE, 100)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 24)
	add_child(message_label)

	restart_game()


func _process(delta):
	if game_over or paused:
		queue_redraw()
		return

	move_timer += delta

	if move_timer >= move_interval:
		move_timer = 0.0
		move_snake()

	queue_redraw()


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:

		match event.keycode:

			KEY_UP, KEY_W:
				if direction != Vector2i.DOWN:
					next_direction = Vector2i.UP

			KEY_DOWN, KEY_S:
				if direction != Vector2i.UP:
					next_direction = Vector2i.DOWN

			KEY_LEFT, KEY_A:
				if direction != Vector2i.RIGHT:
					next_direction = Vector2i.LEFT

			KEY_RIGHT, KEY_D:
				if direction != Vector2i.LEFT:
					next_direction = Vector2i.RIGHT

			KEY_SPACE:
				if not game_over:
					paused = not paused
					update_message()

			KEY_R:
				restart_game()


func restart_game():

	snake.clear()

	var start_x = int(GRID_WIDTH / 2)
	var start_y = int(GRID_HEIGHT / 2)

	snake.append(Vector2i(start_x, start_y))
	snake.append(Vector2i(start_x - 1, start_y))
	snake.append(Vector2i(start_x - 2, start_y))

	direction = Vector2i.RIGHT
	next_direction = Vector2i.RIGHT

	score = 0
	move_timer = 0.0

	# Reset to slow starting speed
	move_interval = START_MOVE_INTERVAL

	game_over = false
	paused = false

	spawn_food()

	update_ui()
	update_message()

	queue_redraw()


func move_snake():

	direction = next_direction

	var new_head = snake[0] + direction

	# Wall collision
	if new_head.x < 0 or new_head.x >= GRID_WIDTH:
		end_game()
		return

	if new_head.y < 0 or new_head.y >= GRID_HEIGHT:
		end_game()
		return

	var eating = new_head == food

	# Check collision with snake body
	var last_body_index = snake.size() - 1

	if not eating:
		last_body_index -= 1

	for i in range(last_body_index + 1):

		if snake[i] == new_head:
			end_game()
			return

	snake.push_front(new_head)

	if eating:

		score += 10

		# Increase speed after eating food
		move_interval = max(
			MIN_MOVE_INTERVAL,
			move_interval - SPEED_INCREASE
		)

		spawn_food()

	else:

		snake.pop_back()

	update_ui()


func spawn_food():

	var empty_cells = []

	for y in range(GRID_HEIGHT):

		for x in range(GRID_WIDTH):

			var cell = Vector2i(x, y)

			if not snake.has(cell):
				empty_cells.append(cell)

	if empty_cells.is_empty():
		end_game()
		return

	var random_index = rng.randi_range(
		0,
		empty_cells.size() - 1
	)

	food = empty_cells[random_index]


func end_game():

	game_over = true

	update_message()

	queue_redraw()


func update_ui():

	score_label.text = "Score: " + str(score)


func update_message():

	if game_over:

		message_label.text = "GAME OVER\nPress R to restart"

	elif paused:

		message_label.text = "PAUSED\nPress SPACE to continue"

	else:

		message_label.text = ""


func _draw():

	# Background
	draw_rect(
		Rect2(
			0,
			HUD_HEIGHT,
			GRID_WIDTH * CELL_SIZE,
			GRID_HEIGHT * CELL_SIZE
		),
		Color("#101820")
	)

	# Vertical grid lines
	for x in range(GRID_WIDTH + 1):

		var px = x * CELL_SIZE

		draw_line(
			Vector2(px, HUD_HEIGHT),
			Vector2(
				px,
				HUD_HEIGHT + GRID_HEIGHT * CELL_SIZE
			),
			Color("#1d2a33"),
			1.0
		)

	# Horizontal grid lines
	for y in range(GRID_HEIGHT + 1):

		var py = HUD_HEIGHT + y * CELL_SIZE

		draw_line(
			Vector2(0, py),
			Vector2(
				GRID_WIDTH * CELL_SIZE,
				py
			),
			Color("#1d2a33"),
			1.0
		)

	# Food
	var food_center = Vector2(
		food.x * CELL_SIZE + CELL_SIZE / 2,
		HUD_HEIGHT + food.y * CELL_SIZE + CELL_SIZE / 2
	)

	draw_circle(
		food_center,
		CELL_SIZE * 0.35,
		Color("#ff5252")
	)

	# Snake
	for i in range(snake.size()):

		var part = snake[i]

		var rect = Rect2(
			part.x * CELL_SIZE + 2,
			HUD_HEIGHT + part.y * CELL_SIZE + 2,
			CELL_SIZE - 4,
			CELL_SIZE - 4
		)

		if i == 0:

			draw_rect(
				rect,
				Color("#66ff99")
			)

		else:

			draw_rect(
				rect,
				Color("#20c76a")
			)
