import React from 'react';
import { motion } from 'framer-motion';

const Hero: React.FC = () => {
  return (
    <div id="hero" className="relative w-full h-screen flex items-center justify-center overflow-hidden">
      {/* Overlay content */}
      <div className="z-10 text-center px-4 md:px-8 max-w-5xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <h2 className="text-xl md:text-2xl text-blue-400 font-mono mb-4">
            Hello, I'm
          </h2>
          <h1 className="text-5xl md:text-7xl font-bold text-white mb-6 tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-blue-400 via-purple-500 to-pink-500">
            ALI HABIBZADEH
          </h1>
          <h3 className="text-2xl md:text-4xl text-gray-300 font-light mb-8">
            AI Pioneer & IT Expert
          </h3>
          <p className="text-gray-400 max-w-2xl mx-auto text-lg mb-10 leading-relaxed">
            Specializing in AI Agents, E-commerce, CRM, and Digital Transformation.
            Building the future of business with cutting-edge technology.
          </p>

          <div className="flex flex-col md:flex-row gap-4 justify-center items-center">
            <a
              href="#contact"
              className="px-8 py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-full transition-all transform hover:scale-105 shadow-lg shadow-blue-500/30"
            >
              Get in Touch
            </a>
            <a
              href="#about"
              className="px-8 py-3 bg-transparent border border-blue-500 text-blue-400 hover:bg-blue-500/10 font-bold rounded-full transition-all"
            >
              View Work
            </a>
          </div>
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <motion.div
        className="absolute bottom-10 left-1/2 transform -translate-x-1/2 z-10"
        animate={{ y: [0, 10, 0] }}
        transition={{ duration: 1.5, repeat: Infinity }}
      >
        <div className="w-6 h-10 border-2 border-gray-500 rounded-full flex justify-center p-1">
          <div className="w-1 h-3 bg-gray-500 rounded-full" />
        </div>
      </motion.div>
    </div>
  );
};

export default Hero;
