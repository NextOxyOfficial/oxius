<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Post A Gig</h1>
      <UDivider label="" class="mb-8" />
      <form
        action="#"
        class="max-w-2xl mx-auto space-y-3"
        @submit.prevent="handleUpdateGig"
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
            }"
          >
          </UInput>
        </UFormGroup>
        <div class="flex gap-4 items-center">
          <UFormGroup
            required
            label="Budget Per Action"
            :error="
              form.price <= 0 &&
              checkSubmit &&
              'You must enter budget per action!'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <UInput
              disabled
              icon="i-mdi:currency-bdt"
              type="text"
              size="md"
              color="white"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              placeholder="2.0"
              class="max-w-40"
              v-model="form.price"
            />
          </UFormGroup>
          <UFormGroup
            label="Required Quantity"
            required
            :error="
              form.required_quantity <= 0 &&
              checkSubmit &&
              'You must enter required quantity!'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <UInput
              disabled
              type="text"
              size="md"
              color="white"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-500',
              }"
              placeholder="10"
              class="max-w-40"
              v-model="form.required_quantity"
            />
          </UFormGroup>
          <!-- <UFormGroup
            label="*"
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <p>=</p>
          </UFormGroup> -->
          <UFormGroup
            label="_"
            :ui="{
              label: {
                base: 'opacity-0',
              },
            }"
            ><UButton
              icon="i-heroicons-plus-solid"
              size="md"
              color="primary"
              variant="solid"
              label="Add QTY"
              @click="isOpen = true"
            />
          </UFormGroup>
        </div>
        <div>
          <UFormGroup
            label="Total Cost (Service handling fee 10% included)"
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
            required
          >
            <p class="inline-flex gap-0.5 items-center">
              <UIcon name="i-mdi:currency-bdt" />{{
                form.price * form.required_quantity +
                (form.price * form.required_quantity * 10) / 100
              }}
            </p>
          </UFormGroup>
        </div>
        <CommonEditor
          v-if="form.instructions"
          :content="form.instructions"
          @updateContent="
            (content) => {
              form.instructions = content;
            }
          "
          class="border border-slate-300 p-2 bg-white pointer-events-none"
        />

        <!-- medias  -->

        <div class="flex flex-wrap gap-5">
          <div
            class="relative max-w-[200px] max-h-[200px]"
            v-for="(img, i) in form.medias"
            :key="i"
          >
            <img
              :src="img.image"
              class="max-h-[100px]"
              :alt="`Uploaded file ${i}`"
            />
            <!-- <div
              class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
              @click="deleteUpload(i)"
            >
              <UIcon name="i-heroicons-trash-solid" class="text-red-500" />
            </div> -->
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
            <!-- <UIcon name="i-heroicons-plus-solid" size="66" /> -->
          </div>
        </div>

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
              disabled
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
              disabled
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
              disabled
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
              disabled
            />
          </UFormGroup>
        </div>

        <div class="text-center">
          <UButton
            class="px-8 mt-10"
            :loading="isLoading"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            type="submit"
          />
        </div>
      </form>
    </UContainer>
    <UModal v-model="isOpen">
      <UCard
        :ui="{
          ring: '',
          divide: 'divide-y divide-gray-100 dark:divide-gray-800',
        }"
      >
        <div>
          <div class="flex gap-4 items-center">
            <UFormGroup
              required
              label="Budget Per Action"
              :error="
                form.price <= 0 &&
                checkSubmit &&
                'You must enter budget per action!'
              "
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
            >
              <UInput
                disabled
                icon="i-mdi:currency-bdt"
                type="text"
                size="md"
                color="white"
                :ui="{
                  size: {
                    md: 'text-base',
                  },
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
                placeholder="2.0"
                class="max-w-40"
                v-model="form.price"
              />
            </UFormGroup>
            <UFormGroup
              label="Add Additional Quantity"
              required
              :error="
                form.additional_quantity <= 0 &&
                checkSubmit &&
                'You must enter required quantity!'
              "
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                :ui="{
                  size: {
                    md: 'text-base',
                  },
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-500',
                }"
                placeholder="10"
                class="max-w-40"
                v-model="form.additional_quantity"
              />
            </UFormGroup>
          </div>
          <div>
            <UFormGroup
              label="Total Cost (Service handling fee 10% included)"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
              required
            >
              <p class="inline-flex gap-0.5 items-center">
                <UIcon name="i-mdi:currency-bdt" />{{
                  form.price * form.additional_quantity +
                  (form.price * form.additional_quantity * 10) / 100
                }}
              </p>
            </UFormGroup>
          </div>
        </div>
        <UButton
          size="md"
          color="primary"
          variant="solid"
          label="Confirm Addition"
          class="mx-auto"
          @click="isOpen = false"
        />
      </UCard>
    </UModal>
  </PublicSection>
</template>

<script setup>
const { get, put } = useApi();
const toast = useToast();
const categories = ref([]);
const network = ref([]);
const device = ref([]);
const country = ref([]);
const route = useRoute();
const isOpen = ref(false);
const isLoading = ref(false);

const form = ref({
  price: 0,
  required_quantity: 0,
  instructions: "",
  // title: "",
  image: null, // This will be the file object when uploaded, not the preview URL yet.
  medias: [],
  target_country: "",
  target_device: "",
  target_network: "",
  category: "",
  additional_quantity: null,
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

async function handleUpdateGig() {
  const required_quantity =
    form.value.required_quantity * 1 + form.value.additional_quantity * 1;
  const balance =
    +form.value.balance + form.value.additional_quantity * form.value.price;

  const additional_cost =
    form.value.additional_quantity * form.value.price +
    (form.value.price * form.value.additional_quantity * 10) / 100;
  console.log({ required_quantity, additional_cost });
  isLoading.value = true;
  const res = await put(`/update-user-micro-gig/${route.params.id}/`, {
    required_quantity,
    additional_cost,
    balance,
  });
  if (res.data) {
    isLoading.value = false;
    navigateTo("/");
    toast.add({ title: "MicroGig Updated" });
  }
  isLoading.value = false;
}

async function getMicroGigsCategory() {
  try {
    const [
      categoriesResponse,
      devicesResponse,
      networksResponse,
      countriesResponse,
      microGigResponse,
    ] = await Promise.all([
      get("/micro-gigs-categories/"),
      get("/target-device/"),
      get("/target-network/"),
      get("/target-country/"),
      get(`/get-user-micro-gig/${route.params.id}/`),
    ]);

    categories.value = categoriesResponse.data;
    device.value = devicesResponse.data;
    network.value = networksResponse.data;
    country.value = countriesResponse.data;
    form.value = microGigResponse.data;
    console.log(microGigResponse.data);
  } catch (error) {
    console.error("Error fetching micro-gigs data:", error);
  }
}

onMounted(() => {
  getMicroGigsCategory();
});
</script>

<style scoped></style>
