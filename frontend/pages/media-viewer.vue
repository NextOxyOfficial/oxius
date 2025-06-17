<template>
  <PublicSection>
    <h1 class="text-center text-2xl my-8">Image / Video</h1>
    <UContainer>
      <UCard>
        <NuxtImg
          :src="router.query.url"
          class="w-full max-w-xl mx-auto"
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
</script>

<style scoped></style>
