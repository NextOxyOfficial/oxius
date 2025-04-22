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
              class="mt-6 px-7 text-center text-base font-medium text-slate-600 dark:text-slate-300"
            >
              AdsyClub – Bangladesh’s 1st Social Business Network: Earn Money,
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
          class="flex flex-col sm:flex-row justify-between gap-5 lg:gap-12 sm:items-center px-[7px] max-w-5xl mx-auto dark:text-gray-200"
        >
          <div class="flex flex-col gap-4">
            <h4 class="font-bold hidden md:block">
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
                    alt="App"
                  />
                </nuxt-link>
              </li>
              <li class="w-[119px]">
                <nuxt-link
                  to="/coming-soon/"
                  class="transition-transform hover:scale-105 duration-300 block"
                >
                  <img
                    src="/static/frontend/images/google.png"
                    class="mx-auto w-full shadow-sm rounded-lg"
                    quality="100"
                    format="webp"
                    alt="App"
                  />
                </nuxt-link>
              </li>
            </ul>
          </div>
          <div class="">
            <div class="flex flex-col gap-4">
              <h4 class="font-bold hidden md:block text-center">
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
          class="text-center text-sm text-slate-600 dark:text-gray-200 flex items-center justify-center gap-1 flex-wrap pt-6 pb-20 sm:pb-6"
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
      class="sm:hidden block fixed left-0 right-0 z-[99999999] bottom-2 mx-6 dark:bg-slate-900/90 bg-white/90 backdrop-blur-sm rounded-2xl border border-emerald-100 dark:border-slate-800 shadow-lg"
    >
      <UHorizontalNavigation
        v-if="user?.user?.id"
        :links="[
          {
            to: '/',
            icon: 'i-material-symbols:android-google-home',
          },
          {
            to: '/deposit-withdraw',
            icon: 'i-token:cusd',
          },
          {
            to: '/mobile-recharge',
            icon: 'i-uil-mobile-vibrate',
          },
          {
            to: '/business-network',
            icon: 'i-eos-icons:network',
          },
          {
            to: '/adsy-news',
            icon: 'i-mdi:newspaper-variant-multiple-outline',
          },
        ]"
        :ui="{
          inactive: 'after:hidden before:hidden',
          active: 'after:hidden before:hidden',
          padding: 'py-1',
          container: 'flex items-center justify-evenly min-w-full',
        }"
      >
        <template #icon="{ link, isActive }">
          <UIcon
            :name="link.icon"
            class="text-3xl"
            :class="isActive ? `text-green-600` : `text-green-400`"
          />
        </template>
      </UHorizontalNavigation>
      <UHorizontalNavigation
        v-else
        :links="[
          {
            to: '/',
            icon: 'i-material-symbols:android-google-home',
          },
          {
            to: '/#microgigs',
            icon: 'i-streamline:money-cash-bag-dollar-bag-payment-cash-money-finance',
          },

          {
            to: '/eshop',
            icon: 'i-heroicons-shopping-bag',
          },
          {
            to: '/business-network',
            icon: 'i-eos-icons-network',
          },
          {
            to: '/adsy-news',
            icon: 'i-mdi-newspaper-variant-multiple-outline',
          },
        ]"
        :ui="{
          inactive: 'after:hidden before:hidden',
          active: 'after:hidden before:hidden',
          padding: 'py-1',
          container: 'flex items-center justify-evenly min-w-full',
        }"
      >
        <template #icon="{ link, isActive }">
          <UIcon
            v-if="link.to === '/'"
            :name="link.icon"
            class="text-3xl"
            :class="isActive ? `text-green-600` : `text-green-400`"
          />
          <UIcon
            v-else
            :name="link.icon"
            class="text-2xl"
            :class="isActive ? `text-green-600` : `text-green-400`"
          />
        </template>
      </UHorizontalNavigation>
    </div>
  </footer>
</template>

<script setup>
const { t } = useI18n();
const toggleStatus = ref("");
const { user } = useAuth();

watch(toggleStatus, () => {
  console.log("State Changed");
});
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
</style>
