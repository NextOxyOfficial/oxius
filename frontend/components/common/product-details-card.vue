<template>
  <UCard v-if="currentProduct" class="p-0">
    <template #header>
      <div
        class="relative bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 px-5 py-4"
      >
        <div class="flex justify-between items-center">
          <h3 class="text-xl font-medium text-slate-800 dark:text-white">
            {{ currentProduct.name }}
          </h3>
          <div v-if="modal">
            <UButton
              icon="i-heroicons-x-mark"
              size="sm"
              color="red"
              square
              variant="ghost"
              @click="closeModal"
            />
          </div>
        </div>
      </div>
    </template>

    <div class="p-5">
      <div class="grid grid-cols-1 gap-6">
        <div>
          <div class="flex justify-center">
            <div
              class="relative w-[400px] h-[400px] bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden"
            >
              <img
                v-if="currentProduct.image_details"
                :src="currentProduct.image_details[0].image"
                :alt="currentProduct.name"
                class="absolute inset-0 w-full h-full object-contain"
              />

              <div
                v-if="currentProduct.discount"
                class="absolute top-2 left-2 badge-discount"
              >
                -{{ currentProduct.discount }}%
              </div>
            </div>
          </div>
          <div
            class="grid grid-cols-4 gap-2 mt-2"
            v-if="currentProduct.image_details"
          >
            <div
              v-for="img in currentProduct.image_details"
              :key="img.id"
              class="aspect-square h-auto sm:h-28 w-auto sm:w-28 relative bg-slate-100 dark:bg-slate-800 rounded-md overflow-hidden cursor-pointer hover:opacity-80 border-2"
              :class="i === 1 ? 'border-primary' : 'border-transparent'"
            >
              <img
                :src="img.image"
                :alt="img.name"
                class="absolute inset-0 w-full h-full object-cover"
              />
            </div>
          </div>
        </div>

        <!-- Right: Product Info -->
        <div>
          <div class="mb-4">
            <div class="text-sm text-slate-500 dark:text-slate-400 mb-1">
              {{ currentProduct?.category_details.name }}
            </div>

            <!-- Rating -->
            <div class="flex items-center gap-2 mb-3">
              <div class="rating-stars">
                <div
                  v-if="!currentProduct.reviews?.length"
                  class="stars-background"
                >
                  <UIcon
                    v-for="n in 5"
                    :key="`bg-${n}`"
                    name="i-heroicons-star"
                    class="w-4 h-4 text-slate-200 dark:text-slate-700"
                  />
                </div>
                <div
                  class="stars-foreground"
                  :style="{
                    width: `${(currentProduct.rating / 5) * 100}%`,
                  }"
                  v-else
                >
                  <UIcon
                    v-for="n in 5"
                    :key="`fg-${n}`"
                    name="i-heroicons-star-solid"
                    class="w-4 h-4 text-yellow-400"
                  />
                </div>
              </div>
              <span class="text-sm text-slate-500 dark:text-slate-400">
                {{ currentProduct.rating }} ({{
                  currentProduct.reviews?.length || 0
                }}
                reviews)
              </span>
            </div>

            <!-- Price -->
            <div class="flex items-center gap-3 mb-4">
              <span
                class="text-2xl font-semibold text-slate-800 dark:text-white"
              >
                ৳{{ currentProduct.sale_price }}
              </span>
              <span
                v-if="currentProduct.regular_price"
                class="text-sm text-slate-400 line-through"
              >
                ৳{{ currentProduct.regular_price }}
              </span>
              <span v-if="currentProduct.regular_price" class="savings-badge">
                Save ৳{{
                  calculateSavings(
                    currentProduct.sale_price,
                    currentProduct.regular_price
                  )
                }}
              </span>
            </div>

            <!-- Description -->
            <div
              class="text-sm text-slate-600 dark:text-slate-300 mb-4 description-text"
            >
              {{ currentProduct.short_description }}
            </div>

            <!-- Add to Cart Area -->
            <div class="flex items-center gap-3 mb-6">
              <button
                class="flex-1 relative overflow-hidden group bg-gradient-to-r from-primary to-primary-600 hover:from-primary-600 hover:to-primary rounded-lg py-3 px-4 text-white font-medium shadow-md hover:shadow-lg transition-all duration-300 max-w-fit sm:px-20 mx-auto"
                @click="addToCart(currentProduct, 1)"
              >
                <!-- Hover overlay effect -->
                <div
                  class="absolute inset-0 w-full h-full bg-white/10 transform origin-left scale-x-0 group-hover:scale-x-100 transition-transform duration-500"
                ></div>

                <!-- Content container -->
                <div class="relative flex items-center justify-center gap-2">
                  <!-- Shopping cart icon -->
                  <UIcon
                    name="i-heroicons-shopping-cart"
                    class="w-5 h-5 transition-transform group-hover:scale-110 duration-300"
                  />

                  <!-- Button text with animated dot -->
                  <span class="text-base">
                    Buy Now
                    <span
                      class="inline-block w-1.5 h-1.5 bg-white rounded-full ml-0.5 animate-pulse"
                    ></span>
                  </span>
                </div>
              </button>
            </div>

            <!-- Features List - Improved Responsive Layout -->
            <div class="bg-slate-50 dark:bg-slate-800/50 p-3 rounded-lg">
              <div class="text-sm font-medium mb-2">Shipping Information:</div>
              <ul class="space-y-1.5 text-slate-600 dark:text-slate-300">
                <li class="flex items-start gap-1.5 text-xs sm:text-sm">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
                  />
                  <span>Inside Dhaka ৳100</span>
                </li>
                <li class="flex items-start gap-1.5 text-xs sm:text-sm">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
                  />
                  <span>Outside Dhaka ৳150</span>
                </li>

                <li class="flex items-start gap-1.5 text-xs sm:text-sm">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
                  />
                  <span>Delivery within 3-5 business days</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <!-- Tabs - Improved Responsiveness -->
        <div
          class="text-sm text-slate-600 dark:text-slate-300 mb-4 description-text"
          v-html="currentProduct.description"
        ></div>

        <div class="flex justify-center mt-3">
          <UButton
            :to="`/product-details/${currentProduct.id}`"
            label="See More Details"
            variant="outline"
            size="lg"
            icon="i-material-symbols-light-arrow-right-alt-rounded"
            :ui="{
              size: {
                lg: 'text-base',
              },
            }"
            trailing
          />
        </div>
      </div>
    </div>
  </UCard>
  <UCard v-else>
    <p>No Products Found!</p>
  </UCard>
