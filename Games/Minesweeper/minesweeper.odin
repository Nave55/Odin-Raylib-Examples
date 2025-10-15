package minesweeper

/*******************************************************************************************
*
*                                     Minesweeper (16x16)
*                    Sample game ported to Odin based off the Microsoft game. 
*
********************************************************************************************/

import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:mem"
import vm "core:mem/virtual"
import "core:slice"
import "core:time"
import rl "vendor:raylib"

NonRevealedValues :: enum u8 {
	Tile,
	Flag,
	Question,
	Bad_Marked,
}

RevealedValues :: enum u8 {
	Bomb,
	Exploded,
	Clear,
	One,
	Two,
	Three,
	Four,
	Five,
	Six,
	Seven,
	Eight,
}

Textures :: enum u8 {
	Tile,
	Flag,
	Question,
	Board,
	Bad_Marked,
	Exploded,
	Bomb,
	Clear,
	One,
	Two,
	Three,
	Four,
	Five,
	Six,
	Seven,
	Eight,
	Smile,
	Frown,
	Surprise,
	Sunglasses,
	Smile_Clear,
}

// struct which makes up the grid
TileInfo :: struct {
	using rect: rl.Rectangle,
	grid_pos:   [2]int,
	revealed:   bool,
	r_value:    RevealedValues,
	nr_value:   NonRevealedValues,
}

// Game Data to be passed to functions
GameData :: struct {
	game_over:  bool,
	first_move: bool,
	bombs_left: i32,
	victory:    bool,
	stopwatch:  time.Stopwatch,
	visited:    map[[2]int]struct {},
	tile_map:   map[Textures]rl.Texture2D,
}

// global constants
SCREEN_WIDTH :: 687
SCREEN_HEIGHT :: 777
COLS :: 16
ROWS :: 16
TILES :: COLS * ROWS
TILE_SIZE :: 40
BOMBS :: 40
TIMER_RECT :: rl.Rectangle{SCREEN_WIDTH - 135, 30, 100, 50}
BOMB_TRACKER_RECT :: rl.Rectangle{30, 30, 100, 50}
FACE_LOC :: rl.Vector2{336, 56}

@(rodata)
int_to_revealed_value := [9]RevealedValues {
	.Clear,
	.One,
	.Two,
	.Three,
	.Four,
	.Five,
	.Six,
	.Seven,
	.Eight,
}

@(rodata)
Revealed_Values_To_Textures := [RevealedValues]Textures {
	.Bomb     = .Bomb,
	.Exploded = .Exploded,
	.Clear    = .Clear,
	.One      = .One,
	.Two      = .Two,
	.Three    = .Three,
	.Four     = .Four,
	.Five     = .Five,
	.Six      = .Six,
	.Seven    = .Seven,
	.Eight    = .Eight,
}

// grid 
grid: [ROWS][COLS]TileInfo

/*******************************************************************************************
*
*                                Main Game Loop Functions
*
********************************************************************************************/

main :: proc() {
	// create arena and arena_allocator
	arena: vm.Arena
	err := vm.arena_init_static(&arena, 100 * mem.Kilobyte)
	assert(err == .None)
	arena_allocator := vm.arena_allocator(&arena)
	defer vm.arena_destroy(&arena)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Minesweeper")
	defer rl.CloseWindow()
	rl.SetTargetFPS(30)

	game_data := initGameData(arena_allocator)
	initGame(&game_data)

	for !rl.WindowShouldClose() do updateGame(&game_data, &arena)
}


// main control proc. calls other small control procs
controls :: proc(game_data: ^GameData, arena: ^vm.Arena) {
	if rl.IsMouseButtonReleased(.LEFT) {
		if !game_data.game_over do unveilTile(game_data)
		if hoverSmiley() do initGame(game_data)
	}

	if rl.IsMouseButtonReleased(.RIGHT) {
		if !game_data.game_over do markTile()
	}
}

// main draw call
drawGame :: proc(game_data: ^GameData) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.DrawTexture(game_data.tile_map[.Board], 0, 0, 255)
	drawTextures(game_data)
	drawBombTracker(game_data^)
	drawTimer(game_data)
}

// update game loop
updateGame :: proc(game_data: ^GameData, arena: ^vm.Arena) {
	controls(game_data, arena)
	bombsAndVictory(game_data)
	drawGame(game_data)
}

/*******************************************************************************************
*
*                                    Initialization Functions
*
********************************************************************************************/

