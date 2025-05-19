<template>
  <div class="bg-gradient-to-b from-gray-50 via-white to-gray-50 min-h-screen product-detail-page">
    <!-- Floating Back Button with improved styling -->
    <div class="fixed left-5 top-5 md:hidden z-50">
      <button 
        @click="$router.back()" 
        class="floating-back-btn bg-white/90 backdrop-blur-sm shadow-lg rounded-full p-3 text-gray-700 hover:text-primary hover:scale-105 transition-all duration-300 border border-gray-100"
      >
        <UIcon name="i-heroicons-arrow-left" class="size-5" />
      </button>
    </div>
      <!-- Page Content Container with enhanced padding -->
    <UContainer class="py-10">
      <!-- Enhanced Breadcrumbs Navigation with Animations -->
      <nav class="flex mb-8 fade-in-element" aria-label="Breadcrumb">
        <div class="bg-white/80 backdrop-blur-sm rounded-full px-4 py-2.5 shadow-sm border border-gray-100 overflow-hidden">
          <ol class="inline-flex items-center flex-wrap gap-1 md:gap-2">
            <li class="inline-flex items-center animate-slide-in" style="--delay: 100ms;">
              <NuxtLink
                to="/"
                class="inline-flex items-center text-sm font-medium text-gray-600 hover:text-primary transition-colors group"
              >
                <span class="bg-gray-100 group-hover:bg-primary-50 p-1.5 rounded-full mr-2 transition-colors">
                  <UIcon name="i-heroicons-home" class="size-3.5 text-gray-500 group-hover:text-primary-600" />
                </span>
                <span class="hidden sm:inline">Home</span>
              </NuxtLink>
            </li>
            <li class="animate-slide-in" style="--delay: 200ms;">
              <div class="flex items-center">
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="size-3 mx-1 text-gray-400"
                />
                <NuxtLink
                  to="/sale/for-sale"
                  class="inline-flex items-center text-sm font-medium text-gray-600 hover:text-primary transition-colors px-2 py-1 hover:bg-gray-50 rounded-md"
                >
                  Sale Posts
                </NuxtLink>
              </div>
            </li>
            <li aria-current="page" class="animate-slide-in" style="--delay: 300ms;">
              <div class="flex items-center">
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="size-3 mx-1 text-gray-400"
                />
                <span class="text-sm font-medium text-gray-800 truncate max-w-[150px] md:max-w-xs px-2 py-1 bg-gray-50 rounded-md">
                  {{ post.title || "Loading..." }}
                </span>
              </div>
            </li>
          </ol>
        </div>
      </nav>      <!-- Enhanced Professional Loading State -->
      <div
        v-if="loading"
        class="py-28 bg-white rounded-xl shadow-sm border border-gray-100 fade-in-element relative overflow-hidden"
      >
        <!-- Background decorative elements -->
        <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-primary-400 to-transparent loading-progress"></div>
        <div class="absolute -left-10 -top-10 w-40 h-40 bg-primary-50 rounded-full blur-3xl opacity-30"></div>
        <div class="absolute -right-10 -bottom-10 w-40 h-40 bg-blue-50 rounded-full blur-3xl opacity-30"></div>
        
        <div class="flex flex-col items-center justify-center relative z-10">
          <!-- Advanced Animated Loading Indicator -->
          <div class="loading-animation">
            <div class="w-24 h-24 relative">
              <div class="w-full h-full rounded-full border-4 border-gray-100"></div>
              <div class="w-full h-full rounded-full border-4 border-t-primary-500 border-r-primary-400 border-b-primary-300 animate-spin absolute top-0 left-0"></div>
              <div class="absolute inset-0 flex items-center justify-center">
                <div class="relative">
                  <UIcon name="i-heroicons-shopping-bag" class="size-10 text-primary-400" />
                  <span class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1.5 h-1.5 bg-white rounded-full animate-ping"></span>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Loading Message -->
          <div class="mt-10 relative">
            <p class="text-center text-gray-700 font-medium text-lg">
              Loading product details<span class="loading-dots">...</span>
            </p>
            <div class="mt-3 text-center text-sm text-gray-400">Please wait while we fetch the latest information</div>
          </div>
          
          <!-- Animated Loading Bars -->
          <div class="mt-8 flex flex-col items-center space-y-3 w-64">
            <div class="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
              <div class="h-full bg-gradient-to-r from-primary-300 to-primary-500 w-3/4 animate-pulse-width"></div>
            </div>
            <div class="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
              <div class="h-full bg-gradient-to-r from-primary-300 to-primary-500 w-1/2 animate-pulse-width delay-150"></div>
            </div>
            <div class="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
              <div class="h-full bg-gradient-to-r from-primary-300 to-primary-500 w-1/4 animate-pulse-width delay-300"></div>
            </div>
          </div>
        </div>
      </div>      <!-- Enhanced Professional Error State -->
      <div
        v-else-if="error"
        class="py-20 text-center bg-white rounded-xl shadow-md border border-gray-100 fade-in-element relative overflow-hidden"
      >
        <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-red-300 to-transparent"></div>
        <div class="absolute -left-20 -top-20 w-60 h-60 bg-red-50 rounded-full blur-3xl opacity-30"></div>
        <div class="absolute -right-20 -bottom-20 w-60 h-60 bg-amber-50 rounded-full blur-3xl opacity-30"></div>
        
        <div class="max-w-md mx-auto px-6 relative z-10">
          <!-- Enhanced Error Animation -->
          <div class="error-animation mb-8 relative">
            <div class="bg-amber-50 w-32 h-32 rounded-full mx-auto flex items-center justify-center border-4 border-amber-100">
              <UIcon
                name="i-heroicons-exclamation-triangle"
                class="h-16 w-16 text-amber-500 error-icon-pulse"
              />
            </div>
            <div class="absolute w-full h-full top-0 left-0 bg-amber-50 rounded-full animate-ping-slow opacity-30"></div>
          </div>
          
          <h3 class="text-2xl font-bold text-gray-800 mb-3 animate-fade-in" style="--delay: 200ms">
            Oops! Product Not Found
          </h3>
          
          <p class="mt-4 text-gray-600 text-lg mb-8 leading-relaxed animate-fade-in" style="--delay: 300ms">
            The product you're looking for doesn't exist or has been removed from our marketplace.
          </p>
          
          <!-- Enhanced action buttons -->
          <div class="flex flex-col sm:flex-row gap-4 justify-center animate-fade-in" style="--delay: 400ms">
            <UButton
              color="primary"
              variant="solid"
              class="px-8 py-3.5 text-base font-medium shadow-lg shadow-primary-500/20 hover:shadow-primary-500/30 transition-all hover:-translate-y-0.5"
              to="/sale/for-sale"
            >
              <UIcon name="i-heroicons-rectangle-stack" class="mr-2 size-5" />
              Browse Listings
            </UButton>
            
            <UButton
              color="gray"
              variant="soft"
              class="px-6 py-3.5 text-base font-medium hover:bg-gray-100 transition-all"
              @click="$router.push('/')"
            >
              <UIcon name="i-heroicons-home" class="mr-2 size-5" />
              Back to Home
            </UButton>
          </div>
        </div>
      </div>      
      
      <!-- Enhanced Post Details Content with Professional Styling -->
      <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Left Column - Main Content -->
        <div class="lg:col-span-2">
          <!-- Premium Title & Price Display with Enhanced Design -->
          <div class="bg-white rounded-xl shadow-md border border-gray-100 overflow-hidden mb-5 transform-gpu product-header fade-in-element" id="product-title">
            <!-- Color accent top bar -->
            <div class="h-1.5 bg-gradient-to-r from-primary-300 via-primary-500 to-primary-400"></div>
            
            <div class="p-6">
              <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
                <!-- Title and Badges -->
                <div class="flex-1 slide-up-fade-in" style="--delay: 100ms">
                  <!-- Premium Title -->
                  <h1 class="text-2xl lg:text-3xl font-bold text-gray-800 leading-tight">
                    {{ post.title }}
                  </h1>
                  
                  <!-- Enhanced Badges -->
                  <div class="flex flex-wrap items-center mt-3 gap-3">
                    <span 
                      v-if="post.featured" 
                      class="inline-flex items-center bg-gradient-to-r from-amber-500 to-amber-600 text-white text-xs px-3 py-1.5 rounded-full font-medium shadow-sm animate-pulse-subtle"
                    >
                      <UIcon name="i-heroicons-star" class="size-3.5 mr-1.5" />
                      Featured
                    </span>
                    <span 
                      v-if="post.status === 'sold'" 
                      class="inline-flex items-center bg-blue-500 text-white text-xs px-3 py-1.5 rounded-full font-medium shadow-sm"
                    >
                      <UIcon name="i-heroicons-check-circle" class="size-3.5 mr-1.5" />
                      Sold
                    </span>
                    <span class="inline-flex items-center bg-gray-100 text-gray-700 text-xs px-3 py-1.5 rounded-full">
                      <UIcon name="i-heroicons-calendar" class="size-3.5 mr-1.5" />
                      {{ formatDate(post.created_at) }}
                    </span>
                    
                    <!-- Category Badge -->
                    <span class="inline-flex items-center bg-primary-50 text-primary-700 text-xs px-3 py-1.5 rounded-full">
                      <UIcon name="i-heroicons-tag" class="size-3.5 mr-1.5" />
                      {{ post.category_details?.name || 'General' }}
                    </span>
                  </div>
                </div>
                
                <!-- Enhanced Price Container -->
                <div class="price-container slide-up-fade-in" style="--delay: 200ms">
                  <div class="price-tag py-4 px-6 bg-gradient-to-br from-primary-50 to-primary-100 border border-primary-200 rounded-lg shadow-sm relative overflow-hidden group">
                    <!-- Decorative price effect -->
                    <div class="absolute inset-0 bg-gradient-to-r from-primary-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-700"></div>
                    
                    <!-- Price Value -->
                    <div class="text-2xl md:text-3xl font-bold text-primary-600 relative">
                      <span v-if="post.negotiable && !post.price">Negotiable</span>
                      <span v-else-if="post.price" class="price-highlight">৳{{ formatPrice(post.price) }}</span>
                      <span v-else>Contact for Price</span>
                    </div>
                    
                    <!-- Negotiable Label -->
                    <div
                      v-if="post.negotiable && post.price"
                      class="mt-1 text-sm text-primary-700 font-medium flex items-center"
                    >
                      <UIcon name="i-heroicons-currency-dollar" class="size-4 mr-1.5" />
                      Price Negotiable
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
            <!-- Professional Images Gallery Card with Advanced Design -->
          <div class="bg-white rounded-xl shadow-md overflow-hidden mb-6 slide-up-fade-in" style="--delay: 300ms">
            <!-- Gallery Header -->
            <div class="bg-gray-50 border-b border-gray-100 px-5 py-3 flex items-center justify-between">
              <h3 class="font-medium text-gray-700 flex items-center">
                <UIcon name="i-heroicons-photo" class="size-4 mr-2" />
                Product Gallery
              </h3>
              <span class="text-xs text-gray-500">
                {{ post.images?.length || 0 }} Photos
              </span>
            </div>
            
            <!-- Main Image with Enhanced Gallery Experience -->
            <div
              class="relative h-[400px] md:h-[500px] overflow-hidden bg-gradient-to-b from-gray-50 to-white"
            >
              <!-- Image Loading Placeholder with Skeleton Animation -->
              <div
                v-if="imageLoading"
                class="absolute inset-0 flex items-center justify-center bg-gray-50 z-10"
              >
                <div class="flex flex-col items-center space-y-4">
                  <div class="animate-pulse-slow">
                    <div class="w-20 h-20 rounded-full bg-gray-200/70 flex items-center justify-center">
                      <UIcon
                        name="i-heroicons-photo"
                        class="h-10 w-10 text-gray-300"
                      />
                    </div>
                  </div>
                  <div class="w-32 h-2 bg-gray-200 rounded-full animate-pulse"></div>
                </div>
              </div>

              <!-- Main Large Image with Hover Effect -->
              <div class="h-full w-full flex items-center justify-center overflow-hidden image-container">
                <img
                  :src="selectedImage || getMainImage()"
                  :alt="post.title"
                  class="w-full h-full object-contain transition-all duration-500 hover:scale-[1.02]"
                  :class="{
                    'opacity-0': imageLoading,
                    'opacity-100': !imageLoading,
                  }"
                  @click="openLightbox = true"
                  @load="imageLoading = false"
                  @error="handleImageError"
                />
                
                <!-- Watermark/Overlay Effect -->
                <div class="absolute inset-0 pointer-events-none bg-gradient-to-t from-black/5 via-transparent to-transparent"></div>
              </div>

              <!-- Enhanced Image Navigation Controls -->
              <div
                v-if="post.images && post.images.length > 1"
                class="absolute inset-x-0 top-1/2 transform -translate-y-1/2 flex justify-between px-4 z-10"
              >
                <button
                  @click.stop="navigateImage('prev')"
                  class="rounded-full p-2 bg-white/80 dark:bg-gray-800/80 text-gray-700 dark:text-gray-300 hover:bg-white dark:hover:bg-gray-800 shadow-sm backdrop-blur-sm transition-all hover:scale-105"
                  aria-label="Previous image"
                >
                  <UIcon name="i-heroicons-chevron-left" class="h-6 w-6" />
                </button>
                <button
                  @click.stop="navigateImage('next')"
                  class="rounded-full p-2 bg-white/80 dark:bg-gray-800/80 text-gray-700 dark:text-gray-300 hover:bg-white dark:hover:bg-gray-800 shadow-sm backdrop-blur-sm transition-all hover:scale-105"
                  aria-label="Next image"
                >
                  <UIcon name="i-heroicons-chevron-right" class="h-6 w-6" />
                </button>
              </div>              <!-- Enhanced Status Badges with Modern Design -->
              <div class="absolute top-4 right-4 flex flex-col gap-2 z-10">
                <div v-if="post.status === 'sold'" class="badge-container animate-fade-in" style="--delay: 400ms">
                  <span
                    class="relative inline-flex items-center gap-1 bg-gradient-to-r from-blue-600 to-blue-500 text-white text-sm font-medium px-4 py-1.5 rounded-md shadow-lg"
                  >
                    <span class="flex w-2 h-2 relative mr-0.5">
                      <span
                        class="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"
                      ></span>
                      <span
                        class="relative inline-flex rounded-full h-2 w-2 bg-white"
                      ></span>
                    </span>
                    SOLD
                  </span>
                </div>
                <div v-if="post.featured" class="badge-container animate-fade-in" style="--delay: 500ms">
                  <span
                    class="bg-gradient-to-r from-amber-500 to-orange-500 text-white text-sm font-medium px-4 py-1.5 rounded-md shadow-lg flex items-center gap-1"
                  >
                    <UIcon name="i-heroicons-star" class="h-3.5 w-3.5 animate-pulse-subtle" />
                    FEATURED
                  </span>
                </div>
              </div>              <!-- Enhanced Zoom Control -->
              <button
                @click.stop="openLightbox = true"
                class="absolute bottom-4 right-4 rounded-full p-3 bg-white/90 text-gray-700 hover:bg-white hover:text-primary-600 shadow-lg border border-gray-100 backdrop-blur-md transition-all hover:scale-110 group"
                aria-label="Zoom image"
                title="View fullscreen"
              >
                <UIcon
                  name="i-heroicons-magnifying-glass-plus"
                  class="h-5 w-5 group-hover:scale-110 transition-transform"
                />
                <span class="absolute -top-8 right-0 bg-black/75 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap backdrop-blur-sm">
                  View fullscreen
                </span>
              </button>              <!-- Enhanced Image Counter -->
              <div
                v-if="post.images && post.images.length > 1"
                class="absolute bottom-4 left-4 bg-black/60 text-white text-xs px-3 py-1.5 rounded-md backdrop-blur-md shadow-lg flex items-center space-x-1 animate-fade-in" style="--delay: 600ms"
              >
                <UIcon name="i-heroicons-photo" class="h-3.5 w-3.5 mr-1.5 text-white/80" />
                <span class="font-medium">{{ currentImageIndex + 1 }}</span>
                <span class="text-white/80">/</span>
                <span>{{ post.images.length }}</span>
              </div>
            </div>            <!-- Professional Thumbnails Gallery with Enhanced Scroll -->
            <div
              v-if="post.images && post.images.length > 1"
              class="relative bg-gray-50 py-4 px-5 border-t border-gray-100"
            >
              <!-- Improved Shadow indicators for scroll -->
              <div
                class="absolute left-0 top-0 bottom-0 w-12 bg-gradient-to-r from-gray-50 via-gray-50/80 to-transparent z-10 pointer-events-none"
              ></div>
              <div
                class="absolute right-0 top-0 bottom-0 w-12 bg-gradient-to-l from-gray-50 via-gray-50/80 to-transparent z-10 pointer-events-none"
              ></div>

              <!-- Enhanced Thumbnails Container with Horizontal Scroll -->
              <div class="relative">
                <!-- Thumbnail Navigation Buttons -->
                <button 
                  @click="scrollThumbnails('left')" 
                  class="absolute left-0 top-1/2 -translate-y-1/2 z-20 size-8 bg-white shadow-md rounded-full flex items-center justify-center text-gray-700 hover:text-primary-600 hover:scale-105 transition-all border border-gray-200"
                >
                  <UIcon name="i-heroicons-chevron-left" class="size-4" />
                </button>
                
                <button 
                  @click="scrollThumbnails('right')" 
                  class="absolute right-0 top-1/2 -translate-y-1/2 z-20 size-8 bg-white shadow-md rounded-full flex items-center justify-center text-gray-700 hover:text-primary-600 hover:scale-105 transition-all border border-gray-200"
                >
                  <UIcon name="i-heroicons-chevron-right" class="size-4" />
                </button>
                
                <!-- Thumbnails Container -->
                <div
                  ref="thumbnailsContainer"
                  class="flex space-x-3 overflow-x-auto thumbnails-container pb-1 px-4 pt-1 scroll-smooth hide-scrollbar"
                >
                  <button
                    v-for="(image, index) in post.images"
                    :key="index"
                    class="flex-shrink-0 cursor-pointer transition-all duration-300 transform rounded-md overflow-hidden border-2 hover:shadow-md"
                    :class="{
                      'border-primary scale-110 shadow-lg ring-2 ring-primary-100':
                        selectedImage === getImageSrc(image),
                      'border-transparent hover:border-gray-300':
                        selectedImage !== getImageSrc(image),
                    }"
                    @click="selectImage(image, index)"
                  >
                    <div class="w-16 h-16 relative thumb-hover-effect">
                      <img
                        :src="getImageSrc(image)"
                        :alt="`${post.title} thumbnail ${index + 1}`"
                        class="w-full h-full object-cover transition-transform duration-300"
                        loading="lazy"
                      />
                      <div class="absolute inset-0 bg-black/0 hover:bg-black/10 transition-colors"></div>
                    </div>
                  </button>
                </div>
              </div>
            </div>

            <!-- No Images Message - Improved -->
            <div
              v-if="!post.images || post.images.length === 0"
              class="text-center py-6 bg-gray-50 dark:bg-gray-900/20"
            >
              <UIcon
                name="i-heroicons-photo"
                class="h-12 w-12 text-gray-400 dark:text-gray-500 mx-auto"
              />
              <p class="text-gray-500 dark:text-gray-500 mt-2">
                No images available for this listing
              </p>
            </div>
          </div>          <!-- Enhanced Location and Posted Date Section -->
          <div class="bg-white rounded-lg shadow-md border border-gray-100 p-0 mb-5 overflow-hidden slide-up-fade-in" style="--delay: 400ms">
            <div class="grid grid-cols-1 md:grid-cols-2 divide-y md:divide-y-0 md:divide-x divide-gray-100">
              <!-- Location Section -->
              <div v-if="post.area || post.district" class="p-4 flex items-center hover:bg-gray-50 transition-colors group">
                <div class="size-10 rounded-full bg-primary-50 flex items-center justify-center mr-3 group-hover:bg-primary-100 transition-colors">
                  <UIcon
                    name="i-heroicons-map-pin"
                    class="size-5 text-primary-600 flex-shrink-0"
                  />
                </div>
                <div>
                  <div class="text-xs text-gray-500 uppercase font-medium tracking-wider mb-0.5">Location</div>
                  <p class="text-gray-700 font-medium">
                    {{ post.area }}{{ post.area && post.district ? ', ' : '' }}{{ post.district }}
                  </p>
                </div>
              </div>
              
              <!-- Posted Date Section -->
              <div class="p-4 flex items-center hover:bg-gray-50 transition-colors group">
                <div class="size-10 rounded-full bg-primary-50 flex items-center justify-center mr-3 group-hover:bg-primary-100 transition-colors">
                  <UIcon
                    name="i-heroicons-calendar"
                    class="size-5 text-primary-600 flex-shrink-0"
                  />
                </div>
                <div>
                  <div class="text-xs text-gray-500 uppercase font-medium tracking-wider mb-0.5">Posted</div>
                  <p class="text-gray-700 font-medium">
                    {{ formatDate(post.created_at) }}
                    <span class="text-xs text-gray-500 ml-1">({{ formatDateFull(post.created_at) }})</span>
                  </p>
                </div>
              </div>
            </div>
          </div>          <!-- Enhanced Product Details Card -->
          <div
            class="bg-white rounded-lg shadow-md border border-gray-100 overflow-hidden mb-6 slide-up-fade-in" style="--delay: 500ms"
          >
            <!-- Card Header -->
            <div class="bg-gray-50 px-6 py-4 border-b border-gray-100">
              <h3 class="text-lg font-medium text-gray-800 flex items-center">
                <UIcon name="i-heroicons-clipboard-document-list" class="size-5 mr-2 text-primary-600" />
                Product Specifications
              </h3>
            </div>
            
            <!-- Post Details Table with Enhanced Design -->
            <div class="p-6">
              <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-y-6 gap-x-8 mb-6">
                <!-- Category with Enhanced Style -->
                <div class="flex items-center spec-item group">
                  <div class="size-9 rounded-full bg-gray-50 flex items-center justify-center mr-3 group-hover:bg-primary-50 transition-colors border border-gray-100">
                    <UIcon
                      name="i-heroicons-tag"
                      class="size-4.5 text-gray-500 group-hover:text-primary-600 flex-shrink-0 transition-colors"
                    />
                  </div>
                  <div>
                    <div class="text-xs text-gray-500 uppercase tracking-wider mb-0.5 font-medium">Category</div>
                    <p class="text-gray-800 font-medium truncate">
                      {{ post.category_details.name }}
                    </p>
                  </div>
                </div>              <!-- Enhanced Condition Display -->
              <div class="flex items-center spec-item group">
                <div class="size-9 rounded-full bg-gray-50 flex items-center justify-center mr-3 group-hover:bg-primary-50 transition-colors border border-gray-100">
                  <UIcon
                    name="i-heroicons-sparkles"
                    class="size-4.5 text-gray-500 group-hover:text-primary-600 flex-shrink-0 transition-colors"
                  />
                </div>
                <div>
                  <div class="text-xs text-gray-500 uppercase tracking-wider mb-0.5 font-medium">Condition</div>
                  <p class="text-gray-800 font-medium truncate">
                    {{ getConditionLabel(post.condition) }}
                  </p>
                </div>
              </div>

              <!-- Additional property for 3rd grid spot -->
              <template v-if="post.category === 1 && post.property_type">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-home"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">
                    {{ propertyTypeLabel(post.property_type) }}
                  </p>
                </div>
              </template>
              <template v-else-if="post.category === 2 && post.make">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-truck"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">{{ post.make }}</p>
                </div>
              </template>
              <template v-else-if="post.category === 3 && post.brand">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-building-storefront"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">{{ post.brand }}</p>
                </div>
              </template>

              <!-- Remaining property-specific fields -->
              <template v-if="post.category === 1">
                <!-- Skip property_type since it's used above -->
                <div v-if="post.size" class="flex items-center">
                  <UIcon
                    name="i-heroicons-square-3-stack-3d"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">
                    {{ post.size }} {{ post.unit || "sqft" }}
                  </p>
                </div>

                <div v-if="post.bedrooms" class="flex items-center">
                  <UIcon
                    name="i-heroicons-bed"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">
                    {{ post.bedrooms }}
                  </p>
                </div>

                <div v-if="post.bathrooms" class="flex items-center">
                  <UIcon
                    name="i-heroicons-beaker"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">
                    {{ post.bathrooms }}
                  </p>
                </div>
              </template>

              <!-- Vehicle-specific fields -->
              <template v-if="post.category === 2">
                <!-- Skip make since it's used above -->
                <div v-if="post.model" class="flex items-center">
                  <UIcon
                    name="i-heroicons-tag"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">{{ post.model }}</p>
                </div>

                <div v-if="post.year" class="flex items-center">
                  <UIcon
                    name="i-heroicons-calendar"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">{{ post.year }}</p>
                </div>

                <div v-if="post.mileage" class="flex items-center">
                  <UIcon
                    name="i-heroicons-arrow-path-rounded-square"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">
                    {{ post.mileage }} {{ post.mileage_unit || "km" }}
                  </p>
                </div>
              </template>

              <!-- Electronics-specific fields -->
              <template v-if="post.category === 3">
                <!-- Skip brand since it's used above -->
                <div v-if="post.model" class="flex items-center">
                  <UIcon
                    name="i-heroicons-tag"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">{{ post.model }}</p>
                </div>

                <div v-if="post.warranty" class="flex items-center">
                  <UIcon
                    name="i-heroicons-shield-check"
                    class="size-5 mr-2.5 text-gray-500 flex-shrink-0"
                  />
                  <p class="text-gray-700 font-medium truncate">
                    {{ warrantyLabel(post.warranty) }}
                  </p>
                </div>
              </template>
            </div>

            <!-- Tags -->
            <div v-if="post.tags && post.tags.length > 0" class="mb-6">
              <h3 class="text-gray-700 font-medium mb-2">Tags</h3>
              <div class="flex flex-wrap gap-2">
                <UBadge
                  v-for="tag in post.tags"
                  :key="tag"
                  color="gray"
                  variant="outline"
                  class="px-2.5 py-1 font-medium"
                >
                  {{ tag }}
                </UBadge>
              </div>
            </div>

            <!-- Description Section -->
            <div class="border-t border-gray-100 pt-6">
              <h3 class="text-lg font-medium text-gray-700 mb-4">
                Description
              </h3>
              <div
                class="prose max-w-none text-gray-500"
                v-html="post.description"
              ></div>
            </div>
          </div>

          <!-- Map Location Card (if coordinates available) -->
          <div
            v-if="post.latitude && post.longitude"
            class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-6"
          >
            <h3 class="text-lg font-medium text-gray-700 mb-4">
              <UIcon name="i-heroicons-map" class="size-5 mr-2 inline-block" />
              Location
            </h3>
            <div class="h-80 bg-gray-100 rounded-lg overflow-hidden">
              <!-- Map component would be added here -->
              <div class="h-full w-full flex items-center justify-center">
                <span class="text-gray-500">Map would be displayed here</span>
              </div>
            </div>
          </div>          <!-- Enhanced Safety Tips Card -->
          <div
            class="bg-gradient-to-br from-amber-50 to-amber-100/50 rounded-lg shadow-md border border-amber-200 overflow-hidden slide-up-fade-in" style="--delay: 700ms"
          >
            <!-- Safety Tips Header -->
            <div class="bg-amber-100/50 border-b border-amber-200 px-6 py-4">
              <h3 class="text-amber-800 font-medium flex items-center">
                <UIcon
                  name="i-heroicons-shield-exclamation"
                  class="size-5 mr-2.5"
                />
                Safety Tips for Buyers
              </h3>
            </div>
            
            <!-- Safety Tips Content -->
            <div class="p-6">
              <ul class="space-y-3 safety-tips">
                <li class="flex items-start hover:bg-amber-100/30 p-2 rounded-md transition-colors">
                  <UIcon name="i-heroicons-check-circle" class="size-5 mr-2.5 text-amber-700 flex-shrink-0 mt-0.5" />
                  <span class="text-amber-800">Meet in a public, well-lit place</span>
                </li>
                <li class="flex items-start hover:bg-amber-100/30 p-2 rounded-md transition-colors">
                  <UIcon name="i-heroicons-check-circle" class="size-5 mr-2.5 text-amber-700 flex-shrink-0 mt-0.5" />
                  <span class="text-amber-800">Verify the item before making payment</span>
                </li>
                <li class="flex items-start hover:bg-amber-100/30 p-2 rounded-md transition-colors">
                  <UIcon name="i-heroicons-exclamation-triangle" class="size-5 mr-2.5 text-amber-700 flex-shrink-0 mt-0.5" />
                  <span class="text-amber-800">Don't send money in advance</span>
                </li>
                <li class="flex items-start hover:bg-amber-100/30 p-2 rounded-md transition-colors">
                  <UIcon name="i-heroicons-check-circle" class="size-5 mr-2.5 text-amber-700 flex-shrink-0 mt-0.5" />
                  <span class="text-amber-800">Use secure payment methods</span>
                </li>
                <li class="flex items-start hover:bg-amber-100/30 p-2 rounded-md transition-colors">
                  <UIcon name="i-heroicons-check-circle" class="size-5 mr-2.5 text-amber-700 flex-shrink-0 mt-0.5" />
                  <span class="text-amber-800">Bring a friend when meeting the seller</span>
                </li>
                <li class="flex items-start hover:bg-amber-100/30 p-2 rounded-md transition-colors">
                  <UIcon name="i-heroicons-flag" class="size-5 mr-2.5 text-amber-700 flex-shrink-0 mt-0.5" />
                  <span class="text-amber-800">Report suspicious behavior to us</span>
                </li>
              </ul>
              
              <!-- Safety Verification Link -->
              <div class="mt-5 pt-4 border-t border-amber-200/50 text-center">
                <a href="#" class="text-amber-800 hover:text-amber-900 text-sm font-medium inline-flex items-center transition-colors">
                  <UIcon name="i-heroicons-information-circle" class="size-4 mr-1.5" />
                  Learn more about safe trading
                </a>
              </div>
            </div>
          </div>
        </div>        <!-- Right Column - Sidebar -->
        <div class="lg:col-span-1">
          <!-- Professional Seller Information Card -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-100 mb-6 seller-card overflow-hidden">
            <!-- Card Header with Premium Style -->
            <div class="bg-gradient-to-r from-gray-50 to-white border-b border-gray-100 p-5">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-medium text-gray-800">
                  Seller Information
                </h3>
                <span 
                  v-if="post.seller?.is_pro"
                  class="badge-pro flex items-center bg-primary-50 text-primary-700 border border-primary-200 px-2.5 py-1 rounded-full"
                >
                  <UIcon name="i-heroicons-check-badge" class="size-3.5 mr-1" />
                  <span class="text-xs font-medium">Pro Seller</span>
                </span>
              </div>
            </div>

            <!-- Seller Profile Content -->
            <div class="p-5">
              <!-- Seller Profile Header -->
              <div class="flex items-center mb-5">
                <div class="mr-4 relative">
                  <div
                    class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden border border-gray-200 shadow-sm seller-avatar"
                  >
                    <UIcon
                      v-if="!post.seller?.profile_picture"
                      name="i-heroicons-building-storefront"
                      class="size-9 text-gray-500"
                    />
                    <img
                      v-else
                      :src="post.seller.profile_picture"
                      :alt="post.seller?.name || 'Seller'"
                      class="w-full h-full object-cover"
                    />
                  </div>
                  <div v-if="post.seller?.is_verified" class="absolute -bottom-1 -right-1 bg-blue-500 rounded-full p-1 border-2 border-white">
                    <UIcon name="i-heroicons-check" class="size-2.5 text-white" />
                  </div>
                </div>
                <div>
                  <h4 class="text-lg font-semibold text-gray-800 mb-0.5">
                    {{ post.user_name || "Anonymous Seller" }}
                  </h4>
                  <div class="flex items-center text-sm text-gray-500">
                    <UIcon name="i-heroicons-map-pin" class="size-3.5 mr-1.5" />
                    <span>{{ post.seller?.location || post.location || "Location not provided" }}</span>
                  </div>
                </div>
              </div>
              
              <!-- Divider -->
              <div class="h-px bg-gradient-to-r from-transparent via-gray-200 to-transparent my-4"></div>
              
              <!-- Contact Information -->
              <div v-if="post.phone" class="mb-5">
                <div class="flex flex-col space-y-2">
                  <label class="text-xs font-medium text-gray-500 uppercase tracking-wider">Contact Number</label>
                  <div class="flex items-center justify-between bg-gray-50 border border-gray-100 rounded-md p-2.5">
                    <div class="flex items-center">
                      <UIcon name="i-heroicons-phone" class="size-4.5 mr-3 text-primary-600" />
                      <div v-if="showPhone" class="phone-number-container">
                        <a :href="`tel:${post.phone}`" class="text-gray-800 font-medium hover:text-primary-700 phone-number">
                          {{ post.phone }}
                        </a>
                      </div>
                      <div v-else class="phone-number-container">
                        <span class="text-gray-700 font-medium">•••• •••• {{ post.phone.slice(-4) }}</span>
                        <button 
                          @click="showPhone = true"
                          class="ml-2 text-xs text-primary-600 hover:text-primary-800 font-medium"
                        >
                          Show
                        </button>
                      </div>
                    </div>
                    
                    <button 
                      @click="copyPhoneNumber"
                      class="flex items-center bg-white hover:bg-gray-50 text-gray-700 border border-gray-200 px-3 py-1.5 rounded-md transition-all copy-btn shadow-sm"
                    >
                      <UIcon name="i-heroicons-clipboard-document" class="size-4 mr-1.5" />
                      <span class="text-xs font-medium">Copy</span>
                    </button>
                  </div>
                </div>
              </div>

              <!-- Contact Buttons -->
              <div class="space-y-3">
                <!-- Message Button -->
                <UButton
                  v-if="post.allows_messaging"
                  color="primary"
                  variant="solid"
                  class="w-full justify-center py-2.5 font-medium"
                  icon="i-heroicons-chat-bubble-oval-left-ellipsis"
                  @click="showContactForm = true"
                >
                  Message Seller
                </UButton>

                <!-- See More Products Button -->
                <UButton
                  color="gray"
                  variant="soft"
                  class="w-full justify-center py-2.5 font-medium"
                  icon="i-heroicons-shopping-bag"
                  :to="`/sale/seller/${post.user_id || post.seller?.id || ''}`"
                >
                  More Products from Seller
                </UButton>
                
                <!-- Report Button as Text Link -->
                <div class="mt-5 text-center">
                  <button
                    class="text-gray-400 text-xs font-medium hover:text-red-500 transition-colors flex items-center justify-center w-full"
                    @click="showReportModal = true"
                  >
                    <UIcon name="i-heroicons-flag" class="size-3.5 mr-1.5" />
                    Report this listing
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Related Posts Card -->
          <div
            class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-6"
          >
            <h3 class="text-lg font-medium text-gray-700 mb-4">
              Similar Listings
            </h3>

            <div v-if="loading" class="animate-pulse space-y-4">
              <div v-for="i in 3" :key="i" class="flex space-x-3">
                <div class="w-16 h-16 bg-gray-200 rounded"></div>
                <div class="flex-1 space-y-2">
                  <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                  <div class="h-4 bg-gray-200 rounded w-1/2"></div>
                </div>
              </div>
            </div>

            <div
              v-else-if="relatedPosts.length === 0"
              class="text-gray-500 text-sm italic text-center py-4"
            >
              No similar listings found
            </div>

            <div v-else class="space-y-4">
              <div
                v-for="relatedPost in relatedPosts"
                :key="relatedPost.id"
                class="group"
              >
                <NuxtLink
                  :to="`/sale/${relatedPost.slug}`"
                  class="flex space-x-3"
                >
                  <div
                    class="w-16 h-16 rounded-md overflow-hidden flex-shrink-0 border border-gray-100"
                  >
                    <img
                      :src="getMainImage(relatedPost)"
                      :alt="relatedPost.title"
                      class="w-full h-full object-cover transition-transform group-hover:scale-110"
                    />
                  </div>
                  <div class="flex-1">
                    <h4
                      class="text-sm font-medium text-gray-700 group-hover:text-primary transition-colors line-clamp-2"
                    >
                      {{ relatedPost.title }}
                    </h4>
                    <p class="text-primary text-sm font-medium mt-1">
                      <span v-if="relatedPost.negotiable && !relatedPost.price"
                        >Negotiable</span
                      >
                      <span v-else-if="relatedPost.price"
                        >৳{{ formatPrice(relatedPost.price) }}</span
                      >
                      <span v-else>Contact for Price</span>
                    </p>
                  </div>
                </NuxtLink>
              </div>
            </div>
          </div>

          <!-- Safety Verification Badge -->
          <div
            class="bg-gradient-to-r from-green-50 to-teal-50 rounded-lg shadow-sm border border-green-100 p-5 mb-6 text-center"
          >
            <UIcon
              name="i-heroicons-shield-check"
              class="size-8 mx-auto text-green-500 mb-2"
            />
            <h4 class="font-medium text-green-800 mb-1">Safety Verified</h4>
            <p class="text-xs text-green-600">
              This listing has been verified by our team and meets our community
              standards.
            </p>
          </div>
        </div>
      </div>
      </div>
    </UContainer>

    <!-- Enhanced Image Lightbox Modal -->
    <UModal
      v-model="openLightbox"
      :ui="{
        container: 'flex min-h-screen items-center justify-center p-0 md:p-4',
        overlay: 'bg-black/90',
        width: 'max-w-full md:max-w-6xl',
        base: 'bg-transparent w-full',
      }"
    >
      <div class="relative p-0 md:p-4">
        <!-- Close Button -->
        <button
          class="absolute top-4 right-4 text-white/80 z-30 bg-black/50 rounded-full p-2 hover:bg-black hover:text-white transition-all duration-300"
          @click="openLightbox = false"
          aria-label="Close lightbox"
        >
          <UIcon name="i-heroicons-x-mark" class="size-5" />
        </button>

        <!-- Navigation Controls -->
        <div
          v-if="post.images && post.images.length > 1"
          class="absolute inset-x-0 top-1/2 transform -translate-y-1/2 flex justify-between px-4 z-20"
        >
          <button
            @click.stop="navigateImage('prev')"
            class="rounded-full p-3 bg-black/50 text-white/80 hover:bg-black/70 hover:text-white transition-all hover:scale-105"
            aria-label="Previous image"
          >
            <UIcon name="i-heroicons-chevron-left" class="h-6 w-6" />
          </button>
          <button
            @click.stop="navigateImage('next')"
            class="rounded-full p-3 bg-black/50 text-white/80 hover:bg-black/70 hover:text-white transition-all hover:scale-105"
            aria-label="Next image"
          >
            <UIcon name="i-heroicons-chevron-right" class="h-6 w-6" />
          </button>
        </div>

        <!-- Main Image with Zoom Functionality -->
        <div
          class="lightbox-image-container max-h-[80vh] flex items-center justify-center"
          @wheel="handleZoom"
          @mousedown="startPan"
          @mousemove="pan"
          @mouseup="endPan"
          @mouseleave="endPan"
        >
          <img
            ref="lightboxImage"
            :src="selectedImage || getMainImage()"
            :alt="post.title"
            class="max-w-full max-h-[80vh] object-contain transition-transform duration-300 ease-out"
            :style="{
              transform: `scale(${zoomLevel}) translate(${panPosition.x}px, ${panPosition.y}px)`,
            }"
            @dblclick="toggleZoom"
          />
        </div>

        <!-- Zoom Controls -->
        <div class="absolute bottom-4 left-4 flex items-center gap-2 z-20">
          <button
            @click="zoomOut"
            class="rounded-full p-2 bg-black/50 text-white hover:bg-black/70 transition-opacity"
            :disabled="zoomLevel <= 1"
            :class="{ 'opacity-50': zoomLevel <= 1 }"
          >
            <UIcon name="i-heroicons-minus" class="h-4 w-4" />
          </button>
          <span class="bg-black/50 px-2 py-1 rounded text-xs text-white"
            >{{ Math.round(zoomLevel * 100) }}%</span
          >
          <button
            @click="zoomIn"
            class="rounded-full p-2 bg-black/50 text-white hover:bg-black/70 transition-opacity"
            :disabled="zoomLevel >= 3"
            :class="{ 'opacity-50': zoomLevel >= 3 }"
          >
            <UIcon name="i-heroicons-plus" class="h-4 w-4" />
          </button>
          <button
            @click="resetZoom"
            class="rounded-full p-2 bg-black/50 text-white hover:bg-black/70 transition-opacity ml-1"
          >
            <UIcon name="i-heroicons-arrow-path" class="h-4 w-4" />
          </button>
        </div>

        <!-- Enhanced Thumbnails for Lightbox -->
        <div
          v-if="post.images && post.images.length > 1"
          class="flex justify-center mt-4 gap-2 overflow-x-auto lightbox-thumbnails pb-2"
        >
          <button
            v-for="(image, index) in post.images"
            :key="index"
            class="flex-shrink-0 transition-all duration-200 rounded overflow-hidden border-2"
            :class="{
              'border-primary opacity-100 scale-110':
                selectedImage === getImageSrc(image),
              'border-transparent opacity-70 hover:opacity-100':
                selectedImage !== getImageSrc(image),
            }"
            @click="selectImage(image, index)"
          >
            <div class="w-14 h-14 relative">
              <img
                :src="getImageSrc(image)"
                :alt="`${post.title} thumbnail ${index + 1}`"
                class="w-full h-full object-cover"
                loading="lazy"
              />
            </div>
          </button>
        </div>
      </div>
    </UModal>

    <!-- Contact Form Modal -->
    <UModal v-model="showContactForm" :ui="{ width: 'max-w-md' }">
      <UCard>
        <template #header>
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-medium text-gray-700">Message Seller</h3>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark"
              @click="showContactForm = false"
            />
          </div>
        </template>

        <form @submit.prevent="sendMessage">
          <div class="space-y-4">
            <UFormGroup label="Your Name" required>
              <UInput
                v-model="contactForm.name"
                placeholder="Enter your name"
              />
            </UFormGroup>

            <UFormGroup label="Your Email" required>
              <UInput
                v-model="contactForm.email"
                placeholder="Enter your email"
                type="email"
              />
            </UFormGroup>

            <UFormGroup label="Phone Number">
              <UInput
                v-model="contactForm.phone"
                placeholder="Enter your phone number (optional)"
              />
            </UFormGroup>

            <UFormGroup label="Message" required>
              <UTextarea
                v-model="contactForm.message"
                placeholder="Type your message here..."
                :rows="4"
                :ui="{ base: 'w-full' }"
                autofocus
              ></UTextarea>
            </UFormGroup>
          </div>

          <div class="mt-6">
            <UButton type="submit" color="primary" block :loading="sending">
              {{ sending ? "Sending..." : "Send Message" }}
            </UButton>
          </div>
        </form>
      </UCard>
    </UModal>

    <!-- Report Modal -->
    <UModal v-model="showReportModal" :ui="{ width: 'max-w-md' }">
      <UCard>
        <template #header>
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-medium text-gray-700">Report Listing</h3>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark"
              @click="showReportModal = false"
            />
          </div>
        </template>

        <form @submit.prevent="reportPost">
          <div class="space-y-4">
            <UFormGroup label="Reason for Report" required>
              <URadio
                v-model="reportForm.reason"
                value="inappropriate"
                label="Inappropriate content"
              />
              <URadio
                v-model="reportForm.reason"
                value="fraud"
                label="Fraudulent listing"
              />
              <URadio
                v-model="reportForm.reason"
                value="duplicate"
                label="Duplicate listing"
              />
              <URadio
                v-model="reportForm.reason"
                value="misrepresentation"
                label="Misrepresentation"
              />
              <URadio v-model="reportForm.reason" value="other" label="Other" />
            </UFormGroup>

            <UFormGroup label="Additional Details">
              <UTextarea
                v-model="reportForm.details"
                placeholder="Please provide any additional details..."
                :rows="3"
                :ui="{ base: 'w-full' }"
              ></UTextarea>
            </UFormGroup>
          </div>

          <div class="mt-6">
            <UButton type="submit" color="red" block :loading="reporting">
              {{ reporting ? "Submitting..." : "Submit Report" }}
            </UButton>
          </div>
        </form>
      </UCard>
    </UModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import { useRoute } from "vue-router";
