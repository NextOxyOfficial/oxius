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
        <div class="w-full lg:w-64 flex-shrink-0 order-2 lg:order-1">
          <!-- Mobile Filter Toggle -->
          <div class="block lg:hidden mb-4">
            <UButton
              block
              color="gray"
              variant="soft"
              @click="showMobileFilters = !showMobileFilters"
              class="flex justify-between items-center"
            >
              <span class="flex items-center gap-2">
                <UIcon name="i-heroicons-funnel" />
                Filters
              </span>
              <UIcon :name="showMobileFilters ? 'i-heroicons-chevron-up' : 'i-heroicons-chevron-down'" />
            </UButton>
          </div>

          <!-- Filter Sidebar -->
          <div :class="[showMobileFilters ? 'block' : 'hidden lg:block']">
            <UCard class="mb-4">
              <template #header>
                <div class="font-medium">Categories</div>
              </template>
              
              <div class="space-y-1">
                <URadio 
                  v-model="selectedCategory"
                  value=""
                  label="All Categories" 
                  @change="clearSubcategory"
                />
                <URadio 
                  v-for="category in categories" 
                  :key="category.id" 
                  v-model="selectedCategory" 
                  :value="category.id.toString()" 
                  :label="category.name" 
                  @change="clearSubcategory"
                />
              </div>
            </UCard>

            <UCard class="mb-4" v-if="selectedCategory && subcategories.length > 0">
              <template #header>
                <div class="font-medium">{{ subcategoryTitle }}</div>
              </template>
              
              <div class="space-y-1">
                <URadio 
                  v-model="selectedSubcategory" 
                  value="" 
                  :label="`All ${getCategoryName(selectedCategory)}`" 
                />
                <URadio 
                  v-for="subcategory in subcategories" 
                  :key="subcategory.id" 
                  v-model="selectedSubcategory" 
                  :value="subcategory.id.toString()" 
                  :label="subcategory.name" 
                />
              </div>
            </UCard>

            <UCard class="mb-4">
              <template #header>
                <div class="font-medium">Location</div>
              </template>

              <div class="space-y-3">
                <!-- Division/City Selection -->
                <div>
                  <UFormGroup label="Division">
                    <USelect
                      v-model="selectedDivision"
                      :options="divisions"
                      placeholder="Select division"
                      @update:modelValue="onDivisionChange"
                    />
                  </UFormGroup>
                </div>

                <!-- District Selection -->
                <div>
                  <UFormGroup label="District">
                    <USelect
                      v-model="selectedDistrict"
                      :options="districtOptions"
                      placeholder="Select district"
                      :disabled="!selectedDivision"
                      @update:modelValue="onDistrictChange"
                    />
                  </UFormGroup>
                </div>

                <!-- Area Selection -->
                <div>
                  <UFormGroup label="Area">
                    <USelect
                      v-model="selectedArea"
                      :options="areaOptions"
                      placeholder="Select area"
                      :disabled="!selectedDistrict"
                    />
                  </UFormGroup>
                </div>
              </div>
            </UCard>

            <UCard class="mb-4">
              <template #header>
                <div class="font-medium">Price Range</div>
              </template>

              <div class="space-y-3">
                <div class="grid grid-cols-2 gap-2">
                  <UFormGroup label="Min">
                    <UInput
                      v-model="priceRange.min"
                      type="number"
                      placeholder="Min Price"
                      icon="i-mdi:currency-bdt"
                    />
                  </UFormGroup>
                  <UFormGroup label="Max">
                    <UInput
                      v-model="priceRange.max"
                      type="number"
                      placeholder="Max Price"
                      icon="i-mdi:currency-bdt"
                    />
                  </UFormGroup>
                </div>
              </div>
            </UCard>

            <UCard class="mb-4">
              <template #header>
                <div class="font-medium">Condition</div>
              </template>

              <div class="space-y-1">
                <URadio 
                  v-model="selectedCondition" 
                  value="" 
                  label="Any Condition" 
                />
                <URadio 
                  v-for="condition in conditions" 
                  :key="condition.value" 
                  v-model="selectedCondition" 
                  :value="condition.value" 
                  :label="condition.label" 
                />
              </div>
            </UCard>

            <div class="flex gap-2">
              <UButton 
                color="primary" 
                block 
                @click="applyFilters"
              >
                Apply Filters
              </UButton>
              <UButton 
                color="gray" 
                variant="outline" 
                @click="clearFilters"
              >
                Clear
              </UButton>
            </div>
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
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from '#app';

