<template>
  <PublicSection>
    <UContainer>
      <UCard
        :ui="{
          ring: '',
          divide: 'divide-y divide-gray-100 dark:divide-gray-800',
          header: {
            background: 'bg-slate-50',
            padding: 'px-2 py-3',
          },
          body: {
            padding: 'px-2 py-3',
          },
          rounded: 'rounded-lg',
        }"
        v-if="gig"
      >
        <template #header>
          <div class="flex items-start justify-between">
            <div>
              <div
                class="text-base font-semibold leading-6 text-gray-800 dark:text-white mb-4 flex gap-3"
              >
                <div class="w-8">
                  <UIcon name="i-unjs:giget" class="text-2xl mt-1.5" />
                </div>
                <span class="text-xl flex-1">
                  {{ gig.title }}
                </span>
              </div>
              <p
                class="text-lg font-semibold text-green-900 inline-flex items-center pl-5"
              >
                Earn:
                <span class="inline-flex items-center"
                  ><UIcon name="i-mdi:currency-bdt" class="text-xl" />{{
                    gig.price
                  }}</span
                >
              </p>
            </div>
          </div>
        </template>

        <div class="space-y-2 md:px-6 pb-8">
          <p class="text-xl font-medium sm:text-left">Instruction</p>

          <div
            class="text-base text-justify prose"
            v-html="gig.instructions"
          ></div>
          <!-- <UDivider label="" class="pt-4" /> -->

          <p
            class="text-lg font-medium !mt-8 sm:text-left"
            v-if="gig.medias?.length"
          >
            Reference Photo/Video
          </p>
          <div class="!mb-6 flex gap-1">
            <div class="" v-for="(m, i) in gig.medias" :key="m.id">
              <a
                class="cursor-pointer relative group"
                v-if="m.image"
                target="_blank"
                :href="'/media-viewer?url=' + m.image + '&type=image'"
              >
                <button
                  class="opacity-0 group-hover:opacity-100 absolute py-0.5 px-2 border bg-primary bg-opacity-90 left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2 rounded-md text-white"
                >
                  View
                </button>
                <img
                  v-if="m.image && errorIndex.includes(i)"
                  :src="errorIndex.includes(i) ? gig.category.image : m.image"
                  class="size-20 object-contain"
                  alt="Gig Image"
                />
                <NuxtImg
                  v-else-if="m.image && !errorIndex.includes(i)"
                  :src="m.image"
                  class="size-20 object-contain"
                />
                <img
                  v-else
                  :src="gig.category.image"
                  alt="No Image"
                  class="size-20"
                />
              </a>
              <a
                class="cursor-pointer relative group"
                target="_blank"
                :href="'/media-viewer?url=' + m.video + '&type=video'"
                v-if="m.video"
              >
                <button
                  class="opacity-0 group-hover:opacity-100 absolute py-0.5 px-2 border bg-primary bg-opacity-90 left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2 rounded-md text-white"
                >
                  View
                </button>
                <video class="w-20 object-contain shadow" :src="m.video"></video>
              </a>
            </div>
          </div>
          <p
            class="text-lg font-medium !mt-8 sm:text-left"
            v-if="gig.action_link"
          >
            Action Url
          </p>
          <a :href="gig.action_link" target="_blank" class="text-blue-400">{{
            gig.action_link
          }}</a>
          <UDivider label="" class="pt-4" />

          <div
            class="border border-dashed !mt-5 pb-3 px-2 sm:p-5 bg-slate-50/50 rounded-xl"
          >
            <div>
              <p
                class="text-xl font-medium !mb-2 !mt-8 text-center sm:text-left"
              >
                Upload Proof
              </p>
              <UFormGroup
                size="xl"
                label="Submit Details"
                class="!mt-8 md:w-1/2"
                required
                :error="
                  !submit_details &&
                  checkSubmit &&
                  'Enter your micro job detail contents'
                "
              >
                <UTextarea
                  color="white"
                  variant="outline"
                  class="w-full"
                  resize
                  placeholder="Enter your micro job detail contents..."
                  v-model="submit_details"
                />
              </UFormGroup>
              <label for="file" class="text-base block mt-8 mb-3 font-semibold"
                >Upload</label
              >
              <div class="flex flex-wrap gap-5">
                <div
                  class="relative max-w-[200px] max-h-[200px]"
                  v-for="(img, i) in medias"
                  :key="i"
                >
                  <img
                    :src="img"
                    :alt="`Uploaded file ${i}`"
                    class="h-full object-contain"
                  />
                  <div
                    class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
                    @click="deleteUpload(i)"
                  >
                    <UIcon
                      name="i-heroicons-trash-solid"
                      class="text-red-500"
                    />
                  </div>
                </div>
                <!-- <p v-if="!medias.length && checkSubmit" class="text-red-500">
                  Add Images to submit the micro job
                </p> -->

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
            </div>
           
            <div class="!mt-7">
              <UFormGroup class="flex flex-row-reverse justify-end gap-2 mb-4">
                <template #label>
                  I accept
                  <ULink
                    to="/terms/"
                    active-class="text-primary"
                    inactive-class="text-gray-600 dark:text-gray-600"
                    >Terms & Condition</ULink
                  >,
                  <ULink
                    to="/privacy/"
                    active-class="text-primary"
                    inactive-class="text-gray-600 dark:text-gray-600"
                    >Privacy Policy</ULink
                  >.
                </template>
                <UCheckbox name="check" v-model="accepted_terms" />
              </UFormGroup>
              <p
                class="text-sm text-red-500"
                v-if="!accepted_terms && checkSubmit"
              >
                Accept Terms & Condition, Privacy Policy
              </p>
              <UCheckbox
                name="notifications"
                v-model="accepted_condition"
                label="I am aware that fake and fraud submission may lead to account ban!"
              />
              <p
                class="text-sm text-red-500"
                v-if="!accepted_condition && checkSubmit"
              >
                Accept Conditions
              </p>
            </div>
          </div>
          <div class="text-center">
            <UButton
              v-if="user.user.kyc"
              class="mt-8"
              icon="i-heroicons-check-solid"
              size="md"
              color="primary"
              variant="solid"
              label="I Completed!"
              @click="submitGig"
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
        </div>
      </UCard>
      <UModal v-model="isOpen">
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          
          <div
            className="relative w-full max-w-sm transform overflow-hidden rounded-lg bg-white shadow-sm transition-all"
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

                <h2 className="text-xl font-semibold text-gray-800 mb-2">
                  KYC Unverified
                </h2>

                <p className="text-gray-600 mb-6">
                  Please Upload your ID to get permission to post a service ad.
                </p>

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
    </UContainer>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const emit = defineEmits(["close"]);
