<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-2xl my-8">{{ $t("my_profile_details") }}</h1>
      <UDivider label="" class="mb-8" />
      <div class="text-center flex gap-1 items-center justify-center mb-3">
        <span v-if="user.user.name" class="font-semibold">{{
          user.user.name
        }}</span>
        <UIcon
          v-if="user.user.kyc"
          name="mdi:check-decagram"
          class="w-5 h-5 text-blue-600"
        />
      </div>
      <form
        action="#"
        class="max-w-xl mx-auto border border-gray-100 p-2 md:p-3 rounded-xl bg-white"
        @submit.prevent="handleForm"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="col-span-2">
            <label for="file" class="text-base block mb-3 font-semibold"
              >Profile Image</label
            >
            <div class="flex flex-wrap gap-5">
              <div
                class="relative max-w-[200px] max-h-[200px]"
                v-if="userProfile.image"
              >
                <img
                  :src="userProfile.image"
                  :alt="`Uploaded profile image`"
                  class="rounded-full size-[100px] object-contain"
                />
                <div
                  class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
                  @click="deleteUpload(i)"
                >
                  <UIcon name="i-heroicons-trash-solid" class="text-red-500" />
                </div>
              </div>

              <div
                class="w-full h-full flex items-center justify-center max-w-[200px] max-h-[200px] relative pt-7"
              >
                <input
                  type="file"
                  name=""
                  id=""
                  class="h-full w-full absolute left-0 top-0 z-10 cursor-pointer opacity-0"
                  @change="handleFileUpload($event, 'image')"
                />
                <!-- <UIcon
                  name="i-material-symbols:drive-folder-upload-outline"
                  size="66"
                /> -->
                <UInput
                  type="file"
                  size="xs"
                  class="pointer-events-none"
                  icon="i-heroicons-folder"
                />
              </div>
            </div>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="First Name"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="First Name"
                v-model="userProfile.first_name"
                :disabled="user.user.kyc"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="Last Name"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Last Name"
                v-model="userProfile.last_name"
                :disabled="user.user.kyc"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2">
            <UFormGroup
              label="Address"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                :disabled="user.user.kyc"
                color="white"
                variant="outline"
                class="w-full"
                resize
                placeholder="Address"
                v-model="userProfile.address"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="Email"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Phone"
                v-model="userProfile.email"
                readonly
                :disabled="user.user.kyc"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="City"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="City"
                :disabled="user.user.kyc"
                v-model="userProfile.city"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="State"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                :disabled="user.user.kyc"
                type="text"
                size="md"
                color="white"
                placeholder="State"
                v-model="userProfile.state"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="Zip"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                :disabled="user.user.kyc"
                type="text"
                size="md"
                color="white"
                placeholder="Zip"
                v-model="userProfile.zip"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>

          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="Phone"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                :disabled="user.user.kyc"
                readonly
                type="text"
                size="md"
                color="white"
                placeholder="Phone"
                v-model="userProfile.phone"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
            <p
              class="text-sm text-red-500 first-letter:capitalize"
              v-if="errors?.phone"
            >
              {{ errors.phone[0] }}
            </p>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="Facebook Url"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Facebook Url"
                v-model="userProfile.face_link"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="Instagram Url"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Instagram Url"
                v-model="userProfile.instagram_link"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2 md:col-auto">
            <UFormGroup
              label="WhatsApp #"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="WhatsApp #"
                v-model="userProfile.whatsapp_link"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>

          <div class="col-span-2">
            <UFormGroup
              label="About Me"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
                },
              }"
            >
              <UTextarea
                color="white"
                variant="outline"
                class="w-full"
                v-model="userProfile.about"
                resize
                placeholder="Please provide information about your self, profession and services so that public can read about you and find interest"
                :ui="{
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
              />
            </UFormGroup>
          </div>
        </div>
        <div class="text-center mt-12">
          <UButton
            class="px-8"
            size="lg"
            :loading="isLoading"
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

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { get, put } = useApi();
const { user } = useAuth();
const userProfile = ref({});
const toast = useToast();
const errors = ref({});
const isLoading = ref(false);

async function getUserDetails() {
  const res = await get(`/persons/${user.value.user.email}/`);
  userProfile.value = res.data;
}

onMounted(() => {
  getUserDetails();
});

async function handleForm() {
  const { groups, user_permissions, image, nid, refer, ...rest } =
    userProfile.value;
  rest.name = userProfile.value.first_name + " " + userProfile.value.last_name;
  if (typeof image === "string") {
    if (image.includes("data:image")) {
      rest.image = image;
    } else {
      console.log("Image type is string; omitting from request.");
    }
  } else if (image === null) {
    console.log("Image type is string; omitting from request.");
  } else {
    rest.image = image;
  }

  isLoading.value = true;
  try {
    const res = await put(`/persons/update/${userProfile.value.email}/`, rest);

    if (res.data?.data?.email) {
      toast.add({ title: res.data?.message });
      res.data.data.image = res.data.data.image ? res.data.data.image : null;
      userProfile.value = res.data.data;
      errors.value = {};
    } else {
      errors.value = res?.error?.data.errors;
    }
  } catch (error) {
    toast.add({ title: error });
  }
  isLoading.value = false;
}

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    userProfile.value.image = reader.result;
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
}

function deleteUpload(ind) {
  userProfile.value.image = null;
}
</script>