const route = useRoute();
const router = useRouter();

// State variables
const loading = ref(true);
const viewMode = ref('grid');
const showMobileFilters = ref(false);
const searchQuery = ref('');
const selectedCategory = ref('');
const selectedSubcategory = ref('');
const selectedDivision = ref('');
const selectedDistrict = ref('');
const selectedArea = ref('');
const selectedCondition = ref('');
const currentPage = ref(1);
const priceRange = ref({
  min: '',
  max: ''
});
const sortOption = ref('newest');

// Data variables
const listings = ref([]);
const totalListings = ref(0);
const totalPages = ref(1);
const itemsPerPage = 20;

// Categories and Subcategories
const categories = ref([
  { id: 1, name: 'Properties' },
  { id: 2, name: 'Vehicles' },
  { id: 3, name: 'Electronics' },
  { id: 4, name: 'Mobiles' },
  { id: 5, name: 'Home & Living' },
  { id: 6, name: 'Sports & Hobbies' },
  { id: 7, name: 'Businesses & Industry' },
  { id: 8, name: 'Fashion & Beauty' },
  { id: 9, name: 'Pets & Animals' },
  { id: 10, name: 'Jobs' },
  { id: 11, name: 'Services' },
  { id: 12, name: 'Education' }
]);

// Property types
const propertySubcategories = [
  { id: 'apartment', name: 'Apartment' },
  { id: 'house', name: 'House' },
  { id: 'plot', name: 'Plot & Land' },
  { id: 'commercial', name: 'Commercial Property' },
  { id: 'room', name: 'Room' }
];

// Vehicle types
const vehicleSubcategories = [
  { id: 'car', name: 'Car' },
  { id: 'motorcycle', name: 'Motorcycle' },
  { id: 'bicycle', name: 'Bicycle' },
  { id: 'truck', name: 'Truck' },
  { id: 'auto-rickshaw', name: 'Auto Rickshaw' },
  { id: 'other', name: 'Other Vehicles' }
];

// Electronics types
const electronicsSubcategories = [
  { id: 'tv', name: 'Televisions' },
  { id: 'computer', name: 'Desktop Computers' },
  { id: 'laptop', name: 'Laptops' },
  { id: 'kitchen', name: 'Kitchen Appliances' },
  { id: 'camera', name: 'Cameras & Camcorders' },
  { id: 'audio', name: 'Audio & Sound Systems' },
  { id: 'gaming', name: 'Video Games & Consoles' }
];

// Mobile types
const mobileSubcategories = [
  { id: 'android', name: 'Android Phones' },
  { id: 'iphone', name: 'iPhones' },
  { id: 'feature-phone', name: 'Feature Phones' },
  { id: 'tablet', name: 'Tablets' },
  { id: 'accessories', name: 'Mobile Accessories' }
];

// Condition options
const conditions = [
  { label: 'New', value: 'new' },
  { label: 'Used - Like New', value: 'like-new' },
  { label: 'Used - Good', value: 'good' },
  { label: 'Used - Fair', value: 'fair' }
];

// Sort options
const sortOptions = [
  { label: 'Newest First', value: 'newest' },
  { label: 'Oldest First', value: 'oldest' },
  { label: 'Price: Low to High', value: 'price_asc' },
  { label: 'Price: High to Low', value: 'price_desc' },
  { label: 'Most Relevant', value: 'relevance' }
];

// Divisions (Bangladesh)
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
  'Dhaka': ['Dhaka', 'Gazipur', 'Narayanganj', 'Tangail'], 
  'Chittagong': ['Chittagong', 'Cox\'s Bazar', 'Comilla'],
  'Khulna': ['Khulna', 'Jessore', 'Kushtia'],
  'Rajshahi': ['Rajshahi', 'Bogra', 'Pabna'],
  'Barisal': ['Barisal', 'Bhola', 'Patuakhali'],
  'Sylhet': ['Sylhet', 'Moulvibazar', 'Habiganj'],
  'Rangpur': ['Rangpur', 'Dinajpur', 'Kurigram'],
  'Mymensingh': ['Mymensingh', 'Jamalpur', 'Netrokona']
};

