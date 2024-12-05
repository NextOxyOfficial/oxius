<template>
  <div>
    <UContainer>
      <div class="flex items-center justify-between gap-6">
        <a href="/">
          <NuxtImg src="/images/logo.jpg" alt="Logo" />
        </a>
        <UHorizontalNavigation
          :links="links"
          class="border-b border-gray-200 dark:border-gray-800"
          :ui="{
            wrapper: 'w-auto',
          }"
        />
        <div>
          <p class="font-bold">Balance: 500 BDT</p>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const links = [
  {
    label: "Profile",
    avatar: {
      src: "https://avatars.githubusercontent.com/u/739984?v=4",
    },
    badge: 100,
  },
  {
    label: "Installation",
    icon: "i-heroicons-home",
    to: "/getting-started/installation",
  },
  {
    label: "Horizontal Navigation",
    icon: "i-heroicons-chart-bar",
    to: "/components/horizontal-navigation",
  },
  {
    label: "Command Palette",
    icon: "i-heroicons-command-line",
    to: "/components/command-palette",
  },
];
</script>
