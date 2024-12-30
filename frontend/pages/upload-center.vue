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
      <p class="text-sm md:text-base font-medium mb-2">NID Front</p>
      <div class="flex flex-wrap gap-5">
        <div class="relative max-w-[200px] max-h-[200px]" v-if="form.front">
          <img :src="form.front" :alt="`Uploaded file `" class="h-full" />
          <div
            class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
            @click="deleteUpload('front')"
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
            @change="handleFileUpload($event, 'front')"
          />
          <UInput
            type="file"
            size="xs"
            icon="i-heroicons-folder"
            class="cursor-default"
          />
        </div>
      </div>
      <p class="text-sm text-red-500" v-if="errors.front">NID front required</p>
      <p class="text-sm md:text-base font-medium mb-2">NID Back</p>
      <div class="flex flex-wrap gap-5">
        <div class="relative max-w-[200px] max-h-[200px]" v-if="form.back">
          <img :src="form.back" :alt="`Uploaded file `" class="h-full" />
          <div
            class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
            @click="deleteUpload('back')"
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
            @change="handleFileUpload($event, 'back')"
          />
          <UInput
            type="file"
            size="xs"
            icon="i-heroicons-folder"
            class="cursor-default"
          />
        </div>
      </div>
      <p class="text-sm text-red-500" v-if="errors.back">NID back required</p>
    </div>
    <div>
      <UButton
        :disabled="Boolean(formData.id)"
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
const { get, put, post, staticURL } = useApi();
const { user } = useAuth();
const form = ref({
  front: null,
  back: null,
});
const errors = ref({});
const formData = ref({});

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    form.value[field] = reader.result;
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
}

function deleteUpload(field) {
  form.value[field] = null;
}

async function handleUploadSubmit() {
  // Reset validation errors
  errors.value.front = !form.value.front;
  errors.value.back = !form.value.back;

  // Check if validation failed
  if (errors.value.front || errors.value.back) {
    toast.add({
      title: "Please fill in all required fields.",
      type: "error",
    });
    return;
  }
  try {
    const res = await post(`/add-user-nid/`, form.value);

    if (res.data?.message) {
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

async function get_nid() {
  try {
    const { data } = await get("/get-user-nid/");

    if (data) {
      form.value = {
        front: staticURL + data.data.front,
        back: staticURL + data.data.back,
      };
      formData.value = data.data;
    }
  } catch (error) {
    console.log(error);
  }
}

get_nid();
</script>
