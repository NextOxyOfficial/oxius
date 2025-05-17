<template>
  <UCard
    :ui="{
      ring: '',
      divide: 'divide-y divide-gray-100 dark:divide-gray-800',
      header: {
        background: 'bg-slate-50',
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
              <UIcon name="i-unjs:giget" class="text-2xl mt-1.5" />
            </div>
            <span class="text-xl flex-1">
              {{ gig.title }}
            </span>
          </div>
          <p class="text-lg font-semibold text-green-900 inline-flex items-center pl-5">
            Earn:
            <span class="inline-flex items-center"
              ><UIcon name="i-mdi:currency-bdt" class="text-xl" />{{ gig.price }}</span
            >
          </p>
        </div>
        <UButton
          color="gray"
          variant="ghost"
          icon="i-heroicons-x-mark-20-solid"
          class="-my-1"
          @click="emit('close')"
        />
      </div>
    </template>

    <div class="space-y-2 px-6 pb-8">
      <p class="text-xl font-medium">Instruction</p>

      <p class="text-base text-justify">
        {{ gig.instructions }}
      </p>
      <!-- <UDivider label="" class="pt-4" /> -->
      <p class="text-xl font-medium !mt-8">Reference Photo/Video</p>
      <div class="!mb-6 flex gap-1 cursor-pointer">
        <div class="" v-for="m in gig.medias" :key="m.id">
          <a
            class=""
            v-if="m.image"
            target="_blank"
            :href="'/media-viewer?url=' + m.image + '&type=image'"
          >
            <NuxtImg class="h-48 w-64 object-cover shadow" :src="m.image" />
          </a>
          <a
            class=""
            target="_blank"
            :href="'/media-viewer?url=' + m.video + '&type=video'"
            v-if="m.video"
          >
            <video class="h-48 w-64 object-cover shadow" :src="m.video"></video>
          </a>
        </div>
      </div>
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
      <UDivider label="" class="pt-4" />
      <div>
        <p class="text-xl font-medium !mb-2 !mt-8">Upload Proof</p>
        <div class="flex flex-wrap gap-5">
          <div class="relative max-w-[200px] max-h-[200px]" v-for="(img, i) in medias" :key="i">
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
      {{ gid }}
      {{ gig }}
    </div>
  </UCard>
</template>

<script setup>
const emit = defineEmits(["close"]);
const props = defineProps(["gid"]);
const { get, post } = useApi();
const medias = ref([]);
const accepted_terms = ref(false);

const accepted_condition = ref(false);

onMounted(() => {
  getGigData();
});
const gig = ref();
async function getGigData() {
  const res = await get(`/micro-gigs/${props.gid}`);
  gig.value = res.data;
}

async function submitGig() {
  const res = await post(`/user-micro-gig-task-post/`, {
    gig: props.gid,
    medias,
  });
  console.log(res);
}

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    medias.value.push(reader.result);
  };

  // Event listener for errors
  reader.onerror = error => reject(error);

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
