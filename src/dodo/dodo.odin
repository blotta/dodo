#+build js wasm32, js wasm64p32

package dodo

import js "core:sys/wasm/js"
import gl "vendor:wasm/WebGL"
import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"

Context :: struct {
    canvas_id: string,
    accum_time: f32,

    user_data: rawptr,
    user_index: int,

    program: gl.Program,
    buffer: gl.Buffer,

    step: Step_Proc,
    fini: Fini_Proc,

    is_done: bool,

    _next: ^Context,
}

Step_Proc :: proc(ctx: ^Context, dt: f32)
Fini_Proc :: proc(ctx: ^Context)

@(private)
global_context_list: ^Context

init :: proc(ctx: ^Context, canvas_id: string, step: Step_Proc, fini: Fini_Proc = nil) -> bool {
    fmt.println("Hellope")

    ctx.canvas_id = canvas_id

    gl.CreateCurrentContextById(canvas_id, gl.DEFAULT_CONTEXT_ATTRIBUTES) or_return
    assert(gl.IsWebGL2Supported(), "WebGL2 must be supported")
    gl.SetCurrentContextById(ctx.canvas_id) or_return

    if step == nil {
        return false
    }
    ctx.step = step

    ctx.program = gl.CreateProgramFromStrings({shader_header, shader_vert}, {shader_header, shader_frag}) or_return

    vertices := [][5]f32{
        {-0.5, +0.5, 1.0, 0.0, 0.0},
        {+0.5, +0.5, 0.0, 1.0, 0.0},
        {+0.5, -0.5, 1.0, 1.0, 0.0},

        {+0.5, -0.5, 1.0, 1.0, 0.0},
        {-0.5, -0.5, 0.0, 0.0, 1.0},
        {-0.5, +0.5, 1.0, 0.0, 0.0},
    }

    ctx.buffer = gl.CreateBuffer()
    gl.BindBuffer(gl.ARRAY_BUFFER, ctx.buffer)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

    ctx._next = global_context_list
    global_context_list = ctx

    return true
}

fini :: proc(ctx: ^Context) {
    if ctx.fini != nil {
        ctx->fini()
    }

    gl.ClearColor(0.0, 0.0, 0.0, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)

    gl.DeleteBuffer(ctx.buffer)
    gl.DeleteProgram(ctx.program)
}

// @(export)
// step :: proc(curr_time_step: f64) {
@(export)
step :: proc(dt: f32) -> (keep_going: bool) {
    for ctx := global_context_list; ctx != nil; ctx = ctx._next {
        ctx.accum_time += dt

        if ctx.is_done {
            p := &global_context_list
            for p^ != ctx {
                p = &p^._next
            }
            p^ = ctx._next

            fini(ctx)

            continue
        }

        gl.SetCurrentContextById(ctx.canvas_id) or_continue

        ctx.step(ctx, dt)

        draw(ctx)
    }
    
    return true
}

draw :: proc(ctx: ^Context) -> bool {

    resize_canvas_to_client(ctx.canvas_id)

    width, height := gl.DrawingBufferWidth(), gl.DrawingBufferHeight()
    aspect_ratio := f32(max(width, 1))/f32(max(height, 1))

    gl.Viewport(0, 0, width, height)
    gl.ClearColor(0.3, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)

    gl.UseProgram(ctx.program)

    {
        loc := gl.GetAttribLocation(ctx.program, "a_position")
        gl.EnableVertexAttribArray(loc)
        gl.VertexAttribPointer(loc, 2, gl.FLOAT, false, size_of([5]f32), 0)
    }
    {
        loc := gl.GetAttribLocation(ctx.program, "a_color")
        gl.EnableVertexAttribArray(loc)
        gl.VertexAttribPointer(loc, 3, gl.FLOAT, false, size_of([5]f32), size_of([2]f32))
    }
    {
        proj := glm.mat4Perspective(glm.radians_f32(60), aspect_ratio, 0.1, 100)
        view := glm.mat4LookAt({1.2, 1.2, 1.2}, {0, 0, 0}, {0, 0, 1})
        model := glm.mat4Rotate({0, 0, 1}, f32(ctx.accum_time))

        mvp := proj * view * model

        loc := gl.GetUniformLocation(ctx.program, "u_mvp")
        gl.UniformMatrix4fv(loc, mvp)
    }

    gl.BindBuffer(gl.ARRAY_BUFFER, ctx.buffer)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)

    return true
}

resize_canvas_to_client :: proc(canvas_id: string) {
    // fmt.println(js.get_element_key_f64("dodo-canvas", "width"), js.get_element_key_f64("dodo-canvas", "height"))
    displayWidth := js.get_element_key_f64(canvas_id, "clientWidth")
    displayHeight := js.get_element_key_f64(canvas_id, "clientHeight")
    canvasWidth := js.get_element_key_f64(canvas_id, "width")
    canvasHeight := js.get_element_key_f64(canvas_id, "height")

    if canvasWidth != displayWidth || canvasHeight != displayHeight {
        js.set_element_key_f64(canvas_id, "width", displayWidth)
        js.set_element_key_f64(canvas_id, "height", displayHeight)
        fmt.println("resize!")
    }
}

shader_header := "#version 300 es\n"

shader_vert := `

uniform mat4 u_mvp;

in vec4 a_position;
in vec3 a_color;

out vec3 v_color;

void main() {
    gl_Position = u_mvp * a_position;
    v_color = a_color;
}
`

shader_frag := `

precision highp float;

in vec3 v_color;
 
out vec4 outColor;

void main() {
    outColor = vec4(v_color, 1.0); //vec4(1.0, 0.5, 0.0, 1.0);
}
`