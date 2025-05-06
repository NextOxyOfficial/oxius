<template>
  <div
    class="flex items-center gap-2.5 mt-4 pt-3 border-t border-gray-100/60 dark:border-slate-700/40 px-2"
  >
    <!-- User avatar with enhanced styling -->
    <div class="relative group">
      <img
        :src="user?.user?.image"
        alt="Your avatar"
        class="size-9 rounded-full object-cover border-2 border-white dark:border-slate-700 shadow-sm group-hover:shadow-md transition-all duration-300"
      />
      <!-- Subtle glow effect on hover -->
      <div
        class="absolute inset-0 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-blue-500/10 blur-md -z-10"
      ></div>
    </div>

    <!-- Comment input with glassmorphism -->
    <div class="flex-1 relative flex items-center gap-2">
      <div class="relative group flex-1">
        <textarea
          ref="commentTextarea"
          v-model="post.commentText"
          placeholder="Add a comment..."
          rows="1"
          class="w-full text-sm py-2.5 pr-[60px] pl-4 bg-gray-50/80 dark:bg-slate-800/70 border border-gray-200/70 dark:border-slate-700/50 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-400/40 shadow-sm hover:shadow-sm focus:shadow-md transition-all duration-300 backdrop-blur-[2px] text-gray-700 dark:text-gray-200 placeholder-gray-500 dark:placeholder-gray-400 resize-none overflow-y-auto leading-5 max-h-[6.5rem] no-scrollbar"
          @input="
            autoResize();
            $emit('handle-comment-input', $event, post);
          "
          @focus="post.showCommentInput = true"
          @keydown="$emit('handle-mention-keydown', $event, post)"
        ></textarea>

        <!-- Subtle gradient line under input on focus -->
        <div
          class="absolute bottom-0 left-4 right-4 h-0.5 bg-gradient-to-r from-blue-500/0 via-blue-500/50 to-blue-500/0 transform scale-x-0 group-focus-within:scale-x-100 transition-transform duration-300"
        ></div>
        
        <!-- Action buttons with premium styling (inside input) -->
        <div
          v-if="post.commentText"
          class="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1"
        >
          <button
            class="p-1 rounded-full text-gray-400 hover:text-gray-500 dark:text-gray-500 dark:hover:text-gray-300 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all duration-300"
            @click="post.commentText = ''"
            aria-label="Clear comment"
          >
            <UIcon name="i-heroicons-x-mark" class="h-3.5 w-3.5" />
          </button>
          <button
            class="p-1 rounded-full bg-blue-500/90 hover:bg-blue-600 mb-1 text-white shadow-sm hover:shadow transform hover:scale-105 transition-all duration-300"
            @click="$emit('add-comment', post)"
            aria-label="Post comment"
          >
            <Send class="h-3.5 w-3.5" />
            <!-- Subtle glow effect -->
            <div
              class="absolute inset-0 rounded-full bg-blue-400/50 blur-md opacity-0 hover:opacity-60 transition-opacity duration-300 -z-10"
            ></div>
          </button>
        </div>
      </div>
      
      <!-- Gift button moved outside of input -->
      <div class="relative">
        <button
          ref="giftButtonRef"
          class="px-2 pt-2 rounded-full text-pink-500 hover:text-pink-600 dark:text-pink-400 dark:hover:text-pink-300 bg-pink-50/80 dark:bg-pink-900/20 hover:bg-pink-100/80 dark:hover:bg-pink-900/30 transition-all duration-300 shadow-sm hover:shadow"
          aria-label="Send Gift"
          @click="toggleDiamondDropup"
        >
          <UIcon name="i-streamline-gift-2" class="size-5" />
          <span v-if="showDiamondDropup" class="sr-only">Close diamond purchase</span>
        </button>
        
        <!-- Diamond Purchase Dropup -->
        <div 
          v-if="showDiamondDropup"
          ref="dropupRef"
          class="absolute right-0 bottom-full mb-2 w-80 bg-white/95 dark:bg-slate-800/95 backdrop-blur-lg rounded-xl shadow-2xl border border-pink-100/60 dark:border-pink-900/30 z-30 animate-fade-in-up diamond-dropup overflow-hidden"
        >
          <!-- Main gift interface -->
          <div v-if="!showBuyDiamonds" class="pt-2 pb-3">
            <!-- Header with diamond icon and balance -->
            <div class="px-4 py-2 flex items-center justify-between border-b border-pink-100/50 dark:border-slate-700/50">
              <div class="flex items-center">
                <div class="p-1.5 bg-gradient-to-br from-pink-500/20 to-purple-500/20 rounded-lg mr-2">
                  <UIcon name="i-heroicons-gift" class="h-5 w-5 text-pink-500" />
                </div>
                <h3 class="text-base font-semibold text-gray-800 dark:text-gray-200">
                  Send Gift to {{ post?.author_details?.name || post?.author?.name || 'User' }}
                </h3>
              </div>
              <button 
                @click="closeDiamondDropup" 
                class="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-500"
              >
                <UIcon name="i-heroicons-x-mark" class="h-4 w-4" />
              </button>
            </div>
            
            <!-- Available Balance Card with Animated Background -->
            <div class="relative px-4 py-4 mt-3 mb-4 mx-4 rounded-xl overflow-hidden diamond-balance-card">
              <!-- Animated shimmer background -->
              <div class="absolute inset-0 bg-gradient-to-r from-pink-50/80 via-purple-50/80 to-pink-50/80 dark:from-pink-900/10 dark:via-purple-900/15 dark:to-pink-900/10 shimmer-background"></div>
              
              <!-- Diamond icon decoration -->
              <div class="absolute -right-4 -top-4 opacity-10">
                <UIcon name="i-heroicons-gem" class="h-20 w-20 text-pink-500" />
              </div>
              
              <!-- Centered diamonds display -->
              <div class="relative flex flex-col items-center justify-center">
                <div class="flex items-center justify-center mb-1">
                  <span class="text-sm text-gray-700 dark:text-gray-300 font-medium">Available Diamonds</span>
                </div>
                <div class="flex items-center justify-center">
                  <span class="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-pink-600 to-purple-600 dark:from-pink-400 dark:to-purple-400">{{ user.user.diamond_balance }}</span>
                  <UIcon name="i-heroicons-gem" class="h-5 w-5 text-pink-400 ml-1.5" />
                </div>
              </div>
              
              <!-- Buy button -->
              <button 
                @click.stop="showBuyDiamonds = true"
                class="absolute top-1.5 right-2 px-2.5 py-1 bg-gradient-to-r from-pink-500 to-purple-500 hover:from-pink-600 hover:to-purple-600 text-white text-xs font-medium rounded-full shadow-sm hover:shadow-md transition-all duration-200 flex items-center"
              >
                <UIcon name="i-heroicons-plus" class="h-3 w-3 mr-1" />
                Buy
              </button>
            </div>
            
            <!-- Use Available Balance Section -->
            <div class="px-4 mb-4">
              <div class="flex flex-col">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5 ml-1">
                  Send gift diamonds
                </label>
                <div class="relative">
                  <input 
                    type="number" 
                    v-model.number="sendFromBalance"
                    placeholder="Enter diamond amount"
                    :max="availableDiamonds"
                    min="1"
                    class="w-full px-3.5 py-2.5 border border-gray-200 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500/50 dark:focus:ring-pink-400/40 text-gray-700 dark:text-gray-200 bg-white/80 dark:bg-slate-800/80"
                  />
                  <div class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center">
                    <UIcon name="i-heroicons-sparkles" class="h-4 w-4 text-pink-400 mr-1" />
                  </div>
                </div>
                
                <!-- Gift message input -->
                <div class="mt-3">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5 ml-1">
                    Gift message
                  </label>
                  <div class="relative">
                    <textarea 
                      v-model="giftMessage"
                      placeholder="Add a gift message... (optional)"
                      rows="2"
                      class="w-full px-3.5 py-2.5 border border-gray-200 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500/50 dark:focus:ring-pink-400/40 text-gray-700 dark:text-gray-200 bg-white/80 dark:bg-slate-800/80 resize-none"
                    ></textarea>
                  </div>
                </div>
              </div>
              
              <div class="mt-4 space-y-3">
                <!-- Send Gift Button -->
                <button 
                  @click="sendGift"
                  :disabled="isSendingGift"
                  class="w-full py-2.5 px-4 bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white font-medium rounded-lg shadow-sm hover:shadow flex items-center justify-center transition-all duration-300 transform hover:translate-y-[-1px]"
                >
                  <template v-if="isSendingGift">
                    <div class="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                    Sending...
                  </template>
                  <template v-else>
                    <UIcon name="i-heroicons-gift-top" class="h-4 w-4 mr-1.5" />
                    Send Gift
                  </template>
                </button>
                
                <!-- No Balance Message -->
                <div v-if="availableDiamonds === 0" class="flex items-center justify-center gap-1.5 text-center text-sm text-gray-500 dark:text-gray-400 py-1.5">
                  <UIcon name="i-heroicons-exclamation-circle" class="h-4 w-4 text-pink-400" />
                  <span>You need diamonds to send a gift</span>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Buy diamonds interface -->
          <div v-else class="pt-2 pb-3">
            <!-- Header with diamond icon -->
            <div class="px-4 py-2 flex items-center justify-between border-b border-pink-100/50 dark:border-slate-700/50 mb-2">
              <div class="flex items-center">
                <div class="p-1.5 bg-gradient-to-br from-pink-500/20 to-purple-500/20 rounded-lg mr-2">
                  <UIcon name="i-heroicons-shopping-bag" class="h-5 w-5 text-pink-500" />
                </div>
                <h3 class="text-base font-semibold text-gray-800 dark:text-gray-200">
                  Buy Diamonds
                </h3>
              </div>
              <button 
                @click.stop="showBuyDiamonds = false" 
                class="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-500"
              >
                <UIcon name="i-heroicons-arrow-left" class="h-4 w-4" />
              </button>
            </div>
            
            <!-- Diamond package options with improved design -->
            <div class="px-4 pt-1">
              <!-- Available Balance Display -->
              <div class="flex items-center justify-between mb-3 pb-3 border-b border-pink-100/50 dark:border-slate-700/50">
                <div class="flex items-center">
                  <UIcon name="i-heroicons-wallet" class="h-4 w-4 text-pink-500 mr-1.5" />
                  <span class="text-sm text-gray-700 dark:text-gray-300">Account Funds:</span>
                </div>
                <div class="flex items-center">
                  <span class="text-md font-bold text-gray-800 dark:text-gray-200">{{ user.user.balance }}</span>
                  <span class="text-md font-bold text-gray-700 dark:text-gray-300 ml-1">৳</span>
                  <button 
                    @click="navigateToFunds"
                    class="ml-2 px-2 py-0.5 text-xs font-medium text-white bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 rounded-full shadow-sm hover:shadow transition-all duration-200"
                  >
                    Add Funds
                  </button>
                </div>
              </div>
              
              <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
                Purchase diamond packages (10 diamonds = 1 BDT)
              </p>
              
              <!-- Diamond packages -->
              <div class="grid grid-cols-2 gap-3 mb-5">
                <button 
                  v-for="(pkg, index) in diamondPackages" 
                  :key="index"
                  @click="selectDiamondPackage(pkg.amount)"
                  :class="[
                    'relative flex flex-col items-center justify-center p-3 rounded-lg border transition-all duration-200',
                    selectedPackage === pkg.amount 
                      ? 'border-pink-500 bg-gradient-to-br from-pink-50/70 to-purple-50/70 dark:from-pink-900/20 dark:to-purple-900/20 shadow-md' 
                      : 'border-gray-200 dark:border-slate-700 hover:border-pink-300 dark:hover:border-pink-800 hover:bg-pink-50/30 dark:hover:bg-pink-900/5'
                  ]"
                >
                  <div class="flex items-center">
                    <span class="text-pink-500 font-bold text-xl">
                      {{ pkg.amount }}
                    </span>
                    <UIcon name="i-heroicons-sparkles" class="h-4 w-4 ml-1 text-pink-400" />
                  </div>
                  <span class="text-xs text-gray-600 dark:text-gray-300 mt-1">{{ pkg.price }} BDT</span>
                  
                  <!-- Selection indicator -->
                  <div v-if="selectedPackage === pkg.amount" class="absolute -top-1.5 -right-1.5 h-5 w-5 bg-gradient-to-br from-pink-500 to-purple-500 rounded-full flex items-center justify-center shadow-sm">
                    <UIcon name="i-heroicons-check" class="h-3 w-3 text-white" />
                  </div>
                </button>
              </div>
              
              <!-- Custom amount input -->
              <div class="mb-5">
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5 ml-1">
                  Custom Amount
                </label>
                <div class="relative">
                  <input 
                    type="number" 
                    v-model="customDiamondAmount"
                    placeholder="Enter diamond amount"
                    min="10"
                    class="w-full px-3.5 py-2.5 border border-gray-200 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500/50 dark:focus:ring-pink-400/40 text-gray-700 dark:text-gray-200 bg-white/80 dark:bg-slate-800/80"
                    @input="onCustomAmountInput"
                  />
                  <div class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center">
                    <UIcon name="i-heroicons-sparkles" class="h-4 w-4 text-pink-400 mr-1" />
                  </div>
                </div>
                <div class="flex items-center justify-between mt-1.5">
                  <p class="text-xs text-gray-500">Minimum 10 diamonds</p>
                  <p class="text-xs text-gray-500">
                    ≈ {{ calculatePrice(customDiamondAmount || 0) }} BDT
                  </p>
                </div>
              </div>
              
              <!-- Purchase button -->
              <button 
                @click="purchaseDiamonds"
                class="w-full py-2.5 px-4 bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white font-medium rounded-lg shadow-sm hover:shadow flex items-center justify-center transition-all duration-300 transform hover:translate-y-[-1px]"
                :disabled="!canPurchase"
                :class="{ 'opacity-60 cursor-not-allowed': !canPurchase }"
              >
                <UIcon name="i-heroicons-shopping-cart" class="h-4 w-4 mr-1.5" />
                Purchase Diamonds
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Mention suggestions dropdown with enhanced glassmorphism -->
      <div
        v-if="
          showMentions &&
          mentionSuggestions.length > 0 &&
          post === mentionInputPosition?.post
        "
        class="absolute left-0 bottom-full mb-2 w-64 bg-white/90 dark:bg-slate-800/90 backdrop-blur-md rounded-lg shadow-xl border border-gray-100/50 dark:border-slate-700/50 z-20 max-h-56 overflow-y-auto animate-fade-in-up premium-shadow"
      >
        <div class="pt-1 pb-1">
          <!-- Header with subtle styling -->
          <div
            class="px-3 py-1.5 text-xs font-medium text-gray-500 dark:text-gray-400 border-b border-gray-100/80 dark:border-slate-700/80"
          >
            Mention someone
          </div>

          <div class="py-1">
            <div
              v-for="(user, index) in mentionSuggestions"
              :key="user.id"
              @click="$emit('select-mention', user, post)"
              :class="[
                'flex items-center px-3 py-2 cursor-pointer transition-colors duration-200',
                index === activeMentionIndex
                  ? 'bg-blue-50/80 dark:bg-blue-900/30'
                  : 'hover:bg-gray-50/80 dark:hover:bg-slate-700/80',
              ]"
            >
              <!-- User avatar in mentions -->
              <div class="relative">
                <img
                  :src="user?.follower_details?.image"
                  :alt="user?.follower_details?.name"
                  class="w-8 h-8 rounded-full mr-2.5 border border-gray-200/70 dark:border-slate-700/70 object-cover"
                />
                <!-- Verified badge if applicable -->
                <div
                  v-if="user?.follower_details?.kyc"
                  class="absolute -bottom-0.5 -right-0.5 bg-blue-500 rounded-full w-3 h-3 border border-white dark:border-slate-800 flex items-center justify-center"
                >
                  <UIcon name="i-heroicons-check" class="w-2 h-2 text-white" />
                </div>
              </div>

              <!-- User name with subtle styling -->
              <div class="flex flex-col">
                <span
                  class="text-sm font-medium text-gray-800 dark:text-gray-200"
                >
                  {{ user?.follower_details?.name }}
                </span>
                <span
                  class="text-xs text-gray-500 dark:text-gray-400"
                  v-if="user?.follower_details?.profession"
                >
                  {{ user?.follower_details?.profession }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Success notification popup -->
  <Teleport to="body">
    <Transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div 
        v-if="showSuccessPopup" 
        class="fixed top-1/4 left-1/2 transform -translate-x-1/2 z-[9999] sm:max-w-md max-w-[85%] w-full"
      >
        <div class="animate-pop-in bg-white/95 dark:bg-slate-800/95 py-4 px-6 rounded-xl shadow-xl border border-pink-200 dark:border-pink-900/30 text-center">
          <div class="flex flex-col items-center">
            <div class="w-14 h-14 rounded-full bg-gradient-to-br from-pink-400 to-purple-500 flex items-center justify-center mb-3 shadow-lg">
              <UIcon name="i-heroicons-gift-top" class="h-7 w-7 text-white" />
            </div>
            <h3 class="text-xl font-bold text-gray-800 dark:text-white mb-1">Gift Sent Successfully!</h3>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              You sent {{ lastGiftAmount }} diamonds to {{ post?.author_details?.name || post?.author?.name || 'User' }}
            </p>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from "vue";
import { Send } from "lucide-vue-next";
import { useUserStore } from '~/store/user';
import { useApi } from '~/composables/useApi'; // Import the API utility

const props = defineProps({
  post: {
    type: Object,
    required: true,
  },
  user: {
    type: Object,
    required: true,
  },
  showMentions: {
    type: Boolean,
    default: false,
  },
  mentionSuggestions: {
    type: Array,
    default: () => [],
  },
  activeMentionIndex: {
    type: Number,
    default: 0,
  },
  mentionInputPosition: {
    type: Object,
    default: null,
  },
});

// Get user store to access balance
const userStore = useUserStore();

// Diamond dropup state
const showDiamondDropup = ref(false);
const showBuyDiamonds = ref(false);
const selectedPackage = ref(null);
const customDiamondAmount = ref(null);
const dropupRef = ref(null);
const giftButtonRef = ref(null);

// Gift sending states
const sendFromBalance = ref(null);
const giftMessage = ref(''); // Gift message input
const isSendingGift = ref(false);
const showSuccessPopup = ref(false);
const lastGiftAmount = ref(0);

// Account balance in BDT
const accountBalance = computed(() => {
  return userStore.user?.balance || 0;
});

// Available diamonds - this will be different from account funds
const availableDiamonds = computed(() => {
  // Check userStore first, then fallback to props.user
  if (userStore.user && typeof userStore.user.diamond_balance !== 'undefined') {
    return userStore.user.diamond_balance || 0;
  }
  // Fallback to the props if userStore is not yet loaded
  return props.user?.user?.diamond_balance || 0;
});

// Diamond packages (10 diamonds = 1 BDT)
const diamondPackages = [
  { amount: 50, price: 5 },
  { amount: 100, price: 10 },
  { amount: 250, price: 25 },
  { amount: 500, price: 50 },
];

// Calculate if purchase is possible
const canPurchase = computed(() => {
  return selectedPackage.value || (customDiamondAmount.value && customDiamondAmount.value >= 10);
});

// Calculate if sending gift is possible
const canSendGift = computed(() => {
  return sendFromBalance.value && 
         sendFromBalance.value > 0 && 
         sendFromBalance.value <= availableDiamonds.value; // Check against diamond balance, not user money balance
});

// Calculate price based on diamonds
const calculatePrice = (diamonds) => {
  return parseFloat((diamonds / 10).toFixed(2));
};

// Toggle diamond dropup
const toggleDiamondDropup = (e) => {
  e.stopPropagation(); // Prevent event bubbling
  showDiamondDropup.value = !showDiamondDropup.value;
  
  // Reset all selections when opening the dropdown
  if (showDiamondDropup.value) {
    selectedPackage.value = null;
    customDiamondAmount.value = null;
    sendFromBalance.value = null;
    giftMessage.value = ''; // Reset gift message
    showBuyDiamonds.value = false;
    
    // Refresh user data to get latest balance
    userStore.fetchUserData();
  }
};

// Handle clicks outside to close dropdown
const handleClickOutside = (event) => {
  if (
    showDiamondDropup.value && 
    dropupRef.value && 
    !dropupRef.value.contains(event.target) && 
    giftButtonRef.value && 
    !giftButtonRef.value.contains(event.target)
  ) {
    showDiamondDropup.value = false;
  }
};

// Setup event listeners for click outside detection
onMounted(() => {
  document.addEventListener('click', handleClickOutside);
  // Ensure we have the latest user data
  if (!userStore.user) {
    userStore.initializeFromStorage();
  }
});

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside);
});

