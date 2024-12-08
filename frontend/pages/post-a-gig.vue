<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Post A Gig</h1>
      <UDivider label="" class="mb-8" />
      <form action="#" class="max-w-2xl mx-auto space-y-3">
        <UFormGroup label="Title">
          <UInput
            type="text"
            size="md"
            color="white"
            class="relative"
            placeholder="Title"
            :ui="{
              size: {
                md: 'text-base',
              },
              padding: { md: 'pl-[60px]' },
            }"
          >
            <span class="absolute left-2 top-2">I Need</span>
          </UInput>
        </UFormGroup>
        <div class="flex gap-4 items-center">
          <UFormGroup label="Budget Per Action">
            <UInput
              icon="i-mdi:currency-bdt"
              type="text"
              size="md"
              color="white"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              placeholder="2.0"
              class="max-w-40"
              v-model="form.price"
            />
          </UFormGroup>
          <UFormGroup label="Required Quantity">
            <UInput
              type="text"
              size="md"
              color="white"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              placeholder="10"
              class="max-w-40"
              v-model="form.required_quantity"
            />
          </UFormGroup>
          <UFormGroup label="*">
            <p>=</p>
          </UFormGroup>
          <UFormGroup label="Total Cost">
            <p>{{ form.price * form.required_quantity }}</p>
          </UFormGroup>
        </div>
        <UFormGroup label="Instruction">
          <UTextarea
            color="white"
            variant="outline"
            :ui="{
              size: {
                md: 'text-base',
              },
            }"
            class="w-full"
            resize
            placeholder="Instruction"
          />
        </UFormGroup>
        <UFormGroup label="Upload Photo/Video">
          <input
            type="file"
            name=""
            id=""
            @change="handleFileUpload($event, 'image')"
          />
        </UFormGroup>
        <div v-if="form.uploads?.length">
          <div v-for="(img, i) in form.uploads" :key="i" class="flex gap-5">
            <div class="relative">
              <img
                :src="img.preview"
                :alt="`Uploaded file ${img.preview + 1}`"
                style="max-width: 200px; margin: 5px"
              />
              <div
                class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
                @click="deleteUpload(i)"
              >
                <UIcon name="i-heroicons-trash-solid" class="text-red-500" />
              </div>
            </div>
          </div>
        </div>
        <!-- <UFormGroup label="Upload Photo/Video">
          <UInput
            type="file"
            size="md"
            color="white"
            :ui="{
              color: {
                white: {
                  outline: 'ring-0',
                },
              },
              size: {
                md: 'text-base',
              },
            }"
            placeholder="Budget Per Action"
            class="max-w-72"
          />
        </UFormGroup> -->
        <div class="grid md:grid-cols-2 gap-4">
          <UFormGroup label="Target Country">
            <USelectMenu
              v-model="form.target_country"
              color="white"
              size="md"
              placeholder="Target Country"
              :options="['Bangladesh']"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
            />
          </UFormGroup>
          <UFormGroup label="Target Device">
            <USelectMenu
              v-model="form.target_device"
              color="white"
              size="md"
              placeholder="Target Device"
              multiple
              :options="['All', 'iPhone', 'Android', 'Windows', 'Linux']"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
            />
          </UFormGroup>
        </div>
        <div class="grid md:grid-cols-2 gap-4">
          <UFormGroup label="Target Network">
            <USelectMenu
              v-model="form.target_network"
              size="md"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              :options="['WiFi', 'Cellular']"
              multiple
              placeholder="Target Network"
            />
          </UFormGroup>
          <UFormGroup label="Category">
            <USelectMenu
              v-model="form.category"
              color="white"
              size="md"
              :options="['Youtube', 'Facebook']"
              placeholder="Target Country"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
            />
          </UFormGroup>
        </div>

        <div class="text-center">
          <UButton
            class="px-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            type="submit"
          />
        </div>
      </form>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const form = ref({
  price: 0,
  required_quantity: 0,
  uploads: [],
  target_country: "",
  target_device: "",
  target_network: "",
  category: "",
});
function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  files.forEach((file) => {
    const preview = URL.createObjectURL(file);
    form.value.uploads.push({ file, preview });
  });
}

function deleteUpload(index) {
  // Revoke object URL to free memory
  URL.revokeObjectURL(form.value.uploads[index].preview);

  // Remove the file from the array
  form.value.uploads.splice(index, 1);
}
</script>

<style scoped></style>
