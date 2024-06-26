package slides

import show "../slideshow" 
import "core:mem"
import "core:fmt"

Presentation :: struct {
	slides: show.SlideShow,
}

p_mem: ^Presentation

@(export)
make_slides :: proc() -> ^show.SlideShow {
  if p_mem == nil {
    p_mem = new(Presentation)
  }
  slides := &p_mem.slides

  show.begin_slide(slides)
    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.2},
      show.RelativeSize{1, 0.4}
    )
      show.slide_text(slides, "Рендеринг текста ", fv = 2)

    show.end_panel(slides)
    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.4},
      show.RelativeSize{1, 0.2}
    )
      show.slide_text(slides, "в современных приложениях", fv = 2)

    show.end_panel(slides)
  show.end_slide(slides)

  show.begin_slide(slides)
    show.begin_panel(
      slides,
      show.AbsolutePosition{160, 160},
      show.AbsoluteSize{120, 250}
    )

      show.set_panel_color(slides, show.COLOR_MUTED)
    show.end_panel(slides)
  show.end_slide(slides)

  return slides
}

@(export)
slides_mem :: proc() -> rawptr {
  return p_mem
}

@(export)
slides_hot_reload :: proc(m: ^Presentation) {
  assert(m != nil, "memory not provided")
  current_slide := m.slides.current_slide 
  p_mem = m 
  p_mem.slides.r = m.slides.r
  show.clean_show(&p_mem.slides)
  make_slides()
  if current_slide < p_mem.slides.slides_count {
    p_mem.slides.current_slide = current_slide
  }
}
