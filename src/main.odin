#+build js wasm32, js wasm64p32

package main

// import "dodo"
import js "core:sys/wasm/js"
import gl "vendor:wasm/WebGL"
import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"

GL_CTX_NAME :: "dodo-canvas"

Context :: struct {
    accum_time: f64,
    program: gl.Program,
    buffer: gl.Buffer
}

global_ctx: Context

// @(export)
// step :: proc(curr_time_step: f64) {
@(export)
step :: proc(dt: f64) -> (keep_going: bool) {
    ctx := &global_ctx

    ctx.accum_time += dt

    _ = do_draw(ctx)
    
    return true
}

do_draw :: proc(ctx: ^Context) -> bool {
    gl.SetCurrentContextById(GL_CTX_NAME) or_return

    resize_canvas_to_client()

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

resize_canvas_to_client :: proc() {
    // fmt.println(js.get_element_key_f64("dodo-canvas", "width"), js.get_element_key_f64("dodo-canvas", "height"))
    displayWidth := js.get_element_key_f64("dodo-canvas", "clientWidth")
    displayHeight := js.get_element_key_f64("dodo-canvas", "clientHeight")
    canvasWidth := js.get_element_key_f64("dodo-canvas", "width")
    canvasHeight := js.get_element_key_f64("dodo-canvas", "height")

    if canvasWidth != displayWidth || canvasHeight != displayHeight {
        js.set_element_key_f64(GL_CTX_NAME, "width", displayWidth)
        js.set_element_key_f64(GL_CTX_NAME, "height", displayHeight)
        fmt.println("resize!")
    }
}

main :: proc() {
    fmt.println("Hellope")

    resize_canvas_to_client()


   _ = gl.CreateCurrentContextById(GL_CTX_NAME, gl.DEFAULT_CONTEXT_ATTRIBUTES)

    major, minor: i32
    gl.GetWebGLVersion(&major, &minor)
    fmt.println("WebGL Version", major, minor)

    ctx := &global_ctx

    ok: bool
    ctx.program, ok = gl.CreateProgramFromStrings({shader_header, shader_vert}, {shader_header, shader_frag})
    assert(ok)

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