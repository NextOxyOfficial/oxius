<template>
  <PublicSection>
    <AccountBalance v-if="user" :user="user" :isUser="true" />
  </PublicSection>
</template>
<script setup>
const { user } = useAuth();
</script>