// Close diamond dropup
const closeDiamondDropup = () => {
  showDiamondDropup.value = false;
};

// Select a diamond package
const selectDiamondPackage = (amount) => {
  if (amount === null || amount === undefined) {
    selectedPackage.value = null;
    return;
  }

  // Check if we're already selecting this package, then toggle it off
  if (selectedPackage.value === amount) {
    selectedPackage.value = null;
  } else {
    // Otherwise select the new package
    selectedPackage.value = amount;
    // And clear other inputs
    customDiamondAmount.value = null;
    sendFromBalance.value = null;
  }
};

// Handle custom amount input with safer null checking
const onCustomAmountInput = () => {
  if (customDiamondAmount.value) {
    selectedPackage.value = null;
    sendFromBalance.value = null;
  }
};

// Send gift from available balance
const sendGift = async () => {
  const { post } = useApi(); // Initialize API utility
  
  console.log("Send Gift button clicked");
  
  try {
    // Make sure we have a valid gift amount to send
    const giftAmount = parseInt(sendFromBalance.value);
    
    // Simple validation - check if we have something to send
    if (!giftAmount || isNaN(giftAmount) || giftAmount <= 0) {
      if (window.$nuxt && window.$nuxt.$toast) {
        window.$nuxt.$toast.error("Please enter a valid diamond amount");
      } else {
        alert("Please enter a valid diamond amount");
      }
      return;
    }
    
    // Check if user has enough diamonds
    if (giftAmount > availableDiamonds.value) {
      if (window.$nuxt && window.$nuxt.$toast) {
        window.$nuxt.$toast.error(`You only have ${availableDiamonds.value} diamonds available`);
      } else {
        alert(`You only have ${availableDiamonds.value} diamonds available`);
      }
      return;
    }
    
    // Set loading state
    isSendingGift.value = true;
    
    // Prepare the payload
    const payload = {
      amount: giftAmount,
      recipientId: props.post.author?.id || props.post.author_details?.id,
      postId: props.post.id,
      message: giftMessage.value || `Sent ${giftAmount} diamonds as a gift! ✨`
    };
    
    console.log("Sending gift with payload:", payload);
    
    // Call the API endpoint
    const response = await post('/diamonds/send-gift/', payload);
    
    console.log("Gift sent successfully:", response);
    
    // Update the user's diamond balance locally
    if (userStore.user) {
      userStore.user.diamond_balance -= giftAmount;
    }
    
    // Close the dialog
    closeDiamondDropup();
    
    // Store the gift amount for the success popup
    lastGiftAmount.value = giftAmount;
    
    // Show success popup
    showSuccessPopup.value = true;
    
    // Auto-hide popup after 3 seconds
    setTimeout(() => {
      showSuccessPopup.value = false;
    }, 3000);
    
    // Refresh user data to get updated balances
    await userStore.fetchUserData();
    
  } catch (error) {
    console.error("Error sending gift:", error);
    
    // Show error message
    let errorMsg = 'Failed to send gift';
    
    if (error.response?.data?.error) {
      errorMsg = error.response.data.error;
    }
    
    if (window.$nuxt && window.$nuxt.$toast) {
      window.$nuxt.$toast.error(errorMsg);
    } else {
      alert(errorMsg);
    }
  } finally {
    // Reset loading state
    isSendingGift.value = false;
  }
};

