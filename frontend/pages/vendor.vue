<template>
  <div class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50 overflow-hidden">
    <!-- Banner Section with Enhanced Parallax -->
    <div class="relative w-full h-[60vh]">
      <div
        ref="bannerRef"
        class="absolute inset-0 w-full h-full transition-transform duration-500 will-change-transform"
      >
        <!-- Dynamic Background with Overlay -->
        <div
          class="absolute inset-0 bg-cover bg-center transition-transform duration-700 scale-105"
          :style="{
            backgroundImage: bannerImage
              ? `url(${bannerImage})`
              : 'url(\'/images/placeholder.jpg?height=800&width=1600\')',
          }"
        ></div>
        
        <!-- Premium Gradient Overlay -->
        <div class="absolute inset-0 bg-gradient-to-r from-slate-900/90 via-slate-800/70 to-slate-900/80 mix-blend-multiply"></div>
        <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-black/40"></div>

        <!-- Animated Particles with Depth Effect -->
        <div class="absolute inset-0">
          <div 
            v-for="(_, i) in 30" 
            :key="i"
            class="absolute rounded-full bg-white/80 blur-[0.5px] backdrop-blur-sm"
            :style="{
              width: `${Math.random() * 5 + 1}px`,
              height: `${Math.random() * 5 + 1}px`,
              top: `${Math.random() * 100}%`,
              left: `${Math.random() * 100}%`,
              opacity: Math.random() * 0.6 + 0.2,
              animation: `floatParticle ${Math.random() * 10 + 15}s ease-in-out infinite`,
              animationDelay: `${Math.random() * 5}s`,
              transform: `translateZ(${Math.random() * 50}px)`,
            }"
          ></div>
        </div>

        <!-- Banner Upload Button with Animation -->
        <div class="absolute top-4 right-4 z-20">
          <button
            class="rounded-full overflow-hidden group bg-white/10 backdrop-blur-md border border-white/20 text-white hover:bg-white/20 hover:border-white/30 px-4 py-2 text-sm font-medium inline-flex items-center transition-all duration-300 shadow-sm hover:shadow-sm transform hover:scale-105"
            @click="showBannerUpload = true"
          >
            <span class="relative z-10 flex items-center">
              <Camera class="w-4 h-4 mr-2 group-hover:scale-110 transition-transform duration-300" />
              <span class="relative after:absolute after:bottom-0 after:left-0 after:w-full after:h-px after:bg-white/40 after:transform after:scale-x-0 after:origin-left group-hover:after:scale-x-100 after:transition-transform after:duration-300">
                {{ bannerImage ? "Change Banner" : "Upload Banner" }}
              </span>
            </span>
          </button>
        </div>
      </div>

      <!-- Banner Upload Modal with Enhanced Design -->
      <Teleport to="body">
        <div
          v-if="showBannerUpload"
          class="fixed inset-0 bg-slate-900/80 backdrop-blur-sm z-50 flex items-center justify-center p-4 transition-opacity duration-300"
          @click.self="showBannerUpload = false"
        >
          <div 
            class="sm:max-w-[500px] bg-white/95 backdrop-blur-xl rounded-xl shadow-sm w-full transform transition-all duration-500 border border-white/50"
            :class="showBannerUpload ? 'scale-100 opacity-100' : 'scale-95 opacity-0'"
          >
            <div class="p-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600">Upload Banner</h3>
                <button
                  class="rounded-full h-9 w-9 p-0 flex items-center justify-center hover:bg-slate-100 transition-colors duration-200 group"
                  @click="showBannerUpload = false"
                >
                  <X class="h-4 w-4 group-hover:rotate-90 transition-transform duration-300" />
                </button>
              </div>
              <p class="text-slate-500 text-sm mb-6">
                Upload a new banner image for your profile.
              </p>

              <label
                class="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed border-slate-300 rounded-xl cursor-pointer bg-slate-50/70 hover:bg-slate-100/80 transition-all duration-300 group relative overflow-hidden"
              >
                <div class="absolute inset-0 bg-gradient-to-br from-slate-100/50 via-white/20 to-slate-50/50 opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                <div class="flex flex-col items-center justify-center pt-5 pb-6 relative z-10">
                  <Camera class="w-12 h-12 mb-4 text-slate-400 group-hover:text-slate-500 transition-colors duration-300 group-hover:scale-110 transform transition-transform" />
                  <p class="mb-2 text-sm text-slate-500 group-hover:text-slate-600 transition-colors duration-300">
                    <span class="font-semibold">Click to upload</span> or drag and drop
                  </p>
                  <p class="text-xs text-slate-400 group-hover:text-slate-500 transition-colors duration-300">
                    PNG, JPG or WEBP (Recommended: 1600×800)
                  </p>
                </div>
                <input
                  type="file"
                  class="hidden"
                  accept="image/*"
                  @change="handleBannerUpload"
                />
              </label>

              <div class="flex justify-end mt-6">
                <button
                  class="px-5 py-2.5 border border-slate-200 rounded-lg text-sm font-medium hover:bg-slate-50 transition-colors duration-200 shadow-sm hover:shadow"
                  @click="showBannerUpload = false"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      </Teleport>

      <!-- Enhanced Vendor Info Card -->
      <div class="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/3 md:translate-y-1/4 w-[92%] max-w-4xl z-10">
        <div class="relative transform transition-all duration-500 hover:translate-y-[-5px] group">
          <!-- Card Backdrop with Glass Effect -->
          <div class="absolute inset-0 bg-white/60 backdrop-blur-xl rounded-xl shadow-[0_10px_60px_-15px_rgba(0,0,0,0.2)] border border-white/50 overflow-hidden"></div>
          
          <!-- Card Light Effect -->
          <div class="absolute inset-0 rounded-xl overflow-hidden">
            <div class="absolute inset-0 bg-gradient-to-tr from-slate-50/80 via-white/90 to-slate-50/80 opacity-80 group-hover:opacity-100 transition-opacity duration-500 rounded-xl"></div>
            <div class="absolute inset-0 bg-grid-slate-200/50 [mask-image:linear-gradient(to_bottom,white,transparent)] opacity-50 group-hover:opacity-70 transition-all duration-500 animate-grid-shift"></div>
          </div>
          
          <!-- Card Content -->
          <div class="p-5 md:p-7 flex flex-col md:flex-row gap-5 items-center relative">
            <!-- Logo with 3D Hover Effect -->
            <div class="relative h-24 w-24 md:h-32 md:w-32 rounded-xl overflow-hidden shadow-sm transform transition-all duration-500 hover:scale-105 hover:rotate-3 hover:-translate-y-1 group/logo">
              <!-- Logo Background -->
              <div class="absolute inset-0 bg-gradient-to-br from-slate-700 to-slate-900 group-hover/logo:from-slate-600 group-hover/logo:to-slate-800 transition-colors duration-500"></div>
              
              <!-- Logo Text Fallback -->
              <div class="absolute inset-0 flex items-center justify-center text-white font-semibold text-xl">
                <span v-if="!logoImage" class="text-2xl tracking-tight">TP</span>
              </div>
              
              <!-- Logo Image -->
              <div
                class="absolute inset-0 bg-cover bg-center opacity-85 group-hover/logo:opacity-100 transition-all duration-500 transform group-hover/logo:scale-110"
                :style="{
                  backgroundImage: logoImage
                    ? `url(${logoImage})`
                    : 'url(\'/images/placeholder.jpg?height=200&width=200\')',
                }"
              ></div>

              <!-- Logo Overlay with Shine Effect -->
              <div class="absolute inset-0 bg-gradient-to-tr from-white/10 to-transparent opacity-0 group-hover/logo:opacity-100 transition-opacity duration-500"></div>
              
              <!-- Logo Upload Button -->
              <div
                class="absolute inset-0 flex items-center justify-center opacity-0 group-hover/logo:opacity-100 transition-all duration-300 bg-black/60 backdrop-blur-sm cursor-pointer"
                @click="showLogoUpload = true"
              >
                <div class="flex flex-col items-center justify-center text-white text-xs transform transition-transform duration-300 group-hover/logo:scale-110">
                  <ImageIcon class="w-7 h-7 mb-1.5 animate-pulse" />
                  <span class="font-medium">{{ logoImage ? "Change Logo" : "Upload Logo" }}</span>
                </div>
              </div>
            </div>
            
            <!-- Vendor Info with Animated Underline -->
            <div class="flex-1 text-center md:text-left">
              <h1 class="text-2xl md:text-2xl font-semibold bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-700 tracking-tight relative inline-block">
                TechVendor Pro
                <span class="absolute -bottom-1 left-0 w-full h-[2px] bg-gradient-to-r from-slate-400 to-transparent transform origin-left scale-x-0 group-hover:scale-x-100 transition-transform duration-500"></span>
              </h1>
              
              <p class="text-slate-600 mt-1.5 font-medium">
                Premium technology solutions since 2010
              </p>
              
              <!-- Vendor Tags with Hover Effects -->
              <div class="flex flex-wrap gap-2 mt-5 justify-center md:justify-start">
                <span class="px-3.5 py-1.5 bg-white shadow-sm hover:shadow-sm transition-all duration-300 rounded-full text-sm flex items-center transform hover:translate-y-[-2px] border border-slate-100">
                  <MapPin class="w-3.5 h-3.5 mr-1.5 text-slate-500" /> New York, USA
                </span>
                
                <span class="px-3.5 py-1.5 bg-white shadow-sm hover:shadow-sm transition-all duration-300 rounded-full text-sm flex items-center transform hover:translate-y-[-2px] border border-slate-100">
                  <Clock class="w-3.5 h-3.5 mr-1.5 text-slate-500" /> Mon-Fri, 9am-5pm
                </span>
                
                <span
                  class="px-3.5 py-1.5 cursor-pointer bg-white shadow-sm hover:shadow-sm transition-all duration-300 rounded-full text-sm flex items-center transform hover:translate-y-[-2px] border border-slate-100"
                  @click="reviewsOpen = true"
                >
                  <span class="flex mr-1.5">
                    <svg
                      v-for="star in 5"
                      :key="star"
                      class="w-3.5 h-3.5 text-yellow-400"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
                      />
                    </svg>
                  </span>
                  <span>4.8 <span class="opacity-70">(256)</span></span>
                </span>
              </div>
            </div>
            
            <!-- Action Buttons with Advanced Hover Effects -->
            <div class="flex gap-3">
              <button class="relative overflow-hidden rounded-full bg-gradient-to-r from-slate-800 to-slate-700 shadow-sm hover:shadow-sm hover:scale-105 transform text-white px-5 py-2.5 font-medium group/btn transition-all duration-300">
                <span class="relative z-10">Contact</span>
                <span class="absolute inset-0 bg-gradient-to-r from-slate-700 to-slate-600 translate-y-full group-hover/btn:translate-y-0 transition-transform duration-300"></span>
              </button>
              
              <button class="relative overflow-hidden rounded-full border-2 border-slate-300 hover:border-slate-400 transition-all duration-300 hover:scale-105 transform px-5 py-2.5 font-medium group/btn">
                <span class="relative z-10 bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600">Follow</span>
                <span class="absolute inset-0 bg-slate-100 opacity-0 group-hover/btn:opacity-100 transition-opacity duration-300"></span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content with Enhanced Sections -->
    <UContainer class="px-4 xl:px-0">
      <div class="pt-48 md:pt-28 lg:pt-40 pb-20">
        <!-- Enhanced Search Section -->
        <div class="mb-20 mt-8 md:mt-16">
          <div 
            class="relative max-w-2xl mx-auto transition-all duration-500 ease-out transform"
            :class="searchFocused ? 'scale-105' : 'scale-100'"
          >
            <!-- Animated Background Glow with Pulse Effect -->
            <div
              class="absolute inset-0 bg-gradient-to-r from-slate-300/60 via-white/80 to-slate-300/60 rounded-full blur-xl transition-all duration-300"
              :class="searchFocused ? 'opacity-100 scale-105 animate-pulse-slow' : 'opacity-70 scale-100'"
            ></div>

            <!-- Enhanced Search Container -->
            <div class="relative z-10">
              <div class="relative overflow-hidden rounded-full shadow-sm">
                <!-- Glass Backdrop -->
                <div
                  class="absolute inset-0 bg-white/90 backdrop-blur-md transition-all duration-300"
                  :class="searchFocused ? 'opacity-100' : 'opacity-90'"
                ></div>
                
                <!-- Glass Highlight -->
                <div 
                  class="absolute top-0 left-0 right-0 h-1/2 bg-gradient-to-b from-white/80 to-transparent transition-opacity duration-300"
                  :class="searchFocused ? 'opacity-80' : 'opacity-50'"
                ></div>

                <!-- Search Input with Animations -->
                <div class="relative flex items-center p-1.5">
                  <div 
                    class="p-2.5 transition-all duration-300"
                    :class="searchFocused ? 'text-slate-800 scale-110' : 'text-slate-400 scale-100'"
                  >
                    <Search class="h-5 w-5" />
                  </div>
                  
                  <input
                    type="text"
                    placeholder="Search premium products..."
                    class="border-0 bg-transparent text-base w-16 sm:w-auto py-2.5 md:py-3 px-2 flex-1 placeholder:text-slate-400 focus:outline-none"
                    @focus="searchFocused = true"
                    @blur="searchFocused = false"
                    v-model="searchValue"
                  />
                  
                  <button
                    v-if="searchValue"
                    class="mr-2 h-8 w-8 rounded-full p-0 flex items-center justify-center hover:bg-slate-100 transition-all duration-200 group"
                    @click="searchValue = ''"
                  >
                    <X class="h-4 w-4 group-hover:rotate-90 transition-transform duration-300" />
                  </button>
                  
                  <button
                    class="relative overflow-hidden rounded-full mr-1 transition-all duration-300 text-white px-4 py-2.5 md:px-5 md:py-2.5 group/search"
                    :class="searchFocused ? 'bg-slate-800 hover:bg-slate-700' : 'bg-slate-700 hover:bg-slate-600'"
                  >
                    <span class="relative z-10">Search</span>
                    <span 
                      class="absolute inset-0 bg-gradient-to-r from-slate-600 to-slate-700 opacity-0 group-hover/search:opacity-100 transition-opacity duration-300"
                    ></span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Categories Section with Enhanced Animation -->
          <div
            ref="categoriesRef"
            class="flex flex-col items-center mt-16 transition-all duration-700 transform"
            :class="visibleSections.categories ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'"
          >
            <h2 class="text-xl font-semibold mb-8 text-center relative">
              <span class="relative inline-block">
                Browse Categories
                <span class="absolute -bottom-2 left-0 right-0 h-1.5 bg-gradient-to-r from-slate-400 to-transparent rounded-full transform scale-x-50 group-hover:scale-x-100 transition-transform duration-500"></span>
              </span>
            </h2>
            
            <!-- Enhanced Categories Grid -->
            <div class="flex flex-wrap justify-center gap-3 max-w-3xl">
              <span
                v-for="(category, index) in categories"
                :key="index"
                class="px-4 py-3 text-sm cursor-pointer bg-white hover:bg-slate-50 shadow-sm hover:shadow-sm transition-all duration-300 border border-slate-100 rounded-xl group/cat relative overflow-hidden"
                :style="{
                  animationDelay: `${index * 80}ms`,
                  animation: 'fadeInUp 0.5s ease-out forwards',
                  opacity: 0,
                  transform: 'translateY(20px)',
                }"
              >
                <!-- Category Highlight Effect -->
                <span class="absolute inset-0 bg-gradient-to-tr from-slate-100/80 to-white/0 opacity-0 group-hover/cat:opacity-100 transition-opacity duration-300"></span>
                
                <!-- Category Content -->
                <span class="relative z-10 font-medium">{{ category.name }}</span>
                <span class="ml-2 px-2.5 py-0.5 text-xs bg-slate-100 group-hover/cat:bg-slate-200 rounded-full transition-colors duration-300 text-slate-600 group-hover/cat:text-slate-700 relative z-10">
                  {{ category.count }}
                </span>
                
                <!-- Animated Border on Hover -->
                <span class="absolute bottom-0 left-0 w-0 h-0.5 bg-slate-300 group-hover/cat:w-full transition-all duration-300 ease-out"></span>
              </span>
            </div>
          </div>
        </div>

        <!-- Product section placeholder - with enhanced design -->
        <div class="flex justify-center my-20">
          <div class="text-center max-w-lg relative group">
            <div class="absolute inset-0 bg-gradient-to-b from-white/0 via-white/80 to-white/0 blur-lg opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-3xl"></div>
            <h2 class="text-xl font-semibold mb-3 bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600 relative inline-block">
              Your Products
              <span class="absolute -bottom-1 left-0 w-full h-0.5 bg-gradient-to-r from-slate-400 to-transparent transform origin-left scale-x-0 group-hover:scale-x-100 transition-transform duration-500"></span>
            </h2>
            <p class="text-slate-500 mb-6">
              Your product components will be displayed here
            </p>
          </div>
        </div>

        <!-- Vendor Details with Enhanced Animation -->
        <div
          ref="detailsRef"
          class="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8 my-20 max-w-5xl mx-auto transition-all duration-700 transform"
          :class="visibleSections.details ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'"
        >
          <div
            v-for="(item, index) in vendorDetails"
            :key="index"
            class="group relative transform transition-all duration-500 hover:translate-y-[-5px]"
            :style="{
              animationDelay: `${index * 150}ms`,
              animation: 'fadeInUp 0.5s ease-out forwards',
              opacity: 0,
              transform: 'translateY(20px)',
            }"
          >
            <!-- Card Background with Glass Effect -->
            <div class="absolute inset-0 bg-white/60 backdrop-blur-sm rounded-xl shadow-sm group-hover:shadow-sm transition-all duration-300 border border-white/50 overflow-hidden"></div>
            
            <!-- Card Background Pattern -->
            <div class="absolute inset-0 bg-gradient-to-br from-slate-50/80 via-white/90 to-slate-50/80 opacity-80 group-hover:opacity-100 transition-opacity duration-500 rounded-xl"></div>
            <div class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(to_bottom,white,transparent)] opacity-50 group-hover:opacity-70 transition-all duration-500"></div>
            
            <!-- Card Content -->
            <div class="p-7 relative">
              <div class="flex flex-col items-center text-center">
                <div class="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center mb-4 group-hover:bg-slate-800 group-hover:text-white transition-all duration-500 transform group-hover:scale-110 shadow-sm group-hover:shadow-sm relative overflow-hidden">
                  <!-- Icon Glow Effect -->
                  <div class="absolute inset-0 bg-gradient-to-br from-slate-200/0 to-slate-100/80 opacity-0 group-hover:opacity-30 transition-opacity duration-500 group-hover:animate-spin-slow"></div>
                  <component :is="item.icon" class="w-6 h-6 relative z-10 transform transition-transform duration-500 group-hover:scale-110" />
                </div>
                
                <h3 class="font-semibold text-lg mb-2 bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600">
                  {{ item.title }}
                </h3>
                
                <p class="text-slate-600 whitespace-pre-line leading-relaxed">
                  {{ item.content }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Enhanced Call to Action -->
        <div
          ref="ctaRef"
          class="relative mt-24 mb-10 max-w-5xl mx-auto overflow-hidden rounded-xl transition-all duration-700 transform"
          :class="visibleSections.cta ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'"
        >
          <!-- CTA Background -->
          <div class="absolute inset-0 bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900"></div>
          
          <!-- CTA Background Pattern -->
          <div 
            class="absolute inset-0 opacity-20"
            style="background-image: radial-gradient(circle at 30% 50%, rgba(255,255,255,0.1) 0%, transparent 45%), 
                   radial-gradient(circle at 70% 20%, rgba(255,255,255,0.08) 0%, transparent 35%);"
          ></div>

          <!-- Parallax Particles -->
          <div class="absolute inset-0 opacity-40">
            <div
              v-for="(_, i) in 25"
              :key="i"
              class="absolute rounded-full bg-white/90 blur-[0.5px]"
              :style="{
                width: `${Math.random() * 4 + 1}px`,
                height: `${Math.random() * 4 + 1}px`,
                top: `${Math.random() * 100}%`,
                left: `${Math.random() * 100}%`,
                opacity: Math.random() * 0.5 + 0.3,
                animation: `floatParticle ${Math.random() * 8 + 10}s ease-in-out infinite`,
                animationDelay: `${Math.random() * 5}s`,
                transform: `translateZ(${Math.random() * 30}px)`,
              }"
            ></div>
          </div>

          <!-- CTA Content -->
          <div class="relative p-10 md:p-14 flex flex-col md:flex-row items-center justify-between gap-8">
            <div class="text-center md:text-left transform transition-all duration-500 md:hover:translate-x-2">
              <h2 class="text-xl md:text-2xl font-semibold text-white mb-3 tracking-tight">
                Ready to explore our products?
              </h2>
              <p class="text-slate-300">
                Join thousands of satisfied customers today.
              </p>
            </div>
            
            <!-- Enhanced CTA Button -->
            <button class="relative overflow-hidden rounded-full bg-white text-slate-900 hover:text-slate-800 px-6 py-3 h-auto text-base lg:text-lg font-medium shadow-sm hover:shadow-sm transition-all duration-500 hover:scale-105 transform group/cta w-full md:w-auto">
              <span class="relative z-10 flex items-center justify-center">
                Browse All Products
                <ChevronRight class="ml-2 h-5 w-5 inline-block group-hover/cta:translate-x-1.5 transition-transform duration-300" />
              </span>
              
              <!-- Button Highlight Effect -->
              <span class="absolute inset-0 bg-gradient-to-r from-white/0 via-white/90 to-white/0 opacity-0 group-hover/cta:opacity-100 transition-opacity duration-500 transform -translate-x-full group-hover/cta:translate-x-full"></span>
            </button>
          </div>
        </div>
      </div>
    </UContainer>

    <!-- Enhanced Reviews Modal -->
    <Teleport to="body">
      <div
        v-if="reviewsOpen"
        class="fixed inset-0 bg-slate-900/70 backdrop-blur-sm z-50 flex items-center justify-center p-4 transition-opacity duration-300"
        @click.self="reviewsOpen = false"
      >
        <!-- Modal Container with Glass Effect -->
        <div
          class="sm:max-w-[600px] max-h-[80vh] overflow-y-auto bg-white/90 backdrop-blur-xl border border-white/50 shadow-sm rounded-xl w-full relative transform transition-all duration-500"
          :class="reviewsOpen ? 'scale-100 opacity-100' : 'scale-95 opacity-0'"
        >
          <!-- Modal Background -->
          <div class="absolute inset-0 bg-gradient-to-br from-slate-50/90 to-white/90 opacity-90 rounded-xl"></div>
          <div class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(to_bottom,white,transparent)] rounded-xl"></div>

          <!-- Modal Content -->
          <div class="relative z-10 p-7">
            <div class="flex items-center justify-between text-xl mb-3">
              <h3 class="font-semibold bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600">
                {{ selectedProduct ? "Product Reviews" : "All Vendor Reviews" }}
              </h3>
              <button
                class="rounded-full h-9 w-9 p-0 flex items-center justify-center bg-slate-100 hover:bg-slate-200 transition-colors duration-200 group"
                @click="reviewsOpen = false"
              >
                <X class="h-4 w-4 group-hover:rotate-90 transition-transform duration-300" />
              </button>
            </div>
            <p class="text-slate-500 text-sm mb-7">
              See what our customers are saying about our products
            </p>

            <!-- Enhanced Reviews List -->
            <div class="space-y-7 mt-4">
              <div
                v-for="(review, index) in reviews"
                :key="review.id"
                class="space-y-4 animate-fade-in transform transition-all duration-500 hover:translate-y-[-3px]"
                :style="{ animationDelay: `${index * 100}ms` }"
              >
                <div class="flex items-start gap-4">
                  <!-- Avatar with Enhanced Styling -->
                  <div class="h-12 w-12 rounded-full bg-gradient-to-br from-slate-700 to-slate-900 text-white flex items-center justify-center border-2 border-white shadow-sm text-sm font-medium">
                    {{ review.avatar }}
                  </div>
                  
                  <div class="flex-1">
                    <div class="flex items-center justify-between">
                      <h4 class="font-medium text-slate-800">{{ review.user }}</h4>
                      <span class="text-sm text-slate-500">{{ review.date }}</span>
                    </div>
                    
                    <!-- Enhanced Star Rating -->
                    <div class="flex mt-1.5">
                      <svg
                        v-for="star in 5"
                        :key="star"
                        :class="`w-4 h-4 ${
                          star <= review.rating
                            ? 'text-yellow-400'
                            : 'text-gray-300'
                        }`"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path
                          d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
                        />
                      </svg>
                    </div>
                    
                    <!-- Review Text with Line Height Adjustment -->
                    <p class="mt-3 text-slate-700 leading-relaxed">{{ review.comment }}</p>
                  </div>
                </div>
                <hr class="border-slate-200/70" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Enhanced Logo Upload Modal -->
    <Teleport to="body">
      <div
        v-if="showLogoUpload"
        class="fixed inset-0 bg-slate-900/80 backdrop-blur-sm z-50 flex items-center justify-center p-4 transition-opacity duration-300"
        @click.self="showLogoUpload = false"
      >
        <div 
          class="sm:max-w-[425px] bg-white/95 backdrop-blur-xl rounded-xl shadow-sm w-full transform transition-all duration-500 border border-white/50"
          :class="showLogoUpload ? 'scale-100 opacity-100' : 'scale-95 opacity-0'"
        >
          <div class="p-7">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600">Upload Logo</h3>
              <button
                class="rounded-full h-9 w-9 p-0 flex items-center justify-center hover:bg-slate-100 transition-colors duration-200 group"
                @click="showLogoUpload = false"
              >
                <X class="h-4 w-4 group-hover:rotate-90 transition-transform duration-300" />
              </button>
            </div>
            <p class="text-slate-500 text-sm mb-6">
              Upload a new logo for your vendor profile.
            </p>

            <!-- Enhanced Upload Area -->
            <label
              class="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed border-slate-300 rounded-xl cursor-pointer bg-slate-50/70 hover:bg-slate-100/80 transition-all duration-300 group relative overflow-hidden"
            >
              <div class="absolute inset-0 bg-gradient-to-br from-slate-100/50 via-white/20 to-slate-50/50 opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
              <div class="flex flex-col items-center justify-center pt-5 pb-6 relative z-10">
                <ImageIcon class="w-12 h-12 mb-4 text-slate-400 group-hover:text-slate-500 transition-colors duration-300 group-hover:scale-110 transform transition-transform" />
                <p class="mb-2 text-sm text-slate-500 group-hover:text-slate-600 transition-colors duration-300">
                  <span class="font-semibold">Click to upload</span> or drag and drop
                </p>
                <p class="text-xs text-slate-400 group-hover:text-slate-500 transition-colors duration-300">
                  PNG, JPG or WEBP (Recommended: Square image)
                </p>
              </div>
              <input
                type="file"
                class="hidden"
                accept="image/*"
                @change="handleLogoUpload"
              />
            </label>

            <div class="flex justify-end mt-6">
              <button
                class="px-5 py-2.5 border border-slate-200 rounded-lg text-sm font-medium hover:bg-slate-50 transition-colors duration-200 shadow-sm hover:shadow"
                @click="showLogoUpload = false"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import {
  Search,
  MapPin,
  Clock,
  Mail,
  ChevronRight,
  X,
  Camera,
  ImageIcon,
} from "lucide-vue-next";

// Sample categories for the vendor with product counts
const categories = [
  { name: "Electronics", count: 42 },
  { name: "Computers", count: 38 },
  { name: "Accessories", count: 56 },
  { name: "Smart Home", count: 27 },
  { name: "Audio", count: 31 },
  { name: "Wearables", count: 19 },
  { name: "Gaming", count: 24 },
];

// Sample reviews
const reviews = [
  {
    id: 1,
    productId: 1,
    user: "Alex Johnson",
    avatar: "AJ",
    rating: 5,
    date: "2023-04-15",
    comment:
      "These headphones have amazing sound quality and the noise cancellation is top-notch. Battery life exceeds expectations.",
  },
  {
    id: 2,
    productId: 1,
    user: "Sarah Miller",
    avatar: "SM",
    rating: 4,
    date: "2023-04-10",
    comment:
      "Great headphones overall, but they're a bit tight on my head after long listening sessions.",
  },
  {
    id: 3,
    productId: 2,
    user: "Michael Brown",
    avatar: "MB",
    rating: 5,
    date: "2023-04-05",
    comment:
      "The picture quality is incredible and the smart features work seamlessly. Highly recommend!",
  },
];

// Vendor details
const vendorDetails = [
  {
    icon: Mail,
    title: "Contact Us",
    content: "support@techvendorpro.com\n(555) 123-4567",
  },
  {
    icon: Clock,
    title: "Business Hours",
    content: "Monday to Friday: 9am - 5pm\nWeekends: 10am - 3pm",
  },
  {
    icon: MapPin,
    title: "Our Location",
    content: "123 Tech Avenue\nNew York, NY 10001",
  },
];

// State variables
const scrolled = ref(false);
const reviewsOpen = ref(false);
const selectedProduct = ref(null);
const searchFocused = ref(false);
const searchValue = ref("");
const visibleSections = reactive({
  categories: false,
  details: false,
  cta: false,
});
const bannerImage = ref(null);
const logoImage = ref(null);
const showBannerUpload = ref(false);
const showLogoUpload = ref(false);

// Refs
const bannerRef = ref(null);
const categoriesRef = ref(null);
const detailsRef = ref(null);
const ctaRef = ref(null);

// Enhanced scroll effects with IntersectionObserver
onMounted(() => {
  // Parallax and scroll effects
  const handleScroll = () => {
    scrolled.value = window.scrollY > 50;

    // Enhanced parallax effect for banner
    if (bannerRef.value) {
      const scrollPosition = window.scrollY;
      const translateY = Math.min(scrollPosition * 0.3, 100); // Limit the movement
      bannerRef.value.style.transform = `translateY(${translateY}px)`;
    }
  };

  // Use Intersection Observer for sections
  const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.2
  };

  const sectionObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.target === categoriesRef.value) {
        visibleSections.categories = entry.isIntersecting;
      } else if (entry.target === detailsRef.value) {
        visibleSections.details = entry.isIntersecting;
      } else if (entry.target === ctaRef.value) {
        visibleSections.cta = entry.isIntersecting;
      }
    });
  }, observerOptions);

  // Observe sections
  if (categoriesRef.value) sectionObserver.observe(categoriesRef.value);
  if (detailsRef.value) sectionObserver.observe(detailsRef.value);
  if (ctaRef.value) sectionObserver.observe(ctaRef.value);

  window.addEventListener("scroll", handleScroll);
  // Trigger once to initialize
  handleScroll();

  // Cleanup
  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
    sectionObserver.disconnect();
  });
});

// Open reviews modal for a specific product
const openProductReviews = (productId) => {
  selectedProduct.value = productId;
  reviewsOpen.value = true;
};

// Handle file uploads
const handleBannerUpload = (e) => {
  const file = e.target.files?.[0];
  if (file) {
    const reader = new FileReader();
    reader.onloadend = () => {
      if (typeof reader.result === "string") {
        bannerImage.value = reader.result;
        showBannerUpload.value = false;
      }
    };
    reader.readAsDataURL(file);
  }
};

const handleLogoUpload = (e) => {
  const file = e.target.files?.[0];
  if (file) {
    const reader = new FileReader();
    reader.onloadend = () => {
      if (typeof reader.result === "string") {
        logoImage.value = reader.result;
        showLogoUpload.value = false;
      }
    };
    reader.readAsDataURL(file);
  }
};
</script>

<style>
/* Enhanced animations and effects */
@keyframes floatParticle {
  0%, 100% {
    transform: translateY(0) translateX(0);
  }
  25% {
    transform: translateY(-15px) translateX(5px);
  }
  50% {
    transform: translateY(-5px) translateX(15px);
  }
  75% {
    transform: translateY(-10px) translateX(-5px);
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes animate-grid {
  0% {
    background-position: 0 0;
  }
  100% {
    background-position: 100% 100%;
  }
}

@keyframes pulse-slow {
  0%, 100% {
    opacity: 0.7;
  }
  50% {
    opacity: 1;
  }
}

@keyframes spin-slow {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.animate-fade-in-up {
  animation: fadeInUp 0.5s ease-out forwards;
}

.animate-fade-in {
  animation: fadeIn 0.4s ease-out forwards;
}

.animate-pulse-slow {
  animation: pulse-slow 3s ease-in-out infinite;
}

.animate-grid-shift {
  animation: animate-grid 20s linear infinite;
}

.animate-spin-slow {
  animation: spin-slow 8s linear infinite;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

/* Enhanced grid patterns for premium look */
.bg-grid-slate-100 {
  background-image: 
    linear-gradient(to right, rgba(241, 245, 249, 0.5) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(241, 245, 249, 0.5) 1px, transparent 1px);
  background-size: 20px 20px;
}

.bg-grid-slate-200 {
  background-image: 
    linear-gradient(to right, rgba(226, 232, 240, 0.5) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(226, 232, 240, 0.5) 1px, transparent 1px);
  background-size: 20px 20px;
}

/* Responsive Adjustments */
@media (max-width: 768px) {
  .animate-grid-shift {
    animation: none; /* Disable on mobile for performance */
  }
  
  /* Optimize animations for mobile */
  .floatParticle {
    animation-duration: 15s;
  }
}

/* Optimize for touch devices */
@media (hover: none) {
  .group:hover .group-hover\:scale-110,
  .group:hover .group-hover\:translate-y-\[-5px\] {
    transform: none !important; /* Remove hover effects that may cause jank on touch */
  }
}

/* Make modals fully responsive */
@media (max-width: 640px) {
  .sm\:max-w-\[600px\],
  .sm\:max-w-\[500px\],
  .sm\:max-w-\[425px\] {
    max-width: calc(100% - 32px);
  }
}
</style>