<template>
  <UContainer>
    <div
      class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50 overflow-hidden"
    >
      <!-- Enhanced Banner Section with Parallax Effect -->
      <div class="relative w-full max-sm:mt-6 min-h-[300px] sm:h-[60vh]">
        <div
          ref="bannerRef"
          class="absolute inset-0 w-full h-[60%] transition-transform duration-500 will-change-transform max-sm:hidden"
        >
          <!-- Premium Banner Background with Enhanced Overlay -->
          <div
            class="absolute inset-0 bg-cover bg-center transition-transform duration-700 scale-105"
            :style="{
              backgroundImage: storeDetails?.store_banner
                ? `url(${storeDetails?.store_banner})`
                : 'url(\'/images/placeholder.jpg?height=800&width=1600\')',
              backgroundPosition: 'center 30%',
            }"
          ></div>

          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-900/90 via-slate-800/70 to-slate-900/80 mix-blend-multiply"
          ></div>
          <div
            class="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-black/40"
          ></div>

          <!-- Enhanced Animated Particles with Depth Effect -->
          <div class="absolute inset-0">
            <div
              v-for="(_, i) in 25"
              :key="i"
              class="absolute rounded-full bg-white/80 blur-[0.5px] backdrop-blur-sm"
              :style="{
                width: `${Math.random() * 5 + 1}px`,
                height: `${Math.random() * 5 + 1}px`,
                top: `${Math.random() * 100}%`,
                left: `${Math.random() * 100}%`,
                opacity: Math.random() * 0.6 + 0.2,
                animation: `floatParticle ${
                  Math.random() * 10 + 15
                }s ease-in-out infinite`,
                animationDelay: `${Math.random() * 5}s`,
                transform: `translateZ(${Math.random() * 50}px)`,
              }"
            ></div>
          </div>

          <!-- Enhanced Banner Upload Button with Animation -->
          <div v-if="isOwner" class="absolute top-4 right-4 z-20">
            <button
              class="rounded-full overflow-hidden group bg-white/10 backdrop-blur-md border border-white/20 text-white hover:bg-white/20 hover:border-white/30 px-4 py-2 text-sm font-medium inline-flex items-center transition-all duration-300 shadow-sm hover:shadow-sm transform hover:scale-105"
              @click="showBannerUpload = true"
            >
              <span class="relative z-10 flex items-center">
                <Camera
                  class="w-4 h-4 mr-2 group-hover:scale-110 transition-transform duration-300"
                />
                <span
                  class="relative after:absolute after:bottom-0 after:left-0 after:w-full after:h-px after:bg-white/40 after:transform after:scale-x-0 after:origin-left group-hover:after:scale-x-100 after:transition-transform after:duration-300"
                >
                  {{
                    storeDetails?.store_banner
                      ? "Change Banner"
                      : "Upload Banner"
                  }}
                </span>
              </span>
            </button>
          </div>
        </div>

        <!-- Enhanced Banner Upload Modal -->
        <Teleport to="body">
          <div
            v-if="showBannerUpload"
            class="fixed inset-0 bg-slate-900/80 backdrop-blur-sm z-50 flex items-center justify-center p-4 transition-opacity duration-300"
            @click.self="showBannerUpload = false"
          >
            <div
              class="sm:max-w-[500px] bg-white/95 backdrop-blur-xl rounded-xl shadow-sm w-full transform transition-all duration-500 border border-white/50"
              :class="
                showBannerUpload
                  ? 'scale-100 opacity-100'
                  : 'scale-95 opacity-0'
              "
            >
              <div class="p-6">
                <div class="flex items-center justify-between mb-4">
                  <h3
                    class="text-lg font-semibold bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600"
                  >
                    Upload Banner
                  </h3>
                  <button
                    class="rounded-full h-9 w-9 p-0 flex items-center justify-center hover:bg-slate-100 transition-colors duration-200 group"
                    @click="showBannerUpload = false"
                  >
                    <X
                      class="h-4 w-4 group-hover:rotate-90 transition-transform duration-300"
                    />
                  </button>
                </div>
                <p class="text-slate-500 text-sm mb-6">
                  Upload a new banner image for your profile.
                </p>

                <label
                  class="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed border-slate-300 rounded-xl cursor-pointer bg-slate-50/70 hover:bg-slate-100/80 transition-all duration-300 group relative overflow-hidden"
                >
                  <div
                    class="absolute inset-0 bg-gradient-to-br from-slate-100/50 via-white/20 to-slate-50/50 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
                  ></div>
                  <div
                    class="flex flex-col items-center justify-center pt-5 pb-6 relative z-10"
                  >
                    <Camera
                      class="w-12 h-12 mb-4 text-slate-400 group-hover:text-slate-500 transition-colors duration-300 group-hover:scale-110 transform transition-transform"
                    />
                    <p
                      class="mb-2 text-sm text-slate-500 group-hover:text-slate-600 transition-colors duration-300"
                    >
                      <span class="font-semibold">Click to upload</span> or drag
                      and drop
                    </p>
                    <p
                      class="text-xs text-slate-400 group-hover:text-slate-500 transition-colors duration-300"
                    >
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
        <div
          class="sm:absolute max-sm:top-0 sm:bottom-0 sm:left-1/2 sm:-translate-x-1/2 sm:translate-y-1/2 md:-translate-y-2/3 sm:w-[90%] max-w-4xl z-10 transition-all duration-500"
          :class="isSeeMore ? 'md:translate-y-0' : ''"
        >
          <div
            class="relative transform transition-all duration-500 hover:translate-y-[-5px] group"
          >
            <!-- Card Backdrop with Glass Effect -->
            <div
              class="absolute inset-0 bg-white/60 backdrop-blur-xl rounded-xl shadow-[0_10px_60px_-15px_rgba(0,0,0,0.2)] border border-white/50 overflow-hidden"
            ></div>

            <!-- Card Light Effect -->
            <div class="absolute inset-0 rounded-xl overflow-hidden">
              <div
                class="absolute inset-0 bg-gradient-to-tr from-slate-50/80 via-white/90 to-slate-50/80 opacity-80 group-hover:opacity-100 transition-opacity duration-500 rounded-xl"
              ></div>
              <div
                class="absolute inset-0 bg-grid-slate-200/50 [mask-image:linear-gradient(to_bottom,white,transparent)] opacity-50 group-hover:opacity-70 transition-all duration-500 animate-grid-shift"
              ></div>
            </div>

            <!-- Card Content -->
            <div
              class="p-5 md:p-7 flex flex-col md:flex-row gap-5 items-center relative"
            >
              <!-- Logo with 3D Hover Effect -->
              <div
                class="relative h-24 w-24 md:h-32 md:w-32 rounded-xl overflow-hidden shadow-sm transform transition-all duration-500 hover:scale-105 hover:rotate-3 hover:-translate-y-1 group/logo"
              >
                <!-- Logo Background -->
                <div
                  class="absolute inset-0 bg-gradient-to-br from-slate-700 to-slate-900 group-hover/logo:from-slate-600 group-hover/logo:to-slate-800 transition-colors duration-500"
                ></div>

                <!-- Logo Text Fallback -->
                <div
                  class="absolute inset-0 flex items-center justify-center text-white font-semibold text-xl"
                >
                  <span
                    v-if="!storeDetails?.store_logo"
                    class="text-3xl tracking-tight"
                    >{{
                      getInitials(storeDetails?.store_name || "Store")
                    }}</span
                  >
                </div>

                <!-- Logo Image -->
                <div
                  class="absolute inset-0 bg-cover bg-center opacity-85 group-hover/logo:opacity-100 transition-all duration-500 transform group-hover/logo:scale-110"
                  :style="{
                    backgroundImage: storeDetails?.store_logo
                      ? `url(${storeDetails?.store_logo})`
                      : 'url(\'/images/placeholder.jpg?height=200&width=200\')',
                  }"
                ></div>

                <!-- Logo Overlay with Shine Effect -->
                <div
                  class="absolute inset-0 bg-gradient-to-tr from-white/10 to-transparent opacity-0 group-hover/logo:opacity-100 transition-opacity duration-500"
                ></div>

                <!-- Logo Upload Button with Enhanced Animation -->
                <div
                  v-if="isOwner"
                  class="absolute inset-0 flex items-center justify-center opacity-0 group-hover/logo:opacity-100 transition-all duration-300 bg-black/60 backdrop-blur-sm cursor-pointer"
                  @click="showLogoUpload = true"
                >
                  <div
                    class="flex flex-col items-center justify-center text-white text-xs transform transition-transform duration-300 group-hover/logo:scale-110"
                  >
                    <ImageIcon class="w-7 h-7 mb-1.5 animate-pulse" />
                    <span class="font-medium">{{
                      storeDetails?.store_logo ? "Change Logo" : "Upload Logo"
                    }}</span>
                  </div>
                </div>
              </div>

              <!-- Store Info with Animated Underline -->
              <div class="flex-1 text-center md:text-left">
                <h1
                  class="text-3xl md:text-4xl font-semibold bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-700 tracking-tight relative inline-block"
                >
                  {{ storeDetails?.store_name || "Store Name" }}
                  <span
                    class="absolute -bottom-1 left-0 w-full h-[2px] bg-gradient-to-r from-slate-400 to-transparent transform origin-left scale-x-0 group-hover:scale-x-100 transition-transform duration-500"
                  ></span>
                </h1>

                <p
                  class="text-slate-600 mt-1.5 font-medium"
                  :class="isSeeMore ? '' : 'line-clamp-2'"
                >
                  {{
                    storeDetails?.store_description ||
                    "Store description will appear here"
                  }}
                </p>

                <UButton
                  v-if="storeDetails?.store_description"
                  @click="isSeeMore = !isSeeMore"
                  :label="isSeeMore ? 'See Less' : 'See More'"
                  variant="link"
                  size="sm"
                  color="slate"
                  class="mt-1 font-medium hover:text-slate-700 transition-colors duration-300"
                />

                <!-- Tags with Enhanced Hover Effects -->
                <div
                  class="flex flex-wrap gap-2 mt-5 justify-center md:justify-start"
                >
                  <span
                    v-if="storeDetails?.store_address"
                    class="px-3.5 py-1.5 bg-white shadow-sm hover:shadow-sm transition-all duration-300 rounded-full text-sm flex items-center transform hover:translate-y-[-2px] border border-slate-100"
                  >
                    <MapPin class="w-3.5 h-3.5 mr-1.5 text-slate-500" />
                    {{ storeDetails?.store_address }}
                  </span>

                  <span
                    v-if="storeDetails?.phone"
                    class="px-3.5 py-1.5 bg-white shadow-sm hover:shadow-sm transition-all duration-300 rounded-full text-sm flex items-center transform hover:translate-y-[-2px] border border-slate-100"
                  >
                    <Phone class="w-3.5 h-3.5 mr-1.5 text-slate-500" />
                    {{ storeDetails?.phone }}
                  </span>
                </div>
              </div>

              <!-- Action Button with Advanced Hover Effect -->
              <div class="flex gap-3">
                <button
                  class="relative overflow-hidden rounded-full bg-gradient-to-r from-slate-800 to-slate-700 shadow-sm hover:shadow-sm hover:scale-105 transform text-white px-5 py-2.5 font-medium group/btn transition-all duration-300"
                >
                  <span class="relative z-10">Follow</span>
                  <span
                    class="absolute inset-0 bg-gradient-to-r from-slate-700 to-slate-600 translate-y-full group-hover/btn:translate-y-0 transition-transform duration-300"
                  ></span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content with Enhanced Sections -->
      <div
        class="container mx-auto sm:pt-48 md:pt-0 transition-all duration-500"
        :class="isSeeMore ? 'mt-12 sm:mt-24 md:mt-3' : 'mt-8 md:-mt-14'"
      >
        <!-- Enhanced Search Section -->
        <div class="mb-1 mt-1 md:mt-1">
          <div
            class="relative max-w-2xl mx-auto transition-all duration-500 ease-out transform"
            :class="searchFocused ? 'scale-105' : 'scale-100'"
          >
            <!-- Animated Background Glow with Pulse Effect -->
            <div
              class="absolute inset-0 bg-gradient-to-r from-slate-300/60 via-white/80 to-slate-300/60 rounded-full blur-xl transition-all duration-300"
              :class="
                searchFocused
                  ? 'opacity-100 scale-105 animate-pulse-slow'
                  : 'opacity-70 scale-100'
              "
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
                    :class="
                      searchFocused
                        ? 'text-slate-800 scale-110'
                        : 'text-slate-400 scale-100'
                    "
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
                    @keyup.enter="handleSearch"
                  />

                  <button
                    v-if="searchValue"
                    class="mr-2 h-8 w-8 rounded-full p-0 flex items-center justify-center hover:bg-slate-100 transition-all duration-200 group"
                    @click="searchValue = ''"
                  >
                    <X
                      class="h-4 w-4 group-hover:rotate-90 transition-transform duration-300"
                    />
                  </button>

                  <button
                    class="relative overflow-hidden rounded-full mr-1 transition-all duration-300 text-white px-4 py-2.5 md:px-5 md:py-2.5 group/search"
                    :class="
                      searchFocused
                        ? 'bg-slate-800 hover:bg-slate-700'
                        : 'bg-slate-700 hover:bg-slate-600'
                    "
                    @click="handleSearch"
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
            class="flex flex-col items-center mt-10 transition-all duration-700 transform"
            :class="
              visibleSections.categories
                ? 'opacity-100 translate-y-0'
                : 'opacity-0 translate-y-10'
            "
          >
            

            <!-- Enhanced Categories Grid -->
            <div class="flex flex-wrap justify-center gap-3 max-w-3xl">
              <span
                class="px-4 py-3 text-sm cursor-pointer transition-all duration-300 border border-slate-100 rounded-xl group/cat relative overflow-hidden"
                :class="
                  selectedCategory === null
                    ? 'bg-slate-800 text-white hover:bg-slate-700'
                    : 'bg-white hover:bg-slate-50 shadow-sm hover:shadow-sm text-slate-700'
                "
                @click="selectedCategory = null"
                style="animation: fadeInUp 0.5s ease-out forwards"
              >
                <!-- Category Highlight Effect -->
                <span
                  class="absolute inset-0 bg-gradient-to-tr from-slate-100/80 to-white/0 opacity-0 group-hover/cat:opacity-100 transition-opacity duration-300"
                ></span>

                <!-- Category Content -->
                <span class="relative z-10 font-medium">All Products</span>
                <span
                  class="ml-2 px-2.5 py-0.5 text-xs bg-slate-700 group-hover/cat:bg-slate-600 rounded-full transition-colors duration-300 text-white relative z-10"
                >
                  {{ products.length }}
                </span>

                <!-- Animated Border on Hover -->
                <span
                  class="absolute bottom-0 left-0 w-0 h-0.5 bg-slate-300 group-hover/cat:w-full transition-all duration-300 ease-out"
                ></span>
              </span>

              <span
                v-for="(category, index) in uniqueCategories"
                :key="category.id"
                class="px-4 py-3 text-sm cursor-pointer transition-all duration-300 border border-slate-100 rounded-xl group/cat relative overflow-hidden"
                :class="
                  selectedCategory === category.id
                    ? 'bg-slate-800 text-white hover:bg-slate-700'
                    : 'bg-white hover:bg-slate-50 shadow-sm hover:shadow-sm text-slate-700'
                "
                @click="selectedCategory = category.id"
                :style="{
                  animationDelay: `${index * 80}ms`,
                  animation: 'fadeInUp 0.5s ease-out forwards',
                  opacity: 0,
                  transform: 'translateY(20px)',
                }"
              >
                <!-- Category Highlight Effect -->
                <span
                  class="absolute inset-0 bg-gradient-to-tr from-slate-100/80 to-white/0 opacity-0 group-hover/cat:opacity-100 transition-opacity duration-300"
                ></span>

                <!-- Category Content -->
                <span class="relative z-10 font-medium">{{
                  category.name
                }}</span>
                <span
                  class="ml-2 px-2.5 py-0.5 text-xs rounded-full transition-colors duration-300 relative z-10"
                  :class="
                    selectedCategory === category.id
                      ? 'bg-slate-700 text-white group-hover/cat:bg-slate-600'
                      : 'bg-slate-100 text-slate-600 group-hover/cat:bg-slate-200 group-hover/cat:text-slate-700'
                  "
                >
                  {{ getProductCountByCategory(category.id) }}
                </span>

                <!-- Animated Border on Hover -->
                <span
                  class="absolute bottom-0 left-0 w-0 h-0.5 bg-slate-300 group-hover/cat:w-full transition-all duration-300 ease-out"
                ></span>
              </span>
            </div>
          </div>
        </div>

        <!-- Products Display with Animations -->
        <div
          class="mt-6 sm:mt-12 grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2 sm:gap-6"
        >
          <CommonProductCard
            v-for="(product, index) in filteredProducts"
            :key="product.id"
            :product="product"
            class="transform transition-all duration-500 hover:translate-y-[-5px] hover:shadow-sm opacity-0"
            :style="{
              animation: 'fadeInUp 0.5s ease-out forwards',
              animationDelay: `${index * 50}ms`,
            }"
          />

          <!-- Enhanced Empty State -->
          <div
            v-if="filteredProducts.length === 0"
            class="col-span-full flex flex-col items-center justify-center py-12 text-center animate-fade-in"
          >
            <div
              class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-6 shadow-inner relative overflow-hidden group"
            >
              <div
                class="absolute inset-0 bg-gradient-to-b from-white/80 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>
              <PackageX
                class="w-10 h-10 text-slate-400 relative z-10 transform transition-all duration-500 group-hover:scale-110"
              />
            </div>
            <h3
              class="font-semibold text-slate-800 text-xl mb-2 bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600"
            >
              No Products Found
            </h3>
            <p class="text-slate-500 max-w-sm">
              There are no products available in this category. Try selecting a
              different category.
            </p>
          </div>
        </div>

        <!-- Vendor Details with Enhanced Animation -->
        <div
          ref="detailsRef"
          class="grid grid-cols-1 md:grid-cols-2 gap-6 lg:gap-8 my-20 max-w-5xl mx-auto transition-all duration-700 transform"
          :class="
            visibleSections.details
              ? 'opacity-100 translate-y-0'
              : 'opacity-0 translate-y-10'
          "
        >
          <div
            v-for="(item, index) in [
              {
                icon: Mail,
                title: 'Email',
                content: storeDetails?.email || 'No email provided',
              },
              {
                icon: LocateIcon,
                title: 'Address',
                content: storeDetails?.store_address || 'No address provided',
              },
            ]"
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
            <div
              class="absolute inset-0 bg-white/60 backdrop-blur-sm rounded-xl shadow-sm group-hover:shadow-sm transition-all duration-300 border border-white/50 overflow-hidden"
            ></div>

            <!-- Card Background Pattern -->
            <div
              class="absolute inset-0 bg-gradient-to-br from-slate-50/80 via-white/90 to-slate-50/80 opacity-80 group-hover:opacity-100 transition-opacity duration-500 rounded-xl"
            ></div>
            <div
              class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(to_bottom,white,transparent)] opacity-50 group-hover:opacity-70 transition-all duration-500"
            ></div>

            <!-- Card Content -->
            <div class="p-7 relative">
              <div class="flex flex-col items-center text-center">
                <div
                  class="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center mb-4 group-hover:bg-slate-800 group-hover:text-white transition-all duration-500 transform group-hover:scale-110 shadow-sm group-hover:shadow-sm relative overflow-hidden"
                >
                  <!-- Icon Glow Effect -->
                  <div
                    class="absolute inset-0 bg-gradient-to-br from-slate-200/0 to-slate-100/80 opacity-0 group-hover:opacity-30 transition-opacity duration-500 group-hover:animate-spin-slow"
                  ></div>
                  <component
                    :is="item.icon"
                    class="w-6 h-6 relative z-10 transform transition-transform duration-500 group-hover:scale-110"
                  />
                </div>

                <h3
                  class="font-semibold text-lg mb-2 bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600"
                >
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
          :class="
            visibleSections.cta
              ? 'opacity-100 translate-y-0'
              : 'opacity-0 translate-y-10'
          "
        >
          <!-- CTA Background -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900"
          ></div>

          <!-- CTA Background Pattern -->
          <div
            class="absolute inset-0 opacity-20"
            style="
              background-image: radial-gradient(
                  circle at 30% 50%,
                  rgba(255, 255, 255, 0.1) 0%,
                  transparent 45%
                ),
                radial-gradient(
                  circle at 70% 20%,
                  rgba(255, 255, 255, 0.08) 0%,
                  transparent 35%
                );
            "
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
                animation: `floatParticle ${
                  Math.random() * 8 + 10
                }s ease-in-out infinite`,
                animationDelay: `${Math.random() * 5}s`,
                transform: `translateZ(${Math.random() * 30}px)`,
              }"
            ></div>
          </div>

          <!-- CTA Content -->
          <div
            class="relative p-10 md:p-14 flex flex-col md:flex-row items-center justify-between gap-8"
          >
            <div
              class="text-center md:text-left transform transition-all duration-500 md:hover:translate-x-2"
            >
              <h2
                class="text-xl md:text-3xl font-semibold text-white mb-3 tracking-tight"
              >
                Ready to explore our products?
              </h2>
              <p class="text-slate-300">
                Join thousands of satisfied customers today.
              </p>
            </div>

            <!-- Enhanced CTA Button -->
            <div
              class="relative overflow-hidden rounded-full bg-white text-slate-900 hover:text-slate-800 px-6 py-3 h-auto text-base lg:text-lg font-medium shadow-sm hover:shadow-sm transition-all duration-500 hover:scale-105 transform group/cta w-full md:w-auto flex items-center justify-center"
            >
              <span class="relative z-10 flex items-center justify-center">
                Thanks for visiting our store
                <ChevronRight
                  class="ml-2 h-5 w-5 inline-block group-hover/cta:translate-x-1.5 transition-transform duration-300"
                />
              </span>

              <!-- Button Highlight Effect -->
              <span
                class="absolute inset-0 bg-gradient-to-r from-white/0 via-white/90 to-white/0 opacity-0 group-hover/cta:opacity-100 transition-opacity duration-500 transform -translate-x-full group-hover/cta:translate-x-full"
              ></span>
            </div>
          </div>
        </div>
      </div>

      <!-- Enhanced Logo Upload Modal -->
      <Teleport to="body">
        <div
          v-if="showLogoUpload"
          class="fixed inset-0 bg-slate-900/80 backdrop-blur-sm z-50 flex items-center justify-center p-4 transition-opacity duration-300"
          @click.self="showLogoUpload = false"
        >
          <div
            class="sm:max-w-[425px] bg-white/95 backdrop-blur-xl rounded-xl shadow-sm w-full transform transition-all duration-500 border border-white/50"
            :class="
              showLogoUpload ? 'scale-100 opacity-100' : 'scale-95 opacity-0'
            "
          >
            <div class="p-7">
              <div class="flex items-center justify-between mb-4">
                <h3
                  class="text-lg font-semibold bg-clip-text text-transparent bg-gradient-to-r from-slate-800 to-slate-600"
                >
                  Upload Logo
                </h3>
                <button
                  class="rounded-full h-9 w-9 p-0 flex items-center justify-center hover:bg-slate-100 transition-colors duration-200 group"
                  @click="showLogoUpload = false"
                >
                  <X
                    class="h-4 w-4 group-hover:rotate-90 transition-transform duration-300"
                  />
                </button>
              </div>
              <p class="text-slate-500 text-sm mb-6">
                Upload a new logo for your vendor profile.
              </p>

              <!-- Enhanced Upload Area -->
              <label
                class="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed border-slate-300 rounded-xl cursor-pointer bg-slate-50/70 hover:bg-slate-100/80 transition-all duration-300 group relative overflow-hidden"
              >
                <div
                  class="absolute inset-0 bg-gradient-to-br from-slate-100/50 via-white/20 to-slate-50/50 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
                ></div>
                <div
                  class="flex flex-col items-center justify-center pt-5 pb-6 relative z-10"
                >
                  <ImageIcon
                    class="w-12 h-12 mb-4 text-slate-400 group-hover:text-slate-500 transition-colors duration-300 group-hover:scale-110 transform transition-transform"
                  />
                  <p
                    class="mb-2 text-sm text-slate-500 group-hover:text-slate-600 transition-colors duration-300"
                  >
                    <span class="font-semibold">Click to upload</span> or drag
                    and drop
                  </p>
                  <p
                    class="text-xs text-slate-400 group-hover:text-slate-500 transition-colors duration-300"
                  >
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
  </UContainer>
