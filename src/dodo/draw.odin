#+build js wasm32, js wasm64p32

package dodo

import "core:math"
import glm "core:math/linalg"

check_draw_call :: proc(ctx: ^Context) {
    if len(ctx.draw_calls) == 0 {
        append(&ctx.draw_calls, Draw_Call{})
    }
}

draw_rect :: proc(ctx: ^Context, pos: Vec2, size: Vec2, col: Color) {

    check_draw_call(ctx)

    a := pos
    b := pos + {size.x, 0}
    c := pos + {size.x, size.y}
    d := pos + {0, size.y}

    append(&ctx.vertices, Vertex{ pos = a, col = col, uv = {0, 0}})
    append(&ctx.vertices, Vertex{ pos = b, col = col, uv = {1, 0}})
    append(&ctx.vertices, Vertex{ pos = c, col = col, uv = {1, 1}})
    append(&ctx.vertices, Vertex{ pos = c, col = col, uv = {1, 1}})
    append(&ctx.vertices, Vertex{ pos = d, col = col, uv = {0, 1}})
    append(&ctx.vertices, Vertex{ pos = a, col = col, uv = {0, 0}})
}

draw_rect_lines :: proc(ctx: ^Context, pos: Vec2, size: Vec2, thickness: f32, col: Color) {
    t := thickness * 0.5
    draw_rect(ctx, pos - t, {size.x, 0} + thickness, col)
    draw_rect(ctx, pos - t + {0, size.y}, {size.x, 0} + thickness, col)

    draw_rect(ctx, pos - t, {0, size.y} + thickness, col)
    draw_rect(ctx, pos - t + {size.x, 0}, {0, size.y} + thickness, col)
}

draw_quad :: proc(ctx: ^Context, verts: [4]Vertex) {

    check_draw_call(ctx)

    append(&ctx.vertices, verts[0], verts[1], verts[2])
    append(&ctx.vertices, verts[2], verts[3], verts[0])
}

draw_line :: proc(ctx: ^Context, start: Vec2, end: Vec2, thickness: f32, col: Color) {

    check_draw_call(ctx)

    dx := end - start
    dy := glm.normalize0(Vec2{-dx.y, +dx.x})

    a := start + dy * thickness * 0.5
    b := end   + dy * thickness * 0.5
    c := end   - dy * thickness * 0.5
    d := start - dy * thickness * 0.5

    append(&ctx.vertices, Vertex{pos = a, col = col, uv = {0, 0}})
    append(&ctx.vertices, Vertex{pos = b, col = col, uv = {1, 0}})
    append(&ctx.vertices, Vertex{pos = c, col = col, uv = {1, 1}})
    append(&ctx.vertices, Vertex{pos = c, col = col, uv = {1, 1}})
    append(&ctx.vertices, Vertex{pos = d, col = col, uv = {0, 1}})
    append(&ctx.vertices, Vertex{pos = a, col = col, uv = {0, 0}})
}

draw_circle :: proc(ctx: ^Context, center: Vec2, radius: f32, col: Color, segments: int = 32) {
    draw_ellipse(ctx, center, {radius, radius}, col, segments)
}

draw_ellipse :: proc(ctx: ^Context, center: Vec2, #no_broadcast radii: Vec2, col: Color, segments: int = 32) {

    check_draw_call(ctx)

    c := Vertex{pos = { center.x, center.y}, col = col}

    for i in 0..<segments {
        t0 := f32(i+0)/f32(segments) * math.TAU
        t1 := f32(i+1)/f32(segments) * math.TAU

        a := c
        b := c

        a.pos.x += radii.x * math.cos(t0)
        a.pos.y += radii.y * math.sin(t0)

        b.pos.x += radii.x * math.cos(t1)
        b.pos.y += radii.y * math.sin(t1)

        append(&ctx.vertices, c, a, b)
    }
}

draw_ring :: proc(ctx: ^Context, center: Vec2, inner_radius, outer_radius: f32, angle_start, angle_end: f32, col: Color, segments: int = 32) {

    check_draw_call(ctx)

    p := Vertex{pos = { center.x, center.y}, col = col}

    for i in 0..<segments {
        t0 := math.lerp(angle_start, angle_end, f32(i+0)/f32(segments))
        t1 := math.lerp(angle_start, angle_end, f32(i+1)/f32(segments))

        a := p
        b := p
        c := p
        d := p

        a.pos.x += outer_radius * math.cos(t0)
        a.pos.y += outer_radius * math.sin(t0)

        b.pos.x += outer_radius * math.cos(t1)
        b.pos.y += outer_radius * math.sin(t1)

        c.pos.x += inner_radius * math.cos(t1)
        c.pos.y += inner_radius * math.sin(t1)

        d.pos.x += inner_radius * math.cos(t0)
        d.pos.y += inner_radius * math.sin(t0)

        append(&ctx.vertices, a, b, c)
        append(&ctx.vertices, c, d, a)
    }
}

draw_arc :: proc(ctx: ^Context, center: Vec2, radius: f32, thickness: f32, angle_start, angle_end: f32, col: Color, segments: int = 32) {
    draw_ring(ctx, center, radius-thickness*0.5, radius+thickness*0.5, angle_start, angle_end, col, segments)
}