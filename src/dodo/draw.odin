#+build js wasm32, js wasm64p32

package dodo

import glm "core:math/linalg"

draw_rect :: proc(ctx: ^Context, pos: Vec2, size: Vec2, col: Color) {
    if len(ctx.draw_calls) == 0 {
        append(&ctx.draw_calls, Draw_Call{})
    }

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
    if len(ctx.draw_calls) == 0 {
        append(&ctx.draw_calls, Draw_Call{})
    }

    z := ctx.curr_depth

    append(&ctx.vertices, verts[0], verts[1], verts[2])
    append(&ctx.vertices, verts[2], verts[3], verts[0])
}

draw_line :: proc(ctx: ^Context, start: Vec2, end: Vec2, thickness: f32, col: Color) {
    if len(ctx.draw_calls) == 0 {
        append(&ctx.draw_calls, Draw_Call{})
    }

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
