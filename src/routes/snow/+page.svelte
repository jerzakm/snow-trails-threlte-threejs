<script lang="ts">
	import { Canvas } from '@threlte/core';
	import Scene2 from './Scene2.svelte';
</script>

<div class="wrapper">
	<Canvas frameloop={'always'}>
		<Scene2 />
	</Canvas>
</div>

<style>
	.wrapper {
		width: 100vw;
		height: 100vh;
		position: fixed;
		top: 0;
		left: 0;
	}
</style>
