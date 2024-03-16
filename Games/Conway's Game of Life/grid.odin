package conway

import rl "vendor:raylib"

cells: [COLUMNS][ROWS]int

drawCells :: proc() {
    for row in 0..<ROWS {
        for column in 0..<COLUMNS {
            color: rl.Color
            if  cells[row][column] == 1  do color = rl.GREEN
            else do color = DARK_GREY
            rl.DrawRectangle(i32(column * CELL_SIZE), 
                             i32(row * CELL_SIZE),
                             i32(CELL_SIZE - 1), 
                             i32(CELL_SIZE - 1),
                             color)
        }
    }
}

fillRandom :: proc() {
    if !running {
        for row in 0..<ROWS {
            for column in 0..<COLUMNS {
                random := rl.GetRandomValue(0, 3)
                if random == 1 do cells[row][column] = 1
                else do cells[row][column] = 0
            }
        }
    }
}

clearGrid :: proc() {
    if !running {
        for row in 0..<ROWS {
            for column in 0..<COLUMNS {
                cells[row][column] = 0
            }
        }
    }   
}
