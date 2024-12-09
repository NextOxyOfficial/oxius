<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Add A Classified Post</h1>
      <UDivider label="" class="mb-8" />
      <form
        action="#"
        class="max-w-2xl mx-auto space-y-3"
        @submit.prevent="handlePostGig"
      >
        <UFormGroup label="Title">
          <UTextarea
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
          </UTextarea>
        </UFormGroup>
        <div class="flex gap-4 items-center"></div>
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
        <div class="grid md:grid-cols-2 gap-4">
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
          <UFormGroup label="Price">
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
        </div>
        <UFormGroup label="Upload Photo/Video">
          <input
            type="file"
            name=""
            id=""
            @change="handleFileUpload($event, 'image')"
          />
        </UFormGroup>
        <div v-if="mediaPreview.length">
          <div v-for="(img, i) in mediaPreview" :key="i" class="flex gap-5">
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
        <div>
          <UFormGroup label="Location">
            <UTextarea
              v-model="form.location"
              color="white"
              variant="outline"
              class="w-full"
              resize
              placeholder="Chewriya, Kushtia"
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

const mediaPreview = ref([]);

const form = ref({
  price: 0,
  instruction: "",
  title: "",
  image: null, // This will be the file object when uploaded, not the preview URL yet.
  medias: [],
  category: "",
  location: "",
});

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  files.forEach((file) => {
    const preview = URL.createObjectURL(file);
    mediaPreview.value.push({ preview });
    form.value.medias.push(file);
    form.value.image = file;
  });
}

function deleteUpload(index) {
  // Revoke object URL to free memory
  URL.revokeObjectURL(mediaPreview.value[index].preview);

  // Remove the preview URL from the array
  mediaPreview.value.splice(index, 1);

  // Remove the file from the array
  form.value.medias.splice(index, 1);
}

async function handlePostGig() {
  console.log(form.value);
  const formData = new FormData();
  formData.append("title", form.value.title);
  formData.append("price", form.value.price);
  formData.append("instructions", form.value.instruction);
  formData.append("image", form.value.image);
  formData.append("category", form.value.category);
  formData.append("medias", form.value.medias); // Not needed as we are sending the image separately
  formData.append("location", form.value.location); // Not needed as we are sending the image separately
  console.log(formData);

  const res = await post("/classified-categories-post/", formData);
  if (res.data) {
    navigateTo("/");
    toast.add({ title: "MicroGig Added" });
  }
}

async function getMicroGigsCategory() {
  try {
    const [categoriesResponse] = await Promise.all([
      get("/classified-categories/"),
    ]);

    categories.value = categoriesResponse.data;
  } catch (error) {
    console.error("Error fetching micro-gigs data:", error);
  }
}

onMounted(() => {
  getMicroGigsCategory();
});
</script>

<style scoped></style>
