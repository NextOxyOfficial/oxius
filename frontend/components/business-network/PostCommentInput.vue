<template>
  <div
    class="flex items-center gap-2.5 mt-4 pt-3 border-t border-gray-100/60 dark:border-slate-700/40 px-2"
  >
    <!-- User avatar with enhanced styling -->
    <div class="relative group">
      <img
        :src="user?.user?.image"
        alt="Your avatar"
        class="size-9 rounded-full object-cover border-2 border-white dark:border-slate-700 shadow-sm group-hover:shadow-sm transition-all duration-300"
      />
      <!-- Subtle glow effect on hover -->
      <div
        class="absolute inset-0 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-blue-500/10 blur-md -z-10"
      ></div>
    </div>    
    <!-- Comment input with glassmorphism and inline mention display -->
    <div class="flex-1 relative flex items-center gap-2">
      <div class="relative group flex-1">        
        <!-- Enhanced input container with mention chips inside -->
        <div class="relative min-h-[42px] w-full bg-gray-50/80 dark:bg-slate-800/70 border border-gray-200/70 dark:border-slate-700/50 rounded-md focus-within:ring-2 focus-within:ring-blue-500/50 dark:focus-within:ring-blue-400/40 shadow-sm hover:shadow-sm focus-within:shadow-sm transition-all duration-300 backdrop-blur-[2px]">
            <!-- Content wrapper with padding for chips and input -->
          <div class="flex flex-wrap items-center gap-1.5 p-2 pr-[60px] min-h-[38px]">
            <!-- Mentioned user chips -->
            <div
              v-for="(mention, index) in extractedMentions"
              :key="index"
              class="inline-flex items-center gap-1.5 px-2.5 py-1 bg-gradient-to-r from-blue-500/15 to-purple-500/15 dark:from-blue-600/25 dark:to-purple-600/25 border border-blue-200/60 dark:border-blue-700/40 rounded-full hover:from-blue-500/25 hover:to-purple-500/25 dark:hover:from-blue-600/35 dark:hover:to-purple-600/35 transition-all duration-300 cursor-pointer group/mention transform hover:scale-105 shadow-sm hover:shadow text-xs font-medium mention-chip-enter"
              @click="navigateToMentionedUser(mention)"
            >
              <!-- Mention indicator -->
              <div class="w-1.5 h-1.5 bg-blue-500 dark:bg-blue-400 rounded-full group-hover/mention:bg-purple-500 dark:group-hover/mention:bg-purple-400 transition-colors duration-300 flex-shrink-0"></div>
                <!-- User name -->
              <span class="text-blue-700 dark:text-blue-300 group-hover/mention:text-purple-700 dark:group-hover/mention:text-purple-300 transition-colors duration-300 font-medium whitespace-nowrap">
                {{ mention }}
              </span>
              
              <!-- Remove button -->
              <button
                @click.stop="removeMention(mention)"
                class="ml-0.5 p-0.5 rounded-full hover:bg-red-100 dark:hover:bg-red-900/40 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-all duration-200 flex-shrink-0"
                aria-label="Remove mention"
              >
                <UIcon name="i-heroicons-x-mark" class="h-2.5 w-2.5" />
              </button>
            </div>            
            <!-- Flexible input field -->
            <textarea
              ref="commentInputRef"
              v-model="displayCommentText"
              placeholder="Add a comment..."
              rows="1"
              class="flex-1 min-w-[120px] text-base bg-transparent border-none outline-none resize-none text-gray-800 dark:text-gray-300 placeholder-gray-500 dark:placeholder-gray-400 leading-5 max-h-[4rem] overflow-y-auto no-scrollbar comment-textarea"
              :style="{ minHeight: '24px' }"
              @input="handleCommentInput"
              @focus="post.showCommentInput = true"
              @keydown="handleMentionKeydown"
              @keyup="autoResize"
            ></textarea>
          </div>          
          <!-- Subtle gradient line under input on focus -->
          <div
            class="absolute bottom-0 left-4 right-4 h-0.5 bg-gradient-to-r from-blue-500/0 via-blue-500/50 to-blue-500/0 transform scale-x-0 focus-within:scale-x-100 transition-transform duration-300"
          ></div>

          <!-- Action buttons with premium styling (positioned over the input container) -->
          <div
            v-if="displayCommentText || extractedMentions.length > 0"
            class="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1 z-10"
          >
            <button
              class="p-1 rounded-full text-gray-600 hover:text-gray-600 dark:text-gray-600 dark:hover:text-gray-400 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all duration-300"
              @click="clearComment"
              aria-label="Clear comment"
            >
              <UIcon name="i-heroicons-x-mark" class="h-3.5 w-3.5" />
            </button>            <button
              class="p-1 rounded-full bg-blue-500/90 hover:bg-blue-600 mb-1 text-white shadow-sm hover:shadow transform hover:scale-105 transition-all duration-300"
              @click="handlePostComment"
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
      </div>

      <!-- Gift button moved outside of input -->
      <div class="relative" v-if="post.author_details.id !== user?.user?.id">
        <button
          ref="giftButtonRef"
          class="px-2 pt-2 rounded-full text-pink-500 hover:text-pink-600 dark:text-pink-400 dark:hover:text-pink-300 bg-pink-50/80 dark:bg-pink-900/20 hover:bg-pink-100/80 dark:hover:bg-pink-900/30 transition-all duration-300 shadow-sm hover:shadow"
          aria-label="Send Gift"
          @click="toggleDiamondDropup"
        >
          <UIcon name="i-streamline-gift-2" class="size-5" />
          <span v-if="showDiamondDropup" class="sr-only"
            >Close diamond purchase</span
          >
        </button>

        <!-- Diamond Purchase Dropup -->
        <div
          v-if="showDiamondDropup"
          ref="dropupRef"
          class="absolute right-0 bottom-full mb-2 w-80 bg-white/95 dark:bg-slate-800/95 backdrop-blur-lg rounded-xl shadow-sm border border-pink-100/60 dark:border-pink-900/30 z-30 animate-fade-in-up diamond-dropup overflow-hidden"
        >
          <!-- Main gift interface -->
          <div v-if="!showBuyDiamonds" class="pt-2 pb-3">
            <!-- Header with diamond icon and balance -->
            <div
              class="px-4 py-2 flex items-center justify-between border-b border-pink-100/50 dark:border-slate-700/50"
            >
              <div class="flex items-center">
                <div
                  class="p-1.5 bg-gradient-to-br from-pink-500/20 to-purple-500/20 rounded-lg mr-2"
                >
                  <UIcon
                    name="i-heroicons-gift"
                    class="h-5 w-5 text-pink-500"
                  />
                </div>
                <h3
                  class="text-base font-semibold text-gray-800 dark:text-gray-300"
                >
                  Send Gift to
                  {{
                    post?.author_details?.name || post?.author?.name || "User"
                  }}
                </h3>
              </div>
              <button
                @click="closeDiamondDropup"
                class="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600"
              >
                <UIcon name="i-heroicons-x-mark" class="h-4 w-4" />
              </button>
            </div>

            <!-- Available Balance Card with Animated Background -->
            <div
              class="relative px-4 py-4 mt-3 mb-4 mx-4 rounded-xl overflow-hidden diamond-balance-card"
            >
              <!-- Animated shimmer background -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-pink-50/80 via-purple-50/80 to-pink-50/80 dark:from-pink-900/10 dark:via-purple-900/15 dark:to-pink-900/10 shimmer-background"
              ></div>

              <!-- Diamond icon decoration -->
              <div class="absolute -right-4 -top-4 opacity-10">
                <UIcon name="i-heroicons-gem" class="h-20 w-20 text-pink-500" />
              </div>

              <!-- Centered diamonds display -->
              <div class="relative flex flex-col items-center justify-center">
                <div class="flex items-center justify-center mb-1">
                  <span
                    class="text-sm text-gray-800 dark:text-gray-400 font-medium"
                    >Available Diamonds</span
                  >
                </div>
                <div class="flex items-center justify-center">
                  <span
                    class="text-2xl font-semibold bg-clip-text text-transparent bg-gradient-to-r from-pink-600 to-purple-600 dark:from-pink-400 dark:to-purple-400"
                    >{{ user.user.diamond_balance }}</span
                  >
                  <UIcon
                    name="i-heroicons-gem"
                    class="h-5 w-5 text-pink-400 ml-1.5"
                  />
                </div>
              </div>

              <!-- Buy button -->
              <button
                @click.stop="showBuyDiamonds = true"
                class="absolute top-1.5 right-2 px-2.5 py-1 bg-gradient-to-r from-pink-500 to-purple-500 hover:from-pink-600 hover:to-purple-600 text-white text-xs font-medium rounded-full shadow-sm hover:shadow-sm transition-all duration-200 flex items-center"
              >
                <UIcon name="i-heroicons-plus" class="h-3 w-3 mr-1" />
                Buy
              </button>
            </div>

            <!-- Use Available Balance Section -->
            <div class="px-4 mb-4">
              <div class="flex flex-col">
                <label
                  class="block text-sm font-medium text-gray-800 dark:text-gray-400 mb-1.5 ml-1"
                >
                  Send gift diamonds
                </label>
                <div class="relative">
                  <input
                    type="number"
                    v-model.number="sendFromBalance"
                    placeholder="Enter diamond amount"
                    :max="availableDiamonds"
                    min="1"
                    class="w-full px-3.5 py-2.5 border border-gray-200 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500/50 dark:focus:ring-pink-400/40 text-gray-800 dark:text-gray-300 bg-white/80 dark:bg-slate-800/80"
                  />
                  <div
                    class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center"
                  >
                    <UIcon
                      name="i-heroicons-sparkles"
                      class="h-4 w-4 text-pink-400 mr-1"
                    />
                  </div>
                </div>

                <!-- Gift message input -->
                <div class="mt-3">
                  <label
                    class="block text-sm font-medium text-gray-800 dark:text-gray-400 mb-1.5 ml-1"
                  >
                    Gift message
                  </label>
                  <div class="relative">
                    <textarea
                      v-model="giftMessage"
                      placeholder="Add a gift message... (optional)"
                      rows="2"
                      class="w-full px-3.5 py-2.5 border border-gray-200 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500/50 dark:focus:ring-pink-400/40 text-gray-800 dark:text-gray-300 bg-white/80 dark:bg-slate-800/80 resize-none"
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
                    <div
                      class="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"
                    ></div>
                    Sending...
                  </template>
                  <template v-else>
                    <UIcon name="i-heroicons-gift-top" class="h-4 w-4 mr-1.5" />
                    Send Gift
                  </template>
                </button>

                <!-- No Balance Message -->
                <div
                  v-if="availableDiamonds === 0"
                  class="flex items-center justify-center gap-1.5 text-center text-sm text-gray-600 dark:text-gray-600 py-1.5"
                >
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="h-4 w-4 text-pink-400"
                  />
                  <span>You need diamonds to send a gift</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Buy diamonds interface -->
          <div v-else class="pt-2 pb-3">
            <!-- Header with diamond icon -->
            <div
              class="px-4 py-2 flex items-center justify-between border-b border-pink-100/50 dark:border-slate-700/50 mb-2"
            >
              <div class="flex items-center">
                <div
                  class="p-1.5 bg-gradient-to-br from-pink-500/20 to-purple-500/20 rounded-lg mr-2"
                >
                  <UIcon
                    name="i-heroicons-shopping-bag"
                    class="h-5 w-5 text-pink-500"
                  />
                </div>
                <h3
                  class="text-base font-semibold text-gray-800 dark:text-gray-300"
                >
                  Buy Diamonds
                </h3>
              </div>
              <button
                @click.stop="showBuyDiamonds = false"
                class="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600"
              >
                <UIcon name="i-heroicons-arrow-left" class="h-4 w-4" />
              </button>
            </div>

            <!-- Diamond package options with improved design -->
            <div class="px-4 pt-1">
              <!-- Available Balance Display -->
              <div
                class="flex items-center justify-between mb-3 pb-3 border-b border-pink-100/50 dark:border-slate-700/50"
              >
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-wallet"
                    class="h-4 w-4 text-pink-500 mr-1.5"
                  />
                  <span class="text-sm text-gray-800 dark:text-gray-400"
                    >Account Funds:</span
                  >
                </div>
                <div class="flex items-center">
                  <span
                    class="text-md font-semibold text-gray-800 dark:text-gray-300"
                    >{{ user.user.balance }}</span
                  >
                  <span
                    class="text-md font-semibold text-gray-800 dark:text-gray-400 ml-1"
                    >৳</span
                  >
                  <button
                    @click="navigateToFunds"
                    class="ml-2 px-2 py-0.5 text-xs font-medium text-white bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 rounded-full shadow-sm hover:shadow transition-all duration-200"
                  >
                    Add Funds
                  </button>
                </div>
              </div>

              <p class="text-xs text-gray-600 dark:text-gray-600 mb-3">
                Purchase diamond packages (10 diamonds = 1 BDT)
              </p>

              <!-- Diamond packages -->
              <div class="grid grid-cols-2 gap-3 mb-5">
                <button
                  v-for="(pkg, index) in diamondPackages"
                  :key="index"
                  @click="selectDiamondPackage(pkg.diamonds)"
                  :class="[
                    'relative flex flex-col items-center justify-center p-3 rounded-lg border transition-all duration-200',
                    selectedPackage === pkg.diamonds
                      ? 'border-pink-500 bg-gradient-to-br from-pink-50/70 to-purple-50/70 dark:from-pink-900/20 dark:to-purple-900/20 shadow-sm'
                      : 'border-gray-200 dark:border-slate-700 hover:border-pink-300 dark:hover:border-pink-800 hover:bg-pink-50/30 dark:hover:bg-pink-900/5',
                  ]"
                >
                  <div class="flex items-center">
                    <span class="text-pink-500 font-semibold text-xl">
                      {{ pkg.diamonds }}
                    </span>
                    <UIcon
                      name="i-heroicons-sparkles"
                      class="h-4 w-4 ml-1 text-pink-400"
                    />
                  </div>
                  <span class="text-xs text-gray-600 dark:text-gray-400 mt-1"
                    >{{ pkg.price }} BDT</span
                  >

                  <!-- Selection indicator -->
                  <div
                    v-if="selectedPackage === pkg.amount"
                    class="absolute -top-1.5 -right-1.5 h-5 w-5 bg-gradient-to-br from-pink-500 to-purple-500 rounded-full flex items-center justify-center shadow-sm"
                  >
                    <UIcon
                      name="i-heroicons-check"
                      class="h-3 w-3 text-white"
                    />
                  </div>
                </button>
              </div>

              <!-- Custom amount input -->
              <div class="mb-5">
                <label
                  class="block text-xs font-medium text-gray-800 dark:text-gray-400 mb-1.5 ml-1"
                >
                  Custom Amount
                </label>
                <div class="relative">
                  <input
                    type="number"
                    v-model="customDiamondAmount"
                    placeholder="Enter diamond amount"
                    min="10"
                    class="w-full px-3.5 py-2.5 border border-gray-200 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500/50 dark:focus:ring-pink-400/40 text-gray-800 dark:text-gray-300 bg-white/80 dark:bg-slate-800/80"
                    @input="onCustomAmountInput"
                  />
                  <div
                    class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center"
                  >
                    <UIcon
                      name="i-heroicons-sparkles"
                      class="h-4 w-4 text-pink-400 mr-1"
                    />
                  </div>
                </div>
                <div class="flex items-center justify-between mt-1.5">
                  <p class="text-xs text-gray-600">Minimum 10 diamonds</p>
                  <p class="text-xs text-gray-600">
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
                <UIcon
                  name="i-heroicons-shopping-cart"
                  class="h-4 w-4 mr-1.5"
                />
                Purchase Diamonds
              </button>
            </div>
          </div>
        </div>
      </div>      <!-- Mention suggestions dropdown with enhanced glassmorphism -->
      <div
        v-if="showMentions"
        ref="mentionDropdownRef"
        class="absolute left-0 bottom-full mb-2 w-72 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-lg shadow-lg border border-gray-100/50 dark:border-slate-700/50 z-20 max-h-64 overflow-y-auto animate-fade-in-up premium-shadow no-scrollbar"
      ><div class="py-2">
          <!-- Show loading state when searching -->
          <div v-if="isSearching" class="px-4 py-3 text-center text-sm text-gray-500 dark:text-gray-400">
            <div class="flex items-center justify-center space-x-2">
              <div class="w-4 h-4 border-2 border-gray-300 border-t-blue-500 rounded-full animate-spin"></div>
              <span>Searching...</span>
            </div>
          </div>
          
          <!-- Show suggestions -->
          <div
            v-for="(user, index) in mentionSuggestions"
            :key="user.id"
            @click="selectMention(user)"
            :class="[
              'flex items-center px-4 py-3 cursor-pointer transition-colors duration-200',
              index === activeMentionIndex
                ? 'bg-blue-50/80 dark:bg-blue-900/30'
                : 'hover:bg-gray-50/80 dark:hover:bg-slate-700/50',
            ]"
          >            <!-- User avatar -->
            <div class="relative mr-3">
              <img
                :src="user?.image || '/static/frontend/images/placeholder.jpg'"
                :alt="user?.name || user?.first_name || 'User'"
                class="w-10 h-10 rounded-full border-2 border-gray-200/70 dark:border-slate-700/70 object-cover"
              />
            </div><!-- User info and badges -->            <div class="flex-1 min-w-0">
              <!-- User name with verified and pro badges on the right -->
              <div class="flex items-center gap-1 flex-1 min-w-0">
                <span class="text-sm font-medium text-gray-800 dark:text-gray-200 truncate">
                  {{ user?.name || `${user?.first_name || ''} ${user?.last_name || ''}`.trim() || user?.username || 'Unknown User' }}
                </span>
                
                <!-- Verified badge -->
                <UIcon
                  v-if="user?.kyc"
                  name="i-mdi-check-decagram"
                  class="w-4 h-4 text-blue-600 animate-pulse-subtle flex-shrink-0"
                />
                
                <!-- Pro badge immediately after verified badge -->
                <span
                  v-if="user?.is_pro"
                  class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-xs font-medium shadow-sm flex-shrink-0"
                >
                  <div class="flex items-center gap-1">
                    <UIcon name="i-heroicons-shield-check" class="size-3" />
                    <span class="text-2xs">Pro</span>
                  </div>
                </span>
              </div>
              
              <!-- Top Contributor badge under the name -->
              <div v-if="user?.is_topcontributor" class="mt-1">
                <span class="px-1.5 py-0.5 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full text-xs font-medium shadow-sm inline-flex items-center gap-1">
                  <UIcon name="i-heroicons-star" class="size-3" />
                  <span class="text-2xs">Top Contributor</span>
                </span>
              </div>
            </div>
          </div>
          
          <!-- Show no results message -->
          <div v-if="mentionSuggestions.length === 0 && mentionSearchText && !isSearching" class="px-4 py-3 text-center text-sm text-gray-500 dark:text-gray-400">
            No users found for "{{ mentionSearchText }}"
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
        <div
          class="animate-pop-in bg-white/95 dark:bg-slate-800/95 py-4 px-6 rounded-xl shadow-sm border border-pink-200 dark:border-pink-900/30 text-center"
        >
          <div class="flex flex-col items-center">
            <div
              class="w-14 h-14 rounded-full bg-gradient-to-br from-pink-400 to-purple-500 flex items-center justify-center mb-3 shadow-sm"
            >
              <UIcon name="i-heroicons-gift-top" class="h-7 w-7 text-white" />
            </div>
            <h3 class="text-xl font-semibold text-gray-800 dark:text-white mb-1">
              Gift Sent Successfully!
            </h3>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              You sent {{ lastGiftAmount }} diamonds to
              {{ post?.author_details?.name || post?.author?.name || "User" }}
            </p>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch, nextTick } from "vue";
