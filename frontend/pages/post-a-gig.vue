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
        <UFormGroup label="Title">
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
            v-model="form.instruction"
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
              :options="country"
              multiple
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="title"
              value-attribute="id"
            />
          </UFormGroup>
          <UFormGroup label="Target Device">
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
          <UFormGroup label="Target Network">
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
          <UFormGroup label="Category">
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
const { get, post } = useApi();
const toast = useToast();
const categories = ref([]);
const network = ref([]);
const device = ref([]);
const country = ref([]);

const form = ref({
  price: 0,
  required_quantity: 0,
  instruction: "",
  // title: "",
  image: null, // This will be the file object when uploaded, not the preview URL yet.
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
    form.value.image = file;
  });
}

function deleteUpload(index) {
  // Revoke object URL to free memory
  URL.revokeObjectURL(form.value.uploads[index].preview);

  // Remove the file from the array
  form.value.uploads.splice(index, 1);
}

async function handlePostGig() {
  console.log(form.value);
  const formData = new FormData();
  formData.append("title", form.value.title);
  formData.append("price", form.value.price);
  formData.append("required_quantity", form.value.required_quantity);
  formData.append("instructions", form.value.instruction);
  formData.append("image", form.value.image);
  formData.append("target_country", form.value.target_country);
  formData.append("target_device", form.value.target_device);
  formData.append("target_network", form.value.target_network);
  formData.append("category", form.value.category);
  console.log(form.value);

  const res = await post("/post-micro-gigs/", formData);
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
      get("/target-country/"),
    ]);

    categories.value = categoriesResponse.data;
    device.value = devicesResponse.data;
    network.value = networksResponse.data;
    country.value = countriesResponse.data;
  } catch (error) {
    console.error("Error fetching micro-gigs data:", error);
  }
}

onMounted(() => {
  getMicroGigsCategory();
});
</script>

<style scoped></style>
