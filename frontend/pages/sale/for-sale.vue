<template>
  <div class="relative min-h-screen bg-gray-50">
    <!-- Page Header with Breadcrumbs -->
    <div class="bg-white border-b border-gray-200 py-4 sticky top-0 z-40">
      <UContainer>
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-xl font-medium text-gray-700">{{ categoryName || 'All Listings' }}</h1>
          </div>
          
          <!-- Post Sale Button -->
          <button 
            class="border border-primary text-primary hover:bg-primary/5 rounded-md py-1.5 px-3 flex items-center gap-2 shadow-sm transition-colors duration-200 font-medium"
            @click="openPostSaleModal"
          >
            <UIcon name="i-heroicons-plus-circle" class="size-4" />
            <span class="text-md font-medium">Post a Sale</span>
          </button>
        </div>
      </UContainer>
    </div>

    <UContainer class="py-6">
      <div class="flex flex-col lg:flex-row gap-6">
        <!-- Main Content Area - Left side -->
        <div class="flex-1">
          <!-- Search and Condition Filters -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-5 mb-6">
            <!-- Search -->
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">Search</label>
              <UInputGroup>
                <UInput
                  v-model="filters.search"
                  placeholder="Search listings..."
                  icon="i-heroicons-magnifying-glass"
                  @keyup.enter="loadPosts(1)"
                  :ui="{
                    base: 'w-full'
                  }"
                />
                <template #trailing>
                  <UButton color="primary" variant="outline" @click="loadPosts(1)">
                    Search
                  </UButton>
                </template>
              </UInputGroup>
            </div>
            
            <!-- Condition Options -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Condition</label>
              <div class="flex flex-wrap gap-2">
                <URadio
                  v-model="filters.condition"
                  value=""
                  label="All"
                  @change="loadPosts(1)"
                />
                <URadio
                  v-for="condition in conditions"
                  :key="condition.value"
                  v-model="filters.condition"
                  :value="condition.value"
                  :label="condition.label"
                  @change="loadPosts(1)"
                />
              </div>
            </div>
          </div>

          <!-- Active Filters Display -->
          <div v-if="hasActiveFilters" class="bg-white rounded-lg shadow-sm border border-gray-100 p-4 mb-6">
            <div class="flex flex-wrap items-center gap-2">
              <span class="text-sm text-gray-500">Active filters:</span>
              
              <UBadge
                v-if="filters.category"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Category: {{ getCategoryName(filters.category) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearCategoryFilter"
                />
              </UBadge>
              
              <UBadge
                v-if="filters.subcategory"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                {{ subcategoryLabel }}: {{ getSubcategoryLabel(filters.subcategory) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="filters.subcategory = ''; loadPosts(1)"
                />
              </UBadge>
              
              <UBadge
                v-if="filters.division"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Division: {{ filters.division }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearDivisionFilter"
                />
              </UBadge>
              
              <UBadge
                v-if="filters.district"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                District: {{ filters.district }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearDistrictFilter"
                />
              </UBadge>
              
              <UBadge
                v-if="filters.area"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Area: {{ filters.area }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="filters.area = ''; loadPosts(1)"
                />
              </UBadge>
              
              <UBadge
                v-if="filters.minPrice || filters.maxPrice"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Price: {{ filters.minPrice || '0' }} - {{ filters.maxPrice || 'Any' }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearPriceFilter"
                />
              </UBadge>
              
              <UBadge
                v-if="filters.condition"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Condition: {{ getConditionLabel(filters.condition) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="filters.condition = ''; loadPosts(1)"
                />
              </UBadge>
              
              <UBadge
                v-if="filters.search"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Search: "{{ filters.search }}"
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="filters.search = ''; loadPosts(1)"
                />
              </UBadge>
            </div>
          </div>
          
          <!-- View Control and Total Listings -->
          <div class="flex items-center justify-between mb-4">
            <div class="text-base text-gray-700">
              <span class="font-medium">{{ totalPosts }}</span> listings found
              <span v-if="filters.category">
                in <span class="font-medium">{{ getCategoryName(filters.category) }}</span>
              </span>
            </div>
            
            <div class="flex items-center gap-3">
              <UButtonGroup size="sm">
                <UButton
                  :color="viewMode === 'grid' ? 'primary' : 'gray'"
                  :variant="viewMode === 'grid' ? 'solid' : 'outline'"
                  icon="i-heroicons-squares-2x2"
                  @click="viewMode = 'grid'"
                />
                <UButton
                  :color="viewMode === 'list' ? 'primary' : 'gray'"
                  :variant="viewMode === 'list' ? 'solid' : 'outline'"
                  icon="i-heroicons-bars-3"
                  @click="viewMode = 'list'"
                />
              </UButtonGroup>
            </div>
          </div>

          <!-- Loading Indicator -->
          <div v-if="loading" class="py-20 bg-white rounded-lg shadow-sm border border-gray-100">
            <div class="flex flex-col items-center justify-center">
              <div class="w-16 h-16 relative">
                <div class="w-full h-full rounded-full border-4 border-primary-100"></div>
                <div class="w-full h-full rounded-full border-4 border-t-primary-500 animate-spin absolute top-0 left-0"></div>
              </div>
              <p class="text-center text-gray-600 mt-6 font-medium">Loading listings...</p>
            </div>
          </div>

          <!-- No Results -->
          <div v-else-if="posts.length === 0" class="py-16 text-center bg-white rounded-lg shadow-sm border border-gray-100">
            <div class="max-w-md mx-auto">
              <UIcon name="i-heroicons-document-magnifying-glass" class="h-16 w-16 mx-auto text-gray-400" />
              <h3 class="mt-4 text-lg font-medium text-gray-700">No listings found</h3>
              <p class="mt-2 text-gray-500">
                We couldn't find any listings matching your search. Try adjusting your filters or search criteria.
              </p>
              <UButton
                color="primary"
                variant="outline"
                class="mt-4"
                @click="clearAllFilters"
              >
                Clear filters
              </UButton>
            </div>
          </div>
          
          <!-- Grid View -->
          <div v-else-if="viewMode === 'grid'" class="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-4 sm:gap-3 gap-1">
            <div 
              v-for="post in posts" 
              :key="post.id" 
              class="bg-white rounded-lg overflow-hidden shadow-sm hover:shadow-sm transition-all duration-300 border border-gray-100 group relative listing-card"
            >
              <!-- Sale Status Badge -->
              <div v-if="post.status === 'sold'" class="absolute top-0 right-0 m-2 z-10">
                <span class="bg-blue-500 text-white text-xs font-bold px-2 py-1 rounded">SOLD</span>
              </div>
              <div v-if="post.featured" class="absolute top-0 left-0 m-2 z-10">
                <span class="bg-amber-500 text-white text-xs font-bold px-2 py-1 rounded">FEATURED</span>
              </div>
              
              <!-- Main Image with hover effect -->
              <div class="aspect-[4/3] relative overflow-hidden">
                <img 
                  :src="getPostImage(post)"
                  :alt="post.title"
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent opacity-70"></div>
                
                <!-- Price Badge -->
                <div class="absolute bottom-3 left-3 price-badge">
                  <span class="border border-primary bg-white text-primary text-sm font-medium px-2.5 py-1 rounded shadow-sm">
                    <span v-if="post.negotiable && !post.price">Negotiable</span>
                    <span v-else-if="post.price">৳{{ formatPrice(post.price) }}</span>
                    <span v-else>Contact for Price</span>
                  </span>
                </div>
              </div>
              
              <div class="p-4">
                <!-- Title & Location -->
                <NuxtLink :to="`/sale/${post.slug}`">
                  <h3 class="font-medium text-gray-700 text-lg mb-1 line-clamp-2 hover:text-primary transition-colors">
                    {{ post.title }}
                  </h3>
                </NuxtLink>
                
                <div class="flex items-start mt-1.5 mb-2 text-sm text-gray-500">
                  <UIcon name="i-heroicons-map-pin" class="h-4 w-4 mt-0.5 mr-1 flex-shrink-0 text-gray-400" />
                  <span class="line-clamp-1">{{ post.area }}, {{ post.district }}</span>
                </div>
                
                <!-- Category & Condition Tags -->
                <div class="flex flex-wrap gap-1.5 mt-3">
                  <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">
                    {{ getCategoryName(post.category) }}
                  </span>
                  <span class="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                    {{ getConditionLabel(post.condition) }}
                  </span>
                </div>
                
                <!-- Date & Contact -->
                <div class="mt-3 pt-3 border-t border-gray-100 flex justify-between items-center">
                  <div class="text-xs text-gray-500 flex items-center">
                    <UIcon name="i-heroicons-clock" class="h-3 w-3 mr-1 text-gray-400" />
                    {{ formatDate(post.created_at) }}
                  </div>
                  <NuxtLink :to="`/sale/${post.slug}`" class="text-primary text-sm font-medium hover:underline flex items-center gap-1">
                    View Details
                    <UIcon name="i-heroicons-arrow-right" class="h-3 w-3" />
                  </NuxtLink>
                </div>
              </div>
            </div>
          </div>
          
          <!-- List View -->
          <div v-else class="divide-y divide-gray-100 border border-gray-100 rounded-lg overflow-hidden bg-white">
            <div v-for="post in posts" :key="post.id" class="flex flex-col sm:flex-row hover:bg-gray-50 transition-colors p-4">
              <!-- Thumbnail with badges -->
              <div class="sm:w-52 flex-shrink-0 mb-4 sm:mb-0 sm:mr-4 aspect-[4/3] relative">
                <img 
                  :src="getPostImage(post)"
                  :alt="post.title"
                  class="w-full h-full object-cover rounded-md"
                />
                <div v-if="post.status === 'sold'" class="absolute top-0 right-0 m-2 z-10">
                  <span class="bg-blue-500 text-white text-xs font-bold px-2 py-1 rounded">SOLD</span>
                </div>
                <div v-if="post.featured" class="absolute top-0 left-0 m-2 z-10">
                  <span class="bg-amber-500 text-white text-xs font-bold px-2 py-1 rounded">FEATURED</span>
                </div>
              </div>
              
              <!-- Details -->
              <div class="flex-1 flex flex-col">
                <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-2">
                  <!-- Title & Category -->
                  <div>
                    <NuxtLink :to="`/sale/${post.slug}`">
                      <h3 class="font-medium text-gray-700 text-lg hover:text-primary transition-colors">
                        {{ post.title }}
                      </h3>
                    </NuxtLink>
                    
                    <div class="flex flex-wrap gap-1.5 mt-1">
                      <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">
                        {{ getCategoryName(post.category) }}
                      </span>
                      <span class="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                        {{ getConditionLabel(post.condition) }}
                      </span>
                    </div>
                  </div>
                  
                  <!-- Price -->
                  <div class="bg-gray-50 px-3 py-2 rounded-md text-right">
                    <div class="text-lg font-bold text-primary">
                      <span v-if="post.negotiable && !post.price">Negotiable</span>
                      <span v-else-if="post.price">৳{{ formatPrice(post.price) }}</span>
                      <span v-else>Contact for Price</span>
                    </div>
                    <div v-if="post.negotiable && post.price" class="text-xs text-gray-500">Negotiable</div>
                  </div>
                </div>
                
                <!-- Location -->
                <div class="flex items-center mt-2 mb-1 text-sm text-gray-500">
                  <UIcon name="i-heroicons-map-pin" class="h-4 w-4 mr-1 flex-shrink-0 text-gray-400" />
                  <span>{{ post.area }}, {{ post.district }}, {{ post.division }}</span>
                </div>
                
                <!-- Specific Details Based on Category -->
                <div class="grid grid-cols-2 sm:grid-cols-3 gap-x-4 gap-y-1 mt-2">
                  <!-- Properties -->
                  <div v-if="post.category === 1 && post.property_type" class="text-sm text-gray-600">
                    <span class="font-medium">Type:</span> {{ propertyTypeLabel(post.property_type) }}
                  </div>
                  <div v-if="post.category === 1 && post.size" class="text-sm text-gray-600">
                    <span class="font-medium">Size:</span> {{ post.size }} {{ post.unit || 'sqft' }}
                  </div>
                  <div v-if="post.category === 1 && post.bedrooms" class="text-sm text-gray-600">
                    <span class="font-medium">Bedrooms:</span> {{ post.bedrooms }}
                  </div>
                  
                  <!-- Vehicles -->
                  <div v-if="post.category === 2 && post.make" class="text-sm text-gray-600">
                    <span class="font-medium">Make:</span> {{ post.make }}
                  </div>
                  <div v-if="post.category === 2 && post.model" class="text-sm text-gray-600">
                    <span class="font-medium">Model:</span> {{ post.model }}
                  </div>
                  <div v-if="post.category === 2 && post.year" class="text-sm text-gray-600">
                    <span class="font-medium">Year:</span> {{ post.year }}
                  </div>
                  
                  <!-- Electronics -->
                  <div v-if="post.category === 3 && post.brand" class="text-sm text-gray-600">
                    <span class="font-medium">Brand:</span> {{ post.brand }}
                  </div>
                  <div v-if="post.category === 3 && post.model" class="text-sm text-gray-600">
                    <span class="font-medium">Model:</span> {{ post.model }}
                  </div>
                  <div v-if="post.category === 3 && post.warranty" class="text-sm text-gray-600">
                    <span class="font-medium">Warranty:</span> {{ warrantyLabel(post.warranty) }}
                  </div>
                </div>
                
                <!-- Date & Actions -->
                <div class="mt-auto pt-3 flex justify-between items-center">
                  <div class="text-xs text-gray-500 flex items-center">
                    <UIcon name="i-heroicons-clock" class="h-3 w-3 mr-1 text-gray-400" />
                    {{ formatDate(post.created_at) }}
                  </div>
                  <NuxtLink :to="`/sale/${post.slug}`" class="text-primary text-sm font-medium hover:underline">
                    View Details
                  </NuxtLink>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Pagination Controls -->
          <div v-if="totalPages > 1" class="mt-8 flex justify-center">
            <UPagination
              v-model="currentPage"
              :total="totalPosts"
              :page-count="totalPages"
              :per-page="perPage"
              :ui="{
                wrapper: 'flex items-center gap-1',
                rounded: 'rounded-md'
              }"
              @update:model-value="loadPosts"
            />
          </div>
        </div>

        <!-- Mobile filter toggle button - only visible on mobile -->
        <button 
          class="lg:hidden fixed left-0 top-1/2 -translate-y-1/2 bg-primary text-white px-3 py-4 rounded-r-lg shadow-lg z-50"
          @click="isMobileFilterOpen = !isMobileFilterOpen"
        >
          <UIcon 
            :name="isMobileFilterOpen ? 'i-heroicons-x-mark' : 'i-heroicons-adjustments-horizontal'" 
            class="size-6"
          />
        </button>

        <!-- Filter Sidebar - Right side on desktop, slide-in on mobile -->
        <div 
          class="filter-sidebar lg:w-72 bg-white rounded-lg shadow-sm border border-gray-100 overflow-auto"
          :class="[
            isMobileFilterOpen ? 'mobile-sidebar-open' : 'mobile-sidebar-closed', 
            'lg:block'
          ]"
        >
          <div class="p-5 max-sm:pt-20 border-b border-gray-100 bg-white z-10">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-bold text-gray-800">Filters</h2>
              <button 
                class="lg:hidden text-gray-400 hover:text-gray-600" 
                @click="isMobileFilterOpen = false"
              >
                <UIcon name="i-heroicons-x-mark" class="size-5" />
              </button>
            </div>
            
            <!-- Category Filter -->
            <div class="mb-6">
              <label class="block text-sm font-medium text-gray-700 mb-2">Category</label>
              <USelectMenu
                v-model="filters.category"
                :options="categories"
                option-attribute="name"
                value-attribute="id"
                searchable
                placeholder="All Categories"
                @update:modelValue="handleCategoryChange"
                :ui="{
                  width: 'w-full',
                  container: 'relative',
                  base: 'relative w-full',
                  button: {
                    base: 'border-gray-300 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 w-full'
                  }
                }"
              >
                <template #leading>
                  <UIcon name="i-heroicons-squares-2x2" class="text-gray-400 w-5 h-5" />
                </template>
              </USelectMenu>
            </div>
            
            <!-- Subcategory Filter -->
            <div class="mb-6">
              <label class="block text-sm font-medium text-gray-700 mb-2">
                {{ subcategoryLabel }}
              </label>
              <USelectMenu
                v-model="filters.subcategory"
                :options="subcategoryOptions"
                option-attribute="label"
                value-attribute="value"
                searchable
                placeholder="All Types"
                @update:modelValue="loadPosts(1)"
                :disabled="!filters.category || subcategoryOptions.length === 0"
                :ui="{
                  width: 'w-full',
                  container: 'relative',
                  base: 'relative w-full',
                  button: {
                    base: 'border-gray-300 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 w-full'
                  }
                }"
              >
                <template #leading>
                  <UIcon name="i-heroicons-tag" class="text-gray-400 w-5 h-5" />
                </template>
              </USelectMenu>
            </div>
            
            <!-- Price Range Filters -->
            <div class="mb-6">
              <label class="block text-sm font-medium text-gray-700 mb-2">Price Range</label>
              <div class="flex items-center gap-2">
                <UInput
                  v-model="filters.minPrice"
                  placeholder="Min"
                  type="number"
                  icon="i-mdi:currency-bdt"
                  @blur="loadPosts(1)"
                  :ui="{
                    base: 'w-full'
                  }"
                />
                <span class="text-gray-500">-</span>
                <UInput
                  v-model="filters.maxPrice"
                  placeholder="Max"
                  type="number"
                  icon="i-mdi:currency-bdt"
                  @blur="loadPosts(1)"
                  :ui="{
                    base: 'w-full'
                  }"
                />
              </div>
            </div>
            
            <!-- Location Filters -->
            <div class="mb-6">
              <div class="flex items-center justify-between mb-2">
                <label class="block text-sm font-medium text-gray-700">Location</label>
              </div>
              
              <!-- Division -->
              <div class="mb-3">
                <USelectMenu
                  v-model="filters.division"
                  :options="divisions"
                  placeholder="All Divisions"
                  @update:modelValue="handleDivisionChange"
                  :ui="{
                    width: 'w-full',
                    container: 'relative',
                    base: 'relative w-full',
                    button: {
                      base: 'border-gray-300 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 w-full'
                    }
                  }"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-map" class="text-gray-400 w-5 h-5" />
                  </template>
                </USelectMenu>
              </div>
              
              <!-- District -->
              <div class="mb-3">
                <USelectMenu
                  v-model="filters.district"
                  :options="districtOptions"
                  placeholder="All Districts"
                  @update:modelValue="handleDistrictChange"
                  :disabled="!filters.division"
                  :ui="{
                    width: 'w-full',
                    container: 'relative',
                    base: 'relative w-full',
                    button: {
                      base: 'border-gray-300 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 w-full'
                    }
                  }"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-map-pin" class="text-gray-400 w-5 h-5" />
                  </template>
                </USelectMenu>
              </div>
              
              <!-- Area -->
              <div>
                <USelectMenu
                  v-model="filters.area"
                  :options="areaOptions"
                  placeholder="All Areas"
                  @update:modelValue="loadPosts(1)"
                  :disabled="!filters.district"
                  :ui="{
                    width: 'w-full',
                    container: 'relative',
                    base: 'relative w-full',
                    button: {
                      base: 'border-gray-300 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 w-full'
                    }
                  }"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-building-office" class="text-gray-400 w-5 h-5" />
                  </template>
                </USelectMenu>
              </div>
            </div>

            <!-- Sort Options -->
            <div class="mb-6">
              <label class="block text-sm font-medium text-gray-700 mb-2">Sort by</label>
              <USelect
                v-model="filters.sort"
                :options="sortOptions"
                option-attribute="label"
                value-attribute="value"
                @update:modelValue="loadPosts(1)"
                :ui="{
                  width: 'w-full',
                  select: {
                    base: 'border-gray-300 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200'
                  }
                }"
              />
            </div>
            
            <!-- Clear Filters Button -->
            <div class="pt-4">
              <UButton
                color="gray"
                variant="outline"
                class="w-full"
                icon="i-heroicons-x-circle"
                @click="clearAllFilters"
              >
                Clear All Filters
              </UButton>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
    
    <!-- Post Sale Modal -->
    <UModal v-model="showPostSaleModal" :ui="{ width: 'w-full max-w-3xl' }">
      <UCard :ui="{ body: { padding: 'p-0' }, ring: '', rounded: 'rounded-lg' }">
        <template #header>
          <div class="flex justify-between items-center">
            <h2 class="text-lg font-medium text-gray-700">Post a Sale</h2>
            <UButton color="gray" variant="ghost" icon="i-heroicons-x-mark" @click="showPostSaleModal = false" />
          </div>
        </template>
        <div class="max-h-[80vh] overflow-y-auto p-4">
          <PostSale :categories="categories" @post-saved="onPostSaved" />
        </div>
      </UCard>
    </UModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, defineAsyncComponent, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useApi } from '~/composables/useApi';
