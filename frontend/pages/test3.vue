<template>
  <div class="py-6">
    <UContainer>
      <div class="mb-4">
        <h1
          class="text-2xl font-bold text-slate-800 dark:text-white flex items-center gap-2"
        >
          <UIcon name="i-heroicons-shopping-bag" class="w-6 h-6 text-primary" />
          Checkout
        </h1>
        <p class="text-slate-500 dark:text-slate-400">
          Complete your purchase securely
        </p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Left Side: Checkout Form -->
        <div class="lg:col-span-2 space-y-5">
          <!-- Customer Information -->
          <div
            class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-4 shadow-sm hover:shadow-md transition-all duration-300"
          >
            <h2
              class="text-lg font-medium text-slate-800 dark:text-white mb-3 flex items-center"
            >
              <UIcon
                name="i-heroicons-user-circle"
                class="mr-2 w-5 h-5 text-primary"
              />
              Your Information
            </h2>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                >
                  Full Name *
                </label>
                <UInput
                  v-model="checkout.name"
                  placeholder="Enter your full name"
                  :ui="{ base: 'w-full', input: 'w-full' }"
                />
              </div>

              <div>
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                >
                  Phone *
                </label>
                <UInput
                  v-model="checkout.phone"
                  placeholder="Enter your phone number"
                  :ui="{ base: 'w-full', input: 'w-full' }"
                />
              </div>

              <div class="md:col-span-2">
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                >
                  Delivery Address *
                </label>
                <UTextarea
                  v-model="checkout.address"
                  placeholder="Enter your full address"
                  rows="2"
                  :ui="{ base: 'w-full' }"
                />
              </div>
            </div>
          </div>

          <!-- Delivery Options -->
          <div
            class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-4 shadow-sm hover:shadow-md transition-all duration-300"
          >
            <h2
              class="text-lg font-medium text-slate-800 dark:text-white mb-3 flex items-center"
            >
              <UIcon
                name="i-heroicons-truck"
                class="mr-2 w-5 h-5 text-primary"
              />
              Delivery Options
            </h2>

            <div class="space-y-2">
              <label
                class="flex items-center p-3 border rounded-lg cursor-pointer transition-all duration-200 hover:bg-slate-50 dark:hover:bg-slate-700/50"
                :class="
                  checkout.deliveryOption === 'inside'
                    ? 'border-primary bg-primary/5'
                    : 'border-slate-200 dark:border-slate-700'
                "
              >
                <input
                  type="radio"
                  v-model="checkout.deliveryOption"
                  value="inside"
                  class="mr-3 text-primary"
                />
                <div class="flex-1">
                  <div
                    class="font-medium text-slate-800 dark:text-white flex items-center"
                  >
                    Inside Dhaka
                    <UBadge color="primary" variant="soft" class="ml-2"
                      >৳100</UBadge
                    >
                  </div>
                  <div class="text-sm text-slate-500 dark:text-slate-400">
                    Delivery within 1-2 business days
                  </div>
                </div>
              </label>

              <label
                class="flex items-center p-3 border rounded-lg cursor-pointer transition-all duration-200 hover:bg-slate-50 dark:hover:bg-slate-700/50"
                :class="
                  checkout.deliveryOption === 'outside'
                    ? 'border-primary bg-primary/5'
                    : 'border-slate-200 dark:border-slate-700'
                "
              >
                <input
                  type="radio"
                  v-model="checkout.deliveryOption"
                  value="outside"
                  class="mr-3 text-primary"
                />
                <div class="flex-1">
                  <div
                    class="font-medium text-slate-800 dark:text-white flex items-center"
                  >
                    Outside Dhaka
                    <UBadge color="primary" variant="soft" class="ml-2"
                      >৳150</UBadge
                    >
                  </div>
                  <div class="text-sm text-slate-500 dark:text-slate-400">
                    Delivery within 3-5 business days
                  </div>
                </div>
              </label>

              <label
                v-if="hasFreeShipping"
                class="flex items-center p-3 border rounded-lg cursor-pointer transition-all duration-200 hover:bg-slate-50 dark:hover:bg-slate-700/50"
                :class="
                  checkout.deliveryOption === 'free'
                    ? 'border-primary bg-primary/5'
                    : 'border-slate-200 dark:border-slate-700'
                "
              >
                <input
                  type="radio"
                  v-model="checkout.deliveryOption"
                  value="free"
                  class="mr-3 text-primary"
                />
                <div class="flex-1">
                  <div
                    class="font-medium text-slate-800 dark:text-white flex items-center"
                  >
                    Free Shipping
                    <UBadge color="green" variant="soft" class="ml-2"
                      >৳0</UBadge
                    >
                  </div>
                  <div class="text-sm text-slate-500 dark:text-slate-400">
                    Free delivery for eligible orders
                  </div>
                </div>
              </label>
            </div>
          </div>

          <!-- Payment Method with Improved Insufficient Balance Warning -->
          <div
            class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-4 shadow-sm hover:shadow-md transition-all duration-300 payment-section"
            :class="{
              'border-red-300 dark:border-red-700': showInsufficientFundsError,
            }"
          >
            <h2
              class="text-lg font-medium text-slate-800 dark:text-white mb-3 flex items-center"
            >
              <UIcon
                name="i-heroicons-credit-card"
                class="mr-2 w-5 h-5 text-primary"
              />
              Payment Method
            </h2>

            <div class="space-y-2">
              <label
                class="flex items-center p-3 border rounded-lg cursor-pointer transition-all duration-200 hover:bg-slate-50 dark:hover:bg-slate-700/50"
                :class="[
                  checkout.paymentMethod === 'account'
                    ? 'border-primary bg-primary/5'
                    : 'border-slate-200 dark:border-slate-700',
                  showInsufficientFundsError &&
                  checkout.paymentMethod === 'account'
                    ? 'border-red-300 dark:border-red-700 bg-red-50 dark:bg-red-900/10'
                    : '',
                ]"
              >
                <input
                  type="radio"
                  v-model="checkout.paymentMethod"
                  value="account"
                  class="mr-3 text-primary"
                />
                <div class="flex-1 relative">
                  <div
                    class="font-medium text-slate-800 dark:text-white flex items-center"
                  >
                    Account Funds
                    <UBadge
                      :color="showInsufficientFundsError ? 'red' : 'primary'"
                      variant="soft"
                      class="ml-2 balance-badge"
                      :class="{
                        'animate-pulse-subtle': showInsufficientFundsError,
                      }"
                    >
                      ৳{{ formatPrice(userBalance) }}
                    </UBadge>
                  </div>
                  <div class="text-sm text-slate-500 dark:text-slate-400">
                    Pay using your account balance
                  </div>

                  <!-- Insufficient funds warning - Inside the payment option -->
                  <div
                    v-if="
                      showInsufficientFundsError &&
                      checkout.paymentMethod === 'account'
                    "
                    class="mt-2 text-xs text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/10 p-2 rounded border border-red-100 dark:border-red-800/20 warning-slide-in"
                  >
                    <div class="flex items-start">
                      <UIcon
                        name="i-heroicons-exclamation-triangle"
                        class="w-4 h-4 mr-1.5 mt-0.5 text-red-500"
                      />
                      <div>
                        <p class="font-medium">
                          Insufficient funds for this purchase
                        </p>
                        <p class="mt-0.5">
                          You need
                          <span class="font-medium"
                            >৳{{ formatPrice(total - userBalance) }}</span
                          >
                          more to complete this order
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </label>

              <label
                class="flex items-center p-3 border rounded-lg cursor-pointer transition-all duration-200 hover:bg-slate-50 dark:hover:bg-slate-700/50"
                :class="
                  checkout.paymentMethod === 'cod'
                    ? 'border-primary bg-primary/5'
                    : 'border-slate-200 dark:border-slate-700'
                "
              >
                <input
                  type="radio"
                  v-model="checkout.paymentMethod"
                  value="cod"
                  class="mr-3 text-primary"
                />
                <div class="flex-1">
                  <div class="font-medium text-slate-800 dark:text-white">
                    Cash on Delivery
                  </div>
                  <div class="text-sm text-slate-500 dark:text-slate-400">
                    Pay when you receive your order
                  </div>
                </div>
              </label>
            </div>
          </div>
        </div>

        <!-- Right Side: Order Summary -->
        <div class="lg:col-span-1">
          <div
            class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-4 shadow-sm hover:shadow-lg transition-all duration-300 sticky top-4"
          >
            <h2
              class="text-lg font-medium text-slate-800 dark:text-white mb-3 flex items-center"
            >
              <UIcon
                name="i-heroicons-shopping-cart"
                class="mr-2 w-5 h-5 text-primary"
              />
              Order Summary
            </h2>

            <!-- Products -->
            <div class="space-y-3 mb-4 max-h-60 overflow-y-auto pr-1">
              <div
                v-for="(item, index) in cartItems"
                :key="index"
                class="flex gap-3 pb-3 border-b border-slate-100 dark:border-slate-700"
              >
                <div
                  class="w-14 h-14 bg-slate-50 dark:bg-slate-700 rounded-md overflow-hidden flex-shrink-0 border border-slate-200 dark:border-slate-600"
                >
                  <img
                    :src="item.image"
                    :alt="item.name"
                    class="w-full h-full object-cover"
                  />
                </div>

                <div class="flex-1">
                  <div class="flex justify-between">
                    <div>
                      <h3
                        class="font-medium text-slate-800 dark:text-white text-sm"
                      >
                        {{ item.name }}
                      </h3>
                      <p class="text-xs text-slate-500 dark:text-slate-400">
                        {{ item.category }}
                      </p>
                    </div>
                    <div
                      class="text-sm font-medium text-slate-800 dark:text-white"
                    >
                      ৳{{ formatPrice(item.price * item.quantity) }}
                    </div>
                  </div>

                  <div class="flex items-center mt-2">
                    <div
                      class="flex items-center border border-slate-200 dark:border-slate-600 rounded-md"
                    >
                      <button
                        @click="decreaseQuantity(index)"
                        class="w-6 h-6 flex items-center justify-center text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-700"
                        :disabled="item.quantity <= 1"
                      >
                        <UIcon name="i-heroicons-minus-small" class="w-3 h-3" />
                      </button>

                      <span class="w-7 text-center text-sm">{{
                        item.quantity
                      }}</span>

                      <button
                        @click="increaseQuantity(index)"
                        class="w-6 h-6 flex items-center justify-center text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-700"
                      >
                        <UIcon name="i-heroicons-plus-small" class="w-3 h-3" />
                      </button>
                    </div>

                    <button
                      @click="removeItem(index)"
                      class="ml-2 text-red-500 hover:text-red-600 text-xs"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Price Summary -->
            <div
              class="space-y-2 py-3 border-b border-slate-200 dark:border-slate-700"
            >
              <div class="flex justify-between">
                <span class="text-sm text-slate-600 dark:text-slate-400"
                  >Subtotal</span
                >
                <span class="font-medium text-sm text-slate-800 dark:text-white"
                  >৳{{ formatPrice(subTotal) }}</span
                >
              </div>

              <div class="flex justify-between">
                <span class="text-sm text-slate-600 dark:text-slate-400"
                  >Shipping</span
                >
                <span class="font-medium text-sm text-slate-800 dark:text-white"
                  >৳{{ formatPrice(deliveryCharge) }}</span
                >
              </div>

              <div v-if="discount > 0" class="flex justify-between">
                <span class="text-sm text-slate-600 dark:text-slate-400"
                  >Discount</span
                >
                <span class="font-medium text-sm text-green-600"
                  >-৳{{ formatPrice(discount) }}</span
                >
              </div>
            </div>

            <!-- Total -->
            <div class="flex justify-between py-3">
              <span class="font-medium text-slate-800 dark:text-white"
                >Total</span
              >
              <span class="font-bold text-lg text-slate-800 dark:text-white"
                >৳{{ formatPrice(total) }}</span
              >
            </div>

            <!-- Checkout Button -->
            <div class="mt-4">
              <button
                class="relative w-full py-3 px-4 overflow-hidden group bg-gradient-to-r from-primary to-primary-600 hover:from-primary-600 hover:to-primary text-white font-medium rounded-lg shadow-md hover:shadow-lg transition-all duration-300 flex items-center justify-center disabled:opacity-70 disabled:cursor-not-allowed"
                :disabled="!isFormValid || processing"
                @click="placeOrder"
              >
                <!-- Hover effect -->
                <span
                  class="absolute w-0 h-0 transition-all duration-300 rounded-full bg-white opacity-10 group-hover:w-full group-hover:h-full"
                ></span>

                <!-- Button content -->
                <span v-if="processing" class="flex items-center">
                  <svg
                    class="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    ></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  Processing...
                </span>
                <span v-else class="flex items-center">
                  <UIcon name="i-heroicons-check-circle" class="mr-2 w-5 h-5" />
                  Complete Order
                </span>
              </button>

              <p
                class="text-xs text-center mt-3 text-slate-500 dark:text-slate-400"
              >
                By placing this order, you agree to our
                <NuxtLink to="/terms" class="text-primary hover:underline"
                  >Terms of Service</NuxtLink
                >
                and
                <NuxtLink to="/privacy" class="text-primary hover:underline"
                  >Privacy Policy</NuxtLink
                >
              </p>
            </div>
          </div>
        </div>
      </div>
    </UContainer>

    <!-- Success Modal -->
    <UModal
      v-model="showSuccessModal"
      :ui="{ padding: 'p-0', background: 'bg-transparent' }"
    >
      <div
        class="modal-container bg-white dark:bg-slate-800 rounded-xl overflow-hidden shadow-2xl transform transition-all max-w-lg w-full mx-auto"
      >
        <!-- Success Animation Header -->
        <div
          class="relative bg-gradient-to-r from-primary/90 to-primary-600 h-32 overflow-hidden"
        >
          <!-- Animated particles/confetti -->
          <div class="absolute inset-0">
            <div
              v-for="n in 20"
              :key="n"
              class="confetti-particle"
              :style="{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
                animationDelay: `${Math.random() * 2}s`,
                backgroundColor: ['#ffffff', '#ffd700', '#ffffff', '#e5e7eb'][
                  Math.floor(Math.random() * 4)
                ],
              }"
            ></div>
          </div>

          <!-- Checkmark -->
          <div class="absolute mt-4 left-1/2 -translate-x-1/2 w-20 h-20">
            <div
              class="absolute w-20 h-20 rounded-full bg-white dark:bg-slate-800 shadow-lg flex items-center justify-center"
            >
              <div class="success-checkmark">
                <div class="check-icon">
                  <span class="icon-line line-tip"></span>
                  <span class="icon-line line-long"></span>
                  <div class="icon-circle"></div>
                  <div class="icon-fix"></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Content -->
        <div class="pt-16 pb-4 px-6">
          <h3
            class="text-xl font-bold text-center text-slate-800 dark:text-white mb-1"
          >
            Order Confirmed!
          </h3>
          <p class="text-slate-500 dark:text-slate-400 text-center mb-6">
            Thank you for your purchase. We're processing your order now.
          </p>

          <!-- Order Details Card -->
          <div
            class="bg-slate-50 dark:bg-slate-700/30 rounded-lg p-4 backdrop-blur-sm border border-slate-100 dark:border-slate-600/20 mb-5"
          >
            <div class="space-y-3">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-shopping-bag"
                    class="w-5 h-5 text-primary mr-2"
                  />
                  <span class="text-sm text-slate-500 dark:text-slate-400"
                    >Order ID</span
                  >
                </div>
                <span
                  class="text-sm font-semibold text-slate-800 dark:text-white"
                  >#{{ orderId }}</span
                >
              </div>

              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-currency-bangladeshi"
                    class="w-5 h-5 text-primary mr-2"
                  />
                  <span class="text-sm text-slate-500 dark:text-slate-400"
                    >Total Amount</span
                  >
                </div>
                <span
                  class="text-sm font-semibold text-slate-800 dark:text-white"
                  >৳{{ formatPrice(total) }}</span
                >
              </div>

              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-credit-card"
                    class="w-5 h-5 text-primary mr-2"
                  />
                  <span class="text-sm text-slate-500 dark:text-slate-400"
                    >Payment</span
                  >
                </div>
                <span
                  class="text-sm font-semibold text-slate-800 dark:text-white"
                >
                  {{
                    checkout.paymentMethod === "account"
                      ? "Account Funds"
                      : "Cash on Delivery"
                  }}
                </span>
              </div>

              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-truck"
                    class="w-5 h-5 text-primary mr-2"
                  />
                  <span class="text-sm text-slate-500 dark:text-slate-400"
                    >Delivery</span
                  >
                </div>
                <span
                  class="text-sm font-semibold text-slate-800 dark:text-white"
                >
                  {{
                    checkout.deliveryOption === "inside"
                      ? "Inside Dhaka"
                      : checkout.deliveryOption === "outside"
                      ? "Outside Dhaka"
                      : "Free Shipping"
                  }}
                </span>
              </div>
            </div>
          </div>

          <!-- Status Timeline -->
          <div class="relative mb-6 px-2">
            <div
              class="absolute left-4 top-0 bottom-0 w-0.5 bg-slate-200 dark:bg-slate-700"
            ></div>

            <div class="relative pl-8 pb-3">
              <div
                class="absolute left-0 w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center"
              >
                <div class="w-3 h-3 rounded-full bg-primary pulse-circle"></div>
              </div>
              <div>
                <p class="font-medium text-sm text-slate-800 dark:text-white">
                  Order Received
                </p>
                <p class="text-xs text-slate-500 dark:text-slate-400">
                  Just now
                </p>
              </div>
            </div>

            <div class="relative pl-8 pb-3">
              <div
                class="absolute left-0 w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center"
              >
                <div
                  class="w-3 h-3 rounded-full bg-slate-300 dark:bg-slate-500"
                ></div>
              </div>
              <div>
                <p
                  class="font-medium text-sm text-slate-600 dark:text-slate-400"
                >
                  Processing Order
                </p>
                <p class="text-xs text-slate-500 dark:text-slate-500">
                  Upcoming
                </p>
              </div>
            </div>

            <div class="relative pl-8">
              <div
                class="absolute left-0 w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center"
              >
                <div
                  class="w-3 h-3 rounded-full bg-slate-300 dark:bg-slate-500"
                ></div>
              </div>
              <div>
                <p
                  class="font-medium text-sm text-slate-600 dark:text-slate-400"
                >
                  Delivery
                </p>
                <p class="text-xs text-slate-500 dark:text-slate-500">
                  Upcoming
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer Action Buttons -->
        <div
          class="bg-slate-50 dark:bg-slate-700/30 px-6 py-5 flex flex-col sm:flex-row gap-3 justify-center"
        >
          <button
            to="/shop"
            class="order-2 sm:order-1 py-2.5 px-4 rounded-lg border border-slate-200 dark:border-slate-600 text-slate-700 dark:text-slate-300 font-medium hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors duration-200 flex items-center justify-center"
          >
            Continue Shopping
            <UIcon name="i-heroicons-arrow-right" class="ml-2 w-4 h-4" />
          </button>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