// Purchase diamonds
const purchaseDiamonds = async () => {
  const { post } = useApi(); // Initialize the API utility
  const diamondAmount = selectedPackage.value || customDiamondAmount.value;
  if (!diamondAmount) return;
  
  // Calculate cost in BDT (10 diamonds = 1 BDT)
  const costInBDT = calculatePrice(diamondAmount);
  
  // Check if user has sufficient balance
  if (accountBalance.value < costInBDT) {
    if (window.$nuxt && window.$nuxt.$toast) {
      window.$nuxt.$toast.error(`Insufficient balance. Please add funds.`);
    } else {
      alert(`Insufficient balance. Please add funds.`);
    }
    return;
  }

  try {
    // Call API to purchase diamonds directly from balance
    const response = await post('/diamonds/purchase/', {
      amount: parseInt(diamondAmount), // Convert to integer to match backend expectation
      cost: costInBDT // Send as number, not string
    });
    
    // Update UI immediately for better user experience
    if (userStore.user) {
      // Deduct the cost from the balance
      userStore.user.balance -= costInBDT;
      // Add diamonds to the diamond balance
      userStore.user.diamond_balance = (userStore.user.diamond_balance || 0) + parseInt(diamondAmount);
    }
    
    // Show success message with animation
    if (window.$nuxt && window.$nuxt.$toast) {
      window.$nuxt.$toast.success(`Successfully purchased ${diamondAmount} diamonds!`);
    } else {
      alert(`Successfully purchased ${diamondAmount} diamonds!`);
    }
    
    // Reset the form and return to gift view
    showBuyDiamonds.value = false;
    selectedPackage.value = null;
    customDiamondAmount.value = null;
    
    // Refresh user data to ensure consistency with server
    await userStore.fetchUserData();
  } catch (error) {
    console.error('Error purchasing diamonds:', error);
    if (window.$nuxt && window.$nuxt.$toast) {
      window.$nuxt.$toast.error(error.response?.data?.error || 'Failed to purchase diamonds. Please try again.');
    } else {
      alert(error.response?.data?.error || 'Failed to purchase diamonds. Please try again.');
    }
  }
};

