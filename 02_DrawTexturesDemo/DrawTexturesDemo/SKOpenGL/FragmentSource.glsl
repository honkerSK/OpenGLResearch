//片段着色器

//varying lowp vec4 DestinationColor;
varying lowp vec2 TexCoordOut; //纹理坐标

uniform sampler2D Texture; //纹理数据

void main(void) {
    gl_FragColor = texture2D(Texture, TexCoordOut);
}
