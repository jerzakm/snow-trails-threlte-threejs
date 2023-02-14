<!-- Step 3
  Step 2+
  - now we want to change position based on user input, let's make a sphere that follows the mouse
  - get normalized screen coordinates
  - make raycaster class
  - bind terrain ref to let
  - move sphere based on raycast
  - draw a sphere in glsl (smoothcircle function) - it will alter height
  - now it follows mouse but does not persist the depth trail
-->
<script lang="ts">
	import { OrbitControls, T, Three, useFrame, useThrelte } from '@threlte/core';
	import { Environment, Grid } from '@threlte/extras';
	import { Vector2 } from 'three';
	import { DoubleSide, Mesh, MeshStandardMaterial, Raycaster } from 'three';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla/dist/three-custom-shader-material-vanilla.cjs.js';
	import { DEG2RAD } from 'three/src/math/MathUtils';

	const planeMaterial = new CustomShaderMaterial({
		baseMaterial: MeshStandardMaterial,
		vertexShader: `
		    varying vec2 vUv;
		    varying vec3 vPosition;
        uniform vec2 mouse;

        float smoothCircle(vec2 position, float radius){
          vec2 d = position - vec2(0.5);
          return 1. - smoothstep(0.0, radius * radius, dot(d,d));
        }

		    void main() {
		        vUv = uv;
            float heightChange = smoothCircle(uv + vec2(-mouse.x, mouse.y) , 0.04);
		        vec3 newPosition = vec3(position.x, position.y, position.z-heightChange);
		        vPosition = (modelMatrix * vec4(newPosition, 1.0)).xyz;
		        csm_Position = newPosition;
		    }
		`,
		fragmentShader: `
		    varying vec2 vUv;
		    uniform float time;
		    varying vec3 vPosition;
		    void main() {
		        csm_FragColor = vec4(vec3(vPosition.y*0.3+0.8), 1.);
		    }`,
		// wireframe: true,
		color: 0xffffff,
		side: DoubleSide,
		uniforms: {
			mouse: {
				value: new Vector2(0, 0)
			}
		}
	});

	const mousePos = {
		x: 0,
		y: 0
	};

	const spherePos: [number, number, number] = [0, 0, 0];

	window.addEventListener('mousemove', (event) => {
		mousePos.x = (event.clientX / window.innerWidth) * 2 - 1;
		mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1;
	});

	let terrain: Mesh | undefined;
	const raycaster = new Raycaster();
	const { camera } = useThrelte();

	useFrame(({ clock }) => {
		if (!terrain) return;
		raycaster.setFromCamera(mousePos, $camera);
		const intersects = raycaster.intersectObjects([terrain]);
		if (intersects.length > 0) {
			const pos = intersects[0];
			spherePos[0] = pos.point.x;
			spherePos[1] = pos.point.y;
			spherePos[2] = pos.point.z;
			planeMaterial.uniforms.mouse.value.set(pos.point.x / 20, pos.point.z / 20);
		}
	});
</script>

<T.PerspectiveCamera position={[0, 8, 15]} fov={35} far={200} makeDefault>
	<OrbitControls enableZoom={true} target={{ x: 0, y: 0, z: 0 }} />
</T.PerspectiveCamera>

<Environment files="env/belfast_sunset_puresky_4k.hdr" isBackground />
<!-- <Grid sectionColor={'black'} sectionSize={10} position.y={0.01} /> -->

<T.Mesh rotation.x={-DEG2RAD * 90} bind:ref={terrain}>
	<T.PlaneGeometry args={[20, 20, 64, 64]} />
	<!-- <T.MeshStandardMaterial wireframe /> -->

	<Three type={planeMaterial} />
</T.Mesh>

<T.Mesh position={spherePos}>
	<T.SphereGeometry args={[0.5, 8, 8]} />
	<T.MeshStandardMaterial color={'white'} wireframe />
</T.Mesh>
