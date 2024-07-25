package box

import rl "vendor:raylib"

debugGame1 :: proc(val: $T, col: rl.Color = rl.RED, size: i32 = 20,  x: i32 = 5, y: i32 = 0) {
    rl.DrawText(rl.TextFormat("%v", val), 
                x,
                y,
                size, 
                col)
}

debugGame2 :: proc(val: $T, descrip: string, col: rl.Color = rl.RED, size: i32 = 20,  x: i32 = 5, y: i32 = 0) {
    rl.DrawText(rl.TextFormat("%v: %v", descrip, val), 
                x,
                y,
                size, 
                col)
}

debugGame3 :: proc(val: $T, descrip: string, col: rl.Color = rl.RED, size: i32 = 20,  x: i32 = 5, y: i32 = 0) {
    rl.DrawText(rl.TextFormat("%v: %v", descrip, val), 
                x,
                y,
                size, 
                col)
}

debugGame :: proc{
    debugGame1,
    debugGame2,
}