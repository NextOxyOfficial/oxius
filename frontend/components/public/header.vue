<template>
  <div class="my-3">
    <UContainer>
      <div class="flex items-center justify-between gap-6">
        <NuxtLink to="/">
          <NuxtImg src="/images/logo.jpg" alt="Logo" />
        </NuxtLink>
        <UHorizontalNavigation
          :links="links"
          class="border-b border-gray-200 dark:border-gray-800 text-lg"
          :ui="{
            wrapper: 'w-auto',
            label: 'text-base',
          }"
        />

        <div v-if="!user">
          <UButton to="/auth/login/" label="Login/Register" color="gray">
            <template #trailing>
              <UIcon name="i-heroicons-arrow-right-20-solid" class="w-5 h-5" />
            </template>
          </UButton>
        </div>
        <div v-else class="flex gap-1">
          <UButton
            to="/my-account/"
            size="md"
            color="primary"
            variant="outline"
            label="My Account"
          />
          <UButton
            icon="i-heroicons-bell-solid"
            size="md"
            color="primary"
            variant="solid"
            label="Logout"
            @click="logout"
          />
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const { user, logout } = useAuth();

const open = ref(true);

defineShortcuts({
  o: () => (open.value = !open.value),
});
const links = [
  {
    label: "Home",
    avatar: {
      src: "https://avatars.githubusercontent.com/u/739984?v=4",
    },
    badge: 100,
    to: "/",
  },
  {
    label: "Classified Services",
    icon: "i-heroicons-home",
    to: "/getting-started/installation",
  },
  {
    label: "Earn Money",
    icon: "i-heroicons-chart-bar",
    to: "/components/horizontal-navigation",
  },
  {
    label: "FAQ",
    icon: "i-heroicons-command-line",
    to: "/components/command-palette",
  },
];
</script>
