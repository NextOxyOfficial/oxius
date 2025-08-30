<template>
  <div class="space-y-4">
    <!-- Loading skeleton -->
    <div v-if="isLoadingProducts" class="grid grid-cols-2 lg:grid-cols-3 gap-2">
      <div
        v-for="i in 6"
        :key="i"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden animate-pulse"
      >
        <div class="h-48 bg-gray-200"></div>
        <div class="p-4">
          <div class="h-5 w-full bg-gray-200 rounded mb-2"></div>
          <div class="h-4 w-3/4 bg-gray-200 rounded mb-3"></div>
          <div class="flex justify-between items-center">
            <div class="h-4 w-20 bg-gray-200 rounded"></div>
            <div class="h-6 w-16 bg-gray-200 rounded"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- User's Products Grid -->
    <div v-else-if="userProducts.length > 0" class="grid grid-cols-2 lg:grid-cols-3 gap-2">
      <div v-for="product in userProducts" :key="product.id" class="relative group">
        <!-- Product Card -->
        <CommonProductCard :product="product" />
        
        <!-- Management Overlay -->
        <div class="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
          <button
            @click="editProduct(product)"
            class="p-1.5 bg-white/90 backdrop-blur-sm text-gray-600 hover:text-blue-600 rounded-full shadow-sm transition-colors"
            title="Edit Product"
          >
            <Pencil class="w-4 h-4" />
          </button>
          <button
            @click="toggleProductStatus(product)"
            class="p-1.5 bg-white/90 backdrop-blur-sm rounded-full shadow-sm transition-colors"
            :class="product.is_active ? 'text-gray-600 hover:text-orange-600' : 'text-gray-600 hover:text-green-600'"
            :title="product.is_active ? 'Deactivate Product' : 'Activate Product'"
          >
            <EyeOff v-if="product.is_active" class="w-4 h-4" />
            <Eye v-else class="w-4 h-4" />
          </button>
        </div>

        <!-- Status Badge -->
        <div class="absolute top-2 left-2">
          <span
            class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
            :class="getStatusBadgeClass(product)"
          >
            {{ getStatusLabel(product) }}
          </span>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="text-center py-12">
      <div class="mx-auto h-24 w-24 rounded-full bg-gray-100 flex items-center justify-center mb-4">
        <ShoppingBag class="h-12 w-12 text-gray-400" />
      </div>
      <h3 class="text-lg font-medium text-gray-900 mb-2">No products yet</h3>
      <p class="text-gray-600 mb-6">You haven't added any products to your shop.</p>
      <button
        @click="createProduct"
        class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
      >
        <Plus class="w-4 h-4 mr-2" />
        Add Your First Product
      </button>
    </div>
  </div>
</template>

<script setup>
import { Pencil, Eye, EyeOff, ShoppingBag, Plus } from 'lucide-vue-next';
import { useApi } from '~/composables/useApi';
import CommonProductCard from '~/components/common/product-card.vue';

// Props
const props = defineProps({
  userProducts: {
    type: Array,
    default: () => []
  },
  isLoadingProducts: {
    type: Boolean,
    default: false
  }
});

// Emits
const emit = defineEmits([
  'edit-product',
  'toggle-product-status', 
  'create-product'
]);

const { patch } = useApi();
const toast = useToast();

// Methods
const getStatusBadgeClass = (product) => {
  if (!product.is_active) {
    return 'bg-gray-100 text-gray-800';
  } else if (product.quantity <= 0) {
    return 'bg-red-100 text-red-800';
  } else {
    return 'bg-green-100 text-green-800';
  }
};

const getStatusLabel = (product) => {
  if (!product.is_active) {
    return 'Inactive';
  } else if (product.quantity <= 0) {
    return 'Out of Stock';
  } else {
    return 'Active';
  }
};

const editProduct = (product) => {
  emit('edit-product', product);
};

const toggleProductStatus = async (product) => {
  try {
    const res = await patch(`/products/${product.slug}/`, {
      is_active: !product.is_active,
    });

    if (res.data) {
      // Update the local product status
      product.is_active = res.data.is_active;
      
      toast.add({
        title: "Status Changed",
        description: `${product.name} is now ${
          res.data.is_active ? "active" : "inactive"
        }.`,
        color: "green",
      });

      emit('toggle-product-status', product);
    }
  } catch (error) {
    console.error("Error toggling product status:", error);
    toast.add({
      title: "Status Change Failed", 
      description: "There was an error changing the product status.",
      color: "red",
    });
  }
};

const createProduct = () => {
  emit('create-product');
};
</script>

<style scoped>
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

.animate-fadeIn {
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
