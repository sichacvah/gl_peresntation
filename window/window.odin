package window


import gl "vendor:OpenGL"
import "vendor:glfw"
import "core:fmt"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

init_window :: proc(width: int, height: int, title: cstring, userdata: rawptr = nil) -> (handle: rawptr, ok: bool) {
  if !glfw.Init() {
    return nil, false
  }
	when ODIN_DEBUG {
		glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, true)
	}
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.SAMPLES, 4)

	handle = glfw.CreateWindow(i32(width), i32(height), title, nil, nil)

	glfw.SetWindowUserPointer(glfw.WindowHandle(handle), userdata)

	glfw.MakeContextCurrent(glfw.WindowHandle(handle))
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	glfw.SetInputMode(glfw.WindowHandle(handle), glfw.STICKY_MOUSE_BUTTONS, 1)
	return handle, true
}

destroy_window :: proc(handle: rawptr) {
	glfw.Terminate()
	glfw.DestroyWindow(glfw.WindowHandle(handle))
}

get_size :: #force_inline proc(handle: rawptr) -> (width: i32, heigth: i32) {
	return glfw.GetWindowSize(glfw.WindowHandle(handle))
}

get_cursor_pos :: #force_inline proc(handle: rawptr) -> (x: f64, y: f64) {
  return glfw.GetCursorPos(glfw.WindowHandle(handle))
}

get_mouse_btn :: #force_inline proc(handle: rawptr, btn: MouseBtn) -> KeyState {
  return KeyState(glfw.GetMouseButton(glfw.WindowHandle(handle), i32(btn)))
}

should_close :: #force_inline proc(handle: rawptr) -> bool {
  return bool(glfw.WindowShouldClose(glfw.WindowHandle(handle)))
}

wait_events :: #force_inline proc(handle: rawptr) {
  glfw.WaitEvents()
}

swap_buffers :: #force_inline proc(handle: rawptr) {
  glfw.SwapBuffers(glfw.WindowHandle(handle))
}

MouseBtn :: enum {
  MOUSE_BUTTON_LEFT = 0,
  MOUSE_BUTTON_RIGHT = 1,
  MOUSE_BUTTON_MIDDLE = 2,
}

KeyState :: enum {
  RELEASE = 0,
  PRESS = 1,
  REPEAT = 2,
}

// TODO: add all keys
Key :: enum {
  None  = 0, 
  KEY_H = 72,
  KEY_J = 74,
  KEY_K = 75,
  KEY_L = 76,
}

get_key :: #force_inline proc(handle: rawptr, key: Key) -> KeyState {
  return KeyState(glfw.GetKey(glfw.WindowHandle(handle), i32(key)))
}

