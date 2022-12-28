<script lang="ts">
	import { OrbitControls, T, useFrame } from '@threlte/core';
	import { decodeTerrainFromTile, genMartiniTerrain } from '$lib/martiniTerrain';
	import { Environment } from '@threlte/extras';
	import type { BufferGeometry } from 'three';
	import {
		AutoColliders,
		Collider,
		Debug,
		World,
		RigidBody,
		Attractor,
		useRapier
	} from '@threlte/rapier';
	import Postprocessing from './Postprocessing.svelte';
	import SnowTerrain from './SnowTerrain.svelte';
	import { DoubleSide } from 'three';
	import type { RigidBody as TRigidBody, Collider as TCollider } from '@dimforge/rapier3d-compat';
	import HeightfieldDebug from './HeightfieldDebug.svelte';
	import Viking from './Viking.svelte';

	interface Ball {
		startingPosition: { x: number; y: number; z: number };
		size: number;
		rigidBody?: TRigidBody;
	}

	let balls: Ball[] = [
		{
			startingPosition: { x: 200, y: 50, z: 80 },
			size: 5,
			rigidBody: undefined
		}
	];

	let testBall = balls[0];

	let spawnTimer = 0;
	let elapsedTime = 0;

	let lookAt = { x: testBall.startingPosition.x, y: 0.5, z: testBall.startingPosition.z };

	useFrame(({ clock, composer }) => {
		if (balls[0].rigidBody) {
			lookAt = balls[0].rigidBody.translation();
		}
		elapsedTime = clock.elapsedTime;

		spawnTimer += clock.getDelta() * 1000;

		if (balls.length < 0 && spawnTimer > 0.2) {
			balls.push({
				startingPosition: { x: 20 + Math.random() * 200, y: 700, z: 20 + Math.random() * 200 },
				size: 4,
				rigidBody: undefined
			});
			balls = balls;

			spawnTimer = 0;
		}
	});

	let terrainGeometry: BufferGeometry;
	let terrainPhysicsGeometry: BufferGeometry;

	let terrain: Float32Array;

	const img = new Image(); // Create new img element
	img.src = 'fuji_terraintile.png';
	img.addEventListener('load', (e) => {
		terrain = decodeTerrainFromTile(img);
		terrainPhysicsGeometry = genMartiniTerrain(terrain, img.width, 50);
		terrainGeometry = genMartiniTerrain(terrain, img.width, 10);
	});

	let terrainCollider: any;
	let vikingThree: any;
</script>

<!-- <T.PerspectiveCamera
	let:ref
	position={[150 + lookAt.x * 0.25, 75 + lookAt.y, 150 + lookAt.z * 0.25]}
	fov={30}
	far={99999}
	makeDefault
>
	<OrbitControls enableZoom={true} target={lookAt} />
</T.PerspectiveCamera> -->

<!-- <T.PerspectiveCamera let:ref position={[150, 100, 150]} fov={30} far={99999} makeDefault>
	<OrbitControls enableZoom={true} />
</T.PerspectiveCamera> -->

<Environment files="env/belfast_sunset_puresky_4k.hdr" isBackground />

<World
	gravity={{
		x: 0,
		y: -20,
		z: 0
	}}
>
	<Viking bind:vikingThree />

	<Collider shape={'cuboid'} args={[128, 300, 5]} position={{ x: 128, y: 150, z: 0 }} />

	<Collider shape={'cuboid'} args={[300, 10, 300]} position={{ x: 0, y: 150, z: 0 }} />
	<Collider shape={'cuboid'} args={[128, 300, 5]} position={{ x: 128, y: 150, z: 256 }} />
	<Collider shape={'cuboid'} args={[5, 300, 128]} position={{ x: 0, y: 150, z: 128 }} />
	<Collider shape={'cuboid'} args={[5, 300, 128]} position={{ x: 256, y: 150, z: 128 }} />
	{#if terrainPhysicsGeometry}
		<Collider
			shape={'trimesh'}
			args={[terrainPhysicsGeometry.attributes.position.array, terrainPhysicsGeometry.index.array]}
			bind:collider={terrainCollider}
		/>
		{#each balls as ball}
			<RigidBody position={ball.startingPosition} type="dynamic" bind:rigidBody={ball.rigidBody}>
				<AutoColliders shape={'ball'} restitution={0.9}>
					<T.Mesh castShadow receiveShadow>
						<T.SphereGeometry args={[ball.size, 15, 15]} />
						<T.MeshStandardMaterial color={'blue'} />
					</T.Mesh>
				</AutoColliders>
			</RigidBody>
		{/each}
	{/if}

	{#if true}
		<Debug depthTest={true} depthWrite={true} side={DoubleSide} />
		<!-- <HeightfieldDebug nsubdivs={256} heights={terrain} /> -->
	{/if}

	{#if terrainGeometry}
		<SnowTerrain {terrainGeometry} {testBall} {balls} {terrainCollider} />
	{/if}
</World>

<T.DirectionalLight position={[40, 50, 50]} intensity={0.2} castShadow />
<T.DirectionalLight position={[200, 80, 200]} intensity={0.2} castShadow />
<T.AmbientLight intensity={0.2} />

<Postprocessing />