// Add these variables to your script setup section
const userBalance = ref(5000); // Account balance (matches the displayed value in the UI)
const showInsufficientFundsError = ref(false);
const route = useRoute();
const router = useRouter();

// State management
const checkout = ref({
  name: "",
  phone: "",
  address: "",
  deliveryOption: "inside",
  paymentMethod: "cod",
});

const processing = ref(false);
const showSuccessModal = ref(false);
const orderId = ref("");

// Sample cart items - would be retrieved from store in real implementation
const cartItems = ref([
  {
    id: 1,
    name: "Premium Product",
    category: "Electronics",
    price: 2999,
    oldPrice: 3499,
    quantity: 1,
    image: "/img/product-1.jpg",
  },
]);

// If URL has product ID, add it to cart
onMounted(() => {
  const productId = route.query.productId;
  const quantity = parseInt(route.query.quantity) || 1;

  if (productId) {
    // In a real app, you would fetch the product details here
    // For now, we'll just use placeholder data if not already in cart
    if (!cartItems.value.some((item) => item.id === parseInt(productId))) {
      cartItems.value.push({
        id: parseInt(productId),
        name: route.query.name || "Product Item",
        category: route.query.category || "General",
        price: parseInt(route.query.price) || 1999,
        oldPrice: parseInt(route.query.oldPrice) || 0,
        quantity: quantity,
        image: route.query.image || "/img/placeholder.jpg",
      });
    }
  }
});

