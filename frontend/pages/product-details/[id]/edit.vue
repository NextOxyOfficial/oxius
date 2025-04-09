<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Main Content -->
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 py-8">
      <!-- Product Summary Card -->
      <div v-if="isLoading" class="flex justify-center py-12">
        <UIcon
          name="i-heroicons-arrow-path"
          class="h-12 w-12 text-indigo-500 animate-spin"
        />
      </div>

      <div
        v-else-if="error"
        class="bg-red-50 border-l-4 border-red-400 p-4 rounded-md mb-6"
      >
        <div class="flex items-center">
          <UIcon
            name="i-heroicons-exclamation-circle"
            class="h-6 w-6 text-red-400 mr-3"
          />
          <div>
            <p class="text-sm text-red-700">
              There was an error loading this product. Please try again or
              contact support.
            </p>
            <button
              @click="getProduct"
              class="mt-2 inline-flex items-center px-3 py-1 border border-red-300 text-sm leading-5 font-medium rounded-md text-red-700 bg-white hover:text-red-500 focus:outline-none focus:border-red-300 focus:shadow-outline-red active:bg-red-50 active:text-red-800 transition ease-in-out duration-150"
            >
              <UIcon name="i-heroicons-arrow-path" class="h-4 w-4 mr-1" />
              Retry
            </button>
          </div>
        </div>
      </div>

      <div
        v-else-if="Object.keys(currentProduct).length === 0"
        class="bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded-md mb-6"
      >
        <div class="flex">
          <UIcon
            name="i-heroicons-exclamation-triangle"
            class="h-6 w-6 text-yellow-400 mr-3"
          />
          <div>
            <p class="text-sm text-yellow-700">
              Product not found or you don't have permission to edit it.
            </p>
            <NuxtLink
              to="/shop-manager"
              class="mt-2 inline-flex items-center px-3 py-1 border border-yellow-300 text-sm leading-5 font-medium rounded-md text-yellow-700 bg-white hover:text-yellow-500 focus:outline-none focus:border-yellow-300 focus:shadow-outline-yellow active:bg-yellow-50 active:text-yellow-800 transition ease-in-out duration-150"
            >
              <UIcon name="i-heroicons-arrow-left" class="h-4 w-4 mr-1" />
              Back to Products
            </NuxtLink>
          </div>
        </div>
      </div>

      <!-- Product Info Summary -->
      <div v-else class="mb-6 animate-fade-in">
        <div
          class="bg-white overflow-hidden shadow-sm rounded-lg border border-gray-200"
        >
          <div class="px-6 py-5 flex flex-col md:flex-row gap-6">
            <div class="w-full md:w-1/4">
              <div
                class="bg-gray-100 rounded-lg overflow-hidden h-48 flex items-center justify-center"
              >
                <img
                  v-if="currentProduct.image_details?.length > 0"
                  :src="currentProduct.image_details[0].image"
                  :alt="currentProduct.name"
                  class="object-cover h-full w-full"
                />
                <div v-else class="text-gray-400 flex flex-col items-center">
                  <UIcon name="i-heroicons-photo" class="h-12 w-12" />
                  <span class="text-sm mt-2">No image available</span>
                </div>
              </div>
            </div>

            <div class="w-full md:w-3/4">
              <div class="flex justify-between items-start">
                <div>
                  <h2 class="text-2xl font-bold text-gray-800">
                    {{ currentProduct.name }}
                  </h2>
                  <p class="text-gray-600 mt-1">
                    {{
                      currentProduct.short_description ||
                      "No description available"
                    }}
                  </p>
                </div>
                <div
                  class="bg-green-100 text-green-800 py-1 px-3 rounded-full text-sm font-medium flex items-center"
                >
                  <UIcon
                    :name="
                      currentProduct.is_active
                        ? 'i-heroicons-check-circle'
                        : 'i-heroicons-x-circle'
                    "
                    class="h-4 w-4 mr-1"
                  />
                  {{ currentProduct.is_active ? "Active" : "Inactive" }}
                </div>
              </div>

              <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-4">
                <div class="bg-gray-50 p-3 rounded-lg">
                  <div class="text-sm text-gray-500">Price</div>
                  <div class="font-medium text-lg line-through">
                    ৳{{ currentProduct.regular_price }}
                  </div>
                </div>
                <div class="bg-gray-50 p-3 rounded-lg">
                  <div class="text-sm text-gray-500">Discounted Price</div>
                  <div class="font-medium text-lg">
                    {{
                      currentProduct.sale_price || currentProduct.regular_price
                    }}
                  </div>
                </div>
                <div class="bg-gray-50 p-3 rounded-lg">
                  <div class="text-sm text-gray-500">Stock</div>
                  <div class="font-medium text-lg">
                    {{ currentProduct.quantity }}
                  </div>
                </div>
                <div class="bg-gray-50 p-3 rounded-lg">
                  <div class="text-sm text-gray-500">Category</div>
                  <div class="font-medium text-lg truncate">
                    {{ currentProduct.category_details?.name || "N/A" }}
                  </div>
                </div>
              </div>

              <div class="flex mt-6 space-x-3">
                <NuxtLink
                  :to="`/product-details/${currentProduct.slug}`"
                  class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none transition duration-150"
                >
                  <UIcon name="i-heroicons-eye" class="h-4 w-4 mr-2" />
                  View Product
                </NuxtLink>
                <NuxtLink
                  to="/shop-manager"
                  class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none transition duration-150"
                >
                  <UIcon name="i-heroicons-arrow-left" class="h-4 w-4 mr-2" />
                  Back to Products
                </NuxtLink>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Edit Form Component -->
      <UCard
        v-if="Object.keys(currentProduct).length > 0"
        class="animate-fade-in"
        :ui="{
          body: {
            padding: 'px-2 py-5 sm:p-6',
          },
        }"
      >
        <template #header>
          <div class="flex items-center">
            <UIcon
              name="i-heroicons-adjustments-horizontal"
              class="h-5 w-5 text-indigo-500 mr-2"
            />
            <h3 class="text-lg font-medium text-gray-900">
              Edit Product Details
            </h3>
          </div>
        </template>
        <CommonAddProductTab :product="currentProduct" />
      </UCard>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useApi } from "~/composables/useApi";
import { useRoute, useRouter } from "vue-router";

const { get } = useApi();
const route = useRoute();
const router = useRouter();

const currentProduct = ref({});
const isLoading = ref(true);
const error = ref(null);

async function getProduct() {
  isLoading.value = true;
  error.value = null;

  try {
    const { data } = await get(`/products/${route.params.id}/`);
    currentProduct.value = data;

    // Set the page title
    useHead({
      title: `Edit - ${data.name} | Dashboard`,
      meta: [{ name: "description", content: `Edit product: ${data.name}` }],
    });
  } catch (err) {
    console.error("Error fetching product:", err);
    error.value = err.message || "Failed to load product";

    if (err.response?.status === 404) {
      // Product not found or unauthorized
      toast.add({
        title: "Product Not Found",
        description:
          "The product you are looking for does not exist or you do not have permission to edit it.",
        color: "red",
      });
    }
  } finally {
    isLoading.value = false;
  }
}

// Initialize page
onMounted(() => {
  getProduct();
});
</script>

<style scoped>
.animate-fade-in {
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
