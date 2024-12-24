<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">My Profile Details</h1>
      <UDivider label="" class="mb-8" />
      <form action="#" class="max-w-lg mx-auto" @submit.prevent="handleForm">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="col-span-2">
            <label for="file" class="text-base block mt-8 mb-3 font-semibold"
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
                  class="rounded-full size-[100px] object-cover"
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
                <UInput type="file" size="xs" icon="i-heroicons-folder" />
              </div>
            </div>
          </div>
          <div>
            <UFormGroup label="First Name">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="First Name"
                v-model="userProfile.first_name"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="Last Name">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Last Name"
                v-model="userProfile.last_name"
              />
            </UFormGroup>
          </div>
          <div class="col-span-2">
            <UFormGroup label="Address">
              <UInput
                color="white"
                variant="outline"
                class="w-full"
                resize
                placeholder="Address"
                v-model="userProfile.address"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="Email">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Phone"
                v-model="userProfile.email"
                readonly
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="City">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="City"
                v-model="userProfile.city"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="State">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="State"
                v-model="userProfile.state"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="Zip">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Zip"
                v-model="userProfile.zip"
              />
            </UFormGroup>
          </div>

          <div>
            <UFormGroup label="Phone">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Phone"
                v-model="userProfile.phone"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="Facebook Url">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Facebook Url"
                v-model="userProfile.face_link"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="Instagram Url">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Instagram Url"
                v-model="userProfile.instagram_link"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup label="WhatsApp #">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="WhatsApp #"
                v-model="userProfile.whatsapp_link"
              />
            </UFormGroup>
          </div>

          <div class="col-span-2">
            <UFormGroup label="About Me">
              <UTextarea
                color="white"
                variant="outline"
                class="w-full"
                v-model="userProfile.about"
                resize
                placeholder="Please provide information about your self, profession and services so that public can read about you and find interest"
              />
            </UFormGroup>
          </div>
        </div>
        <div class="text-center mt-12">
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

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { get, put, patch, staticURL } = useApi();
const { user } = useAuth();
const userProfile = ref({});
const toast = useToast();

async function getUserDetails() {
  const res = await get(`/persons/${user.value.user.email}/`);
  userProfile.value = res.data;
}

onMounted(() => {
  getUserDetails();
});

async function handleForm() {
  const { groups, user_permissions, image, nid, ...rest } = userProfile.value;
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
  console.log(rest);

  try {
    const res = await put(`/persons/update/${userProfile.value.email}/`, rest);
    console.log(res, "result");

    if (res.data?.data?.email) {
      toast.add({ title: res.data?.message });
      res.data.data.image = staticURL + res.data.data.image;
      userProfile.value = res.data.data;
    }
  } catch (error) {
    toast.add({ title: error });
  }
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