import { useNotifications } from '~/composables/useNotifications';

// Lazy load PostSale component to improve initial page load performance
const PostSale = defineAsyncComponent(() => import('~/components/sale/PostSale.vue'));

// API and notifications
const { get } = useApi();
const { showNotification } = useNotifications();
const route = useRoute();
const router = useRouter();

// Component state variables
const loading = ref(true);
const posts = ref([]);
const totalPosts = ref(0);
const currentPage = ref(1);
const perPage = ref(20);
const viewMode = ref('grid'); // grid or list
const showPostSaleModal = ref(false);
const isMobileFilterOpen = ref(false); // For mobile sidebar toggle
const categories = ref([]);
const categoryName = ref('');

// Filter variables
const filters = ref({
  category: null, // Category ID
  subcategory: '', // For property_type, vehicle_type, or electronics_type
  division: '',
  district: '',
  area: '',
  minPrice: '',
  maxPrice: '',
  condition: '',
  search: '',
  sort: 'newest' // Default sort option
});

// Location data from PostSale component (Bangladesh divisions, districts, areas)
const divisions = [
  'Dhaka',
  'Chittagong',
  'Khulna',
  'Rajshahi',
  'Barisal',
  'Sylhet',
  'Rangpur',
  'Mymensingh'
];

// Districts by division
const districtsByDivision = {
  'Dhaka': ['Dhaka', 'Gazipur', 'Narayanganj', 'Tangail', 'Narsingdi', 'Munshiganj', 'Manikganj'],
  'Chittagong': ['Chittagong', 'Cox\'s Bazar', 'Comilla', 'Chandpur', 'Noakhali', 'Feni'],
  'Khulna': ['Khulna', 'Jessore', 'Kushtia', 'Bagerhat', 'Satkhira', 'Chuadanga'],
  'Rajshahi': ['Rajshahi', 'Bogra', 'Pabna', 'Sirajganj', 'Naogaon', 'Natore'],
  'Barisal': ['Barisal', 'Bhola', 'Patuakhali', 'Pirojpur', 'Jhalokati', 'Barguna'],
  'Sylhet': ['Sylhet', 'Moulvibazar', 'Habiganj', 'Sunamganj'],
  'Rangpur': ['Rangpur', 'Dinajpur', 'Kurigram', 'Gaibandha', 'Nilphamari', 'Panchagarh'],
  'Mymensingh': ['Mymensingh', 'Jamalpur', 'Sherpur', 'Netrokona']
};

