import React from 'react';

const EshopTitle: React.FC = () => {
  const particles = Array.from({ length: 5 }, (_, index) => index);

  return (
    <div className="flex items-center justify-between mb-2">
      <div className="inline-flex items-center">
        <div className="w-8 h-8 text-emerald-600">🛍️</div>
        <div className="py-4 text-start relative">
          <h1
            className="text-2xl md:text-2xl ml-2 font-bold bg-clip-text text-transparent bg-gradient-to-r from-emerald-600 to-teal-500 inline-block"
          >
            eShop Manager
          </h1>
          {/* Header underline */}
          <div
            className="h-1 ml-2 w-44 mx-auto mt-2 rounded-full bg-gradient-to-r from-emerald-400 to-teal-400"
          ></div>

          {/* Floating particles around header */}
          {particles.map((n) => (
            <div
              key={`header-particle-${n}`}
              className="absolute w-1.5 h-1.5 rounded-full bg-emerald-400/50 service-particle"
              style={{
                top: `${50 + Math.random() * 30 - 15}%`,
                left: `${50 + Math.random() * 60 - 30}%`,
                animationDelay: `${Math.random() * 2}s`,
                animationDuration: `${3 + Math.random() * 2}s`,
              }}
            ></div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default EshopTitle;