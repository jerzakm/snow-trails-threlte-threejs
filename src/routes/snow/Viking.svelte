<script lang="ts">
	import { Three, useFrame, useThrelte, T, OrbitControls } from '@threlte/core';
	import {
		AnimationMixer,
		DoubleSide,
		Group,
		LoadingManager,
		Mesh,
		MeshStandardMaterial,
		SkinnedMesh,
		SphereGeometry,
		Vector3
	} from 'three';
	import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';

	import { Collider, CollisionGroups, RigidBody } from '@threlte/rapier';
	import type { RigidBody as TRigidBody, Collider as TCollider } from '@dimforge/rapier3d-compat';
	import * as THREE from 'three';
	import Controller from './Controller.svelte';
	import type { Ball } from './util';

	export let balls: Ball[];

	const getVertexPosition = function (skin: SkinnedMesh, index: number) {
		const skinIndices = new THREE.Vector4().fromBufferAttribute(
			skin.geometry.getAttribute('skinIndex') as THREE.BufferAttribute,
			index
		);

		const skinWeights = new THREE.Vector4().fromBufferAttribute(
			skin.geometry.getAttribute('skinWeight') as THREE.BufferAttribute,
			index
		);
		const skinVertex = new THREE.Vector3()
			.fromBufferAttribute(skin.geometry.getAttribute('position'), index)
			.applyMatrix4(skin.bindMatrix);
		const result = new THREE.Vector3(),
			temp = new THREE.Vector3(),
			tempMatrix = new THREE.Matrix4();
		const properties = ['x', 'y', 'z', 'w'];
		for (let i = 0; i < 4; i++) {
			const boneIndex = skinIndices[properties[i]];
			tempMatrix.multiplyMatrices(
				skin.skeleton.bones[boneIndex].matrixWorld,
				skin.skeleton.boneInverses[boneIndex]
			);

			result.add(
				temp.copy(skinVertex).applyMatrix4(tempMatrix).multiplyScalar(skinWeights[properties[i]])
			);
		}
		return result.applyMatrix4(skin.bindMatrixInverse);
	};

	let debugMesh: Mesh;

	//https://stackoverflow.com/questions/36461699/three-js-get-updated-vertices-with-morph-targets
	// https://stackoverflow.com/questions/57332347/three-js-get-updated-vertices-with-skeletal-animations
	//https://github.com/mrdoob/three.js/issues/3187

	const loadingManager = new LoadingManager();

	let position: [number, number, number] = [0, 0, 0];

	export let vikingThree: Group;

	loadingManager.setURLModifier(function (url) {
		// this function is called for each asset request

		url = url.replace('U:/Dropbox/SyntyStudios/PolygonVikings/_working/Mike/Characters/', '');

		return url;
	});

	let viking: Group;
	let mixer: AnimationMixer;

	const loader = new FBXLoader(loadingManager);

	let targetArray: Vector3[] = [];
	let vertexPositionArray: [number, number, number][] = [];
	let bonePreviewHelpers: Mesh[] = [];

	let skinnedMesh: SkinnedMesh;

	loader.load('assets/characters/Walking_viking.fbx', function (object) {
		mixer = new AnimationMixer(object);
		const action = mixer.clipAction(object.animations[0]);
		action.play();
		object.traverse(function (child: any) {
			if (child.isSkinnedMesh) {
				skinnedMesh = child;
				skinnedMesh.material.transparent = true;
				skinnedMesh.material.opacity = 0.1;
			}
		});
		viking = object;
		targetArray = targetArray;
		vertexPositionArray = vertexPositionArray;
	});

	const cg = new SphereGeometry(10, 5, 5);
	const cm = new MeshStandardMaterial({
		color: 'red',
		side: DoubleSide,
		transparent: true,
		opacity: 0
	});

	debugMesh = new Mesh(cg, cm);

	const { scene } = useThrelte();

	scene.add(debugMesh);

	let tempCounter = 0;

	let lookAt = { x: 0, y: 0, z: 0 };
	let rigidBody: TRigidBody;

	let leftFoot: {
		helper?: Mesh;
		position?: Vector3;
		size?: Number;
		strength?: number;
		collider?: TCollider;
		pushed?: boolean;
	} = {};

	let rightFoot: {
		helper?: Mesh;
		position?: Vector3;
		size?: Number;
		strength?: number;
		collider?: TCollider;

		pushed?: boolean;
	} = {};

	$: {
		if (skinnedMesh && debugMesh) {
			skinnedMesh.material.transparent = true;
			skinnedMesh.material.opacity = 0.9;
			// const bone = skinnedMesh.skeleton.getBoneByName('LowerLeg_L');
			// bone?.add(debugMesh);
			for (const bone of skinnedMesh.skeleton.bones) {
				if (bone.name == 'Ankle_L') {
					const bonePreviewMesh = new Mesh(cg, cm);
					bone.add(bonePreviewMesh);
					leftFoot.helper = bonePreviewMesh;
					leftFoot.size = 2;
					leftFoot.strength = 2;
					leftFoot.position = new Vector3();
				}
				if (bone.name == 'Ankle_R') {
					const bonePreviewMesh = new Mesh(cg, cm);
					bone.add(bonePreviewMesh);
					rightFoot.helper = bonePreviewMesh;
					rightFoot.size = 2;
					rightFoot.strength = 2;
					rightFoot.position = new Vector3();
				}
			}
		}
	}

	let lastClock = 0;
	let delta = 0;

	useFrame(({ clock }) => {
		let currentClock = clock.elapsedTime;

		delta = currentClock - lastClock;
		delta *= 1;

		lastClock = currentClock;

		tempCounter++;
		// console.log(debugMesh.getWorldPosition(new Vector3()));

		if (leftFoot.helper && leftFoot.collider) {
			leftFoot.helper.getWorldPosition(leftFoot.position);
			leftFoot.collider.setTranslation(leftFoot.position);

			if (!leftFoot.pushed) {
				balls.push({
					size: leftFoot.size,
					startingPosition: leftFoot.position,
					collider: leftFoot.collider
				});
				leftFoot.pushed = true;
			}
			leftFoot = leftFoot;
		}

		if (rightFoot.helper && rightFoot.collider) {
			rightFoot.helper.getWorldPosition(rightFoot.position);
			rightFoot.collider.setTranslation(rightFoot.position);
			rightFoot = rightFoot;
			if (!rightFoot.pushed) {
				balls.push({
					size: rightFoot.size,
					rightFoot: rightFoot.position,
					collider: rightFoot.collider
				});
				rightFoot.pushed = true;
			}
		}

		if (mixer) {
			mixer.update(delta);
			const mod = 36;
		}

		if (rigidBody) {
			lookAt = rigidBody.translation();
		}
	});
</script>

{#if viking}
	<Collider
		shape={'ball'}
		args={[1]}
		position={rightFoot.position}
		bind:collider={rightFoot.collider}
	/>
	<Collider
		shape={'ball'}
		args={[1]}
		position={leftFoot.position}
		bind:collider={leftFoot.collider}
	/>
	<!-- <CollisionGroups memberships={[2]} filter={[1]}>
		
	</CollisionGroups> -->

	<T.PerspectiveCamera position={[150, 100, 150]} fov={30} far={99999} makeDefault>
		<OrbitControls enableZoom={true} target={lookAt} />
	</T.PerspectiveCamera>
	<RigidBody
		position={{ x: 100, y: 25, z: 110 }}
		type="dynamic"
		enabledRotations={[false, false, false]}
		bind:rigidBody
	>
		{#if rigidBody}
			<Controller {rigidBody} />
		{/if}
		<Three type={viking} bind:ref={vikingThree} scale={10} />
		<Collider shape={'capsule'} args={[2, 8]} position={{ y: 8 }} />
	</RigidBody>
{/if}
