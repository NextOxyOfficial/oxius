<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Post A Gig</h1>
      <UDivider label="" class="mb-8" />
      <form
        action="#"
        class="max-w-2xl mx-auto space-y-3"
        @submit.prevent="handlePostGig"
      >
        <UFormGroup
          label="Title"
          required
          v-slot="{ error }"
          :error="!form.title && checkSubmit && 'You must enter a title!'"
        >
          <UInput
            type="text"
            size="md"
            color="white"
            class="relative"
            placeholder="Title"
            v-model="form.title"
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
          <UFormGroup
            label="Budget Per Action"
            required
            v-slot="{ error }"
            :error="
              form.price <= 0 &&
              checkSubmit &&
              'You must enter budget per action!'
            "
          >
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
          <UFormGroup
            label="Required Quantity"
            required
            v-slot="{ error }"
            :error="
              form.required_quantity <= 0 &&
              checkSubmit &&
              'You must enter required quantity!'
            "
          >
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
        <UFormGroup
          label="Instructions"
          required
          v-slot="{ error }"
          :error="
            !form.instructions && checkSubmit && 'You must enter instructions!'
          "
        >
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
            placeholder="Instructions"
            v-model="form.instructions"
          />
        </UFormGroup>

        <!-- medias  -->
        <label for="" class="block mt-3 font-semibold"
          >Upload Photo/Video</label
        >
        <div class="flex flex-wrap gap-5">
          <div
            class="relative max-w-[200px] max-h-[200px]"
            v-for="(img, i) in form.medias"
            :key="i"
          >
            <img :src="img" :alt="`Uploaded file ${i}`" />
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
            <UIcon name="i-heroicons-plus-solid" size="66" />
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
          <UFormGroup
            label="Target Country"
            required
            v-slot="{ error }"
            :error="
              !form.target_country &&
              checkSubmit &&
              'You must select a target country!'
            "
          >
            <USelectMenu
              v-model="form.target_country"
              color="white"
              size="md"
              placeholder="Target Country"
              :options="country"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="title"
              value-attribute="title"
            />
          </UFormGroup>
          <UFormGroup
            label="Target Device"
            required
            v-slot="{ error }"
            :error="
              !form.target_device &&
              checkSubmit &&
              'You must select a target device!'
            "
          >
            <USelectMenu
              v-model="form.target_device"
              color="white"
              size="md"
              placeholder="Target Device"
              multiple
              :options="device"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="title"
              value-attribute="id"
            />
          </UFormGroup>
        </div>
        <div class="grid md:grid-cols-2 gap-4">
          <UFormGroup
            label="Target Network"
            required
            v-slot="{ error }"
            :error="
              !form.target_network &&
              checkSubmit &&
              'You must select a target network!'
            "
          >
            <USelectMenu
              v-model="form.target_network"
              size="md"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              :options="network"
              multiple
              placeholder="Target Network"
              option-attribute="title"
              value-attribute="id"
            />
          </UFormGroup>
          <UFormGroup
            label="Category"
            required
            v-slot="{ error }"
            :error="
              !form.category && checkSubmit && 'You must select a category!'
            "
          >
            <USelectMenu
              v-model="form.category"
              color="white"
              size="md"
              :options="categories"
              placeholder="Target Category"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="title"
              value-attribute="id"
            />
          </UFormGroup>
        </div>

        <div class="text-center">
          <UButton
            v-if="user.user.kyc"
            class="px-8 mt-10"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            type="submit"
          />
          <UButton
            v-else
            class="px-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            @click="isOpen = true"
          />
        </div>
      </form>
    </UContainer>
    <UModal v-model="isOpen">
      <div class="p-4 text-center space-y-3">
        <h3 class="text-lg font-semibold">KYC Validation Failed!</h3>
        <p>Please Upload your NID to get permission to post a service ad.</p>

        <UButton
          size="md"
          color="primary"
          variant="solid"
          to="/upload-center"
          label="Upload NID"
        />
      </div>
    </UModal>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const isOpen = ref(false);
const { user } = useAuth();
const { get, post } = useApi();
const toast = useToast();
const categories = ref([]);
const network = ref([]);
const device = ref([]);
const country = ref([{ title: "Bangladesh" }]);
const checkSubmit = ref(false);

const form = ref({
  price: 0,
  required_quantity: 0,
  instructions: "",
  title: "",
  medias: [],
  target_country: "Bangladesh",
  target_device: "",
  target_network: "",
  category: "",
});

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    form.value.medias.push(reader.result);
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
}

function deleteUpload(ind) {
  if (ind >= 0 && ind < form.value.medias.length) {
    form.value.medias.splice(ind, 1);
  }
}

function validateForm() {
  for (const key in form.value) {
    const value = form.value[key];
    // Check for empty strings, false values, or empty arrays
    if (
      (typeof value === "string" && !value.trim()) ||
      (typeof value === "boolean" && !value) ||
      (Array.isArray(value) && value.length === 0)
    ) {
      return false; // Validation failed
    }
  }
  return true; // All fields are valid
}

async function handlePostGig() {
  if (!validateForm()) {
    checkSubmit.value = true;
    toast.add({ title: "Please fill in all required fields." });
    return;
  }
  const balance = form.value.required_quantity * form.value.price;
  const total_cost = balance + (10 / 100) * balance;
  const submitValue = { ...form.value, total_cost, balance };
  console.log(submitValue);

  const res = await post("/post-micro-gigs/", submitValue);
  if (res.data) {
    navigateTo("/");
    toast.add({ title: "MicroGig Added" });
  }
}

async function getMicroGigsCategory() {
  try {
    const [
      categoriesResponse,
      devicesResponse,
      networksResponse,
      countriesResponse,
    ] = await Promise.all([
      get("/micro-gigs-categories/"),
      get("/target-device/"),
      get("/target-network/"),
      // get("/target-country/"),
    ]);

    categories.value = categoriesResponse.data;
    device.value = devicesResponse.data;
    network.value = networksResponse.data;
    // country.value = countriesResponse.data;
  } catch (error) {
    console.error("Error fetching micro-gigs data:", error);
  }
}

onMounted(() => {
  getMicroGigsCategory();
});
</script>

<style scoped></style>