// Handle deposit button click - redirect to deposit page
const goToDeposit = () => {
  // Close the dropdown and navigate to the deposit page
  showDiamondDropup.value = false;
  navigateTo('/account/deposit');
};

function autoResize() {
  const textarea = document.querySelector('textarea[placeholder="Add a comment..."]');
  if (textarea) {
    textarea.style.height = "auto";
    textarea.style.height = Math.min(textarea.scrollHeight, 104) + "px"; // 3 lines ~ 104px
  }
}

// Navigate to funds page
const navigateToFunds = () => {
  navigateTo('/deposit-withdraw');
};

defineEmits([
  "add-comment",
  "handle-comment-input",
  "handle-mention-keydown",
  "select-mention",
]);
</script>

<style scoped>
/* Premium shadow for dropdown */
.premium-shadow {
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08), 0 2px 8px rgba(0, 0, 0, 0.06),
    0 0 1px rgba(0, 0, 0, 0.08);
}

.dark .premium-shadow {
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2), 0 2px 8px rgba(0, 0, 0, 0.15),
    0 0 1px rgba(255, 255, 255, 0.05);
}

/* Diamond dropup special styling */
.diamond-dropup {
  box-shadow: 0 10px 40px rgba(255, 105, 180, 0.1), 0 4px 12px rgba(0, 0, 0, 0.08),
    0 0 2px rgba(255, 105, 180, 0.1);
  z-index: 40; /* Increase z-index to appear above other posts */
}