// Load all textures
loadTextures :: proc(game_data: ^GameData) {
	game_data.tile_map[.Tile] = rl.LoadTexture("textures/tile.png")
	game_data.tile_map[.Flag] = rl.LoadTexture("textures/flag.png")
	game_data.tile_map[.Question] = rl.LoadTexture("textures/question.png")
	game_data.tile_map[.Board] = rl.LoadTexture("textures/board.png")
	game_data.tile_map[.Bad_Marked] = rl.LoadTexture("textures/bad_marked.png")
	game_data.tile_map[.Exploded] = rl.LoadTexture("textures/exploded.png")
	game_data.tile_map[.Bomb] = rl.LoadTexture("textures/bomb.png")
	game_data.tile_map[.Clear] = rl.LoadTexture("textures/clear.png")
	game_data.tile_map[.One] = rl.LoadTexture("textures/one.png")
	game_data.tile_map[.Two] = rl.LoadTexture("textures/two.png")
	game_data.tile_map[.Three] = rl.LoadTexture("textures/three.png")
	game_data.tile_map[.Four] = rl.LoadTexture("textures/four.png")
	game_data.tile_map[.Five] = rl.LoadTexture("textures/five.png")
	game_data.tile_map[.Six] = rl.LoadTexture("textures/six.png")
	game_data.tile_map[.Seven] = rl.LoadTexture("textures/seven.png")
	game_data.tile_map[.Eight] = rl.LoadTexture("textures/eight.png")
	game_data.tile_map[.Smile] = rl.LoadTexture("textures/smile.png")
	game_data.tile_map[.Frown] = rl.LoadTexture("textures/frown.png")
	game_data.tile_map[.Surprise] = rl.LoadTexture("textures/surprise.png")
	game_data.tile_map[.Sunglasses] = rl.LoadTexture("textures/sunglasses.png")
	game_data.tile_map[.Smile_Clear] = rl.LoadTexture("textures/smile_clear.png")
}

// init GameData struct with starting values
@(require_results)
initGameData :: proc(arena_allocator: mem.Allocator) -> GameData {
	game_data := GameData {
		false,
		true,
		0,
		false,
		{},
		make(map[[2]int]struct {}, 100, arena_allocator),
		make(map[Textures]rl.Texture2D, 21, arena_allocator),
	}

	loadTextures(&game_data)
	return game_data
}

// initializes all tile starting conditions
initalizeGrid :: proc() {
	for &r_val, r_ind in grid {
		for &c_val, c_ind in r_val {
			c_val = {
				{f32(c_ind * TILE_SIZE) + 21, f32(r_ind * TILE_SIZE) + 116, TILE_SIZE, TILE_SIZE},
				{r_ind, c_ind},
				false,
				.Clear,
				.Tile,
			}
		}
	}
}

// initialize game on each start
initGame :: proc(game_data: ^GameData) {
	clear(&game_data.visited)
	game_data.first_move = true
	game_data.game_over = false
	game_data.victory = false
	time.stopwatch_reset(&game_data.stopwatch)
	initalizeGrid()
}

// sets all tile values at first click
initializeGridVals :: proc(pos: [2]int) {
	x := make(map[i32]struct {}, context.temp_allocator) // create set to track bomb locations
	defer free_all(context.temp_allocator)

	num := i32(pos.x * ROWS + pos.y) // pos where player clicked as first move

	for len(x) < BOMBS {
		val := rl.GetRandomValue(0, TILES - 1)
		for val == num do val = rl.GetRandomValue(0, TILES - 1) // make sure bomb location isn't same as player
		x[val] = {} // Push val into set
		setTileRevealedValFromNum(val, .Bomb) // set Tile.r_value to .Bomb
	}

	setTileVals(&grid) // set remaining r_values
}

/*******************************************************************************************
*
*                                    Tile Functions
*
********************************************************************************************/

// Checks if pos is within bounds of the grid
@(require_results)
inBounds :: proc(pos: [2]int, width, height: int) -> bool {
	return pos.x >= 0 && pos.y >= 0 && pos.x < height && pos.y < width
}

// Retrieves value from grid given [2]int pos
@(require_results)
fetchVal :: proc(mat: ^[ROWS][COLS]TileInfo, pos: [2]int) -> ^TileInfo {
	return &mat[pos.x][pos.y]
}

// Calculates tile pos in grid from a Vector2d
@(require_results)
getTilePos :: proc(pos: rl.Vector2) -> [2]int {
	x_pos := int(math.floor((pos.x - 21) / 40))
	y_pos := int(math.floor((pos.y - 116) / 40))
	return {y_pos, x_pos}
}

// If you click a tile it will run a dfs to see what tiles should be revealed
dfs :: proc(mat: ^[ROWS][COLS]TileInfo, pos: [2]int, mp: ^map[[2]int]struct {}) {
	val := fetchVal(mat, pos)

	val.revealed = true
	val.nr_value = .Tile
	if val.r_value != .Clear || pos in mp do return

	mp[pos] = {}

	inds, _ := nbrs(mat, pos)
	for i in sa.slice(&inds) {
		b := fetchVal(mat, i)
		#partial switch b.r_value {
		case .One, .Two, .Three, .Four, .Five, .Six, .Seven, .Eight:
			b.revealed = true
			b.nr_value = .Tile
		}

		dfs(mat, i, mp)
	}
}