// Areas by district (common areas for major districts)
const areasByDistrict = {
  'Dhaka': ['Uttara', 'Mirpur', 'Dhanmondi', 'Gulshan', 'Mohammadpur', 'Bashundhara', 'Banani', 'Motijheel', 'Khilgaon', 'Rampura'],
  'Chittagong': ['Agrabad', 'Pahartali', 'Nasirabad', 'Halishahar', 'GEC', 'Chawkbazar', 'Patenga', 'Khulshi'],
  'Khulna': ['Khulna Sadar', 'Sonadanga', 'Khalishpur', 'Daulatpur', 'Rupsha', 'Khan Jahan Ali'],
  'Rajshahi': ['Rajshahi Sadar', 'Boalia', 'Motihar', 'Shah Makhdum', 'Paba'],
  'Gazipur': ['Gazipur Sadar', 'Tongi', 'Sreepur', 'Kaliganj', 'Kaliakair', 'Kapasia'],
  'Narayanganj': ['Narayanganj Sadar', 'Rupganj', 'Araihazar', 'Sonargaon', 'Bandar']
  // Add more areas as needed
};

// Dynamic options for districts based on selected division
const districtOptions = computed(() => {
  if (!filters.value.division) return [];
  return districtsByDivision[filters.value.division] || [];
});