</template>

<script setup>
const { get, patch } = useApi();
const router = useRoute();
const toast = useToast();
const products = ref([]);
const storeDetails = ref({});
const { user, token } = useAuth();
const isLoading = ref(false);
const isSeeMore = ref(false);

// Check if current user is store owner
const isOwner = computed(() => {
  return (
    user.value?.user?.store_username === storeDetails.value?.store_username
  );
});

import {
  Search,
  MapPin,
  Clock,
  Mail,
  ChevronRight,
  X,
  Camera,
  ImageIcon,
  Heart,
  Truck,
  PackageX,
  Phone,
  LocateIcon,
} from "lucide-vue-next";

// Helper to get initials from name
const getInitials = (name) => {
  if (!name) return "";
  return name
    .split(" ")
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
};

async function getMyProducts() {
  isLoading.value = true;
  try {
    const response = await get(`/store/${router.params.id}/products/`);
    products.value = response.data;
    console.log("Products loaded:", products.value.length);
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load products. Please try again later.",
      color: "red",
    });
    products.value = [];
  } finally {
    isLoading.value = false;
  }
}

async function getStoreDetails() {
  isLoading.value = true;
  try {
    const { data } = await get(`/store/${router.params.id}/`);
    storeDetails.value = data;
    console.log("Store details loaded successfully");
  } catch (error) {
    console.error("Error fetching store details:", error);
    toast.add({
      title: "Error loading store",
      description: "Could not load store details. Please try again later.",
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// State for category filtering
const selectedCategory = ref(null);
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

// Get unique categories from products
const uniqueCategories = computed(() => {
  if (!products.value || products.value.length === 0) return [];

  const categories = [];
  const map = new Map();

  products.value.forEach((product) => {
    if (product.category_details && !map.has(product.category_details.id)) {
      map.set(product.category_details.id, true);
      categories.push(product.category_details);
    }
  });

  return categories;
});

// Filter products by selected category
const filteredProducts = computed(() => {
  let result = products.value;

  // Filter by category if selected
  if (selectedCategory.value) {
    result = result.filter(
      (product) => product.category === selectedCategory.value
    );
  }

  // Filter by search term if present
  if (searchValue.value.trim()) {
    const searchTerm = searchValue.value.toLowerCase().trim();
    result = result.filter(
      (product) =>
        product.name?.toLowerCase().includes(searchTerm) ||
        product.description?.toLowerCase().includes(searchTerm) ||
        product.price?.toString().includes(searchTerm)
    );
  }

  return result;
});

// Add a function to handle search submission (for Enter key or button click)
function handleSearch() {
  // Trigger filtering by setting the search value
  console.log("Searching for:", searchValue.value);
  // You could add additional logic here if needed
}

// Helper function to get product count by category
function getProductCountByCategory(categoryId) {
  return products.value.filter((product) => product.category === categoryId)
    .length;
}

// Refs
const bannerRef = ref(null);
const categoriesRef = ref(null);
const detailsRef = ref(null);
const ctaRef = ref(null);

// Handle file uploads with improved error handling
async function handleBannerUpload(e) {
  const files = Array.from(e.target.files);
  const file = files[0];
  if (!file) return;

  try {
    isLoading.value = true;

    // Validate file size (limit to 2MB)
    if (file.size > 2 * 1024 * 1024) {
      throw new Error("File size exceeds 2MB limit");
    }

    // Validate file type
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      throw new Error("Only JPEG, PNG, and WEBP formats are allowed");
    }

    // Convert file to base64
    const base64 = await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = (error) => reject(error);
      reader.readAsDataURL(file);
    });

    // Set local state for preview
    bannerImage.value = base64;

    // Make API call with the proper headers
    const response = await patch(`/store/${router.params.id}/`, {
      store_banner: base64,
    });

    // Show success message
    toast.add({
      title: "Banner Updated",
      description: "Your store banner has been successfully updated",
      color: "green",
    });

    // Hide the upload modal
    showBannerUpload.value = false;

    // Update store details with new data
    storeDetails.value = response.data;
  } catch (error) {
    console.error("Error uploading banner:", error);
    toast.add({
      title: "Upload Failed",
      description:
        error.message || "Could not upload banner. Please try again.",
      color: "red",
    });
  } finally {
    isLoading.value = false;
    // Refresh store details
    await getStoreDetails();
  }
}

async function handleLogoUpload(e) {
  const files = Array.from(e.target.files);
  const file = files[0];
  if (!file) return;

  try {
    isLoading.value = true;

    // Validate file size (limit to 1MB)
    if (file.size > 1 * 1024 * 1024) {
      throw new Error("File size exceeds 1MB limit");
    }

    // Validate file type
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      throw new Error("Only JPEG, PNG, and WEBP formats are allowed");
    }

    // Convert file to base64
    const base64 = await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = (error) => reject(error);
      reader.readAsDataURL(file);
    });

    // Set local state for preview
    logoImage.value = base64;

    // Make API call with the proper headers
    const response = await patch(`/store/${router.params.id}/`, {
      store_logo: base64,
    });

    // Show success message
    toast.add({
      title: "Logo Updated",
      description: "Your store logo has been successfully updated",
      color: "green",
    });

    // Hide the upload modal
    showLogoUpload.value = false;

    // Update store details with new data
    storeDetails.value = response.data;
  } catch (error) {
    console.error("Error uploading logo:", error);
    toast.add({
      title: "Upload Failed",
      description: error.message || "Could not upload logo. Please try again.",
      color: "red",
    });
  } finally {
    isLoading.value = false;
    // Refresh store details
    await getStoreDetails();
  }
}