import { Send } from "lucide-vue-next";

const { get, post: postApi } = useApi();
const { user, jwtLogin } = useAuth();
const router = useRouter();
const toast = useToast();

// Add ref for the comment input
const commentInputRef = ref(null);
const mentionDropdownRef = ref(null);

// Mention functionality state
const showMentions = ref(false);
const mentionSuggestions = ref([]);
const activeMentionIndex = ref(0);
const mentionSearchText = ref("");

// Enhanced mention display state
const extractedMentions = ref([]);
const displayCommentText = ref("");
const mentionInputPosition = ref(null);
const isSearching = ref(false);

const props = defineProps({
  post: {
    type: Object,
    required: true,
  },
  user: {
    type: Object,
    required: true,
  },
});

// Diamond dropup state
const showDiamondDropup = ref(false);
const showBuyDiamonds = ref(false);
const selectedPackage = ref(null);
const customDiamondAmount = ref(null);
const dropupRef = ref(null);
const giftButtonRef = ref(null);

// Gift sending states
const sendFromBalance = ref(null);
const giftMessage = ref(""); // Gift message input
const isSendingGift = ref(false);
const showSuccessPopup = ref(false);
const lastGiftAmount = ref(0);

// Account balance in BDT
const accountBalance = computed(() => {
  return user.value.user?.balance || 0;
});

