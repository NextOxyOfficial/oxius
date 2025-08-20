<template>
  <footer
    class="pt-6 bg-slate-100/70 dark:bg-slate-900 relative overflow-hidden"
  >
    <!-- Modern Subtle Background Pattern -->
    <div class="absolute inset-0 bg-pattern opacity-10 dark:opacity-10"></div>

    <!-- Subtle gradient accents -->
    <div
      class="absolute -top-24 -right-24 w-72 h-72 bg-emerald-400 dark:bg-emerald-600 rounded-full opacity-5 blur-3xl"
    ></div>
    <div
      class="absolute -bottom-24 -left-24 w-72 h-72 bg-blue-400 dark:bg-blue-600 rounded-full opacity-5 blur-3xl"
    ></div>

    <!-- Content with relative positioning to appear above the pattern -->
    <div class="relative">
      <UContainer>
        <UDivider class="mb-6 w-60 mx-auto" />
        <!-- Logo at the top -->
        <div class="flex justify-center mb-4">
          <div class="flex flex-col items-center">
            <PublicLogo customClass="h-10 sm:h-12" />
            <h3
              class="mt-6 px-7 text-center text-base font-medium text-gray-600 dark:text-slate-300"
            >
              AdsyClub – Social Business Network: Earn Money,
              Connect with Society & Find the Services You Need!
            </h3>
          </div>
        </div>

        <div class="mb-8">
          <UHorizontalNavigation
            :links="[
              {
                label: $t('classified_service'),
                to: '/',
              },
              {
                label: $t('earn_money'),
                to: '/',
              },
              {
                label: $t('mobile_recharge'),
                to: '/mobile-recharge',
              },
              {
                label: $t('packeges'),
                to: '/upgrade-to-pro',
              },
              {
                label: $t('refer_program'),
                to: '/refer-a-friend',
              },
              {
                label: $t('about_us'),
                to: '/about',
              },
              {
                label: $t('faq'),
                to: '/faq',
              },
              {
                label: $t('contact_us'),
                to: '/contact-us',
              },
            ]"
            :ui="{
              base: 'before:hidden font-normal hover:text-green-500',
              padding: 'px-1',
              inactive: 'hover:text-green-300 after:hidden',
              active: 'after:hidden',
              wrapper: 'justify-center',
              size: 'text-base md:text-lg',
            }"
            class="w-full !bg-transparent hidden md:flex"
          />
          <UVerticalNavigation
            :links="[
              {
                label: $t('classified_service'),
                to: '/',
              },
              {
                label: $t('earn_money'),
                to: '/',
              },
              {
                label: $t('packeges'),
                to: '/upgrade-to-pro',
              },
              {
                label: $t('refer_program'),
                to: '/refer-a-friend',
              },
              {
                label: $t('about_us'),
                to: '/about',
              },
              {
                label: $t('contact_us'),
                to: '/contact-us',
              },
            ]"
            :ui="{
              base: 'before:hidden justify-center font-normal hover:text-green-500',
              padding: 'px-1',
              inactive: 'hover:text-green-300 after:hidden',
              active: 'after:hidden',
              wrapper: 'justify-center',
              size: 'text-base md:text-lg',
            }"
            class="w-full !bg-transparent md:hidden"
          />
        </div>

        <div
          class="flex flex-col sm:flex-row justify-between gap-5 lg:gap-12 sm:items-center px-[7px] max-w-5xl mx-auto dark:text-gray-300"
        >
          <div class="flex flex-col gap-4">
            <h4 class="font-semibold hidden md:block">
              {{ $t("download_app") }}
            </h4>
            <ul class="flex gap-2 flex-1 max-md:justify-center">
              <li class="w-[117px]">
                <nuxt-link
                  to="/coming-soon/"
                  class="transition-transform hover:scale-105 duration-300 block"
                >
                  <img
                    src="/static/frontend/images/apple.png"
                    class="mx-auto w-full shadow-sm rounded-lg"
                    quality="100"
                    format="webp"
                    alt="App Store - Coming Soon"
                  />
                </nuxt-link>
              </li>
              <li class="w-[119px]">
                <button
                  @click="downloadAndroidApp"
                  class="transition-transform hover:scale-105 duration-300 block w-full"
                >
                  <img
                    src="/static/frontend/images/google.png"
                    class="mx-auto w-full shadow-sm rounded-lg"
                    quality="100"
                    format="webp"
                    alt="Download Android App"
                  />
                </button>
              </li>
            </ul>
          </div>
          <div class="">
            <div class="flex flex-col gap-4">
              <h4 class="font-semibold hidden md:block text-center">
                {{ $t("we_accept") }}
              </h4>
              <img
                src="/static/frontend/images/payment.png"
                quality="100"
                format="webp"
                alt="Payment"
                class="md:w-[370px]"
              />
            </div>
          </div>
        </div>

        <div>
          <UHorizontalNavigation
            :ui="{
              base: 'before:hidden text-sm lg:text-base font-normal hover:text-green-500',
              padding: 'px-1',
              inactive: 'hover:text-green-300 after:hidden',
              active: 'after:hidden',
              wrapper: 'justify-center',
            }"
            :links="[
              {
                label: $t('terms_conditions'),
                to: '/terms',
              },
              {
                label: $t('privacy_policy'),
                to: '/privacy',
              },
            ]"
          />
        </div>
        <UDivider label="" class="opacity-60" />

        <p
          class="text-center text-sm text-gray-600 dark:text-gray-300 flex items-center justify-center gap-1 flex-wrap pt-6 pb-20 sm:pb-6"
        >
          <span>Developed With</span>
          <span class="inline-flex items-center">
            <UIcon
              name="i-heroicons-heart"
              class="text-red-500 h-5 w-5 mx-0.5 animate-pulse"
              aria-label="love"
            />
          </span>
          <span
            >By Lyricz Softwares & Technology Limited ©
            {{ new Date().getFullYear() }}</span
          >
        </p>
      </UContainer>
    </div>
    <!-- Mobile Navigation Bar -->
    <div
      class="sm:hidden block fixed left-0 right-0 z-50 bottom-2 mx-6 dark:bg-slate-900/90 bg-white/90 backdrop-blur-sm rounded-xl border border-emerald-100 dark:border-slate-800 shadow-sm transition-all duration-500"
      :class="[
        // Hide on mobile when scrolling down
        isScrollingDown ? 'translate-y-20' : 'translate-y-0'
      ]"
    >
      <!-- Logged in users navigation -->
      <div
        v-if="user?.user?.id"
        class="flex items-center justify-evenly min-w-full py-1"
      >
        <NuxtLink
          to="/"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('mobile_home')"
        >
          <div
            v-if="loadingButtons.has('mobile_home')"
            class="dotted-spinner green mb-1"
          ></div>
          <!-- <UIcon
            v-else
            name="i-material-symbols:android-google-home"
            class="text-3xl text-green-400"
          /> -->
          <img
            v-else
            src="/static/frontend/favicon.png"
            class="size-[26px]"
            alt="AdsyClub Logo"
          />
        </NuxtLink>

        <NuxtLink
          to="/deposit-withdraw"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('mobile_deposit')"
        >
          <div
            v-if="loadingButtons.has('mobile_deposit')"
            class="dotted-spinner green mb-1"
          ></div>
          <UIcon v-else name="i-token:cusd" class="text-3xl text-green-400" />
        </NuxtLink>

        <NuxtLink
          to="/mobile-recharge"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('mobile_recharge')"
        >
          <div
            v-if="loadingButtons.has('mobile_recharge')"
            class="dotted-spinner green mb-1"
          ></div>
          <UIcon
            v-else
            name="i-uil-mobile-vibrate"
            class="text-3xl text-green-400"
          />
        </NuxtLink>

        <NuxtLink
          to="/business-network"
          class="flex flex-col items-center p-2 relative"
          @click="handleButtonClick('mobile_business')"
        >
          <div class="relative">
            <div
              v-if="loadingButtons.has('mobile_business')"
              class="dotted-spinner green mb-1"
            ></div>
            <UIcon
              v-else
              name="i-eos-icons:network"
              class="text-3xl text-green-400"
            />
            <!-- Notification badge for business network icon -->
            <div
              v-if="unreadCount > 0"
              class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1 animate-pulse"
            >
              {{ unreadCount > 99 ? "99+" : unreadCount }}
            </div>
          </div>
        </NuxtLink>

        <NuxtLink
          to="/adsy-news"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('mobile_news')"
        >
          <div
            v-if="loadingButtons.has('mobile_news')"
            class="dotted-spinner green mb-1"
          ></div>
          <UIcon
            v-else
            name="i-mdi:newspaper-variant-multiple-outline"
            class="text-3xl text-green-400"
          />
        </NuxtLink>
      </div>

      <!-- Guest users navigation -->
      <div v-else class="flex items-center justify-evenly min-w-full py-1">
        <NuxtLink
          to="/"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('guest_home')"
        >
          <div
            v-if="loadingButtons.has('guest_home')"
            class="dotted-spinner green mb-1"
          ></div>
          <!-- <UIcon
            v-else
            name="i-material-symbols:android-google-home"
            class="text-3xl text-green-400"
          /> -->
          <img
            v-else
            src="/static/frontend/favicon.png"
            class="size-[26px]"
            alt="AdsyClub Logo"
          />
        </NuxtLink>

        <NuxtLink
          to="/#microgigs"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('guest_microgigs')"
        >
          <div
            v-if="loadingButtons.has('guest_microgigs')"
            class="dotted-spinner green mb-1"
          ></div>
          <UIcon
            v-else
            name="i-streamline:money-cash-bag-dollar-bag-payment-cash-money-finance"
            class="text-3xl text-green-400"
          />
        </NuxtLink>

        <NuxtLink
          to="/eshop"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('guest_eshop')"
        >
          <div
            v-if="loadingButtons.has('guest_eshop')"
            class="dotted-spinner green mb-1"
          ></div>
          <UIcon
            v-else
            name="i-heroicons-shopping-bag"
            class="text-3xl text-green-400"
          />
        </NuxtLink>

        <NuxtLink
          to="/business-network"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('guest_business')"
        >
          <div
            v-if="loadingButtons.has('guest_business')"
            class="dotted-spinner green mb-1"
          ></div>
          <UIcon
            v-else
            name="i-eos-icons-network"
            class="text-3xl text-green-400"
          />
        </NuxtLink>

        <NuxtLink
          to="/adsy-news"
          class="flex flex-col items-center p-2"
          @click="handleButtonClick('guest_news')"
        >
          <div
            v-if="loadingButtons.has('guest_news')"
            class="dotted-spinner green mb-1"
          ></div>
          <UIcon
            v-else
            name="i-mdi-newspaper-variant-multiple-outline"
            class="text-3xl text-green-400"
          />
        </NuxtLink>
      </div>
    </div>
  </footer>
