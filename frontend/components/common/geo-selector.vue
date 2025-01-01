<script setup>
const isOpen = ref(false);
</script>
<template>
  <div>
    <UButton label="Open" @click="isOpen = true" />

    <UModal v-model="isOpen">
      <div class="p-4">
        <div
          class="flex flex-col md:flex-row justify-between md:items-end gap-4"
        >
          <UFormGroup class="md:w-1/4">
            <USelectMenu
              v-model="form.state"
              color="white"
              size="md"
              :options="regions"
              placeholder="State"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="name"
              value-attribute="name"
            />
          </UFormGroup>
          <UFormGroup class="md:w-1/4">
            <USelectMenu
              v-model="form.city"
              color="white"
              size="md"
              :options="cities"
              placeholder="City"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="name"
              value-attribute="name"
            />
          </UFormGroup>
        </div>
      </div>
    </UModal>
  </div>
</template>
<script setup>
const form = ref({
  country: "Bangladesh",
  state: "",
  city: "",
});
const regions = ref([]);
const cities = ref();

const regions_response = await get(
  `/cities-light/regions/?country=${form.value.country}`
);
regions.value = regions_response.data;

watch(
  () => form.value.state,
  async (newState) => {
    console.log(newState);
    if (newState) {
      const cities_response = await get(
        `/cities-light/cities/?region=${newState}`
      );
      cities.value = cities_response.data;
    }
  }
);
</script>

<style scoped></style>
