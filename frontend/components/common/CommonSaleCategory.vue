<template>
  <div class="sale-categories py-6">
    <h2 class="text-2xl md:text-3xl text-center font-bold mb-8 text-gray-800 dark:text-white">
      Browse Sale Categories
    </h2>
    
    <!-- Sale Categories Grid -->
    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4 max-w-7xl mx-auto px-4">
      <!-- Loading placeholders -->
      <div 
        v-if="isLoading" 
        v-for="i in 6" 
        :key="i" 
        class="flex flex-col items-center p-4 rounded-xl bg-white dark:bg-slate-800 shadow-sm border border-slate-100 dark:border-slate-700 h-full"
      >
        <div class="w-16 h-16 mb-4 rounded-full bg-gray-200 dark:bg-gray-700 animate-pulse"></div>
        <div class="h-5 w-24 bg-gray-200 dark:bg-gray-700 rounded animate-pulse"></div>
        <div class="h-4 w-16 bg-gray-200 dark:bg-gray-700 rounded mt-2 animate-pulse"></div>
      </div>

      <!-- Categories -->
      <NuxtLink
        v-else
        v-for="category in categories"
        :key="category.id"
        :to="`/sale/categories/${category.id}`"
        class="category-card group"
      >
        <div class="flex flex-col items-center p-4 rounded-xl bg-white dark:bg-slate-800 shadow-sm hover:shadow-md transition-all duration-300 border border-slate-100 dark:border-slate-700 h-full">
          <!-- Category Icon with Fallback -->
          <div class="w-16 h-16 mb-4 flex items-center justify-center rounded-full bg-emerald-50 dark:bg-emerald-900/20 p-3 group-hover:scale-110 transition-transform duration-300">
            <img 
              v-if="category.icon" 
              :src="getImageUrl(category.icon)" 
              :alt="category.name" 
              class="w-10 h-10 object-contain"
              @error="handleImageError($event)"
            />
            <Icon 
              v-else
              :name="getCategoryIcon(category.name)" 
              class="w-8 h-8 text-emerald-500"
            />
          </div>
          
          <!-- Category Name -->
          <h3 class="text-center font-medium text-gray-800 dark:text-gray-200 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">
            {{ category.name }}
          </h3>
          
          <!-- Child Categories Count -->
          <span v-if="category.child_count > 0" class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            {{ category.child_count }} subcategories
          </span>
        </div>
      </NuxtLink>
    </div>
    
    <!-- View All Button -->
    <div class="text-center mt-8">
      <NuxtLink 
        to="/sale/categories"
        class="inline-flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg font-medium transition-colors duration-300 shadow-sm"
      >
        Browse All Categories
        <Icon name="heroicons:arrow-right" class="w-4 h-4" />
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
const { get } = useApi();

// Categories data
const categories = ref([]);
const isLoading = ref(true);

// Load categories data
const loadCategories = async () => {
  isLoading.value = true;
  
  try {
    const response = await get('/sale/categories/');
    const data = response.data.results || response.data;
    
    // Process each category to add child count
    const processedCategories = await Promise.all(data.map(async (category) => {
      try {
        const childResponse = await get(`/sale/categories/${category.id}/child-categories/`);
        const childData = childResponse.data.results || childResponse.data;
        return {
          ...category,
          child_count: childData ? childData.length : 0
        };
      } catch (err) {
        console.error(`Failed to load child categories for ${category.name}:`, err);
        return {
          ...category,
          child_count: 0
        };
      }
    }));
    
    categories.value = processedCategories;
  } catch (err) {
    console.error('Failed to load sale categories:', err);
  } finally {
    isLoading.value = false;
  }
};

// Helper function to construct full image URL
const getImageUrl = (path) => {
  if (!path) return "";
  const { staticURL } = useApi();

  // If path already starts with http(s) or //, it's a full URL
  if (path.match(/^(https?:)?\/\//)) {
    return path;
  }

  // Otherwise prepend static URL
  return `${staticURL}${path}`;
};

// Get appropriate icon for a category based on its name
const getCategoryIcon = (categoryName) => {
  const iconMap = {
    Properties: "heroicons:home-modern",
    Vehicles: "heroicons:truck",
    Electronics: "heroicons:device-phone-mobile",
    Sports: "heroicons:trophy",
    B2B: "heroicons:building-office",
    Fashion: "heroicons:shopping-bag",
    Services: "heroicons:wrench",
    Jobs: "heroicons:briefcase",
    Pets: "heroicons:heart",
    Books: "heroicons:book-open",
    Furniture: "heroicons:table"
  };

  return iconMap[categoryName] || "heroicons:shopping-bag";
};

// Handle image loading errors
const handleImageError = (event) => {
  event.target.src = '/placeholder-image.jpg';
  
  // Fallback to icon if placeholder image also fails to load
  event.target.onerror = () => {
    event.target.style.display = 'none';
    // Automatically switches to the icon since image is hidden
  };
};

onMounted(() => {
  loadCategories();
});
</script>

<style scoped>
.category-card {
  transition: transform 0.3s ease;
}

.category-card:hover {
  transform: translateY(-3px);
}

.animate-pulse {
  animation: pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}
</style>