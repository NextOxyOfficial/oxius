<template>
  <UContainer class="mt-20 mb-12">
    <h1 class="text-center text-4xl my-8">Upload Center</h1>
    <UDivider label="" class="mb-8" />
    <div class="w-1/2">
      <p class="text-2xl font-medium mb-5">Upload Here</p>
      <UInput type="file" size="sm" icon="i-heroicons-folder" />
    </div>
    <div>
      <UButton
        class="mt-8"
        size="md"
        color="primary"
        variant="solid"
        label="Upload"
      />
    </div>
  </UContainer>
</template>
