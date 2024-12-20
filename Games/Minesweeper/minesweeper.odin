package minesweeper

/*******************************************************************************************
*
*   Minesweeper (16x16)
*   Sample game ported to Odin based of the Microsoft Original 
*
********************************************************************************************/

import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:time"
import rl "vendor:raylib"

// enum for tile markings
Mark :: enum {
	Clear,
	Flag,
	Question,
}

// struct which makes up the grid
TileInfo :: struct {
	using rect: rl.Rectangle,
	grid_pos:   [2]int,
	revealed:   bool,
	value:      int,
	mark:       Mark,
}

// global constants
SCREEN_WIDTH :: 687
SCREEN_HEIGHT :: 777
COLS :: 16
ROWS :: 16
TILE_SIZE :: 40

// global variables
game_over: bool
first_move: bool
bombs_left: i32
victory: bool
stopwatch: time.Stopwatch
grid: [16][16]TileInfo
visited: map[[2]int]bool
int_map: map[int]rl.Texture2D
enum_map: map[Mark]rl.Texture2D
board: rl.Texture2D

// main proc
main :: proc() {
	rl.SetTraceLogLevel(.NONE)
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Minesweeper")
	defer rl.CloseWindow()
	rl.SetTargetFPS(30)
	unloadGame()
	loadTextures()
	initGame()

	for !rl.WindowShouldClose() do updateGame()
}

// Main Game Loop Functions

// initialize game on each start
initGame :: proc() {
	clear(&visited)
	first_move = true
	game_over = false
	victory = false
	time.stopwatch_reset(&stopwatch)
	initalizeGrid()
}

// main control proc. calls other small control procs
controls :: proc() {
	if rl.IsMouseButtonReleased(.LEFT) {
		if !game_over do unveilTile()
		if hoverSmiley() do initGame()
	}

	if rl.IsMouseButtonReleased(.RIGHT) {
		if !game_over do markTile()
	}
}

// main draw call
drawGame :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.DrawTexture(board, 0, 0, 255)
	drawTextures()
	drawBombTracker()
	drawTimer()
	// debugGame(rl.GetMousePosition())
}

// update game loop
updateGame :: proc() {
	controls()
	bombsAndVictory()
	drawGame()
}

// deletes items from memory
unloadGame :: proc() {
	defer {
		delete(visited)
		delete(int_map)
		delete(enum_map)
	}
}

// Grid Functions for init

// initializes all tiles starting conditions
initalizeGrid :: proc() {
	for &r_val, r_ind in grid {
		for &c_val, c_ind in r_val {
			c_val = {
				{f32(c_ind * TILE_SIZE) + 21, f32(r_ind * TILE_SIZE) + 116, TILE_SIZE, TILE_SIZE},
				{r_ind, c_ind},
				false,
				0,
				.Clear,
			}
		}
	}
}

// sets all tile values
setGridVals :: proc(pos: [2]int) {
	x := make(map[i32]bool)
	defer delete(x)

	num := i32(pos.x * 16 + pos.y)

	for len(x) < 40 {
		val := rl.GetRandomValue(0, 255)
		for val == num do val = rl.GetRandomValue(0, 255)
		x[val] = true
	}

	ttl: i32 = 0
	for r_val, r_ind in grid {
		for c_val, c_ind in r_val {
			if ttl in x {
				grid[r_ind][c_ind].value = -1
			}
			ttl += 1
		}
	}
	setTileVals(&grid)
	// printGridVals(&grid)
}

// Controls

// If left click release reveal tiles contents. 
unveilTile :: proc() {
	m_pos := rl.GetMousePosition()
	t_pos := getTilePos(m_pos)
	if inBounds(t_pos, 16, 16) {
		if first_move {
			first_move = false
			setGridVals(t_pos)
			time.stopwatch_start(&stopwatch)
		}
		val := fetchVal(&grid, t_pos)
		if val.mark == .Clear {
			dfs(&grid, t_pos, &visited)

			// fmt.println(val)
			if val.revealed && val.value == -1 do game_over = true
		}
	}
}

// If hovering tile show tile as a clear empty tile.
hoverTile :: proc() -> (t_pos: [2]int) {
	if rl.IsMouseButtonDown(.LEFT) {
		m_pos := rl.GetMousePosition()
		t_pos = getTilePos(m_pos)
		if inBounds(t_pos, 16, 16) do return
	}
	return {-100, -100}
}

// If right click release cycle through clear, bomb, and question enum.
markTile :: proc() {
	m_pos := rl.GetMousePosition()
	t_pos := getTilePos(m_pos)
	if inBounds(t_pos, 16, 16) {
		val := fetchVal(&grid, t_pos)
		if !val.revealed {
			switch val.mark {
			case .Clear:
				val.mark = .Flag
			case .Flag:
				val.mark = .Question
			case .Question:
				val.mark = .Clear
			}
		}
		// fmt.println(val)
	}
}

