<!-- filepath: c:\Users\NextOxy\Desktop\office\oxy-us\frontend\components\common\product-details-card2.vue -->
<template>
  <div class="product-sales-funnel w-full">
    <!-- Hero Section -->
    <section
      class="hero-section bg-gradient-to-br from-slate-900 to-slate-800 text-white rounded-xl overflow-hidden w-full"
    >
      <div class="px-6 py-2 md:py-20 w-full">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <!-- Product Image -->
          <div class="relative order-2 md:order-1">
            <div
              class="aspect-square rounded-xl overflow-hidden bg-white/10 backdrop-blur-sm p-6 shadow-2xl relative"
            >
              <img
                v-if="
                  currentProduct.image_details &&
                  currentProduct.image_details.length > 0
                "
                :src="currentProduct.image_details[0].image"
                :alt="currentProduct.name"
                class="w-full h-full object-contain"
              />
              <!-- Sale badge -->
              <div
                v-if="currentProduct.sale_price && currentProduct.regular_price"
                class="absolute top-4 right-4 bg-red-500 text-white text-sm font-bold px-3 py-1.5 rounded-full shadow-lg animate-pulse"
              >
                SAVE
                {{
                  calculateDiscountPercentage(
                    currentProduct.regular_price,
                    currentProduct.sale_price
                  )
                }}%
              </div>
            </div>
          </div>

          <!-- Product Headline -->
          <div class="order-1 md:order-2">
            <span
              class="inline-block px-3 py-1 bg-primary-500/20 text-primary-400 rounded-full text-xs uppercase font-semibold mb-4"
            >
              {{ currentProduct.category_details?.name || "Premium Product" }}
            </span>
            <h1 class="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">
              {{ currentProduct.name }}
            </h1>
            <div class="flex items-center mb-4">
              <div class="flex text-amber-400">
                <UIcon
                  v-for="n in 5"
                  :key="n"
                  name="i-heroicons-star-solid"
                  class="w-5 h-5"
                />
              </div>
              <span class="text-sm text-white/70 ml-2">
                {{ reviewCount }} verified reviews
              </span>
            </div>
            <p class="text-lg text-white/80 mb-6">
              {{
                currentProduct.short_description ||
                "Experience the ultimate product designed to transform your life. Premium quality, outstanding performance, and exceptional value."
              }}
            </p>

            <!-- Price Section -->
            <div class="flex items-baseline mb-8">
              <span class="text-4xl font-bold text-white">
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </span>
              <span
                v-if="currentProduct.regular_price && currentProduct.sale_price"
                class="text-lg text-white/60 line-through ml-2"
              >
                ৳{{ currentProduct.regular_price }}
              </span>
            </div>

            <!-- Primary CTA Button -->
            <button
              @click="addToCart(currentProduct, 1)"
              class="w-full md:w-auto px-8 py-4 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white text-lg font-bold rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 focus:ring-4 focus:ring-primary-500/50 flex items-center justify-center gap-3 group"
            >
              <UIcon name="i-heroicons-shopping-cart" class="w-6 h-6" />
              Buy Now
              <span
                class="group-hover:translate-x-1 transition-transform duration-300"
              >
                <UIcon name="i-heroicons-arrow-right" class="w-5 h-5" />
              </span>
            </button>

            <!-- Trust Badges -->
            <div
              class="flex flex-wrap justify-center md:justify-start gap-4 mt-8"
            >
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-shield-check"
                  class="w-5 h-5 text-emerald-400"
                />
                <span class="text-xs text-white/70">Secure Payment</span>
              </div>
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-truck"
                  class="w-5 h-5 text-emerald-400"
                />
                <span class="text-xs text-white/70">Fast Delivery</span>
              </div>
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-arrow-path"
                  class="w-5 h-5 text-emerald-400"
                />
                <span class="text-xs text-white/70">30-Day Returns</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Description Section -->
    <section class="w-full my-6">
      <div class="bg-slate-50 dark:bg-slate-800/20 rounded-lg p-6">
        <div class="prose prose-slate dark:prose-invert max-w-none">
          <div
            v-if="currentProduct.description"
            v-html="currentProduct.description"
          ></div>
          <p v-else>
            This premium product offers exceptional performance and reliability.
            Built with high-quality materials and expert craftsmanship, it's
            designed to exceed your expectations. The ergonomic design ensures
            comfortable use while the durable construction guarantees
            long-lasting performance.
          </p>
        </div>
      </div>
    </section>

    <!-- Key Benefits Section -->
    <section class="py-2 w-full">
      <h2 class="text-2xl md:text-3xl font-bold text-center mb-12">
        Why Choose
        <span class="text-primary-600 dark:text-primary-400">{{
          currentProduct.name
        }}</span
        >?
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div class="benefit-card">
          <div class="icon-container">
            <UIcon
              name="i-heroicons-sparkles"
              class="w-8 h-8 text-primary-500"
            />
          </div>
          <h3 class="text-xl font-semibold mb-2">Premium Quality</h3>
          <p>
            Crafted with the highest quality materials for exceptional
            durability and performance.
          </p>
        </div>

        <div class="benefit-card">
          <div class="icon-container">
            <UIcon
              name="i-heroicons-rocket-launch"
              class="w-8 h-8 text-primary-500"
            />
          </div>
          <h3 class="text-xl font-semibold mb-2">Fast Results</h3>
          <p>
            Experience immediate benefits and see results faster than with
            competing products.
          </p>
        </div>

        <div class="benefit-card">
          <div class="icon-container">
            <UIcon
              name="i-heroicons-check-badge"
              class="w-8 h-8 text-primary-500"
            />
          </div>
          <h3 class="text-xl font-semibold mb-2">Satisfaction Guarantee</h3>
          <p>
            Not completely satisfied? Return within 30 days for a full refund,
            no questions asked.
          </p>
        </div>
      </div>

      <div class="text-center mt-12">
        <button
          @click="addToCart(currentProduct, 1)"
          class="px-8 py-3 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white font-bold rounded-xl shadow-lg transition-all duration-300"
        >
          Yes! I Want This Now
        </button>
      </div>
    </section>

    <!-- Shipping Information Section -->
    <section
      class="pt-10 pb-2 bg-slate-50 dark:bg-slate-800/30 rounded-xl w-full"
    >
      <div class="w-full px-6">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          Shipping Information
        </h2>
        <p class="text-center text-slate-600 dark:text-slate-300 mb-6">
          Fast and reliable delivery options for {{ currentProduct.name }}
        </p>

        <div class="py-6 max-w-3xl mx-auto">
          <div
            class="mb-6 p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-100 dark:border-green-900"
          >
            <div class="flex items-start">
              <UIcon
                name="i-heroicons-information-circle"
                class="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 mr-2 flex-shrink-0"
              />
              <p class="text-green-800 dark:text-green-300 text-sm">
                <strong>Free shipping available!</strong> Orders over ৳5,000
                qualify for free delivery nationwide.
              </p>
            </div>
          </div>

          <div class="space-y-4">
            <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-truck"
                    class="w-5 h-5 text-slate-600 dark:text-slate-300 mr-2"
                  />
                  <h4 class="font-medium">Inside Dhaka</h4>
                </div>
                <div class="font-semibold">
                  ৳{{ currentProduct.delivery_fee_inside_dhaka || "100" }}
                </div>
              </div>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                Estimated delivery: 2-3 business days
              </p>
            </div>

            <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-truck"
                    class="w-5 h-5 text-slate-600 dark:text-slate-300 mr-2"
                  />
                  <h4 class="font-medium">Outside Dhaka</h4>
                </div>
                <div class="font-semibold">
                  ৳{{ currentProduct.delivery_fee_outside_dhaka || "150" }}
                </div>
              </div>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                Estimated delivery: 3-5 business days
              </p>
            </div>

            <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm">
              <div class="flex items-center">
                <UIcon
                  name="i-heroicons-gift"
                  class="w-5 h-5 text-slate-600 dark:text-slate-300 mr-2"
                />
                <h4 class="font-medium">Premium Packaging</h4>
              </div>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                All products are securely packed to ensure safe delivery
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Customer Reviews Section -->
    <section class="pb-2 pt-10 w-full customer-reviews-section">
      <div class="w-full px-3">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          Customer Reviews
        </h2>
        <p class="text-center text-slate-600 dark:text-slate-300 mb-12">
          Join thousands of satisfied customers who have experienced the
          difference
        </p>

        <!-- Reviews Summary -->
        <div
          class="mb-10 bg-white dark:bg-slate-800/80 rounded-xl shadow-md p-6 max-w-4xl mx-auto"
        >
          <div class="flex flex-col md:flex-row gap-6 md:items-center">
            <div
              class="text-center md:border-r md:border-slate-200 dark:md:border-slate-700 md:pr-6"
            >
              <div
                class="text-5xl font-bold text-slate-800 dark:text-white mb-2"
              >
                {{ averageRating }}
              </div>
              <div class="flex justify-center text-amber-400 my-1">
                <UIcon
                  v-for="i in 5"
                  :key="i"
                  name="i-heroicons-star-solid"
                  class="w-6 h-6"
                />
              </div>
              <div class="text-sm text-slate-500 dark:text-slate-400">
                Based on {{ reviewCount }} reviews
              </div>
            </div>

            <div class="flex-1 space-y-2">
              <div v-for="n in 5" :key="n" class="flex items-center">
                <div class="text-sm w-5 text-right mr-3">
                  {{ 6 - n }}
                </div>
                <UIcon
                  name="i-heroicons-star-solid"
                  class="w-4 h-4 text-amber-400 mr-2"
                />
                <div
                  class="flex-1 h-2.5 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden"
                >
                  <div
                    class="h-full bg-amber-400"
                    :style="{ width: getRatingPercentage(6 - n) }"
                  ></div>
                </div>
                <div class="text-sm w-10 text-left ml-3">
                  {{ getRatingCount(6 - n) }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Featured Reviews with Pagination -->
        <div class="max-w-6xl mx-auto mb-10">
          <!-- Reviews grid -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div
              v-for="(review, index) in displayedReviews"
              :key="index"
              class="bg-white dark:bg-slate-800 rounded-xl shadow-md p-6 transition-transform hover:translate-y-[-5px]"
            >
              <div class="flex text-amber-400 mb-3">
                <UIcon
                  v-for="star in 5"
                  :key="star"
                  :name="
                    star <= review.rating
                      ? 'i-heroicons-star-solid'
                      : 'i-heroicons-star'
                  "
                  class="w-5 h-5"
                  :class="
                    star <= review.rating ? 'text-amber-400' : 'text-gray-200'
                  "
                />
              </div>
              <p class="text-slate-600 dark:text-slate-300 mb-4">
                "{{ review.comment }}"
              </p>
              <div class="flex items-center">
                <div
                  class="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mr-3 text-primary-700 dark:text-primary-300 font-medium"
                >
                  {{ review.name?.charAt(0) || "U" }}
                </div>
                <div>
                  <div class="font-medium text-slate-900 dark:text-white">
                    {{ review.name }}
                  </div>
                  <div class="text-xs text-slate-500 dark:text-slate-400">
                    {{ review.date || "Verified Purchase" }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Pagination controls -->
          <div
            class="flex justify-center items-center mt-8 gap-2"
            v-if="totalReviewPages > 1"
          >
            <!-- Previous button -->
            <UButton
              icon="i-heroicons-chevron-left"
              color="gray"
              variant="ghost"
              :disabled="currentReviewPage === 1"
              @click="previousReviewPage"
              size="sm"
              class="rounded-full"
            />

            <!-- Page numbers -->
            <div class="flex gap-1">
              <UButton
                v-for="page in paginationRange"
                :key="page"
                :variant="currentReviewPage === page ? 'solid' : 'ghost'"
                :color="currentReviewPage === page ? 'primary' : 'gray'"
                size="sm"
                class="w-8 h-8"
                @click="goToReviewPage(page)"
                v-if="page !== '...'"
              >
                {{ page }}
              </UButton>
              <!-- Ellipsis -->
              <div
                v-if="paginationRange.includes('...')"
                class="w-8 h-8 flex items-center justify-center text-slate-500"
              >
                ...
              </div>
            </div>

            <!-- Next button -->
            <UButton
              icon="i-heroicons-chevron-right"
              color="gray"
              variant="ghost"
              :disabled="currentReviewPage === totalReviewPages"
              @click="nextReviewPage"
              size="sm"
              class="rounded-full"
            />
          </div>
        </div>

        <!-- Write a Review Section (Updated) -->
        <div
          class="mt-12 bg-slate-50 dark:bg-slate-800/50 rounded-xl p-2 max-w-3xl mx-auto"
        >
          <h3 class="text-xl font-semibold mb-4 text-center">
            Share Your Experience
          </h3>

          <!-- Conditionally show review form or login message -->
          <div v-if="isLoggedIn">
            <div class="space-y-4">
              <div>
                <label
                  class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                >
                  Your Rating
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
                          ? 'text-amber-400'
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
                  Your Review
                </label>
                <UTextarea
                  v-model="reviewForm.comment"
                  placeholder="Share your experience with this product..."
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

          <div v-else class="text-center p-6">
            <UIcon
              name="i-heroicons-lock-closed"
              class="w-12 h-12 text-slate-300 dark:text-slate-600 mx-auto mb-4"
            />
            <h4 class="text-lg font-medium mb-2">Please Log In to Review</h4>
            <p class="text-slate-600 dark:text-slate-400 mb-4">
              You need to be logged in to share your experience with this
              product.
            </p>
            <div class="flex justify-center">
              <UButton to="/login" color="primary">
                Log in to continue
              </UButton>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-2 w-full">
      <div class="w-full px-3 max-w-4xl mx-auto">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          Frequently Asked Questions
        </h2>
        <p class="text-center text-slate-600 dark:text-slate-300 mb-12">
          Everything you need to know about our product
        </p>

        <div>
          <UAccordion :items="faqs" />
        </div>
      </div>
    </section>

    <!-- Final CTA Section -->
    <section
      class="py-2 bg-gradient-to-br from-primary-600 to-primary-800 text-white rounded-xl my-6 w-full"
    >
      <div class="px-6 py-8 text-center w-full">
        <h2 class="text-3xl md:text-4xl font-bold mb-6">
          Ready to Experience the Difference?
        </h2>
        <p class="text-white/80 mb-8 text-lg max-w-3xl mx-auto">
          Join thousands of satisfied customers who have already transformed
          their experience with {{ currentProduct.name }}.
        </p>

        <!-- Price Box -->
        <div
          class="mb-8 inline-block bg-white/10 backdrop-blur-sm rounded-xl p-6 mx-auto"
        >
          <div class="flex items-center justify-center gap-4">
            <div class="text-center">
              <div class="text-white/60 line-through text-lg">
                Regular Price:
              </div>
              <div class="text-2xl font-bold">
                ৳{{
                  currentProduct.regular_price ||
                  (currentProduct.sale_price || 0) * 1.5
                }}
              </div>
            </div>
            <div class="text-4xl font-bold">→</div>
            <div class="text-center">
              <div class="text-white/90 text-lg">Special Offer:</div>
              <div class="text-4xl font-bold">
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </div>
            </div>
          </div>
        </div>

        <button
          @click="addToCart(currentProduct, 1)"
          class="px-10 py-4 bg-white hover:bg-slate-50 text-primary-700 text-xl font-bold rounded-xl shadow-2xl transition-all duration-300 animate-pulse hover:animate-none transform hover:scale-105"
        >
          Order Now & Save
          <span class="block text-sm font-normal mt-1"
            >30-Day Money Back Guarantee</span
          >
        </button>

        <!-- Trust Badges -->
        <div class="flex flex-wrap justify-center gap-6 mt-8">
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
          >
            <UIcon name="i-heroicons-credit-card" class="w-5 h-5" />
            <span class="text-sm">Secure Payment</span>
          </div>
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
          >
            <UIcon name="i-heroicons-shield-check" class="w-5 h-5" />
            <span class="text-sm">Money-Back Guarantee</span>
          </div>
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
          >
            <UIcon name="i-heroicons-truck" class="w-5 h-5" />
            <span class="text-sm">Fast Delivery</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Sticky Buy Now Button (Centered) -->
    <div
      class="fixed bottom-32 left-12 right-12 z-50 shadow-lg transform transition-transform"
      :class="{ 'translate-y-full': hideSticky, 'translate-y-0': !hideSticky }"
    >
      <div class="max-w-md mx-auto flex items-center justify-center">
        <button
          @click="addToCart(currentProduct, 1)"
          class="w-full bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white px-6 py-3 rounded-lg font-medium shadow flex items-center justify-center gap-2"
        >
          <div class="flex items-center gap-2">
            <UIcon name="i-heroicons-shopping-cart" class="w-5 h-5" />
            <span
              >Buy Now - ৳{{
                currentProduct.sale_price || currentProduct.regular_price
              }}</span
            >
          </div>
        </button>
      </div>
    </div>
  </div>
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
const user = useState("user"); // Access user state

// Check if user is logged in
const isLoggedIn = computed(() => !!user.value);

// Determine if user can submit a review
const canSubmitReview = computed(() => {
  return isLoggedIn.value;
});

function addToCart(product, quantity) {
  cart.addProduct(product, quantity);
  navigateTo("/checkout/");
}

// Calculate discount percentage
function calculateDiscountPercentage(regular, sale) {
  if (!regular || !sale) return 0;

  const regularPrice = parseFloat(regular);
  const salePrice = parseFloat(sale);

  if (regularPrice <= 0) return 0;

  const discount = Math.round(
    ((regularPrice - salePrice) / regularPrice) * 100
  );
  return discount;
}

// Calculate savings
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

const reviewForm = ref({
  name: "",
  rating: 0,
  comment: "",
});

// Review calculations
const reviewCount = computed(() => {
  return currentProduct?.reviews?.length || 125;
});

const averageRating = computed(() => {
  if (!currentProduct?.reviews?.length) return "4.9";

  const sum = currentProduct.reviews.reduce(
    (total, review) => total + review.rating,
    0
  );
  return (sum / currentProduct.reviews.length).toFixed(1);
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
  if (!currentProduct?.reviews?.length) {
    // Default distribution if no reviews
    if (rating === 5) return "78%";
    if (rating === 4) return "18%";
    if (rating === 3) return "3%";
    return "1%";
  }

  const total = currentProduct.reviews.length;
  const count = currentProduct.reviews.filter(
    (r) => Math.round(r.rating) === rating
  ).length;

  return `${(count / total) * 100}%`;
}

function getRatingCount(rating) {
  if (!currentProduct?.reviews?.length) {
    // Default counts if no reviews
    if (rating === 5) return "98";
    if (rating === 4) return "22";
    if (rating === 3) return "4";
    return "1";
  }

  return currentProduct.reviews.filter((r) => Math.round(r.rating) === rating)
    .length;
}

// Reviews pagination
const reviewsPerPage = 3;
const currentReviewPage = ref(1);

// Modified to support pagination
const displayedReviews = computed(() => {
  // Get all available reviews (actual or sample)
  const allReviews =
    currentProduct?.reviews?.length > 0
      ? currentProduct.reviews
      : [
          {
            name: "Ahmed Khan",
            rating: 5,
            date: "2 weeks ago",
            comment:
              "This product exceeded my expectations! The quality is outstanding and it arrived quickly. Would definitely recommend to anyone looking for a premium solution.",
          },
          {
            name: "Priya Sharma",
            rating: 5,
            date: "1 month ago",
            comment:
              "I've tried many similar products but this one stands out. The attention to detail is impressive and the performance is consistently reliable.",
          },
          {
            name: "Mohammad Ali",
            rating: 4,
            date: "3 weeks ago",
            comment:
              "Great product overall. Shipping was fast and the quality is as advertised. Only giving 4 stars because the instructions could be clearer.",
          },
          {
            name: "Sarah Johnson",
            rating: 5,
            date: "2 months ago",
            comment:
              "Absolutely love this! It's made such a difference in my daily routine. The design is beautiful and functionality is perfect.",
          },
          {
            name: "Rahul Patel",
            rating: 5,
            date: "3 months ago",
            comment:
              "Best purchase I've made this year! The product is durable, well-designed and performs exactly as described. Customer service was also excellent.",
          },
          {
            name: "Lisa Wong",
            rating: 4,
            date: "1 month ago",
            comment:
              "Very satisfied with my purchase. The product is high quality and the delivery was quick. Would buy from this store again.",
          },
        ];

  // Calculate the start and end index for the current page
  const startIndex = (currentReviewPage.value - 1) * reviewsPerPage;
  const endIndex = startIndex + reviewsPerPage;

  // Return the reviews for the current page
  return allReviews.slice(startIndex, endIndex);
});

// Calculate total number of pages
const totalReviewPages = computed(() => {
  const totalReviews = currentProduct?.reviews?.length || 6; // Use 6 if no reviews
  return Math.ceil(totalReviews / reviewsPerPage);
});

// Generate pagination range with ellipsis for many pages
const paginationRange = computed(() => {
  if (totalReviewPages.value <= 5) {
    return Array.from({ length: totalReviewPages.value }, (_, i) => i + 1);
  }

  if (currentReviewPage.value <= 3) {
    return [1, 2, 3, 4, "...", totalReviewPages.value];
  }

  if (currentReviewPage.value >= totalReviewPages.value - 2) {
    return [
      1,
      "...",
      totalReviewPages.value - 3,
      totalReviewPages.value - 2,
      totalReviewPages.value - 1,
      totalReviewPages.value,
    ];
  }

  return [
    1,
    "...",
    currentReviewPage.value - 1,
    currentReviewPage.value,
    currentReviewPage.value + 1,
    "...",
    totalReviewPages.value,
  ];
});

// Navigation functions
function goToReviewPage(page) {
  currentReviewPage.value = page;
}

function previousReviewPage() {
  if (currentReviewPage.value > 1) {
    currentReviewPage.value--;
  }
}

function nextReviewPage() {
  if (currentReviewPage.value < totalReviewPages.value) {
    currentReviewPage.value++;
  }
}

// Auto-scroll to reviews when page changes
watch(currentReviewPage, () => {
  // Optional: Smooth scroll to the reviews section on page change
  const reviewsSection = document.querySelector(".customer-reviews-section");
  if (reviewsSection) {
    setTimeout(() => {
      reviewsSection.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 100);
  }
});

// Submit review function
function submitReview() {
  if (!isReviewValid.value || !isLoggedIn.value) return;

  // Add review to product
  if (!currentProduct.reviews) {
    currentProduct.reviews = [];
  }

  currentProduct.reviews.unshift({
    name: reviewForm.value.name || user.value?.name || "Anonymous",
    rating: reviewForm.value.rating,
    date: "Just now",
    comment: reviewForm.value.comment.trim(),
    avatar: user.value?.avatar || "",
    verified: false, // Changed from hasPurchased.value
  });

  // Reset form
  reviewForm.value = {
    name: "",
    rating: 0,
    comment: "",
  };

  // Reset to first page to show the newly added review
  currentReviewPage.value = 1;
}

// FAQ items
const faqs = [
  {
    label: "How long is the warranty period?",
    content:
      "Our product comes with a full 1-year warranty that covers all manufacturing defects and normal wear and tear. We stand behind the quality of our products.",
    icon: "i-heroicons-shield-check",
  },
  {
    label: "What payment methods do you accept?",
    content:
      "We accept all major credit cards, mobile banking, bKash, Nagad, and bank transfers. All payments are processed securely.",
    icon: "i-heroicons-credit-card",
  },
  {
    label: "How long does delivery take?",
    content:
      "Delivery within Dhaka typically takes 2-3 business days. For locations outside Dhaka, please allow 3-5 business days for your order to arrive.",
    icon: "i-heroicons-truck",
  },
  {
    label: "Is this product suitable for commercial use?",
    content:
      "Yes, our product is designed for both personal and commercial use. The durable construction ensures it can withstand heavy usage in commercial settings.",
    icon: "i-heroicons-building-storefront",
  },
];

// Sticky button visibility control
const lastScrollPosition = ref(0);
const hideSticky = ref(true);

onMounted(() => {
  window.addEventListener("scroll", handleScroll);
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});

function handleScroll() {
  // Show sticky button when user has scrolled a bit (200px)
  if (window.scrollY > 200) {
    hideSticky.value = false;

    // Hide when scrolling up at the very top
    if (window.scrollY < lastScrollPosition.value && window.scrollY < 50) {
      hideSticky.value = true;
    }

    // Hide when reaching the bottom of the page (near the CTA)
    const bottomPosition =
      document.documentElement.scrollHeight - window.innerHeight - 300;
    if (window.scrollY > bottomPosition) {
      hideSticky.value = true;
    }
  } else {
    hideSticky.value = true;
  }

  lastScrollPosition.value = window.scrollY;
}
</script>

<style scoped>
.product-sales-funnel {
  width: 100%; /* Make it full width */
}

.benefit-card {
  @apply bg-white dark:bg-slate-800 p-6 rounded-xl shadow-md text-center;
}

.icon-container {
  @apply w-16 h-16 mx-auto bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mb-4;
}

.feature-item {
  @apply flex items-center gap-2 bg-white dark:bg-slate-800 p-3 rounded-lg shadow-sm;
}
</style>