// Dynamic options for areas based on selected district
const areaOptions = computed(() => {
  if (!filters.value.district) return [];
  return areasByDistrict[filters.value.district] || [];
});

// Condition options
const conditions = [
  { label: 'Brand New', value: 'brand-new' },
  { label: 'Like New', value: 'like-new' },
  { label: 'Good', value: 'good' },
  { label: 'Fair', value: 'fair' },
  { label: 'For Parts', value: 'for-parts' }
];

// Sort options
const sortOptions = [
  { label: 'Newest First', value: 'newest' },
  { label: 'Oldest First', value: 'oldest' },
  { label: 'Price: Low to High', value: 'price_low' },
  { label: 'Price: High to Low', value: 'price_high' },
  { label: 'Most Viewed', value: 'most_viewed' }
];

// Dynamic subcategory label based on selected category
const subcategoryLabel = computed(() => {
  switch (parseInt(filters.value.category)) {
    case 1: return 'Property Type';
    case 2: return 'Vehicle Type';
    case 3: return 'Electronics Type';
    default: return 'Type';
  }
});

// Dynamic subcategory options based on selected category
const subcategoryOptions = computed(() => {
  switch (parseInt(filters.value.category)) {
    case 1: // Properties
      return [
        { label: 'Apartment', value: 'apartment' },
        { label: 'House', value: 'house' },
        { label: 'Land', value: 'land' },
        { label: 'Commercial Space', value: 'commercial' },
        { label: 'Office Space', value: 'office' }
      ];
    case 2: // Vehicles
      return [
        { label: 'Car', value: 'car' },
        { label: 'Motorcycle', value: 'motorcycle' },
        { label: 'Bicycle', value: 'bicycle' },
        { label: 'Truck', value: 'truck' },
        { label: 'Bus', value: 'bus' },
        { label: 'Other Vehicle', value: 'other' }
      ];
    case 3: // Electronics
      return [
        { label: 'Smartphone', value: 'smartphone' },
        { label: 'Laptop', value: 'laptop' },
        { label: 'Tablet', value: 'tablet' },
        { label: 'Desktop Computer', value: 'desktop' },
        { label: 'Camera', value: 'camera' },
        { label: 'Television', value: 'tv' },
        { label: 'Audio Equipment', value: 'audio' },
        { label: 'Gaming Console', value: 'gaming' },
        { label: 'Home Appliance', value: 'appliance' },
        { label: 'Other Electronics', value: 'other' }
      ];
    default:
      return [];
  }
});

