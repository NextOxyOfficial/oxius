<template>
  <div class="py-3 sticky z-50 top-0 bg-white dark:bg-black">
    <UContainer>
      <USlideover
        v-model="isOpen"
        side="left"
        :ui="{
          width: 'w-screen max-w-[270px]',
        }"
      >
        <UCard
          :ui="{
            header: {
              padding: 'pb-0.5',
            },
            ring: '',
            rounded: '',
            shadow: '',
          }"
        >
          <template #header>
            <div class="w-full flex justify-end">
              <UButton
                color="gray"
                variant="ghost"
                icon="i-heroicons-x-mark-20-solid"
                class="-my-1"
                @click="isOpen = false"
              />
            </div>
          </template>
        </UCard>
        <PublicLogo
          :logo="logo"
          :staticURL="staticURL"
          class="text-center mx-auto mb-4"
        />
        <UVerticalNavigation
          :links="links"
          :ui="{
            inactive: 'after:hidden before:hidden',
            active: 'after:hidden before:hidden',
            padding: 'py-2',
          }"
        />
        <!-- <PublicTranslateHandler class="px-2 mt-3" /> -->
      </USlideover>
      <div class="flex items-center justify-between gap-2 lg:gap-6">
        <div class="block md:hidden">
          <UButton
            @click="isOpen = true"
            icon="i-ci-hamburger-md"
            variant="outline"
            color="gray"
          />
        </div>
        <PublicLogo :logo="logo" :staticURL="staticURL" class="mr-auto" />
        <div class="hidden md:block">
          <UHorizontalNavigation
            :links="links"
            class="border-b border-gray-200 dark:border-gray-800 text-lg"
            :ui="{
              wrapper: 'w-auto',
              label: 'text-base',
              active: 'after:hidden',
            }"
          />
        </div>
        <div v-if="!user">
          <UButton
            to="/auth/login/"
            label="Login/Register"
            color="gray"
            :ui="{
              size: {
                sm: 'text-xs md:text-sm',
              },
              padding: {
                sm: 'px-2 py-1 md:px-2.5 md:py-1.5',
              },
              icon: {
                size: {
                  sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
                },
              },
            }"
            size="md"
          >
            <template #trailing>
              <UIcon name="i-heroicons-arrow-right-20-solid" class="w-5 h-5" />
            </template>
          </UButton>
        </div>
        <div v-else class="flex relative menu-container">
          <!-- <PublicTranslateHandler class="px-2 max-sm:hidden" /> -->
          <UButton
            size="sm"
            color="primary"
            variant="outline"
            @click="openMenu = !openMenu"
            :ui="{
              size: {
                sm: 'text-xs md:text-sm',
              },
              padding: {
                sm: 'px-1.5 py-1 md:px-2.5 md:py-1.5',
              },
              icon: {
                size: {
                  sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
                },
              },
            }"
          >
            <UIcon name="i-heroicons-user-circle" class="text-xl" />
            {{ $t("my_account") }}
            <UIcon name="i-heroicons-chevron-down-16-solid" v-if="!openMenu" />
            <UIcon name="i-heroicons-chevron-up-16-solid" v-if="openMenu" />
          </UButton>
          <div
            class="absolute bg-slate-50 rounded-md py-3 px-2 top-10 right-3"
            :class="openMenu ? '' : 'hidden'"
          >
            <UVerticalNavigation
              :links="accountLinks"
              :ui="{
                label: 'text-base',
              }"
            />
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const { t } = useI18n();
const { user, logout } = useAuth();
const { get, staticURL } = useApi();
const openMenu = ref(false);
const router = useRouter();
const open = ref(true);
const logo = ref({});
const isOpen = ref(false);

async function getLogo() {
  const res = await get("/logo/");
  logo.value = res.data;
}

getLogo();

defineShortcuts({
  o: () => (open.value = !open.value),
});

const handleClickOutside = (event) => {
  const menuContainer = document.querySelector(".menu-container");
  if (menuContainer && !menuContainer.contains(event.target)) {
    openMenu.value = false;
  }
};

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
});

// if sidebar clicked and route changes, close sidebar if opened
watch(router.currentRoute, () => {
  if (openMenu.value) {
    openMenu.value = false;
    isOpen.value = false;
  }
});
useSeoMeta({
  ogImage: "/static/frontend/favicon.ico",
  favicon: "/static/frontend/favicon.ico",
  // title: "Easy Business Manager",
});
const links = [
  {
    label: t("home"),
    to: "/",
    icon: "i-heroicons:home",
  },
  {
    label: t("classified_service"),
    to: "#classified-services",
    icon: "i-heroicons:clipboard-document-list",
  },
  {
    label: t("earn_money"),
    to: "#micro-gigs",
    icon: "i-healthicons:money-bag-outline",
  },
  {
    label: t("faq"),
    to: "/coming-soon/",
    icon: "i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question",
  },
];

const accountLinks = [
  [
    {
      label: t("profile"),
      icon: "i-heroicons-user",
      to: "/my-account/",
    },
    {
      label: t("transaction"),
      to: "/deposit-withdraw",
      icon: "i-heroicons:currency-dollar",
    },
    {
      label: t("upload_center"),
      icon: "material-symbols:drive-folder-upload-outline-sharp",
      to: "/upload-center/",
    },
    {
      label: t("settings"),
      icon: "material-symbols:settings-outline",
      to: "/settings/",
    },
    {
      label: t("support"),
      icon: "i-heroicons-question-mark-circle",
      to: "/contact-us/",
    },
    {
      label: t("logout"),
      icon: "bitcoin-icons:exit-filled",
      click: () => {
        logout();
      },
    },
  ],
];
</script>