// Computed properties
const subTotal = computed(() => {
  return cartItems.value.reduce(
    (total, item) => total + item.price * item.quantity,
    0
  );
});

const hasFreeShipping = computed(() => {
  // Check if any products have free shipping option
  return (
    cartItems.value.some((item) => item.freeShipping) || subTotal.value > 5000
  );
});

const deliveryCharge = computed(() => {
  if (checkout.value.deliveryOption === "free" || subTotal.value > 5000)
    return 0;
  return checkout.value.deliveryOption === "inside" ? 100 : 150;
});

const discount = computed(() => {
  // Calculate any discounts - example logic
  return 0;
});

const total = computed(() => {
  return subTotal.value + deliveryCharge.value - discount.value;
});

// Update the isFormValid computed property
const isFormValid = computed(() => {
  const hasValidInfo =
    checkout.value.name && checkout.value.phone && checkout.value.address;
  const hasValidPayment =
    checkout.value.paymentMethod !== "account" ||
    userBalance.value >= total.value;

  // Show error when account payment is selected but balance is insufficient
  showInsufficientFundsError.value =
    checkout.value.paymentMethod === "account" &&
    userBalance.value < total.value;

  return hasValidInfo && hasValidPayment;
});
// Methods
function formatPrice(price) {
  return price.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function increaseQuantity(index) {
  if (cartItems.value[index].quantity < 10) {
    cartItems.value[index].quantity++;
  }
}

function decreaseQuantity(index) {
  if (cartItems.value[index].quantity > 1) {
    cartItems.value[index].quantity--;
  }
}

function removeItem(index) {
  cartItems.value.splice(index, 1);
  if (cartItems.value.length === 0) {
    // Redirect to products page if cart becomes empty
    router.push("/products");
  }
}

try {
  // In a real app, you would send order data to your API here
  await new Promise((resolve) => setTimeout(resolve, 1500)); // Simulating API call

  // If using account funds, deduct the amount
  if (checkout.value.paymentMethod === "account") {
    userBalance.value -= total.value;
  }

  // Generate a sample order ID
  orderId.value = "BD" + Math.floor(100000 + Math.random() * 900000);

  // Show success modal
  showSuccessModal.value = true;

  // Clear cart
  // In a real app, you would clear the cart in your store
} catch (error) {
  // Handle error
  console.error("Order placement failed:", error);
  alert("There was an error processing your order. Please try again.");
} finally {
  processing.value = false;
}
// Fix and update the placeOrder function
async function placeOrder() {
  if (!isFormValid.value) {
    // Handle insufficient funds error with visual feedback
    if (showInsufficientFundsError.value) {
      // Find the payment section and apply animation
      const paymentSection = document.querySelector(".payment-section");
      if (paymentSection) {
        paymentSection.classList.add("error-shake");
        setTimeout(() => {
          paymentSection.classList.remove("error-shake");
        }, 600);

        // Scroll to the payment section
        paymentSection.scrollIntoView({ behavior: "smooth", block: "center" });

        // Flash the balance badge for attention
        const badge = document.querySelector(".balance-badge");
        if (badge) {
          badge.classList.add("flash-attention");
          setTimeout(() => {
            badge.classList.remove("flash-attention");
          }, 1000);
        }
      }
    }
    return;
  }

  processing.value = true;

  try {
    // In a real app, you would send order data to your API here
    await new Promise((resolve) => setTimeout(resolve, 1500)); // Simulating API call

    // If using account funds, deduct the amount
    if (checkout.value.paymentMethod === "account") {
      userBalance.value -= total.value;
    }

    // Generate a sample order ID
    orderId.value = "BD" + Math.floor(100000 + Math.random() * 900000);

    // Show success modal
    showSuccessModal.value = true;

    // Clear cart (In a real app, you would clear the cart in your store)
    // cartItems.value = [];
  } catch (error) {
    // Handle error
    console.error("Order placement failed:", error);
    alert("There was an error processing your order. Please try again.");
  } finally {
    processing.value = false;
  }
}

// Make sure the navigateToProducts function is correctly implemented
function navigateToProducts() {
  showSuccessModal.value = false;
  router.push("/products");
}
</script>

<style scoped>
.sticky {
  position: sticky;
  top: 2rem;
}

/* Add hover transition to sections */
.hover\:shadow-md,
.hover\:shadow-lg {
  will-change: box-shadow;
}

/* Pulse animation for success icon */
@keyframes success-pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.4);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(34, 197, 94, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(34, 197, 94, 0);
  }
}

