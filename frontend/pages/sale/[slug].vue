<template>
  <div class="bg-gray-100 min-h-screen product-detail-page">
    <!-- Simple back button for mobile - Mudah.my style -->
    <div class="fixed left-3 top-3 md:hidden z-50">
      <button 
        @click="$router.back()" 
        class="bg-white shadow-sm rounded p-2 text-gray-700 hover:text-orange-600 border border-gray-200"
      >
        <UIcon name="i-heroicons-arrow-left" class="size-4" />
      </button>
    </div>      
    <UContainer class="py-4">
      <nav class="flex mb-4 hidden md:block" aria-label="Breadcrumb">
        <ol class="inline-flex items-center flex-wrap text-xs">
          <li class="inline-flex items-center">
            <NuxtLink
              to="/"
              class="text-gray-600 hover:text-orange-600 transition-colors"
            >
              Home
            </NuxtLink>
          </li>
          <li>
            <div class="flex items-center">
              <span class="mx-1 text-gray-400">›</span>
              <NuxtLink
                to="/sale/for-sale"
                class="text-gray-600 hover:text-orange-600 transition-colors"
              >
                Sale Posts
              </NuxtLink>
            </div>
          </li>
          <li aria-current="page">
            <div class="flex items-center">
              <span class="mx-1 text-gray-400">›</span>
              <span class="text-gray-700 truncate max-w-[150px] md:max-w-xs">
                {{ post.title || "Loading..." }}
              </span>
            </div>
          </li>
        </ol>
      </nav><!-- Enhanced Professional Loading State -->
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
          <div class="bg-white border border-gray-200 mb-3" id="product-title">
            <div class="p-4">
              <!-- Title -->
              <h1 class="text-xl font-bold text-gray-800 mb-2">
                {{ post.title }}
              </h1>
              
              <div class="mb-3">
                <div class="text-2xl text-orange-600 font-bold">
                  <span v-if="post.negotiable && !post.price">Negotiable</span>
                  <span v-else-if="post.price">৳{{ formatPrice(post.price) }}</span>
                  <span v-else>Contact for Price</span>
                  <span v-if="post.negotiable && post.price" class="text-sm font-normal text-gray-500 ml-2">
                    (Negotiable)
                  </span>
                </div>
              </div>
              
              <!-- Simple Info Tags -->
              <div class="flex flex-wrap gap-2 text-sm text-gray-500">
                <span class="flex items-center">
                  <UIcon name="i-heroicons-calendar" class="size-3.5 mr-1" />
                  {{ formatDate(post.created_at) }}
                </span>
                <span class="flex items-center">
                  <UIcon name="i-heroicons-tag" class="size-3.5 mr-1" />
                  {{ post.category_details?.name || 'General' }}
                </span>
                <span v-if="post.area || post.district" class="flex items-center">
                  <UIcon name="i-heroicons-map-pin" class="size-3.5 mr-1" />
                  {{ post.area }}{{ post.area && post.district ? ', ' : '' }}{{ post.district }}
                </span>
              </div>
            </div>
          </div><!-- Mudah.my Style Images Gallery Card -->
          <div class="bg-white border border-gray-200 mb-6 slide-up-fade-in" style="--delay: 300ms">
            <!-- Simple Gallery Header - Similar to Mudah.my -->
            <div class="bg-gray-100 py-1 px-3 flex justify-between">
              <span class="text-xs text-gray-500">Ad Images</span>
              <span class="text-xs text-gray-500">
                {{ post.images?.length || 0 }} Photos
              </span>
            </div>
              <!-- Mudah.my Style Main Image Gallery Experience -->
            <div
              class="relative h-[350px] md:h-[450px] overflow-hidden bg-white"
            >
              <!-- Simple Image Loading Placeholder (Mudah.my style) -->
              <div
                v-if="imageLoading"
                class="absolute inset-0 flex items-center justify-center bg-gray-100 z-10"
              >
                <div class="flex flex-col items-center space-y-3">
                  <UIcon name="i-heroicons-photo" class="h-10 w-10 text-gray-300" />
                  <div class="text-sm text-gray-400">Loading image...</div>
                </div>
              </div>

              <!-- Main Large Image - Mudah.my Style -->
              <div class="h-full w-full flex items-center justify-center overflow-hidden image-container bg-gray-50">
                <img
                  :src="selectedImage || getMainImage()"
                  :alt="post.title"
                  class="w-full h-full object-contain transition-all duration-300"
                  :class="{
                    'opacity-0': imageLoading,
                    'opacity-100': !imageLoading,
                  }"
                  @click="openLightbox = true"
                  @load="imageLoading = false"
                  @error="handleImageError"
                />
              </div>              <!-- Mudah.my Style Navigation Controls -->
              <div
                v-if="post.images && post.images.length > 1"
                class="absolute inset-x-0 top-1/2 transform -translate-y-1/2 flex justify-between px-2 z-10"
              >
                <button
                  @click.stop="navigateImage('prev')"
                  class="p-1 bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 shadow-sm transition-colors"
                  aria-label="Previous image"
                >
                  <UIcon name="i-heroicons-chevron-left" class="h-5 w-5" />
                </button>
                <button
                  @click.stop="navigateImage('next')"
                  class="p-1 bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 shadow-sm transition-colors"
                  aria-label="Next image"
                >
                  <UIcon name="i-heroicons-chevron-right" class="h-5 w-5" />
                </button>
              </div>              <!-- Mudah.my Style Status Badges -->
              <div class="absolute top-2 right-2 flex flex-col gap-1 z-10">
                <div v-if="post.status === 'sold'" class="badge-container">
                  <span
                    class="inline-flex items-center bg-blue-600 text-white text-xs px-2 py-0.5"
                  >
                    SOLD
                  </span>
                </div>
                <div v-if="post.featured" class="badge-container">
                  <span
                    class="bg-orange-500 text-white text-xs px-2 py-0.5 inline-flex items-center gap-1"
                  >
                    <UIcon name="i-heroicons-star" class="h-3 w-3" />
                    FEATURED
                  </span>
                </div>
              </div>              <!-- Mudah.my Style Zoom Control -->
              <button
                @click.stop="openLightbox = true"
                class="absolute bottom-2 right-2 p-1 bg-white border border-gray-300 text-gray-600 hover:bg-gray-50 shadow-sm transition-colors"
                aria-label="Zoom image"
              >
                <UIcon name="i-heroicons-magnifying-glass-plus" class="h-4 w-4" />
              </button>
              
              <!-- Mudah.my Style Image Counter -->
              <div
                v-if="post.images && post.images.length > 1"
                class="absolute bottom-2 left-2 bg-white border border-gray-300 text-gray-600 text-xs px-2 py-0.5"
              >
                {{ currentImageIndex + 1 }}/{{ post.images.length }}
              </div>
            </div>            <!-- Mudah.my Style Thumbnails Gallery -->
            <div
              v-if="post.images && post.images.length > 1"
              class="relative bg-white py-2 px-2 border-t border-gray-200"
            >
              <!-- Simple Thumbnails Container -->
              <div class="relative">
                <!-- Thumbnails Container - Mudah.my Style -->
                <div
                  ref="thumbnailsContainer"
                  class="flex gap-1.5 overflow-x-auto thumbnails-container pb-1"
                >
                  <button
                    v-for="(image, index) in post.images"
                    :key="index"
                    class="flex-shrink-0 cursor-pointer w-14 h-14 overflow-hidden"
                    :class="{
                      'border-2 border-orange-500':
                        selectedImage === getImageSrc(image),
                      'border border-gray-200':
                        selectedImage !== getImageSrc(image),
                    }"
                    @click="selectImage(image, index)"
                  >
                    <img
                      :src="getImageSrc(image)"
                      :alt="`${post.title} thumbnail ${index + 1}`"
                      class="w-full h-full object-cover"
                      loading="lazy"
                    />
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
          </div>          <!-- Removed separate location section as per Mudah.my style - information moved to title section -->
          <!-- This section is removed to match Mudah.my's layout which combines this information with the title section --><!-- Enhanced Product Details Card -->
          <div
            class="bg-white rounded-lg shadow-md border border-gray-100 overflow-hidden mb-6 slide-up-fade-in" style="--delay: 500ms"
          >            <!-- Mudah.my Style Header -->
            <div class="bg-gray-100 p-2.5 border-b border-gray-200">
              <h3 class="text-sm uppercase font-semibold text-gray-800 flex items-center">
                <UIcon name="i-heroicons-clipboard-document-list" class="size-4 mr-1.5 text-gray-700" />
                Product Details
              </h3>
            </div>
            
            <!-- Post Details Table with Enhanced Design -->
            <div class="p-6">
              <div class="grid grid-cols-1 gap-y-3">
              <!-- Mudah.my Style Category Display -->
                <div class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Category
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.category_details.name }}
                  </div>
                </div>
                
              <!-- Mudah.my Style Condition Display -->
              <div class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                <div class="w-1/3 text-xs text-gray-500">
                  Condition
                </div>
                <div class="w-2/3 text-sm text-gray-800">
                  {{ getConditionLabel(post.condition) }}
                </div>
              </div>
              
              <!-- Property-specific fields -->
              <template v-if="post.category === 1">
                <div v-if="post.property_type" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Property Type
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ propertyTypeLabel(post.property_type) }}
                  </div>
                </div>

                <div v-if="post.size" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Size
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.size }} {{ post.unit || "sqft" }}
                  </div>
                </div>

                <div v-if="post.bedrooms" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Bedrooms
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.bedrooms }}
                  </div>
                </div>

                <div v-if="post.bathrooms" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Bathrooms
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.bathrooms }}
                  </div>
                </div>
              </template>

              <!-- Vehicle-specific fields -->
              <template v-if="post.category === 2">
                <div v-if="post.make" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Make
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.make }}
                  </div>
                </div>

                <div v-if="post.model" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Model
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.model }}
                  </div>
                </div>

                <div v-if="post.year" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Year
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.year }}
                  </div>
                </div>

                <div v-if="post.mileage" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Mileage
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.mileage }} {{ post.mileage_unit || "km" }}
                  </div>
                </div>
              </template>

              <!-- Electronics-specific fields -->
              <template v-if="post.category === 3">
                <div v-if="post.brand" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Brand
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.brand }}
                  </div>
                </div>

                <div v-if="post.model" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Model
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ post.model }}
                  </div>
                </div>

                <div v-if="post.warranty" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                  <div class="w-1/3 text-xs text-gray-500">
                    Warranty
                  </div>
                  <div class="w-2/3 text-sm text-gray-800">
                    {{ warrantyLabel(post.warranty) }}
                  </div>
                </div>
              </template>
              
              <!-- Location info -->
              <div v-if="post.area || post.district" class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                <div class="w-1/3 text-xs text-gray-500">
                  Location
                </div>
                <div class="w-2/3 text-sm text-gray-800">
                  {{ post.area }}{{ post.area && post.district ? ', ' : '' }}{{ post.district }}
                </div>
              </div>
              
              <!-- Posted Date -->
              <div class="flex items-baseline spec-item border-b border-gray-100 pb-2">
                <div class="w-1/3 text-xs text-gray-500">
                  Posted Date
                </div>
                <div class="w-2/3 text-sm text-gray-800">
                  {{ formatDateFull(post.created_at) }}
                </div>
              </div>
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
            </div>            <!-- Mudah.my Style Description Section -->
            <div class="border-t border-gray-200 mt-4 pt-4">
              <div class="bg-gray-50 p-2 mb-2">
                <h3 class="text-sm font-medium text-gray-700 uppercase">
                  Description
                </h3>
              </div>
              <div
                class="prose max-w-none text-gray-600 text-sm p-2"
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
          </div>          <!-- Mudah.my Style Safety Tips - Much Simpler -->
          <div
            class="bg-white border border-gray-200 mb-6"
          >
            <!-- Simple Header Like Mudah.my -->
            <div class="bg-gray-100 border-b border-gray-200 p-2.5">
              <h3 class="text-sm uppercase font-semibold text-gray-800 flex items-center">
                <UIcon
                  name="i-heroicons-shield-exclamation"
                  class="size-4 mr-1.5"
                />
                Safety Tips
              </h3>
            </div>
            
            <!-- Simplified Safety Tips Content -->
            <div class="p-3">
              <ul class="space-y-2 text-xs text-gray-600">
                <li class="flex items-start">
                  <span class="text-orange-600 mr-1.5">•</span>
                  <span>Meet in a public, well-lit place</span>
                </li>
                <li class="flex items-start">
                  <span class="text-orange-600 mr-1.5">•</span>
                  <span>Verify the item before making payment</span>
                </li>
                <li class="flex items-start">
                  <span class="text-orange-600 mr-1.5">•</span>
                  <span>Don't send money in advance</span>
                </li>
                <li class="flex items-start">
                  <span class="text-orange-600 mr-1.5">•</span>
                  <span>Use secure payment methods</span>
                </li>
              </ul>
              
            </div>
          </div>
        </div>          <!-- Right Column - Sidebar -->
        <div class="lg:col-span-1">          
          <!-- Mudah.my Style Seller Information Card -->
          <div class="bg-white border border-gray-200 mb-6 seller-card">
            <!-- Simple Seller Card Header - Mudah.my Style -->
            <div class="bg-gray-100 border-b border-gray-200 p-2.5">
              <div class="flex items-center justify-between">
                <h3 class="font-semibold text-gray-800 text-sm uppercase">
                  Contact Seller
                </h3>
                <span 
                  v-if="post.seller?.is_pro"
                  class="badge-pro flex items-center bg-orange-50 text-orange-700 border border-orange-200 px-2 py-0.5 text-xs"
                >
                  <UIcon name="i-heroicons-check-badge" class="size-3 mr-1" />
                  <span class="text-xs font-medium">Pro</span>
                </span>
              </div>
            </div>            <!-- Mudah.my Style Seller Profile Content -->
            <div class="p-3">
              <!-- Seller Profile Header - Simpler Mudah.my Style -->
              <div class="flex items-center mb-3">
                <div class="mr-3 relative">
                  <div
                    class="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden border border-gray-200"
                  >
                    <UIcon
                      v-if="!post.seller?.profile_picture"
                      name="i-heroicons-user"
                      class="size-7 text-gray-500"
                    />
                    <img
                      v-else
                      :src="post.seller.profile_picture"
                      :alt="post.seller?.name || 'Seller'"
                      class="w-full h-full object-cover"
                    />
                  </div>
                  <div v-if="post.seller?.is_verified" class="absolute -bottom-1 -right-1 bg-blue-500 rounded-full p-0.5 border-2 border-white">
                    <UIcon name="i-heroicons-check" class="size-2 text-white" />
                  </div>
                </div>
                <div>
                  <h4 class="text-base font-semibold text-gray-800">
                    {{ post.user_name || "Anonymous Seller" }}
                  </h4>
                  <div class="flex items-center text-xs text-gray-500">
                    <UIcon name="i-heroicons-map-pin" class="size-3 mr-1" />
                    <span>{{ post.seller?.location || post.location || "Location not provided" }}</span>
                  </div>
                </div>
              </div>
              
              <!-- Simple Divider -->
              <div class="h-px bg-gray-200 my-3"></div>
                <!-- Mudah.my Style Contact Information -->
              <div v-if="post.phone" class="mb-3">
                <div class="flex flex-col space-y-1">
                  <div class="flex items-center justify-between bg-white border border-gray-200 p-2">
                    <div class="flex items-center">
                      <UIcon name="i-heroicons-phone" class="size-4 mr-2 text-gray-600" />
                      <div v-if="showPhone" class="phone-number-container">
                        <a :href="`tel:${post.phone}`" class="text-gray-800 font-medium hover:text-orange-600">
                          {{ post.phone }}
                        </a>
                      </div>
                      <div v-else class="phone-number-container">
                        <span class="text-gray-700 font-medium">•••• •••• {{ post.phone.slice(-4) }}</span>
                        <button 
                          @click="showPhone = true"
                          class="ml-2 text-xs text-orange-600 hover:text-orange-800 font-medium"
                        >
                          Show
                        </button>
                      </div>
                    </div>
                    
                    <button 
                      @click="copyPhoneNumber"
                      class="flex items-center bg-gray-100 hover:bg-gray-200 text-gray-700 px-2 py-1 text-xs"
                    >
                      <UIcon name="i-heroicons-clipboard" class="size-3 mr-1" />
                      Copy
                    </button>
                  </div>
                </div>
              </div>              <!-- Mudah.my Style Contact Buttons -->              <div class="space-y-2">                <!-- Message Button - Orange color like Mudah.my -->
                <UButton
                  v-if="post.allows_messaging"
                  color="orange"
                  variant="solid"
                  class="w-full justify-center py-2 font-medium text-sm"
                  icon="i-heroicons-chat-bubble-oval-left-ellipsis"
                  @click="showContactForm = true"
                >
                  Chat with Seller
                </UButton>
                  <!-- View Seller's Other Ads - Borderless and clickable -->
                <NuxtLink
                  :to="`/sale/seller/${post.user_id || post.seller?.id || ''}`"
                  class="flex items-center justify-center py-2 text-sm text-gray-700 hover:text-orange-600 transition-colors"
                >
                  <UIcon name="i-heroicons-shopping-bag" class="size-4 mr-1.5" />
                  View Seller's Other Ads
                </NuxtLink>

                <div class="mt-3 text-center border-t border-gray-200 pt-3">
                  <button
                    class="text-gray-500 text-xs hover:text-red-500 transition-colors flex items-center justify-center w-full"
                    @click="showReportModal = true"
                  >
                    <UIcon name="i-heroicons-flag" class="size-3 mr-1" />
                    Report Ad
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Mudah.my Style Share Section -->
          <div class="bg-white border border-gray-200 mb-6">
            <div class="bg-gray-100 border-b border-gray-200 p-2.5">
              <h3 class="text-sm uppercase font-semibold text-gray-800">
                Share This Ad
              </h3>
            </div>
            <div class="p-3 flex justify-center space-x-3">
              <button class="text-gray-600 hover:text-blue-600" @click="shareOnFacebook">
                <UIcon name="i-heroicons-globe-alt" class="size-5" />
              </button>
              <button class="text-gray-600 hover:text-blue-400" @click="shareOnTwitter">
                <UIcon name="i-heroicons-chat-bubble-oval-left-ellipsis" class="size-5" />
              </button>
              <button class="text-gray-600 hover:text-green-600" @click="shareOnWhatsapp">
                <UIcon name="i-heroicons-phone" class="size-5" />
              </button>
              <button class="text-gray-600 hover:text-orange-600" @click="copyPostLink" title="Copy link">
                <UIcon name="i-heroicons-link" class="size-5" />
              </button>
            </div>
          </div>
          
          <div
            class="bg-white border border-gray-200 mb-6"
          >
            <div class="bg-gray-100 border-b border-gray-200 p-2.5">
              <h3 class="text-sm uppercase font-semibold text-gray-800">
                Similar Listings
              </h3>
            </div>

            <div v-if="loading" class="animate-pulse space-y-4 p-3">
              <div v-for="i in 3" :key="i" class="flex space-x-3">
                <div class="w-16 h-16 bg-gray-200"></div>
                <div class="flex-1 space-y-2">
                  <div class="h-4 bg-gray-200 w-3/4"></div>
                  <div class="h-4 bg-gray-200 w-1/2"></div>
                </div>
              </div>
            </div>

            <div
              v-else-if="relatedPosts.length === 0"
              class="text-gray-500 text-sm text-center py-4"
            >
              No similar listings found
            </div>

            <div v-else class="p-3">
              <div
                v-for="relatedPost in relatedPosts"
                :key="relatedPost.id"
                class="group border-b border-gray-100 last:border-b-0 py-2 first:pt-0 last:pb-0"
              >
                <NuxtLink
                  :to="`/sale/${relatedPost.slug}`"
                  class="flex space-x-3"
                >
                  <div
                    class="w-16 h-16 overflow-hidden flex-shrink-0 border border-gray-200"
                  >
                    <img
                      :src="getMainImage(relatedPost)"
                      :alt="relatedPost.title"
                      class="w-full h-full object-cover"
                    />
                  </div>
                  <div class="flex-1">
                    <h4
                      class="text-sm font-medium text-gray-700 group-hover:text-orange-600 transition-colors line-clamp-2"
                    >
                      {{ relatedPost.title }}
                    </h4>
                    <p class="text-orange-600 text-sm font-medium mt-1">
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
              </div>            </div>
          </div>
          
          <div
            class="bg-white border border-gray-200 p-3 mb-6 text-center"
          >
            <p class="text-xs text-gray-500">
              Ad ID: {{ post.id || 'XXXXXX' }}
            </p>
            
            <!-- Small report link like Mudah.my -->
            <div class="mt-1">
              <button
                class="text-gray-500 text-xs hover:text-orange-600 transition-colors inline-flex items-center"
                @click="showReportModal = true"
              >
                <UIcon name="i-heroicons-flag" class="size-3 mr-1" />
                Report suspicious ad
              </button>
            </div>
          </div>
        </div>
      </div>
      </div>
    </UContainer>    
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
        <button
          class="absolute top-4 right-4 text-white z-30 bg-black/70 p-2 hover:bg-black"
          @click="openLightbox = false"
          aria-label="Close lightbox"
        >
          <UIcon name="i-heroicons-x-mark" class="size-5" />
        </button>

        <div
          v-if="post.images && post.images.length > 1"
          class="absolute inset-x-0 top-1/2 transform -translate-y-1/2 flex justify-between px-4 z-20"
        >
          <button
            @click.stop="navigateImage('prev')"
            class="p-2 bg-black/70 text-white hover:bg-black/90"
            aria-label="Previous image"
          >
            <UIcon name="i-heroicons-chevron-left" class="h-6 w-6" />
          </button>
          <button
            @click.stop="navigateImage('next')"
            class="p-2 bg-black/70 text-white hover:bg-black/90"
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

        <div class="absolute bottom-4 left-4 flex items-center gap-2 z-20">
          <button
            @click="zoomOut"
            class="p-2 bg-black/70 text-white hover:bg-black/90"
            :disabled="zoomLevel <= 1"
            :class="{ 'opacity-50': zoomLevel <= 1 }"
          >
            <UIcon name="i-heroicons-minus" class="h-4 w-4" />
          </button>
          <span class="bg-black/70 px-2 py-1 text-xs text-white"
            >{{ Math.round(zoomLevel * 100) }}%</span
          >
          <button
            @click="zoomIn"
            class="p-2 bg-black/70 text-white hover:bg-black/90"
            :disabled="zoomLevel >= 3"
            :class="{ 'opacity-50': zoomLevel >= 3 }"
          >
            <UIcon name="i-heroicons-plus" class="h-4 w-4" />
          </button>
          <button
            @click="resetZoom"
            class="p-2 bg-black/70 text-white hover:bg-black/90 ml-1"
          >
            <UIcon name="i-heroicons-arrow-path" class="h-4 w-4" />
          </button>
        </div>

        <div
          v-if="post.images && post.images.length > 1"
          class="flex justify-center mt-4 gap-2 overflow-x-auto lightbox-thumbnails pb-2"
        >
          <button
            v-for="(image, index) in post.images"
            :key="index"
            class="flex-shrink-0 transition-all border"
            :class="{
              'border-orange-500 opacity-100':
                selectedImage === getImageSrc(image),
              'border-gray-300 opacity-70 hover:opacity-100':
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

    <UModal v-model="showContactForm" :ui="{ width: 'max-w-md' }">
      <div class="bg-white border border-gray-200">
        <!-- Header -->
        <div class="flex justify-between items-center bg-gray-100 border-b border-gray-200 p-3">
          <h3 class="text-base font-medium text-gray-800">Message Seller</h3>
          <button 
            class="text-gray-500 hover:text-gray-700"
            @click="showContactForm = false"
          >
            <UIcon name="i-heroicons-x-mark" class="size-5" />
          </button>
        </div>

        <!-- Form -->
        <div class="p-4">
          <form @submit.prevent="sendMessage">
            <div class="space-y-4">
              <div class="mb-3">
                <label class="block text-sm font-medium text-gray-700 mb-1">Your Name <span class="text-red-500">*</span></label>
                <input
                  v-model="contactForm.name"
                  type="text"
                  placeholder="Enter your name"
                  class="w-full px-3 py-2 border border-gray-300 text-gray-700 text-sm focus:outline-none focus:border-orange-500 focus:ring-1 focus:ring-orange-500"
                  required
                />
              </div>

              <div class="mb-3">
                <label class="block text-sm font-medium text-gray-700 mb-1">Your Email <span class="text-red-500">*</span></label>
                <input
                  v-model="contactForm.email"
                  type="email"
                  placeholder="Enter your email"
                  class="w-full px-3 py-2 border border-gray-300 text-gray-700 text-sm focus:outline-none focus:border-orange-500 focus:ring-1 focus:ring-orange-500"
                  required
                />
              </div>

              <div class="mb-3">
                <label class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                <input
                  v-model="contactForm.phone"
                  type="text"
                  placeholder="Enter your phone number (optional)"
                  class="w-full px-3 py-2 border border-gray-300 text-gray-700 text-sm focus:outline-none focus:border-orange-500 focus:ring-1 focus:ring-orange-500"
                />
              </div>

              <div class="mb-3">
                <label class="block text-sm font-medium text-gray-700 mb-1">Message <span class="text-red-500">*</span></label>
                <textarea
                  v-model="contactForm.message"
                  placeholder="Type your message here..."
                  rows="4"
                  class="w-full px-3 py-2 border border-gray-300 text-gray-700 text-sm focus:outline-none focus:border-orange-500 focus:ring-1 focus:ring-orange-500"
                  required
                ></textarea>
              </div>
            </div>

            <div class="mt-5">
              <button
                type="submit"
                class="w-full bg-orange-600 hover:bg-orange-700 text-white py-2.5 text-sm font-medium transition-colors"
                :class="{ 'opacity-75 cursor-not-allowed': sending }"
                :disabled="sending"
              >
                {{ sending ? "Sending..." : "Send Message" }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </UModal>    
    <UModal v-model="showReportModal" :ui="{ width: 'max-w-md' }">
      <div class="bg-white border border-gray-200">
        <!-- Header -->
        <div class="flex justify-between items-center bg-gray-100 border-b border-gray-200 p-3">
          <h3 class="text-base font-medium text-gray-800">Report Listing</h3>
          <button 
            class="text-gray-500 hover:text-gray-700"
            @click="showReportModal = false"
          >
            <UIcon name="i-heroicons-x-mark" class="size-5" />
          </button>
        </div>

        <!-- Form -->
        <div class="p-4">
          <form @submit.prevent="reportPost">
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">Reason for Report <span class="text-red-500">*</span></label>
              
              <div class="space-y-2">
                <label class="flex items-center">
                  <input type="radio" v-model="reportForm.reason" value="inappropriate" class="text-orange-600 focus:ring-orange-500" />
                  <span class="ml-2 text-sm text-gray-700">Inappropriate content</span>
                </label>
                
                <label class="flex items-center">
                  <input type="radio" v-model="reportForm.reason" value="fraud" class="text-orange-600 focus:ring-orange-500" />
                  <span class="ml-2 text-sm text-gray-700">Fraudulent listing</span>
                </label>
                
                <label class="flex items-center">
                  <input type="radio" v-model="reportForm.reason" value="duplicate" class="text-orange-600 focus:ring-orange-500" />
                  <span class="ml-2 text-sm text-gray-700">Duplicate listing</span>
                </label>
                
                <label class="flex items-center">
                  <input type="radio" v-model="reportForm.reason" value="misrepresentation" class="text-orange-600 focus:ring-orange-500" />
                  <span class="ml-2 text-sm text-gray-700">Misrepresentation</span>
                </label>
                
                <label class="flex items-center">
                  <input type="radio" v-model="reportForm.reason" value="other" class="text-orange-600 focus:ring-orange-500" />
                  <span class="ml-2 text-sm text-gray-700">Other</span>
                </label>
              </div>
            </div>

            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-1">Additional Details</label>
              <textarea
                v-model="reportForm.details"
                placeholder="Please provide any additional details..."
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 text-gray-700 text-sm focus:outline-none focus:border-orange-500 focus:ring-1 focus:ring-orange-500"
              ></textarea>
            </div>

            <div class="mt-5">
              <button
                type="submit"
                class="w-full bg-red-600 hover:bg-red-700 text-white py-2.5 text-sm font-medium transition-colors"
                :class="{ 'opacity-75 cursor-not-allowed': reporting }"
                :disabled="reporting"
              >
                {{ reporting ? "Submitting..." : "Submit Report" }}
              </button>
            </div>
          </form>
        </div>
      </div>
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

// Share functions (Mudah.my style)
function copyPostLink() {
  const url = window.location.href;
  navigator.clipboard.writeText(url).then(() => {
    showNotification({
      title: "Link Copied",
      text: "Ad link copied to clipboard",
      type: "success",
    });
  });
}

function shareOnFacebook() {
  const url = encodeURIComponent(window.location.href);
  const title = encodeURIComponent(post.value.title || "Check out this ad");
  window.open(`https://www.facebook.com/sharer/sharer.php?u=${url}&t=${title}`, '_blank');
}

function shareOnTwitter() {
  const url = encodeURIComponent(window.location.href);
  const text = encodeURIComponent(`${post.value.title || "Check out this ad"}`);
  window.open(`https://twitter.com/intent/tweet?url=${url}&text=${text}`, '_blank');
}

function shareOnWhatsapp() {
  const url = encodeURIComponent(window.location.href);
  const text = encodeURIComponent(`${post.value.title || "Check out this ad"}`);
  window.open(`https://api.whatsapp.com/send?text=${text}%20${url}`, '_blank');
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

/* Mudah.my style for the rich text content */
:deep(.prose) {
  max-width: none;
  font-size: 0.9375rem;
}

:deep(.prose p) {
  margin-bottom: 0.75rem;
  color: #444;
}

:deep(.prose h1, .prose h2, .prose h3, .prose h4) {
  margin-top: 1.25rem;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #333;
}

:deep(.prose ul, .prose ol) {
  padding-left: 1.25rem;
  margin-bottom: 0.75rem;
}

:deep(.prose li) {
  margin-bottom: 0.35rem;
}

:deep(.prose img) {
  margin: 0.75rem auto;
  border: 1px solid #e5e5e5;
}

/* Mudah.my style thumbnails container */
.thumbnails-container {
  scrollbar-width: thin;
  scrollbar-color: #ccc #f0f0f0;
}

.thumbnails-container::-webkit-scrollbar {
  height: 6px;
}

.thumbnails-container::-webkit-scrollbar-thumb {
  background-color: #ccc;
  border-radius: 0;
}

.thumbnails-container::-webkit-scrollbar-track {
  background-color: #f0f0f0;
}

/* Mudah.my style lightbox thumbnails */
.lightbox-thumbnails {
  scrollbar-width: thin;
  scrollbar-color: #666 #111;
}

.lightbox-thumbnails::-webkit-scrollbar {
  height: 6px;
}

.lightbox-thumbnails::-webkit-scrollbar-thumb {
  background-color: #666;
  border-radius: 0;
}

.lightbox-thumbnails::-webkit-scrollbar-track {
  background-color: #222;
}

/* Simpler Mudah.my seller section styling */
.seller-card {
  transition: all 0.2s ease;
  margin-bottom: 1.5rem;
}

.phone-number-container {
  position: relative;
  display: inline-flex;
  align-items: center;
}

/* Mudah.my style spec items */
.spec-item {
  padding-bottom: 0.5rem;
}

.spec-item:last-child {
  border-bottom: none !important;
}

/* Product Detail Page - Mudah.my specific */
.product-detail-page :deep(.uppercase) {
  letter-spacing: 0.5px;
}

.product-detail-page :deep(button:focus) {
  outline: none;
}

/* Fix for image aspect ratios in thumbnails */
.product-detail-page .image-container {
  background: #fafafa;
}

/* Override button colors to match Mudah.my orange */
.product-detail-page :deep(.bg-primary),
.product-detail-page :deep(.text-primary) {
  --tw-bg-opacity: 1;
  background-color: rgb(234 88 12 / var(--tw-bg-opacity)) !important;
  --tw-text-opacity: 1;
  color: rgb(234 88 12 / var(--tw-text-opacity)) !important;
}

.product-detail-page :deep(.border-primary) {
  --tw-border-opacity: 1;
  border-color: rgb(234 88 12 / var(--tw-border-opacity)) !important;
}

/* Simplify form control styling */
.product-detail-page :deep(input:focus),
.product-detail-page :deep(textarea:focus) {
  border-color: #ea580c;
  box-shadow: 0 0 0 1px rgba(234, 88, 12, 0.15);
}

/* Sidebar styling */
@media (min-width: 1024px) { /* lg breakpoint */
  .lg\:col-span-1 {
    display: block;
  }
}
</style>