</template>

<script setup>
import { useScrollDirection } from "~/composables/useScrollDirection";

const { t } = useI18n();
const { isScrollingDown, isScrollingUp } = useScrollDirection();
const toggleStatus = ref("");
const { user } = useAuth();
const { unreadCount, fetchUnreadCount } = useNotifications(); // Import useNotifications
const toast = useToast();

// Loading state for buttons
const loadingButtons = ref(new Set());

// Handle button clicks with loading states
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
};

// Watch route changes to clear loading states
watch(
  () => useRoute().fullPath,
  () => {
    loadingButtons.value.clear();
  }
);

// Use the app download composable
import { useAppDownload } from "~/composables/useAppDownload";
const { downloadApp } = useAppDownload();

// Download Android app function
const downloadAndroidApp = async () => {
  try {
    // Use the composable to get the dynamic download URL from admin
    await downloadApp();

    // Show success toast
    toast.add({
      title: "Download Started",
      description: "AdsyClub Android app is downloading...",
      color: "green",
      icon: "i-heroicons-check-circle",
    });
  } catch (error) {
    console.error("Download error:", error);
    toast.add({
      title: "Download Error",
      description: "Failed to start download. Please try again.",
      color: "red",
      icon: "i-heroicons-exclamation-triangle",
    });
  }
};