import { useApi } from "~/composables/useApi";
import { useNotifications } from "~/composables/useNotifications";

// API and notifications
const { get, postData } = useApi();
const { showNotification } = useNotifications();
const route = useRoute();

// Get the slug from the route params
const slug = computed(() => route.params.slug);

// Component state
const loading = ref(true);
const error = ref(false);
const post = ref({});
const relatedPosts = ref([]);
const selectedImage = ref(null);
const openLightbox = ref(false);
const showContactForm = ref(false);
const showReportModal = ref(false);
const copying = ref(false);
const sending = ref(false);
const reporting = ref(false);
const imageLoading = ref(true);
const currentImageIndex = ref(0);
const zoomLevel = ref(1);
const panPosition = ref({ x: 0, y: 0 });
let isPanning = false;
let startPanPosition = { x: 0, y: 0 };
const showPhone = ref(false);

// Form state
const contactForm = ref({
  name: "",
  email: "",
  phone: "",
  message: "",
});

const reportForm = ref({
  reason: "inappropriate",
  details: "",
});

// Categories (same as in for-sale.vue)
const categories = ref([
  { id: 1, name: "Properties" },
  { id: 2, name: "Vehicles" },
  { id: 3, name: "Electronics" },
  { id: 4, name: "Sports" },
  { id: 5, name: "B2B" },
  { id: 6, name: "Others" },
]);