// Available diamonds - this will be different from account funds
const availableDiamonds = computed(() => {
  // Check userStore first, then fallback to props.user
  if (
    user.value.user &&
    typeof user.value.user.diamond_balance !== "undefined"
  ) {
    return user.value.user.diamond_balance || 0;
  }
  // Fallback to the props if userStore is not yet loaded
  return props.user?.user?.diamond_balance || 0;
});

// Diamond packages (10 diamonds = 1 BDT)
const diamondPackages = ref([]);

async function getDiamondsPackges(params) {
  try {
    const response = await get("/diamonds/packages/");
    if (response.data) {
      diamondPackages.value = response.data;
    }
  } catch (error) {}
}
await getDiamondsPackges();

// Calculate if purchase is possible
const canPurchase = computed(() => {
  return (
    selectedPackage.value ||
    (customDiamondAmount.value && customDiamondAmount.value >= 10)
  );
});

// Calculate if sending gift is possible
const canSendGift = computed(() => {
  return (
    sendFromBalance.value &&
    sendFromBalance.value > 0 &&
    sendFromBalance.value <= availableDiamonds.value
  ); // Check against diamond balance, not user money balance
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
    giftMessage.value = ""; // Reset gift message
    showBuyDiamonds.value = false;

    // Refresh user data to get latest balance
  }
};

