<template>
  <div>
    <UModal v-model="isOpen" prevent-close>
      <div class="p-4">
        <div
          class="flex flex-col md:flex-row justify-between md:items-end gap-4"
        >
          <UFormGroup class="md:w-2/4">
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
          <UFormGroup class="md:w-2/4">
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
        <UButton
          class="mt-4"
          size="md"
          color="primary"
          variant="solid"
          label="Add Location"
          @click="addLocation"
        />
      </div>
    </UModal>
  </div>
</template>
<script setup>
const { get } = useApi();
const isOpen = ref(false);
const location = useCookie("location");

if (!location.value) {
  isOpen.value = true;
}
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

function addLocation() {
  location.value = form.value;
  isOpen.value = false;
  window.location.reload();
}
</script>

<style scoped></style>