// takes a tile number and a val and then sets r_value to that val
setTileRevealedValFromNum :: proc(num: i32, val: RevealedValues) {
	row := i32(math.floor(f32(num) / ROWS))
	col := num % COLS
	grid[row][col].r_value = val

	return
}

// Calculates how many bombs each tile touches
setTileVals :: proc(mat: ^[ROWS][COLS]TileInfo) {
	defer free_all(context.temp_allocator)
	for &i, c_ind in mat {
		for &j, r_ind in i {
			if j.r_value != .Bomb {
				_, vals := nbrs(mat, {c_ind, r_ind})
				filt := len(
					slice.filter(
						sa.slice(&vals),
						proc(tile: ^TileInfo) -> bool {return tile.r_value == .Bomb},
						context.temp_allocator,
					),
				)
				j.r_value = int_to_revealed_value[filt]
			}
		}
	}
}

// Reveal tile 
unveilTile :: proc(game_data: ^GameData) {
	t_pos := getTilePos(rl.GetMousePosition())

	if inBounds(t_pos, ROWS, COLS) {
		if game_data.first_move {
			game_data.first_move = false
			initializeGridVals(t_pos) // set all r_values
			time.stopwatch_start(&game_data.stopwatch)
		}
		// if nr_value is .Tile run dfs to see if tiles should be revealed
		val := fetchVal(&grid, t_pos)
		if val.nr_value == .Tile {
			dfs(&grid, t_pos, &game_data.visited)
			if val.revealed && val.r_value == .Bomb do game_data.game_over = true // fail condition
		}
	}
}

// Returns a tile pos if you are hovering a tile that hasn't been revealed
@(require_results)
hoverTile :: proc() -> (t_pos: [2]int) {
	if rl.IsMouseButtonDown(.LEFT) {
		t_pos = getTilePos(rl.GetMousePosition())
		if inBounds(t_pos, ROWS, COLS) && !fetchVal(&grid, t_pos).revealed do return
	}
	return {-1, -1}
}

// If right click release cycle through clear, bomb, and question enum.
markTile :: proc() {
	t_pos := getTilePos(rl.GetMousePosition())
	if inBounds(t_pos, ROWS, COLS) {
		val := fetchVal(&grid, t_pos)
		if !val.revealed {
			#partial switch val.nr_value {
			case .Tile:
				val.nr_value = .Flag
			case .Flag:
				val.nr_value = .Question
			case .Question:
				val.nr_value = .Tile
			case:
				panic("Wrong Enum in MarkTile")
			}
		}
	}
}

// Checks if hovering over smiley face
@(require_results)
hoverSmiley :: proc() -> bool {
	m_pos := rl.GetMousePosition()
	x_pos := abs(FACE_LOC.x - m_pos.x)
	y_pos := abs(FACE_LOC.y - m_pos.y)
	return x_pos <= 36 && y_pos <= 36
}

/*******************************************************************************************
*
*                                   Tracking Functions
*
********************************************************************************************/

// checks how many bombs are left and also victory conditions
bombsAndVictory :: proc(game_data: ^GameData) {
	clear: i32 = 0
	bombs: i32 = 0

	for &i in grid {
		for &j in i {
			if game_data.victory && j.r_value == .Bomb do j.nr_value = .Flag
			if !game_data.victory &&
			   game_data.game_over &&
			   j.r_value == .Bomb &&
			   j.revealed &&
			   j.nr_value == .Tile {
				j.r_value = .Exploded
			}
			if j.nr_value == .Flag do bombs += 1
			if j.revealed && j.r_value != .Bomb && j.r_value != .Exploded do clear += 1
		}
	}

	if clear == ROWS * COLS - BOMBS {
		game_data.game_over = true
		game_data.victory = true
	}

	game_data.bombs_left = BOMBS - bombs
}

/*******************************************************************************************
*
*                                    Draw Functions
*
********************************************************************************************/

