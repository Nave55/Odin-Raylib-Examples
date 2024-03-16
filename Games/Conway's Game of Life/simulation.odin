package conway

import rl "vendor:raylib"

tmp_cells := cells

countLiveNeighbors :: proc(row, column: int) -> (live_neighbors := 0) {
    neighbor_offsets: [8][2]int = {{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}}
    for offset in neighbor_offsets {
        new_row := (row + offset[0]) %% ROWS
        new_column := (column + offset[1]) %% COLUMNS
        if cells[new_row][new_column] == 1 do live_neighbors += 1
    }
    return
}

updateSim :: proc() {
    if running {
        for row in 0..<ROWS {
            for column in 0..<COLUMNS {
                live_neighbors := countLiveNeighbors(row, column)
                cell_value := cells[row][column]

                if cell_value == 1 {
                    if live_neighbors > 3 || live_neighbors < 2 do tmp_cells[row][column] = 0
                    else do tmp_cells[row][column] = 1
                }
                else {
                    if live_neighbors == 3 do tmp_cells[row][column] = 1
                    else do tmp_cells[row][column] = 0
                }
            }
        }
        for row in 0..<ROWS {
            for column in 0..<COLUMNS {
                cells[row][column] = tmp_cells[row][column]
            }
        }
    }
}