</template>

<script setup>
const { currentProduct, modal } = defineProps({
  currentProduct: { type: Object, required: true },
  modal: { type: Boolean, required: false },
});

const emit = defineEmits(["close-modal"]);

function closeModal() {
  emit("close-modal");
}

const cart = useStoreCart();
function addToCart(product, quantity) {
  cart.addProduct(product, quantity);
  navigateTo("/checkout/");
}
// Update this function to use sale_price and regular_price parameter names
function calculateSavings(sale_price, regular_price) {
  // Safety check in case prices are undefined
  if (!sale_price || !regular_price) return 0;

  // Handle both string and number inputs
  const current =
    typeof sale_price === "string"
      ? Number(sale_price.replace(/,/g, ""))
      : Number(sale_price);

  const regular =
    typeof regular_price === "string"
      ? Number(regular_price.replace(/,/g, ""))
      : Number(regular_price);

  // Calculate and format savings
  return (regular - current).toLocaleString();
}

// Add these to your existing script section
const activeTab = ref("details");
const reviewForm = ref({
  name: "",
  rating: 0,
  comment: "",
});

// Computed property for tabs configuration - prevents recursive updates
const tabItems = computed(() => {
  if (!currentProduct.value) return [];

  return [
    {
      label: "Details",
      slot: "details",
      icon: "i-heroicons-document-text",
    },
    {
      label: "Reviews",
      slot: "reviews",
      icon: "i-heroicons-chat-bubble-left-right",
      badge: currentProduct.value.reviews?.length || 0,
    },
  ];
});

// Computed for review validity
const isReviewValid = computed(() => {
  return (
    reviewForm.value.name &&
    reviewForm.value.rating > 0 &&
    reviewForm.value.comment.trim().length > 0
  );
});

// Rating distribution functions
function getRatingPercentage(rating) {
  if (!currentProduct.value || !currentProduct.value.reviews) return "0%";

  const total = currentProduct.value.reviews.length || 1;
  const count = currentProduct.value.reviews.filter(
    (r) => Math.round(r.rating) === rating
  ).length;

  return `${(count / total) * 100}%`;
}

function getRatingCount(rating) {
  if (!currentProduct.value || !currentProduct.value.reviews) return 0;

  return currentProduct.value.reviews.filter(
    (r) => Math.round(r.rating) === rating
  ).length;
}

// Improved submit review function
function submitReview() {
  if (!isReviewValid.value) return;

  // Add review to product
  if (!currentProduct.value.reviews) {
    currentProduct.value.reviews = [];
  }

  currentProduct.value.reviews.unshift({
    name: reviewForm.value.name,
    rating: reviewForm.value.rating,
    date: "Just now",
    comment: reviewForm.value.comment.trim(),
    avatar: "",
  });

  // Reset form
  reviewForm.value = {
    name: "",
    rating: 0,
    comment: "",
  };
}
</script>
