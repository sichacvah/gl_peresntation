#version 330 core

// MAX_TEXTURES const
uniform sampler2D u_tex[8];
in vec4 frag_color;
in vec2 frag_uv;
in float v_tex_index;

void main() {
  switch (int(v_tex_index)) {
    case 0: gl_FragColor = frag_color / 255.0f * texture(u_tex[0], frag_uv); break;
    case 1: gl_FragColor = frag_color / 255.0f * texture(u_tex[1], frag_uv); break;
    case 2: gl_FragColor = frag_color / 255.0f * texture(u_tex[2], frag_uv); break;
    case 3: gl_FragColor = frag_color / 255.0f * texture(u_tex[3], frag_uv); break;
    case 4: gl_FragColor = frag_color / 255.0f * texture(u_tex[4], frag_uv); break;
    case 5: gl_FragColor = frag_color / 255.0f * texture(u_tex[5], frag_uv); break;
    case 6: gl_FragColor = frag_color / 255.0f * texture(u_tex[6], frag_uv); break;
    case 7: gl_FragColor = frag_color / 255.0f * texture(u_tex[7], frag_uv); break;
    default: discard;
  }
}

