import React from 'react';

const Title: React.FC = () => {
  const particles = Array.from({ length: 5 }, (_, n) => ({
    key: `header-particle-${n}`,
    top: `${50 + (Math.random() * 30 - 15)}%`,
    left: `${50 + (Math.random() * 60 - 30)}%`,
    animationDelay: `${Math.random() * 2}s`,
    animationDuration: `${3 + Math.random() * 2}s`,
  }));

  return (
    <div className="flex items-center justify-between mb-4 md:mb-8">
      <div>
        <div className="py-4 text-start relative">
          <h1
            className="text-2xl ml-3 font-bold bg-clip-text text-transparent bg-gradient-to-r from-emerald-600 to-teal-500 inline-block"
          >
            Classified Service
          </h1>
          <div
            className="h-1 ml-4 w-28 mx-auto mt-2 rounded-full bg-gradient-to-r from-emerald-400 to-teal-400"
          ></div>

          {particles.map((particle) => (
            <div
              key={particle.key}
              className="absolute w-1.5 h-1.5 rounded-full bg-emerald-400/50 service-particle"
              style={{
                top: particle.top,
                left: particle.left,
                animationDelay: particle.animationDelay,
                animationDuration: particle.animationDuration,
              }}
            ></div>
          ))}
        </div>
      </div>

      <button
        className="relative overflow-hidden bg-white hover:bg-gray-50 text-emerald-600 font-medium rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 border border-dashed border-green-600 max-sm:!text-sm mr-2 px-3 py-1.5"
      >
        <span className="absolute inset-0 overflow-hidden">
          <span
            className="absolute inset-0 scale-0 rounded-full bg-emerald-200/70 group-hover:animate-ripple"
          ></span>
        </span>
        <div className="relative z-10 flex items-center justify-center space-x-2">
          <div className="icon-plus-container">
            <span className="text-2xl text-emerald-600 animate-pulse-icon">+</span>
          </div>
          <span className="text-xs font-medium">Post Free Ad</span>
        </div>
      </button>
    </div>
  );
};

export default Title;