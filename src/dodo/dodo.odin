#+build js wasm32, js wasm64p32

package dodo

import js "core:sys/wasm/js"
import gl "vendor:wasm/WebGL"
import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Color :: [4]u8

Context :: struct {
    canvas_id: string,
    accum_time: f32,

    user_data: rawptr,
    user_index: int,

    program: gl.Program,
    vertex_buffer: gl.Buffer,

    update: Update_Proc,
    fini: Fini_Proc,

    camera:     Camera,
    vertices:   [dynamic]Vertex,
    draw_calls: [dynamic]Draw_Call,
    curr_depth: f32,

    is_done: bool,

    _next: ^Context,
}

Update_Proc :: proc(ctx: ^Context, dt: f32)
Fini_Proc :: proc(ctx: ^Context)

Camera :: struct {
    offset:            Vec2,
    target:            Vec2,
    rotation_radians:  f32,
    zoom:              f32,
    near:              f32,
    far:               f32,
}
Camera_Default :: Camera{
    zoom = 1,
    near = -1024,
    far  = +1024,
}

Vertex :: struct {
    pos: Vec3,
    col: Color,
    uv:  Vec2,
}

Draw_Call :: struct {
    program: gl.Program,
    texture: gl.Texture,
    offset: int,
    length: int,
}

@(private)
global_context_list: ^Context

init :: proc(ctx: ^Context, canvas_id: string, update: Update_Proc, fini: Fini_Proc = nil) -> bool {
    fmt.println("Hellope")

    ctx.canvas_id = canvas_id

    gl.CreateCurrentContextById(canvas_id, gl.DEFAULT_CONTEXT_ATTRIBUTES) or_return
    assert(gl.IsWebGL2Supported(), "WebGL2 must be supported")
    gl.SetCurrentContextById(ctx.canvas_id) or_return

    if update == nil {
        return false
    }
    ctx.update = update
    ctx.fini = fini
    ctx.camera = Camera_Default

    ctx.program = gl.CreateProgramFromStrings({shader_header, shader_vert}, {shader_header, shader_frag}) or_return

    reserve(&ctx.vertices, 1<<20)
    reserve(&ctx.draw_calls, 1<<12)

    ctx.vertex_buffer = gl.CreateBuffer()
    gl.BindBuffer(gl.ARRAY_BUFFER, ctx.vertex_buffer)
    gl.BufferData(gl.ARRAY_BUFFER, len(ctx.vertices)*size_of(ctx.vertices[0]), raw_data(ctx.vertices), gl.DYNAMIC_DRAW)

    ctx._next = global_context_list
    global_context_list = ctx

    return true
}

fini :: proc(ctx: ^Context) {
    if ctx.fini != nil {
        ctx->fini()
    }
    gl.SetCurrentContextById(ctx.canvas_id)

    gl.DeleteBuffer(ctx.vertex_buffer)
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

        resize_canvas_to_client(ctx.canvas_id)

        ctx.update(ctx, dt)

        draw_all(ctx)
    }
    
    return true
}


@(private)
draw_all :: proc(ctx: ^Context) -> bool {

    gl.SetCurrentContextById(ctx.canvas_id) or_return

    gl.BindBuffer(gl.ARRAY_BUFFER, ctx.vertex_buffer)
    gl.BufferData(gl.ARRAY_BUFFER, len(ctx.vertices)*size_of(ctx.vertices[0]), raw_data(ctx.vertices), gl.DYNAMIC_DRAW)
    defer {
        clear(&ctx.vertices)
        clear(&ctx.draw_calls)
        ctx.curr_depth = 0
    }

    width, height := gl.DrawingBufferWidth(), gl.DrawingBufferHeight()
    aspect_ratio := f32(max(width, 1))/f32(max(height, 1))

    gl.Viewport(0, 0, width, height)
    gl.ClearColor(0.3, 0.3, 0.3, 1.0)
    gl.Enable(gl.DEPTH_TEST)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    gl.UseProgram(ctx.program)

    {
        a_pos := gl.GetAttribLocation(ctx.program, "a_pos")
        gl.EnableVertexAttribArray(a_pos)
        gl.VertexAttribPointer(a_pos, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
    }
    {
        a_col := gl.GetAttribLocation(ctx.program, "a_col")
        gl.EnableVertexAttribArray(a_col)
        gl.VertexAttribPointer(a_col, 4, gl.UNSIGNED_BYTE, true, size_of(Vertex), offset_of(Vertex, col))
    }
    {
        a_uv := gl.GetAttribLocation(ctx.program, "a_uv")
        fmt.println("uv", a_uv)
        gl.EnableVertexAttribArray(a_uv)
        gl.VertexAttribPointer(a_uv, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))
    }
    {

        proj := glm.mat4Ortho3d(0, f32(width), f32(height), 0, ctx.camera.near, ctx.camera.far)

        origin := glm.mat4Translate({-ctx.camera.target.x, -ctx.camera.target.y, 0})
        rotation := glm.mat4Rotate({0, 0, 1}, ctx.camera.rotation_radians)
        scale := glm.mat4Scale({ctx.camera.zoom, ctx.camera.zoom, 1})
        translation := glm.mat4Translate({ctx.camera.offset.x, ctx.camera.offset.y, 0})
        view := origin * scale * rotation * translation

        mvp := proj * view

        gl.UniformMatrix4fv(gl.GetUniformLocation(ctx.program, "u_mvp"), mvp)
    }

    if len(ctx.draw_calls) > 0 {
        last := &ctx.draw_calls[len(ctx.draw_calls)-1]
        last.length = len(ctx.vertices)-last.offset
    }

    for dc in ctx.draw_calls {
        gl.DrawArrays(gl.TRIANGLES, dc.offset, dc.length)
    }


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

layout(location = 0) in vec3 a_pos;
layout(location = 1) in vec4 a_col;
layout(location = 2) in vec2 a_uv;

out vec4 v_color;
out vec2 v_uv;

void main() {
    gl_Position = u_mvp * vec4(a_pos, 1.0);
    v_color = a_col;
    v_uv = a_uv;
}
`

shader_frag := `

precision highp float;

in vec4 v_color;
in vec2 v_uv;
 
out vec4 outColor;

void main() {
    outColor = v_color, 1.0;
}
`