.success-pulse {
  animation: success-pulse 2s infinite;
}

/* Button hover effect */
.checkout-btn-hover {
  position: absolute;
  width: 0;
  height: 0;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  transform: translate(-50%, -50%);
  transition: width 0.5s, height 0.5s;
}

/* Scale effect for cards */
.hover\:shadow-md,
.hover\:shadow-lg {
  transition: all 0.3s ease;
}

.hover\:shadow-md:hover,
.hover\:shadow-lg:hover {
  transform: translateY(-2px);
}
/* Confetti animation */
.confetti-particle {
  position: absolute;
  width: 6px;
  height: 6px;
  opacity: 0;
  animation: confetti-fall 3s ease-in-out infinite;
}

@keyframes confetti-fall {
  0% {
    transform: translateY(0) rotate(0deg);
    opacity: 0;
  }
  10% {
    opacity: 1;
  }
  100% {
    transform: translateY(100px) rotate(720deg);
    opacity: 0;
  }
}

/* Checkmark animation */
.success-checkmark {
  width: 80px;
  height: 80px;
  margin: 0 auto;
  position: relative;
  transform: scale(0.7);
}

.success-checkmark .check-icon {
  width: 80px;
  height: 80px;
  position: relative;
  border-radius: 50%;
  box-sizing: content-box;
  border: 4px solid #4caf50;
}

