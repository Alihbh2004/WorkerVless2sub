import React from 'react';
import { motion } from 'framer-motion';

const About: React.FC = () => {
  return (
    <section id="about" className="py-20 bg-gray-900/50 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row items-center gap-12">
        {/* Content */}
        <div className="md:w-1/2">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
          >
            <h2 className="text-4xl font-bold text-white mb-6 leading-tight">
              About <span className="text-blue-500">Me</span>
            </h2>
            <p className="text-gray-300 text-lg mb-6 leading-relaxed">
              I am <span className="text-white font-semibold">Ali Habibzadeh</span>, an IT Expert and AI Pioneer with a deep passion for technological innovation.
              My expertise lies in integrating advanced AI solutions with practical business applications.
            </p>
            <p className="text-gray-300 text-lg mb-6 leading-relaxed">
              With a strong background in E-commerce, I specialize in building intelligent systems that drive growth.
              From <span className="text-blue-400">AI Agents</span> and <span className="text-blue-400">n8n</span> automation to comprehensive CRM strategies,
              I help businesses scale efficiently.
            </p>
            <div className="grid grid-cols-2 gap-4 text-gray-400 text-sm">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                CRM & Customer Club
              </div>
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                SEO & Content
              </div>
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                App & Web Design
              </div>
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                Ads & Branding
              </div>
            </div>
          </motion.div>
        </div>

        {/* Image/Visual - Using a placeholder or 3D element later */}
        <div className="md:w-1/2 relative">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="relative z-10 w-full h-80 md:h-[500px] bg-gradient-to-tr from-blue-900/20 to-purple-900/20 rounded-2xl border border-gray-700 overflow-hidden flex items-center justify-center shadow-2xl"
          >
            <div className="absolute inset-0 flex items-center justify-center opacity-30">
               {/* This could be replaced with an actual image of Ali later */}
               <svg className="w-32 h-32 text-blue-500 animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                 <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M12 11c0 3.517-1.009 6.799-2.753 9.571m-3.44-2.04l.054-.09A13.916 13.916 0 008 11a4 4 0 118 0c0 1.017-.07 2.019-.203 3m-2.118 6.844A21.88 21.88 0 0015.171 17m3.839 1.132c.645-2.266.99-4.659.99-7.132A8 8 0 008 4.07M3 15.364c.64-1.319 1-2.8 1-4.364 0-1.457.2-2.858.59-4.18" />
               </svg>
            </div>
            <p className="z-20 text-gray-500 font-mono text-sm">[ Profile Image Placeholder ]</p>
          </motion.div>

          {/* Decorative background elements */}
          <div className="absolute -top-10 -right-10 w-40 h-40 bg-blue-500/20 rounded-full blur-3xl"></div>
          <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-purple-500/20 rounded-full blur-3xl"></div>
        </div>
      </div>
    </section>
  );
};

export default About;
