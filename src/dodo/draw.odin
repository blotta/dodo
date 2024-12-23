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

    z := ctx.curr_depth

    pos3 := Vec3{pos.x, pos.y, z}
    a := pos3
    b := pos3 + {size.x, 0, 0}
    c := pos3 + {size.x, size.y, 0}
    d := pos3 + {0, size.y, 0}

    append(&ctx.vertices, Vertex{ pos = a, col = col, uv = {0, 0}})
    append(&ctx.vertices, Vertex{ pos = b, col = col, uv = {1, 0}})
    append(&ctx.vertices, Vertex{ pos = c, col = col, uv = {1, 1}})
    append(&ctx.vertices, Vertex{ pos = c, col = col, uv = {1, 1}})
    append(&ctx.vertices, Vertex{ pos = d, col = col, uv = {0, 1}})
    append(&ctx.vertices, Vertex{ pos = a, col = col, uv = {0, 0}})
}

draw_quad :: proc(ctx: ^Context, verts: [4]Vertex) {

    check_draw_call(ctx)

    z := ctx.curr_depth

    append(&ctx.vertices, verts[0], verts[1], verts[2])
    append(&ctx.vertices, verts[2], verts[3], verts[0])
}

draw_line :: proc(ctx: ^Context, start: Vec2, end: Vec2, thickness: f32, col: Color) {

    check_draw_call(ctx)

    z := ctx.curr_depth

    dx := end - start
    dy := glm.normalize0(Vec2{-dx.y, +dx.x})

    a := start + dy * thickness * 0.5
    b := end   + dy * thickness * 0.5
    c := end   - dy * thickness * 0.5
    d := start - dy * thickness * 0.5

    append(&ctx.vertices, Vertex{pos = {a.x, a.y, z}, col = col, uv = {0, 0}})
    append(&ctx.vertices, Vertex{pos = {b.x, b.y, z}, col = col, uv = {1, 0}})
    append(&ctx.vertices, Vertex{pos = {c.x, c.y, z}, col = col, uv = {1, 1}})

    append(&ctx.vertices, Vertex{pos = {c.x, c.y, z}, col = col, uv = {1, 1}})
    append(&ctx.vertices, Vertex{pos = {d.x, d.y, z}, col = col, uv = {0, 1}})
    append(&ctx.vertices, Vertex{pos = {a.x, a.y, z}, col = col, uv = {0, 0}})
}

draw_circle :: proc(ctx: ^Context, center: Vec2, radius: f32, col: Color, segments: int = 32) {
    draw_ellipse(ctx, center, {radius, radius}, col, segments)
}

draw_ellipse :: proc(ctx: ^Context, center: Vec2, #no_broadcast radii: Vec2, col: Color, segments: int = 32) {

    check_draw_call(ctx)

    z := ctx.curr_depth

    c := Vertex{pos = { center.x, center.y, z}, col = col}

    for i in 0..<segments {
        t0 := f32(i+0)/f32(segments) * math.TAU
        t1 := f32(i+1)/f32(segments) * math.TAU

        a := c
        b := c

        a.pos.x += radii.x * math.cos(t0)
        a.pos.y += radii.y * math.sin(t0)

        b.pos.x += radii.x * math.cos(t1)
        b.pos.y += radii.y * math.sin(t1)

        append(&ctx.vertices, c)
        append(&ctx.vertices, a)
        append(&ctx.vertices, b)
    }

}