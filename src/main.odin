#+build js wasm32, js wasm64p32

package main

import "dodo"
import "core:math"

ctx1: dodo.Context
ctx2: dodo.Context

update :: proc(ctx: ^dodo.Context, dt: f32) {

    dodo.draw_quad(ctx, {{ 10, 100}, {100, 100}, {100,  10}, { 10,  10}}, {0,   0, 255, 255})

    dodo.draw_rect(ctx, {50 + math.mod(ctx.accum_time, 3) * 50, 50}, {32, 64}, {255, 0, 255, 155})

    dodo.draw_line(ctx, {300, 300}, {500, 300}, 2, {200, 100, 50, 255})

    dodo.draw_circle(ctx, {300, 300}, 40, {0, 255, 100, 255})
    dodo.draw_ellipse(ctx, {500, 300}, {60, 40}, {0, 255, 100, 255})

    dodo.draw_ring(ctx, {400, 100}, 40, 50, math.PI, 0.75*math.TAU, {255, 255, 0, 255})
    dodo.draw_sector(ctx, {400, 100}, 15, 0.75*math.TAU, math.TAU, {255,   0, 0, 255})
    dodo.draw_sector_lines(ctx, {400, 100}, 45, 10, 0.75*math.TAU, math.TAU, {255,   0, 0, 255})

    dodo.draw_ellipse_ring(ctx, {400, 100}, {40, 80}, {50, 90}, 0, 0.5*math.PI, {0, 255, 0, 255})
    dodo.draw_ellipse_lines(ctx, {400, 100}, {45, 85}, 10, 0.25*math.TAU, 0.5*math.TAU, {30, 30, 120, 255})

    dodo.draw_rect_lines(ctx, {100, 300}, {100, 100}, 15, {0, 0, 0, 255})
    dodo.draw_rect(ctx, {100, 300}, {100, 100}, {40, 40, 40, 255})

    dodo.draw_triangle(ctx, {50, 100}, {110, 80}, {90, 120}, {100, 50, 150, 255})
    dodo.draw_triangle_lines(ctx, {50, 100}, {110, 80}, {90, 120}, 3, {200, 150, 250, 255})
}

main :: proc() {

    dodo.init(&ctx1, "canvas1", update)
    dodo.init(&ctx2, "canvas2", proc(ctx: ^dodo.Context, dt: f32) {
        ctx.is_done = true
    })
}