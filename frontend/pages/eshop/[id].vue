<template>
  <UContainer>
    <div
      class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50"
    >
      <!-- Banner Section with Parallax Effect -->
      <div class="relative w-full h-[60vh]">
        <div
          ref="bannerRef"
          class="absolute inset-0 w-full h-[60%] transition-transform duration-300"
        >
          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-900/80 to-slate-800/80 mix-blend-multiply"
          ></div>
          <div
            class="absolute inset-0 bg-cover bg-center"
            :style="{
              backgroundImage: bannerImage
                ? `url(${bannerImage})`
                : 'url(\'/placeholder.svg?height=800&width=1600\')',
            }"
          ></div>
          <div
            class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/30"
          ></div>

          <!-- Banner upload button -->
          <div class="absolute top-4 right-4 z-20">
            <button
              class="rounded-full bg-white/20 backdrop-blur-md border-white/30 text-white hover:bg-white/30 hover:text-white px-3 py-1.5 text-sm font-medium inline-flex items-center"
              @click="showBannerUpload = true"
            >
              <Camera class="w-4 h-4 mr-2" />
              {{ bannerImage ? "Change Banner" : "Upload Banner" }}
            </button>
          </div>

          <!-- Animated particles -->
          <div class="absolute inset-0 opacity-30">
            <div
              v-for="(_, i) in 20"
              :key="i"
              class="absolute rounded-full bg-white"
              :style="{
                width: `${Math.random() * 4 + 1}px`,
                height: `${Math.random() * 4 + 1}px`,
                top: `${Math.random() * 100}%`,
                left: `${Math.random() * 100}%`,
                opacity: Math.random() * 0.5 + 0.3,
                animation: `float ${Math.random() * 8 + 8}s linear infinite`,
                animationDelay: `${Math.random() * 5}s`,
              }"
            ></div>
          </div>
        </div>

        <!-- Banner Upload Modal -->
        <Teleport to="body">
          <div
            v-if="showBannerUpload"
            class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
          >
            <div class="sm:max-w-[500px] bg-white rounded-lg shadow-xl w-full">
              <div class="p-6">
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-lg font-semibold">Upload Banner</h3>
                  <button
                    class="rounded-full h-8 w-8 p-0 flex items-center justify-center hover:bg-slate-100"
                    @click="showBannerUpload = false"
                  >
                    <X class="h-4 w-4" />
                  </button>
                </div>
                <p class="text-slate-500 text-sm mb-4">
                  Upload a new banner image for your profile.
                </p>

                <label
                  class="flex flex-col items-center justify-center w-full h-40 border-2 border-dashed border-slate-300 rounded-lg cursor-pointer bg-slate-50 hover:bg-slate-100 transition-colors"
                >
                  <div
                    class="flex flex-col items-center justify-center pt-5 pb-6"
                  >
                    <Camera class="w-10 h-10 mb-3 text-slate-400" />
                    <p class="mb-2 text-sm text-slate-500">
                      <span class="font-semibold">Click to upload</span> or drag
                      and drop
                    </p>
                    <p class="text-xs text-slate-500">
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

                <div class="flex justify-end mt-4">
                  <button
                    class="px-4 py-2 border border-slate-300 rounded-md text-sm font-medium hover:bg-slate-50"
                    @click="showBannerUpload = false"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>
        </Teleport>

        <!-- Vendor Info Card at Bottom of Banner -->
        <div
          class="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 md:-translate-y-2/3 w-[90%] max-w-4xl z-10"
        >
          <div
            class="border-none shadow-2xl bg-white/95 backdrop-blur-md rounded-2xl overflow-hidden animate-fade-in-up relative"
          >
            <div
              class="absolute inset-0 bg-gradient-to-r from-slate-100/50 to-white/50 opacity-80"
            ></div>
            <div
              class="absolute inset-0 bg-grid-slate-200/50 [mask-image:linear-gradient(to_bottom,white,transparent)]"
            ></div>
            <div
              class="p-4 md:p-6 flex flex-col md:flex-row gap-4 items-center relative"
            >
              <div
                class="relative h-20 w-20 md:h-28 md:w-28 rounded-2xl overflow-hidden ring-4 ring-white shadow-lg transform transition-transform hover:scale-105 group"
              >
                <div
                  class="absolute inset-0 bg-gradient-to-br from-slate-700 to-slate-900 group-hover:from-slate-600 group-hover:to-slate-800 transition-colors duration-300"
                ></div>
                <div
                  class="absolute inset-0 flex items-center justify-center text-white font-bold text-2xl"
                >
                  <span v-if="!logoImage">TP</span>
                </div>
                <div
                  class="absolute inset-0 bg-cover bg-center opacity-80 group-hover:opacity-100 transition-opacity duration-300"
                  :style="{
                    backgroundImage: logoImage
                      ? `url(${logoImage})`
                      : 'url(\'/placeholder.svg?height=200&width=200\')',
                  }"
                ></div>

                <!-- Logo upload button -->
                <div
                  class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black/50 cursor-pointer"
                  @click="showLogoUpload = true"
                >
                  <div
                    class="flex flex-col items-center justify-center text-white text-xs"
                  >
                    <ImageIcon class="w-6 h-6 mb-1" />
                    <span>{{ logoImage ? "Change Logo" : "Upload Logo" }}</span>
                  </div>
                </div>
              </div>
              <div class="flex-1 text-center md:text-left">
                <h1
                  class="text-3xl md:text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-700"
                >
                  TechVendor Pro
                </h1>
                <p class="text-slate-600 mt-1">
                  Premium technology solutions since 2010
                </p>
                <div
                  class="flex flex-wrap gap-2 mt-4 justify-center md:justify-start"
                >
                  <span
                    class="px-3 py-1 bg-white shadow-sm hover:shadow transition-shadow duration-300 rounded-full text-sm flex items-center"
                  >
                    <MapPin class="w-3 h-3 mr-1" /> New York, USA
                  </span>
                  <span
                    class="px-3 py-1 bg-white shadow-sm hover:shadow transition-shadow duration-300 rounded-full text-sm flex items-center"
                  >
                    <Clock class="w-3 h-3 mr-1" /> Mon-Fri, 9am-5pm
                  </span>
                  <span
                    class="px-3 py-1 cursor-pointer bg-white shadow-sm hover:shadow hover:bg-slate-50 transition-all duration-300 rounded-full text-sm flex items-center"
                    @click="reviewsOpen = true"
                  >
                    <span class="flex">
                      <svg
                        v-for="star in 5"
                        :key="star"
                        class="w-3 h-3 text-yellow-400"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path
                          d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
                        />
                      </svg>
                    </span>
                    <span class="ml-1">4.8 (256)</span>
                  </span>
                </div>
              </div>
              <div class="flex gap-2">
                <button
                  class="rounded-full bg-gradient-to-r from-slate-800 to-slate-700 hover:from-slate-700 hover:to-slate-600 transition-all duration-300 shadow-lg hover:shadow-xl hover:scale-105 transform text-white px-4 py-2 font-medium"
                >
                  Contact
                </button>
                <button
                  class="rounded-full border border-slate-300 hover:bg-slate-100 transition-all duration-300 hover:scale-105 transform px-4 py-2 font-medium"
                >
                  Follow
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="container mx-auto px-4 pt-48 md:pt-0 mt-0 md:-mt-16 pb-16">
        <!-- Enhanced Search Section - No Dropdown -->
        <div class="mb-16 mt-8">
          <div
            :class="`relative max-w-2xl mx-auto transition-all duration-300 ease-out ${
              searchFocused ? 'scale-105' : 'scale-100'
            }`"
          >
            <!-- Animated background glow -->
            <div
              :class="`absolute inset-0 bg-gradient-to-r from-slate-300/70 via-slate-200/70 to-slate-300/70 rounded-full blur-xl transition-all duration-300 ${
                searchFocused ? 'opacity-100 scale-105' : 'opacity-70 scale-100'
              }`"
            ></div>

            <!-- Search input container -->
            <div class="relative z-10">
              <div class="relative overflow-hidden rounded-full shadow-xl">
                <div
                  :class="`absolute inset-0 bg-white/90 backdrop-blur-md transition-opacity duration-200 ${
                    searchFocused ? 'opacity-100' : 'opacity-90'
                  }`"
                ></div>

                <div class="relative flex items-center p-1">
                  <div
                    :class="`p-2 transition-all duration-200 ${
                      searchFocused ? 'text-slate-800' : 'text-slate-400'
                    }`"
                  >
                    <Search class="h-5 w-5" />
                  </div>
                  <input
                    type="text"
                    placeholder="Search premium products..."
                    class="border-0 bg-transparent text-base w-16 sm:w-auto py-2 md:py-3 px-2 flex-1 placeholder:text-slate-400 focus:outline-none"
                    @focus="searchFocused = true"
                    @blur="searchFocused = false"
                    v-model="searchValue"
                  />
                  <button
                    v-if="searchValue"
                    class="mr-2 h-8 w-8 rounded-full p-0 flex items-center justify-center hover:bg-slate-100"
                    @click="searchValue = ''"
                  >
                    <X class="h-4 w-4" />
                  </button>
                  <button
                    :class="`rounded-full mr-1 transition-all duration-200 text-white px-3 py-1 md:px-4 md:py-2 ${
                      searchFocused
                        ? 'bg-slate-800 hover:bg-slate-700'
                        : 'bg-slate-700 hover:bg-slate-600'
                    }`"
                  >
                    Search
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Categories & Products Section -->
        <div class="mb-16 mt-8">
          <!-- Category Tabs -->
          <div
            ref="categoriesRef"
            :class="`flex flex-col items-center mt-16 transition-all duration-500 transform ${
              visibleSections.categories
                ? 'opacity-100 translate-y-0'
                : 'opacity-0 translate-y-10'
            }`"
          >
            <h2 class="text-xl font-semibold mb-6 text-center relative">
              <span class="relative inline-block">
                Browse Categories
                <span
                  class="absolute -bottom-2 left-0 right-0 h-1 bg-gradient-to-r from-slate-400 to-transparent rounded-full"
                ></span>
              </span>
            </h2>

            <div class="flex flex-wrap justify-center gap-3 max-w-3xl">
              <span
                class="px-4 py-3 text-sm cursor-pointer bg-white hover:bg-slate-50 shadow-md hover:shadow-lg transition-all duration-200 border border-slate-100 rounded-xl group"
                :class="{
                  'bg-slate-800 text-slate-500 ': selectedCategory === null,
                }"
                @click="selectedCategory = null"
                style="
                  animation: fadeInUp 0.3s ease-out forwards;
                  animation-delay: 0ms;
                "
              >
                <span class="relative z-10">All Products</span>
                <span
                  class="ml-2 px-2 py-0.5 text-xs bg-slate-100 group-hover:bg-slate-200 rounded-full transition-colors duration-200 text-slate-500"
                >
                  {{ products.length }}
                </span>
              </span>

              <span
                v-for="category in uniqueCategories"
                :key="category.id"
                class="px-4 py-3 text-sm cursor-pointer bg-white hover:bg-slate-50 shadow-md hover:shadow-lg transition-all duration-200 border border-slate-100 rounded-xl group"
                :class="{
                  'bg-slate-800 text-slate-500 ':
                    selectedCategory === category.id,
                }"
                @click="selectedCategory = category.id"
                style="animation: fadeInUp 0.3s ease-out forwards"
                :style="{ animationDelay: `${50}ms` }"
              >
                <span class="relative z-10">{{ category.name }}</span>
                <span
                  class="ml-2 px-2 py-0.5 text-xs bg-slate-100 group-hover:bg-slate-200 rounded-full transition-colors duration-200 text-slate-500"
                >
                  {{ getProductCountByCategory(category.id) }}
                </span>
              </span>
            </div>
          </div>

          <!-- Products Display Section -->
          <div
            class="mt-12 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6"
          >
            <div
              v-for="product in filteredProducts"
              :key="product.id"
              class="bg-white border border-slate-200 rounded-xl shadow-md hover:shadow-lg transition-all duration-300 overflow-hidden group animate-fade-in"
            >
              <!-- Product Image -->
              <div class="relative h-48 overflow-hidden bg-slate-100">
                <img
                  v-if="
                    product.image_details && product.image_details.length > 0
                  "
                  :src="product.image_details[0].image"
                  :alt="product.name"
                  class="w-full h-full object-cover object-center group-hover:scale-105 transition-transform duration-500"
                />
                <div
                  v-else
                  class="w-full h-full flex items-center justify-center"
                >
                  <ImageIcon class="w-10 h-10 text-slate-300" />
                </div>

                <!-- Sale Badge -->
                <div
                  v-if="product.sale_price"
                  class="absolute top-2 right-2 bg-red-500 text-white text-xs px-2 py-1 rounded-full font-medium"
                >
                  Sale
                </div>
              </div>

              <!-- Product Details -->
              <div class="p-4">
                <h3 class="font-medium text-slate-900 mb-1 truncate">
                  {{ product.name }}
                </h3>

                <!-- Category Badge -->
                <div class="mb-2">
                  <span
                    class="inline-block bg-slate-100 px-2 py-0.5 rounded text-xs text-slate-600"
                  >
                    {{ getCategoryName(product.category) }}
                  </span>
                </div>

                <!-- Price -->
                <div class="flex items-center gap-2 mb-3">
                  <span class="font-bold text-slate-900">
                    ৳{{ product.sale_price || product.regular_price }}
                  </span>
                  <span
                    v-if="product.sale_price"
                    class="text-sm text-slate-500 line-through"
                  >
                    ৳{{ product.regular_price }}
                  </span>
                </div>

                <!-- Action Buttons -->
                <div class="flex gap-2">
                  <button
                    class="flex-1 bg-slate-800 hover:bg-slate-700 text-white py-2 rounded-lg text-sm font-medium transition-colors duration-200"
                  >
                    Add to Cart
                  </button>
                  <button
                    class="w-10 h-10 flex items-center justify-center border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors duration-200"
                  >
                    <Heart class="w-4 h-4" />
                  </button>
                </div>

                <!-- Delivery Info -->
                <div
                  class="mt-3 flex items-center justify-between text-xs text-slate-500"
                >
                  <span
                    v-if="product.is_free_delivery"
                    class="flex items-center"
                  >
                    <Truck class="w-3.5 h-3.5 mr-1" />
                    Free Delivery
                  </span>
                  <span v-else class="flex items-center">
                    <Truck class="w-3.5 h-3.5 mr-1" />
                    Paid Shipping
                  </span>

                  <span>Stock: {{ product.quantity }}</span>
                </div>
              </div>
            </div>

            <!-- Empty State -->
            <div
              v-if="filteredProducts.length === 0"
              class="col-span-full flex flex-col items-center justify-center py-12 text-center"
            >
              <div
                class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4"
              >
                <PackageX class="w-8 h-8 text-slate-400" />
              </div>
              <h3 class="font-medium text-slate-800 text-lg mb-1">
                No Products Found
              </h3>
              <p class="text-slate-500 max-w-sm">
                There are no products available in this category. Try selecting
                a different category.
              </p>
            </div>
          </div>
        </div>

        <!-- Vendor Details with Animation -->
        <div
          ref="detailsRef"
          :class="`grid grid-cols-1 md:grid-cols-3 gap-6 my-16 max-w-5xl mx-auto transition-all duration-500 transform ${
            visibleSections.details
              ? 'opacity-100 translate-y-0'
              : 'opacity-0 translate-y-10'
          }`"
        >
          <div
            v-for="(item, index) in vendorDetails"
            :key="index"
            class="overflow-hidden border-none shadow-lg hover:shadow-xl transition-all duration-300 group rounded-xl relative"
            :style="{
              animationDelay: `${index * 100}ms`,
              animation: 'fadeInUp 0.3s ease-out forwards',
              opacity: 0,
              transform: 'translateY(20px)',
            }"
          >
            <div
              class="absolute inset-0 bg-gradient-to-br from-slate-50 to-white opacity-80"
            ></div>
            <div
              class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(to_bottom,white,transparent)]"
            ></div>
            <div class="p-6 relative">
              <div class="flex flex-col items-center text-center">
                <div
                  class="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center mb-4 group-hover:bg-slate-800 group-hover:text-white transition-all duration-300 transform group-hover:scale-110 shadow-md group-hover:shadow-xl"
                >
                  <component :is="item.icon" class="w-5 h-5" />
                </div>
                <h3 class="font-semibold text-lg mb-2">{{ item.title }}</h3>
                <p class="text-slate-600 whitespace-pre-line">
                  {{ item.content }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Call to Action with Animation -->
        <div
          ref="ctaRef"
          :class="`relative mt-20 mb-10 max-w-5xl mx-auto overflow-hidden rounded-2xl transition-all duration-500 transform ${
            visibleSections.cta
              ? 'opacity-100 translate-y-0'
              : 'opacity-0 translate-y-10'
          }`"
        >
          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-800 to-slate-900"
          ></div>

          <!-- Animated particles -->
          <div class="absolute inset-0 opacity-30">
            <div
              v-for="(_, i) in 15"
              :key="i"
              class="absolute rounded-full bg-white"
              :style="{
                width: `${Math.random() * 4 + 1}px`,
                height: `${Math.random() * 4 + 1}px`,
                top: `${Math.random() * 100}%`,
                left: `${Math.random() * 100}%`,
                opacity: Math.random() * 0.5 + 0.3,
                animation: `float ${Math.random() * 8 + 8}s linear infinite`,
                animationDelay: `${Math.random() * 5}s`,
              }"
            ></div>
          </div>

          <div
            class="absolute inset-0 opacity-20"
            style="
              background-image: url('/placeholder.svg?height=400&width=1200');
              background-size: cover;
              background-position: center;
            "
          ></div>
          <div
            class="relative p-8 md:p-12 flex flex-col md:flex-row items-center justify-between gap-6"
          >
            <div class="text-center md:text-left">
              <h2 class="text-2xl md:text-3xl font-bold text-white mb-2">
                Ready to explore our products?
              </h2>
              <p class="text-slate-300">
                Join thousands of satisfied customers today.
              </p>
            </div>
            <button
              class="rounded-full bg-white text-slate-900 hover:bg-slate-100 px-4 py-2 h-auto text-base lg:text-lg font-medium shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-105 transform group w-64"
            >
              Browse All Products
              <ChevronRight
                class="ml-2 h-5 w-5 inline-block group-hover:translate-x-1 transition-transform duration-200"
              />
            </button>
          </div>
        </div>
      </div>

      <!-- Reviews Modal -->
      <Teleport to="body">
        <div
          v-if="reviewsOpen"
          class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        >
          <div
            class="sm:max-w-[600px] max-h-[80vh] overflow-y-auto bg-white/95 backdrop-blur-md border-none shadow-2xl rounded-2xl w-full relative"
          >
            <div
              class="absolute inset-0 bg-gradient-to-br from-slate-50 to-white opacity-80 rounded-2xl"
            ></div>
            <div
              class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(to_bottom,white,transparent)] rounded-2xl"
            ></div>

            <div class="relative z-10 p-6">
              <div class="flex items-center justify-between text-xl mb-2">
                <h3 class="font-semibold">
                  {{
                    selectedProduct ? "Product Reviews" : "All Vendor Reviews"
                  }}
                </h3>
                <button
                  class="rounded-full h-8 w-8 p-0 flex items-center justify-center bg-slate-100 hover:bg-slate-200 transition-colors duration-200"
                  @click="reviewsOpen = false"
                >
                  <X class="h-4 w-4" />
                </button>
              </div>
              <p class="text-slate-500 text-sm mb-6">
                See what our customers are saying about our products
              </p>

              <div class="space-y-6 mt-4">
                <div
                  v-for="(review, index) in reviews"
                  :key="review.id"
                  class="space-y-4 animate-fade-in"
                  :style="{ animationDelay: `${index * 100}ms` }"
                >
                  <div class="flex items-start gap-4">
                    <div
                      class="h-10 w-10 rounded-full bg-gradient-to-br from-slate-700 to-slate-900 text-white flex items-center justify-center border-2 border-white shadow-md"
                    >
                      {{ review.avatar }}
                    </div>
                    <div class="flex-1">
                      <div class="flex items-center justify-between">
                        <h4 class="font-medium">{{ review.user }}</h4>
                        <span class="text-sm text-slate-500">{{
                          review.date
                        }}</span>
                      </div>
                      <div class="flex mt-1">
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
                      <p class="mt-2 text-slate-700">{{ review.comment }}</p>
                    </div>
                  </div>
                  <hr class="border-slate-200" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </Teleport>

      <!-- Logo Upload Modal -->
      <Teleport to="body">
        <div
          v-if="showLogoUpload"
          class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        >
          <div class="sm:max-w-[425px] bg-white rounded-lg shadow-xl w-full">
            <div class="p-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold">Upload Logo</h3>
                <button
                  class="rounded-full h-8 w-8 p-0 flex items-center justify-center hover:bg-slate-100"
                  @click="showLogoUpload = false"
                >
                  <X class="h-4 w-4" />
                </button>
              </div>
              <p class="text-slate-500 text-sm mb-4">
                Upload a new logo for your vendor profile.
              </p>

              <label
                class="flex flex-col items-center justify-center w-full h-40 border-2 border-dashed border-slate-300 rounded-lg cursor-pointer bg-slate-50 hover:bg-slate-100 transition-colors"
              >
                <div
                  class="flex flex-col items-center justify-center pt-5 pb-6"
                >
                  <ImageIcon class="w-10 h-10 mb-3 text-slate-400" />
                  <p class="mb-2 text-sm text-slate-500">
                    <span class="font-semibold">Click to upload</span> or drag
                    and drop
                  </p>
                  <p class="text-xs text-slate-500">
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

              <div class="flex justify-end mt-4">
                <button
                  class="px-4 py-2 border border-slate-300 rounded-md text-sm font-medium hover:bg-slate-50"
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
const { get } = useApi();
const router = useRoute();
const products = ref([]);
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
} from "lucide-vue-next";

async function getMyProducts() {
  try {
    const response = await get(`/store/${router.params.id}/products/`);
    products.value = response.data;
    console.log("Products loaded:", products.value.length);
  } catch (error) {
    console.error("Error fetching products:", error);
    products.value = [];
  }
}

// State for category filtering
const selectedCategory = ref(null);

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
  if (!selectedCategory.value) return products.value;
  return products.value.filter(
    (product) => product.category === selectedCategory.value
  );
});

// Helper function to get product count by category
function getProductCountByCategory(categoryId) {
  return products.value.filter((product) => product.category === categoryId)
    .length;
}

// Helper function to get category name
function getCategoryName(categoryId) {
  const category = uniqueCategories.value.find((cat) => cat.id === categoryId);
  return category ? category.name : "Uncategorized";
}

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

await getMyProducts();
// Handle scroll effects
onMounted(async () => {
  // If there's only one category, auto-select it
  if (uniqueCategories.value.length === 1) {
    selectedCategory.value = uniqueCategories.value[0].id;
  }

  const handleScroll = () => {
    if (window.scrollY > 50) {
      scrolled.value = true;
    } else {
      scrolled.value = false;
    }

    // Check if sections are visible
    const isVisible = (element) => {
      if (!element) return false;
      const rect = element.getBoundingClientRect();
      return rect.top < window.innerHeight * 0.8 && rect.bottom >= 0;
    };

    visibleSections.categories = isVisible(categoriesRef.value);
    visibleSections.details = isVisible(detailsRef.value);
    visibleSections.cta = isVisible(ctaRef.value);
  };

  window.addEventListener("scroll", handleScroll);
  handleScroll();

  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
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
@keyframes float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-15px);
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

.animate-fade-in-up {
  animation: fadeInUp 0.5s ease-out forwards;
}

.animate-fade-in {
  animation: fadeIn 0.3s ease-out forwards;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.bg-grid-slate-100 {
  background-image: linear-gradient(to right, #f1f5f9 1px, transparent 1px),
    linear-gradient(to bottom, #f1f5f9 1px, transparent 1px);
  background-size: 20px 20px;
}

.bg-grid-slate-200 {
  background-image: linear-gradient(to right, #e2e8f0 1px, transparent 1px),
    linear-gradient(to bottom, #e2e8f0 1px, transparent 1px);
  background-size: 20px 20px;
}
</style>
