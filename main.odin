package js_console

import "core:dynlib"
import "core:os"
import "core:fmt"
import "./presentation"
import show "./slideshow"

SlidesAPI :: struct {
  make: proc() -> ^show.SlideShow,
  mem:  proc() -> rawptr,
  hot_reload: proc(rawptr),
  lib: dynlib.Library,
  dll_time: os.File_Time,
  api_version: int,
}

load_slides_api :: proc(api_version: int) -> (SlidesAPI, bool) {
  dll_time, dll_time_err := os.last_write_time_by_name("./slides.so")
  if dll_time_err != os.ERROR_NONE {
    fmt.println("Could not fetch last write date of slides.so")
    return {}, false
  }

  dll_name := fmt.tprintf("./slides_{0}.so", api_version)
  content, read_ok := os.read_entire_file("./slides.so")
  defer delete(content)
  if !read_ok {
    fmt.eprintln("can't read file slides.so")
    return {}, false
  }

  write_ok := os.write_entire_file(dll_name, content)
  if !write_ok {
    fmt.eprintln("can't write file", dll_name)
    return {}, false
  }

  lib, lib_ok := dynlib.load_library(dll_name)
  if !lib_ok {
    fmt.eprintln("can't load library", dll_name)
    return {}, false
  }

  api := SlidesAPI {
    make = cast(proc() -> ^show.SlideShow)(dynlib.symbol_address(lib, "make_slides") or_else nil),
    mem = cast(proc() -> rawptr)(dynlib.symbol_address(lib, "slides_mem") or_else nil),
    hot_reload = cast(proc(rawptr))(dynlib.symbol_address(lib, "slides_hot_reload") or_else nil),
    lib = lib,
    api_version = api_version,
    dll_time = dll_time,
  }

  if api.make == nil || api.mem == nil || api.hot_reload == nil {
    dynlib.unload_library(api.lib)
    fmt.eprintln("Dll missing required procedure")
    return {}, false
  }

  return api, true
}

unload_library :: proc(api: SlidesAPI) {
  if api.lib != nil {
    dynlib.unload_library(api.lib)
  }

  dll_name := fmt.tprintf("./slides_{0}.so", api.api_version)
  if os.remove(dll_name) != os.ERROR_NONE {
    fmt.eprintln("cant remove dll", dll_name)
  }
}

/**
███    ███  █████  ██ ███    ██ 
████  ████ ██   ██ ██ ████   ██ 
██ ████ ██ ███████ ██ ██ ██  ██ 
██  ██  ██ ██   ██ ██ ██  ██ ██ 
██      ██ ██   ██ ██ ██   ████                           
-> MAIN                                
*/
main :: proc() {
  api_version := 0
  api, api_ok := load_slides_api(api_version)
  if !api_ok {
    fmt.eprintln("Failed to load Slides")
    return
  }

  slides := api.make()

  assert(presentation.presentation_init(slides))
  api_version += 1

  for {
    if !presentation.presentation_update(slides) {
      break
    }

    dll_time, dll_time_err := os.last_write_time_by_name("./slides.so")

    if dll_time_err == os.ERROR_NONE && api.dll_time != dll_time {
      new_api, new_api_ok := load_slides_api(api_version)
      if new_api_ok {
        memory := api.mem()
        unload_library(api)
        api = new_api
        api.hot_reload(memory)
        api_version += 1
      }
    }
  }

  presentation.presentation_shutdown(slides)
}

