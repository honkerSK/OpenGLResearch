// 使用attribute修饰的属性, 表示是别人需要传入数据
// vec4 最大可以接受四个顶点数据
attribute vec4 Position; //顶点坐标
attribute vec2 TexCoordIn; //纹理坐标

varying vec2 TexCoordOut;

void main(void) {
    gl_Position = Position;
    TexCoordOut = TexCoordIn; 
}