// Handle clicks outside to close dropdown
const handleClickOutside = (event) => {
  // Handle diamond dropup
  if (
    showDiamondDropup.value &&
    dropupRef.value &&
    !dropupRef.value.contains(event.target) &&
    giftButtonRef.value &&
    !giftButtonRef.value.contains(event.target)
  ) {
    showDiamondDropup.value = false;
  }
  
  // Handle mention dropdown
  if (
    showMentions.value &&
    mentionDropdownRef.value &&
    !mentionDropdownRef.value.contains(event.target) &&
    commentInputRef.value &&
    !commentInputRef.value.contains(event.target)
  ) {
    showMentions.value = false;
    mentionSuggestions.value = [];
  }
};

// Setup event listeners for click outside detection
onMounted(() => {
  document.addEventListener("click", handleClickOutside);
  // Initialize with empty state - mentions are only created by selection
});

onBeforeUnmount(() => {
  document.removeEventListener("click", handleClickOutside);
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
  // Initialize API utility

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
        window.$nuxt.$toast.error(
          `You only have ${availableDiamonds.value} diamonds available`
        );
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
      message: giftMessage.value || `Sent ${giftAmount} diamonds as a gift! ✨`,
    };

    console.log("Sending gift with payload:", payload);

    // Call the API endpoint
    const response = await postApi("/diamonds/send-gift/", payload);

    console.log("Gift sent successfully:", response);

    // Update the user's diamond balance locally
    if (user.value.user) {
      user.value.user.diamond_balance -= giftAmount;
    }

    // Close the dialog
    closeDiamondDropup();

    // Store the gift amount for the success popup
    lastGiftAmount.value = giftAmount; // Show success popup
    showSuccessPopup.value = true;

    // Auto-hide popup after 3 seconds
    setTimeout(() => {
      showSuccessPopup.value = false;
    }, 3000);

    // Emit event that a gift was sent
    emit("gift-sent", {
      postId: props.post.id,
      giftAmount: giftAmount,
    });

    // Refresh user data to get updated balances
  } catch (error) {
    console.error("Error sending gift:", error);

    // Show error message
    let errorMsg = "Failed to send gift";

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
  // Initialize the API utility
  console.log(selectedPackage.value, customDiamondAmount.value);
  const diamondAmount = selectedPackage.value || customDiamondAmount.value;
  if (!diamondAmount) return;

  // Calculate cost in BDT (10 diamonds = 1 BDT)
  const costInBDT = calculatePrice(diamondAmount);

  // Check if user has sufficient balance
  if (user.value?.user?.balance < costInBDT) {
    toast.add({
      title: "Insufficient balance",
      description: "Please add funds to your account",
    });
    return;
  }

  try {
    // Call API to purchase diamonds
    const response = await postApi("/diamonds/purchase/", {
      amount: parseInt(diamondAmount),
      cost: costInBDT,
    });

    // Update UI immediately for better UX
    if (response.data) {
      jwtLogin();
      // Show success message
      toast.add({
        title: "Purchase successful",
        description: `You've purchased ${diamondAmount} diamonds!`,
        color: "green",
      });
      showBuyDiamonds.value = false;
    }
  } catch (error) {
    console.error("Error purchasing diamonds:", error);
    toast.add({
      title: "Purchase failed",
      description: error.response?.data?.error || "Failed to purchase diamonds",
      color: "red",
    });
  }
};

