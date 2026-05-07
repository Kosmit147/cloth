package cloth

import rl "vendor:raylib"

CLOTH_WIDTH :: 150
CLOTH_HEIGHT :: 75
CLOTH_SPACING :: 10

DRAG :: 0.005
GRAVITY :: rl.Vector2{ 0, 980 }
ELASTICITY :: 100

Point :: struct {
	pos: rl.Vector2,
	prev_pos: rl.Vector2,
	init_pos: rl.Vector2,
	is_pinned: bool,
	is_selected: bool,
}

Link :: struct {
	p0: ^Point,
	p1: ^Point,
	is_torn: bool,
}

Cloth :: struct {
	points: [dynamic]^Point,
	links: [dynamic]^Link,
}

make_cloth :: proc(cloth_size: [2]i32, cloth_spacing: i32, cloth_start_position: [2]i32) -> Cloth {
	return {}
}

destroy_cloth :: proc(cloth: Cloth) {
	for point in cloth.points do free(point)
	for link in cloth.links do free(link)
	delete(cloth.points)
	delete(cloth.links)
}

interact_with_cloth :: proc(cloth: ^Cloth, cursor_size: f32) {

}

update_cloth :: proc(cloth: ^Cloth, delta_time: f32, cloth_spacing: i32) {

}

draw_cloth :: proc(cloth: Cloth) {

}

main :: proc() {
	rl.InitWindow(0, 0, "Cloth")
	defer rl.CloseWindow()
	rl.ToggleBorderlessWindowed()
	screen_size := [2]i32{ rl.GetScreenWidth(), rl.GetScreenHeight() }
	rl.SetTargetFPS(60)

	cloth_start_position := [2]i32{ (screen_size.x - (CLOTH_WIDTH * CLOTH_SPACING)) / 2, screen_size.y / 12 }
	cloth := make_cloth({ CLOTH_WIDTH, CLOTH_HEIGHT }, CLOTH_SPACING, cloth_start_position)
	defer destroy_cloth(cloth)

	FIXED_DELTA_TIME :: 1.0 / 300.0
	accumulator := f32(0)
	cursor_size := f32(30)

	for !rl.WindowShouldClose() {
		interact_with_cloth(&cloth, cursor_size)

		accumulator += rl.GetFrameTime()
		for accumulator >= FIXED_DELTA_TIME {
			update_cloth(&cloth, FIXED_DELTA_TIME, CLOTH_SPACING)
			accumulator -= FIXED_DELTA_TIME
		}

		rl.BeginDrawing()
		rl.ClearBackground({ 33, 40, 48, 255 })
		draw_cloth(cloth)
		rl.EndDrawing()
	}
}
