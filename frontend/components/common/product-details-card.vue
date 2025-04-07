<template>
  <UCard
    v-if="currentProduct"
    class="p-0 overflow-hidden border-none shadow-lg"
  >
    <!-- Header section remains the same -->
    <template #header>
      <div
        class="relative bg-gradient-to-r from-primary-50 to-white dark:from-slate-900 dark:to-slate-800 px-5 py-4"
      >
        <div class="flex justify-between items-center">
          <h3
            class="text-xl md:text-2xl font-bold text-primary-700 dark:text-primary-300"
          >
            {{ currentProduct.name }}
          </h3>
          <div v-if="modal" class="flex items-center gap-2">
            <UBadge
              v-if="currentProduct.quantity > 0"
              color="green"
              class="mr-2"
            >
              In Stock
            </UBadge>
            <UBadge v-else color="red" class="mr-2"> Out of Stock </UBadge>
            <UButton
              icon="i-heroicons-x-mark"
              size="sm"
              color="gray"
              square
              variant="ghost"
              class="hover:bg-white/20"
              @click="closeModal"
            />
          </div>
        </div>
      </div>
    </template>

    <div class="p-4 md:p-6">
      <!-- Two-column layout remains the same -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-8">
        <!-- Left column with images remains the same -->
        <div>
          <!-- Main Image with Glass Effect Border -->
          <div class="flex justify-center mb-3">
            <div
              class="relative w-full aspect-square bg-slate-50 dark:bg-slate-800/40 rounded-xl overflow-hidden backdrop-blur-sm shadow-md border border-white/20 dark:border-slate-700/50"
            >
              <img
                v-if="
                  currentProduct.image_details &&
                  currentProduct.image_details.length
                "
                :src="
                  currentProduct.image_details[selectedImageIndex || 0].image
                "
                :alt="currentProduct.name"
                class="absolute inset-0 w-full h-full object-contain p-2"
                @error="(e) => (e.target.src = '/placeholder.svg')"
              />
              <div
                v-else
                class="absolute inset-0 flex items-center justify-center text-slate-400"
              >
                <UIcon name="i-heroicons-photo" class="w-20 h-20" />
              </div>

              <!-- Discount Badge with Improved Design -->
              <div
                v-if="currentProduct.discount"
                class="absolute top-2 left-2 bg-red-500 text-white text-sm font-bold px-3 py-1 rounded-full shadow-md transform -rotate-6 animate-pulse"
              >
                -{{ currentProduct.discount }}% OFF!
              </div>

              <!-- Free Delivery Badge -->
              <div
                v-if="currentProduct.is_free_delivery"
                class="absolute top-2 right-2 bg-green-500 text-white text-sm font-bold px-3 py-1 rounded-full shadow-md"
              >
                Free Shipping
              </div>
            </div>
          </div>

          <!-- Thumbnail Gallery remains the same -->
          <div
            class="grid grid-cols-5 gap-2 mt-4"
            v-if="
              currentProduct.image_details &&
              currentProduct.image_details.length > 1
            "
          >
            <div
              v-for="(img, i) in currentProduct.image_details"
              :key="img.id"
              class="relative aspect-square bg-slate-100 dark:bg-slate-800 rounded-md overflow-hidden cursor-pointer hover:opacity-90 transition-all duration-300 shadow-sm"
              :class="
                i === selectedImageIndex
                  ? 'ring-2 ring-primary-500 ring-offset-1'
                  : 'opacity-70 hover:opacity-100'
              "
              @click="selectedImageIndex = i"
            >
              <img
                :src="img.image"
                :alt="currentProduct.name"
                class="absolute inset-0 w-full h-full object-cover"
                @error="(e) => (e.target.src = '/placeholder.svg?size=100')"
              />
            </div>
          </div>
        </div>

        <!-- Right column with product info -->
        <div>
          <!-- Category Name -->
          <div class="flex items-center gap-2 mb-2">
            <UBadge
              color="gray"
              variant="subtle"
              class="uppercase text-xs tracking-wider"
            >
              {{ currentProduct?.category_details?.name || "Uncategorized" }}
            </UBadge>
            <div v-if="currentProduct.weight" class="text-xs text-slate-500">
              Weight: {{ currentProduct.weight }}g
            </div>
          </div>

          <!-- Ratings section remains the same -->
          <div class="flex items-center gap-2 mb-4">
            <div class="rating-stars relative inline-block">
              <!-- Background stars -->
              <div class="flex">
                <UIcon
                  v-for="n in 5"
                  :key="`bg-${n}`"
                  name="i-heroicons-star"
                  class="w-5 h-5 text-slate-200 dark:text-slate-700"
                />
              </div>

              <!-- Foreground stars with animation -->
              <div
                class="absolute top-0 left-0 flex overflow-hidden"
                :style="{
                  width: `${(currentProduct.rating / 5) * 100}%`,
                }"
              >
                <UIcon
                  v-for="n in 5"
                  :key="`fg-${n}`"
                  name="i-heroicons-star-solid"
                  class="w-5 h-5 text-yellow-400"
                />
              </div>
            </div>

            <span
              class="text-sm font-medium text-slate-700 dark:text-slate-300"
            >
              {{ currentProduct.rating }} ({{
                currentProduct.reviews?.length || 0
              }}
              reviews)
            </span>
          </div>

          <!-- Price section remains the same -->
          <div class="bg-slate-50 dark:bg-slate-800/30 p-4 rounded-xl mb-4">
            <div class="flex items-end gap-3">
              <span
                class="text-3xl font-bold text-primary-600 dark:text-primary-400"
              >
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </span>
              <span
                v-if="
                  currentProduct.sale_price &&
                  currentProduct.sale_price !== currentProduct.regular_price
                "
                class="text-base text-slate-400 line-through"
              >
                ৳{{ currentProduct.regular_price }}
              </span>

              <!-- Savings Badge with Animation -->
              <span
                v-if="
                  currentProduct.sale_price &&
                  currentProduct.regular_price &&
                  currentProduct.sale_price !== currentProduct.regular_price
                "
                class="savings-badge bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-xs font-medium px-2 py-1 rounded-md ml-auto animate-pulse"
              >
                Save ৳{{
                  calculateSavings(
                    currentProduct.sale_price,
                    currentProduct.regular_price
                  )
                }}
              </span>
            </div>

            <!-- Stock Status -->
            <div class="mt-2 text-sm">
              <span
                :class="
                  currentProduct.quantity > 10
                    ? 'text-green-600 dark:text-green-400'
                    : currentProduct.quantity > 0
                    ? 'text-amber-600 dark:text-amber-400'
                    : 'text-red-600 dark:text-red-400'
                "
              >
                <span v-if="currentProduct.quantity > 10">In Stock</span>
                <span v-else-if="currentProduct.quantity > 0"
                  >Only {{ currentProduct.quantity }} left!</span
                >
                <span v-else>Out of Stock</span>
              </span>
            </div>
          </div>

          <!-- Short Description - Updated to use short_description -->
          <div class="mb-6">
            <h4 class="font-medium text-slate-800 dark:text-white mb-2">
              Summary
            </h4>
            <div
              class="text-sm text-slate-600 dark:text-slate-300 leading-relaxed bg-slate-50 dark:bg-slate-800/20 p-3 rounded-lg border border-slate-100 dark:border-slate-700/40"
            >
              {{ currentProduct.short_description || "No summary available." }}
            </div>
          </div>

          <!-- Add to Cart Area remains the same -->
          <div class="flex items-center gap-4 mb-6">
            <!-- Quantity Selector -->
            <div
              class="flex items-center border border-slate-200 dark:border-slate-700 rounded-lg"
            >
              <button
                type="button"
                class="w-10 h-10 flex items-center justify-center text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                @click="quantity > 1 ? quantity-- : null"
              >
                <UIcon name="i-heroicons-minus" class="w-4 h-4" />
              </button>

              <span class="w-10 text-center font-medium">{{ quantity }}</span>

              <button
                type="button"
                class="w-10 h-10 flex items-center justify-center text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                @click="quantity++"
              >
                <UIcon name="i-heroicons-plus" class="w-4 h-4" />
              </button>
            </div>

            <!-- Buy Now Button with Enhanced Design -->
            <button
              type="button"
              class="flex-1 relative overflow-hidden group bg-gradient-to-r from-primary-600 to-primary-500 hover:from-primary-500 hover:to-primary-400 rounded-lg py-3 px-6 text-white font-medium shadow-md hover:shadow-lg transition-all duration-300"
              @click="addToCart(currentProduct, quantity)"
              :disabled="currentProduct.quantity <= 0"
            >
              <!-- Shine animation effect -->
              <div
                class="absolute inset-0 w-40 h-full bg-white/20 skew-x-30 transform -translate-x-[150%] group-hover:translate-x-[200%] transition-transform duration-700"
              ></div>

              <!-- Content container -->
              <div class="relative flex items-center justify-center gap-2">
                <!-- Shopping cart icon -->
                <UIcon
                  name="i-heroicons-shopping-cart"
                  class="w-5 h-5 transition-transform group-hover:scale-110 duration-300"
                />

                <!-- Button text with animated dot -->
                <span class="text-base font-bold">
                  Buy Now
                  <span
                    class="inline-block w-1.5 h-1.5 bg-white rounded-full ml-0.5 animate-pulse"
                  ></span>
                </span>
              </div>
            </button>
          </div>

          <!-- Shipping Information remains the same -->
          <div class="bg-slate-50 dark:bg-slate-800/40 p-4 rounded-xl">
            <div class="text-sm font-medium mb-3 flex items-center">
              <UIcon
                name="i-heroicons-truck"
                class="w-5 h-5 mr-2 text-primary-600 dark:text-primary-400"
              />
              <span>Shipping Information</span>
            </div>

            <ul class="space-y-2.5 text-slate-600 dark:text-slate-300">
              <li class="flex items-start gap-2 text-sm">
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5"
                />
                <span
                  >Inside Dhaka:
                  <span class="font-medium"
                    >৳{{
                      currentProduct.delivery_fee_inside_dhaka || 100
                    }}</span
                  ></span
                >
              </li>

              <li class="flex items-start gap-2 text-sm">
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5"
                />
                <span
                  >Outside Dhaka:
                  <span class="font-medium"
                    >৳{{
                      currentProduct.delivery_fee_outside_dhaka || 150
                    }}</span
                  ></span
                >
              </li>

              <li class="flex items-start gap-2 text-sm">
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5"
                />
                <span>Delivery within 3-5 business days</span>
              </li>

              <li
                v-if="currentProduct.is_free_delivery"
                class="flex items-start gap-2 text-sm"
              >
                <UIcon
                  name="i-heroicons-gift"
                  class="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5"
                />
                <span class="font-semibold text-red-600 dark:text-red-400"
                  >Free Delivery on this product!</span
                >
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Product Full Description - Replaced tabs with direct content -->
      <div class="mt-8 border-t border-slate-200 dark:border-slate-700 pt-6">
        <!-- Full Description Section -->
        <div class="mb-8">
          <h3
            class="text-lg font-semibold mb-4 text-slate-800 dark:text-white flex items-center"
          >
            <UIcon
              name="i-heroicons-document-text"
              class="w-5 h-5 mr-2 text-primary-600 dark:text-primary-400"
            />
            Detailed Description
          </h3>

          <div
            class="prose prose-slate max-w-none dark:prose-invert prose-img:rounded-xl prose-headings:font-semibold prose-a:text-primary-600 dark:prose-a:text-primary-400"
            v-html="
              currentProduct.description || 'No detailed description available.'
            "
          ></div>
        </div>
      </div>

      <div class="flex justify-center mt-6">
        <UButton
          :to="`/product-details/${currentProduct.id}`"
          color="primary"
          variant="outline"
          size="lg"
          icon="i-material-symbols-light-arrow-right-alt-rounded"
          :ui="{
            size: {
              lg: 'text-base',
            },
          }"
          trailing
        >
          See Full Details
        </UButton>
      </div>
    </div>
  </UCard>
  <UCard v-else class="flex items-center justify-center p-8 h-64">
    <div class="text-center">
      <UIcon
        name="i-heroicons-face-frown"
        class="w-12 h-12 mx-auto text-slate-300 dark:text-slate-700 mb-3"
      />
      <p class="text-slate-500 dark:text-slate-400">No Product Found!</p>
      <UButton to="/eshop" class="mt-4" size="sm" color="primary">
        Browse Products
      </UButton>
    </div>
  </UCard>