// Handle deposit button click - redirect to deposit page
const goToDeposit = () => {
  // Close the dropdown and navigate to the deposit page
  showDiamondDropup.value = false;
  navigateTo("/deposit-withdraw");
};

// Navigate to funds page
const navigateToFunds = () => {
  navigateTo("/deposit-withdraw");
};

// Handle keyboard navigation for mentions
const handleMentionKeydown = (event) => {
  if (!showMentions.value || mentionSuggestions.value.length === 0) {
    emit('handle-mention-keydown', event, props.post);
    return;
  }
  
  // Handle arrow keys for mention selection
  if (event.key === "ArrowDown") {
    event.preventDefault();
    activeMentionIndex.value = (activeMentionIndex.value + 1) % mentionSuggestions.value.length;
  } else if (event.key === "ArrowUp") {
    event.preventDefault();
    activeMentionIndex.value =
      activeMentionIndex.value <= 0
        ? mentionSuggestions.value.length - 1
        : activeMentionIndex.value - 1;
  } else if (event.key === "Enter" && showMentions.value) {
    event.preventDefault();
    const selectedUser = mentionSuggestions.value[activeMentionIndex.value];
    if (selectedUser) {
      selectMention(selectedUser);
    }
  } else if (event.key === "Escape" || event.key === " ") {
    // Close mention dropdown without selecting
    showMentions.value = false;
    mentionSuggestions.value = [];
    if (event.key === " ") {
      // For space, we don't prevent default so the space gets typed
      // But we close the mention dropdown
    } else {
      event.preventDefault();
    }
  }
  
  // Emit the event for parent components
  emit('handle-mention-keydown', event, props.post);
};

