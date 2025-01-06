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
              option-attribute="name_eng"
              value-attribute="name_eng"
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
              option-attribute="name_eng"
              value-attribute="name_eng"
            />
          </UFormGroup>
          <UFormGroup class="md:w-2/4">
            <USelectMenu
              v-model="form.upazila"
              color="white"
              size="md"
              :options="upazilas"
              placeholder="Thana"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="name_eng"
              value-attribute="name_eng"
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
  upazila: "",
});
// geo filter

const regions = ref([]);
const cities = ref();
const upazilas = ref();

const regions_response = await get(
  `/geo/regions/?country_name_eng=${form.value.country}`
);
regions.value = regions_response.data;

watch(
  () => form.value.state,
  async (newState) => {
    console.log(newState);
    if (newState) {
      const cities_response = await get(
        `/geo/cities/?region_name_eng=${newState}`
      );
      cities.value = cities_response.data;
      console.log(cities_response.data);
    }
  }
);

watch(
  () => form.value.city,
  async (newCity) => {
    console.log(newCity);
    if (newCity) {
      const thana_response = await get(
        `/geo/upazila/?city_name_eng=${newCity}`
      );
      upazilas.value = thana_response.data;
      console.log(thana_response.data);
    }
  }
);

// geo filter

function addLocation() {
  location.value = form.value;
  isOpen.value = false;
  window.location.reload();
}
</script>

<style scoped></style>
