package slideshow

import r "../renderer"
import k "../kernel"
import wnd "../window"
import "core:strings"
import "core:strconv"
import stbi "vendor:stb/image"
import "core:mem"
import "core:fmt"

MouseState :: enum {
	DOWN,
	UP,
}

SlideShow :: struct {
	current_slide: int,
	items:         [128]Slide,
	slides_count:  int,
	images:        [dynamic]Image,
  mouse_pos:     [2]i32,
  mouse_state:   MouseState,
  r:             ^r.Renderer,
  key:           wnd.Key,
}

ColorBackground :: distinct r.Color
ImgBackground :: struct {
	tex_id: r.Texture,
	img_id: int,
}

None :: struct {}

Background :: union {
	ColorBackground,
	ImgBackground,
	None,
}

AbsolutePosition :: distinct [2]f32
RelativePosition :: distinct [2]f32
Position :: union {
	AbsolutePosition,
	RelativePosition,
}

AbsoluteSize :: distinct [2]f32
RelativeSize :: distinct [2]f32
Size :: union {
	AbsoluteSize,
	RelativeSize,
}

SlidePanel :: struct {
	bg:      Background,
	pos:     Position,
	size:    Size,
}

Slide :: struct {
	panels: k.ItemsStack(SlidePanel, 64),
	texts:  k.ItemsStack(SlideText, 128),
  _current_panel: int,
}

Image :: struct {
	w:       i32,
	h:       i32,
	channes: i32,
	buf:     [^]byte,
	path:    string,
}

TextVertPos :: enum {
	TOP,
	CENTER,
	BOTTOM,
}

TextHorzPos :: enum {
	LEFT,
	RIGHT,
	CENTER,
}

TextPos :: struct {
	horz: TextHorzPos,
	vert: TextVertPos,
}


SlideText :: struct {
	text:  string,
	fv:    int,
	color: r.Color,
	pos:   TextPos,
  panel_id: int,
}


/**
 ██████  ██████  ██       ██████  ██████  ███████ 
██      ██    ██ ██      ██    ██ ██   ██ ██      
██      ██    ██ ██      ██    ██ ██████  ███████ 
██      ██    ██ ██      ██    ██ ██   ██      ██ 
 ██████  ██████  ███████  ██████  ██   ██ ███████ 
-> Colors
from https://rosepinetheme.com/palette/ingredients/
*/
COLOR_TEXT :: r.Color{0xe0, 0xde, 0xf4, 0xff}
// #524f67
COLOR_SUBTLE :: r.Color{0x52, 0x4f, 0x67, 0xff}
// #9ccfd8
COLOR_FOAM :: r.Color{0x9c, 0xcf, 0xd8, 0xff}
// #f6c177
COLOR_GOLD :: r.Color{0xf6, 0xc1, 0x77, 0xff}
//#eb6f92
COLOR_LOVE :: r.Color{0xeb, 0xbf, 0x92, 0xff}
// #ebbcba
COLOR_ROSE :: r.Color{0xeb, 0xbc, 0xba, 0xff}
// #191724
COLOR_BASE :: r.Color{0x19, 0x16, 0x24, 0xff}
// #1f1d2e
COLOR_SURFACE :: r.Color{0x1f, 0x1d, 0x2e, 0xff}
// #26233a
COLOR_OVERLAY :: r.Color{0x26, 0x23, 0x3a, 0xff}
// #6e6a86
COLOR_MUTED :: r.Color{0x6e, 0x6a, 0x86, 0xff}
// #31748f
COLOR_PINE :: r.Color{0x31, 0x74, 0x8f, 0xff}
// #31748f
COLOR_IRIS :: r.Color{0x31, 0x74, 0x8f, 0xff}
// #21202e
COLOR_HIGHLIGHT_LOW :: r.Color{0x21, 0x20, 0x2e, 0xff}
// #403d52
COLOR_HIGHLIGHT_MED :: r.Color{0x40, 0x3d, 0x52, 0xff}
// #524f67
COLOR_HIGHLIGHT_HIGH :: r.Color{0x52, 0x4f, 0x67, 0xff}

/*
███████ ████████  █████  ████████ ███████ 
██         ██    ██   ██    ██    ██      
███████    ██    ███████    ██    █████   
     ██    ██    ██   ██    ██    ██      
███████    ██    ██   ██    ██    ███████ 
-> State functions                                          
*/                                          
get_current_slide :: #force_inline proc(s: ^SlideShow) -> ^Slide {
  assert(s.current_slide < len(s.items))
  return &s.items[s.current_slide]
}

/*

██████  ██████   █████  ██     ██ 
██   ██ ██   ██ ██   ██ ██     ██ 
██   ██ ██████  ███████ ██  █  ██ 
██   ██ ██   ██ ██   ██ ██ ███ ██ 
██████  ██   ██ ██   ██  ███ ███  
-> Draw functions                                  
*/

get_absolute_position :: #force_inline proc(w: i32, h: i32, pos: Position) -> AbsolutePosition {
	apos: AbsolutePosition
	switch p in pos {
	case AbsolutePosition:
		apos = p
	case RelativePosition:
		apos = AbsolutePosition{p.x * f32(w), p.y * f32(h)}
	}
	return apos
}

