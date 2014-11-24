library beta;
import 'dart:html';
import 'dart:web_gl' as GL;
import 'dart:typed_data';
import 'dart:math';
import 'package:vector_math/vector_math.dart';

part 'shader.dart';
part 'texture.dart';

CanvasElement canvas;
GL.RenderingContext gl;
const int FLOATS_PER_VERTEX = 9;
class Game {
  Random random;
  Shader shader;
  Texture base, normals;
  int posLocation, colLocation, offsLocation;
  GL.UniformLocation texLocation, normalsLocation;
  GL.UniformLocation resLocation, ambientColLocation, lightPosColor, lightColLocation, falloffLocation, lightSizeLocation;

  double xPos = 0.5, yPos = 0.5;

  double lightZ = 0.075;
  Vector4 lightCol = new Vector4(1.0, 0.8, 0.6, 1.0);
  Vector4 ambCol = new Vector4(0.6, 0.6, 1.0, 0.2);
  Vector3 falloff = new Vector3(0.4, 3.0, 20.0);
  double lightSize = 1024.0;
  Game() {
    canvas = querySelector("#game");
    gl = canvas.getContext("webgl");
    if (gl == null) gl = canvas.getContext("experimental-webgl");
    if (gl == null) noWebGl();
    else start();
  }

  void start() {
    random = new Random();
    shader = normalsShader;
    posLocation = gl.getAttribLocation(shader.program, "a_pos");
    offsLocation = gl.getAttribLocation(shader.program, "a_uv");
    colLocation = gl.getAttribLocation(shader.program, "a_col");

    resLocation = gl.getUniformLocation(shader.program, "u_res");
    ambientColLocation = gl.getUniformLocation(shader.program, "u_aCol");
    lightPosColor = gl.getUniformLocation(shader.program, "u_lightPos");
    lightColLocation = gl.getUniformLocation(shader.program, "u_lightCol");
    falloffLocation = gl.getUniformLocation(shader.program, "u_falloff");
    lightSizeLocation = gl.getUniformLocation(shader.program, "u_lightSize");
    texLocation = gl.getUniformLocation(shader.program, "u_tex");
    normalsLocation = gl.getUniformLocation(shader.program, "u_nTex");

    base = new Texture("tex/pixel-diffuse.png");
    normals = new Texture("tex/pixel-normals.png");
    Texture._loadAll();

    canvas.onMouseMove.listen((e) {
      xPos=((e.offset.x+0.0)/canvas.width);
      yPos=1.0-((e.offset.y+0.0)/canvas.height);
    });

    canvas.onMouseWheel.listen((e) {
      lightSize += e.deltaY;
    });
    window.requestAnimationFrame(render);
  }

  void noWebGl() {
    querySelector("#noWebGl").setAttribute("style", "display: all");
    canvas.setAttribute("style", "display: none");
  }

  void render(double time) {
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.1, 0.1, 0.1, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT);


    shader.use();
    gl.uniform1i(texLocation, 0);
    gl.uniform1i(normalsLocation, 1);

    gl.activeTexture(GL.TEXTURE1);
    gl.bindTexture(GL.TEXTURE_2D, normals.texture);
    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_2D, base.texture);

    Vector4 col = new Vector4(1.0, 1.0, 1.0, 1.0);
    Float32List vertexData = new Float32List.fromList([
      -1.0, -1.0, 1.0, 0.0+0.5, 0.0+0.5, col.storage[0], col.storage[1], col.storage[2], col.storage[3],
      -1.0, 1.0, 1.0, 0.0+0.5, 0.0+125.0+0.5, col.storage[0], col.storage[1], col.storage[2], col.storage[3],
      1.0, 1.0, 1.0, 0.0+256.0+0.5, 0.0+125.0+0.5, col.storage[0], col.storage[1], col.storage[2], col.storage[3],
      1.0, -1.0, 1.0, 0.0+256.0+0.5, 0.0+0.5, col.storage[0], col.storage[1], col.storage[2], col.storage[3],
    ]);
    GL.Buffer vertexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);

    GL.Buffer indexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(GL.ELEMENT_ARRAY_BUFFER, new Int16List.fromList([0, 1, 2, 0, 2, 3]), GL.STATIC_DRAW);

    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.enableVertexAttribArray(posLocation);
    gl.enableVertexAttribArray(offsLocation);
    gl.enableVertexAttribArray(colLocation);
    gl.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, FLOATS_PER_VERTEX*Float32List.BYTES_PER_ELEMENT, 0*Float32List.BYTES_PER_ELEMENT);
    gl.vertexAttribPointer(offsLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*Float32List.BYTES_PER_ELEMENT, 3*Float32List.BYTES_PER_ELEMENT);
    gl.vertexAttribPointer(colLocation, 4, GL.FLOAT, false, FLOATS_PER_VERTEX*Float32List.BYTES_PER_ELEMENT, 5*Float32List.BYTES_PER_ELEMENT);

    gl.uniform2f(resLocation, canvas.width, canvas.height);
    gl.uniform4fv(ambientColLocation, ambCol.storage);
    gl.uniform3fv(lightPosColor, new Float32List.fromList([xPos, yPos, lightZ]));
    gl.uniform4fv(lightColLocation, lightCol.storage);
    gl.uniform3fv(falloffLocation, falloff.storage);
    gl.uniform1f(lightSizeLocation, lightSize+sin(time*0.001)*50);

    gl.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0);
    int errorCode = gl.getError();
    if (errorCode>0) print("ErrorCode: ${errorCode}");

    window.requestAnimationFrame(render);
  }
}

void main() {
  new Game();
}
