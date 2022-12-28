<script lang="ts">
	import type { RigidBody as TRigidBody } from '@dimforge/rapier3d-compat';
	import { useFrame } from '@threlte/core';
	import { Quaternion, Vector3 } from 'three';

	export let rigidBody: TRigidBody;

	let buttons: { [key: string]: boolean } = {};

	let move = false;

	window.addEventListener('keydown', (e) => {
		buttons[e.key] = true;
		buttons = buttons;
	});

	window.addEventListener('keyup', (e) => {
		buttons[e.key] = false;
		buttons = buttons;
		move = false;
	});

	const impulseStrength = rigidBody.mass() * 0.1;

	const rotationQuat = new Quaternion();
	const velocity = new Vector3(1, 0, 1);

	const speed = 11;
	const rotationSpeed = 0.01;

	useFrame(() => {
		const rotation = rigidBody.rotation();
		rotationQuat.set(rotation.x, rotation.y, rotation.z, rotation.w);
		if (buttons.s) {
			velocity.set(0, -2, -speed);
			move = true;
		}
		if (buttons.w) {
			velocity.set(0, -2, speed);
			move = true;
		}

		if (buttons.d) {
			rotation.y -= rotationSpeed;
			if (Math.abs(rotation.y) >= 1) {
				rotation.y *= -1;
			}
		}
		if (buttons.a) {
			rotation.y += rotationSpeed;
		}

		rigidBody.setRotation(rotation, true);

		if (move) {
			rotationQuat.set(rotation.x, rotation.y, rotation.z, rotation.w);

			velocity.applyQuaternion(rotationQuat);

			rigidBody.setLinvel(velocity, true);
		}
	});
</script>
