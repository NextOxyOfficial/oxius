<template>
  <div class="my-3 sticky z-50 top-0 bg-white">
    <UContainer>
      <div class="flex items-center justify-between gap-6">
        <NuxtLink to="/">
          <NuxtImg
            v-if="logo?.image"
            :src="'http://127.0.0.1:8000/' + logo?.image"
            alt="Logo"
            class="h-12"
          />
          <NuxtImg v-else src="/images/logo.jpg" alt="Logo" />
        </NuxtLink>
        <UHorizontalNavigation
          :links="links"
          class="border-b border-gray-200 dark:border-gray-800 text-lg"
          :ui="{
            wrapper: 'w-auto',
            label: 'text-base',
            active: 'after:hidden',
          }"
        />

        <div v-if="!user">
          <UButton to="/auth/login/" label="Login/Register" color="gray">
            <template #trailing>
              <UIcon name="i-heroicons-arrow-right-20-solid" class="w-5 h-5" />
            </template>
          </UButton>
        </div>
        <div v-else class="flex relative">
          <UButton
            size="md"
            color="primary"
            variant="outline"
            @click="openMenu = !openMenu"
          >
            <UIcon name="i-heroicons-user-circle" class="text-xl" /> My Account
            <UIcon name="i-heroicons-chevron-down-16-solid" v-if="!openMenu" />
            <UIcon name="i-heroicons-chevron-up-16-solid" v-if="openMenu" />
          </UButton>
          <div
            class="absolute bg-slate-50 rounded-md py-3 px-2 top-10"
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
const { user, logout } = useAuth();
const { get } = useApi();
const openMenu = ref(false);
const router = useRouter();
const open = ref(true);
const logo = ref({});

async function getLogo() {
  const res = await get("/logo/");
  console.log(res);

  logo.value = res.data;
}

getLogo();

defineShortcuts({
  o: () => (open.value = !open.value),
});

// if sidebar clicked and route changes, close sidebar if opened
watch(router.currentRoute, () => {
  if (openMenu.value) {
    openMenu.value = false;
  }
});
// useSeoMeta({
// 	ogImage: "/static/favicon.ico",
// 	favicon: "/static/favicon.ico",
// 	title: "Easy Business Manager",
// });
const links = [
  {
    label: "Home",
    to: "/",
    icon: "i-heroicons:home",
  },
  {
    label: "Classified Services",
    to: "#classified-services",
    icon: "i-heroicons:clipboard-document-list",
  },
  {
    label: "Earn Money",
    to: "#micro-gigs",
    icon: "i-healthicons:money-bag-outline",
  },
  {
    label: "FAQ",
    to: "/faq",
    icon: "i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question",
  },
];

const accountLinks = [
  [
    {
      label: "Profile",
      icon: "i-heroicons-user",
      to: "/my-account/",
    },
    {
      label: "Upload Center",
      icon: "material-symbols:drive-folder-upload-outline-sharp",
      to: "/upload-center/",
    },
    {
      label: "Settings",
      icon: "material-symbols:settings-outline",
      to: "/settings/",
    },
    {
      label: "Support",
      icon: "i-heroicons-question-mark-circle",
      to: "/contact-us/",
    },
    {
      label: "Logout",
      icon: "bitcoin-icons:exit-filled",
      click: () => {
        logout();
      },
    },
  ],
];
</script>
