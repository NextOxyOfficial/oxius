<template>
  <div>
    <div class="md:hover:-translate-y-2 transition-all duration-300">
      <!-- Glass-like Card Container with Premium Shadows -->
      <div
        class="bg-slate-100/80 dark:bg-slate-800/90 border border-white/40 dark:border-slate-700/40 rounded-2xl overflow-hidden shadow-custom transition-all duration-500 h-full flex flex-col backdrop-blur-sm hover:shadow-custom-hover"
      >
        <!-- Product Image Section -->
        <div class="relative pt-[100%] overflow-hidden group">
          <!-- Premium-looking Discount Badge -->
          <div
            v-if="
              product.regular_price &&
              calculateDiscount(product.sale_price, product.regular_price) > 0
            "
            class="absolute top-3 left-3 z-20 discount-badge"
          >
            <div class="relative">
              <div
                class="absolute inset-0 bg-gradient-to-r from-red-500 to-rose-600 rounded-full blur-[1px]"
              ></div>
              <div
                class="relative px-3 py-1 bg-gradient-to-r from-red-500 to-rose-600 rounded-full text-white text-xs font-semibold flex items-center"
              >
                <UIcon name="i-heroicons-bolt" class="size-3 mr-1" />
                <span
                  >{{
                    calculateDiscount(
                      product.sale_price,
                      product.regular_price
                    )
                  }}% OFF</span
                >
              </div>
            </div>
          </div>

          <!-- Image with Gradient Overlay -->
          <div
            class="absolute inset-0 bg-gradient-to-br from-black/5 via-transparent to-black/30 dark:from-black/20 dark:to-black/40 z-10"
          ></div>
          <img
            :src="getProductImage(product)"
            :alt="product.name"
            class="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-700 ease-out-expo hover:scale-110"
            loading="lazy"
          />

          <!-- Quick View Button with Premium Effects -->
          <div class="absolute inset-0 z-10 flex items-center justify-center">
            <button
              @click="openProductModal(product)"
              class="quick-view-btn px-4 py-2.5 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md text-sm font-medium rounded-full transform opacity-0 translate-y-8 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-500 shadow-lg flex items-center"
            >
              <UIcon name="i-heroicons-eye" class="mr-2 size-4" />
              <span>Quick View</span>
              <div
                class="absolute inset-0 rounded-full bg-gradient-to-r from-primary-500/10 to-primary-600/20 animate-pulse-subtle"
              ></div>
            </button>
          </div>
        </div>

        <!-- Product Details with Improved Layout -->
        <div class="my-4 px-2 flex-grow flex flex-col">
          <!-- Store Link with Premium Style -->
          <NuxtLink
            :to="`/eshop/${
              product?.owner_details?.store_username ||
              product?.owner?.store_username
            }`"
            class="text-primary-500 dark:text-primary-400 text-sm mb-1.5 inline-flex items-center gap-1 hover:text-primary-600 transition-colors"
          >
            <div
              class="flex items-center justify-center size-4 bg-primary-50 dark:bg-primary-900/20 rounded-full"
            >
              <UIcon
                name="i-material-symbols-storefront-outline-rounded"
                class="size-3"
              />
            </div>
            <span class="line-clamp-1 font-medium">
              {{
                product?.owner_details?.store_name ||
                product?.owner?.store_name ||
                "Store"
              }}
            </span>
          </NuxtLink>
          <!-- Product Title with Premium Hover Effect -->
          <NuxtLink :to="`/product-details/${product?.slug}`" class="">
            <h3
              class="font-medium text-slate-800 dark:text-white mb-2 line-clamp-1 flex-grow text-base first-letter:uppercase text-primary-600 transition-colors"
            >
              {{ product.name }}
            </h3>
          </NuxtLink>

          <!-- Price Section with Premium Styling -->
          <div
            class="flex items-center justify-between mt-auto pt-3 border-t border-slate-100/70 dark:border-slate-700/30 mr-0.5 sm:mr-3"
          >
            <!-- Price Section with Improved Logic - regular_price is used if sale_price is missing/0/null -->
            <div class="flex flex-col">
              <span
                class="font-semibold text-slate-900 dark:text-white text-md flex items-center"
              >
                <span class="text-xs mr-1 text-slate-500">৳</span
                >{{
                  product.sale_price && parseFloat(product.sale_price) > 0
                    ? product.sale_price
                    : product.regular_price
                }}
              </span>
              <span
                v-if="
                  product.sale_price &&
                  parseFloat(product.sale_price) > 0 &&
                  product.regular_price &&
                  parseFloat(product.sale_price) <
                    parseFloat(product.regular_price)
                "
                class="text-xs text-slate-400 line-through -mt-0.5 flex items-center"
              >
                <span class="text-[10px] mr-0.5">৳</span
                >{{ product.regular_price }}
              </span>
            </div>

            <!-- Premium Buy Button with Custom Loading Animation -->
            <button
              :disabled="loadingStates[product.id]"
              class="premium-buy-button flex items-center justify-center gap-1 px-1.5 py-1 font-medium text-white rounded-full relative overflow-hidden transition-all duration-300 disabled:pointer-events-none disabled:opacity-70 h-[38px] min-w-[50px]"
              @click="addToCart(product, quantity)"
            >
              <!-- Gradient backgrounds -->
              <span
                class="absolute inset-0 bg-gradient-to-r from-primary-400 to-primary-500"
              ></span>
              <span
                class="absolute inset-0 bg-gradient-to-r from-primary-500 to-primary-600 opacity-0 hover:opacity-100 transition-opacity duration-300"
              ></span>

              <!-- Glow effect -->
              <span
                class="absolute inset-0 rounded-full opacity-0 hover:opacity-100 transition-opacity duration-500"
              >
                <span
                  class="absolute inset-0 rounded-full bg-primary-400 blur-xl opacity-30"
                ></span>
              </span>

              <!-- Content with custom spinner -->
              <span class="relative z-10 flex items-center justify-center">
                <template v-if="!loadingStates[product.id]">
                  <UIcon
                    name="i-heroicons-shopping-cart"
                    class="size-4 mr-1 cart-icon"
                  />
                  <span class="text-sm whitespace-nowrap">Buy</span>
                </template>
                <template v-else>
                  <div class="premium-spinner">
                    <div class="spinner-dot"></div>
                    <div class="spinner-dot"></div>
                    <div class="spinner-dot"></div>
                  </div>
                </template>
              </span>

              <!-- Shine effect -->
              <span
                class="absolute top-0 left-0 w-full h-full shine-effect"
              ></span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Premium Modal Design -->
    <Teleport to="body">
      <div
        v-if="isModalOpen"
        class="fixed inset-0 top-14 z-50 overflow-y-auto"
        :class="{ 'animate-fade-in': isModalOpen }"
        @click="closeProductModal()"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
          aria-hidden="true"
          @click="isModalOpen = false"
        ></div>
        <div
          class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
        >
          <div
            class="relative max-w-4xl w-full mx-auto my-8 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-2xl shadow-2xl border border-white/20 dark:border-slate-700/40 overflow-hidden"
            :class="{ 'animate-modal-slide-up': isModalOpen }"
            @click.stop
          >
            <div
              class="w-full md:h-[80vh] overflow-hidden overflow-y-auto custom-scrollbar"
            >
              <CommonProductDetailsCard
                :current-product="selectedProduct"
                :modal="true"
                :seeDetails="true"
                @close-modal="closeProductModal"
              />
            </div>

            <!-- Decorative blobs -->
            <div
              class="absolute top-0 right-0 w-64 h-64 bg-primary-400/10 rounded-full filter blur-3xl -z-10 transform translate-x-1/3 -translate-y-1/3"
            ></div>
            <div
              class="absolute bottom-0 left-0 w-64 h-64 bg-violet-400/10 rounded-full filter blur-3xl -z-10 transform -translate-x-1/3 translate-y-1/3"
            ></div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
const { product } = defineProps({ product: { type: Object, required: true } });
const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);

const loadingStates = ref({});
const cart = useStoreCart();

function getProductImage(item) {
  if (!item) return "/placeholder-image.jpg";

  if (item.image_details) {
    if (Array.isArray(item.image_details) && item.image_details.length > 0) {
      return item.image_details[0].image || "/placeholder-image.jpg";
    }
    if (typeof item.image_details === "string") {
      return item.image_details;
    }
  } else if (item.image) {
    return item.image;
  }

  return "/placeholder-image.jpg";
}

// Calculate discount percentage
function calculateDiscount(salePrice, originalPrice) {
  if (
    !salePrice ||
    !originalPrice ||
    parseFloat(originalPrice) <= parseFloat(salePrice)
  )
    return 0;
  const discount =
    ((parseFloat(originalPrice) - parseFloat(salePrice)) /
      parseFloat(originalPrice)) *
    100;
  return Math.round(discount);
}

// Cart functionality with improved loading handling
function addToCart(item, qty = 1) {
  // Set loading state for this specific product
  loadingStates.value[item.id] = true;

  try {
    // Simulate network delay (remove in production)
    setTimeout(() => {
      cart.addProduct(item, qty);
      navigateTo("/checkout/");

      // Clear loading state if navigation fails
      loadingStates.value[item.id] = false;
    }, 800); // Simulate network latency
  } catch (error) {
    console.error("Error adding to cart:", error);
    const toast = useToast();
    toast.add({
      title: "Network Error",
      description: "Please check your internet connection and try again.",
      color: "red",
    });

    // Clear loading state on error
    loadingStates.value[item.id] = false;
  }
}

// Product modal functions
function openProductModal(product) {
  document.body.style.overflow = "hidden";
  selectedProduct.value = product;
  quantity.value = 1;
  isModalOpen.value = true;
}

function closeProductModal() {
  isModalOpen.value = false;
}
</script>

<style scoped>
/* Premium shadows */
.shadow-custom {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03), 0 1px 4px rgba(0, 0, 0, 0.02),
    0 8px 24px rgba(0, 0, 0, 0.04);
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.shadow-custom-hover {
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.06), 0 2px 8px rgba(0, 0, 0, 0.04),
    0 16px 40px rgba(0, 0, 0, 0.08);
}

/* Premium card hover effect */

/* Premium button effects */
.premium-buy-button {
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.premium-buy-button:hover {
  transform: translateY(-2px);
}

.premium-buy-button:active {
  transform: translateY(0);
}

/* Cart icon animation */
.cart-icon {
  transition: transform 0.3s ease;
}

.premium-buy-button:hover .cart-icon {
  animation: cartBounce 0.75s ease;
}

@keyframes cartBounce {
  0%,
  100% {
    transform: translateY(0);
  }
  40% {
    transform: translateY(-4px);
  }
  60% {
    transform: translateY(2px);
  }
  80% {
    transform: translateY(-1px);
  }
}

/* Premium spinner animation */
.premium-spinner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.spinner-dot {
  width: 6px;
  height: 6px;
  background-color: white;
  border-radius: 50%;
}

.spinner-dot:nth-child(1) {
  animation: spinner-dot-fade 1.2s infinite ease-in-out;
  animation-delay: -0.24s;
}

.spinner-dot:nth-child(2) {
  animation: spinner-dot-fade 1.2s infinite ease-in-out;
  animation-delay: -0.12s;
}

.spinner-dot:nth-child(3) {
  animation: spinner-dot-fade 1.2s infinite ease-in-out;
}

@keyframes spinner-dot-fade {
  0%,
  80%,
  100% {
    transform: scale(0.6);
    opacity: 0.3;
  }
  40% {
    transform: scale(1);
    opacity: 1;
  }
}

/* Shine effect */
.shine-effect {
  position: absolute;
  top: -300%;
  left: -300%;
  width: 500%;
  height: 500%;
  background: linear-gradient(
    to right,
    rgba(255, 255, 255, 0) 0%,
    rgba(255, 255, 255, 0.3) 50%,
    rgba(255, 255, 255, 0) 100%
  );
  transform: rotate(30deg);
  opacity: 0;
  transition: opacity 0.3s;
}

.premium-buy-button:hover .shine-effect {
  animation: shine 1.5s ease-in-out;
}

@keyframes shine {
  0% {
    opacity: 0;
    transform: translate(-30%, -30%) rotate(30deg);
  }
  20% {
    opacity: 0.5;
  }
  100% {
    opacity: 0;
    transform: translate(-15%, -15%) rotate(30deg);
  }
}

/* Subtle pulse animation */
@keyframes pulse-subtle {
  0%,
  100% {
    opacity: 0.7;
  }
  50% {
    opacity: 0.3;
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 3s infinite;
}

/* Smoother easing for image hover effect */
.ease-out-expo {
  transition-timing-function: cubic-bezier(0.16, 1, 0.3, 1);
}

/* Custom scrollbar styling */
.custom-scrollbar {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 5px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.4);
  border-radius: 20px;
}

.dark .custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(75, 85, 99, 0.5);
}

/* Quick view button hover animation */
.quick-view-btn {
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.1), 0 2px 6px rgba(0, 0, 0, 0.08);
}

.quick-view-btn:hover {
  box-shadow: 0 6px 18px rgba(0, 0, 0, 0.15), 0 3px 8px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

/* Modal animations */
@keyframes fade-in {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes modal-slide-up {
  from {
    opacity: 0;
    transform: translateY(30px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.animate-fade-in {
  animation: fade-in 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

.animate-modal-slide-up {
  animation: modal-slide-up 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

/* Custom colors */
:root {
  --primary-400: #38bdf8;
  --primary-500: #0ea5e9;
  --primary-600: #0284c7;
  --primary-700: #0369a1;
}

/* Discount badge animation */
.discount-badge {
  animation: float 4s ease-in-out infinite;
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-3px);
  }
}
</style>
