import React, { useState } from 'react';

interface Service {
  id: number;
  title: string;
  image: string;
  business_type: string;
}

interface ServiceCategoryProps {
  services: {
    results: Service[];
    count: number;
  };
}

const ServiceCategory: React.FC<ServiceCategoryProps> = ({ services }) => {
  const [hoveredId, setHoveredId] = useState<number | null>(null);
  const [clickedId, setClickedId] = useState<number | null>(null);

  const handleCardClick = (id: number, businessType: string) => {
    setClickedId(id);
    setTimeout(() => {
      setClickedId(null);
    }, 800);
  };

  const containerAnimations = [
    "animate-float-up-down",
    "animate-float-left-right",
    "animate-pulse-grow",
    "animate-bounce-subtle",
    "animate-wiggle",
  ];

  const iconAnimations = [
    "animate-pulse-premium",
    "animate-bounce-premium",
    "animate-shake-premium",
    "animate-float-3d",
    "animate-breathe-premium",
  ];

  const getContainerAnimation = (id: number) => {
    return containerAnimations[id % containerAnimations.length];
  };

  const getIconAnimation = (id: number) => {
    return iconAnimations[(id * 7) % iconAnimations.length];
  };

  return (
    <div className="py-2 md:p-6">
      <div className="grid grid-cols-3 sm:grid-cols-4 lg:flex justify-center lg:flex-wrap gap-1.5 sm:gap-3 mt-4 sm:mt-6">
        {services?.results.map((service) => (
          <div
            key={service.id}
            className={`relative rounded-xl border-2 border-dashed border-green-500 transition-all duration-300 cursor-pointer lg:w-[180px] ${
              hoveredId === service.id ? "border-green-600 shadow-md" : ""
            }`}
            onMouseEnter={() => setHoveredId(service.id)}
            onMouseLeave={() => setHoveredId(null)}
            onClick={() => handleCardClick(service.id, service.business_type)}
          >
            <div className="absolute inset-0 bg-green-50"></div>

            {clickedId === service.id && (
              <div className="absolute inset-0 bg-green-50/80 backdrop-blur-sm z-20 flex items-center justify-center overflow-hidden">
                <div className="relative">
                  <svg className="w-12 h-12 animate-spin-slow" viewBox="0 0 50 50">
                    <circle
                      className="stroke-green-500"
                      cx="25"
                      cy="25"
                      r="20"
                      fill="none"
                      strokeWidth="4"
                      strokeDasharray="60, 100"
                    />
                  </svg>
                  <svg
                    className="w-8 h-8 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 animate-spin-reverse"
                    viewBox="0 0 50 50"
                  >
                    <circle
                      className="stroke-green-600"
                      cx="25"
                      cy="25"
                      r="15"
                      fill="none"
                      strokeWidth="3"
                      strokeDasharray="40, 80"
                    />
                  </svg>
                  <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-green-600 rounded-full animate-pulse"></div>
                </div>
                <span className="absolute bottom-4 text-sm font-medium text-green-800 animate-pulse">
                  লোড হচ্ছে...
                </span>
              </div>
            )}

            <div className="relative z-10 flex flex-col items-center justify-center p-3 sm:p-2.5">
              <div
                className={`mb-3 w-16 h-16 flex items-center justify-center rounded-full bg-white relative ${getContainerAnimation(
                  service.id
                )}`}
              >
                <img
                  src={service.image}
                  alt={service.title}
                  className={`size-9 z-10 ${getIconAnimation(service.id)}`}
                />
              </div>
              <h3
                className={`text-md font-medium text-center ${
                  hoveredId === service.id ? "text-green-700" : "text-slate-600"
                }`}
              >
                {service.title}
              </h3>
              <div
                className={`absolute bottom-0 left-0 right-0 h-1.5 bg-green-400 transition-transform duration-300 origin-left ${
                  hoveredId === service.id ? "scale-x-100" : "scale-x-0"
                }`}
              ></div>
            </div>
          </div>
        ))}

        {services && !services.count && (
          <div className="col-span-3 w-full py-12 px-2 relative rounded-xl border-2 border-dashed border-green-500 bg-green-50 text-center overflow-hidden">
            <div className="absolute inset-0 opacity-10 bg-grid-pattern"></div>
            <div className="relative flex flex-col items-center justify-center mb-2">
              <div className="animate-search-motion mb-1">
                <span className="w-12 h-12 text-green-600">🔍</span>
              </div>
            </div>
            <p className="text-gray-700 font-medium max-w-md mx-auto">
              No categories found.
            </p>
            <p className="text-gray-500 text-sm mt-2 max-w-md mx-auto">
              Try searching for something else.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ServiceCategory;