// Computed properties
const totalPages = computed(() => Math.ceil(totalPosts.value / perPage.value));

const hasActiveFilters = computed(() => {
  return filters.value.category || 
    filters.value.subcategory ||
    filters.value.division || 
    filters.value.district ||
    filters.value.area ||
    filters.value.minPrice || 
    filters.value.maxPrice || 
    filters.value.condition || 
    filters.value.search;
});

// Initialize data
onMounted(async () => {
  // Parse URL parameters and set initial filters
  const { 
    category, subcategory, 
    division, district, area, 
    minPrice, maxPrice, 
    condition, search, sort, page 
  } = route.query;
  
  if (category) filters.value.category = parseInt(category);
  if (subcategory) filters.value.subcategory = subcategory;
  if (division) filters.value.division = division;
  if (district) filters.value.district = district;
  if (area) filters.value.area = area;
  if (minPrice) filters.value.minPrice = minPrice;
  if (maxPrice) filters.value.maxPrice = maxPrice;
  if (condition) filters.value.condition = condition;
  if (search) filters.value.search = search;
  if (sort) filters.value.sort = sort;
  if (page) currentPage.value = parseInt(page) || 1;
  
  await Promise.all([
    fetchCategories(),
    loadPosts(currentPage.value)
  ]);
  
  // Set category name if category filter is active
  if (filters.value.category) {
    setCategoryName(filters.value.category);
  }
  
  // Close mobile sidebar initially
  isMobileFilterOpen.value = false;

  // Add event listener for clicking outside the sidebar
  window.addEventListener('click', handleClickOutside);
});

