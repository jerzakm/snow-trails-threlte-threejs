<!-- Step 1
- Setup
- grid
- environment
- lights
- plane + rotate it 
- pierced props
- make plane bigger
-->
<script lang="ts">
	import { OrbitControls, T } from '@threlte/core';
	import { Environment, Grid } from '@threlte/extras';
	import { DEG2RAD } from 'three/src/math/MathUtils';
</script>

<T.PerspectiveCamera let:ref position={[0, 8, 15]} fov={35} far={200} makeDefault>
	<OrbitControls enableZoom={true} target={{ x: 0, y: 0, z: 0 }} />
</T.PerspectiveCamera>

<Environment files="env/belfast_sunset_puresky_4k.hdr" isBackground />
<Grid sectionColor={'black'} sectionSize={10} position.y={0.01} />

<T.Mesh rotation.x={-DEG2RAD * 90}>
	<T.PlaneGeometry args={[20, 20]} />
	<T.MeshStandardMaterial />
</T.Mesh>