get_absolute_size :: #force_inline proc(w: i32, h: i32, size: Size) -> AbsoluteSize {
	asize: AbsoluteSize
	switch s in size {
	case AbsoluteSize:
		asize = s
	case RelativeSize:
		asize = AbsoluteSize{s.x * f32(w), s.y * f32(h)}
	}
	return asize
}

draw_bg :: #force_inline proc(slides: ^SlideShow, panel_id: int) {
  slide := get_current_slide(slides)
  panel : ^SlidePanel = &slide.panels.items[panel_id]
	width, height := wnd.get_size(slides.r.window_handle)
	abs_pos := get_absolute_position(width, height, panel.pos)
	abs_size := get_absolute_size(width, height, panel.size)

	for i := 0; i < slide.texts.id; i += 1 {
		text := &slide.texts.items[i]
    if text.panel_id != panel_id {
      continue
    }
		tw := f32(r.measure_text(slides.r, text.text, text.fv))
		th := f32(r.get_text_height(slides.r, text.fv))

		if tw > abs_size.x || th > abs_size.y {
			abs_size.x = tw > abs_size.x ? tw : abs_size.x
			abs_size.y = th > abs_size.y ? th : abs_size.y
		}
	}

	switch bg in panel.bg {
	case None:
		return
	case ImgBackground:
		r.render_quad(
			slides.r,
			abs_pos.x,
			abs_pos.y,
			abs_size.x,
			abs_size.y,
			{0xff, 0xff, 0xff, 0xff},
			bg.tex_id,
		)
	case ColorBackground:
		r.render_quad(
			slides.r,
			abs_pos.x,
			abs_pos.y,
			abs_size.x,
			abs_size.y,
			r.Color(bg),
			slides.r.white_tex.id,
		)
	}
}

draw_panel_text :: #force_inline proc(slides: ^SlideShow, slide: ^Slide, panel_id: int, text_id: int) {
  assert(panel_id < len(slide.panels.items))
  assert(slide != nil)
  panel := &slide.panels.items[panel_id]
	text := &slide.texts.items[text_id]
	assert(text != nil)
	width, height := wnd.get_size(slides.r.window_handle)
	abs_pos := get_absolute_position(width, height, panel.pos)
	abs_size := get_absolute_size(width, height, panel.size)
	x, y: i32
	text_width := f32(r.measure_text(slides.r, text.text, text.fv))
	text_height := f32(r.get_text_height(slides.r, text.fv))
  if text_width > abs_size.x {
    abs_size.x = text_width
  }
  if text_height > abs_size.y {
    abs_size.y = text_height
  }
	switch text.pos.horz {
	case .LEFT:
		x = i32(abs_pos.x)
	case .RIGHT:
		x = i32(abs_pos.x + abs_size.x - text_width)
	case .CENTER:
		x = i32(abs_pos.x + abs_size.x / 2 - text_width / 2)
	}
	switch text.pos.vert {
	case .TOP:
		y = i32(abs_pos.y)
	case .BOTTOM:
		y = i32(abs_pos.y + abs_size.y - text_height)
	case .CENTER:
		y = i32(abs_pos.y + abs_size.y / 2 - text_height / 2)
	}

	r.render_text(slides.r, text.text, {x, y}, text.color, text.fv)
}

render_slides :: proc(slides: ^SlideShow) {
	if slides.slides_count > 0 {
		slide := &slides.items[slides.current_slide]
		for i := 0; i < slide.panels.id; i += 1 {
			draw_bg(slides, i)
      for tid := 0; tid < slide.texts.id; tid += 1 {
        panel_id := slide.texts.items[tid].panel_id
        if panel_id == i {
          draw_panel_text(slides, slide, i, tid)
        }
      }
		}
	}
}

draw_frame :: proc(slides: ^SlideShow, fv: int) {
  rndr := slides.r
  ww, wh := wnd.get_size(rndr.window_handle)
	current_bytes: [8]byte
  count_bytes: [8]byte

	current := strconv.itoa(current_bytes[:], slides.current_slide + 1)
	count := strconv.itoa(count_bytes[:], slides.slides_count)

  width := r.measure_text(rndr, current, fv)
  width += r.measure_text(rndr, "/", fv)
  width += r.measure_text(rndr, count, fv)


	x: i32 = ww / 2 - width / 2

  fvh := r.get_text_height(rndr, fv)
  y := wh - fvh - 8

	x += r.render_text(rndr, current, {x, y}, {0xff, 0xff, 0xff, 0xff}, fv)
	x += r.render_text(rndr, "/", {x, y}, {0xff, 0xff, 0xff, 0xff}, fv)
	r.render_text(rndr, count, {x, y}, {0xff, 0xff, 0xff, 0xff}, fv)
}