// Checks if hovering over smiley face
hoverSmiley :: proc() -> bool {
	face_loc: rl.Vector2 = {336, 56}
	m_pos := rl.GetMousePosition()
	x_pos := abs(face_loc.x - m_pos.x)
	y_pos := abs(face_loc.y - m_pos.y)
	return x_pos <= 36 && y_pos <= 36
}

// checks how many bombs are left and also victory conditions
bombsAndVictory :: proc() {
	clear: i32 = 0
	bombs: i32 = 0
	for &i in grid {
		for &j in i {
			if victory && j.value == -1 do j.mark = .Flag
			if !victory && game_over && j.value == -1 && j.revealed && j.mark == .Clear {
				j.value -= 1
			}
			if j.mark == .Flag do bombs += 1
			if j.revealed do clear += 1
		}
	}

	if clear == ROWS * COLS - 40 {
		game_over = true
		victory = true
	}

	bombs_left = 40 - bombs
}

// Load all textures
loadTextures :: proc() {
	board = rl.LoadTexture("textures/board.png")
	tile_img := rl.LoadTexture("textures/tile.png")
	flag_img := rl.LoadTexture("textures/flag.png")
	question_img := rl.LoadTexture("textures/question.png")
	smile_img := rl.LoadTexture("textures/smile.png")
	smile_clear_img := rl.LoadTexture("textures/smile_clear.png")
	frown_img := rl.LoadTexture("textures/frown.png")
	sunglasses_img := rl.LoadTexture("textures/sunglasses.png")
	surprise_img := rl.LoadTexture("textures/surprise.png")
	clear_img := rl.LoadTexture("textures/clear.png")
	bomb_img := rl.LoadTexture("textures/bomb.png")
	exploded_img := rl.LoadTexture("textures/exploded.png")
	bad_marked_img := rl.LoadTexture("textures/bad_marked.png")
	one_img := rl.LoadTexture("textures/one.png")
	two_img := rl.LoadTexture("textures/two.png")
	three_img := rl.LoadTexture("textures/three.png")
	four_img := rl.LoadTexture("textures/four.png")
	five_img := rl.LoadTexture("textures/five.png")
	six_img := rl.LoadTexture("textures/six.png")
	seven_img := rl.LoadTexture("textures/seven.png")
	eight_img := rl.LoadTexture("textures/eight.png")

	enum_map[.Clear] = tile_img
	enum_map[.Flag] = flag_img
	enum_map[.Question] = question_img
	int_map[-3] = bad_marked_img
	int_map[-2] = exploded_img
	int_map[-1] = bomb_img
	int_map[0] = clear_img
	int_map[1] = one_img
	int_map[2] = two_img
	int_map[3] = three_img
	int_map[4] = four_img
	int_map[5] = five_img
	int_map[6] = six_img
	int_map[7] = seven_img
	int_map[8] = eight_img
	int_map[9] = smile_img
	int_map[10] = frown_img
	int_map[11] = surprise_img
	int_map[12] = sunglasses_img
	int_map[13] = smile_clear_img
}

// Draw Textures and caluclates bomb number left and victory conditions.
drawTextures :: proc() {
	for &i in grid {
		for &j in i {
			drawEnumMapTiles(&j)
			drawIntMapTiles(&j)
		}
	}
	drawFaces()
}

// Draw Everything that's not revealed
drawEnumMapTiles :: proc(j: ^TileInfo) {
	if !j.revealed {
		switch j.mark {
		case .Clear:
			if j.grid_pos == hoverTile() && !game_over {
				rl.DrawTexture(int_map[0], i32(j.x), i32(j.y), 255)
			} else {
				rl.DrawTexture(enum_map[.Clear], i32(j.x), i32(j.y), 255)

			}
		case .Flag:
			if game_over && j.value != -1 {
				rl.DrawTexture(int_map[-3], i32(j.x), i32(j.y), 255)
			} else {
				rl.DrawTexture(enum_map[.Flag], i32(j.x), i32(j.y), 255)

			}
		case .Question:
			rl.DrawTexture(enum_map[.Question], i32(j.x), i32(j.y), 255)
		}

		if !victory && game_over && j.value == -1 && j.mark != .Flag {
			rl.DrawTexture(int_map[-1], i32(j.x), i32(j.y), 255)
		}
	}
}

// Draw Everyting revealed
drawIntMapTiles :: proc(j: ^TileInfo) {
	if j.revealed {
		rl.DrawTexture(int_map[j.value], i32(j.x), i32(j.y), 255)
	}
}

