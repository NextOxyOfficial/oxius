<script setup lang="ts"></script>

<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">My Profile Details</h1>
      <UDivider label="" class="mb-8" />
      <form action="#" class="max-w-3xl mx-auto">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="mb-4">
            <UFormGroup label="First Name">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="First Name"
              />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="Last Name">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Last Name"
              />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="Address">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Address"
              />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="City">
              <UInput type="text" size="md" color="white" placeholder="City" />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="State">
              <UInput type="text" size="md" color="white" placeholder="State" />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="Zip">
              <UInput type="text" size="md" color="white" placeholder="Zip" />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="Phone">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Phone"
                readonly
              />
            </UFormGroup>
          </div>
          <div class="mb-4">
            <UFormGroup label="Email">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Email"
                readonly
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
      </form>
    </UContainer>
  </PublicSection>
</template>