/*

███    ███  █████  ██   ██ ███████     ███████ ██   ██  ██████  ██     ██ 
████  ████ ██   ██ ██  ██  ██          ██      ██   ██ ██    ██ ██     ██ 
██ ████ ██ ███████ █████   █████       ███████ ███████ ██    ██ ██  █  ██ 
██  ██  ██ ██   ██ ██  ██  ██               ██ ██   ██ ██    ██ ██ ███ ██ 
██      ██ ██   ██ ██   ██ ███████     ███████ ██   ██  ██████   ███ ███  
-> Make show functions                                                                          
*/

load_image_to_texture :: proc(
  slides: ^SlideShow,
  img_id: int
) -> (id: u32, ok: bool) {
	if len(slides.images) < img_id {
    return 0, false
	}
	img := &slides.images[img_id]
	assert(img != nil)
  return r.load_image_to_texture(
    int(img.w),
    int(img.h),
    img.buf,
    int(img.channes)
  )
}

begin_slide :: proc(slides: ^SlideShow) {
  assert(slides.slides_count < len(slides.items))
  slides.slides_count += 1
  slides.current_slide = slides.slides_count - 1
}

end_slide :: proc(slides: ^SlideShow) {
  slide := get_current_slide(slides)
  assert(slide._current_panel == 0)
  slides.current_slide = 0
}

begin_panel :: proc(s: ^SlideShow, pos: Position, size: Size) {
  slide := get_current_slide(s)
  assert(slide.panels.id < len(slide.panels.items)) 
  slide.panels.id += 1
  slide._current_panel = slide.panels.id - 1
  panel := get_current_panel(get_current_slide(s))
  panel.pos = pos
  panel.size = size
}

end_panel :: proc(s: ^SlideShow) {
  slide := get_current_slide(s)
  slide._current_panel = 0
}

get_current_panel :: #force_inline proc(slide: ^Slide) -> ^SlidePanel {
  return &slide.panels.items[slide._current_panel]
}

set_panel_color :: proc(s: ^SlideShow, color: r.Color) {
  slide := get_current_slide(s)
  panel := get_current_panel(slide)
  panel.bg = ColorBackground(color)
}

load_image :: proc(slides: ^SlideShow, path: string) -> int {
	for img, indx in slides.images {
		if strings.compare(path, img.path) == 0 {
			return indx
		}
	}

	img := Image{}
	img.buf = stbi.load(strings.clone_to_cstring(path), &img.w, &img.h, &img.channes, 0)
	if img.buf == nil {
		return -1
	}
	append(&slides.images, img)
	return len(slides.images) - 1
}

set_panel_image :: proc(s: ^SlideShow, path: string) {
  img_id := load_image(s, path)
	assert(img_id >= 0, "fail to load img")
	tex_id, ok := load_image_to_texture(s, img_id)
	assert(ok, "fail to load texture to gpu")

  slide := get_current_slide(s)

	id := slide.panels.id
	assert(id <= len(slide.panels.items))
  panel := get_current_panel(slide)
  panel.bg = ImgBackground{tex_id = r.Texture(tex_id), img_id = img_id}
}



slide_text :: proc(
  slides: ^SlideShow,
  text: string,
  color: r.Color = COLOR_TEXT,
  pos: TextPos = {.CENTER, .CENTER},
  fv: int = 1
) {
  slide := get_current_slide(slides)
  add_slide_text(slide, slide._current_panel, text, color, pos, fv)
}

add_slide_text :: proc(
	slide: ^Slide,
	panel_id: int,
	text: string,
	color: r.Color,
	pos: TextPos = {.CENTER, .CENTER},
	fv: int = 1,
) {
  assert(fv != 0)
	id := slide.texts.id
	assert(id <= len(slide.texts.items))
	slide.texts.id += 1

	slide.texts.items[id] = SlideText {
		color = color,
		text  = text,
		fv    = fv,
		pos   = pos,
    panel_id = panel_id,
	}
}

clean_show :: proc(slides: ^SlideShow) {
  for i := 0; i < slides.slides_count; i += 1 {
    slide := &slides.items[i]
    slide._current_panel = 0
    mem.zero_slice(slide.panels.items[0:slide.panels.id])
    mem.zero_slice(slide.texts.items[0:slide.texts.id])
    slide.texts.id = 0
    slide.panels.id = 0
  }

  slides.current_slide = 0
  slides.slides_count = 0
}

/*

███████ ██    ██ ███████ ███    ██ ████████ ███████ 
██      ██    ██ ██      ████   ██    ██    ██      
█████   ██    ██ █████   ██ ██  ██    ██    ███████ 
██       ██  ██  ██      ██  ██ ██    ██         ██ 
███████   ████   ███████ ██   ████    ██    ███████ 
-> Handle Events                                                    
*/
                                                    
handle_keys :: #force_inline proc(slides: ^SlideShow) {
  if slides.key == wnd.Key.KEY_L {
    slides.current_slide =
			(slides.current_slide + 1) % slides.slides_count
  }
  if slides.key == wnd.Key.KEY_H {
    slides.current_slide = (slides.current_slide - 1)
    if slides.current_slide < 0 {
      slides.current_slide = slides.slides_count + slides.current_slide
    }
  }  
}

