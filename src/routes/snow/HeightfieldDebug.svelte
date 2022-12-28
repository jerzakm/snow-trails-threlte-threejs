<script lang="ts">
	import * as RAPIER from '@dimforge/rapier3d-compat';
	import { Collider, RigidBody, useRapier } from '@threlte/rapier';

	const { world, debug } = useRapier();

	export let nsubdivs = 10;
	export let heights = generateHeightfield(nsubdivs);

	const scale = new RAPIER.Vector3(512.0, 0.01, 512);

	function generateHeightfield(nsubdivs: number) {
		let heights = [];

		const rng = Math.random() * 3;

		let i, j;
		for (i = 0; i <= nsubdivs; ++i) {
			for (j = 0; j <= nsubdivs; ++j) {
				heights.push(rng);
			}
		}

		return new Float32Array(heights);
	}

	const bodyDesc = RAPIER.RigidBodyDesc.fixed();
	const body = world.createRigidBody(bodyDesc);
	const colliderDesc = RAPIER.ColliderDesc.heightfield(nsubdivs, nsubdivs, heights, scale);

	world.createCollider(colliderDesc, body);
</script>
