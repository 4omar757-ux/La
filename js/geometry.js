// توليد هندسة "شريط" (ribbon) مسطّح لطريق من خط وسطه ونقاطه، بعرض معيّن.
// يرجع مصفوفات خام (positions/uvs/indices) تُغذّى مباشرة لـ THREE.BufferGeometry.
function buildRoadRibbon(points, width) {
  const n = points.length;
  if (n < 2) return null;

  const half = width / 2;
  const left = new Array(n);
  const right = new Array(n);

  for (let i = 0; i < n; i++) {
    const prev = points[Math.max(0, i - 1)];
    const next = points[Math.min(n - 1, i + 1)];
    let dx = next.x - prev.x;
    let dz = next.z - prev.z;
    const len = Math.hypot(dx, dz) || 1;
    dx /= len;
    dz /= len;
    // عمودي على اتجاه الطريق في مستوى XZ
    const px = -dz;
    const pz = dx;
    left[i] = { x: points[i].x + px * half, z: points[i].z + pz * half };
    right[i] = { x: points[i].x - px * half, z: points[i].z - pz * half };
  }

  const positions = new Float32Array(n * 2 * 3);
  const uvs = new Float32Array(n * 2 * 2);
  for (let i = 0; i < n; i++) {
    positions[i * 6 + 0] = left[i].x;
    positions[i * 6 + 1] = 0;
    positions[i * 6 + 2] = left[i].z;
    positions[i * 6 + 3] = right[i].x;
    positions[i * 6 + 4] = 0;
    positions[i * 6 + 5] = right[i].z;
    uvs[i * 4 + 0] = 0;
    uvs[i * 4 + 1] = i;
    uvs[i * 4 + 2] = 1;
    uvs[i * 4 + 3] = i;
  }

  const indices = [];
  for (let i = 0; i < n - 1; i++) {
    const l0 = i * 2, r0 = i * 2 + 1, l1 = (i + 1) * 2, r1 = (i + 1) * 2 + 1;
    indices.push(l0, r0, l1, r0, r1, l1);
  }

  return { positions, uvs, indices: new Uint32Array(indices) };
}