// Remove event listener on component unmount
onUnmounted(() => {
  window.removeEventListener('click', handleClickOutside);
});

// Watch for filter changes to update URL
watch(filters, (newFilters) => {
  const query = {};
  
  if (newFilters.category) query.category = newFilters.category;
  if (newFilters.subcategory) query.subcategory = newFilters.subcategory;
  if (newFilters.division) query.division = newFilters.division;
  if (newFilters.district) query.district = newFilters.district;
  if (newFilters.area) query.area = newFilters.area;
  if (newFilters.minPrice) query.minPrice = newFilters.minPrice;
  if (newFilters.maxPrice) query.maxPrice = newFilters.maxPrice;
  if (newFilters.condition) query.condition = newFilters.condition;
  if (newFilters.search) query.search = newFilters.search;
  if (newFilters.sort && newFilters.sort !== 'newest') query.sort = newFilters.sort;
  if (currentPage.value > 1) query.page = currentPage.value;
  
  // Update URL without reloading the page
  router.replace({ query });
}, { deep: true });

watch(currentPage, (newPage) => {
  const query = { ...route.query, page: newPage > 1 ? newPage : undefined };
  if (newPage === 1) delete query.page;
  
  // Update URL without reloading the page
  router.replace({ query });
});

// Fetch categories from the API
async function fetchCategories() {
  try {
    // Update to use the correct endpoint
    const response = await get('/sale/categories/');
    if (response && Array.isArray(response.data)) {
      categories.value = response.data;
    } else {
      // Default categories if API fails
      categories.value = [
        { id: 1, name: 'Properties' },
        { id: 2, name: 'Vehicles' },
        { id: 3, name: 'Electronics' },
        { id: 4, name: 'Sports' },
        { id: 5, name: 'B2B' },
        { id: 6, name: 'Others' }
      ];
    }
  } catch (error) {
    console.error('Error fetching categories:', error);
    // Set default categories
    categories.value = [
      { id: 1, name: 'Properties' },
      { id: 2, name: 'Vehicles' },
      { id: 3, name: 'Electronics' },
      { id: 4, name: 'Sports' },
      { id: 5, name: 'B2B' },
      { id: 6, name: 'Others' }
    ];
  }
}

