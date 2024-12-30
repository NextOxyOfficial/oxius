<template>
  <UContainer>
    <div class="flex flex-col gap-4 py-12">
      <h1 class="text-center text-4xl my-8">FAQ</h1>
      <UDivider label="" class="mb-8" />
      <UAccordion
        class="max-w-2xl mx-auto"
        color="slate"
        variant="outline"
        size="md"
        multiple
        :items="items"
      />
    </div>
  </UContainer>
</template>

<script setup>
const items = ref([]);
const { get } = useApi();

async function getFaq() {
  const response = await get("/faq/");
  items.value = response.data;
}

onMounted(async () => {
  getFaq();
});
// const items = [
//   {
//     label: "1. What is Nuxt UI?",
//     content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
//   },
//   {
//     label: "2. Getting Started",
//     content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
//   },
//   {
//     label: "3. Theming",
//     content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
//   },
//   {
//     label: "4. Components",
//     content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
//   },
// ];
</script>
