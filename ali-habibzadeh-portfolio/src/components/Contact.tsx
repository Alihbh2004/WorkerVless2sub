import React from 'react';
import { Mail, Github, Linkedin, Twitter } from 'lucide-react';

const Contact: React.FC = () => {
  return (
    <section id="contact" className="py-20 bg-gray-900 text-white border-t border-gray-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold mb-4">
            Get in <span className="text-blue-500">Touch</span>
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Ready to start a new project or collaborate on something amazing?
            Let's connect and discuss how we can bring your ideas to life.
          </p>
        </div>

        <div className="flex flex-col md:flex-row justify-center items-center gap-12">
          {/* Contact Info */}
          <div className="flex flex-col items-center md:items-start space-y-6">
            <a href="mailto:contact@alihabibzadeh.com" className="flex items-center space-x-3 text-gray-300 hover:text-white transition-colors text-lg">
              <Mail size={24} />
              <span>contact@alihabibzadeh.com</span>
            </a>

            <div className="flex space-x-6 mt-8">
              <a href="#" className="p-3 bg-gray-800 rounded-full hover:bg-blue-600 transition-colors">
                <Github size={24} />
              </a>
              <a href="#" className="p-3 bg-gray-800 rounded-full hover:bg-blue-600 transition-colors">
                <Linkedin size={24} />
              </a>
              <a href="#" className="p-3 bg-gray-800 rounded-full hover:bg-blue-600 transition-colors">
                <Twitter size={24} />
              </a>
            </div>
          </div>

          {/* Simple Form */}
          <form className="w-full max-w-lg bg-gray-800/50 p-8 rounded-2xl border border-gray-700">
            <div className="mb-4">
              <label htmlFor="name" className="block text-sm font-medium text-gray-400 mb-2">Name</label>
              <input type="text" id="name" className="w-full bg-gray-900 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors text-white" placeholder="Your Name" />
            </div>
            <div className="mb-4">
              <label htmlFor="email" className="block text-sm font-medium text-gray-400 mb-2">Email</label>
              <input type="email" id="email" className="w-full bg-gray-900 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors text-white" placeholder="you@example.com" />
            </div>
            <div className="mb-6">
              <label htmlFor="message" className="block text-sm font-medium text-gray-400 mb-2">Message</label>
              <textarea id="message" rows={4} className="w-full bg-gray-900 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors text-white" placeholder="How can I help you?"></textarea>
            </div>
            <button type="submit" className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg transition-colors">
              Send Message
            </button>
          </form>
        </div>

        <div className="mt-20 pt-8 border-t border-gray-800 text-center text-gray-500 text-sm">
          &copy; {new Date().getFullYear()} Ali Habibzadeh. All rights reserved.
        </div>
      </div>
    </section>
  );
};

export default Contact;
