<template>
  <div class="bg-gray-50 min-h-screen">
    <!-- Page Content Container -->
    <UContainer class="py-6">
      <!-- Breadcrumbs Navigation -->
      <nav class="flex mb-5" aria-label="Breadcrumb">
        <ol class="inline-flex items-center space-x-1 md:space-x-3">
          <li class="inline-flex items-center">
            <NuxtLink
              to="/"
              class="inline-flex items-center text-sm text-gray-500 hover:text-primary"
            >
              <UIcon name="i-heroicons-home" class="size-4 mr-2" />
              Home
            </NuxtLink>
          </li>
          <li>
            <div class="flex items-center">
              <UIcon
                name="i-heroicons-chevron-right"
                class="size-3 mx-1 text-gray-500"
              />
              <NuxtLink
                to="/sale/for-sale"
                class="text-sm text-gray-500 hover:text-primary"
              >
                Sale Posts
              </NuxtLink>
            </div>
          </li>
          <li aria-current="page">
            <div class="flex items-center">
              <UIcon
                name="i-heroicons-chevron-right"
                class="size-3 mx-1 text-gray-500"
              />
              <span class="text-sm text-gray-600 font-medium">{{
                post.title || "Loading..."
              }}</span>
            </div>
          </li>
        </ol>
      </nav>

      <!-- Loading State -->
      <div
        v-if="loading"
        class="py-20 bg-white rounded-lg shadow-sm border border-gray-100"
      >
        <div class="flex flex-col items-center justify-center">
          <div class="w-16 h-16 relative">
            <div
              class="w-full h-full rounded-full border-4 border-primary-100"
            ></div>
            <div
              class="w-full h-full rounded-full border-4 border-t-primary-500 animate-spin absolute top-0 left-0"
            ></div>
          </div>
          <p class="text-center text-gray-600 mt-6 font-medium">
            Loading post details...
          </p>
        </div>
      </div>

      <!-- Error State -->
      <div
        v-else-if="error"
        class="py-16 text-center bg-white rounded-lg shadow-sm border border-gray-100"
      >
        <div class="max-w-md mx-auto">
          <UIcon
            name="i-heroicons-exclamation-triangle"
            class="h-16 w-16 mx-auto text-amber-500"
          />
          <h3 class="mt-4 text-lg font-medium text-gray-700">Post not found</h3>
          <p class="mt-2 text-gray-500">
            The post you're looking for doesn't exist or has been removed.
          </p>
          <UButton
            color="primary"
            variant="solid"
            class="mt-4"
            to="/sale/for-sale"
          >
            Browse Available Listings
          </UButton>
        </div>
      </div>

      <!-- Post Details Content -->
      <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Left Column - Main Content -->
        <div class="lg:col-span-2">
          <!-- Images Gallery Card - Enhanced Design -->
          <div
            class="bg-white rounded-xl shadow-sm overflow-hidden mb-6"
          >
            <!-- Main Image with Enhanced Gallery Experience -->
            <div
              class="relative h-[400px] md:h-[500px] overflow-hidden bg-gray-50 dark:bg-gray-900/20"
            >
              <!-- Image Loading Placeholder -->
              <div v-if="imageLoading" class="absolute inset-0 flex items-center justify-center bg-gray-100 dark:bg-gray-800/50 z-10">
                <div class="animate-pulse">
                  <UIcon name="i-heroicons-photo" class="h-16 w-16 text-gray-400 dark:text-gray-600" />
                </div>
              </div>
              
              <!-- Main Large Image -->
              <img
                :src="selectedImage || getMainImage()"
                :alt="post.title"
                class="w-full h-full object-contain transition-opacity duration-300"
                :class="{ 'opacity-0': imageLoading, 'opacity-100': !imageLoading }"
                @click="openLightbox = true"
                @load="imageLoading = false"
                @error="handleImageError"
              />

              <!-- Image Navigation Controls -->
              <div v-if="post.images && post.images.length > 1" class="absolute inset-x-0 top-1/2 transform -translate-y-1/2 flex justify-between px-4">
                <button 
                  @click.stop="navigateImage('prev')" 
                  class="rounded-full p-2 bg-white/80 dark:bg-gray-800/80 text-gray-800 dark:text-gray-300 hover:bg-white dark:hover:bg-gray-800 shadow-sm backdrop-blur-sm transition-all hover:scale-105"
                  aria-label="Previous image"
                >
                  <UIcon name="i-heroicons-chevron-left" class="h-6 w-6" />
                </button>
                <button 
                  @click.stop="navigateImage('next')" 
                  class="rounded-full p-2 bg-white/80 dark:bg-gray-800/80 text-gray-800 dark:text-gray-300 hover:bg-white dark:hover:bg-gray-800 shadow-sm backdrop-blur-sm transition-all hover:scale-105"
                  aria-label="Next image"
                >
                  <UIcon name="i-heroicons-chevron-right" class="h-6 w-6" />
                </button>
              </div>

              <!-- Status Badges with Improved Design -->
              <div class="absolute top-4 right-4 flex flex-col gap-2 z-10">
                <div
                  v-if="post.status === 'sold'"
                  class="badge-container"
                >
                  <span class="relative inline-flex items-center gap-1 bg-blue-500 text-white text-sm font-medium px-4 py-1.5 rounded shadow-sm">
                    <span class="flex w-2 h-2 relative mr-0.5">
                      <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
                      <span class="relative inline-flex rounded-full h-2 w-2 bg-white"></span>
                    </span>
                    SOLD
                  </span>
                </div>
                <div v-if="post.featured" class="badge-container">
                  <span class="bg-gradient-to-r from-amber-500 to-orange-500 text-white text-sm font-medium px-4 py-1.5 rounded shadow-sm flex items-center gap-1">
                    <UIcon name="i-heroicons-star" class="h-3.5 w-3.5" />
                    FEATURED
                  </span>
                </div>
              </div>

              <!-- Zoom Control -->
              <button 
                @click.stop="openLightbox = true" 
                class="absolute bottom-4 right-4 rounded-full p-2 bg-white/80 dark:bg-gray-800/80 text-gray-800 dark:text-gray-300 hover:bg-white dark:hover:bg-gray-800 shadow-sm backdrop-blur-sm transition-all hover:scale-105"
                aria-label="Zoom image"
              >
                <UIcon name="i-heroicons-magnifying-glass-plus" class="h-5 w-5" />
              </button>
              
              <!-- Image Counter -->
              <div v-if="post.images && post.images.length > 1" class="absolute bottom-4 left-4 bg-black/50 text-white text-xs px-2.5 py-1 rounded-full backdrop-blur-sm">
                {{ currentImageIndex + 1 }} / {{ post.images.length }}
              </div>
            </div>

            <!-- Enhanced Thumbnails Gallery with Scroll -->
            <div
              v-if="post.images && post.images.length > 1"
              class="relative bg-gray-50 dark:bg-gray-900/20 py-3 px-4 border-t border-gray-100 dark:border-gray-800"
            >
              <!-- Shadow indicators for scroll -->
              <div class="absolute left-0 top-0 bottom-0 w-8 bg-gradient-to-r from-gray-50 to-transparent dark:from-gray-900/20 z-10"></div>
              <div class="absolute right-0 top-0 bottom-0 w-8 bg-gradient-to-l from-gray-50 to-transparent dark:from-gray-900/20 z-10"></div>
              
              <!-- Thumbnails Container with Horizontal Scroll -->
              <div class="flex space-x-2 overflow-x-auto thumbnails-container pb-1 px-2">
                <button
                  v-for="(image, index) in post.images"
                  :key="index"
                  class="flex-shrink-0 cursor-pointer transition-all duration-300 transform rounded-md overflow-hidden border-2"
                  :class="{
                    'border-primary scale-105 shadow-sm': selectedImage === getImageSrc(image),
                    'border-transparent hover:border-gray-300 dark:hover:border-gray-600': selectedImage !== getImageSrc(image)
                  }"
                  @click="selectImage(image, index)"
                >
                  <div class="w-16 h-16 relative">
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

            <!-- No Images Message - Improved -->
            <div
              v-if="!post.images || post.images.length === 0"
              class="text-center py-6 bg-gray-50 dark:bg-gray-900/20"
            >
              <UIcon name="i-heroicons-photo" class="h-12 w-12 text-gray-400 dark:text-gray-600 mx-auto" />
              <p class="text-gray-500 dark:text-gray-500 mt-2">No images available for this listing</p>
            </div>
          </div>
          
          <!-- Title, Price, and Details Card -->
          <div
            class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-6"
          >
            <div
              class="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-6"
            >
              <h1 class="text-xl font-semibold text-gray-800">{{ post.title }}</h1>
              <div class="flex flex-col items-end">
                <div class="text-xl font-semibold text-primary">
                  <span v-if="post.negotiable && !post.price">Negotiable</span>
                  <span v-else-if="post.price"
                    >৳{{ formatPrice(post.price) }}</span
                  >
                  <span v-else>Contact for Price</span>
                </div>
                <div
                  v-if="post.negotiable && post.price"
                  class="text-sm text-gray-500"
                >
                  Negotiable
                </div>
              </div>
            </div>

            <!-- Post Details Table -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-8 mb-6">
              <!-- Category -->
              <div class="flex items-start">
                <UIcon
                  name="i-heroicons-tag"
                  class="size-5 mt-0.5 mr-3 text-gray-500"
                />
                <div>
                  <span class="text-gray-500 text-sm">Category</span>
                  <p class="text-gray-800 font-medium">
                    {{ getCategoryName(post.category) }}
                  </p>
                </div>
              </div>

              <!-- Condition -->
              <div class="flex items-start">
                <UIcon
                  name="i-heroicons-sparkles"
                  class="size-5 mt-0.5 mr-3 text-gray-500"
                />
                <div>
                  <span class="text-gray-500 text-sm">Condition</span>
                  <p class="text-gray-800 font-medium">
                    {{ getConditionLabel(post.condition) }}
                  </p>
                </div>
              </div>

              <!-- Location -->
              <div class="flex items-start">
                <UIcon
                  name="i-heroicons-map-pin"
                  class="size-5 mt-0.5 mr-3 text-gray-500"
                />
                <div>
                  <span class="text-gray-500 text-sm">Location</span>
                  <p class="text-gray-800">
                    {{ post.area }}, {{ post.district }}
                  </p>
                </div>
              </div>

              <!-- Posted Date -->
              <div class="flex items-start">
                <UIcon
                  name="i-heroicons-calendar"
                  class="size-5 mt-0.5 mr-3 text-gray-500"
                />
                <div>
                  <span class="text-gray-500 text-sm">Posted</span>
                  <p class="text-gray-800">
                    {{ formatDateFull(post.created_at) }}
                  </p>
                </div>
              </div>

              <!-- Property-specific fields -->
              <template v-if="post.category === 1">
                <div v-if="post.property_type" class="flex items-start">
                  <UIcon
                    name="i-heroicons-home"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Property Type</span>
                    <p class="text-gray-800 font-medium">
                      {{ propertyTypeLabel(post.property_type) }}
                    </p>
                  </div>
                </div>

                <div v-if="post.size" class="flex items-start">
                  <UIcon
                    name="i-heroicons-square-3-stack-3d"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Size</span>
                    <p class="text-gray-800 font-medium">
                      {{ post.size }} {{ post.unit || "sqft" }}
                    </p>
                  </div>
                </div>

                <div v-if="post.bedrooms" class="flex items-start">
                  <UIcon
                    name="i-heroicons-bed"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Bedrooms</span>
                    <p class="text-gray-800 font-medium">{{ post.bedrooms }}</p>
                  </div>
                </div>

                <div v-if="post.bathrooms" class="flex items-start">
                  <UIcon
                    name="i-heroicons-beaker"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Bathrooms</span>
                    <p class="text-gray-800 font-medium">
                      {{ post.bathrooms }}
                    </p>
                  </div>
                </div>
              </template>

              <!-- Vehicle-specific fields -->
              <template v-if="post.category === 2">
                <div v-if="post.make" class="flex items-start">
                  <UIcon
                    name="i-heroicons-truck"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Make</span>
                    <p class="text-gray-800 font-medium">{{ post.make }}</p>
                  </div>
                </div>

                <div v-if="post.model" class="flex items-start">
                  <UIcon
                    name="i-heroicons-tag"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Model</span>
                    <p class="text-gray-800 font-medium">{{ post.model }}</p>
                  </div>
                </div>

                <div v-if="post.year" class="flex items-start">
                  <UIcon
                    name="i-heroicons-calendar"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Year</span>
                    <p class="text-gray-800 font-medium">{{ post.year }}</p>
                  </div>
                </div>

                <div v-if="post.mileage" class="flex items-start">
                  <UIcon
                    name="i-heroicons-arrow-path-rounded-square"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Mileage</span>
                    <p class="text-gray-800 font-medium">
                      {{ post.mileage }} {{ post.mileage_unit || "km" }}
                    </p>
                  </div>
                </div>
              </template>

              <!-- Electronics-specific fields -->
              <template v-if="post.category === 3">
                <div v-if="post.brand" class="flex items-start">
                  <UIcon
                    name="i-heroicons-building-storefront"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Brand</span>
                    <p class="text-gray-800 font-medium">{{ post.brand }}</p>
                  </div>
                </div>

                <div v-if="post.model" class="flex items-start">
                  <UIcon
                    name="i-heroicons-tag"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Model</span>
                    <p class="text-gray-800 font-medium">{{ post.model }}</p>
                  </div>
                </div>

                <div v-if="post.warranty" class="flex items-start">
                  <UIcon
                    name="i-heroicons-shield-check"
                    class="size-5 mt-0.5 mr-3 text-gray-500"
                  />
                  <div>
                    <span class="text-gray-500 text-sm">Warranty</span>
                    <p class="text-gray-800 font-medium">
                      {{ warrantyLabel(post.warranty) }}
                    </p>
                  </div>
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
              <h3 class="text-lg font-medium text-gray-800 mb-4">
                Description
              </h3>
              <div
                class="prose max-w-none text-gray-600"
                v-html="post.description"
              ></div>
            </div>
          </div>

          <!-- Map Location Card (if coordinates available) -->
          <div
            v-if="post.latitude && post.longitude"
            class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-6"
          >
            <h3 class="text-lg font-medium text-gray-800 mb-4">
              <UIcon name="i-heroicons-map" class="size-5 mr-2 inline-block" />
              Location
            </h3>
            <div class="h-80 bg-gray-100 rounded-lg overflow-hidden">
              <!-- Map component would be added here -->
              <div class="h-full w-full flex items-center justify-center">
                <span class="text-gray-500">Map would be displayed here</span>
              </div>
            </div>
          </div>

          <!-- Safety Tips Card -->
          <div
            class="bg-amber-50 rounded-lg shadow-sm border border-amber-100 p-6"
          >
            <h3 class="text-amber-800 font-medium flex items-center mb-4">
              <UIcon
                name="i-heroicons-shield-exclamation"
                class="size-5 mr-2"
              />
              Safety Tips for Buyers
            </h3>
            <ul class="space-y-2 text-amber-700 text-sm list-disc list-inside">
              <li>Meet in a public, well-lit place</li>
              <li>Verify the item before making payment</li>
              <li>Don't send money in advance</li>
              <li>Use secure payment methods</li>
              <li>Bring a friend when meeting the seller</li>
              <li>Report suspicious behavior to us</li>
            </ul>
          </div>
        </div>

        <!-- Right Column - Sidebar -->
        <div class="lg:col-span-1">
          <!-- Seller Contact Card -->
          <div
            class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-6"
          >
            <h3 class="text-lg font-medium text-gray-800 mb-4">
              Seller Information
            </h3>
            <div class="flex items-center mb-4">
              <div class="mr-3">
                <div
                  class="w-14 h-14 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden"
                >
                  <img
                    v-if="post.seller?.profile_picture"
                    :src="post.seller.profile_picture"
                    :alt="post.seller?.name || 'Seller'"
                    class="w-full h-full object-cover"
                  />
                  <UIcon
                    v-else
                    name="i-heroicons-user"
                    class="size-8 text-gray-500"
                  />
                </div>
              </div>
              <div>
                <h4 class="font-medium text-gray-700">
                  {{ post.seller?.name || "Anonymous Seller" }}
                </h4>
                <p
                  v-if="post.seller?.member_since"
                  class="text-xs text-gray-500"
                >
                  Member since {{ formatDate(post.seller.member_since) }}
                </p>
              </div>
            </div>

            <!-- Contact Buttons -->
            <div class="space-y-3">
              <UButton
                v-if="post.phone"
                color="primary"
                variant="solid"
                class="w-full justify-center"
                icon="i-heroicons-phone"
                :href="`tel:${post.phone}`"
              >
                Call Seller
              </UButton>

              <UButton
                v-if="post.allows_messaging"
                color="primary"
                variant="outline"
                class="w-full justify-center"
                icon="i-heroicons-chat-bubble-oval-left-ellipsis"
                @click="showContactForm = true"
              >
                Message Seller
              </UButton>

              <!-- Copy Link Button -->
              <UButton
                color="gray"
                variant="soft"
                class="w-full justify-center"
                icon="i-heroicons-link"
                :loading="copying"
                @click="copyPostLink"
              >
                {{ copying ? "Copied!" : "Copy Link" }}
              </UButton>

              <!-- Report Button -->
              <UButton
                color="gray"
                variant="ghost"
                class="w-full justify-center"
                icon="i-heroicons-flag"
                @click="showReportModal = true"
              >
                Report Listing
              </UButton>
            </div>
          </div>

          <!-- Related Posts Card -->
          <div
            class="bg-white rounded-lg shadow-sm border border-gray-100 p-6 mb-6"
          >
            <h3 class="text-lg font-medium text-gray-800 mb-4">
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
    </UContainer>

    <!-- Enhanced Image Lightbox Modal -->
    <UModal v-model="openLightbox" :ui="{ 
      container: 'flex min-h-screen items-center justify-center p-0 md:p-4',
      overlay: 'bg-black/90',
      width: 'max-w-full md:max-w-6xl',
      base: 'bg-transparent w-full' 
    }">
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
        <div v-if="post.images && post.images.length > 1" class="absolute inset-x-0 top-1/2 transform -translate-y-1/2 flex justify-between px-4 z-20">
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
            :style="{ transform: `scale(${zoomLevel}) translate(${panPosition.x}px, ${panPosition.y}px)` }"
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
          <span class="bg-black/50 px-2 py-1 rounded text-xs text-white">{{ Math.round(zoomLevel * 100) }}%</span>
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
              'border-primary opacity-100 scale-110': selectedImage === getImageSrc(image),
              'border-transparent opacity-70 hover:opacity-100': selectedImage !== getImageSrc(image)
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
            <h3 class="text-lg font-medium text-gray-800">Message Seller</h3>
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
            <h3 class="text-lg font-medium text-gray-800">Report Listing</h3>
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

.lightbox-thumbnails::-webkit-scrollbar-thumb {
  background-color: var(--tw-bg-gray-300);
  border-radius: 4px;
}

.lightbox-thumbnails::-webkit-scrollbar-track {
  background-color: var(--tw-bg-gray-50);
}
</style>
