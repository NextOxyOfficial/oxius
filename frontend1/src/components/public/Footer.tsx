import React from 'react';

const Footer: React.FC = () => {
  return (
    <footer className="pt-6 bg-slate-100/70 dark:bg-slate-900 relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 bg-pattern opacity-10 dark:opacity-10"></div>

      {/* Gradient Accents */}
      <div className="absolute -top-24 -right-24 w-72 h-72 bg-emerald-400 dark:bg-emerald-600 rounded-full opacity-5 blur-3xl"></div>
      <div className="absolute -bottom-24 -left-24 w-72 h-72 bg-blue-400 dark:bg-blue-600 rounded-full opacity-5 blur-3xl"></div>

      {/* Content */}
      <div className="relative">
        <div className="text-center mb-6">
          <h3 className="mt-6 px-7 text-center text-base font-medium text-slate-600 dark:text-slate-300">
            AdsyClub – Bangladesh’s 1st Social Business Network: Earn Money, Connect with Society & Find the Services You Need!
          </h3>
        </div>

        <div className="flex flex-col sm:flex-row justify-between gap-5 lg:gap-12 sm:items-center px-[7px] max-w-5xl mx-auto dark:text-gray-200">
          <div className="flex flex-col gap-4">
            <h4 className="font-bold hidden md:block">Download App</h4>
            <ul className="flex gap-2 flex-1 max-md:justify-center">
              <li className="w-[117px]">
                <a href="/coming-soon/" className="transition-transform hover:scale-105 duration-300 block">
                  <img
                    src="/static/frontend/images/apple.png"
                    className="mx-auto w-full shadow-sm rounded-lg"
                    alt="App"
                  />
                </a>
              </li>
              <li className="w-[119px]">
                <a href="/coming-soon/" className="transition-transform hover:scale-105 duration-300 block">
                  <img
                    src="/static/frontend/images/google.png"
                    className="mx-auto w-full shadow-sm rounded-lg"
                    alt="App"
                  />
                </a>
              </li>
            </ul>
          </div>
          <div>
            <div className="flex flex-col gap-4">
              <h4 className="font-bold hidden md:block text-center">We Accept</h4>
              <img
                src="/static/frontend/images/payment.png"
                alt="Payment"
                className="md:w-[370px]"
              />
            </div>
          </div>
        </div>

        <div className="text-center text-sm text-slate-600 dark:text-gray-200 flex items-center justify-center gap-1 flex-wrap pt-6 pb-20 sm:pb-6">
          <span>Developed With</span>
          <span className="inline-flex items-center">
            <span className="text-red-500 h-5 w-5 mx-0.5 animate-pulse">❤️</span>
          </span>
          <span>By Lyricz Softwares & Technology Limited © {new Date().getFullYear()}</span>
        </div>
      </div>
    </footer>
  );
};

export default Footer;