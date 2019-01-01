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
  show.init_slide_show(slides)

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
      show.slide_text(slides, "в приложениях", fv = 2)

    show.end_panel(slides) 
  show.end_slide(slides)

  show.begin_slide(slides)
    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.02},
      show.RelativeSize{1, 1},
    )
      show.slide_text(slides, "Кодировки:", pos = {.CENTER, .TOP})
    show.end_panel(slides) 

    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.1},
      show.RelativeSize{1, 1},
    )
      show.slide_text(slides, "ASCII", pos = {.CENTER, .TOP})
    show.end_panel(slides)

    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.15},
      show.RelativeSize{1, 1},
    )
      show.slide_text(slides, "UTF-8", pos = {.CENTER, .TOP}, color = show.COLOR_GOLD)
    show.end_panel(slides)

    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.2},
      show.RelativeSize{1, 1},
    )
      show.slide_text(slides, "UTF-16", pos = {.CENTER, .TOP}, color = show.COLOR_ROSE)
    show.end_panel(slides)

    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.25},
      show.RelativeSize{1, 1},
    )
      show.slide_text(slides, "UTF-32", pos = {.CENTER, .TOP}, color = show.COLOR_PINE)
    show.end_panel(slides)

  show.end_slide(slides)

  show.begin_slide(slides)
    show.begin_panel(
      slides,
      show.RelativePosition{0, 0.02},
      show.RelativeSize{1, 1}
    )
      show.slide_text(slides, "ASCII", pos = {.CENTER, .TOP})
    show.end_panel(slides)
    show.begin_panel(
      slides,
      show.RelativePosition{0.05, 0.1},
      show.RelativeSize{1, 1}
    )
      show.slide_text(slides, "American standard code for information interchange", pos = {.LEFT, .TOP})
    show.end_panel(slides)
    show.begin_panel(
      slides,
      show.RelativePosition{0.05, 0.15},
      show.RelativeSize{1, 1}
    )
      show.slide_text(slides, "Размер одного символа - 7 bits", pos = {.LEFT, .TOP})
    show.end_panel(slides)

    show.begin_panel(
      slides,
      show.RelativePosition{0.05, 0.2},
      show.AbsoluteSize{64, 64}
    )

      show.set_panel_color(slides, show.COLOR_LOVE)
      show.slide_text(slides, "0")
    show.end_panel(slides)

    for i := 1; i < 8; i += 1 {
      show.begin_panel(
        slides,
        show.RelativePosition{0.05 + 0.055 * f32(i), 0.2},
        show.AbsoluteSize{64, 64},
      )
        show.set_panel_color(slides, show.COLOR_PINE)
        show.slide_text(slides, "1")
      show.end_panel(slides)
    }

  show.end_slide(slides)

  show.begin_slide(slides)
    show.begin_panel(
      slides,
      show.AbsolutePosition{0, 16},
      show.RelativeSize{1, 1}
    )
      show.slide_text(slides, "Cсылки:", fv = 1, pos = {.CENTER, .TOP})
    show.end_panel(slides)
    show.begin_panel(
      slides,
      show.AbsolutePosition{100, 100},
      show.AbsoluteSize{200, 200}
    )
      show.set_panel_image(slides, "./slides/qr.png")
    show.end_panel(slides)
    show.begin_panel(
      slides,
      show.AbsolutePosition{316, 148},
      show.AbsoluteSize{300, 100},
    )
      show.slide_text(slides, "https://github.com/sichacvah/gl_peresntation")
    show.end_panel(slides)
    show.begin_panel(
      slides,
      show.AbsolutePosition{316, 148 - 48},
      show.AbsoluteSize{100, 100},
    )
      show.slide_text(slides, "Слайды:")
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