// Conditions
const conditions = [
  { label: "Brand New", value: "brand-new" },
  { label: "Like New", value: "like-new" },
  { label: "Good", value: "good" },
  { label: "Fair", value: "fair" },
  { label: "For Parts", value: "for-parts" },
];

// Fetch post data on component mount
onMounted(async () => {
  await fetchPostDetails();
});

// Get post details from API
async function fetchPostDetails() {
  loading.value = true;
  error.value = false;

  try {
    // API request to get post details
    const response = await get(`/sale/posts/${slug.value}/`);

    if (response && response.data) {
      post.value = response.data;

      // Set default selected image
      if (post.value.images && post.value.images.length > 0) {
        // Find the main image or use the first one
        const mainImage =
          post.value.images.find((img) => img.is_main) || post.value.images[0];
        selectedImage.value = getImageSrc(mainImage);
        currentImageIndex.value = post.value.images.indexOf(mainImage);
      }

      // Increment view count in background
      incrementViewCount();

      // Fetch related posts
      fetchRelatedPosts();
    } else {
      error.value = true;
    }
  } catch (err) {
    console.error("Error fetching post details:", err);
    error.value = true;
  } finally {
    loading.value = false;
  }
}

// Fetch related posts based on category and exclude current post
async function fetchRelatedPosts() {
  try {
    const response = await get("/sale-posts/", {
      params: {
        category: post.value.category,
        exclude: post.value.id,
        page_size: 3,
        status: "active",
      },
    });

    if (response && response.data) {
      // Handle paginated response
      if (response.data.results && Array.isArray(response.data.results)) {
        relatedPosts.value = response.data.results;
      }
      // Handle non-paginated response
      else if (Array.isArray(response.data)) {
        relatedPosts.value = response.data;
      }
    }
  } catch (err) {
    console.error("Error fetching related posts:", err);
    relatedPosts.value = [];
  }
}