// Areas by district
const areasByDistrict = {
  'Dhaka': ['Uttara', 'Mirpur', 'Dhanmondi', 'Gulshan', 'Mohammadpur', 'Banani'],
  'Chittagong': ['Agrabad', 'Nasirabad', 'Halishahar', 'Khulshi'],
  'Khulna': ['Sonadanga', 'Khalishpur', 'Daulatpur'],
  'Gazipur': ['Tongi', 'Gazipur Sadar', 'Joydebpur']
};

// Computed properties
const subcategories = computed(() => {
  if (!selectedCategory.value) return [];
  
  const categoryId = parseInt(selectedCategory.value);
  
  switch (categoryId) {
    case 1: return propertySubcategories;
    case 2: return vehicleSubcategories;
    case 3: return electronicsSubcategories;
    case 4: return mobileSubcategories;
    default: return [];
  }
});

const subcategoryTitle = computed(() => {
  const categoryId = parseInt(selectedCategory.value);
  
  switch (categoryId) {
    case 1: return 'Property Type';
    case 2: return 'Vehicle Type';
    case 3: return 'Electronic Type';
    case 4: return 'Mobile Type';
    default: return 'Type';
  }
});

const districtOptions = computed(() => {
  if (!selectedDivision.value) return [];
  return districtsByDivision[selectedDivision.value] || [];
});

const areaOptions = computed(() => {
  if (!selectedDistrict.value) return [];
  return areasByDistrict[selectedDistrict.value] || [];
});

const hasActiveFilters = computed(() => {
  return selectedCategory.value !== '' || 
         selectedSubcategory.value !== '' || 
         selectedDivision.value || 
         selectedDistrict.value || 
         selectedArea.value || 
         selectedCondition.value !== '' || 
         priceRange.value.min || 
         priceRange.value.max ||
         searchQuery.value;
});

// Helper functions
function getCategoryName(categoryId) {
  if (!categoryId) return '';
  const category = categories.value.find(c => c.id === parseInt(categoryId));
  return category ? category.name : '';
}

function getSubcategoryName(subcategoryId) {
  if (!subcategoryId) return '';
  const subcategory = subcategories.value.find(s => s.id === subcategoryId);
  return subcategory ? subcategory.name : '';
}

function getConditionLabel(conditionValue) {
  if (!conditionValue) return '';
  const condition = conditions.find(c => c.value === conditionValue);
  return condition ? condition.label : '';
}

function formatDate(dateString) {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) {
    return 'Today';
  } else if (diffDays === 1) {
    return 'Yesterday';
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7);
    return `${weeks} ${weeks === 1 ? 'week' : 'weeks'} ago`;
  } else {
    return date.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
  }
}

function formatPrice(price) {
  if (!price) return '';
  return new Intl.NumberFormat('en-IN').format(price);
}

function getListingImage(listing) {
  if (listing.main_image) {
    return listing.main_image;
  }
  
  if (listing.images && listing.images.length > 0) {
    // Extract image URL depending on the structure
    if (typeof listing.images[0] === 'string') {
      return listing.images[0];
    } else if (listing.images[0].image) {
      return listing.images[0].image;
    }
  }
  
  // Return a placeholder image if no image is available
  return 'https://via.placeholder.com/400x300?text=No+Image';
}

// Filter action methods
function clearCategory() {
  selectedCategory.value = '';
  selectedSubcategory.value = '';
}

function clearSubcategory() {
  selectedSubcategory.value = '';
}

function clearLocation() {
  selectedDivision.value = '';
  selectedDistrict.value = '';
  selectedArea.value = '';
}

function clearPriceRange() {
  priceRange.value = {
    min: '',
    max: ''
  };
}

function clearFilters() {
  searchQuery.value = '';
  selectedCategory.value = '';
  selectedSubcategory.value = '';
  selectedDivision.value = '';
  selectedDistrict.value = '';
  selectedArea.value = '';
  selectedCondition.value = '';
  priceRange.value = {
    min: '',
    max: ''
  };
  sortOption.value = 'newest';
  currentPage.value = 1;
  
  // Apply filters (fetch data)
  applyFilters();
}

