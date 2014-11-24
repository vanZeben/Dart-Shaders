part of beta;

class Shader {
  GL.Program program;
  Shader(String vertexSource, String fragmentSource) {
    GL.Shader vertexShader = compile(vertexSource, GL.VERTEX_SHADER);
    GL.Shader fragmentShader = compile(fragmentSource, GL.FRAGMENT_SHADER);
    program = link(vertexShader, fragmentShader);
  }

  void use() {
    gl.useProgram(program);
  }

  GL.Shader compile(String source, int type) {
    GL.Shader shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, GL.COMPILE_STATUS)) throw gl.getShaderInfoLog(shader);
    return shader;
  }

  GL.Program link(GL.Shader vertexShader, GL.Shader fragmentShader) {
    GL.Program program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, GL.LINK_STATUS)) throw gl.getProgramInfoLog(program);
    return program;
  }
}

Shader normalsShader = new Shader("""
  precision highp float;
  
  attribute vec3 a_pos;
  attribute vec2 a_uv;
  attribute vec4 a_col;
    
  varying vec4 v_col;
  varying vec2 v_uv;
  
  void main() {
    v_col = a_col;
    v_uv = a_uv/256.0;
    gl_Position = vec4(a_pos.x, 0.0-a_pos.y, a_pos.z, 1.0);
  }
""", """
  precision highp float;
  
  varying vec4 v_col;
  varying vec2 v_uv;
  
  uniform sampler2D u_tex;
  uniform sampler2D u_nTex;

  uniform vec2 u_res;
  uniform vec4 u_aCol;
  
  uniform vec3 u_lightPos;
  uniform vec4 u_lightCol;
  uniform vec3 u_falloff;
  uniform float u_lightSize;

  void main() {
    vec4 diffuseCol = texture2D(u_tex, v_uv);
    vec3 normalMap = texture2D(u_nTex, v_uv).rgb;

    vec3 lightDir = vec3(u_lightPos.xy - (gl_FragCoord.xy / u_res.xy), u_lightPos.z);
    
    lightDir.x /= (u_lightSize/u_res.x);
    lightDir.y /= (u_lightSize/u_res.y);
    float dist = length(lightDir);
    vec3 n = normalize(normalMap*2.0-1.0);
    vec3 l = normalize(lightDir);

    n = mix(n, vec3(0), 0.5);

    float df = max(dot(n, l), 0.0);
    vec3 diff = (u_lightCol.rgb*u_lightCol.a)*df;
    vec3 amb = u_aCol.rgb*u_aCol.a;

    float a = 1.0/(u_falloff.x+(u_falloff.y*dist)+(u_falloff.z*dist*dist));
    if (a<0.4) {
      a = 0.0;
    } else if (a<0.6) {
      a = 0.6;
    } else if (a<0.8) {
      a = 0.8;
    } else {
      a = 1.0;
    }

    vec3 intensity = amb+diff*a;
    vec3 final = diffuseCol.rgb*intensity;

    gl_FragColor = v_col*vec4(final, diffuseCol.a);
  }
""");