.success-checkmark .check-icon::before {
  top: 3px;
  left: -2px;
  width: 30px;
  transform-origin: 100% 50%;
  border-radius: 100px 0 0 100px;
}

.success-checkmark .check-icon::after {
  top: 0;
  left: 30px;
  width: 60px;
  transform-origin: 0 50%;
  border-radius: 0 100px 100px 0;
}

.success-checkmark .check-icon::before,
.success-checkmark .check-icon::after {
  content: "";
  height: 100px;
  position: absolute;
  background: #ffffff;
  transform: rotate(-45deg);
}

.success-checkmark .check-icon .icon-line {
  height: 5px;
  background-color: #4caf50;
  display: block;
  border-radius: 2px;
  position: absolute;
  z-index: 10;
}

.success-checkmark .check-icon .icon-line.line-tip {
  top: 46px;
  left: 14px;
  width: 25px;
  transform: rotate(45deg);
  animation: icon-line-tip 0.75s;
}

.success-checkmark .check-icon .icon-line.line-long {
  top: 38px;
  right: 8px;
  width: 47px;
  transform: rotate(-45deg);
  animation: icon-line-long 0.75s;
}

.success-checkmark .check-icon .icon-circle {
  top: -4px;
  left: -4px;
  z-index: 10;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  position: absolute;
  box-sizing: content-box;
  border: 4px solid rgba(76, 175, 80, 0.5);
}

