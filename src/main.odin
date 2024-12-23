#+build js wasm32, js wasm64p32

package main

import "dodo"

ctx1: dodo.Context
ctx2: dodo.Context

step :: proc(ctx: ^dodo.Context, dt: f32) {

}

main :: proc() {

    dodo.init(&ctx1, "canvas1", step)
    dodo.init(&ctx2, "canvas2", proc(ctx: ^dodo.Context, dt: f32) {
        ctx.is_done = true
    })
}