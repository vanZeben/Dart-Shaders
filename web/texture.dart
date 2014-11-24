part of beta;

class Texture {
  static List<Texture> _allTextures = new List<Texture>();
  static void _loadAll() {
    _allTextures.forEach((texture)=>texture.load());
  }

  String url;
  GL.Texture texture;
  Texture(this.url) {
    _allTextures.add(this);
  }

  void load() {
    texture = gl.createTexture();
    ImageElement img = new ImageElement();
    img.onLoad.listen((e) {
      gl.bindTexture(GL.TEXTURE_2D, texture);
      gl.texImage2DImage(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA, GL.UNSIGNED_BYTE, img);
      gl.texParameterf(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
      gl.texParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
    });
    img.src = url;
  }
}