<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">{{ $t("settings") }}</h1>
      <UDivider label="" class="mb-8" />
      <h2 class="text-2xl my-4 md:text-center">পাসওয়ার্ড পরিবর্তন</h2>
      <form action="#" class="max-w-3xl mx-auto">
        <UCard
          :ui="{
            background: 'bg-green-50/50',
            ring: 'border border-dashed border-green-500',

            shadow: 'shadow-md',
            body: {
              padding: 'px-4 py-2 sm:p-6',
            },
          }"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="">
              <UFormGroup
                label="পুরাতন পাসওয়ার্ড"
                :ui="{
                  label: {
                    base: 'block font-medium text-gray-700 dark:text-slate-700',
                  },
                }"
              >
                <UInput
                  size="md"
                  color="white"
                  type="password"
                  placeholder="********"
                  :ui="{
                    placeholder:
                      'placeholder-gray-400 dark:placeholder-gray-200',
                  }"
                />
              </UFormGroup>
            </div>
            <div class="mb-4">
              <UFormGroup
                label="নতুন পাসওয়ার্ড"
                :ui="{
                  label: {
                    base: 'block font-medium text-gray-700 dark:text-slate-700',
                  },
                }"
              >
                <UInput
                  type="password"
                  size="md"
                  color="white"
                  placeholder="********"
                  :ui="{
                    placeholder:
                      'placeholder-gray-400 dark:placeholder-gray-200',
                  }"
                />
              </UFormGroup>
            </div>
          </div>
          <div class="text-center mt-4">
            <UButton
              class="px-8"
              size="lg"
              color="primary"
              variant="solid"
              label="Save"
              type="submit"
            />
          </div>
        </UCard>
      </form>
    </UContainer>
  </PublicSection>
</template>

<script setup></script>

<style scoped></style>
