import React, { useState, useEffect } from 'react';

const Header: React.FC = () => {
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 80);
    };

    window.addEventListener('scroll', handleScroll);
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  return (
    <div
      className={`py-3 z-[99999999] bg-slate-100/80 shadow-sm md:shadow-md rounded-2xl mx-2 dark:bg-black max-w-[1280px] md:mx-auto ${
        isScrolled
          ? 'fixed top-0 left-0 right-0 mx-auto backdrop-blur-sm border-b border-slate-200/50 rounded-2xl'
          : 'sticky'
      }`}
    >
      {/* Subscription Warnings */}
      <div className="subscription-warnings relative px-4">
        {/* Example warning content */}
        <div className="mx-auto my-2 px-4 relative overflow-hidden rounded-lg border border-amber-300/70 dark:border-amber-600/50 group transition-all duration-300 hover:shadow-lg">
          <div className="absolute inset-0 bg-gradient-to-r from-amber-50/90 via-amber-50/80 to-amber-100/90 dark:from-amber-900/30 dark:via-amber-800/20 dark:to-amber-900/30 backdrop-blur-md"></div>
          <div className="relative z-10 p-2.5 sm:p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-2 sm:gap-3">
              <div className="relative hidden xs:block">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-amber-100 to-amber-200 dark:from-amber-800 dark:to-amber-700 border border-amber-300/50 dark:border-amber-600/30 flex items-center justify-center shadow-inner"></div>
              </div>
              <div className="inline-flex items-center gap-2">
                <h3 className="text-xs sm:text-sm font-medium text-amber-800">
                  Subscription expiring in <span className="inline-block ml-1 font-semibold">3 days</span>
                </h3>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button
                className="!p-1 hover:rotate-90 transition-transform"
                aria-label="Dismiss"
              >
                ✖
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Header Content */}
      <div className="flex items-center justify-between gap-1.5 lg:gap-6">
        <div className="block md:hidden">
          <button className="icon-button">☰</button>
        </div>
        <div className="hidden md:block">
          <nav className="border-b border-gray-200 dark:border-gray-800 text-lg">
            <ul className="flex space-x-4">
              <li><a href="/">Home</a></li>
              <li><a href="/#classified-services">Classified Services</a></li>
              <li><a href="/#micro-gigs">Earn Money</a></li>
              <li><a href="/faq">FAQ</a></li>
              <li><a href="/mobile-recharge">Mobile Recharge</a></li>
            </ul>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default Header;