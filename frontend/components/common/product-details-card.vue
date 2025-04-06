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
          <div
            class="relative pt-[100%] bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden"
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

          <div
            class="grid grid-cols-4 gap-2 mt-2"
            v-if="currentProduct.image_details"
          >
            <div
              v-for="img in currentProduct.image_details"
              :key="img.id"
              class="aspect-square relative bg-slate-100 dark:bg-slate-800 rounded-md overflow-hidden cursor-pointer hover:opacity-80 border-2"
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
              {{ currentProduct.category }}
            </div>
            <h2 class="text-xl font-medium text-slate-800 dark:text-white mb-2">
              {{ currentProduct.name }}
            </h2>

            <!-- Rating -->
            <div class="flex items-center gap-2 mb-3">
              <div class="rating-stars">
                <div class="stars-background">
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
              v-html="currentProduct.description"
            ></div>

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
        <div class="">
          <UTabs v-model="activeTab" :items="tabItems">
            <!-- Reviews Tab -->
            <template #reviews>
              <div>
                <!-- Reviews Summary -->
                <div
                  class="mb-4 p-3 bg-slate-50/70 dark:bg-slate-800/70 rounded-lg"
                >
                  <div class="flex flex-col sm:flex-row gap-4">
                    <div
                      class="flex flex-col items-center sm:border-r sm:border-slate-200 sm:dark:border-slate-700 sm:pr-6"
                    >
                      <div
                        class="text-2xl font-bold text-slate-800 dark:text-white"
                      >
                        {{ currentProduct?.rating }}
                      </div>
                      <div class="flex text-yellow-400 my-1">
                        <UIcon
                          v-for="i in 5"
                          :key="i"
                          name="i-heroicons-star-solid"
                          class="w-4 h-4"
                        />
                      </div>
                      <div class="text-xs text-slate-500">
                        {{ currentProduct?.reviews?.length || 0 }} reviews
                      </div>
                    </div>

                    <div class="flex-1 space-y-1.5">
                      <div v-for="n in 5" :key="n" class="flex items-center">
                        <div class="text-xs w-5 text-right mr-2">
                          {{ 6 - n }}
                        </div>
                        <UIcon
                          name="i-heroicons-star"
                          class="w-3.5 h-3.5 text-yellow-400 mr-1.5"
                        />
                        <div
                          class="flex-1 h-2 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden"
                        >
                          <div
                            class="h-full bg-yellow-400"
                            :style="{ width: getRatingPercentage(6 - n) }"
                          ></div>
                        </div>
                        <div class="text-xs w-5 text-right ml-2">
                          {{ getRatingCount(6 - n) }}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Reviews List -->
                <div class="space-y-3 max-h-60 overflow-y-auto pr-2">
                  <div
                    v-for="(review, index) in currentProduct?.reviews || []"
                    :key="index"
                    class="p-3 bg-white dark:bg-slate-800 rounded-lg shadow-sm"
                  >
                    <div class="flex justify-between mb-2">
                      <div class="flex items-center gap-2">
                        <div
                          class="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center"
                        >
                          <span class="font-medium text-sm">{{
                            review.name?.charAt(0) || "?"
                          }}</span>
                        </div>
                        <div>
                          <div
                            class="font-medium text-slate-800 dark:text-white"
                          >
                            {{ review.name }}
                          </div>
                          <div class="text-xs text-slate-500">
                            {{ review.date }}
                          </div>
                        </div>
                      </div>
                      <div class="flex">
                        <UIcon
                          v-for="n in 5"
                          :key="n"
                          :name="
                            n <= review.rating
                              ? 'i-heroicons-star-solid'
                              : 'i-heroicons-star'
                          "
                          class="w-3.5 h-3.5"
                          :class="
                            n <= review.rating
                              ? 'text-yellow-400'
                              : 'text-gray-200'
                          "
                        />
                      </div>
                    </div>
                    <p class="text-sm text-slate-600 dark:text-slate-300">
                      {{ review.comment }}
                    </p>
                  </div>
                </div>
                <!-- Write a Review Section -->
                <div
                  class="mb-6 p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg"
                >
                  <h4 class="font-medium text-slate-800 dark:text-white mb-3">
                    Write a Review
                  </h4>
                  <div class="space-y-4">
                    <div>
                      <label
                        class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                      >
                        Rating
                      </label>
                      <div class="flex gap-1">
                        <UButton
                          v-for="star in 5"
                          :key="star"
                          variant="ghost"
                          color="gray"
                          class="p-1"
                          @click="reviewForm.rating = star"
                        >
                          <UIcon
                            :name="
                              star <= reviewForm.rating
                                ? 'i-heroicons-star-solid'
                                : 'i-heroicons-star'
                            "
                            class="w-6 h-6 transition-colors duration-200"
                            :class="
                              star <= reviewForm.rating
                                ? 'text-yellow-400'
                                : 'text-slate-300 dark:text-slate-600'
                            "
                          />
                        </UButton>
                      </div>
                    </div>
                    <div>
                      <label
                        class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                      >
                        Your Name
                      </label>
                      <UInput
                        v-model="reviewForm.name"
                        placeholder="Enter your name"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                      >
                        Review Comment
                      </label>
                      <UTextarea
                        v-model="reviewForm.comment"
                        placeholder="Share your thoughts about this product"
                        :ui="{ rounded: 'rounded-lg' }"
                        rows="3"
                      />
                    </div>
                    <UButton
                      color="primary"
                      @click="submitReview"
                      :disabled="!isReviewValid"
                      block
                    >
                      Submit Review
                    </UButton>
                  </div>
                </div>
              </div>
            </template>

            <!-- Details Tab -->
            <template #details>
              <div
                class="prose prose-sm max-w-none text-slate-600 dark:text-slate-300"
              >
                <div v-html="currentProduct.description"></div>
                <p class="mt-3">
                  Experience the perfect blend of design and functionality with
                  our {{ currentProduct.name }}. Designed with the modern
                  consumer in mind.
                </p>

                <h4
                  class="text-base font-semibold mt-4 mb-2 text-slate-800 dark:text-white"
                >
                  Specifications
                </h4>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-2">
                  <div
                    class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                  >
                    <span class="text-slate-500 dark:text-slate-400"
                      >Brand:</span
                    >
                    <span class="font-medium">Premium Selection</span>
                  </div>
                  <div
                    class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                  >
                    <span class="text-slate-500 dark:text-slate-400"
                      >Model:</span
                    >
                    <span class="font-medium"
                      >X-{{ 1000 + Math.floor(Math.random() * 9000) }}</span
                    >
                  </div>
                  <div
                    class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                  >
                    <span class="text-slate-500 dark:text-slate-400"
                      >Dimensions:</span
                    >
                    <span class="font-medium">24 x 12 x 8 cm</span>
                  </div>
                  <div
                    class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                  >
                    <span class="text-slate-500 dark:text-slate-400"
                      >Weight:</span
                    >
                    <span class="font-medium">1.2 kg</span>
                  </div>
                </div>
              </div>
            </template>
          </UTabs>
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
