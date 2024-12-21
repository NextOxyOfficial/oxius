<template>
  <PublicSection>
    <UContainer v-if="!loading">
      <h1 class="text-center text-4xl my-8">My Profile Details</h1>
      <UDivider label="" class="mb-8" />
      <form action="#" class="max-w-lg mx-auto" @submit.prevent="handleForm">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
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
    <div v-else>
      <NuxtLoadingIndicator class="!opacity-[1]" />
      <section
        class="h-screen w-screen flex items-center justify-center"
        v-if="!user"
      >
        <UIcon
          name="svg-spinners:bars-scale-middle"
          dynamic
          class="text-xl w-12 h-12 text-primary"
        />
      </section>
    </div>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { get, put, patch } = useApi();
const { user } = useAuth();
const userProfile = ref({});
const toast = useToast();
console.log(user.value);

async function getUserDetails() {
  const res = await get(`/persons/${user.value.user.email}/`);
  userProfile.value = res.data;
}

onMounted(() => {
  getUserDetails();
});

async function handleForm() {
  const { groups, user_permissions, ...rest } = userProfile.value;
  console.log(rest);

  const res = await put(`/persons/update/${userProfile.value.email}/`, rest);
  console.log(res, "result");

  if (res.data.data.email) {
    toast.add({ title: res.data.message });
  }
  userProfile.value = res.data.data;
}
</script>