.dark .diamond-dropup {
  box-shadow: 0 10px 40px rgba(255, 105, 180, 0.15), 0 4px 12px rgba(0, 0, 0, 0.25),
    0 0 2px rgba(255, 255, 255, 0.05);
}

/* Animation for mention dropdown */
.animate-fade-in-up {
  animation: fadeInUp 0.2s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
/* Hide scrollbar for Chrome, Safari and Opera */
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
/* Hide scrollbar for IE, Edge and Firefox */
.no-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}

/* Diamond balance card styling */
.diamond-balance-card {
  position: relative;
  overflow: hidden;
}

.shimmer-background {
  background-size: 200% 100%;
  animation: shimmer 2.5s ease-in-out infinite;
}

@keyframes shimmer {
  0% {
    background-position: -100% 0;
  }
  50% {
    background-position: 100% 0;
  }
  100% {
    background-position: -100% 0;
  }
}
.gift-comment {
  background: linear-gradient(to right, #fff8f8, #fff0f8);
  border-radius: 10px;
  padding: 8px 12px;
  border-left: 3px solid #ff66cc;
  margin: 8px 0;
}
.gift-message {
  font-weight: 500;
  color: #ff3399;
}

/* Animation for success popup */
@keyframes popIn {
  0% {
    opacity: 0;
    transform: scale(0.8);
  }
  70% {
    transform: scale(1.05);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-pop-in {
  animation: popIn 0.3s ease-out forwards;
}
</style>
