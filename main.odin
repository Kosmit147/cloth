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

make_cloth :: proc() -> (cloth: Cloth) {
	screen_size := [2]i32{ rl.GetScreenWidth(), rl.GetScreenHeight() }
	cloth_start_position := [2]i32{ (screen_size.x - (CLOTH_WIDTH * CLOTH_SPACING)) / 2, screen_size.y / 12 }
	start_x, start_y := expand_values(cloth_start_position)

	for y := i32(0); y <= CLOTH_HEIGHT; y += 1 {
		for x := i32(0); x <= CLOTH_WIDTH; x += 1 {
			point := new(Point)
			point.init_pos = { f32(start_x + x * CLOTH_SPACING), f32(start_y + y * CLOTH_SPACING) }
			point.pos = point.init_pos
			point.prev_pos = point.pos
			point.is_pinned = y == 0
			append(&cloth.points, point)

			if x != 0 {
				link := new(Link)
				link.p0 = cloth.points[len(cloth.points) - 2]
				link.p1 = cloth.points[len(cloth.points) - 1]
				append(&cloth.links, link)
			}

			if y != 0 {
				link := new(Link)
				link.p0 = cloth.points[(y - 1) * (CLOTH_WIDTH + 1) + x]
				link.p1 = cloth.points[y * (CLOTH_WIDTH + 1) + x]
				append(&cloth.links, link)
			}
		}
	}

	return
}

destroy_cloth :: proc(cloth: Cloth) {
	for point in cloth.points do free(point)
	for link in cloth.links do free(link)
	delete(cloth.points)
	delete(cloth.links)
}

interact_with_cloth :: proc(cloth: ^Cloth, cursor_size: ^f32) {
	set_cursor_size(cursor_size)
	interact_with_points(cloth, cursor_size)

	set_cursor_size :: proc(cursor_size: ^f32) {
		STEP_SIZE :: 5
		if rl.GetMouseWheelMove() > 0 {
			cursor_size^ += STEP_SIZE
		} else if rl.GetMouseWheelMove() < 0 && cursor_size^ > STEP_SIZE {
			cursor_size^ -= STEP_SIZE
		}
	}

	interact_with_points :: proc(cloth: ^Cloth, cursor_size: ^f32) {
		@(static) prev_mouse_pos: rl.Vector2

		mouse_pos := rl.GetMousePosition()
		max_delta := rl.Vector2(200)
		mouse_delta := rl.Vector2Clamp(mouse_pos - prev_mouse_pos, rl.Vector2(-100), max_delta)

		for point in cloth.points {
			distance := rl.Vector2Distance(mouse_pos, point.pos)
			if distance < cursor_size^ {
				if rl.IsMouseButtonDown(.LEFT) {
					point.prev_pos = point.prev_pos + mouse_delta
					point.pos = point.pos + mouse_delta
				}

				point.is_selected = true
			} else {
				point.is_selected = false
			}
		}

		prev_mouse_pos = mouse_pos
	}
}

update_cloth :: proc(cloth: ^Cloth, dt: f32) {
	for point in cloth.points do update_point(point, dt)
	for link in cloth.links do update_link(link)

	update_point :: proc(point: ^Point, dt: f32) {
		if point.is_pinned {
			point.pos = point.init_pos
			return
		}

		current_pos := point.pos
		point.pos += (point.pos - point.prev_pos) * (1 - DRAG) + GRAVITY * dt * dt
		point.prev_pos = current_pos
	}

	update_link :: proc(link: ^Link) {
		delta := link.p1.pos - link.p0.pos
		distance := rl.Vector2Length(delta)

		if distance > ELASTICITY {
			link.is_torn = true
			return
		}

		correction := delta * ((distance - CLOTH_SPACING) / distance * 0.5) * 0.5

		if !link.p0.is_pinned && !link.is_torn do link.p0.pos += correction
		if !link.p1.is_pinned && !link.is_torn do link.p1.pos -= correction
	}
}

draw_cloth :: proc(cloth: Cloth) {
	for link in cloth.links do draw_link(link^)

	draw_link :: proc(link: Link) {
		if link.is_torn do return

		distance := rl.Vector2Distance(link.p0.pos, link.p1.pos)
		color := rl.BLUE if link.p0.is_selected || link.p1.is_selected else get_color_from_tension(distance)
		rl.DrawLineV(link.p0.pos, link.p1.pos, color)
	}

	get_color_from_tension :: proc(distance: f32) -> rl.Color {
		if distance <= CLOTH_SPACING {
			return { 44, 222, 130, 255 }
		} else if distance <= CLOTH_SPACING * 1.33 {
			t := (distance - CLOTH_SPACING) / (CLOTH_SPACING * 0.33)
			color1 := rl.Color{ 44, 222, 130, 255 }
			color2 := rl.Color{ 255, 255, 0, 255 }
			return rl.ColorLerp(color1, color2, t)
		} else {
			t := (distance - CLOTH_SPACING * 1.33) / (ELASTICITY - CLOTH_SPACING * 1.33)
			color1 := rl.Color{ 255, 255, 0, 255 }
			color2 := rl.Color{ 222, 44, 44, 255 }
			return rl.ColorLerp(color1, color2, t)
		}
	}
}

main :: proc() {
	rl.InitWindow(0, 0, "Cloth")
	defer rl.CloseWindow()
	rl.ToggleBorderlessWindowed()
	rl.SetTargetFPS(60)

	cloth := make_cloth()
	defer destroy_cloth(cloth)

	FIXED_DELTA_TIME :: 1.0 / 300.0
	accumulator := f32(0)
	cursor_size := f32(30)

	for !rl.WindowShouldClose() {
		interact_with_cloth(&cloth, &cursor_size)

		accumulator += rl.GetFrameTime()
		for accumulator >= FIXED_DELTA_TIME {
			update_cloth(&cloth, FIXED_DELTA_TIME)
			accumulator -= FIXED_DELTA_TIME
		}

		rl.BeginDrawing()
		rl.ClearBackground({ 33, 40, 48, 255 })
		draw_cloth(cloth)
		rl.EndDrawing()
	}
}
