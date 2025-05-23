<template>
  <div class="bg-gradient-to-b from-white to-gray-50 dark:from-slate-900 dark:to-slate-800 min-h-screen">
    <!-- Header Section with Decorative Element -->
    <div class="relative bg-green-600 dark:bg-green-800 py-12 mb-8 overflow-hidden">
      <div class="absolute inset-0 overflow-hidden">
        <div class="absolute -right-10 -top-20 w-72 h-72 rounded-full bg-green-500 opacity-20"></div>
        <div class="absolute -left-20 -bottom-20 w-80 h-80 rounded-full bg-green-400 opacity-10"></div>
        <div class="absolute right-1/4 bottom-1/4 w-40 h-40 rounded-full bg-white opacity-10"></div>
      </div>
      <UContainer class="relative z-10">
        <div class="text-center">
          <h1 class="text-3xl md:text-4xl font-bold text-white mb-2">About Adsy Club</h1>
          <p class="text-green-100 max-w-3xl mx-auto">
            Bangladesh's 1st Social Business Network
          </p>
        </div>
      </UContainer>
    </div>

    <!-- Main Content -->
    <UContainer class="mb-16">
      <!-- Introduction Card -->
      <div class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 p-6 mb-8">
        <div class="flex items-start">
          <div class="bg-green-50 dark:bg-green-900/30 p-3 rounded-lg mr-4">
            <UIcon name="i-heroicons-building-storefront" class="w-6 h-6 text-green-600 dark:text-green-400"/>
          </div>
          <div>
            <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Welcome to Adsy Club</h2>
            <p class="text-gray-600 dark:text-gray-300 leading-relaxed">
              Adsy Club is Bangladesh's first social business network dedicated to connecting individuals and businesses through an innovative platform. Our mission is to create a vibrant ecosystem where you can earn money, build meaningful connections, and find the services you need—all in one place.
            </p>
          </div>
        </div>
      </div>
      
      <!-- Main About Content -->
      <div class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 overflow-hidden">
        <!-- Table of Contents -->
        <div class="border-b border-gray-100 dark:border-slate-700 bg-gray-50 dark:bg-slate-800/80 p-5">
          <h3 class="font-medium text-gray-900 dark:text-white mb-3 flex items-center">
            <UIcon name="i-heroicons-list-bullet" class="w-5 h-5 mr-2 text-green-600 dark:text-green-400"/>
            What's Inside
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            <a href="#section-1" class="text-green-600 dark:text-green-400 hover:underline text-sm flex items-center">
              <span class="w-5 h-5 inline-flex items-center justify-center bg-green-100 dark:bg-green-900/50 text-green-600 dark:text-green-400 rounded-full mr-2 text-xs font-medium">1</span>
              Our Vision
            </a>
            <a href="#section-2" class="text-green-600 dark:text-green-400 hover:underline text-sm flex items-center">
              <span class="w-5 h-5 inline-flex items-center justify-center bg-green-100 dark:bg-green-900/50 text-green-600 dark:text-green-400 rounded-full mr-2 text-xs font-medium">2</span>
              What We Offer
            </a>
            <a href="#section-3" class="text-green-600 dark:text-green-400 hover:underline text-sm flex items-center">
              <span class="w-5 h-5 inline-flex items-center justify-center bg-green-100 dark:bg-green-900/50 text-green-600 dark:text-green-400 rounded-full mr-2 text-xs font-medium">3</span>
              User-Friendly Platform
            </a>
            <a href="#section-4" class="text-green-600 dark:text-green-400 hover:underline text-sm flex items-center">
              <span class="w-5 h-5 inline-flex items-center justify-center bg-green-100 dark:bg-green-900/50 text-green-600 dark:text-green-400 rounded-full mr-2 text-xs font-medium">4</span>
              Business Network
            </a>
            <a href="#section-5" class="text-green-600 dark:text-green-400 hover:underline text-sm flex items-center">
              <span class="w-5 h-5 inline-flex items-center justify-center bg-green-100 dark:bg-green-900/50 text-green-600 dark:text-green-400 rounded-full mr-2 text-xs font-medium">5</span>
              Commitment to Safety
            </a>
            <a href="#section-6" class="text-green-600 dark:text-green-400 hover:underline text-sm flex items-center">
              <span class="w-5 h-5 inline-flex items-center justify-center bg-green-100 dark:bg-green-900/50 text-green-600 dark:text-green-400 rounded-full mr-2 text-xs font-medium">6</span>
              Our Future
            </a>
          </div>
        </div>
        
        <!-- About Content -->
        <div class="p-6">
          <div class="space-y-8">
            <!-- Our Vision -->
            <section id="section-1" class="scroll-mt-24">
              <div class="flex items-center mb-3">
                <div class="bg-green-100 dark:bg-green-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
                  <span class="text-green-600 dark:text-green-400 font-semibold">1</span>
                </div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Our Vision</h2>
              </div>
              <div class="pl-11">
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  At Adsy Club, we envision a marketplace where users can engage freely and safely while building a sustainable income. We believe in empowering Bangladeshis to take control of their economic future, fostering a sense of community, and promoting innovative business practices through our comprehensive platform.
                </p>
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  Our goal is to bridge the gap between businesses and customers, creating opportunities for growth and collaboration in a rapidly evolving digital landscape. We're committed to being at the forefront of Bangladesh's digital transformation by providing tools that enable entrepreneurship and connection.
                </p>
                <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 border border-green-100 dark:border-green-900/30 mb-4">
                  <div class="flex items-center mb-2">
                    <UIcon name="i-heroicons-light-bulb" class="w-5 h-5 text-green-600 dark:text-green-400 mr-2" />
                    <h3 class="font-medium text-gray-900 dark:text-white">Our Mission</h3>
                  </div>
                  <p class="text-gray-600 dark:text-gray-300 text-sm">
                    To create Bangladesh's most trusted platform for business networking, classified advertisements, and service discovery, empowering users to earn, connect, and grow together.
                  </p>
                </div>
              </div>
            </section>
            
            <!-- What We Offer -->
            <section id="section-2" class="scroll-mt-24">
              <div class="flex items-center mb-3">
                <div class="bg-green-100 dark:bg-green-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
                  <span class="text-green-600 dark:text-green-400 font-semibold">2</span>
                </div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">What We Offer</h2>
              </div>
              <div class="pl-11">
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-6">
                  Adsy Club combines multiple services in one cohesive platform, designed to meet the diverse needs of Bangladesh's growing digital community:
                </p>
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  <div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
                    <div class="flex items-center mb-2 text-green-600 dark:text-green-400">
                      <UIcon name="i-heroicons-newspaper" class="w-5 h-5 mr-2" />
                      <h4 class="font-medium">Classified Advertisements</h4>
                    </div>
                    <p class="text-gray-600 dark:text-gray-300 text-sm">
                      Post and browse classified ads across multiple categories, from electronics and vehicles to services and job opportunities.
                    </p>
                  </div>
                  
                  <div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
                    <div class="flex items-center mb-2 text-green-600 dark:text-green-400">
                      <UIcon name="i-heroicons-briefcase" class="w-5 h-5 mr-2" />
                      <h4 class="font-medium">Business Networking</h4>
                    </div>
                    <p class="text-gray-600 dark:text-gray-300 text-sm">
                      Connect with other professionals and businesses to establish partnerships, collaborations, and expand your professional network.
                    </p>
                  </div>
                  
                  <div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
                    <div class="flex items-center mb-2 text-green-600 dark:text-green-400">
                      <UIcon name="i-heroicons-device-phone-mobile" class="w-5 h-5 mr-2" />
                      <h4 class="font-medium">Mobile Recharge</h4>
                    </div>
                    <p class="text-gray-600 dark:text-gray-300 text-sm">
                      Easily recharge mobile credits directly through our platform, saving time and providing convenience.
                    </p>
                  </div>
                  
                  <div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
                    <div class="flex items-center mb-2 text-green-600 dark:text-green-400">
                      <UIcon name="i-heroicons-currency-bangladeshi" class="w-5 h-5 mr-2" />
                      <h4 class="font-medium">Earning Opportunities</h4>
                    </div>
                    <p class="text-gray-600 dark:text-gray-300 text-sm">
                      Multiple ways to generate income, including posting services, referring friends, and participating in our growing ecosystem.
                    </p>
                  </div>
                </div>
              </div>
            </section>
            
            <!-- User-Friendly Platform -->
            <section id="section-3" class="scroll-mt-24">
              <div class="flex items-center mb-3">
                <div class="bg-green-100 dark:bg-green-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
                  <span class="text-green-600 dark:text-green-400 font-semibold">3</span>
                </div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">User-Friendly Platform</h2>
              </div>
              <div class="pl-11">
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  Our platform is designed with the user in mind. With intuitive navigation and easy-to-use features, posting and browsing ads is simple and efficient. Users can create listings in just a few clicks, complete with photos and descriptions, ensuring that their offerings are clearly communicated.
                </p>
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  We've built Adsy Club using modern web technologies to ensure a smooth experience across all devices. Whether you're using a smartphone, tablet, or computer, our responsive design adapts to your screen size and provides consistent functionality.
                </p>
                <div class="flex flex-wrap gap-2 mb-4">
                  <span class="bg-gray-100 dark:bg-slate-700 px-3 py-1 rounded-full text-xs font-medium text-gray-600 dark:text-gray-300">Mobile-Friendly</span>
                  <span class="bg-gray-100 dark:bg-slate-700 px-3 py-1 rounded-full text-xs font-medium text-gray-600 dark:text-gray-300">Fast Loading</span>
                  <span class="bg-gray-100 dark:bg-slate-700 px-3 py-1 rounded-full text-xs font-medium text-gray-600 dark:text-gray-300">Easy Navigation</span>
                  <span class="bg-gray-100 dark:bg-slate-700 px-3 py-1 rounded-full text-xs font-medium text-gray-600 dark:text-gray-300">Dark Mode Support</span>
                  <span class="bg-gray-100 dark:bg-slate-700 px-3 py-1 rounded-full text-xs font-medium text-gray-600 dark:text-gray-300">Multi-language Support</span>
                </div>
              </div>
            </section>
            
            <!-- Business Network -->
            <section id="section-4" class="scroll-mt-24">
              <div class="flex items-center mb-3">
                <div class="bg-green-100 dark:bg-green-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
                  <span class="text-green-600 dark:text-green-400 font-semibold">4</span>
                </div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Business Network</h2>
              </div>
              <div class="pl-11">
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  At the core of Adsy Club is our unique business networking feature that sets us apart from traditional classified platforms. Our business network allows entrepreneurs, professionals, and service providers to:
                </p>
                <ul class="list-disc list-inside space-y-2 text-gray-600 dark:text-gray-300 mb-4 pl-2">
                  <li>Create detailed business profiles to showcase their services</li>
                  <li>Connect with potential clients and partners</li>
                  <li>Receive reviews and build reputation</li>
                  <li>Access business tools and resources</li>
                  <li>Participate in a community of like-minded professionals</li>
                </ul>
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  Whether you're a small business owner, freelancer, or established company, our business network provides the tools and connections you need to grow your venture and increase your visibility in the marketplace.
                </p>
              </div>
            </section>
            
            <!-- Commitment to Safety -->
            <section id="section-5" class="scroll-mt-24">
              <div class="flex items-center mb-3">
                <div class="bg-green-100 dark:bg-green-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
                  <span class="text-green-600 dark:text-green-400 font-semibold">5</span>
                </div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Commitment to Safety</h2>
              </div>
              <div class="pl-11">
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  Safety is a top priority at Adsy Club. We strive to create a secure environment for all users by implementing strict content guidelines and monitoring listings for compliance. Our team is dedicated to ensuring that all interactions on the platform are safe and trustworthy.
                </p>
                <div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm mb-4">
                  <div class="flex items-center mb-2">
                    <UIcon name="i-heroicons-shield-check" class="w-5 h-5 text-green-600 dark:text-green-400 mr-2" />
                    <h4 class="font-medium text-gray-900 dark:text-white">Our Safety Measures</h4>
                  </div>
                  <ul class="list-disc list-inside space-y-1 text-gray-600 dark:text-gray-300 text-sm">
                    <li>Verification processes for businesses and users</li>
                    <li>Secure payment processing through trusted partners</li>
                    <li>Content moderation to maintain quality standards</li>
                    <li>Privacy controls that put you in charge of your data</li>
                    <li>Regular security audits and updates</li>
                  </ul>
                </div>
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed">
                  We're committed to continuously improving our safety measures to adapt to new challenges and ensure that Adsy Club remains a trusted platform for all your business and classified needs.
                </p>
              </div>
            </section>
            
            <!-- Our Future -->
            <section id="section-6" class="scroll-mt-24">
              <div class="flex items-center mb-3">
                <div class="bg-green-100 dark:bg-green-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
                  <span class="text-green-600 dark:text-green-400 font-semibold">6</span>
                </div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Our Future</h2>
              </div>
              <div class="pl-11">
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
                  As Adsy Club continues to grow, we aim to enhance our services further by incorporating advanced features and technologies. Our future goals include improving user experience through personalized recommendations, expanding our reach across Bangladesh, and continually enhancing the opportunities for our users to connect and prosper.
                </p>
                <p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-6">
                  We're committed to evolving alongside Bangladesh's digital transformation and playing a key role in creating a more connected and prosperous business ecosystem.
                </p>
                <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 border border-green-100 dark:border-green-900/30">
                  <p class="text-gray-800 dark:text-white font-medium mb-2">Join Us on This Journey</p>
                  <p class="text-gray-600 dark:text-gray-300 text-sm">
                    Adsy Club is more than just a platform; it's a growing community of entrepreneurs, businesses, and customers working together to create value. We invite you to be part of this journey as we build Bangladesh's premier social business network.
                  </p>
                  <div class="mt-4">
                    <UButton color="green" variant="soft" size="sm">Sign Up Today</UButton>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script></script>

