import React, { useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Points, PointMaterial, Float, Text } from '@react-three/drei';
import * as THREE from 'three';

const generateParticles = (count: number) => {
  const positions = new Float32Array(count * 3);
  const colors = new Float32Array(count * 3);
  const color = new THREE.Color();

  for (let i = 0; i < count; i++) {
    const r = 40 * Math.cbrt(Math.random()); // Radius
    const theta = Math.random() * 2 * Math.PI;
    const phi = Math.acos(2 * Math.random() - 1);

    const x = r * Math.sin(phi) * Math.cos(theta);
    const y = r * Math.sin(phi) * Math.sin(theta);
    const z = r * Math.cos(phi);

    positions[i * 3] = x;
    positions[i * 3 + 1] = y;
    positions[i * 3 + 2] = z;

    // Color gradient from blue to purple
    color.setHSL(0.6 + Math.random() * 0.1, 0.8, 0.5 + Math.random() * 0.3);
    colors[i * 3] = color.r;
    colors[i * 3 + 1] = color.g;
    colors[i * 3 + 2] = color.b;
  }
  return [positions, colors];
};

const ParticleField = (props: React.ComponentProps<typeof Points>) => {
  const ref = useRef<THREE.Points>(null!);

  // Generate random points in a sphere
  const [positions, colors] = useMemo(() => generateParticles(2000), []);

  useFrame((_state, delta) => {
    if (ref.current) {
      ref.current.rotation.x -= delta / 10;
      ref.current.rotation.y -= delta / 15;
    }
  });

  return (
    <group rotation={[0, 0, Math.PI / 4]}>
      <Points ref={ref} positions={positions} colors={colors} stride={3} frustumCulled={false} {...props}>
        <PointMaterial
          transparent
          vertexColors
          size={0.15}
          sizeAttenuation={true}
          depthWrite={false}
          blending={THREE.AdditiveBlending}
        />
      </Points>
    </group>
  );
};

const FloatingText = ({ position, text, color = '#4fa1f8', fontSize = 1 }: { position: [number, number, number], text: string, color?: string, fontSize?: number }) => {
  return (
    <Float speed={1.5} rotationIntensity={0.2} floatIntensity={0.5}>
      <Text
        position={position}
        color={color}
        fontSize={fontSize}
        maxWidth={20}
        lineHeight={1}
        letterSpacing={0.05}
        textAlign="center"
        anchorX="center"
        anchorY="middle"
      >
        {text}
      </Text>
    </Float>
  );
};

const Scene3D: React.FC = () => {
  return (
    <div className="fixed inset-0 z-0 bg-black">
      <Canvas camera={{ position: [0, 0, 15], fov: 60 }}>
        <React.Suspense fallback={null}>
          <ambientLight intensity={0.5} />
          <ParticleField />

          {/* Floating Keywords */}
          <group position={[0, 0, -5]}>
             <FloatingText position={[-6, 4, 0]} text="AI Agent" fontSize={0.8} />
             <FloatingText position={[6, -3, 2]} text="n8n" fontSize={1.2} color="#ff6b6b" />
             <FloatingText position={[-5, -5, -2]} text="SEO" fontSize={0.9} color="#ffd93d" />
             <FloatingText position={[7, 5, -3]} text="Branding" fontSize={0.7} color="#a8e6cf" />
             <FloatingText position={[0, 8, -5]} text="Google Ads" fontSize={0.8} />
             <FloatingText position={[0, -8, -5]} text="CRM" fontSize={0.8} />
          </group>
        </React.Suspense>

        {/* Subtle camera movement or controls could be added here */}
        {/* <OrbitControls enableZoom={false} autoRotate autoRotateSpeed={0.5} /> */}
        {/* We keep it static for better UX with scroll, or use scroll controls */}
      </Canvas>
      <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-black pointer-events-none"></div>
    </div>
  );
};

export default Scene3D;