// Increment view count
async function incrementViewCount() {
  try {
    await postData(`/sale-posts/${post.value.id}/view/`);
  } catch (err) {
    console.error("Error incrementing view count:", err);
  }
}

// Send message to seller
async function sendMessage() {
  sending.value = true;

  try {
    await postData(`/sale-posts/${post.value.id}/contact/`, contactForm.value);

    showNotification({
      title: "Message Sent",
      text: "Your message has been sent to the seller.",
      type: "success",
    });

    // Reset form and close modal
    contactForm.value = {
      name: "",
      email: "",
      phone: "",
      message: "",
    };
    showContactForm.value = false;
  } catch (err) {
    console.error("Error sending message:", err);
    showNotification({
      title: "Error",
      text: "Failed to send message. Please try again later.",
      type: "error",
    });
  } finally {
    sending.value = false;
  }
}

// Report post
async function reportPost() {
  reporting.value = true;

  try {
    await postData(`/sale-posts/${post.value.id}/report/`, reportForm.value);

    showNotification({
      title: "Report Submitted",
      text: "Thank you for your report. Our team will review it shortly.",
      type: "success",
    });

    // Reset form and close modal
    reportForm.value = {
      reason: "inappropriate",
      details: "",
    };
    showReportModal.value = false;
  } catch (err) {
    console.error("Error reporting post:", err);
    showNotification({
      title: "Error",
      text: "Failed to submit report. Please try again later.",
      type: "error",
    });
  } finally {
    reporting.value = false;
  }
}

