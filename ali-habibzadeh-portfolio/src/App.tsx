import { Suspense } from 'react';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import About from './components/About';
import Skills from './components/Skills';
import Contact from './components/Contact';
import Scene3D from './components/Scene3D';

function App() {
  return (
    <div className="relative min-h-screen bg-black text-white font-sans antialiased selection:bg-blue-500 selection:text-white">
      {/* 3D Background */}
      <Suspense fallback={<div className="fixed inset-0 bg-black z-0 flex items-center justify-center text-blue-500">Loading 3D Scene...</div>}>
        <Scene3D />
      </Suspense>

      {/* Navigation */}
      <Navbar />

      {/* Main Content */}
      <main className="relative z-10 w-full">
        <Hero />
        <About />
        <Skills />
        <Contact />
      </main>
    </div>
  );
}

export default App;
