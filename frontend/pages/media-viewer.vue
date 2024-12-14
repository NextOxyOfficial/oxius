<template>
  <PublicSection>
    <h1 class="text-center text-4xl my-8">Gig Media</h1>
    <UContainer>
      <UCard>
        <NuxtImg
          :src="router.query.url"
          class="w-full max-w-xl"
          v-if="router.query.type == 'image'"
        />

        <video
          :src="router.query.url"
          class="w-full max-w-xl"
          v-if="router.query.type == 'video'"
          controls
          autoplay
        ></video>
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const router = useRoute();
console.log(router);
</script>

<style scoped></style>