// Copy post link to clipboard
function copyPostLink() {
  const url = window.location.href;
  navigator.clipboard.writeText(url).then(() => {
    copying.value = true;
    setTimeout(() => {
      copying.value = false;
    }, 2000);
  });
}

// Copy phone number to clipboard
function copyPhoneNumber() {
  if (!post.value.phone) return;
  
  navigator.clipboard.writeText(post.value.phone).then(() => {
    showNotification({
      title: "Phone Number Copied",
      text: "Phone number copied to clipboard",
      type: "success",
    });
  });
}

// Helper functions
function getCategoryName(categoryId) {
  if (!categoryId) return "";
  const category = categories.value.find((c) => c.id === parseInt(categoryId));
  return category ? category.name : "";
}

function getConditionLabel(conditionValue) {
  const condition = conditions.find((c) => c.value === conditionValue);
  return condition ? condition.label : "Unknown";
}

function formatPrice(price) {
  return new Intl.NumberFormat("en-IN").format(price);
}

function formatDate(dateString) {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString("en-US", { day: "numeric", month: "short" });
}

function formatDateFull(dateString) {
  if (!dateString) return "";
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function getMainImage(postData = post.value) {
  // Get API static URL from composable
  const { staticURL } = useApi();

  // Handle main_image from API response
  if (postData.main_image) {
    return postData.main_image.startsWith("http")
      ? postData.main_image
      : `${staticURL}${postData.main_image}`;
  }

  // Handle images array if provided
  if (postData.images && postData.images.length > 0) {
    // Find main image or use first image
    const mainImage =
      postData.images.find((img) => img.is_main) || postData.images[0];

    // Handle different image data structures
    if (typeof mainImage === "string") {
      return mainImage.startsWith("http")
        ? mainImage
        : `${staticURL}${mainImage}`;
    } else if (mainImage.image) {
      const imgUrl =
        typeof mainImage.image === "string"
          ? mainImage.image
          : mainImage.image.url || "";
      return imgUrl.startsWith("http") ? imgUrl : `${staticURL}${imgUrl}`;
    }
  }

  // Fallback image
  return "https://via.placeholder.com/800/3b82f6/FFFFFF?text=No+Image";
}

function getImageSrc(image) {
  // Get API static URL from composable
  const { staticURL } = useApi();

  // Handle different image data structures
  if (typeof image === "string") {
    return image.startsWith("http") ? image : `${staticURL}${image}`;
  } else if (image.image) {
    const imgUrl =
      typeof image.image === "string" ? image.image : image.image.url || "";
    return imgUrl.startsWith("http") ? imgUrl : `${staticURL}${imgUrl}`;
  }

  // Fallback image
  return "https://via.placeholder.com/800/3b82f6/FFFFFF?text=No+Image";
}

// Property type formatter
function propertyTypeLabel(type) {
  const labels = {
    apartment: "Apartment",
    house: "House",
    land: "Land",
    commercial: "Commercial Space",
    office: "Office Space",
  };
  return labels[type] || type;
}

// Warranty formatter
function warrantyLabel(warranty) {
  const labels = {
    "under-warranty": "Under Warranty",
    expired: "Warranty Expired",
    "no-warranty": "No Warranty",
  };
  return labels[warranty] || warranty;
}

// Navigate images in gallery
function navigateImage(direction) {
  if (!post.value.images || post.value.images.length === 0) return;

  if (direction === "prev") {
    currentImageIndex.value =
      (currentImageIndex.value - 1 + post.value.images.length) %
      post.value.images.length;
  } else if (direction === "next") {
    currentImageIndex.value =
      (currentImageIndex.value + 1) % post.value.images.length;
  }

  selectedImage.value = getImageSrc(post.value.images[currentImageIndex.value]);
}

// Select image from thumbnails
function selectImage(image, index) {
  selectedImage.value = getImageSrc(image);
  currentImageIndex.value = index;
}

// Handle image error
function handleImageError(event) {
  event.target.src =
    "https://via.placeholder.com/800/3b82f6/FFFFFF?text=No+Image";
}

// Zoom functionality
function zoomIn() {
  if (zoomLevel.value < 3) {
    zoomLevel.value += 0.1;
  }
}

function zoomOut() {
  if (zoomLevel.value > 1) {
    zoomLevel.value -= 0.1;
  }
}

function resetZoom() {
  zoomLevel.value = 1;
  panPosition.value = { x: 0, y: 0 };
}

function toggleZoom() {
  zoomLevel.value = zoomLevel.value === 1 ? 2 : 1;
  panPosition.value = { x: 0, y: 0 };
}

function handleZoom(event) {
  event.preventDefault();
  const delta = event.deltaY > 0 ? -0.1 : 0.1;
  const newZoomLevel = zoomLevel.value + delta;
  if (newZoomLevel >= 1 && newZoomLevel <= 3) {
    zoomLevel.value = newZoomLevel;
  }
}

function startPan(event) {
  isPanning = true;
  startPanPosition = { x: event.clientX, y: event.clientY };
}

function pan(event) {
  if (isPanning) {
    const deltaX = event.clientX - startPanPosition.x;
    const deltaY = event.clientY - startPanPosition.y;
    panPosition.value = {
      x: panPosition.value.x + deltaX,
      y: panPosition.value.y + deltaY,
    };
    startPanPosition = { x: event.clientX, y: event.clientY };
  }
}

function endPan() {
  isPanning = false;
}
</script>

<style scoped>
/* Line clamp utility for truncating text */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Style for the rich text content */
:deep(.prose) {
  max-width: none;
}

:deep(.prose p) {
  margin-bottom: 1rem;
}

:deep(.prose h1, .prose h2, .prose h3, .prose h4) {
  margin-top: 1.5rem;
  margin-bottom: 0.75rem;
  font-weight: 600;
}

:deep(.prose ul, .prose ol) {
  padding-left: 1.5rem;
  margin-bottom: 1rem;
}

:deep(.prose li) {
  margin-bottom: 0.5rem;
}

:deep(.prose img) {
  margin: 1rem auto;
  border-radius: 0.25rem;
}

/* Thumbnails container styles */
.thumbnails-container {
  scrollbar-width: thin;
  scrollbar-color: var(--tw-bg-gray-300) var(--tw-bg-gray-50);
}

.thumbnails-container::-webkit-scrollbar {
  height: 8px;
}

.thumbnails-container::-webkit-scrollbar-thumb {
  background-color: var(--tw-bg-gray-300);
  border-radius: 4px;
}

.thumbnails-container::-webkit-scrollbar-track {
  background-color: var(--tw-bg-gray-50);
}

/* Lightbox thumbnails styles */
.lightbox-thumbnails {
  scrollbar-width: thin;
  scrollbar-color: var(--tw-bg-gray-300) var(--tw-bg-gray-50);
}

.lightbox-thumbnails::-webkit-scrollbar {
  height: 8px;
}

lightbox-thumbnails::-webkit-scrollbar-thumb {
  background-color: var(--tw-bg-gray-300);
  border-radius: 4px;
}

lightbox-thumbnails::-webkit-scrollbar-track {
  background-color: var(--tw-bg-gray-50);
}

/* Professional Seller section styling */
.seller-card {
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.seller-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.seller-avatar {
  position: relative;
  border: 1px solid rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
}

.seller-avatar:hover {
  transform: scale(1.05);
  border-color: var(--primary);
}

.badge-pro {
  position: relative;
  transition: all 0.3s ease;
}

.badge-pro:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
}

.phone-number-container {
  position: relative;
  display: inline-flex;
  align-items: center;
}

.phone-number {
  transition: all 0.2s ease;
  position: relative;
}

.phone-number:hover {
  color: var(--primary);
}

.copy-btn {
  opacity: 0.85;
  transition: all 0.25s ease;
}

.copy-btn:hover {
  opacity: 1;
  transform: translateY(-1px);
}

/* Gradient divider effect */
.h-px.bg-gradient-to-r {
  height: 1px;
}

/* Button hover improvements */
:deep(.seller-card .button) {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

:deep(.seller-card .button:hover) {
  transform: translateY(-1px);
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}
</style>
