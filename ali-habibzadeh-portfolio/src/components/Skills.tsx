import React from 'react';
import { motion } from 'framer-motion';

const skills = [
  { name: 'AI Agents', description: 'n8n & Workflow Automation', level: 'Advanced' },
  { name: 'E-commerce', description: 'Business Strategy & Growth', level: 'Advanced' },
  { name: 'CRM', description: 'Customer Relationship Management', level: 'Expert' },
  { name: 'SEO', description: 'Search Engine Optimization', level: 'Expert' },
  { name: 'Content Creation', description: 'Engaging Multimedia', level: 'Skilled' },
  { name: 'Web Design', description: 'Modern UI/UX', level: 'Advanced' },
  { name: 'App Design', description: 'Mobile First Approach', level: 'Advanced' },
  { name: 'Branding', description: 'Identity & Voice', level: 'Expert' },
  { name: 'Google Ads', description: 'PPC & Campaign Management', level: 'Certified' },
];

const Skills: React.FC = () => {
  return (
    <section id="skills" className="py-20 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-gray-900 via-gray-800 to-gray-900 opacity-90 -z-10"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl font-bold text-white mb-4">
            My <span className="text-blue-500">Expertise</span>
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            A comprehensive toolkit for digital success, spanning from technical implementation to strategic planning.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {skills.map((skill, index) => (
            <motion.div
              key={skill.name}
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              viewport={{ once: true }}
              className="bg-gray-800/50 backdrop-blur-sm p-6 rounded-xl border border-gray-700 hover:border-blue-500 transition-colors group cursor-pointer"
            >
              <div className="flex justify-between items-start mb-4">
                <h3 className="text-xl font-bold text-white group-hover:text-blue-400 transition-colors">
                  {skill.name}
                </h3>
                <span className="text-xs font-mono text-gray-500 bg-gray-900 px-2 py-1 rounded">
                  {skill.level}
                </span>
              </div>
              <p className="text-gray-400 text-sm">
                {skill.description}
              </p>
              <div className="mt-4 w-full bg-gray-700 h-1 rounded-full overflow-hidden">
                <div
                  className="bg-blue-500 h-full rounded-full"
                  style={{ width: skill.level === 'Expert' ? '95%' : skill.level === 'Advanced' ? '85%' : '75%' }}
                ></div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Skills;
