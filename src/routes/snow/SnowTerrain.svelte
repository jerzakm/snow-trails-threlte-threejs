<script lang="ts">
	import type { Collider as TCollider } from '@dimforge/rapier3d-compat';
	import { T, useFrame, useTexture, useThrelte } from '@threlte/core';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla';
	import { GPUComputationRenderer } from 'three/examples/jsm/misc/GPUComputationRenderer.js';
	import type { Ball } from './util';
	import {
		ClampToEdgeWrapping,
		DoubleSide,
		HalfFloatType,
		Mesh,
		MeshBasicMaterial,
		MeshStandardMaterial,
		NearestFilter,
		PlaneGeometry,
		RGBAFormat,
		ShaderChunk,
		ShaderLib,
		ShaderMaterial,
		UniformsUtils,
		UnsignedByteType,
		Vector2,
		Vector3,
		WebGLRenderTarget
	} from 'three';
	import { default as heightmapFragmentShader } from './heightmapFragmentShader.glsl?raw';
	import { default as heightVertexShader } from './heightVertexShader.glsl?raw';
	import { default as readHeightFragmentShader } from './readHeightFragmentShader.glsl?raw';
	import { default as fragmentShader } from './snowFrag.glsl?raw';
	import { default as vertexShader } from './snowVert.glsl?raw';

	export let terrainGeometry: any;
	export let testBall: any;
	export let balls: Ball[];

	export let terrainCollider: TCollider;

	const WIDTH = 512;
	const BOUNDS = 512;

	const { renderer } = useThrelte();

	let heightmapVariable: any;
	let readWaterLevelShader: any;
	let readWaterLevelRenderTarget;
	let readWaterLevelImage;

	const geometry = new PlaneGeometry(BOUNDS, BOUNDS, WIDTH - 1, WIDTH - 1);

	const material = new ShaderMaterial({
		uniforms: UniformsUtils.merge([
			ShaderLib['phong'].uniforms,
			{
				heightmap: { value: null }
			}
		]),
		vertexShader: heightVertexShader,
		fragmentShader: ShaderChunk['meshphong_frag']
	});

	material.defines.WIDTH = WIDTH.toFixed(1);
	material.defines.BOUNDS = BOUNDS.toFixed(1);

	const waterUniforms = material.uniforms;

	const waterMesh = new Mesh(geometry, material);
	waterMesh.rotation.x = -Math.PI / 2;
	waterMesh.matrixAutoUpdate = false;
	waterMesh.updateMatrix();

	const geometryRay = new PlaneGeometry(BOUNDS, BOUNDS, 1, 1);
	const meshRay = new Mesh(geometryRay, new MeshBasicMaterial({ color: 0xffffff, visible: false }));
	meshRay.rotation.x = -Math.PI / 2;
	meshRay.matrixAutoUpdate = false;
	meshRay.updateMatrix();

	//@ts-ignore
	const gpuCompute = new GPUComputationRenderer(WIDTH, WIDTH, renderer);

	if (renderer?.capabilities.isWebGL2 === false) {
		gpuCompute.setDataType(HalfFloatType);
	}

	const starterHeightmap = gpuCompute.createTexture();

	fillTexture(starterHeightmap);

	heightmapVariable = gpuCompute.addVariable(
		'heightmap',
		heightmapFragmentShader,
		starterHeightmap
	);

	gpuCompute.setVariableDependencies(heightmapVariable, [heightmapVariable]);

	heightmapVariable.material.uniforms['objects'] = {
		value: []
	};

	// fill up vector
	for (let i = 0; i < 512; i++) {
		heightmapVariable.material.uniforms['objects'].value.push(new Vector3(0, 0, 0));
	}

	heightmapVariable.material.uniforms['mouseSize'] = { value: 20.0 };
	heightmapVariable.material.uniforms['viscosityConstant'] = { value: 0.98 };
	heightmapVariable.material.uniforms['heightCompensation'] = { value: 0 };
	heightmapVariable.material.uniforms['intensity'] = { value: 0.28 };
	heightmapVariable.material.defines.BOUNDS = BOUNDS.toFixed(1);

	const error = gpuCompute.init();
	if (error !== null) {
		console.error(error);
	}

	// Create compute shader to read water level
	readWaterLevelShader = gpuCompute.createShaderMaterial(readHeightFragmentShader, {
		point1: { value: new Vector2() },
		levelTexture: { value: null }
	});
	readWaterLevelShader.defines.WIDTH = WIDTH.toFixed(1);
	readWaterLevelShader.defines.BOUNDS = BOUNDS.toFixed(1);

	// Create a 4x1 pixel image and a render target (Uint8, 4 channels, 1 byte per channel) to read water height and orientation
	readWaterLevelImage = new Uint8Array(4 * 1 * 4);

	readWaterLevelRenderTarget = new WebGLRenderTarget(4, 1, {
		wrapS: ClampToEdgeWrapping,
		wrapT: ClampToEdgeWrapping,
		minFilter: NearestFilter,
		magFilter: NearestFilter,
		format: RGBAFormat,
		type: UnsignedByteType,
		depthBuffer: false
	});

	function fillTexture(texture: any) {
		const pixels = texture.image.data;
		let p = 0;
		for (let j = 0; j < WIDTH; j++) {
			for (let i = 0; i < WIDTH; i++) {
				const x = (i * 128) / WIDTH;
				const y = (j * 128) / WIDTH;
				pixels[p + 0] = 0;
				pixels[p + 1] = 0;
				pixels[p + 2] = 0;
				pixels[p + 3] = 1;
				p += 4;
			}
		}
	}

	const snowNormal = useTexture('snow_normal.png');

	const terrainMaterial = new CustomShaderMaterial({
		baseMaterial: MeshStandardMaterial,
		vertexShader: `
      varying vec3 vPosition;
      uniform sampler2D heightmap;
      void main() {
          vUv = uv;
          float tColor = texture2D(heightmap, vec2(vUv.x, 1.-vUv.y)).x;  
          vPosition = (modelMatrix * vec4(position, 1.0)).xyz;
          csm_Position = vec3(position.x, position.y + tColor*1., position.z);
      }
  `,
		fragmentShader: `
      uniform sampler2D heightmap;
      varying vec3 vPosition;      
      void main() {
          float tColor = texture2D(heightmap, vec2(vUv.x, 1.-vUv.y)).x;            
          // float tColorVal = min(0.5,-tColor*0.1);
          float tColorVal = -tColor*0.2;
          vec3 tColorMod = vec3(tColorVal);          
          // csm_DiffuseColor = vec4(diffuse-tColorMod, 1.);            
          csm_DiffuseColor = vec4(diffuse*(1.-tColorVal), 1.);            
          // DEFORM debug
          // csm_DiffuseColor = vec4(1.+ tColor*0.7,0., 0.-tColor*0.5, 1.);
      }
  `,

		normalMap: snowNormal,
		normalScale: new Vector2(0.1, 0.1),
		envMapIntensity: 0.2,
		emissiveIntensity: 0.5,
		wireframe: false,

		uniforms: {
			heightmap: { value: null }
		},

		color: 0xceceef
	});

	const snowMaterial = new ShaderMaterial({
		fragmentShader,
		vertexShader,
		side: DoubleSide,
		uniforms: {
			heightmap: { value: null }
		}
	});

	let terrainMesh: THREE.Mesh;

	// performance, can render every x frame
	let renderToggle = 0;
	const renderToggleMod = 1;

	useFrame(() => {
		renderToggle++;
		const uniforms = heightmapVariable.material.uniforms;
		if (renderToggle % renderToggleMod == 0) {
			for (let i = 0; i < balls.length; i++) {
				const ball = balls[i];
				if (ball.rigidBody || ball.collider) {
					//@ts-ignore
					const bCollider: TCollider = ball.rigidBody ? ball.rigidBody.collider(0) : ball.collider;

					const point = bCollider.translation();

					const collisionHackVal = 0.5;
					point.y -= collisionHackVal;

					bCollider.setTranslation(point);

					const collision = bCollider.contactCollider(terrainCollider, 6);
					uniforms['objects'].value[i].set(
						point.x * 2 - 256,
						point.z * 2 - 256,
						ball.size * (collision ? 1 : 0)
					);
					point.y += collisionHackVal;
					bCollider.setTranslation(point);
				}
			}
			uniforms['intensity'].value = 0.13;
			gpuCompute.compute();
		}

		waterUniforms['heightmap'].value = gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		snowMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		terrainMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;
	});
</script>

<T.Mesh
	geometry={terrainGeometry}
	material={terrainMaterial}
	bind:ref={terrainMesh}
	position={[0, 3, 0]}
	castShadow
	receiveShadow
/>