// Load posts based on current filters
async function loadPosts(page = 1) {
  loading.value = true;
  currentPage.value = page;
  
  // Close mobile sidebar when loading posts
  isMobileFilterOpen.value = false;
  
  try {
    // Construct the API query parameters
    const queryParams = {
      page,
      page_size: perPage.value,
      ordering: filters.value.sort === '' ? '-created_at' : filters.value.sort
    };
    
    // Add category filter
    if (filters.value.category) {
      queryParams.category = filters.value.category;
    }
    
    // Add child category filter if available
    if (filters.value.subcategory) {
      queryParams.child_category = filters.value.subcategory;
    }
    
    // Add condition filter
    if (filters.value.condition) {
      queryParams.condition = filters.value.condition;
    }
    
    // Add price range
    if (filters.value.minPrice) {
      queryParams.min_price = filters.value.minPrice;
    }
    
    if (filters.value.maxPrice) {
      queryParams.max_price = filters.value.maxPrice;
    }
    
    // Add location filters
    if (filters.value.division) {
      queryParams.division = filters.value.division;
    }
    
    if (filters.value.district) {
      queryParams.district = filters.value.district;
    }
    
    if (filters.value.area) {
      queryParams.area = filters.value.area;
    }
    
    // Add specific category type filters if needed
    if (filters.value.category === 'electronics' && filters.value.subcategory) {
      queryParams.electronics_type = filters.value.subcategory;
    }
    
    // Add sorting
    switch (filters.value.sort) {
      case 'oldest':
        queryParams.ordering = 'created_at';
        break;
      case 'price_low':
        queryParams.ordering = 'price';
        break;
      case 'price_high':
        queryParams.ordering = '-price';
        break;
      case 'most_viewed':
        queryParams.ordering = '-view_count';
        break;
      default:
        queryParams.ordering = '-created_at'; // newest first (default)
    }
    
    // Use the correct API endpoint
    const response = await get('/sale/posts/', { params: queryParams });
    
    if (response && response.data) {
      const data = response.data;
      
      // Handle paginated response
      if (data.results && Array.isArray(data.results)) {
        posts.value = data.results;
        totalPosts.value = data.count || data.results.length;
      }
      // Handle non-paginated response
      else if (Array.isArray(data)) {
        posts.value = data;
        totalPosts.value = data.length;
      }
    } else {
      posts.value = [];
      totalPosts.value = 0;
    }
  } catch (error) {
    console.error('Error loading posts:', error);
    posts.value = [];
    totalPosts.value = 0;
    showNotification({
      title: 'Error',
      content: 'Failed to load listings. Please try again.',
      type: 'error'
    });
  } finally {
    loading.value = false;
  }
}

// Category and subcategory handling
function handleCategoryChange() {
  // Reset subcategory when category changes
  filters.value.subcategory = '';
  loadPosts(1);
}

function clearCategoryFilter() {
  filters.value.category = null;
  filters.value.subcategory = '';
  categoryName.value = '';
  loadPosts(1);
}

function getSubcategoryLabel(value) {
  const option = subcategoryOptions.value.find(opt => opt.value === value);
  return option ? option.label : value;
}

// Location filter handling
function handleDivisionChange() {
  // Reset district and area when division changes
  filters.value.district = '';
  filters.value.area = '';
  loadPosts(1);
}

function handleDistrictChange() {
  // Reset area when district changes
  filters.value.area = '';
  loadPosts(1);
}