<style scoped>
/* Smooth transitions for theme changes */
* {
  transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease, box-shadow 0.3s ease;
}

/* Scrollbar styling for webkit browsers */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.05);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb {
  background: rgba(34, 197, 94, 0.5);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(34, 197, 94, 0.7);
}

/* Animations */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes pulseGlow {
  0% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(34, 197, 94, 0); }
  100% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0); }
}

/* Apply animations to sections */
section {
  animation: fadeIn 0.6s ease forwards;
  opacity: 0;
}

/* Enhance focus styles for better accessibility */
a:focus, button:focus {
  outline: 2px solid rgba(34, 197, 94, 0.5);
  outline-offset: 2px;
}

/* Gradient animation for links */
a[href^="#section-"] {
  position: relative;
  transition: all 0.3s ease;
}

a[href^="#section-"]:hover {
  background: linear-gradient(90deg, rgba(34, 197, 94, 0.1) 0%, rgba(34, 197, 94, 0) 100%);
  padding-left: 0.5rem;
  padding-right: 0.5rem;
  border-radius: 4px;
}

/* Card hover effects */
.bg-white, .bg-slate-800 {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.bg-white:hover, .bg-slate-800:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
}

/* Print styles */
@media print {
  .bg-gradient-to-b {
    background: white !important;
    color: black !important;
  }
  
  .bg-green-600, .bg-green-800 {
    background: #f0f0f0 !important;
    color: black !important;
  }
  
  * {
    color: black !important;
    background-color: transparent !important;
  }
  
  a {
    text-decoration: underline;
  }
  
  section {
    page-break-inside: avoid;
  }
}
</style>