.success-checkmark .check-icon .icon-fix {
  top: 8px;
  width: 5px;
  left: 26px;
  z-index: 1;
  height: 85px;
  position: absolute;
  transform: rotate(-45deg);
  background-color: #ffffff;
}

@keyframes icon-line-tip {
  0% {
    width: 0;
    left: 1px;
    top: 19px;
  }
  54% {
    width: 0;
    left: 1px;
    top: 19px;
  }
  70% {
    width: 50px;
    left: -8px;
    top: 37px;
  }
  84% {
    width: 17px;
    left: 21px;
    top: 48px;
  }
  100% {
    width: 25px;
    left: 14px;
    top: 45px;
  }
}

@keyframes icon-line-long {
  0% {
    width: 0;
    right: 46px;
    top: 54px;
  }
  65% {
    width: 0;
    right: 46px;
    top: 54px;
  }
  84% {
    width: 55px;
    right: 0px;
    top: 35px;
  }
  100% {
    width: 47px;
    right: 8px;
    top: 38px;
  }
}

/* Pulse animation for active status */
.pulse-circle {
  animation: pulse-animation 2s infinite;
}

@keyframes pulse-animation {
  0% {
    box-shadow: 0 0 0 0 rgba(var(--color-primary), 0.7);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(var(--color-primary), 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(var(--color-primary), 0);
  }
}

/* Modal container transitions */
.modal-container {
  animation: modal-appear 0.3s ease-out forwards;
}

@keyframes modal-appear {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

/* Add these new styles for the enhanced insufficient funds warning */
.warning-slide-in {
  animation: slide-in 0.3s ease-out forwards;
  transform-origin: top;
}

@keyframes slide-in {
  from {
    opacity: 0;
    transform: translateY(-10px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.error-shake {
  animation: shake 0.5s cubic-bezier(0.36, 0.07, 0.19, 0.97) both;
  border-color: theme("colors.red.400") !important;
  box-shadow: 0 0 0 1px theme("colors.red.400/30") !important;
}

@keyframes shake {
  0%,
  100% {
    transform: translateX(0);
  }
  10%,
  30%,
  50%,
  70%,
  90% {
    transform: translateX(-5px);
  }
  20%,
  40%,
  60%,
  80% {
    transform: translateX(5px);
  }
}

.flash-attention {
  animation: flash 0.5s ease alternate 2;
}

@keyframes flash {
  from {
    background-color: theme("colors.red.200");
    color: theme("colors.red.900");
  }
  to {
    background-color: theme("colors.red.500");
    color: theme("colors.white");
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse-subtle {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

/* Fix for the "Continue Shopping" button in the success modal */
.bg-slate-50 button {
  cursor: pointer;
}
</style>
