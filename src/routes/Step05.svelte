<!-- Step 5
  Step 4+
  - Sphere position was only being updated on raycast. Move the logic out of the intersect call and use sphere position instead of mouse position
  - Depth keeps going indefinitely. Apply global max depth (even for this demo), imagine it's the depth of snow, and you can't make trails deeper than the snow is:
      - float newHeight = max(heightmapValue.y + change, -sphere.z * 0.8); this makes max depth just a bit smaller than the sphere's radius
  - fix: Sphere trail was inaccurate. It didn't need to be moved by half radius. I meant to move sphere by half of it's diameter.
  - make the trail slowly disappear:
-->
<script lang="ts">
	import { OrbitControls, T, Three, useFrame, useThrelte } from '@threlte/core';
	import { Environment } from '@threlte/extras';
	import { DoubleSide, Mesh, MeshStandardMaterial, Raycaster, Vector2, Vector3 } from 'three';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla/dist/three-custom-shader-material-vanilla.cjs.js';
	import { GPUComputationRenderer } from 'three/examples/jsm/misc/GPUComputationRenderer';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import { default as trailmapFS } from './05_trailmapFragmentShader.glsl?raw';

	const planeMaterial = new CustomShaderMaterial({
		baseMaterial: MeshStandardMaterial,
		vertexShader: `
		    varying vec2 vUv;
		    varying vec3 vPosition;
        uniform sampler2D heightmap;

		    void main() {
		        vUv = uv;
            float heightChange = texture2D(heightmap, vec2(vUv.x, vUv.y)).x;  
		        vec3 newPosition = vec3(position.x, position.y, position.z+heightChange);
		        vPosition = (modelMatrix * vec4(newPosition, 1.0)).xyz;
		        csm_Position = newPosition;
		    }
		`,
		fragmentShader: `
		    varying vec2 vUv;
		    varying vec3 vPosition;
		    void main() {
		        csm_FragColor = vec4(vec3(vPosition.y*0.3+0.8), 1.);
		    }`,
		wireframe: false,
		color: 0xffffff,
		side: DoubleSide,
		uniforms: {
			mouse: {
				value: new Vector2(0, 0)
			},
			heightmap: {
				value: null
			}
		}
	});

	const mousePos = {
		x: 0,
		y: 0
	};

	const spherePosition: [number, number, number] = [0, 0, 0];
	const sphereRadius = 0.5;

	window.addEventListener('mousemove', (event) => {
		mousePos.x = (event.clientX / window.innerWidth) * 2 - 1;
		mousePos.y = -(event.clientY / window.innerHeight) * 2 + 1;
	});

	let terrain: Mesh | undefined;
	const raycaster = new Raycaster();
	const { camera, renderer } = useThrelte();

	const COMPUTE_DETAILS = 256;
	const PLANE_SIZE = 16;
	//@ts-ignore
	const gpuCompute = new GPUComputationRenderer(COMPUTE_DETAILS, COMPUTE_DETAILS, renderer);

	const starterHeightmap = gpuCompute.createTexture();
	fillTexture(starterHeightmap);

	const heightmapVariable = gpuCompute.addVariable('heightmap', trailmapFS, starterHeightmap);
	gpuCompute.setVariableDependencies(heightmapVariable, [heightmapVariable]);

	heightmapVariable.material.uniforms = {
		intensity: { value: 0.05 },
		sphere: { value: new Vector3() }
	};

	heightmapVariable.material.defines.PLANE_SIZE = PLANE_SIZE.toFixed(1);

	function fillTexture(texture: any) {
		const pixels = texture.image.data;
		let p = 0;
		for (let j = 0; j < COMPUTE_DETAILS; j++) {
			for (let i = 0; i < COMPUTE_DETAILS; i++) {
				pixels[p + 0] = 0;
				pixels[p + 1] = 0;
				pixels[p + 2] = 0;
				pixels[p + 3] = 1;
				p += 4;
			}
		}
	}

	const error = gpuCompute.init();
	console.log(error);

	useFrame(() => {
		if (!terrain || !gpuCompute) return;
		raycaster.setFromCamera(mousePos, $camera);
		const intersects = raycaster.intersectObjects([terrain]);
		if (intersects.length > 0) {
			const pos = intersects[0];
			spherePosition[0] = pos.point.x;
			spherePosition[1] = pos.point.y;
			spherePosition[2] = pos.point.z;
		}

		gpuCompute.compute();

		heightmapVariable.material.uniforms['sphere'].value.set(
			spherePosition[0],
			spherePosition[2],
			sphereRadius
		);
		planeMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;
	});
</script>

<T.PerspectiveCamera position={[0, 8, 15]} fov={35} far={200} makeDefault>
	<OrbitControls enableZoom={true} target={{ x: 0, y: 0, z: 0 }} />
</T.PerspectiveCamera>

<Environment files="env/belfast_sunset_puresky_4k.hdr" isBackground />
<!-- <Grid sectionColor={'black'} sectionSize={10} position.y={0.01} /> -->

<T.Mesh rotation.x={-DEG2RAD * 90} bind:ref={terrain}>
	<T.PlaneGeometry args={[PLANE_SIZE, PLANE_SIZE, COMPUTE_DETAILS, COMPUTE_DETAILS]} />
	<!-- <T.MeshStandardMaterial wireframe /> -->

	<Three type={planeMaterial} />
</T.Mesh>

<T.Mesh position={spherePosition}>
	<T.SphereGeometry args={[sphereRadius, 8, 8]} />
	<T.MeshStandardMaterial color={'white'} wireframe />
</T.Mesh>
