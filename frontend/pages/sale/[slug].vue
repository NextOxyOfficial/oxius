<template>
  <div class="max-w-6xl mx-auto -mt-3">
    <!-- Breadcrumb -->
    <nav
      class="flex items-center justify-between text-sm sm:my-6 my-3 px-3 pt-4"
    >
      <div class="flex items-center flex-1 min-w-0">
        <NuxtLink to="/" class="text-gray-500 hover:text-emerald-600"
          >Home</NuxtLink
        >
        <span class="mx-2 text-gray-400">
          <UIcon name="i-heroicons-chevron-right" class="h-3 w-3" />
        </span>
        <NuxtLink to="/sale" class="text-gray-500 hover:text-emerald-600"
          >Marketplace</NuxtLink
        >
        <span class="mx-2 text-gray-400">
          <UIcon name="i-heroicons-chevron-right" class="h-3 w-3" />
        </span>
        <NuxtLink
          v-if="product?.category_details"
          :to="`/sale?category=${product?.category}`"
          class="text-gray-500 hover:text-emerald-600 hidden sm:inline"
        >
          {{ product?.category_details?.name }}
        </NuxtLink>
        <span
          v-if="product?.category_details"
          class="mx-2 text-gray-400 hidden sm:inline"
        >
          <UIcon name="i-heroicons-chevron-right" class="h-3 w-3" />
        </span>
        <span class="text-gray-700 truncate max-w-[100px] sm:max-w-[200px]">{{
          product?.title
        }}</span>
      </div>

      <!-- Action buttons for logged in users -->
      <div
        v-if="isAuthenticated"
        class="flex items-center gap-2 flex-shrink-0 ml-2"
      >
        <NuxtLink
          to="/sale/my-posts"
          class="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-xs border border-emerald-500 text-emerald-600 rounded-md hover:bg-emerald-50 transition-colors duration-200"
        >
          <List class="h-3 w-3" />
          <span class="hidden sm:inline">My Posts</span>
        </NuxtLink>
        <NuxtLink
          to="/sale/my-posts?tab=post-sale"
          class="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-xs bg-emerald-600 text-white rounded-md hover:bg-emerald-700 transition-colors duration-200"
        >
          <UIcon name="i-heroicons-plus-circle" class="h-3 w-3" />
          <span class="hidden sm:inline">Post Ad</span>
        </NuxtLink>
      </div>
    </nav>

    <!-- Main Product Section -->
    <div class="grid grid-cols-1 lg:grid-cols-5 gap-2">
      <div class="lg:col-span-3 relative">
        <div
          ref="galleryRef"
          class="relative aspect-video bg-gray-100 rounded-lg overflow-hidden border border-gray-200"
          @touchstart="handleTouchStart"
          @touchmove="handleTouchMove"
          @touchend="handleTouchEnd"
        >
          <div
            v-if="
              !product.images ||
              product.images.length === 0 ||
              !product.images[currentImageIndex]?.image
            "
            class="absolute inset-0 w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex flex-col items-center justify-center"
          >
            <div
              class="bg-white/80 backdrop-blur-sm rounded-full p-6 mb-4 shadow-sm"
            >
              <UIcon name="i-heroicons-photo" class="h-16 w-16 text-gray-400" />
            </div>
            <p class="text-gray-500 text-lg font-medium">No Photo Uploaded</p>
          </div>
          <img
            v-else
            :src="product.images[currentImageIndex]?.image"
            :alt="product.title"
            class="absolute inset-0 w-full h-full object-cover"
          />
          <button
            class="absolute left-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 transition-all duration-200 opacity-0 hover:opacity-100"
            @click="prevImage"
          >
            <ChevronLeft class="h-4 w-4 text-gray-800" />
          </button>
          <button
            class="absolute right-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 transition-all duration-200 opacity-0 hover:opacity-100"
            @click="nextImage"
          >
            <ChevronRight class="h-4 w-4 text-gray-800" />
          </button>
          <div class="absolute bottom-3 right-3 flex space-x-2">
            <button
              class="bg-white/90 hover:bg-white text-gray-800 text-sm h-7 px-3 rounded-md transition-all duration-200 flex items-center"
              @click="downloadImage"
            >
              <Download class="h-3 w-3 mr-1" />
              Download
            </button>
            <span
              class="bg-white/90 text-gray-800 text-sm px-3 py-1.5 rounded-md"
            >
              {{ currentImageIndex + 1 }}/{{ product.images?.length }}
            </span>
          </div>
        </div>
        <!-- Thumbnail Gallery -->
        <div
          v-if="product?.images && product.images.length > 0"
          class="flex mt-3 space-x-2 overflow-x-auto pb-2 px-2 scrollbar-hide"
        >
          <div
            v-for="(image, index) in product?.images"
            :key="index"
            :class="`relative w-16 h-16 flex-shrink-0 cursor-pointer rounded-md overflow-hidden border-2 transition-all duration-200 ${
              index === currentImageIndex
                ? 'border-emerald-600'
                : 'border-transparent'
            }`"
            @click="selectImage(index)"
          >
            <div
              v-if="!image.image"
              class="absolute inset-0 w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center"
            >
              <UIcon name="i-heroicons-photo" class="h-6 w-6 text-gray-400" />
            </div>
            <img
              v-else
              :src="image.image"
              :alt="`Thumbnail ${index + 1}`"
              class="absolute inset-0 w-full h-full object-cover"
            />
          </div>
        </div>
      </div>

      <!-- Product Info - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg p-3 border border-gray-200">
          <div class="flex justify-between items-start">
            <h1 class="text-xl font-bold text-gray-800">
              {{ capitalizeTitle(product?.title) }}
            </h1>
            <div class="flex space-x-2">
              <button
                class="text-gray-400 hover:text-emerald-600 p-1 transition-colors duration-200"
                @click="handleShare"
              >
                <Share2 class="h-5 w-5" />
              </button>
            </div>
          </div>

          <div class="mt-2 flex items-center text-sm text-gray-600">
            <span class="font-medium text-gray-600 mr-2"
              >Ad ID: {{ product?.id }}</span
            >
            <span class="flex items-center">
              <Calendar class="h-3 w-3 mr-1" />
              {{ formatDate(product?.created_at) }}
            </span>
          </div>
          <div class="mt-4">
            <span class="text-2xl font-bold text-emerald-600"
              >৳{{
                product?.price
                  ? product.price.toLocaleString()
                  : "Contact for Price"
              }}</span
            >
          </div>

          <div class="mt-4 grid grid-cols-2 gap-2">
            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <Tag class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-sm font-medium text-gray-600">Category</div>
                <div class="text-sm text-gray-800">
                  {{ product.category_details?.name }}
                </div>
              </div>
            </div>

            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <Layers class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-sm font-medium text-gray-600">
                  Sub-Category
                </div>
                <div class="text-sm text-gray-800">
                  {{ product?.child_category_details?.name }}
                </div>
              </div>
            </div>

            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <ShieldCheck class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-sm font-medium text-gray-600">Condition</div>
                <div class="text-sm text-gray-800">{{ product.condition }}</div>
              </div>
            </div>

            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <MapPin class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-sm font-medium text-gray-600">Location</div>
                <div class="text-sm text-gray-800">
                  {{
                    product?.division && product?.district && product?.area
                      ? `${product?.division}, ${product?.district}, ${product?.area}`
                      : `All Over Bagnladesh`
                  }}
                </div>
              </div>
            </div>
          </div>

          <!-- Financing Banner -->
          <div
            class="mt-5 overflow-hidden rounded-lg border border-emerald-100"
          >
            <div class="bg-gradient-to-r from-emerald-600 to-emerald-700 p-5">
              <div class="flex items-start sm:items-center justify-between">
                <div class="flex-1">
                  <h3 class="font-bold text-white text-sm">Need financing?</h3>
                  <p class="text-emerald-100 text-xs sm:text-sm mt-1">
                    Get Free consultation from our experts
                  </p>
                  <div
                    class="mt-3 items-center text-xs sm:text-sm hidden sm:flex"
                  >
                    <div class="flex space-x-1">
                      <div
                        class="h-4 w-4 sm:h-6 sm:w-6 rounded-full bg-white flex items-center justify-center text-emerald-600"
                      >
                        $
                      </div>
                      <div
                        class="h-4 w-4 sm:h-6 sm:w-6 rounded-full bg-white flex items-center justify-center text-emerald-600"
                      >
                        %
                      </div>
                      <div
                        class="h-4 w-4 sm:h-6 sm:w-6 rounded-full bg-white flex items-center justify-center text-emerald-600"
                      >
                        ✓
                      </div>
                    </div>
                    <span class="ml-0.5 sm:ml-2 text-white font-medium"
                      >Competitive rates available</span
                    >
                  </div>
                </div>
                <div class="mt-5 sm:mt-0">
                  <NuxtLink
                    href="/contact-us"
                    class="bg-white hover:bg-gray-50 text-emerald-600 text-xs sm:text-sm px-4 py-2 rounded-md transition-all duration-200 whitespace-nowrap"
                  >
                    Apply Now
                  </NuxtLink>
                </div>
              </div>
              <div class="mt-3 flex items-center text-xs sm:text-sm sm:hidden">
                <div class="flex space-x-0.5">
                  <div
                    class="h-6 w-6 rounded-full bg-white flex items-center justify-center text-emerald-600"
                  >
                    $
                  </div>
                  <div
                    class="h-6 w-6 rounded-full bg-white flex items-center justify-center text-emerald-600"
                  >
                    %
                  </div>
                  <div
                    class="h-6 w-6 rounded-full bg-white flex items-center justify-center text-emerald-600"
                  >
                    ✓
                  </div>
                </div>
                <span class="ml-2 text-white font-medium"
                  >Competitive rates available</span
                >
              </div>
            </div>
            <div class="h-1 w-full bg-emerald-600"></div>
          </div>

          <div class="mt-4 flex justify-between">
            <button
              class="flex-1 mr-2 text-sm py-2 rounded-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-600"
              @click="openReportDialog"
            >
              <Flag class="h-3 w-3 mr-1" />
              Report Ad
            </button>
            <button
              class="flex-1 text-sm py-2 rounded-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-600"
              @click="handleShare"
            >
              <Share2 class="h-3 w-3 mr-1" />
              Share
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Details Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mt-4">
      <!-- Product Details - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200">
          <div class="p-3">
            <h2 class="text-lg font-bold mb-4 text-gray-800 flex items-center">
              <ClipboardList class="h-5 w-5 mr-2 text-emerald-600" />
              Details
            </h2>
            <div
              class="text-gray-600 sm:px-6 whitespace-pre-line text-sm leading-relaxed"
              v-html="product?.description"
            ></div>

            <div class="my-6 border-t border-gray-100"></div>

            <div>
              <h3
                class="text-base font-semibold mb-3 text-gray-800 flex items-center"
              >
                <MapPin class="h-4 w-4 mr-2 text-emerald-600" />
                Item/Property Address
              </h3>
              <div
                v-if="product?.division && product?.district && product?.area"
                class="text-sm sm:px-6 text-gray-800"
              >
                {{
                  product?.division && product?.district && product?.area
                    ? `${product?.detailed_address}`
                    : `All Over Bagnladesh`
                }}
              </div>
            </div>
          </div>
        </div>

        <!-- Safety Tips -->
        <div
          class="bg-white rounded-lg overflow-hidden mt-6 border border-gray-200"
        >
          <div class="p-6">
            <div class="flex items-center mb-4">
              <ShieldCheck class="h-5 w-5 text-emerald-600 mr-2" />
              <h2 class="text-lg font-bold text-gray-800">Safety Tips</h2>
            </div>
            <ul class="space-y-3 text-gray-600 text-sm">
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Meet in a safe, public place</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Don't pay or transfer money in advance</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Inspect the item before purchasing</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Be wary of unrealistic offers or prices</span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Seller Info - 1 column on large screens -->
      <div class="lg:col-span-1">
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200">
          <div class="p-6">
            <h2 class="text-lg font-bold mb-4 text-gray-800 flex items-center">
              <User class="h-5 w-5 mr-2 text-emerald-600" />
              Seller Information
            </h2>
            <div class="flex items-center">
              <div
                class="size-16 rounded-full bg-gray-200 overflow-hidden mr-4 border border-gray-200"
              >
                <img
                  :src="
                    product.user_details?.image ||
                    '/static/frontend/images/placeholder.jpg'
                  "
                  :alt="product.user_details?.name"
                  class="h-full w-full object-cover"
                />
              </div>
              <div>
                <div class="flex items-center">
                  <NuxtLink
                    :to="`/sale/user-profile/${product.user_details?.id}`"
                    class="font-semibold text-gray-800 hover:text-emerald-600 transition-colors duration-200 cursor-pointer"
                  >
                    {{ product.user_details?.name }}
                  </NuxtLink>
                  <div class="flex items-center space-x-1 ml-2">
                    <UIcon
                      v-if="product.user_details?.kyc"
                      name="mdi:check-decagram"
                      class="w-4 h-4 text-blue-600"
                      title="Verified"
                    />
                    <div
                      class="inline-flex"
                      v-if="product.user_details?.is_pro"
                    >
                      <span
                        class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-xs font-medium shadow-sm"
                        title="Pro Member"
                      >
                        <div class="flex items-center gap-1">
                          <UIcon
                            name="i-heroicons-shield-check"
                            class="size-3"
                          />
                          <span class="text-2xs">Pro</span>
                        </div>
                      </span>
                    </div>
                  </div>
                </div>
                <p class="text-sm text-gray-600">
                  Member since
                  {{ formatDate(product.user_details.date_joined) }}
                </p>
              </div>
            </div>

            <div class="mt-4 space-y-3 bg-gray-50 p-4 rounded-md">
              <div class="flex justify-between text-sm">
                <span class="text-gray-600">Total Listings</span>
                <span class="font-medium text-gray-800">{{
                  product.user_details?.sale_post_count
                }}</span>
              </div>

              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-600">Phone</span>
                <div class="flex items-center">
                  <span class="font-medium mr-2 text-gray-800">
                    {{
                      showPhone
                        ? product?.user_details?.phone
                        : maskPhoneNumber(product?.user_details?.phone)
                    }}
                  </span>
                  <button
                    class="h-6 w-6 p-0 text-emerald-600 hover:text-emerald-600"
                    @click="toggleShowPhone"
                  >
                    <component :is="showPhone ? EyeOff : Eye" class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>

            <button
              class="w-full mt-4 text-sm border border-gray-200 rounded-md py-2 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-800"
              @click="
                navigateTo('/sale/user-profile/' + product.user_details?.id)
              "
            >
              <User class="h-4 w-4 mr-2 text-emerald-600" />
              View Seller Profile
            </button>

            <NuxtLink
              @click="
                navigateTo('/sale/user-profile/' + product.user_details?.id)
              "
              class="cursorpointer mt-3 text-emerald-600 hover:text-emerald-600 text-sm flex items-center justify-center"
            >
              View more listings from this seller
              <ChevronRight class="h-3 w-3 ml-1" />
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>

    <!-- Similar Listings -->
    <div class="mt-8">
      <div class="flex items-center justify-between mb-4 px-3">
        <h2 class="text-lg font-bold text-gray-800 flex items-center">
          <LayoutGrid class="h-5 w-5 mr-2 text-emerald-600" />
          Similar Listings You May Like
        </h2>
        <NuxtLink
          href="/sale"
          class="text-emerald-600 hover:text-emerald-600 text-sm flex items-center"
        >
          View all
          <ChevronRight class="h-3 w-3 ml-1" />
        </NuxtLink>
      </div>

      <div class="grid grid-cols-2 md:grid-cols-4 gap-2 px-1">
        <NuxtLink
          v-for="item in similarProducts.slice(0, 4)"
          :key="item.id"
          :to="`/sale/${item.slug}`"
          class="bg-white rounded-lg overflow-hidden group border border-gray-200 hover:border-emerald-200 transition-all duration-300"
        >
          <div class="relative aspect-video">
            <img
              :src="item?.main_image || '/placeholder.svg'"
              :alt="item?.title"
              class="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
          </div>
          <div class="p-4">
            <h3
              class="font-semibold truncate text-sm text-gray-800 hover:text-emerald-600"
            >
              {{ capitalizeTitle(item.title) }}
            </h3>
            <div class="flex items-start mt-1 mb-2 text-xs text-gray-600">
              <UIcon
                name="i-heroicons-map-pin"
                class="h-3 w-3 mr-1 mt-0.5 flex-shrink-0 text-gray-600"
              />
              {{
                post?.division && post?.district && post?.area
                  ? `${post?.division}, ${post?.district}, ${post?.area}`
                  : `All Over Bangladesh`
              }}
            </div>
            <div class="flex justify-between items-center mt-2">
              <span class="font-bold text-emerald-600 text-sm"
                >৳{{
                  item?.price
                    ? item.price.toLocaleString()
                    : "Contact for Price"
                }}</span
              >
              <span
                class="text-gray-400 hover:text-emerald-600 h-6 w-6 p-0 transition-colors duration-200"
              >
                <ExternalLink class="h-4 w-4" />
              </span>
            </div>
          </div>
        </NuxtLink>
      </div>
    </div>

    <!-- Share Dialog -->
    <div
      v-if="shareDialogOpen"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeShareDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Share this listing</h3>
          <button
            @click="closeShareDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5" style="word-break: break-word">
          <div
            class="flex items-center space-x-2 overflow-hidden"
            style="word-break: break-word"
          >
            <div class="flex-1 overflow-hidden" style="word-break: break-word">
              <div
                class="flex items-center justify-between rounded-md border border-gray-200 px-3 py-2 overflow-hidden"
                style="word-break: break-word"
              >
                <span class="text-sm text-gray-600">{{ shareUrl }}</span>
              </div>
            </div>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="copyToClipboard"
            >
              <span class="flex items-center">
                <UIcon name="i-heroicons-clipboard" class="w-4 h-4 mr-1" />
                Copy
              </span>
            </button>
          </div>

          <div class="mt-5">
            <h4 class="text-sm font-medium mb-3 text-gray-800">Share via</h4>
            <div class="grid grid-cols-2 gap-3">
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('facebook')"
              >
                <span
                  class="w-5 h-5 bg-blue-600 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >f</span
                >
                Facebook
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('twitter')"
              >
                <span
                  class="w-5 h-5 bg-sky-500 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >t</span
                >
                Twitter
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('whatsapp')"
              >
                <span
                  class="w-5 h-5 bg-emerald-500 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >w</span
                >
                WhatsApp
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('email')"
              >
                <span
                  class="w-5 h-5 bg-gray-700 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >@</span
                >
                Email
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Report Dialog -->
    <div
      v-if="showReportDialog"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeReportDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Report Ad</h3>
          <button
            @click="closeReportDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5">
          <p class="text-sm text-gray-600 mb-4">
            Please select a reason for reporting this ad:
          </p>

          <div class="space-y-2">
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="fake"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800"
                >Fake or misleading listing</span
              >
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="prohibited"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Prohibited item</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="offensive"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Offensive content</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="scam"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Scam or fraud</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="other"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Other</span>
            </label>
          </div>

          <textarea
            v-if="reportReason === 'other'"
            v-model="reportDetails"
            placeholder="Please provide details about your report..."
            class="mt-4 w-full border border-gray-200 rounded-md p-2 text-sm text-gray-800 h-24 resize-none focus:outline-none focus:ring-1 focus:ring-emerald-500"
          ></textarea>

          <div class="mt-6 flex justify-end space-x-3">
            <button
              class="px-4 py-2 border border-gray-200 rounded-md text-sm text-gray-600 hover:bg-gray-50"
              @click="closeReportDialog"
            >
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="submitReport"
            >
              Submit Report
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from "vue";
import {
  Calendar,
  MapPin,
  Share2,
  Tag,
  Layers,
  AlertTriangle,
  ShieldCheck,
  User,
  ChevronRight,
  Flag,
  Heart,
  ChevronLeft,
  ExternalLink,
  Eye,
  EyeOff,
  X,
  Download,
  ClipboardList,
  LayoutGrid,
  List,
} from "lucide-vue-next";

// Import toast functionality for notifications
const toast = useToast();

// Import authentication composable
const { user, isAuthenticated } = useAuth();

const { params } = useRoute();
const { get } = useApi();
const product = ref({});
const similarProducts = ref([]);

async function getSalePost() {
  try {
    const response = await get(`/sale/posts/${params.slug}/`);
    if (response.data) {
      product.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching sale post:", error);
  }
}

await getSalePost();

async function getSimilarProducts() {
  try {
    const response = await get(
      `/sale/posts/?category=${product.value?.category}`
    );
    if (response.data) {
      similarProducts.value = response.data.results;
    }
  } catch (error) {
    console.error("Error fetching similar products:", error);
  }
}
await getSimilarProducts();

// State variables
const currentImageIndex = ref(0);
const showPhone = ref(false);
const shareDialogOpen = ref(false);
const showReportDialog = ref(false);
const galleryRef = ref(null);
const touchStartX = ref(0);
const touchEndX = ref(0);
const shareUrl = ref("");
const reportReason = ref("");
const reportDetails = ref("");

// Format date
const formatDate = (dateString) => {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
  }).format(date);
};

// Mask phone number
const maskPhoneNumber = (phone) => {
  return "XXXXXXX" + phone?.slice(-3);
};

// Image navigation
const nextImage = () => {
  currentImageIndex.value =
    currentImageIndex.value === product.images.length - 1
      ? 0
      : currentImageIndex.value + 1;
};

const prevImage = () => {
  currentImageIndex.value =
    currentImageIndex.value === 0
      ? product.images.length - 1
      : currentImageIndex.value - 1;
};

const selectImage = (index) => {
  currentImageIndex.value = index;
};

// Touch handlers for swipe
const handleTouchStart = (e) => {
  touchStartX.value = e.touches[0].clientX;
};

const handleTouchMove = (e) => {
  touchEndX.value = e.touches[0].clientX;
};

const handleTouchEnd = () => {
  const touchDiff = touchStartX.value - touchEndX.value;

  // If swipe distance is significant enough (more than 50px)
  if (Math.abs(touchDiff) > 50) {
    if (touchDiff > 0) {
      // Swipe left, go to next image
      nextImage();
    } else {
      // Swipe right, go to previous image
      prevImage();
    }
  }
};

// Download image
const downloadImage = () => {
  // Get the current image URL from the product images array
  const currentImage = product.value?.images?.[currentImageIndex.value];
  const imageUrl = currentImage?.image;

  if (!imageUrl) {
    console.error("No image URL found for download");
    return;
  }

  // Create a download link for the current image
  const link = document.createElement("a");
  link.href = imageUrl;
  link.download = `product-image-${currentImageIndex.value + 1}.jpg`;
  link.setAttribute("target", "_blank"); // Open in new tab if direct download fails
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

// Toggle phone visibility
const toggleShowPhone = () => {
  showPhone.value = !showPhone.value;
};

// Share functionality
const handleShare = () => {
  shareDialogOpen.value = true;
  // Use the current hostname; in production, this will be your domain
  const productionDomain = "https://adsyclub.com";
  // Use window.location.pathname to get just the path without hostname
  const pathname = window.location.pathname;
  // Create the full URL using the production domain
  shareUrl.value = productionDomain + pathname;
};

const closeShareDialog = () => {
  shareDialogOpen.value = false;
};

const copyToClipboard = () => {
  navigator.clipboard.writeText(shareUrl.value);
  // Show a toast message
  toast.add({
    title: "Link Copied!",
    description: "Share link has been copied to clipboard",
    color: "green",
    icon: "i-heroicons-check-circle",
  });
};

const shareViaMedia = (platform) => {
  let platformShareUrl = "";
  const currentUrl = encodeURIComponent(shareUrl.value);
  const title = encodeURIComponent(product.value?.title);
  switch (platform) {
    case "facebook":
      platformShareUrl = `https://www.facebook.com/sharer/sharer.php?u=${currentUrl}`;
      break;
    case "twitter":
      platformShareUrl = `https://twitter.com/intent/tweet?text=${title}&url=${currentUrl}`;
      break;
    case "whatsapp":
      platformShareUrl = `https://api.whatsapp.com/send?text=${title} ${currentUrl}`;
      break;
    case "email":
      platformShareUrl = `mailto:?subject=${title}&body=${currentUrl}`;
      break;
  }

  if (platformShareUrl) {
    window.open(platformShareUrl, "_blank");
  }

  closeShareDialog();
};

// Report functionality
const openReportDialog = () => {
  showReportDialog.value = true;
};

const closeReportDialog = () => {
  showReportDialog.value = false;
};

// Function to capitalize first letter of title
const capitalizeTitle = (title) => {
  if (!title) return "";
  return title.charAt(0).toUpperCase() + title.slice(1);
};

const submitReport = () => {
  closeReportDialog();
};
</script>

<style scoped>
/* Hide scrollbar but maintain functionality */
.scrollbar-hide {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Chrome, Safari and Opera */
}
</style>
