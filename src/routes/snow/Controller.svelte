<script lang="ts">
	import type { RigidBody as TRigidBody } from '@dimforge/rapier3d-compat';
	import { useFrame } from '@threlte/core';

	export let rigidBody: TRigidBody;

	let buttons: { [key: string]: boolean } = {};

	window.addEventListener('keydown', (e) => {
		buttons[e.key] = true;
		buttons = buttons;
	});

	window.addEventListener('keyup', (e) => {
		buttons[e.key] = false;
		buttons = buttons;
	});

	const impulseStrength = rigidBody.mass() * 0.1;

	useFrame(() => {
		const impulseVector = {
			x: 0,
			y: 0,
			z: 0
		};
		const rotation = rigidBody.rotation();
		if (buttons.s) {
			impulseVector.z += impulseStrength;
		}
		if (buttons.w) {
			impulseVector.z -= impulseStrength;
		}

		if (buttons.d) {
			// impulseVector.x += impulseStrength;
			rotation.y -= 0.01;
		}
		if (buttons.a) {
			rotation.y += 0.01;
		}

		rigidBody.setRotation(rotation, true);
		rigidBody.setLinvel({ x: 0, y: 0, z: impulseVector.z }, true);
	});
</script>