// Draw All Map Tiles
drawMapTiles :: proc(j: ^TileInfo, game_data: ^GameData) {
	x, y := i32(j.x), i32(j.y)

	if !j.revealed {
		#partial switch j.nr_value {
		case .Tile:
			if j.grid_pos == hoverTile() && !game_data.game_over {
				rl.DrawTexture(game_data.tile_map[.Clear], x, y, 255)
			} else {
				rl.DrawTexture(game_data.tile_map[.Tile], x, y, 255)

			}
		case .Flag:
			if game_data.game_over && j.r_value != .Bomb {
				rl.DrawTexture(game_data.tile_map[.Bad_Marked], x, y, 255)
			} else {
				rl.DrawTexture(game_data.tile_map[.Flag], x, y, 255)

			}
		case .Question:
			rl.DrawTexture(game_data.tile_map[.Question], x, y, 255)
		case:
			panic("Wrong Enum in drawEnumMapTiles")
		}

		if !game_data.victory && game_data.game_over && j.r_value == .Bomb && j.nr_value != .Flag {
			rl.DrawTexture(game_data.tile_map[.Bomb], x, y, 255)
		}
	} else do rl.DrawTexture(game_data.tile_map[Revealed_Values_To_Textures[j.r_value]], x, y, 255)
}

// Draw Textures
drawTextures :: proc(game_data: ^GameData) {
	for &i in grid {
		for &j in i do drawMapTiles(&j, game_data)
	}
	drawFaces(game_data)
}

// Draw Faces
drawFaces :: proc(game_data: ^GameData) {
	if !game_data.game_over {
		if inBounds(hoverTile(), ROWS, COLS) {
			rl.DrawTexture(game_data.tile_map[.Surprise], 300, 20, 255)
		} else do rl.DrawTexture(game_data.tile_map[.Smile], 300, 20, 255)
	} else {
		if !game_data.victory do rl.DrawTexture(game_data.tile_map[.Frown], 300, 20, 255)
		else do rl.DrawTexture(game_data.tile_map[.Sunglasses], 300, 20, 255)
	}

	if rl.IsMouseButtonDown(.LEFT) {
		if hoverSmiley() do rl.DrawTexture(game_data.tile_map[.Smile_Clear], 300, 20, 255)
	}
}

// Draw Bomb Tracker
drawBombTracker :: proc(game_data: GameData) {
	@(static) rect_draw_width := i32(BOMB_TRACKER_RECT.x + BOMB_TRACKER_RECT.width / 2)
	@(static) rect_draw_height := i32(BOMB_TRACKER_RECT.y + 10)
	rl.DrawRectangleRec(BOMB_TRACKER_RECT, rl.BLACK)

	rl.DrawText(
		rl.TextFormat("%v", game_data.bombs_left),
		rect_draw_width - rl.MeasureText(rl.TextFormat("%v", game_data.bombs_left), 40) / 2,
		rect_draw_height,
		40,
		rl.RED,
	)
}

// Draw Timer
drawTimer :: proc(game_data: ^GameData) {
	@(static) rect_draw_width := i32(TIMER_RECT.x + TIMER_RECT.width / 2)
	@(static) rect_draw_height := i32(TIMER_RECT.y + 10)
	rl.DrawRectangleRec(TIMER_RECT, rl.BLACK)

	hr, min, sec := time.clock_from_stopwatch(game_data.stopwatch)
	ttl := (hr * 60 * 60) + (min * 60) + sec
	rl.DrawText(
		rl.TextFormat("%v", ttl),
		rect_draw_width - rl.MeasureText(rl.TextFormat("%v", ttl), 40) / 2,
		rect_draw_height,
		40,
		rl.RED,
	)

	if game_data.game_over do time.stopwatch_stop(&game_data.stopwatch)
}

/*******************************************************************************************
*
*                                    Helper Functions
*
********************************************************************************************/

// Find Indexes and values in 8 directions from a given [2]int pos
@(require_results)
nbrs :: proc(
	mat: ^[ROWS][COLS]TileInfo,
	pos: [2]int,
) -> (
	inds: sa.Small_Array(8, [2]int),
	vals: sa.Small_Array(8, ^TileInfo),
) {
	width, height := len(mat[0]), len(mat)
	dirs: [8][2]int = {{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}}

	for val in dirs {
		n_pos := pos + val
		if inBounds(n_pos, width, height) {
			sa.append(&inds, n_pos)
			sa.append(&vals, fetchVal(mat, n_pos))
		}
	}

	return inds, vals
}

// Debug function that can print value to screen for visualization
debugGame :: proc(val: $T, col: rl.Color = rl.RED, size: i32 = 20, x: i32 = 5, y: i32 = 0) {
	rl.DrawText(rl.TextFormat("%v", val), x, y, size, col)
}

// Prints Grid To Console if you want to verify values.
printGridVals :: proc(mat: [ROWS][COLS]TileInfo) {
	for i in mat {
		fmt.print("[ ")
		for j, ind in i {
			if ind % 15 != 0 || ind == 0 do fmt.printf("%v, ", j.r_value)
			else do fmt.print(j.r_value)
		}

		fmt.println(" ]")
	}
}

