#include <common>
uniform float intensity;
uniform vec3 sphere;

float smoothCircle(vec2 position, float radius) {
  vec2 d = position - vec2(0.5);
  return 1. - smoothstep(0.0, radius * radius, dot(d, d));
}

void main() {

  vec2 cellSize = 1.0 / resolution.xy;
  vec2 uv = gl_FragCoord.xy * cellSize;

  float halfRadius = sphere.z * 0.5;

  vec4 heightmapValue = texture2D(heightmap, uv);
  float change = smoothCircle((uv - vec2(0.5)) * PLANE_SIZE - vec2(sphere.x - halfRadius, -sphere.y - halfRadius), sphere.z) * intensity;

  if(change < 0.25) {
    change *= -1.;
  }
  float newHeight = heightmapValue.y + change;

  heightmapValue.y = heightmapValue.x;
  heightmapValue.x = newHeight;

  gl_FragColor = vec4(newHeight);

}
