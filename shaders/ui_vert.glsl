#version 330 core

uniform mat4 projection;
// POS_LOCATION const
layout(location = 0) in vec2 v_position;
// TEX_COORD_LOCATION const
layout(location = 1) in vec2 tex_coord;
// COLOR_LOCATION const
layout(location = 2) in vec4 v_color;
// TEX_INDEX_LOCATION const
layout(location = 3) in float a_tex_index;

out vec4 frag_color;
out vec2 frag_uv;
out float v_tex_index;

void main() {
  frag_color = v_color;
  frag_uv = tex_coord;
  v_tex_index = a_tex_index;
  gl_Position = projection * vec4(v_position, 0.0f, 1.0f);
}
