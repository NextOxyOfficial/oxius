import React, { useEffect, useState } from 'react';

const ShopBanner: React.FC = () => {
  const sliderImages = [
    '/img/banner1.jpg',
    '/img/banner2.jpg',
    '/img/banner3.jpg',
  ];

  const [currentSlide, setCurrentSlide] = useState(0);

  const nextSlide = () => {
    setCurrentSlide((prev) => (prev === sliderImages.length - 1 ? 0 : prev + 1));
  };

  const prevSlide = () => {
    setCurrentSlide((prev) => (prev === 0 ? sliderImages.length - 1 : prev - 1));
  };

  const goToSlide = (index: number) => {
    setCurrentSlide(index);
  };

  useEffect(() => {
    const intervalId = setInterval(() => {
      nextSlide();
    }, 5000);

    return () => {
      clearInterval(intervalId);
    };
  }, []);

  return (
    <div className="mb-4">
      <div className="max-w-7xl w-full mx-auto">
        <div className="rounded-md overflow-hidden shadow-sm bg-gradient-to-br from-slate-50 to-white border border-gray-100">
          <div className="flex flex-col md:flex-row">
            <div className="w-full relative overflow-hidden">
              <div className="relative pb-[40.625%] md:pb-[40.4%] lg:pb-[40.625%]">
                {sliderImages.map((src, index) => (
                  <div
                    key={index}
                    className={`absolute inset-0 transition-all duration-700 ease-in-out transform ${
                      index === currentSlide
                        ? 'opacity-100 scale-100'
                        : 'opacity-0 scale-105'
                    }`}
                  >
                    <div className="absolute inset-0 bg-gradient-to-r from-black/30 to-transparent z-10"></div>
                    <img
                      src={src}
                      alt={`Slide ${index + 1}`}
                      className="w-full h-full object-cover"
                    />
                  </div>
                ))}
              </div>

              <button
                onClick={prevSlide}
                className="absolute left-3 top-1/2 -translate-y-1/2 bg-white/10 backdrop-blur-sm hover:bg-white/20 rounded-full p-1.5 sm:p-2 z-20 transition-all duration-300 border border-white/20"
                aria-label="Previous slide"
              >
                ◀
              </button>

              <button
                onClick={nextSlide}
                className="absolute right-3 top-1/2 -translate-y-1/2 bg-white/10 backdrop-blur-sm hover:bg-white/20 rounded-full p-1.5 sm:p-2 z-20 transition-all duration-300 border border-white/20"
                aria-label="Next slide"
              >
                ▶
              </button>

              <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex space-x-2 z-20">
                {sliderImages.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => goToSlide(index)}
                    className={`w-2 h-2 rounded-full transition-all duration-300 ${
                      index === currentSlide
                        ? 'bg-white scale-110'
                        : 'bg-white/40 hover:bg-white/60'
                    }`}
                    aria-label={`Go to slide ${index + 1}`}
                  ></button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ShopBanner;