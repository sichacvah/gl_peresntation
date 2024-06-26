package presentation

import r "../renderer"
import w "../window"
import show "../slideshow" 
import "core:mem"
import "core:fmt"


WIDTH :: 1920
HEIGHT :: 1080


FontDecl :: struct {
	name: string,
	path: string,
	size: int,
}
default_fonts := []FontDecl {
	{name = "p", path = "./resources/JetBrainsMono-Regular.ttf", size = 48},
	{name = "h", path = "./resources/JetBrainsMono-Regular.ttf", size = 96},
	{name = "s", path = "./resources/JetBrainsMono-Regular.ttf", size = 24},
}
P :: 1
H :: 2
S :: 3

init_fonts :: proc(rndr: ^r.Renderer, allocator: mem.Allocator, fonts: []FontDecl) {
	for decl in default_fonts {
		r.init_font(rndr, allocator, decl.name, decl.path)
		r.init_font_variant(rndr, allocator, decl.name, decl.size)
	}
}

presentation_init :: proc(slides: ^show.SlideShow) -> bool {
  renderer := r.renderer_init(context.allocator)
  if renderer == nil {
    return false
  }
  ok : bool
  renderer.window_handle, ok = w.init_window(
    WIDTH,
    HEIGHT,
    "Slide show",
    renderer,
  )
  if !ok {
    fmt.eprintln("Can't init window") 
    return false
  }
  r.init_gl()
  init_fonts(renderer, context.allocator, default_fonts)
  r.init_resources(renderer)
  slides.r = renderer 
  r.change_shader(renderer, .ui)

  return true
}

process_events :: #force_inline proc(slides: ^show.SlideShow) {
	rndr := slides.r
	xraw, yraw := w.get_cursor_pos(rndr.window_handle)
	slides.mouse_pos = {i32(xraw), i32(yraw)}
	slides.mouse_state =
		w.get_mouse_btn(rndr.window_handle, .MOUSE_BUTTON_LEFT) == .RELEASE ? .UP : .DOWN

  slides.key = .None
  if w.get_key(rndr.window_handle, .KEY_L) == .PRESS {
    slides.key = .KEY_L
  }
  if w.get_key(rndr.window_handle, .KEY_H) == .PRESS {
    slides.key = .KEY_H
  }  
}


process_frame :: proc(slides: ^show.SlideShow) {
	show.render_slides(slides)
	show.draw_frame(slides, S)
}

presentation_update :: proc(slides: ^show.SlideShow) -> bool {
  if slides == nil || slides.r == nil {
    return false
  }
  renderer := slides.r

  w.wait_events(renderer.window_handle)
  process_events(slides) 
  process_events(slides) 
  process_frame(slides)
  show.handle_keys(slides)
  r.flush(renderer)
  r.clean(renderer)
  process_frame(slides)
  r.flush(renderer)
  w.swap_buffers(renderer.window_handle)
  should_close := w.should_close(renderer.window_handle)
  return !should_close
}

clean :: proc(slides: ^show.SlideShow) {
  show.clean_show(slides)
}


presentation_shutdown :: proc(slides: ^show.SlideShow) {
  if slides != nil {
    handle := slides.r.window_handle
    w.destroy_window(handle)
    free(slides)
  }
}