// Search for users to mention
const searchMentions = async (query) => {
  console.log('searchMentions called with query:', query);
  console.log('Before search - isSearching:', isSearching.value);
  console.log('Before search - mentionSuggestions:', mentionSuggestions.value);
  
  // Only search if we have a valid query
  if (!query || query.length === 0) {
    console.log('Empty query, not searching');
    mentionSuggestions.value = [];
    isSearching.value = false;
    return;
  }
  
  isSearching.value = true;
  console.log('Set isSearching to true');
  
  try {
    console.log('Making API call to:', `/bn/user-search/?q=${encodeURIComponent(query)}`);
    const { data } = await get(`/bn/user-search/?q=${encodeURIComponent(query)}`);
    
    console.log('API response received:', data);
    console.log('API response type:', typeof data);
    console.log('API response keys:', Object.keys(data || {}));
    
    // Handle paginated response
    if (data && data.results) {
      mentionSuggestions.value = data.results.slice(0, 10); // Limit to 10 suggestions
      console.log('Set suggestions from paginated results:', mentionSuggestions.value);
    } else if (Array.isArray(data)) {
      mentionSuggestions.value = data.slice(0, 10);
      console.log('Set suggestions from array:', mentionSuggestions.value);
    } else {
      mentionSuggestions.value = [];
      console.log('No valid data format, clearing suggestions');
    }
    
    console.log('Final mentionSuggestions:', mentionSuggestions.value);
    console.log('Final mentionSuggestions length:', mentionSuggestions.value.length);
      activeMentionIndex.value = 0;
  } catch (error) {
    console.error("Error searching mentions:", error);
    console.error("Error details:", error.response?.data);
    mentionSuggestions.value = [];
  } finally {
    isSearching.value = false;
    console.log('Set isSearching to false');
    console.log('After search - mentionSuggestions:', mentionSuggestions.value);
    console.log('After search - isSearching:', isSearching.value);
  }
};

