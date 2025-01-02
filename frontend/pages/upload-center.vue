<template>
  <UContainer class="mt-20 mb-12">
    <h1 class="text-center text-4xl my-8">{{ $t("upload_center") }}</h1>
    <UDivider label="" class="mb-8" />
    <ul class="mb-4 space-y-1 text-sm font-medium">
      <li>
        This is the upload center where you can upload documents for
        verification purposes.
      </li>
      <li>You can upload NID front, back, and selfie.</li>
      <li>We accept NID, Passport, Driving License, Birth Certificate.</li>
      <li>
        After uploading, you will be able to review and approve the documents.
      </li>
    </ul>
    <div class="w-2/3 sm:w-1/2 max-sm:mx-auto" v-if="form && !form?.pending">
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

      <template v-if="!id_verification">
        <p class="text-sm md:text-base font-medium mb-2">ID Front</p>
        <div class="flex flex-wrap flex-col gap-5">
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
            v-if="!form.front"
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
        <p class="text-sm text-red-500" v-if="errors.front">
          ID front is required
        </p>
        <p class="text-sm md:text-base font-medium mb-2 mt-6">ID Back</p>
        <div class="flex flex-wrap flex-col gap-5">
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
            v-if="!form.back"
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
        <p class="text-sm text-red-500" v-if="errors.back">
          ID back is required
        </p>
        <p class="text-sm md:text-base font-medium mb-2 mt-6">
          Selfie with document
        </p>
        <div class="flex flex-wrap flex-col gap-5">
          <div class="relative max-w-[200px] max-h-[200px]" v-if="form.selfie">
            <img :src="form.selfie" :alt="`Uploaded file `" class="h-full" />
            <div
              class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
              @click="deleteUpload('selfie')"
            >
              <UIcon name="i-heroicons-trash-solid" class="text-red-500" />
            </div>
          </div>
          <div
            v-if="!form.selfie"
            class="w-full h-full border flex items-center justify-center max-w-[200px] max-h-[200px] relative"
          >
            <input
              type="file"
              name=""
              id=""
              class="h-full w-full absolute left-0 top-0 z-10 cursor-pointer opacity-0"
              @change="handleFileUpload($event, 'selfie')"
            />
            <UInput
              type="file"
              size="xs"
              icon="i-heroicons-folder"
              class="cursor-default"
            />
          </div>
        </div>

        <p class="text-sm text-red-500" v-if="errors.selfie">
          Selfie with ID is required.
        </p>
      </template>

      <UDivider label="" class="my-3" />
      <p class="text-sm md:text-base font-medium mb-2 mt-6">Other document</p>
      <div class="flex flex-wrap flex-col gap-5">
        <div
          class="relative max-w-[200px] max-h-[200px]"
          v-if="form.other_document"
        >
          <img
            :src="form.other_document"
            :alt="`Uploaded file `"
            class="h-full"
          />
          <div
            class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
            @click="deleteUpload('other_document')"
          >
            <UIcon name="i-heroicons-trash-solid" class="text-red-500" />
          </div>
        </div>
        <div
          v-if="!form.other_document"
          class="w-full h-full border flex items-center justify-center max-w-[200px] max-h-[200px] relative"
        >
          <input
            type="file"
            name=""
            id=""
            class="h-full w-full absolute left-0 top-0 z-10 cursor-pointer opacity-0"
            @change="handleFileUpload($event, 'other_document')"
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
    <div v-else>
      <UCard>
        <div>
          <div
            className="rounded-full bg-yellow-100 p-3 mb-4 max-w-16 flex items-center justify-center mx-auto"
          >
            <!-- <AlertCircle className="h-8 w-8 text-yellow-600" /> -->
            <UIcon
              name="i-line-md-alert-circle"
              class="h-8 w-8 text-yellow-600 mx-auto"
            />
          </div>
          <h4
            class="text-center text-xl my-4 flex items-center justify-center gap-2"
          >
            ID Verification is pending
          </h4>
        </div>
      </UCard>
    </div>
    <div class="text-center">
      <UButton
        v-if="!form.pending"
        :loading="isLoading"
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
const isLoading = ref(false);
const { user } = useAuth();
const id_verification = ref(false);
const form = ref({
  front: null,
  back: null,
  selfie: null,
  other_document: null,
});
const errors = ref({
  front: false,
  back: false,
  selfie: false,
});

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
  errors.value.selfie = !form.value.selfie;

  // Check if validation failed
  if (errors.value.front || errors.value.back || errors.value.selfie) {
    toast.add({
      title: "Please fill in all required fields.",
      type: "error",
    });
    return;
  }
  isLoading.value = true;
  try {
    const res = await post(`/add-user-nid/`, form.value);

    if (res.data?.message) {
      toast.add({ title: res.data.message, type: "success" });
      form.value = res.data.data;
    }
  } catch (error) {
    console.error("Error during submission:", error);
    toast.add({
      title: "An error occurred. Please try again later.",
      type: "error",
    });
  }
  isLoading.value = false;
}

async function get_nid() {
  try {
    const { data } = await get("/get-user-nid/");

    if (data) {
      form.value = data.data;
      console.log(data.data);

      id_verification.value = Boolean(data.data.approved);

      form.value = {
        front: staticURL + data.data.front,
        back: staticURL + data.data.back,
        selfie: staticURL + data.data.selfie,
        other_document: data.data.other_document
          ? staticURL + data.data.other_document
          : data.data.other_document,
      };
    }
  } catch (error) {
    console.log(error);
  }
}

get_nid();
</script>
