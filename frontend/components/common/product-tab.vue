<template>
  <div>
    <div
      class="grid grid-cols-2 md:grid-cols-4 gap-2 p-2 bg-gray-50 border-b border-gray-200"
    >
      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Total Products</p>
            <p class="text-xl font-semibold text-gray-900">
              {{ products.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-indigo-50 flex items-center justify-center"
          >
            <ShoppingCart class="h-6 w-6 text-indigo-500" />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-indigo-600">
          ৳{{ totalProductsValue }}
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Active Products</p>
            <p class="text-xl font-semibold text-gray-900">
              {{ activeProducts.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-green-50 flex items-center justify-center"
          >
            <CircleCheck class="h-6 w-6 text-green-500" />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-green-600">
          ৳{{ activeProductsValue }}
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Inactive Products</p>
            <p class="text-xl font-semibold text-gray-900">
              {{ inactiveProducts.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-gray-50 flex items-center justify-center"
          >
            <CirclePause class="h-6 w-6 text-gray-500" />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-gray-600">
          ৳{{ inactiveProductsValue }}
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Out of Stock</p>
            <p class="text-xl font-semibold text-gray-900">
              {{ outOfStockProducts.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-red-50 flex items-center justify-center"
          >
            <CircleX class="h-6 w-6 text-red-500" />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-red-600">
          ৳{{ outOfStockProductsValue }}
        </p>
      </div>
    </div>

    <div class="px-6 py-5 border-b border-gray-200 bg-gray-50">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between">
        <div class="flex items-center space-x-2">
          <ShoppingCart class="h-5 w-5 text-indigo-600" />
          <h2 class="text-xl font-semibold text-gray-800">My Products</h2>
        </div>
        <div class="mt-3 md:mt-0 flex items-center space-x-4">
          <div class="relative">
            <select
              v-model="productFilter"
              class="block w-full pl-3 pr-10 py-1.5 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
            >
              <option value="all">All Products</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="out-of-stock">Out of Stock</option>
            </select>
          </div>
          <div class="relative rounded-md shadow-sm">
            <input
              type="text"
              v-model="productSearch"
              placeholder="Search products..."
              class="focus:ring-indigo-500 focus:border-indigo-500 block w-full pr-10 py-2 pl-1.5 sm:text-sm border-gray-300 rounded-md"
            />
            <div
              class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none"
            >
              <Search class="h-5 w-5 text-gray-500" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Products Grid -->
    <div class="p-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="product in products"
        :key="product.id"
        class="group bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden hover:shadow-sm transition-all duration-300 transform hover:-translate-y-1"
      >
        <div class="relative">
          <img
            v-if="product.image_details.length"
            :src="product.image_details[0].image"
            :alt="product.name"
            class="w-full h-48 object-cover transition-transform duration-500 group-hover:scale-105"
          />
          <div class="absolute top-2 right-2">
            <span
              v-if="product.status === 'active'"
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
            >
              <CircleCheck class="h-3 w-3 mr-1" />
              Active
            </span>
            <span
              v-else-if="product.status === 'inactive'"
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
            >
              <CirclePause class="h-3 w-3 mr-1" />
              Inactive
            </span>
            <span
              v-else
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
            >
              <CircleX class="h-3 w-3 mr-1" />
              Out of Stock
            </span>
          </div>
        </div>
        <div class="p-4">
          <h3 class="text-lg font-medium text-gray-900 mb-1 line-clamp-1">
            {{ product.name }}
          </h3>
          <div
            v-html="product.description"
            class="text-sm text-gray-500 mb-2 line-clamp-2"
          ></div>
          <div class="flex justify-between items-center">
            <div class="text-lg font-semibold text-indigo-600">
              ৳{{ product.price }}
            </div>
            <div class="text-sm text-gray-500 flex items-center">
              <Package class="h-4 w-4 mr-1 text-gray-500" />
              {{ product.stock }}
            </div>
          </div>
          <div class="mt-4 grid grid-cols-3 gap-2">
            <button
              @click="editProduct(product)"
              class="btn-product-action bg-indigo-50 text-indigo-600 hover:bg-indigo-600 hover:text-white"
            >
              <Edit2 class="h-4 w-4 mr-1.5" />
              <span>Edit</span>
            </button>
            <button
              @click="toggleProductStatus(product)"
              class="btn-product-action bg-gray-50 text-gray-600 hover:bg-gray-600 hover:text-white"
            >
              <component
                :is="product.status === 'active' ? 'EyeOff' : 'Eye'"
                class="h-4 w-4 mr-1.5"
              />
              <span>{{
                product.status === "active" ? "Deactivate" : "Activate"
              }}</span>
            </button>
            <button
              @click="confirmDeleteProduct(product)"
              class="btn-product-action bg-red-50 text-red-600 hover:bg-red-600 hover:text-white"
            >
              <Trash2 class="h-4 w-4 mr-1.5" />
              <span>Delete</span>
            </button>
          </div>
        </div>
      </div>
      <div
        v-if="paginatedProducts.length === 0"
        class="col-span-full py-10 text-center text-gray-500"
      >
        <div class="flex flex-col items-center justify-center">
          <PackageX class="h-12 w-12 text-gray-400 mb-2" />
          No products found matching your criteria
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  products: {
    type: Array,
    required: true,
  },
});
</script>

<style scoped></style>