function clearDivisionFilter() {
  filters.value.division = '';
  filters.value.district = '';
  filters.value.area = '';
  loadPosts(1);
}

function clearDistrictFilter() {
  filters.value.district = '';
  filters.value.area = '';
  loadPosts(1);
}

// Helper functions
function getCategoryName(categoryId) {
  if (!categoryId) return '';
  const category = categories.value.find(c => c.id === parseInt(categoryId));
  return category ? category.name : '';
}

function setCategoryName(categoryId) {
  categoryName.value = getCategoryName(categoryId);
}

function getConditionLabel(conditionValue) {
  const condition = conditions.find(c => c.value === conditionValue);
  return condition ? condition.label : 'Unknown';
}

function formatPrice(price) {
  return new Intl.NumberFormat('en-IN').format(price);
}

function formatDate(dateString) {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  
  return date.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
}

function getPostImage(post) {
  // Get API static URL from composable
  const { staticURL } = useApi();
  
  // Handle main_image from API response
  if (post.main_image) {
    return post.main_image.startsWith('http') ? post.main_image : `${staticURL}${post.main_image}`;
  }
  
  // Handle images array if provided
  if (post.images && post.images.length > 0) {
    // Find main image or use first image
    const mainImage = post.images.find(img => img.is_main) || post.images[0];
    
    // Handle different image data structures
    if (typeof mainImage === 'string') {
      return mainImage.startsWith('http') ? mainImage : `${staticURL}${mainImage}`;
    } else if (mainImage.image) {
      const imgUrl = typeof mainImage.image === 'string' ? mainImage.image : mainImage.image.url || '';
      return imgUrl.startsWith('http') ? imgUrl : `${staticURL}${imgUrl}`;
    }
  }
  
  // Fallback image
  return 'https://via.placeholder.com/300/3b82f6/FFFFFF?text=No+Image';
}

// Property type formatter
function propertyTypeLabel(type) {
  const labels = {
    'apartment': 'Apartment',
    'house': 'House',
    'land': 'Land',
    'commercial': 'Commercial Space',
    'office': 'Office Space'
  };
  return labels[type] || type;
}

// Warranty formatter
function warrantyLabel(warranty) {
  const labels = {
    'under-warranty': 'Under Warranty',
    'expired': 'Warranty Expired',
    'no-warranty': 'No Warranty'
  };
  return labels[warranty] || warranty;
}

// Filter actions
function clearPriceFilter() {
  filters.value.minPrice = '';
  filters.value.maxPrice = '';
  loadPosts(1);
}

function clearAllFilters() {
  filters.value = {
    category: null,
    subcategory: '',
    division: '',
    district: '',
    area: '',
    minPrice: '',
    maxPrice: '',
    condition: '',
    search: '',
    sort: 'newest'
  };
  categoryName.value = '';
  loadPosts(1);
}

// Modal actions
function openPostSaleModal() {
  showPostSaleModal.value = true;
}

function onPostSaved() {
  showPostSaleModal.value = false;
  showNotification({
    title: 'Success',
    text: 'Your listing has been submitted successfully!',
    type: 'success'
  });
  loadPosts(1);
}

// Function to handle clicking outside the sidebar
function handleClickOutside(event) {
  // Only consider this when mobile sidebar is open
  if (!isMobileFilterOpen.value) return;
  
  // Get the sidebar element
  const sidebar = document.querySelector('.filter-sidebar');
  
  // Get the toggle button - make sure we're getting the right element
  const toggleButton = document.querySelector('button[class*="lg:hidden fixed left-0"]');
  
  // If click is outside sidebar and not on toggle button, close sidebar
  if (sidebar && 
      !sidebar.contains(event.target) && 
      toggleButton && 
      !toggleButton.contains(event.target)) {
    isMobileFilterOpen.value = false;
  }
}
</script>

<style scoped>
.filter-sidebar {
  height: calc(100vh - 180px);
  position: sticky;
  top: 100px;
  overflow-y: auto;
  margin-top: 1rem; /* Added margin to account for the header */
}

/* Mobile sidebar styles */
@media (max-width: 1023px) {
  .filter-sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    width: 300px;
    z-index: 50;
    transition: transform 0.3s ease-in-out;
    box-shadow: 0 0 15px rgba(0, 0, 0, 0.1);
    margin-top: 0; /* Reset margin for mobile sidebar since it's fixed */
  }
  
  .mobile-sidebar-closed {
    transform: translateX(-100%);
  }
  
  .mobile-sidebar-open {
    transform: translateX(0);
  }
}

/* Line clamp utility for truncating text */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Listing card animations */
.listing-card {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.listing-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 15px rgba(0, 0, 0, 0.08);
}

/* Price badge hover effect */
.price-badge {
  transition: transform 0.2s ease;
}

.price-badge:hover {
  transform: scale(1.05);
}

/* Image hover effect */
.aspect-\[4\/3\] img {
  transition: transform 0.5s ease, filter 0.3s ease;
}

.listing-card:hover .aspect-\[4\/3\] img {
  transform: scale(1.05);
}
</style>