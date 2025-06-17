<template>
  <!-- Fixed: Explicitly check both local state and prop directly -->
  <div
    v-if="isVisible || props.show"
    class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50 flex items-center justify-center p-4"
    @click.self="closeModal"
  >
    <div
      class="bg-white rounded-xl shadow-2xl max-w-md w-full mx-auto transform transition-all duration-300 ease-out"
      :class="{
        'scale-95 opacity-0': !isAnimating,
        'scale-100 opacity-100': isAnimating,
      }"
    >
      <!-- Modal Header -->
      <div class="px-6 py-4 border-b border-gray-200">
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-bold text-gray-900 flex items-center">
            <svg
              class="w-6 h-6 text-red-500 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
              />
            </svg>
            {{ $t("premium_access_required") || "Premium Access Required" }}
          </h3>
          <button
            @click="closeModal"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <svg
              class="w-6 h-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>
      </div>

      <!-- Modal Body -->
      <div class="px-6 py-6">
        <!-- Icon and Message -->
        <div class="text-center mb-6">
          <div
            class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-gradient-to-br from-red-500 to-rose-600 mb-4"
          >
            <svg
              class="h-8 w-8 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
              />
            </svg>
          </div>

          <h4 class="text-lg font-semibold text-gray-900 mb-2">
            {{ modalContent.title }}
          </h4>
          <p class="text-gray-600 leading-relaxed">
            {{ modalContent.message }}
          </p>
        </div>

        <!-- Features List -->
        <div class="bg-gray-50 rounded-lg p-4 mb-6">
          <h5 class="font-semibold text-gray-900 mb-3 flex items-center">
            <svg
              class="w-5 h-5 text-green-500 mr-2"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                clip-rule="evenodd"
              />
            </svg>
            {{ $t("premium_benefits") || "Premium Benefits" }}
          </h5>
          <ul class="space-y-2 text-sm text-gray-600">
            <li class="flex items-center">
              <svg
                class="w-4 h-4 text-green-500 mr-2"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
              {{ $t("unlimited_video_access") || "Unlimited video access" }}
            </li>
            <li class="flex items-center">
              <svg
                class="w-4 h-4 text-green-500 mr-2"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
              {{ $t("download_materials") || "Download course materials" }}
            </li>
            <li class="flex items-center">
              <svg
                class="w-4 h-4 text-green-500 mr-2"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
              {{ $t("priority_support") || "Priority customer support" }}
            </li>
            <li class="flex items-center">
              <svg
                class="w-4 h-4 text-green-500 mr-2"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
              {{ $t("ad_free_experience") || "Ad-free learning experience" }}
            </li>
          </ul>
        </div>
      </div>

      <!-- Modal Footer -->
      <div class="px-6 py-4 bg-gray-50 rounded-b-xl">
        <div class="flex flex-col sm:flex-row gap-3">
          <!-- Primary Action - Login/Subscribe -->
          <button
            v-if="!isAuthenticated"
            @click="goToLogin"
            class="flex-1 bg-gradient-to-r from-blue-500 to-blue-600 text-white py-3 px-4 rounded-lg font-semibold hover:from-blue-600 hover:to-blue-700 transition-all duration-200 flex items-center justify-center"
          >
            <svg
              class="w-5 h-5 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"
              />
            </svg>
            {{ $t("login_now") || "Login Now" }}
          </button>

          <button
            v-else
            @click="goToSubscription"
            class="flex-1 bg-gradient-to-r from-green-500 to-green-600 text-white py-3 px-4 rounded-lg font-semibold hover:from-green-600 hover:to-green-700 transition-all duration-200 flex items-center justify-center"
          >
            <svg
              class="w-5 h-5 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"
              />
            </svg>
            {{ $t("upgrade_to_premium") || "Upgrade to Premium" }}
          </button>

          <!-- Secondary Action - Maybe Later -->
          <button
            @click="closeModal"
            class="flex-1 sm:flex-none bg-gray-200 text-gray-800 py-3 px-4 rounded-lg font-semibold hover:bg-gray-300 transition-colors duration-200"
          >
            {{ $t("maybe_later") || "Maybe Later" }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, watchEffect } from "vue";

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  type: {
    type: String,
    default: "login_required", // 'login_required' | 'subscription_required'
    validator: (value) =>
      ["login_required", "subscription_required"].includes(value),
  },
});

const emit = defineEmits(["close", "login", "subscribe"]);

const { user, isAuthenticated } = useAuth();
const isVisible = ref(false);
const isAnimating = ref(false);

// Modal content based on type and authentication status
const modalContent = computed(() => {
  if (!isAuthenticated.value) {
    return {
      title: $t("login_required") || "Login Required",
      message:
        $t("login_required_message") ||
        "Please login to your account to access premium video content. Join thousands of learners already benefiting from our comprehensive courses.",
    };
  } else {
    return {
      title:
        $t("premium_subscription_required") || "Premium Subscription Required",
      message:
        $t("premium_subscription_message") ||
        "Upgrade to our premium subscription to unlock unlimited access to all video lessons and exclusive content.",
    };
  }
});

// This effect immediately sets the visibility state when props.show changes
// This ensures the modal shows immediately without waiting for the watcher
const modalVisibility = computed(() => {
  return props.show;
});

// Ensure visibility state is updated on prop changes
watchEffect(() => {
  if (modalVisibility.value) {
    isVisible.value = true;
    nextTick(() => {
      isAnimating.value = true;
    });
  }
});

// Watch for show prop changes
watch(
  () => props.show,
  async (newValue) => {
    if (newValue) {
      // Show modal
      isVisible.value = true;
      await nextTick();
      isAnimating.value = true;
    } else {
      // Hide modal with animation
      isAnimating.value = false;
      setTimeout(() => {
        isVisible.value = false;
      }, 300);
    }
  },
  { immediate: true }
); // Important: Run the callback immediately on component creation

const closeModal = () => {
  isAnimating.value = false;
  setTimeout(() => {
    isVisible.value = false;
    emit("close");
  }, 300);
};

const goToLogin = () => {
  emit("login");
  closeModal();
  navigateTo("/auth/login");
};

const goToSubscription = () => {
  emit("subscribe");
  closeModal();
  // Navigate to subscription page (adjust route as needed)
  navigateTo("/subscription");
};

// Close modal on Escape key
const handleKeydown = (event) => {
  if (event.key === "Escape" && isVisible.value) {
    closeModal();
  }
};

onMounted(() => {
  document.addEventListener("keydown", handleKeydown);

  // Force update initial state based on props
  if (props.show) {
    isVisible.value = true;
    setTimeout(() => {
      isAnimating.value = true;
    }, 50);
  }
});

onUnmounted(() => {
  document.removeEventListener("keydown", handleKeydown);
});
</script>

<style scoped>
/* Smooth transitions for modal */
.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
  transform: scale(0.95);
}

/* Prevent body scroll when modal is open */
.overflow-hidden {
  overflow: hidden;
}
</style>