// Initialize component
onMounted(async () => {
  // Get initial data
  await Promise.all([getStoreDetails(), getMyProducts()]);

  // If there's only one category, auto-select it
  if (uniqueCategories.value.length === 1) {
    selectedCategory.value = uniqueCategories.value[0].id;
  }

  // Enhanced scroll effects with IntersectionObserver for better performance
  const observerOptions = {
    root: null,
    rootMargin: "0px",
    threshold: 0.2,
  };

  const sectionObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.target === categoriesRef.value) {
        visibleSections.categories = entry.isIntersecting;
      } else if (entry.target === detailsRef.value) {
        visibleSections.details = entry.isIntersecting;
      } else if (entry.target === ctaRef.value) {
        visibleSections.cta = entry.isIntersecting;
      }
    });
  }, observerOptions);

  // Handle parallax effect
  const handleScroll = () => {
    if (bannerRef.value) {
      const scrollPosition = window.scrollY;
      const translateY = Math.min(scrollPosition * 0.3, 100); // Limit the movement
      bannerRef.value.style.transform = `translateY(${translateY}px)`;
    }
  };

  // Observe sections for animations
  if (categoriesRef.value) sectionObserver.observe(categoriesRef.value);
  if (detailsRef.value) sectionObserver.observe(detailsRef.value);
  if (ctaRef.value) sectionObserver.observe(ctaRef.value);

  window.addEventListener("scroll", handleScroll);
  handleScroll(); // Initial call

  // Clean up event listeners and observers
  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
    sectionObserver.disconnect();
  });
});
</script>