// Fetch unread notification count when component is mounted and user is logged in
onMounted(async () => {
  if (user.value?.user?.id) {
    await fetchUnreadCount();
  }
});

// Watch for user changes and fetch notification count when user logs in
watch(
  () => user.value?.user?.id,
  async (newValue) => {
    if (newValue) {
      await fetchUnreadCount();
    }
  }
);
</script>

<style scoped>
/* Professional geometric pattern background - subtle diagonal lines */
.bg-pattern {
  background-color: transparent;
  background-image: linear-gradient(
    135deg,
    rgba(0, 0, 0, 0.05) 25%,
    transparent 25%,
    transparent 50%,
    rgba(0, 0, 0, 0.05) 50%,
    rgba(0, 0, 0, 0.05) 75%,
    transparent 75%,
    transparent
  );
  background-size: 60px 60px;
}

/* For dark mode */
@media (prefers-color-scheme: dark) {
  .bg-pattern {
    background-image: linear-gradient(
      135deg,
      rgba(255, 255, 255, 0.03) 25%,
      transparent 25%,
      transparent 50%,
      rgba(255, 255, 255, 0.03) 50%,
      rgba(255, 255, 255, 0.03) 75%,
      transparent 75%,
      transparent
    );
  }
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1.5rem;
  height: 1.5rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.emerald {
  border-color: #059669;
}

.dotted-spinner.green {
  border-color: #16a34a;
}

.dotted-spinner.slate {
  border-color: #64748b;
}

.dotted-spinner.blue {
  border-color: #3b82f6;
}

.dotted-spinner.violet {
  border-color: #8b5cf6;
}

.dotted-spinner.white {
  border-color: #ffffff;
}

.dotted-spinner.primary {
  border-color: #059669;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
