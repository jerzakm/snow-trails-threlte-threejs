import type { RigidBody as TRigidBody, Collider as TCollider } from '@dimforge/rapier3d-compat';

export interface Ball {
	startingPosition: { x: number; y: number; z: number };
	size: number;
	rigidBody?: TRigidBody;
	collider?: TCollider;
}