<style>
/* Enhanced animations and effects */
@keyframes floatParticle {
  0%,
  100% {
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
  0%,
  100% {
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
  background-image: linear-gradient(
      to right,
      rgba(241, 245, 249, 0.5) 1px,
      transparent 1px
    ),
    linear-gradient(to bottom, rgba(241, 245, 249, 0.5) 1px, transparent 1px);
  background-size: 20px 20px;
}

.bg-grid-slate-200 {
  background-image: linear-gradient(
      to right,
      rgba(226, 232, 240, 0.5) 1px,
      transparent 1px
    ),
    linear-gradient(to bottom, rgba(226, 232, 240, 0.5) 1px, transparent 1px);
  background-size: 20px 20px;
}

/* Responsive optimizations */
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
  .group:hover .group-hover\:translate-y-\[-5px\],
  .group:hover .group-hover\:rotate-3 {
    transform: none !important; /* Remove hover effects that may cause jank on touch */
  }

  /* Ensure touch devices still get feedback */
  .group:active .group-hover\:scale-105 {
    transform: scale(1.02) !important;
    transition: transform 0.2s ease;
  }
}

/* Make modals fully responsive */
@media (max-width: 640px) {
  .sm\:max-w-\[600px\],
  .sm\:max-w-\[500px\],
  .sm\:max-w-\[425px\] {
    max-width: calc(100% - 32px);
  }

  /* Ensure better spacing on small screens */
  .p-7 {
    padding: 1.25rem;
  }

  .gap-5 {
    gap: 0.75rem;
  }
}

/* Improved mobile responsiveness for description expansion */
@media (max-width: 640px) {
  /* ...existing mobile styles... */

  /* Add smoother transition for description expansion/collapse */
  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    transition: all 0.3s ease;
  }

  /* Prevent content jump when toggling description */
  [v-cloak] {
    display: none;
  }
}
</style>