<script setup>
import { ref, onMounted } from 'vue';

// Track page load state
const pageLoaded = ref(false);

// Scroll to section when clicking on table of contents links
const scrollToSection = (event, sectionId) => {
  event.preventDefault();
  const element = document.getElementById(sectionId);
  if (element) {
    window.scrollTo({
      top: element.offsetTop - 80,
      behavior: 'smooth'
    });
  }
};

// Highlight current section based on scroll position
const highlightCurrentSection = () => {
  const sections = document.querySelectorAll('section[id^="section-"]');
  const scrollPosition = window.scrollY;
  
  sections.forEach(section => {
    const sectionTop = section.offsetTop - 100;
    const sectionHeight = section.offsetHeight;
    
    if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
      const id = section.getAttribute('id');
      const link = document.querySelector(`a[href="#${id}"]`);
      
      if (link) {
        document.querySelectorAll('a[href^="#section-"]').forEach(a => {
          a.classList.remove('font-medium', 'bg-green-50', 'dark:bg-green-900/30', 'px-2', 'py-1', 'rounded');
        });
        
        link.classList.add('font-medium', 'bg-green-50', 'dark:bg-green-900/30', 'px-2', 'py-1', 'rounded');
      }
    }
  });
};

// Add smooth fade-in animation on page load
onMounted(() => {
  setTimeout(() => {
    pageLoaded.value = true;
    
    // Apply animation delays to sections
    document.querySelectorAll('section[id^="section-"]').forEach(section => {
      const sectionNumber = parseInt(section.id.split('-')[1]);
      section.style.animationDelay = `${sectionNumber * 0.1}s`;
    });
  }, 100);
  
  // Add scroll event listener for section highlighting
  window.addEventListener('scroll', highlightCurrentSection);
  
  // Initial highlighting
  highlightCurrentSection();
  
  // Fix table of contents links
  document.querySelectorAll('a[href^="#section-"]').forEach(link => {
    link.addEventListener('click', (e) => {
      scrollToSection(e, link.getAttribute('href').substring(1));
    });
  });
  
  // Clean up event listener
  return () => {
    window.removeEventListener('scroll', highlightCurrentSection);
  };
});
</script>
