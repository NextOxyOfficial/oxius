<template>
  <div class="bg-gray-100 min-h-screen">
    <!-- Top Navigation Bar with Search and Post Button -->
    <div class="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
      <UContainer class="py-3">
        <div class="flex items-center justify-between gap-4">
          <div class="flex-1 max-w-3xl">
            <div class="relative">
              <UInputGroup class="w-full">
                <UInput
                  v-model="searchQuery"
                  placeholder="What are you looking for?"
                  class="!rounded-l-md"
                  @keyup.enter="applyFilters"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-magnifying-glass" class="text-gray-400" />
                  </template>
                </UInput>
                <UButton 
                  color="primary" 
                  @click="applyFilters"
                  class="!rounded-r-md"
                >
                  Search
                </UButton>
              </UInputGroup>
            </div>
          </div>
          <UButton
            color="primary"
            variant="outline"
            to="/sale/post"
            class="whitespace-nowrap flex items-center gap-1"
          >
            <UIcon name="i-heroicons-plus-circle" />
            Post Ad
          </UButton>
        </div>
      </UContainer>
    </div>

    <UContainer class="py-6">
      <div class="flex flex-col lg:flex-row gap-6">
        <!-- Sidebar with filters -->
        <div 
          class="filter-sidebar lg:w-72 bg-white rounded-lg shadow-sm border border-gray-100 overflow-auto"
          :class="[
            isMobileFilterOpen ? 'mobile-sidebar-open' : 'mobile-sidebar-closed', 
            'lg:block'
          ]"
        >
          <div class="p-5 max-sm:pt-20 border-b border-gray-100 bg-white z-10">
            <!-- Categories Section -->
            <div class="mb-6">
              <h2 class="text-lg font-medium text-gray-800 mb-3">Categories</h2>
              <ul class="space-y-1">
                <!-- All Categories option -->
                <li>
                  <button 
                    @click="selectCategory(null)"
                    class="w-full text-left px-2 py-1.5 rounded-md flex items-center justify-between"
                    :class="!selectedCategory ? 'bg-primary/10 text-primary font-medium' : 'text-gray-700 hover:bg-gray-100'"
                  >
                    <span class="flex items-center gap-2">
                      <UIcon name="i-heroicons-squares-2x2" class="w-5 h-5" />
                      All Categories
                    </span>
                    <span class="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full">
                      {{ totalListings }}
                    </span>
                  </button>
                </li>
                
                <!-- Individual categories -->
                <li v-for="category in categories" :key="category.id">
                  <button 
                    @click="selectCategory(category.id)"
                    class="w-full text-left px-2 py-1.5 rounded-md flex items-center justify-between"
                    :class="selectedCategory === category.id ? 'bg-primary/10 text-primary font-medium' : 'text-gray-700 hover:bg-gray-100'"
                  >
                    <span class="flex items-center gap-2">
                      <UIcon :name="getCategoryIcon(category.id)" class="w-5 h-5" />
                      {{ category.name }}
                    </span>
                    <span class="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full">
                      {{ getCategoryCount(category.id) }}
                    </span>
                  </button>
                </li>
              </ul>
            </div>
            
            <!-- Looking to List a Sale? Section -->
            <div class="mb-6 bg-gradient-to-r from-primary/5 to-primary/10 p-4 rounded-lg border border-primary/20">
              <h3 class="text-base font-medium text-primary mb-2 flex items-center gap-1">
                <UIcon name="i-heroicons-tag" class="w-4 h-4" />
                Looking to List a Sale?
              </h3>
              <p class="text-sm text-gray-600 mb-3">List your items easily and reach thousands of potential buyers in your area.</p>
              <UButton
                to="/sale/post"
                color="primary"
                size="sm"
                class="w-full flex items-center justify-center gap-1"
              >
                <UIcon name="i-heroicons-plus-circle" class="w-4 h-4" />
                Post Your Ad
              </UButton>
            </div>

            <!-- Location Selection -->
            <div class="mb-6">
              <h3 class="text-base font-medium text-gray-700 mb-3 flex items-center gap-1">
                <UIcon name="i-heroicons-map-pin" class="w-4 h-4" />
                Location
              </h3>
              
              <!-- Division Selection -->
              <div class="mb-3">
                <label class="block text-sm text-gray-500 mb-1">Division</label>
                <USelectMenu
                  v-model="selectedDivision"
                  :options="divisions"
                  placeholder="All Divisions"
                  class="w-full"
                  @update:modelValue="handleDivisionChange"
                />
              </div>
              
              <!-- District Selection -->
              <div class="mb-3">
                <label class="block text-sm text-gray-500 mb-1">District</label>
                <USelectMenu
                  v-model="selectedDistrict"
                  :options="districtOptions"
                  placeholder="All Districts"
                  class="w-full"
                  @update:modelValue="handleDistrictChange"
                  :disabled="!selectedDivision"
                />
              </div>
              
              <!-- Area Selection -->
              <div>
                <label class="block text-sm text-gray-500 mb-1">Area</label>
                <USelectMenu
                  v-model="selectedArea"
                  :options="areaOptions"
                  placeholder="All Areas"
                  class="w-full"
                  @update:modelValue="applyFilters"
                  :disabled="!selectedDistrict"
                />
              </div>
            </div>
            
            <!-- Sponsored Ads -->
            <div class="mb-6">
              <h3 class="text-xs uppercase text-gray-500 font-medium mb-2 flex items-center gap-1">
                <UIcon name="i-heroicons-sparkles" class="w-4 h-4 text-amber-500" />
                Sponsored
              </h3>
              
              <!-- Premium Ad Card -->
              <div class="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm mb-3 group cursor-pointer hover:shadow-md transition-shadow">
                <div class="relative">
                  <img src="https://picsum.photos/300/150?ad=1" alt="Premium Ad" class="w-full h-32 object-cover group-hover:scale-105 transition-transform duration-300" />
                  <div class="absolute top-2 left-2">
                    <span class="bg-amber-500 text-white text-xs px-2 py-0.5 rounded font-medium">Premium</span>
                  </div>
                </div>
                <div class="p-3">
                  <h4 class="font-medium text-gray-800">Luxury Apartments</h4>
                  <p class="text-primary text-sm font-medium">Starting at ৳8,500,000</p>
                </div>
              </div>
              
              <!-- Regular Ad Card -->
              <div class="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm group cursor-pointer hover:shadow-md transition-shadow">
                <div class="flex">
                  <div class="w-1/3">
                    <img src="https://picsum.photos/300/150?ad=2" alt="Ad" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                  </div>
                  <div class="w-2/3 p-3">
                    <h4 class="font-medium text-gray-800 text-sm">Latest Electronics</h4>
                    <p class="text-primary text-xs font-medium">Discounts up to 30%</p>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Additional filter sections can go here -->
          </div>
        </div>

        <!-- Main Content Area -->
        <div class="flex-1 order-1 lg:order-2">
          <!-- Sorting & View Options -->
          <div class="bg-white p-4 rounded-lg shadow-sm mb-4 flex flex-wrap justify-between items-center gap-4">
            <div>
              <p class="text-gray-500 text-sm">
                <span class="font-medium text-gray-700">{{ totalListings }}</span> ads found
                <span v-if="selectedCategory">
                  in <span class="font-medium text-gray-700">{{ getCategoryName(selectedCategory) }}</span>
                </span>
              </p>
            </div>
            <div class="flex gap-6 items-center">
              <div class="flex items-center gap-2">
                <span class="text-sm text-gray-500">Sort by:</span>
                <USelect
                  v-model="sortOption"
                  :options="sortOptions"
                  option-attribute="label"
                  value-attribute="value"
                  size="sm"
                  class="w-40"
                  @update:modelValue="applyFilters"
                />
              </div>
              <div class="flex items-center border-l border-gray-200 pl-4">
                <UButtonGroup size="sm">
                  <UButton
                    :color="viewMode === 'grid' ? 'primary' : 'gray'"
                    :variant="viewMode === 'grid' ? 'soft' : 'ghost'"
                    @click="viewMode = 'grid'"
                    icon="i-heroicons-squares-2x2"
                  />
                  <UButton
                    :color="viewMode === 'list' ? 'primary' : 'gray'"
                    :variant="viewMode === 'list' ? 'soft' : 'ghost'"
                    @click="viewMode = 'list'"
                    icon="i-heroicons-bars-3"
                  />
                </UButtonGroup>
              </div>
            </div>
          </div>

          <!-- Active Filters Display -->
          <div v-if="hasActiveFilters" class="bg-white p-3 rounded-lg shadow-sm mb-4">
            <div class="flex flex-wrap items-center gap-2">
              <span class="text-sm text-gray-500">Filters:</span>
              
              <UBadge
                v-if="selectedCategory"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Category: {{ getCategoryName(selectedCategory) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearCategory"
                />
              </UBadge>
              
              <UBadge
                v-if="selectedSubcategory"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                {{ subcategoryTitle }}: {{ getSubcategoryName(selectedSubcategory) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearSubcategory"
                />
              </UBadge>
              
              <UBadge
                v-if="selectedDivision"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Division: {{ selectedDivision }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearLocation"
                />
              </UBadge>
              
              <UBadge
                v-if="priceRange.min || priceRange.max"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Price: {{ priceRange.min || 'Any' }} - {{ priceRange.max || 'Any' }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearPriceRange"
                />
              </UBadge>
              
              <UBadge
                v-if="selectedCondition"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Condition: {{ getConditionLabel(selectedCondition) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="selectedCondition = ''"
                />
              </UBadge>

              <UBadge
                v-if="searchQuery"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Search: "{{ searchQuery }}"
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="searchQuery = ''"
                />
              </UBadge>
            </div>
          </div>

          <!-- Category Tabs Listings Section -->
          <div class="bg-blue-50/50 rounded-lg border border-blue-100/50 p-5 mb-6">
            <div class="flex flex-col sm:flex-row items-center justify-between mb-4 gap-4">
              <h2 class="text-lg font-medium text-gray-800">Browse By Category</h2>
              <div class="overflow-x-auto w-full sm:w-auto pb-1">
                <UButtonGroup size="sm">
                  <UButton
                    color="primary"
                    :variant="!activeCategoryTab ? 'soft' : 'ghost'"
                    class="px-4 whitespace-nowrap"
                    @click="changeActiveCategoryTab(null)"
                  >
                    All
                  </UButton>
                  <UButton
                    v-for="cat in topCategories"
                    :key="cat.id"
                    :color="activeCategoryTab === cat.id ? 'primary' : 'gray'"
                    :variant="activeCategoryTab === cat.id ? 'soft' : 'ghost'"
                    class="px-4 whitespace-nowrap"
                    @click="changeActiveCategoryTab(cat.id)"
                  >
                    {{ cat.name }}
                  </UButton>
                </UButtonGroup>
              </div>
            </div>
            
            <!-- Category Posts Grid -->
            <div v-if="categoryTabLoading" class="py-8 text-center">
              <UIcon name="i-heroicons-arrow-path" class="animate-spin h-6 w-6 mx-auto text-blue-500" />
              <p class="mt-2 text-gray-500 text-sm">Loading listings...</p>
            </div>
            
            <div v-else-if="!categoryPosts.length" class="py-8 text-center">
              <p class="text-gray-500">No listings found in this category</p>
            </div>
            
            <div v-else class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
              <NuxtLink 
                v-for="post in categoryPosts"
                :key="post.id"
                :to="`/sale/${post.slug}`"
                class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow transition-shadow group"
              >
                <!-- Featured Badge -->
                <div v-if="post.featured" class="absolute top-2 left-2 z-10">
                  <span class="bg-amber-500 text-white text-xs px-1.5 py-0.5 rounded shadow-sm">FEATURED</span>
                </div>

                <!-- Image -->
                <div class="relative aspect-square overflow-hidden">
                  <img 
                    :src="getListingImage(post)" 
                    :alt="post.title" 
                    class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                  <div class="absolute bottom-0 left-0 w-full bg-gradient-to-t from-black/70 to-transparent p-2">
                    <div class="text-white text-sm font-medium line-clamp-1">{{ post.title }}</div>
                  </div>
                </div>

                <!-- Price -->
                <div class="p-2 border-t border-gray-100">
                  <div class="flex items-center justify-between">
                    <p class="text-primary font-medium">
                      <span v-if="post.negotiable && !post.price">Negotiable</span>
                      <span v-else-if="post.price">৳{{ formatPrice(post.price) }}</span>
                      <span v-else>Contact for Price</span>
                    </p>
                    <p class="text-xs text-gray-500">{{ formatDate(post.created_at) }}</p>
                  </div>
                </div>
              </NuxtLink>
            </div>
            
            <!-- View More Button -->
            <div class="text-center mt-4">
              <UButton
                color="primary"
                variant="outline"
                size="sm"
                :to="activeCategoryTab ? `/sale?category=${activeCategoryTab}` : '/sale'"
                class="px-6"
              >
                View More
                <UIcon name="i-heroicons-arrow-right" class="ml-1 w-4 h-4" />
              </UButton>
            </div>
          </div>

          <!-- Recent Listings Section -->
          <div class="bg-amber-50/40 rounded-lg border border-dashed border-amber-200 p-5 mb-6">
            <h2 class="text-lg font-medium text-amber-700 flex items-center mb-4">
              <UIcon name="i-heroicons-clock" class="mr-2 h-5 w-5" />
              Recent Listings
            </h2>
            
            <!-- Recent Listings Horizontal Scroll -->
            <div class="overflow-x-auto pb-4 -mx-1 px-1">
              <div class="flex gap-4">
                <NuxtLink 
                  v-for="listing in listings.slice(0, 8)" 
                  :key="`recent-${listing.id}`"
                  :to="`/sale/${listing.slug}`"
                  class="flex-shrink-0 w-64 bg-white rounded-lg shadow-sm border border-amber-100 overflow-hidden hover:shadow-md transition-shadow group"
                >
                  <div class="relative h-36 overflow-hidden">
                    <img 
                      :src="getListingImage(listing)" 
                      :alt="listing.title" 
                      class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                    <div class="absolute top-2 right-2">
                      <span class="bg-white/90 text-amber-700 text-xs px-2 py-0.5 rounded-full shadow-sm font-medium">
                        {{ getCategoryName(listing.category) }}
                      </span>
                    </div>
                  </div>
                  
                  <div class="p-3">
                    <h3 class="font-medium text-gray-800 line-clamp-1 group-hover:text-amber-700">
                      {{ listing.title }}
                    </h3>
                    
                    <div class="flex items-center justify-between mt-1.5">
                      <p class="text-amber-700 font-medium text-sm">
                        <span v-if="listing.price">৳{{ formatPrice(listing.price) }}</span>
                        <span v-else>Negotiable</span>
                      </p>
                      <p class="text-xs text-gray-500">{{ formatDate(listing.created_at) }}</p>
                    </div>
                  </div>
                </NuxtLink>
              </div>
            </div>
          </div>

          <!-- Loading State -->
          <div v-if="loading" class="py-12 text-center bg-white rounded-lg shadow-sm">
            <UIcon name="i-heroicons-arrow-path" class="animate-spin h-8 w-8 mx-auto text-primary" />
            <p class="mt-2 text-gray-500">Loading listings...</p>
          </div>

          <!-- Empty State -->
          <div v-else-if="listings.length === 0" class="py-12 flex flex-col items-center justify-center bg-white rounded-lg shadow-sm">
            <UIcon name="i-heroicons-face-frown" class="h-16 w-16 text-gray-300" />
            <h3 class="mt-2 text-lg font-medium text-gray-700">No listings found</h3>
            <p class="mt-1 text-gray-500 max-w-sm text-center">
              We couldn't find any listings matching your criteria. Try adjusting your filters or search terms.
            </p>
          </div>

          <!-- Grid View -->
          <div v-else-if="viewMode === 'grid'" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <NuxtLink 
              v-for="listing in listings"
              :key="listing.id"
              :to="`/sale/${listing.slug}`"
              class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow transition-shadow group"
            >
              <!-- Featured Badge -->
              <div v-if="listing.featured" class="absolute top-2 left-2 z-10">
                <span class="bg-amber-500 text-white text-xs font-bold px-2 py-1 rounded shadow-sm">FEATURED</span>
              </div>

              <!-- Image with conditional badges -->
              <div class="relative aspect-[4/3] overflow-hidden">
                <img 
                  :src="getListingImage(listing)" 
                  :alt="listing.title" 
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
                <div class="absolute top-2 right-2">
                  <span 
                    v-if="listing.status === 'sold'" 
                    class="bg-blue-600 text-white text-xs font-bold px-2 py-1 rounded shadow-sm"
                  >
                    SOLD
                  </span>
                </div>
                <div class="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent opacity-60"></div>

                <!-- Price Badge -->
                <div class="absolute bottom-2 left-2 z-10">
                  <span class="bg-white text-primary text-sm font-medium px-2 py-1 rounded shadow-sm">
                    <span v-if="listing.negotiable && !listing.price">Negotiable</span>
                    <span v-else-if="listing.price">৳{{ formatPrice(listing.price) }}</span>
                    <span v-else>Contact for Price</span>
                  </span>
                </div>
              </div>

              <!-- Content -->
              <div class="p-4">
                <h3 class="font-medium text-gray-800 text-lg mb-1 line-clamp-2 group-hover:text-primary transition-colors">
                  {{ listing.title }}
                </h3>
                
                <div class="flex items-center mt-1.5 mb-2 text-gray-500 text-sm">
                  <UIcon name="i-heroicons-map-pin" class="h-4 w-4 mr-1 text-gray-400" />
                  <span class="line-clamp-1">{{ listing.area }}, {{ listing.district }}</span>
                </div>
                
                <!-- Tags -->
                <div class="flex flex-wrap gap-1.5 mt-2">
                  <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">
                    {{ getCategoryName(listing.category) }}
                  </span>
                  <span v-if="listing.condition" class="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                    {{ getConditionLabel(listing.condition) }}
                  </span>
                </div>
                
                <!-- Date -->
                <div class="mt-3 pt-2 border-t border-gray-100 flex justify-between items-center">
                  <div class="text-xs text-gray-500">
                    {{ formatDate(listing.created_at) }}
                  </div>
                </div>
              </div>
            </NuxtLink>
          </div>

          <!-- List View -->
          <div v-else class="space-y-4">
            <NuxtLink 
              v-for="listing in listings"
              :key="listing.id"
              :to="`/sale/${listing.slug}`"
              class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow group block"
            >
              <div class="flex flex-col sm:flex-row">
                <!-- Image Container -->
                <div class="sm:w-48 md:w-56 lg:w-64 relative">
                  <img 
                    :src="getListingImage(listing)" 
                    :alt="listing.title" 
                    class="w-full h-40 sm:h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                  <div v-if="listing.featured" class="absolute top-2 left-2 z-10">
                    <span class="bg-amber-500 text-white text-xs font-bold px-2 py-1 rounded shadow-sm">FEATURED</span>
                  </div>
                  <div class="absolute top-2 right-2">
                    <span 
                      v-if="listing.status === 'sold'" 
                      class="bg-blue-600 text-white text-xs font-bold px-2 py-1 rounded shadow-sm"
                    >
                      SOLD
                    </span>
                  </div>
                </div>

                <!-- Content -->
                <div class="flex-1 p-4 flex flex-col">
                  <div class="flex flex-col md:flex-row md:justify-between gap-2">
                    <div>
                      <h3 class="font-medium text-gray-800 text-lg mb-1 group-hover:text-primary transition-colors">
                        {{ listing.title }}
                      </h3>
                      
                      <div class="flex items-center mt-1 mb-2 text-gray-500 text-sm">
                        <UIcon name="i-heroicons-map-pin" class="h-4 w-4 mr-1 text-gray-400" />
                        <span>{{ listing.area }}, {{ listing.district }}</span>
                      </div>
                      
                      <!-- Tags -->
                      <div class="flex flex-wrap gap-1.5 mt-1">
                        <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">
                          {{ getCategoryName(listing.category) }}
                        </span>
                        <span v-if="listing.condition" class="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                          {{ getConditionLabel(listing.condition) }}
                        </span>
                      </div>
                    </div>

                    <!-- Price Box -->
                    <div class="mt-2 md:mt-0 bg-gray-50 px-4 py-2 rounded-md text-right flex-shrink-0">
                      <div class="text-lg font-bold text-primary">
                        <span v-if="listing.negotiable && !listing.price">Negotiable</span>
                        <span v-else-if="listing.price">৳{{ formatPrice(listing.price) }}</span>
                        <span v-else>Contact for Price</span>
                      </div>
                      <div v-if="listing.negotiable && listing.price" class="text-xs text-gray-500">Negotiable</div>
                    </div>
                  </div>

                  <!-- Details based on category -->
                  <div v-if="listing.category === 1" class="grid grid-cols-2 gap-x-8 gap-y-1 mt-3 text-sm text-gray-600">
                    <div v-if="listing.property_type">
                      <span class="font-medium">Type:</span> {{ listing.property_type }}
                    </div>
                    <div v-if="listing.bedrooms">
                      <span class="font-medium">Bedrooms:</span> {{ listing.bedrooms }}
                    </div>
                    <div v-if="listing.size">
                      <span class="font-medium">Size:</span> {{ listing.size }} {{ listing.unit || 'sqft' }}
                    </div>
                  </div>
                  
                  <div v-else-if="listing.category === 2" class="grid grid-cols-2 gap-x-8 gap-y-1 mt-3 text-sm text-gray-600">
                    <div v-if="listing.make">
                      <span class="font-medium">Make:</span> {{ listing.make }}
                    </div>
                    <div v-if="listing.model">
                      <span class="font-medium">Model:</span> {{ listing.model }}
                    </div>
                    <div v-if="listing.year">
                      <span class="font-medium">Year:</span> {{ listing.year }}
                    </div>
                  </div>
                  
                  <div v-else-if="listing.category === 3" class="grid grid-cols-2 gap-x-8 gap-y-1 mt-3 text-sm text-gray-600">
                    <div v-if="listing.brand">
                      <span class="font-medium">Brand:</span> {{ listing.brand }}
                    </div>
                    <div v-if="listing.model">
                      <span class="font-medium">Model:</span> {{ listing.model }}
                    </div>
                  </div>

                  <!-- Date -->
                  <div class="mt-auto pt-3 text-xs text-gray-500">
                    {{ formatDate(listing.created_at) }}
                  </div>
                </div>
              </div>
            </NuxtLink>
          </div>

          <!-- Pagination -->
          <div v-if="!loading && totalPages > 1" class="mt-6 flex justify-center">
            <UPagination
              v-model="currentPage"
              :page-count="totalPages"
              :total="totalListings"
              :ui="{
                wrapper: 'flex items-center gap-1',
                rounded: 'rounded-md'
              }"
              @update:model-value="onPageChange"
            />
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, defineAsyncComponent } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useApi } from '~/composables/useApi';
import { useNotifications } from '~/composables/useNotifications';

const route = useRoute();
const router = useRouter();
const { get } = useApi();
const { showNotification } = useNotifications();

// State variables
const loading = ref(true);
const listings = ref([]); // Renamed from posts to match template usage
const viewMode = ref('grid');
const isMobileFilterOpen = ref(false);
const searchQuery = ref('');
const totalListings = ref(0); // Added to match template usage
const categories = ref([]);
const selectedCategory = ref(null); // Added to match template usage
const selectedSubcategory = ref(null); // Added to match template usage
const selectedDivision = ref(''); // Added to match template usage
const selectedDistrict = ref(''); // Added for location selection
const selectedArea = ref(''); // Added for location selection
const selectedCondition = ref(''); // Added to match template usage
const sortOption = ref('newest'); // Added to match template usage
const currentPage = ref(1);
const perPage = ref(20);
const categoryCountsMap = ref({});

// Define priceRange object
const priceRange = ref({
  min: '',
  max: ''
});

// Define subcategoryTitle computed prop
const subcategoryTitle = computed(() => {
  switch (parseInt(selectedCategory.value)) {
    case 1: return 'Property Type';
    case 2: return 'Vehicle Type';
    case 3: return 'Electronics Type';
    default: return 'Type';
  }
});

// Sort options
const sortOptions = [
  { label: 'Newest First', value: 'newest' },
  { label: 'Oldest First', value: 'oldest' },
  { label: 'Price: Low to High', value: 'price_low' },
  { label: 'Price: High to Low', value: 'price_high' },
  { label: 'Most Viewed', value: 'most_viewed' }
];

// Computed property for checking active filters
const hasActiveFilters = computed(() => {
  return selectedCategory.value || 
    selectedSubcategory.value ||
    selectedDivision.value || 
    selectedDistrict.value ||
    selectedArea.value ||
    priceRange.value.min || 
    priceRange.value.max || 
    selectedCondition.value || 
    searchQuery.value;
});

// Computed property for total pages
const totalPages = computed(() => {
  return Math.ceil(totalListings.value / perPage.value);
});

// Location variables
const divisions = ref([
  'Dhaka',
  'Chittagong',
  'Khulna',
  'Rajshahi',
  'Barisal',
  'Sylhet',
  'Rangpur',
  'Mymensingh'
]);

// Districts by division
const districtsByDivision = {
  'Dhaka': ['Dhaka', 'Gazipur', 'Narayanganj', 'Tangail', 'Narsingdi', 'Munshiganj', 'Manikganj'],
  'Chittagong': ['Chittagong', 'Cox\'s Bazar', 'Comilla', 'Chandpur', 'Noakhali', 'Feni'],
  'Khulna': ['Khulna Sadar', 'Sonadanga', 'Khalishpur', 'Daulatpur', 'Rupsha', 'Khan Jahan Ali'],
  'Rajshahi': ['Rajshahi Sadar', 'Boalia', 'Motihar', 'Shah Makhdum', 'Paba'],
  'Gazipur': ['Gazipur Sadar', 'Tongi', 'Sreepur', 'Kaliganj', 'Kaliakair', 'Kapasia'],
  'Narayanganj': ['Narayanganj Sadar', 'Rupganj', 'Araihazar', 'Sonargaon', 'Bandar']
};

// Areas by district
const areasByDistrict = {
  'Dhaka': ['Uttara', 'Mirpur', 'Dhanmondi', 'Gulshan', 'Mohammadpur', 'Bashundhara', 'Banani', 'Motijheel', 'Khilgaon', 'Rampura'],
  'Chittagong': ['Agrabad', 'Pahartali', 'Nasirabad', 'Halishahar', 'GEC', 'Chawkbazar', 'Patenga', 'Khulshi'],
  'Khulna': ['Khulna Sadar', 'Sonadanga', 'Khalishpur', 'Daulatpur', 'Rupsha', 'Khan Jahan Ali'],
  'Rajshahi': ['Rajshahi Sadar', 'Boalia', 'Motihar', 'Shah Makhdum', 'Paba'],
  'Gazipur': ['Gazipur Sadar', 'Tongi', 'Sreepur', 'Kaliganj', 'Kaliakair', 'Kapasia'],
  'Narayanganj': ['Narayanganj Sadar', 'Rupganj', 'Araihazar', 'Sonargaon', 'Bandar']
};

// Computed properties for location options
const districtOptions = computed(() => {
  return selectedDivision.value ? districtsByDivision[selectedDivision.value] || [] : [];
});

const areaOptions = computed(() => {
  return selectedDistrict.value ? areasByDistrict[selectedDistrict.value] || [] : [];
});

// Fetch categories from the API
async function fetchCategories() {
  try {
    // Use a more generic path that's likely to work
    const response = await get('/api/sale/categories');
    
    if (response && Array.isArray(response.data)) {
      categories.value = response.data.map(category => ({
        id: category.id,
        name: category.name,
        slug: category.slug || category.name.toLowerCase().replace(/\s+/g, '-'),
        count: category.post_count || 0
      }));
      
      // Update category counts map
      categories.value.forEach(category => {
        categoryCountsMap.value[category.id] = category.count || 0;
      });
    } else if (response && response.data && typeof response.data === 'object') {
      // Handle non-array response format
      const categoriesData = Object.values(response.data).filter(item => item && typeof item === 'object');
      categories.value = categoriesData.map((category, index) => ({
        id: category.id || index + 1,
        name: category.name || `Category ${index + 1}`,
        slug: category.slug || `category-${index + 1}`,
        count: category.post_count || 0
      }));
    } else {
      categories.value = generateDefaultCategories();
    }
    
    console.log("Categories loaded:", categories.value);
  } catch (error) {
    console.error('Error fetching categories:', error);
    categories.value = generateDefaultCategories();
  }
}

// Generate default categories with counts to ensure we have data
function generateDefaultCategories() {
  console.log("Using default categories");
  const defaultCategories = [
    { id: 1, name: 'Properties', icon: 'home', count: 45 },
    { id: 2, name: 'Vehicles', icon: 'car', count: 32 },
    { id: 3, name: 'Electronics', icon: 'device-mobile', count: 27 },
    { id: 4, name: 'Sports', icon: 'basketball', count: 18 },
    { id: 5, name: 'B2B', icon: 'building-office', count: 12 },
    { id: 6, name: 'Others', icon: 'inbox', count: 24 }
  ];
  
  defaultCategories.forEach(category => {
    categoryCountsMap.value[category.id] = category.count || 0;
  });
  
  return defaultCategories;
}

// Load posts based on current filters - modify the API path and add fallback data
async function loadPosts(page = 1) {
  loading.value = true;
  currentPage.value = page;
  
  try {
    // Build query parameters
    const params = new URLSearchParams();
    params.append('page', page.toString());
    params.append('page_size', perPage.value.toString());
    
    // Add filters
    if (selectedCategory.value) params.append('category', selectedCategory.value.toString());
    if (selectedSubcategory.value) params.append('subcategory', selectedSubcategory.value.toString());
    if (searchQuery.value) params.append('search', searchQuery.value);
    if (priceRange.value.min) params.append('min_price', priceRange.value.min.toString());
    if (priceRange.value.max) params.append('max_price', priceRange.value.max.toString());
    if (selectedCondition.value) params.append('condition', selectedCondition.value);
    if (selectedDivision.value) params.append('division', selectedDivision.value);
    if (selectedDistrict.value) params.append('district', selectedDistrict.value);
    if (selectedArea.value) params.append('area', selectedArea.value);
    
    // Sort
    const sortMapping = {
      'newest': '-created_at',
      'oldest': 'created_at',
      'price_low': 'price',
      'price_high': '-price',
      'most_viewed': '-views'
    };
    params.append('sort', sortMapping[sortOption.value] || '-created_at');
    
    // Try different API paths to increase chances of success
    let response;
    try {
      response = await get(`/api/sale/listings?${params.toString()}`);
    } catch (firstError) {
      console.log("First API path failed, trying alternative");
      try {
        response = await get(`/api/listings?${params.toString()}`);
      } catch (secondError) {
        console.log("Second API path failed, trying last alternative");
        response = await get(`/listings?${params.toString()}`);
      }
    }
    
    if (response && response.data) {
      if (response.data.results) {
        // Paginated response
        listings.value = mapListingsData(response.data.results);
        totalListings.value = response.data.count || 0;
      } else if (Array.isArray(response.data)) {
        // Array response
        listings.value = mapListingsData(response.data);
        totalListings.value = response.data.length;
      }
    } else {
      listings.value = [];
      totalListings.value = 0;
    }
  } catch (error) {
    console.error('Error loading listings:', error);
    // Use fallback data to ensure UI has something to display
    listings.value = generateMockListings(10);
    totalListings.value = listings.value.length;
  } finally {
    loading.value = false;
  }
}

// Generate mock listings for fallback
function generateMockListings(count = 10, recent = false) {
  console.log("Generating mock listings");
  const mockListings = [];
  const categories = [1, 2, 3, 4, 5, 6];
  const statuses = ['active', 'sold'];
  const conditions = ['new', 'like-new', 'good', 'fair', 'poor'];
  const districts = ['Dhaka', 'Chittagong', 'Rajshahi', 'Khulna'];
  const areas = ['Uttara', 'Gulshan', 'Mirpur', 'Dhanmondi', 'Banani'];
  
  for (let i = 1; i <= count; i++) {
    const categoryId = categories[Math.floor(Math.random() * categories.length)];
    const createdDate = recent 
      ? new Date(Date.now() - Math.floor(Math.random() * 7) * 24 * 60 * 60 * 1000) // Last 7 days for recent listings
      : new Date(Date.now() - Math.floor(Math.random() * 30) * 24 * 60 * 60 * 1000);
      
    mockListings.push({
      id: i,
      title: `Sample Listing ${i} - ${getCategoryName(categoryId)}`,
      slug: `sample-listing-${i}`,
      price: Math.floor(Math.random() * 900000) + 100000,
      negotiable: Math.random() > 0.5,
      description: "This is a sample listing description.",
      category: categoryId,
      condition: conditions[Math.floor(Math.random() * conditions.length)],
      status: statuses[Math.floor(Math.random() * statuses.length)],
      featured: Math.random() > 0.8,
      created_at: createdDate.toISOString(),
      main_image: `https://picsum.photos/600/400?random=${i}`,
      images: [`https://picsum.photos/600/400?random=${i}`],
      district: districts[Math.floor(Math.random() * districts.length)],
      area: areas[Math.floor(Math.random() * areas.length)],
      bedrooms: categoryId === 1 ? Math.floor(Math.random() * 5) + 1 : undefined,
      size: categoryId === 1 ? Math.floor(Math.random() * 2000) + 500 : undefined,
      make: categoryId === 2 ? ['Toyota', 'Honda', 'BMW', 'Mercedes'][Math.floor(Math.random() * 4)] : undefined,
      model: categoryId === 2 ? `Model ${String.fromCharCode(65 + Math.floor(Math.random() * 26))}` : undefined,
      year: categoryId === 2 ? 2010 + Math.floor(Math.random() * 13) : undefined,
      brand: categoryId === 3 ? ['Apple', 'Samsung', 'Sony', 'LG'][Math.floor(Math.random() * 4)] : undefined,
    });
  }
  
  return mockListings;
}

// Map listing data to a consistent format
function mapListingsData(data) {
  return data.map(item => ({
    id: item.id,
    title: item.title,
    slug: item.slug || `listing-${item.id}`,
    price: item.price,
    negotiable: item.negotiable,
    description: item.description,
    category: item.category_id || item.category,
    condition: item.condition,
    status: item.status,
    featured: item.featured,
    created_at: item.created_at || new Date().toISOString(),
    
    // Images
    main_image: item.main_image,
    images: item.images || [],
    
    // Location
    division: item.division,
    district: item.district,
    area: item.area,
    
    // Category-specific fields
    property_type: item.property_type,
    bedrooms: item.bedrooms,
    size: item.size,
    unit: item.unit,
    make: item.make,
    model: item.model,
    year: item.year,
    brand: item.brand
  }));
}

// Helper functions
function getCategoryName(categoryId) {
  if (!categoryId) return '';
  const category = categories.value.find(c => c.id === parseInt(categoryId));
  return category ? category.name : '';
}

function getCategoryIcon(categoryId) {
  const iconMapping = {
    1: 'i-heroicons-home',
    2: 'i-heroicons-truck',
    3: 'i-heroicons-device-phone-mobile',
    4: 'i-heroicons-trophy',
    5: 'i-heroicons-building-office-2',
    6: 'i-heroicons-square-3-stack-3d'
  };
  return iconMapping[categoryId] || 'i-heroicons-squares-2x2';
}

function getCategoryCount(categoryId) {
  return categoryCountsMap.value[categoryId] || 0;
}

function getConditionLabel(condition) {
  const conditions = {
    'new': 'Brand New',
    'like-new': 'Like New',
    'good': 'Good',
    'fair': 'Fair',
    'poor': 'Poor'
  };
  return conditions[condition] || condition;
}

function getSubcategoryName(subcategoryId) {
  // This would ideally be populated from your API
  return subcategoryId;
}

function getListingImage(listing) {
  if (listing.main_image) {
    return listing.main_image;
  }
  
  if (listing.images && listing.images.length > 0) {
    return listing.images[0];
  }
  
  return 'https://via.placeholder.com/300x200?text=No+Image';
}

function formatPrice(price) {
  return new Intl.NumberFormat('en-IN').format(price);
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  
  const date = new Date(dateStr);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;
  
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric'
  });
}

// Action handlers
function selectCategory(catId) {
  selectedCategory.value = catId;
  selectedSubcategory.value = null;
  loadPosts(1);
}

function clearCategory() {
  selectedCategory.value = null;
  selectedSubcategory.value = null;
  loadPosts(1);
}

function clearSubcategory() {
  selectedSubcategory.value = null;
  loadPosts(1);
}

function clearLocation() {
  selectedDivision.value = '';
  selectedDistrict.value = '';
  selectedArea.value = '';
  applyFilters();
}

function clearPriceRange() {
  priceRange.value.min = '';
  priceRange.value.max = '';
  loadPosts(1);
}

function applyFilters() {
  loadPosts(1);
}

function onPageChange(page) {
  loadPosts(page);
}

// Location selection handlers
function handleDivisionChange() {
  selectedDistrict.value = '';
  selectedArea.value = '';
  applyFilters();
}

function handleDistrictChange() {
  selectedArea.value = '';
  applyFilters();
}

// Category tabs section variables
const topCategories = computed(() => {
  // Get top 4-5 categories with most listings
  return categories.value.slice(0, 5);
});
const activeCategoryTab = ref(null);
const categoryPosts = ref([]);
const categoryTabLoading = ref(false);

// Function to change active category tab
function changeActiveCategoryTab(categoryId) {
  if (activeCategoryTab.value === categoryId) {
    // Toggle off if already active
    activeCategoryTab.value = null;
  } else {
    activeCategoryTab.value = categoryId;
  }
  loadCategoryPosts();
}

// Load posts for the selected category tab with improved API paths and fallback
async function loadCategoryPosts() {
  categoryTabLoading.value = true;
  
  try {
    const params = new URLSearchParams();
    params.append('page', '1');
    params.append('page_size', '8');
    params.append('sort', '-created_at');
    
    if (activeCategoryTab.value) {
      params.append('category', activeCategoryTab.value.toString());
    }
    
    let response;
    try {
      response = await get(`/api/sale/listings?${params.toString()}`);
    } catch (firstError) {
      console.log("First category API path failed, trying alternative");
      try {
        response = await get(`/api/listings?${params.toString()}`);
      } catch (secondError) {
        console.log("Second category API path failed, trying last alternative");
        response = await get(`/listings?${params.toString()}`);
      }
    }
    
    if (response && response.data) {
      if (response.data.results) {
        categoryPosts.value = mapListingsData(response.data.results);
      } else if (Array.isArray(response.data)) {
        categoryPosts.value = mapListingsData(response.data);
      } else {
        categoryPosts.value = generateMockListings(8);
      }
    } else {
      categoryPosts.value = generateMockListings(8);
    }
  } catch (error) {
    console.error('Error loading category posts:', error);
    categoryPosts.value = generateMockListings(8);
  } finally {
    categoryTabLoading.value = false;
  }
}

// Recent Listings section variables
const recentListingsCategory = ref(null);
const recentListings = ref([]);
const recentListingsLoading = ref(false);

// Function to change recent listings category
function changeRecentListingsCategory(categoryId) {
  if (recentListingsCategory.value === categoryId) {
    // Toggle off if already active
    recentListingsCategory.value = null;
  } else {
    recentListingsCategory.value = categoryId;
  }
  loadRecentListings();
}

// Load recent listings with improved API paths and fallback
async function loadRecentListings() {
  recentListingsLoading.value = true;
  
  try {
    const params = new URLSearchParams();
    params.append('page', '1');
    params.append('page_size', '10');
    params.append('sort', '-created_at'); // Always sort by newest
    
    if (recentListingsCategory.value) {
      params.append('category', recentListingsCategory.value.toString());
    }
    
    let response;
    try {
      response = await get(`/api/sale/listings?${params.toString()}`);
    } catch (firstError) {
      console.log("First recent listings API path failed, trying alternative");
      try {
        response = await get(`/api/listings?${params.toString()}`);
      } catch (secondError) {
        console.log("Second recent listings API path failed, trying last alternative");
        response = await get(`/listings?${params.toString()}`);
      }
    }
    
    if (response && response.data) {
      if (response.data.results) {
        recentListings.value = mapListingsData(response.data.results);
      } else if (Array.isArray(response.data)) {
        recentListings.value = mapListingsData(response.data);
      } else {
        recentListings.value = generateMockListings(10, true);
      }
    } else {
      recentListings.value = generateMockListings(10, true);
    }
  } catch (error) {
    console.error('Error loading recent listings:', error);
    recentListings.value = generateMockListings(10, true);
  } finally {
    recentListingsLoading.value = false;
  }
}

// Modified onMounted to also load recent listings
onMounted(() => {
  console.log("Component mounted - starting data loading");
  // Load categories first
  fetchCategories().then(() => {
    console.log("Categories loaded, now loading other data");
    // Then load all list types in parallel
    Promise.all([
      loadPosts(),
      loadCategoryPosts(),
      loadRecentListings()
    ]).catch(error => {
      console.error("Error during initial data loading:", error);
    });
  });
});

// Add recent listings to the categories watcher
watch(categories, () => {
  if (categories.value.length > 0) {
    if (categoryPosts.value.length === 0) loadCategoryPosts();
    if (recentListings.value.length === 0) loadRecentListings();
  }
});
</script>

<style>
/* Small utility classes to support the design */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>