// Location filter handlers
function onDivisionChange() {
  selectedDistrict.value = '';
  selectedArea.value = '';
}

function onDistrictChange() {
  selectedArea.value = '';
}

// Pagination
function onPageChange(page) {
  currentPage.value = page;
  fetchListings();
  
  // Scroll to top of results
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Apply filters method
function applyFilters() {
  currentPage.value = 1;
  fetchListings();
  
  // Update URL query parameters
  updateUrlParams();
}

// Update URL parameters based on current filters
function updateUrlParams() {
  const query = {};
  
  if (searchQuery.value) query.q = searchQuery.value;
  if (selectedCategory.value) query.category = selectedCategory.value;
  if (selectedSubcategory.value) query.subcategory = selectedSubcategory.value;
  if (selectedDivision.value) query.division = selectedDivision.value;
  if (selectedDistrict.value) query.district = selectedDistrict.value;
  if (selectedArea.value) query.area = selectedArea.value;
  if (selectedCondition.value) query.condition = selectedCondition.value;
  if (priceRange.value.min) query.min_price = priceRange.value.min;
  if (priceRange.value.max) query.max_price = priceRange.value.max;
  if (sortOption.value !== 'newest') query.sort = sortOption.value;
  if (currentPage.value > 1) query.page = currentPage.value;
  
  // Update URL without refreshing the page
  router.replace({ query });
}

// Fetch listings from API
async function fetchListings() {
  loading.value = true;
  
  try {
    // Build query params
    const params = new URLSearchParams();
    params.append('page', currentPage.value);
    params.append('page_size', itemsPerPage);
    
    if (searchQuery.value) params.append('search', searchQuery.value);
    if (selectedCategory.value) params.append('category', selectedCategory.value);
    if (selectedSubcategory.value) params.append('subcategory', selectedSubcategory.value);
    if (selectedDivision.value) params.append('division', selectedDivision.value);
    if (selectedDistrict.value) params.append('district', selectedDistrict.value);
    if (selectedArea.value) params.append('area', selectedArea.value);
    if (selectedCondition.value) params.append('condition', selectedCondition.value);
    if (priceRange.value.min) params.append('min_price', priceRange.value.min);
    if (priceRange.value.max) params.append('max_price', priceRange.value.max);
    
    // Handle sorting
    switch (sortOption.value) {
      case 'newest':
        params.append('ordering', '-created_at');
        break;
      case 'oldest':
        params.append('ordering', 'created_at');
        break;
      case 'price_asc':
        params.append('ordering', 'price');
        break;
      case 'price_desc':
        params.append('ordering', '-price');
        break;
      case 'relevance':
        // Relevance is usually handled by the search engine
        break;
    }
    
    // Make API request
    // const response = await fetch(`/api/sale/posts?${params.toString()}`);
    // const data = await response.json();
    
    // For demo, we'll simulate API response with mock data
    // In a real application, you'd use the actual API endpoint
    await new Promise(resolve => setTimeout(resolve, 800));
    
    const mockData = generateMockListings(selectedCategory.value);
    
    // Update state
    listings.value = mockData.results;
    totalListings.value = mockData.count;
    totalPages.value = Math.ceil(mockData.count / itemsPerPage);
    
  } catch (error) {
    console.error('Error fetching listings:', error);
    listings.value = [];
    totalListings.value = 0;
    totalPages.value = 0;
  } finally {
    loading.value = false;
  }
}

// Mock data generator
function generateMockListings(categoryId) {
  const count = Math.floor(Math.random() * 50) + 30; // 30-80 listings
  const results = [];
  
  for (let i = 0; i < Math.min(count, itemsPerPage); i++) {
    const id = i + 1;
    const categoryIdInt = parseInt(categoryId) || Math.floor(Math.random() * 5) + 1;
    
    let mockListing = {
      id,
      slug: `listing-${id}`,
      title: getRandomTitle(categoryIdInt),
      category: categoryIdInt,
      price: Math.floor(Math.random() * 500000) + 1000,
      negotiable: Math.random() > 0.7,
      condition: conditions[Math.floor(Math.random() * conditions.length)].value,
      division: 'Dhaka',
      district: 'Dhaka',
      area: 'Uttara',
      featured: Math.random() > 0.9,
      status: Math.random() > 0.9 ? 'sold' : 'available',
      created_at: new Date(Date.now() - Math.floor(Math.random() * 30) * 24 * 60 * 60 * 1000).toISOString(),
      main_image: `https://picsum.photos/id/${id + 50}/600/400`
    };
    
    // Add category-specific fields
    if (categoryIdInt === 1) { // Properties
      mockListing = {
        ...mockListing,
        property_type: propertySubcategories[Math.floor(Math.random() * propertySubcategories.length)].id,
        bedrooms: Math.floor(Math.random() * 5) + 1,
        size: Math.floor(Math.random() * 2000) + 500,
        unit: 'sqft'
      };
    } else if (categoryIdInt === 2) { // Vehicles
      mockListing = {
        ...mockListing,
        make: ['Toyota', 'Honda', 'Nissan', 'Ford', 'BMW', 'Mercedes'][Math.floor(Math.random() * 6)],
        model: ['Corolla', 'Civic', 'Sunny', 'Focus', '3 Series', 'C Class'][Math.floor(Math.random() * 6)],
        year: 2010 + Math.floor(Math.random() * 14)
      };
    } else if (categoryIdInt === 3) { // Electronics
      mockListing = {
        ...mockListing,
        brand: ['Samsung', 'LG', 'Sony', 'Apple', 'Dell', 'HP'][Math.floor(Math.random() * 6)],
        model: ['Galaxy', 'UHD', 'Bravia', 'MacBook', 'Inspiron', 'Pavilion'][Math.floor(Math.random() * 6)]
      };
    }
    
    results.push(mockListing);
  }
  
  return {
    count,
    results
  };
}

function getRandomTitle(categoryId) {
  const titles = {
    1: [ // Properties
      'Spacious 3 Bedroom Apartment in Prime Location',
      'Luxury Villa with Swimming Pool',
      'Modern Studio Apartment for Rent',
      'Commercial Space in Business District',
      'Beautiful House with Garden'
    ],
    2: [ // Vehicles
      'Toyota Corolla in Excellent Condition',
      'Honda CBR 150R Sports Bike',
      'Ford Ranger Pickup Truck',
      'Mercedes C200 Low Mileage',
      'Hero Bicycle Almost New'
    ],
    3: [ // Electronics
      'Samsung 55" 4K Smart TV',
      'MacBook Pro M1 16GB RAM',
      'Sony PlayStation 5 with Games',
      'Dell XPS Desktop Computer',
      'Canon EOS DSLR Camera'
    ],
    4: [ // Mobiles
      'iPhone 13 Pro Max 256GB',
      'Samsung Galaxy S22 Ultra',
      'Xiaomi Redmi Note 10',
      'OnePlus 10 Pro 5G',
      'Google Pixel 6 Pro'
    ],
    5: [ // Home & Living
      'Solid Wood Dining Table Set',
      'Modern L-shaped Sofa',
      'Queen Size Bed with Storage',
      'Samsung Double Door Refrigerator',
      'Toshiba Microwave Oven'
    ]
  };
  
  const categoryTitles = titles[categoryId] || titles[1];
  return categoryTitles[Math.floor(Math.random() * categoryTitles.length)];
}

// Initialize from URL parameters
function initFromUrlParams() {
  const { q, category, subcategory, division, district, area, condition, min_price, max_price, sort, page } = route.query;
  
  if (q) searchQuery.value = q;
  if (category) selectedCategory.value = category;
  if (subcategory) selectedSubcategory.value = subcategory;
  if (division) selectedDivision.value = division;
  if (district) selectedDistrict.value = district;
  if (area) selectedArea.value = area;
  if (condition) selectedCondition.value = condition;
  if (min_price) priceRange.value.min = min_price;
  if (max_price) priceRange.value.max = max_price;
  if (sort) sortOption.value = sort;
  if (page) currentPage.value = parseInt(page);
}

// Watch for filter changes to highlight the sidebar on mobile
watch([selectedCategory, selectedSubcategory, selectedCondition, selectedDivision, selectedDistrict], () => {
  if (window.innerWidth < 1024) {
    showMobileFilters.value = false;
  }
});

// Lifecycle hooks
onMounted(() => {
  initFromUrlParams();
  fetchListings();
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