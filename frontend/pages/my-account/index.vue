<script setup lang="ts">
const links = [
  [
    {
      label: 'Profile',
      icon: 'i-heroicons-user',
      badge: 100,
    },
    {
      label: 'Payments',
      icon: 'i-heroicons-wallet',
      to: '/getting-started/installation',
    },
    {
      label: 'Upload Center',
      icon: 'material-symbols:drive-folder-upload-outline-sharp',
      to: '/components/vertical-navigation',
    },
    // {
    //   label: 'Command Palette',
    //   icon: 'i-heroicons-command-line',
    //   to: '/components/command-palette',
    // },

    {
      label: 'Settings',
      icon: 'material-symbols:settings-outline',
    },
    {
      label: 'Support',
      icon: 'i-heroicons-question-mark-circle',
    },
    {
      label: 'Logout',
      icon: 'bitcoin-icons:exit-filled',
    },
  ],
];
</script>

<template>
  <UContainer>
    <UVerticalNavigation
      :links="links"
      :ui="{
        label: 'text-base',
      }"
    />
  </UContainer>
</template>
