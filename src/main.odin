#+build js wasm32, js wasm64p32

package main

import "dodo"
import "core:math"

ctx1: dodo.Context
ctx2: dodo.Context

update :: proc(ctx: ^dodo.Context, dt: f32) {

    dodo.draw_quad(ctx, {
        { pos = { 10, 100, 0}, col = {255,   0,   0, 255}},
        { pos = {100, 100, 0}, col = {255, 255,   0, 255}},
        { pos = {100,  10, 0}, col = {  0, 255,   0, 255}},
        { pos = { 10,  10, 0}, col = {  0, 255,   0, 255}}
    })

    ctx.curr_depth = +1
    dodo.draw_rect(ctx, {50 + math.mod(ctx.accum_time, 3) * 50, 50}, {32, 64}, {255, 0, 255, 255})

    dodo.draw_line(ctx, {300, 300}, {500, 300}, 2, {200, 100, 50, 255})

    dodo.draw_circle(ctx, {300, 300}, 40, {0, 255, 100, 255})
    dodo.draw_ellipse(ctx, {500, 300}, {60, 40}, {0, 255, 100, 255})
}

main :: proc() {

    dodo.init(&ctx1, "canvas1", update)
    dodo.init(&ctx2, "canvas2", proc(ctx: ^dodo.Context, dt: f32) {
        ctx.is_done = true
    })
}