<template>
  <UContainer class="mt-20 mb-12">
    <h1 class="text-center text-4xl my-8">Upload Center</h1>
    <UDivider label="" class="mb-8" />
    <div class="w-1/2">
      <div class="flex gap-1 items-center mb-3">
        <span v-if="user.user.kyc" class="font-semibold">{{
          user.user.name
        }}</span>
        <span v-else class="text-red-500">* KYC Unverified</span>
        <UIcon
          v-if="user.user.kyc"
          name="mdi:check-decagram"
          class="w-5 h-5 text-blue-600"
        />
      </div>
      <p class="text-lg md:text-xl font-medium mb-5">Upload Document</p>
      <div class="flex flex-wrap gap-5">
        <div
          class="relative max-w-[200px] max-h-[200px]"
          v-for="(img, i) in form.nid"
          :key="i"
        >
          <img :src="img" :alt="`Uploaded file ${i}`" class="h-full" />
          <div
            class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
            @click="deleteUpload(i)"
          >
            <UIcon name="i-heroicons-trash-solid" class="text-red-500" />
          </div>
        </div>
        <div
          class="w-full h-full border flex items-center justify-center max-w-[200px] max-h-[200px] relative"
        >
          <input
            type="file"
            name=""
            id=""
            class="h-full w-full absolute left-0 top-0 z-10 cursor-pointer opacity-0"
            @change="handleFileUpload($event, 'image')"
          />
          <UInput
            type="file"
            size="xs"
            icon="i-heroicons-folder"
            class="cursor-default"
          />
        </div>
      </div>
    </div>
    <div>
      <UButton
        class="mt-8"
        size="md"
        color="primary"
        variant="solid"
        label="Submit"
        @click="handleUploadSubmit"
      />
    </div>
  </UContainer>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const toast = useToast();
const { put } = useApi();
const { user } = useAuth();
const form = ref({
  nid: [],
});

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    form.value.nid.push(reader.result);
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
}

function deleteUpload(ind) {
  if (ind >= 0 && ind < form.value.nid.length) {
    form.value.nid.splice(ind, 1);
  }
}
console.log(user.value.user.email);

async function handleUploadSubmit() {
  // Check if nid is empty
  if (!form.value.nid.length) {
    toast.add({ title: "Please upload your NID before submitting." });
    return;
  }
  try {
    const res = await put(`/persons/update/${user.value.user.email}/`, {
      nid: form.value.nid,
    });

    if (res.data.message) {
      toast.add({ title: res.data.message, type: "success" });
    }
  } catch (error) {
    console.error("Error during submission:", error);
    toast.add({
      title: "An error occurred. Please try again later.",
      type: "error",
    });
  }
}
</script>