// Select a mention and insert it into the comment
const selectMention = (selectedUser) => {
  if (!commentInputRef.value) return;
  
  // Get the user's display name
  const userName = selectedUser.name || 
                   `${selectedUser.first_name || ''} ${selectedUser.last_name || ''}`.trim() || 
                   selectedUser.username || 
                   'Unknown User';
  
  // Add to extracted mentions if not already present
  if (!extractedMentions.value.includes(userName)) {
    extractedMentions.value.push(userName);
  }
  
  // Clear the @mention from display text
  const currentText = displayCommentText.value;
  const lastAtIndex = currentText.lastIndexOf('@');
  if (lastAtIndex !== -1) {
    displayCommentText.value = currentText.substring(0, lastAtIndex).trim();
  }
  
  // Rebuild full comment text properly
  const mentionText = extractedMentions.value.map(mention => `@${mention}`).join(' ');
  
  let finalText = '';
  if (mentionText && displayCommentText.value.trim()) {
    finalText = mentionText + ' ' + displayCommentText.value;
  } else if (mentionText) {
    finalText = mentionText;
  } else if (displayCommentText.value.trim()) {
    finalText = displayCommentText.value;
  }
  
  props.post.commentText = finalText;
  
  console.log('Selected mention, final text:', {
    userName,
    mentions: extractedMentions.value,
    displayText: displayCommentText.value,
    finalText: finalText
  });
  
  // Reset mention state
  showMentions.value = false;
  mentionSuggestions.value = [];
  mentionInputPosition.value = null;
  
  // Focus back to the input
  nextTick(() => {
    if (commentInputRef.value) {
      commentInputRef.value.focus();
    }
  });
  
  // Emit the event for parent components that might need it
  emit('select-mention', selectedUser, props.post);
};

// Enhanced mention functionality methods
const parseCommentForMentions = (text) => {
  if (!text) return { mentions: [], cleanText: text };
  
  // Improved regex to capture full names properly
  // This matches up to 3 words after @, but stops at lowercase words or punctuation
  const mentionRegex = /@([A-Za-z0-9_'-]+(?:\s+[A-Za-z0-9_'-]+)*?)(?=\s+[a-z]|\s*[.!?]|\s*$|$)/g;
  const mentions = [];
  let match;
  
  while ((match = mentionRegex.exec(text)) !== null) {
    const mentionName = match[1].trim();
    if (mentionName && !mentions.includes(mentionName)) {
      mentions.push(mentionName);
    }
  }
  
  // Remove mentions from text to show clean text in input
  const cleanText = text.replace(mentionRegex, '').replace(/\s+/g, ' ').trim();
  
  return { mentions, cleanText };
};

// Update mentions and display text when comment text changes
const updateMentionDisplay = () => {
  const { mentions, cleanText } = parseCommentForMentions(props.post.commentText);
  extractedMentions.value = mentions;
  displayCommentText.value = cleanText;
};

// Navigate to mentioned user's profile
const navigateToMentionedUser = async (mentionName) => {
  try {
    const router = useRouter();
    // Try to navigate to search results filtered by users
    await router.push({
      path: `/business-network/search-results/${encodeURIComponent(mentionName)}`,
      query: { type: 'users' }
    });
  } catch (error) {
    console.error('Error navigating to mentioned user:', error);
  }
};

// Remove a mention from the list
const removeMention = (mentionToRemove) => {
  // Remove from extracted mentions
  extractedMentions.value = extractedMentions.value.filter(mention => mention !== mentionToRemove);
  
  // Rebuild the comment text without this mention
  const remainingMentions = extractedMentions.value.map(mention => `@${mention}`).join(' ');
  
  let finalText = '';
  if (remainingMentions && displayCommentText.value.trim()) {
    finalText = remainingMentions + ' ' + displayCommentText.value;
  } else if (remainingMentions) {
    finalText = remainingMentions;
  } else if (displayCommentText.value.trim()) {
    finalText = displayCommentText.value;
  }
  
  props.post.commentText = finalText;
  
  console.log('Removed mention, final text:', {
    removedMention: mentionToRemove,
    remainingMentions: extractedMentions.value,
    displayText: displayCommentText.value,
    finalText: finalText
  });
};

// Clear all content
const clearComment = () => {
  props.post.commentText = '';
  displayCommentText.value = '';
  extractedMentions.value = [];
};

