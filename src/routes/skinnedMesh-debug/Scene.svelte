<script lang="ts">
	import { decodeTerrainFromTile, genMartiniTerrain } from '$lib/martiniTerrain';
	import Stag from '$lib/Stag.svelte';
	import { OrbitControls, T, Three, useThrelte } from '@threlte/core';
	import { Environment, Grid } from '@threlte/extras';
	import { Mesh, TorusKnotGeometry } from 'three';
	import { DoubleSide, Group, MeshStandardMaterial, Object3D, SphereGeometry } from 'three';
	import Viking from './Viking.svelte';
	import { CSG } from 'three-csg-ts';

	let actions: any;
	let stag: Group;
	let stagBones: any;
	const cg = new SphereGeometry(0.25);
	const cm = new MeshStandardMaterial({ color: 'white', side: DoubleSide });

	const { scene } = useThrelte();

	$: {
		if (stag && stagBones) {
			console.log(stagBones);

			for (const bone of Object.values(stagBones)) {
				const bpg = new Group();
				const bonePreviewMesh = new Mesh(cg, cm);
				bonePreviewMesh.position.setY(0.2);
				bpg.add(bonePreviewMesh);
				console.log(bone);
				bone.add(bpg);
			}
		}
	}

	$: {
		if ($actions && $actions.Walk) {
			$actions.Walk.play();
		}
	}

	//@ts-ignore

	let terrain, terrainGeometry, terrainMesh, torusMesh;

	let unionMesh;

	const img = new Image(); // Create new img element
	img.src = 'fuji_terraintile.png';
	img.addEventListener('load', (e) => {
		terrain = decodeTerrainFromTile(img);
		terrainGeometry = genMartiniTerrain(terrain, img.width, 500);
	});
</script>

<T.PerspectiveCamera let:ref position={[12, 12, 5]} fov={30} far={99999} makeDefault>
	<OrbitControls enableZoom={true} target={{ x: 0, y: 2, z: 0 }} />
</T.PerspectiveCamera>

<Environment files="env/belfast_sunset_puresky_4k.hdr" isBackground />
<Grid sectionColor={'black'} sectionSize={10} />

<!-- <Horse position={[0, 0, 0]} /> -->

<!-- <Viking /> -->

<Stag bind:actions bind:ref={stag} bind:bones={stagBones} />

<T.DirectionalLight position={[40, 50, 50]} intensity={0.2} castShadow />
<T.DirectionalLight position={[200, 80, 200]} intensity={0.2} castShadow />
<T.AmbientLight intensity={0.2} />
