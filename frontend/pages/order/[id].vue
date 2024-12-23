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
                class="text-base font-semibold leading-6 text-gray-900 dark:text-white mb-4 flex gap-3"
              >
                <div class="w-8">
                  <UIcon name="i-unjs:giget" class="text-3xl mt-1.5" />
                </div>
                <span class="text-2xl flex-1">
                  {{ gig.title }}
                </span>
              </div>
              <p
                class="text-lg font-bold text-green-900 inline-flex items-center pl-5"
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

          <p class="text-base text-justify">
            {{ gig.instructions }}
          </p>
          <!-- <UDivider label="" class="pt-4" /> -->

          <p class="text-xl font-medium !mt-8 sm:text-left">
            Reference Photo/Video
          </p>
          <div class="!mb-6 flex gap-1">
            <div class="" v-for="m in gig.medias" :key="m.id">
              <a
                class="cursor-pointer relative group"
                v-if="m.image"
                target="_blank"
                :href="
                  '/media-viewer?url=' + staticURL + m.image + '&type=image'
                "
              >
                <button
                  class="opacity-0 group-hover:opacity-100 absolute py-0.5 px-2 border bg-primary bg-opacity-90 left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2 rounded-md text-white"
                >
                  View
                </button>
                <NuxtImg
                  class="w-20 object-cover shadow"
                  :src="staticURL + m.image"
                />
              </a>
              <a
                class="cursor-pointer relative group"
                target="_blank"
                :href="
                  '/media-viewer?url=' + staticURL + m.video + '&type=video'
                "
                v-if="m.video"
              >
                <button
                  class="opacity-0 group-hover:opacity-100 absolute py-0.5 px-2 border bg-primary bg-opacity-90 left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2 rounded-md text-white"
                >
                  View
                </button>
                <video
                  class="w-20 object-cover shadow"
                  :src="staticURL + m.video"
                ></video>
              </a>
            </div>
          </div>

          <UDivider label="" class="pt-4" />

          <div>
            <p class="text-xl font-medium !mb-2 !mt-8 text-center sm:text-left">
              Upload Proof
            </p>
            <UFormGroup
              size="xl"
              label="Submit Details"
              class="!mt-8 md:w-1/2"
              required
              v-slot="{ error }"
              :error="
                !submit_details &&
                checkSubmit &&
                'You must enter submit details'
              "
            >
              <UTextarea
                color="white"
                variant="outline"
                class="w-full"
                resize
                placeholder="Submit Details"
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
          </div>
          <div class="!mt-7">
            <UCheckbox
              name="notifications"
              v-model="accepted_terms"
              label="I accept Terms & Conditions"
            />
            <UCheckbox
              name="notifications"
              v-model="accepted_condition"
              label="I am aware that fake and fraud submission may lead to account ban!"
            />
          </div>
          <div class="text-center">
            <UButton
              class="mt-8"
              icon="i-heroicons-check-solid"
              size="md"
              color="primary"
              variant="solid"
              label="I Completed!"
              @click="submitGig"
            />
          </div>
        </div>
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const emit = defineEmits(["close"]);
const props = defineProps(["gid"]);
const { get, staticURL, post } = useApi();
const route = useRoute();
const medias = ref([]);
const submit_details = ref("");
const accepted_terms = ref(false);
const toast = useToast();
const checkSubmit = ref(false);
const accepted_condition = ref(false);

onMounted(() => {
  getGigData();
});
const gig = ref();
async function getGigData() {
  const res = await get(`/micro-gigs/${route.params.id}/`);
  gig.value = res.data;
}

async function submitGig() {
  if (submit_details.value === "" && medias.value.length === 0) {
    checkSubmit.value = true;
    toast.add({ title: "You must enter submit details or upload proof!" });
    return;
  }

  const res = await post(`/user-micro-gig-task-post/`, {
    gig: route.params.id,
    medias: medias.value,
    submit_details: submit_details.value,
  });

  if (res.error) {
    toast.add({ title: "Something went wrong!" });
  } else {
    console.log(true);

    toast.add({ title: "Order Submitted Successfully!" });
  }
}

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    medias.value.push(reader.result);
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
}

function deleteUpload(ind) {
  if (ind >= 0 && ind < medias.value.length) {
    medias.value.splice(ind, 1);
  }
}
</script>

<style scoped></style>
