<!-- Step 2
  Step 1+
  - How are we going to manipulate the terrain to make trails? Vertex shader
  - let's have a look at our terrain. Set wireframe. 
  - manipulating height on standard plane would suck, not enough of vertices to resemble terrain
  - increase width and height segments to 64
  - disable grid because it's blending in with wireframe 
  - now make basic vertex shader
  - we're lazy. Let's just extend existing threejs material with three-custom-shader-material library (what dis, credit)
  - extending MeshStandardMaterial. First fragment shader that colors the mesh based on vUv
  - some simple vertex shader to change terrain height
  - Let's color based on terrain height (varying vPosition)
-->
<script lang="ts">
	import { OrbitControls, T, Three, useFrame } from '@threlte/core';
	import { Environment, Grid } from '@threlte/extras';
	import { DoubleSide, MeshStandardMaterial } from 'three';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla';
	import { DEG2RAD } from 'three/src/math/MathUtils';

	const planeMaterial = new CustomShaderMaterial({
		baseMaterial: MeshStandardMaterial,
		vertexShader: `
        varying vec2 vUv;                
        varying vec3 vPosition;
        void main() {
            vUv = uv;
            vec3 newPosition = vec3(position.x, position.y, position.z + sin(position.x*0.5));
            vPosition = (modelMatrix * vec4(newPosition, 1.0)).xyz;
            csm_Position = newPosition;
        }
    `,
		fragmentShader: `
        varying vec2 vUv;        
        uniform float time;
        varying vec3 vPosition;
        void main() {
            csm_FragColor = vec4(vec3(vPosition.y*0.3+0.5), 1.);
        }`,
		// wireframe: true,
		color: 0xceceef,
		side: DoubleSide
	});

	useFrame(({ clock }) => {});
</script>

<T.PerspectiveCamera let:ref position={[0, 8, 15]} fov={35} far={200} makeDefault>
	<OrbitControls enableZoom={true} target={{ x: 0, y: 0, z: 0 }} />
</T.PerspectiveCamera>

<Environment files="env/belfast_sunset_puresky_4k.hdr" isBackground />
<!-- <Grid sectionColor={'black'} sectionSize={10} position.y={0.01} /> -->

<T.Mesh rotation.x={-DEG2RAD * 90}>
	<T.PlaneGeometry args={[20, 20, 64, 64]} />
	<!-- <T.MeshStandardMaterial wireframe /> -->

	<Three type={planeMaterial} />
</T.Mesh>
