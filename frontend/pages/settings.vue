<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Settings</h1>
      <UDivider label="" class="mb-8" />
      <form action="#" class="max-w-3xl mx-auto">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="mb-4">
            <UFormGroup label="Old Password">
              <UInput
                size="md"
                color="white"
                type="password"
                placeholder="********"
              />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="New Password">
              <UInput
                type="password"
                size="md"
                color="white"
                placeholder="********"
              />
            </UFormGroup>
          </div>
        </div>
        <div class="text-center mt-4 mb-20">
          <UButton
            class="px-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Save"
            type="submit"
          />
        </div>
      </form>
    </UContainer>
  </PublicSection>
</template>

<script setup></script>

<style scoped></style>