const props = defineProps(["gid"]);
const { jwtLogin, user } = useAuth();
const { get, post } = useApi();
const route = useRoute();
const medias = ref([]);
const submit_details = ref("");
const accepted_terms = ref(false);
const toast = useToast();
const checkSubmit = ref(false);
const accepted_condition = ref(false);
const isLoading = ref(false);
const isOpen = ref(false);

const errorIndex = ref([]);

function handleImageError(index) {
  console.log(index);

  console.log(`Broken image detected at index: ${index}`);
  if (!errorIndex.value.includes(index)) {
    errorIndex.value.push(index); // Add index to errorIndex
  }
}

onMounted(() => {
  getGigData();
});
const gig = ref();
async function getGigData() {
  const res = await get(`/micro-gigs/${route.params.id}/`);
  gig.value = res.data;
}

async function submitGig() {
  if (
    !submit_details.value.trim() ||
    !accepted_terms.value ||
    !accepted_condition.value
  ) {
    checkSubmit.value = true;
    return;
  } else {
    isLoading.value = true;
    const res = await post(`/user-micro-gig-task-post/`, {
      gig: route.params.id,
      medias: medias.value,
      submit_details: submit_details.value,
    });

    if (res.error) {
      console.log(res.error?.data?.error);
      toast.add({ title: res.error?.data?.error });
    } else {
      console.log(true);
      jwtLogin();
      toast.add({ title: "Order Submitted Successfully!" });
      isLoading.value = false;
      navigateTo(`/pending-tasks/${user.value.user.id}/`);
    }
    isLoading.value = false;
  }
}

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  if (!files.length) return;

  const file = files[0];

  // Validate file size (5MB limit)
  const maxSize = 12 * 1024 * 1024; // 5MB in bytes
  if (file.size > maxSize) {
    toast.add({
      title: "File size too large",
      description: "Maximum size allowed is 12MB",
      color: "red",
    });
    return;
  }

  // Validate file type
  const allowedTypes = [
    "image/jpeg",
    "image/png",
    "image/jpg",
    "image/heic",
    "image/heif",
  ];
  if (!allowedTypes.includes(file.type.toLowerCase())) {
    toast.add({
      title: "Invalid file type",
      description: "Please upload a valid image (JPEG, PNG, HEIC)",
      color: "red",
    });
    return;
  }

  // Create new FileReader instance
  const reader = new FileReader();

  reader.onload = () => {
    // Create an image element for compression
    const img = new Image();
    img.onload = () => {
      // Create canvas for image compression
      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");

      // Calculate new dimensions (max 1200px)
      let width = img.width;
      let height = img.height;
      const maxWidth = 1200;
      const maxHeight = 1200;

      if (width > height) {
        if (width > maxWidth) {
          height = Math.round((height * maxWidth) / width);
          width = maxWidth;
        }
      } else {
        if (height > maxHeight) {
          width = Math.round((width * maxHeight) / height);
          height = maxHeight;
        }
      }

      // Set canvas dimensions
      canvas.width = width;
      canvas.height = height;

      // Draw and compress image
      ctx.drawImage(img, 0, 0, width, height);

      // Convert to compressed base64
      const compressedBase64 = canvas.toDataURL("image/jpeg", 0.7);

      // Add to medias array
      medias.value.push(compressedBase64);
    };

    img.onerror = () => {
      toast.add({
        title: "Error processing image",
        description: "Please try another image",
        color: "red",
      });
    };

    img.src = reader.result;
  };

  reader.onerror = () => {
    toast.add({
      title: "Error reading file",
      description: "Please try again",
      color: "red",
    });
  };

  reader.readAsDataURL(file);
}

function deleteUpload(ind) {
  if (ind >= 0 && ind < medias.value.length) {
    medias.value.splice(ind, 1);
  }
}
</script>

<style scoped></style>
