<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">{{ $t("post_gigs") }}</h1>
      <UDivider label="" class="mb-8" />
      <section
        class="max-w-3xl mx-auto space-y-3 py-3 px-2 sm:px-8 rounded-xl sm:py-6 bg-white"
      >
        <UFormGroup
          label="Category"
          required
          :error="
            !form.category && checkSubmit && 'You must select a category!'
          "
          :ui="{
            label: {
              base: 'block font-medium text-gray-700 dark:text-slate-700',
            },
          }"
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
              placeholder: 'text-gray-400 dark:text-gray-200',
            }"
            option-attribute="title"
            value-attribute="id"
          />
        </UFormGroup>
        <UFormGroup
          label="Title"
          required
          :error="!form.title && checkSubmit && 'You must enter a title!'"
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
            class="relative"
            placeholder="Title"
            v-model="form.title"
            :ui="{
              size: {
                md: 'text-base',
              },
              // padding: { md: 'pl-[60px]' },
              placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
            }"
          >
            <!-- <span class="absolute left-2 top-2">I Need</span> -->
          </UInput>
        </UFormGroup>
        <div class="flex gap-4 items-center">
          <UFormGroup
            label="Budget Per Action"
            required
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
        </div>
        <div>
          <UFormGroup
            label="Total Cost (Service handling fee 10% included)"
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700 italic',
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
        <!-- <UFormGroup
          label="Instructions"
          required
          :error="
            !form.instructions && checkSubmit && 'You must enter instructions!'
          "
          :ui="{
            label: {
              base: 'block font-medium text-gray-700 dark:text-slate-700',
            },
          }"
        >
          <UTextarea
            color="white"
            variant="outline"
            :ui="{
              size: {
                md: 'text-base',
              },
              placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
            }"
            class="w-full"
            resize
            placeholder="Instructions"
            v-model="form.instructions"
          />
        </UFormGroup> -->
        <p class="text-sm font-semibold">
          Instructions <span class="text-red-500">*</span>
        </p>
        <CommonEditor
          v-model="form.instructions"
          @updateContent="updateContent"
          class="border border-slate-300 p-2 bg-white"
        />
        <div>
          <UFormGroup label="URL">
            <UInput
              type="text"
              size="md"
              color="white"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              placeholder="Task URL"
              v-model="form.action_link"
              class="sm:max-w-[50%]"
            />
          </UFormGroup>
        </div>
        <!-- medias  -->
        <label for="" class="block mt-3 font-semibold text-slate-700"
          >Upload Photo/Video</label
        >
        <div class="flex flex-wrap gap-5">
          <div
            class="relative max-w-[200px] max-h-[200px]"
            v-for="(img, i) in form.medias"
            :key="i"
          >
            <img
              :src="img"
              :alt="`Uploaded file ${i}`"
              class="h-full object-cover"
            />
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
            :error="
              !form.target_country &&
              checkSubmit &&
              'You must select a target country!'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
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
                placeholder: 'text-gray-400 dark:text-gray-200',
              }"
              option-attribute="title"
              value-attribute="title"
            />
          </UFormGroup>
          <UFormGroup
            label="Target Device"
            required
            :error="
              !form.target_device &&
              checkSubmit &&
              'You must select a target device!'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
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
                placeholder: 'text-gray-400 dark:text-gray-200',
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
            :error="
              !form.target_network &&
              checkSubmit &&
              'You must select a target network!'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <USelectMenu
              v-model="form.target_network"
              size="md"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'text-gray-400 dark:text-gray-200',
              }"
              :options="network"
              multiple
              placeholder="Target Network"
              option-attribute="title"
              value-attribute="id"
            />
          </UFormGroup>
        </div>
        <div v-if="showError">
          <span class="text-sm text-red-500">{{ showError }}!</span>
          <nuxt-link to="/deposit-withdraw/" class="text-blue-950 text-sm">
            Click here to make a deposit</nuxt-link
          >
        </div>
        <div class="text-center pb-6">
          <UButton
            :loading="isLoading"
            v-if="user.user.kyc"
            class="px-8 mt-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            type="submit"
            @click="handlePostGig"
          />
          <UButton
            v-else
            class="px-8 mt-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            @click="isOpen = true"
          />
        </div>
      </section>
    </UContainer>
    <UModal v-model="isOpen">
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <!-- <div 
              className="fixed inset-0 bg-gray-500/75 backdrop-blur-sm transition-opacity"
              onClick={onClose}
            /> -->
        <div
          className="relative w-full max-w-sm transform overflow-hidden rounded-lg bg-white shadow-xl transition-all"
        >
          <div className="px-6 py-8">
            <div className="flex flex-col items-center text-center">
              <div
                className="rounded-full bg-red-100 p-3 mb-4 inline-flex items-center justify-center"
              >
                <!-- <AlertCircle className="h-8 w-8 text-red-600" /> -->
                <UIcon
                  name="i-line-md-alert-circle"
                  class="h-8 w-8 text-red-600"
                />
              </div>

              <h2 className="text-xl font-semibold text-gray-900 mb-2">
                KYC Unverified
              </h2>

              <p className="text-gray-600 mb-6">
                Please Upload your ID to get permission to post a service ad.
              </p>

              <!-- <button
                  className="inline-flex items-center justify-center w-full px-4 py-2.5 rounded-lg bg-emerald-500 text-white hover:bg-emerald-600 active:bg-emerald-700 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2"
                  onClick="{handleUpload}"
                >
                  <Upload className="h-5 w-5 mr-2" />
                  Upload NID
                </button> -->
              <UButton
                size="md"
                color="primary"
                variant="solid"
                to="/upload-center"
                label="Upload NID"
                block
              >
                <template #leading>
                  <UIcon
                    name="i-material-symbols-upload-rounded"
                    class="h-5 w-5"
                  />
                </template>
              </UButton>
            </div>
          </div>
        </div>
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
const showError = ref("");
const isLoading = ref(false);

const form = ref({
  price: null,
  required_quantity: null,
  instructions: "",
  title: "",
  medias: [],
  target_country: "Bangladesh",
  target_device: "",
  target_network: "",
  category: "",
  active_gig: true,
  action_link: "",
});

function updateContent(p) {
  form.value.instructions = p;
}

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
  const { medias, action_link, ...rest } = form.value;
  for (const key in rest) {
    const value = rest[key];
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
  console.log(form.value.instructions);

  if (!validateForm()) {
    checkSubmit.value = true;
    toast.add({ title: "Please fill in all required fields." });
    return;
  }
  isLoading.value = true;
  const balance = form.value.required_quantity * form.value.price;
  const total_cost = balance + (balance * 10) / 100;
  const submitValue = { ...form.value, total_cost, balance };
  console.log(submitValue);

  const res = await post("/post-micro-gigs/", submitValue);
  console.log(res);

  if (res.data) {
    navigateTo("/");
    toast.add({ title: "MicroGig Added" });
  } else {
    toast.add({ title: res.error.data.errors });
    showError.value = res.error.data.errors;
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
