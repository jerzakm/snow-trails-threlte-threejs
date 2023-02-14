<script lang="ts">
	import { Canvas } from '@threlte/core';
	import Step01 from './Step01.svelte';
	import Step02 from './Step02.svelte';
	import Step03 from './Step03.svelte';
	import Step04 from './Step04.svelte';
	import Step05 from './Step05.svelte';

	const steps = [Step01, Step02, Step03, Step04, Step05];

	const stepDesc = [
		`Setup: grid, environment, lights, plane + rotate it, pierced props,make plane bigger`,
		` Step 1+
  - How are we going to manipulate the terrain to make trails? Vertex shader
  - let's have a look at our terrain. Set wireframe. 
  - manipulating height on standard plane would suck, not enough of vertices to resemble terrain
  - increase width and height segments to 64
  - disable grid because it's blending in with wireframe 
  - now make basic vertex shader
  - we're lazy. Let's just extend existing threejs material with three-custom-shader-material library (what dis, credit)
  - extending MeshStandardMaterial. First fragment shader that colors the mesh based on vUv
  - some simple vertex shader to change terrain height
  - Let's color based on terrain height (varying vPosition)`,
		` Step 2+
  - now we want to change position based on user input, let's make a sphere that follows the mouse
  - get normalized screen coordinates
  - make raycaster class
  - bind terrain ref to let
  - move sphere based on raycast
  - draw a sphere in glsl (smoothcircle function) - it will alter height
  - now it follows mouse but does not persist the depth trail`,
		`  Step 3+
  - how to make the trail persistent?
  - GPUComputationRenderer - render target bouncing
  - create texture
  - compute in useframe, but what? Make new shader.
  - will use Plane size and detail (bind to plane geometry & uniform/const)
  - pass sphere position (2d) to shader and radius + intensity uniform
  - take the circle drawing function and apply it in the compute shader at the point where sphere is
  - use compute texture as heightmap and alter vertices height in plane material shader`,
		`  Step 4+
  - Sphere position was only being updated on raycast. Move the logic out of the intersect call and use sphere position instead of mouse position
  - Depth keeps going indefinitely. Apply global max depth (even for this demo), imagine it's the depth of snow, and you can't make trails deeper than the snow is:
      - float newHeight = max(heightmapValue.y + change, -sphere.z * 0.8); this makes max depth just a bit smaller than the sphere's radius
  - fix: Sphere trail was inaccurate. It didn't need to be moved by half radius. I meant to move sphere by half of it's diameter.
  - make the trail slowly disappear:`
	];
	let currentStep = 4;
</script>

<div id="ui">
	<div>
		<button disabled={currentStep == 0} on:click={() => currentStep--}>Previous</button>
		<span>Step {currentStep + 1}</span>
		<button disabled={currentStep == steps.length - 1} on:click={() => currentStep++}>Next</button>
	</div>
	<code id="step-desc">
		{stepDesc[currentStep]}
	</code>
</div>

<Canvas frameloop={'always'}>
	<!-- <Step01 /> -->
	<!-- <Step02 /> -->
	<!-- <Step03 /> -->
	<!-- <Step04 /> -->
	<!-- <Step05 /> -->
	<svelte:component this={steps[currentStep]} />
</Canvas>

<style>
	#ui {
		position: fixed;
		display: flex;
		flex-direction: column;
	}
	#step-desc {
		max-width: 300px;
	}
</style>