</template>

<script setup>
const { currentProduct, modal } = defineProps({
  currentProduct: { type: Object, required: true },
  modal: { type: Boolean, required: false },
});

const emit = defineEmits(["close-modal"]);
const selectedImageIndex = ref(0);
const quantity = ref(1);

function closeModal() {
  emit("close-modal");
}

const cart = useStoreCart();
function addToCart(product, qty) {
  cart.addProduct(product, qty);
  navigateTo("/checkout/");
}

function calculateSavings(sale_price, regular_price) {
  if (!sale_price || !regular_price) return 0;

  const current =
    typeof sale_price === "string"
      ? Number(sale_price.replace(/,/g, ""))
      : Number(sale_price);

  const regular =
    typeof regular_price === "string"
      ? Number(regular_price.replace(/,/g, ""))
      : Number(regular_price);

  return (regular - current).toLocaleString();
}

// Reset selected image when product changes
watch(
  () => currentProduct?.id,
  () => {
    selectedImageIndex.value = 0;
    quantity.value = 1;
  }
);
</script>

<style scoped>
/* Shine animation for button */
@keyframes shine {
  from {
    transform: translateX(-100%);
  }
  to {
    transform: translateX(200%);
  }
}

/* Rating stars component styling */
.rating-stars {
  position: relative;
  display: inline-flex;
}

/* Animation for the discount badge */
@keyframes pulse-scale {
  0%,
  100% {
    transform: scale(1) rotate(-6deg);
  }
  50% {
    transform: scale(1.05) rotate(-4deg);
  }
}

.prose img {
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}
</style>