// Draw Faces
drawFaces :: proc() {
	if !game_over {
		tile := hoverTile()
		if tile.x >= 0 && tile.y >= 0 && tile.x <= 15 && tile.y <= 15 {
			rl.DrawTexture(int_map[11], 300, 20, 255)
		} else do rl.DrawTexture(int_map[9], 300, 20, 255)
	} else {
		if !victory do rl.DrawTexture(int_map[10], 300, 20, 255)
		else do rl.DrawTexture(int_map[12], 300, 20, 255)
	}

	if rl.IsMouseButtonDown(.LEFT) {
		if hoverSmiley() do rl.DrawTexture(int_map[13], 300, 20, 255)
	}
}

// Draw Bomb Tracker
drawBombTracker :: proc() {
	rect: rl.Rectangle = {30, 30, 100, 50}

	rl.DrawRectangleRec(rect, rl.BLACK)

	rl.DrawText(
		rl.TextFormat("%v", bombs_left),
		i32(rect.x + rect.width / 2) - rl.MeasureText(rl.TextFormat("%v", bombs_left), 40) / 2,
		i32(rect.y + 10),
		40,
		rl.RED,
	)
}

// Draw Timer
drawTimer :: proc() {
	hr, min, sec := time.clock_from_stopwatch(stopwatch)
	ttl := (hr * 60 * 60) + (min * 60) + sec
	rect: rl.Rectangle = {SCREEN_WIDTH - 135, 30, 100, 50}

	rl.DrawRectangleRec(rect, rl.BLACK)

	rl.DrawText(
		rl.TextFormat("%v", ttl),
		i32(rect.x + rect.width / 2) - rl.MeasureText(rl.TextFormat("%v", ttl), 40) / 2,
		i32(rect.y + 10),
		40,
		rl.RED,
	)

	if game_over do time.stopwatch_stop(&stopwatch)
}

// Helper Functions

// Checks if pos is within bounds of the grid
inBounds :: proc(pos: [2]int, width, height: int) -> bool {
	return pos.x >= 0 && pos.y >= 0 && pos.x < height && pos.y < width
}

// Retrieves value from grid given [2]int pos
fetchVal :: proc(mat: ^[16][16]TileInfo, pos: [2]int) -> ^TileInfo {
	return &mat[pos.x][pos.y]
}

// Find Indexes and values in 8 directions from a given [2]int pos
nbrs :: proc(
	mat: ^[16][16]TileInfo,
	pos: [2]int,
) -> (
	inds: sa.Small_Array(8, [2]int),
	vals: sa.Small_Array(8, ^TileInfo),
) {
	width, height := len(mat[0]), len(mat)
	dirs: [8][2]int = {{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}}

	for val, ind in dirs {
		n_pos := pos + val
		if inBounds(n_pos, width, height) {
			sa.append(&inds, n_pos)
			sa.append(&vals, fetchVal(mat, n_pos))
		}
	}

	return inds, vals
}

// Prints Grid To Console if you want to verify values.
printGridVals :: proc(mat: ^[16][16]TileInfo) {
	for i in mat {
		fmt.print("[")
		for j, ind in i {
			if ind % 15 != 0 || ind == 0 do fmt.printf("%v, ", j.value)
			else do fmt.print(j.value)
		}

		fmt.print("]\n")
	}
}

// Calculates tile pos in grid from a Vector2d
getTilePos :: proc(pos: rl.Vector2) -> [2]int {
	x_pos := int(math.floor((pos.x - 21) / 40))
	y_pos := int(math.floor((pos.y - 116) / 40))
	return {y_pos, x_pos}
}

// Calculates how many bombs each tile touches
setTileVals :: proc(mat: ^[16][16]TileInfo) {
	for &i, c_ind in mat {
		for &j, r_ind in i {
			defer free_all(context.temp_allocator)
			if j.value != -1 {
				_, vals := nbrs(mat, {c_ind, r_ind})
				filt := len(
					slice.filter(
						sa.slice(&vals),
						proc(tile: ^TileInfo) -> bool {return tile.value == -1},
						context.temp_allocator,
					),
				)
				j.value = filt
			}
		}
	}
}

// Debug function that can print value to screen for visualization
debugGame :: proc(val: $T, col: rl.Color = rl.RED, size: i32 = 20, x: i32 = 5, y: i32 = 0) {
	rl.DrawText(rl.TextFormat("%v", val), x, y, size, col)
}

// If you click a tile it will run a dfs to see what tiles should be revealed
dfs :: proc(mat: ^[16][16]TileInfo, pos: [2]int, mp: ^map[[2]int]bool) {
	val := fetchVal(mat, pos)

	val.revealed = true
	if val.value != 0 || pos in mp do return

	mp[pos] = true
	// fmt.println(pos)

	inds, _ := nbrs(mat, pos)
	for i in sa.slice(&inds) {
		b := fetchVal(mat, i)
		if b.value > 0 do b.revealed = true
		dfs(mat, i, mp)
	}
}