// Override the original handleCommentInput to work with the new display
const handleCommentInput = (event) => {
  const inputValue = event.target.value;
  
  // Update the display text
  displayCommentText.value = inputValue;
  
  // Rebuild full comment text with mentions (only include confirmed mentions)
  const mentionText = extractedMentions.value.map(mention => `@${mention}`).join(' ');
  
  // Build the final text properly
  let fullText = '';
  if (mentionText && inputValue.trim()) {
    fullText = mentionText + ' ' + inputValue;
  } else if (mentionText) {
    fullText = mentionText;
  } else if (inputValue.trim()) {
    fullText = inputValue;
  }
  
  props.post.commentText = fullText;
  
  console.log('Comment text built:', {
    mentions: extractedMentions.value,
    inputValue: inputValue,
    finalText: fullText
  });
  
  // Handle mention detection in the new input
  const lastAtIndex = inputValue.lastIndexOf('@');
  if (lastAtIndex !== -1) {
    const textAfterAt = inputValue.substring(lastAtIndex + 1);
    // Only show mentions if there's no space after @ AND there's at least one character after @
    if (!textAfterAt.includes(' ') && textAfterAt.length > 0) {
      mentionSearchText.value = textAfterAt;
      searchMentions(textAfterAt);
      showMentions.value = true;
      
      // Store mention position for the display text input
      mentionInputPosition.value = {
        startPos: lastAtIndex,
        endPos: inputValue.length
      };
    } else {
      showMentions.value = false;
    }
  } else {
    showMentions.value = false;
  }
  
  // Auto resize the textarea
  autoResize();
  
  // Emit the event for parent components that might need it
  emit('handle-comment-input', event, props.post);
};

// Handle posting comment with debug info
const handlePostComment = () => {
  // Rebuild the final comment text one more time before posting
  const mentionText = extractedMentions.value.map(mention => `@${mention}`).join(' ');
  
  let finalText = '';
  if (mentionText && displayCommentText.value.trim()) {
    finalText = mentionText + ' ' + displayCommentText.value;
  } else if (mentionText) {
    finalText = mentionText;
  } else if (displayCommentText.value.trim()) {
    finalText = displayCommentText.value;
  }
  
  props.post.commentText = finalText;
  
  console.log('=== POSTING COMMENT ===');
  console.log('Mentions:', extractedMentions.value);
  console.log('Display text:', displayCommentText.value);
  console.log('Final comment text:', finalText);
  console.log('Comment text length:', finalText?.length);
  console.log('Comment text trimmed:', finalText?.trim());
  console.log('Post object commentText:', props.post.commentText);
  console.log('========================');
  
  // Only emit if we have content
  if (finalText?.trim()) {
    emit('add-comment', props.post);
  } else {
    console.warn('No content to post!');
  }
};

// Watch for changes in post.commentText to update display (but don't auto-parse mentions)
watch(() => props.post.commentText, (newText) => {
  // Only update if the text was changed externally (not from our own input handling)
  // We handle our own display updates in handleCommentInput
}, { immediate: false });

// Auto-resize textarea function
const autoResize = () => {
  nextTick(() => {
    if (commentInputRef.value) {
      commentInputRef.value.style.height = 'auto';
      const newHeight = Math.min(commentInputRef.value.scrollHeight, 96); // Max 4 lines
      commentInputRef.value.style.height = newHeight + 'px';
    }
  });
};

const emit = defineEmits([
  "add-comment",
  "handle-comment-input",
  "handle-mention-keydown",
  "select-mention",
  "gift-sent",
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
  box-shadow: 0 10px 40px rgba(255, 105, 180, 0.1),
    0 4px 12px rgba(0, 0, 0, 0.08), 0 0 2px rgba(255, 105, 180, 0.1);
  z-index: 40; /* Increase z-index to appear above other posts */
}

.dark .diamond-dropup {
  box-shadow: 0 10px 40px rgba(255, 105, 180, 0.15),
    0 4px 12px rgba(0, 0, 0, 0.25), 0 0 2px rgba(255, 255, 255, 0.05);
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

/* Enhanced mention chip animations */
@keyframes mention-chip-in {
  0% {
    opacity: 0;
    transform: scale(0.8) translateY(10px);
  }
  100% {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

.mention-chip-enter {
  animation: mention-chip-in 0.2s ease-out forwards;
}

/* Smooth transitions for textarea resize */
.comment-textarea {
  transition: height 0.2s ease-out;
  resize: none;
}

/* Custom scrollbar for mention chips area */
.mention-chips-container::-webkit-scrollbar {
  height: 4px;
}

.mention-chips-container::-webkit-scrollbar-track {
  background: transparent;
}

.mention-chips-container::-webkit-scrollbar-thumb {
  background: rgba(156, 163, 175, 0.3);
  border-radius: 2px;
}

.mention-chips-container::-webkit-scrollbar-thumb:hover {
  background: rgba(156, 163, 175, 0.5);
}
</style>
