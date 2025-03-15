<template>
  <div>
    <UModal v-model="isOpen" prevent-close>
      <div
        class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4"
      >
        <div
          class="bg-white rounded-2xl shadow-2xl w-full max-w-md transform transition-all duration-300 ease-out scale-100"
        >
          <div class="p-6">
            <h2 class="text-2xl font-semibold text-gray-900 mb-6">
              Select Your Location
            </h2>

            <div class="space-y-4">
              <UFormGroup label="State">
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
                <p
                  v-if="showErrors && !form.state"
                  class="text-red-500 text-sm mt-1"
                >
                  Please select a state
                </p>
              </UFormGroup>

              <UFormGroup label="City">
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
                <p
                  v-if="showErrors && !form.city"
                  class="text-red-500 text-sm mt-1"
                >
                  Please select a city
                </p>
              </UFormGroup>

              <UFormGroup label="Area">
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
                <p
                  v-if="showErrors && !form.upazila"
                  class="text-red-500 text-sm mt-1"
                >
                  Please select an area
                </p>
              </UFormGroup>
            </div>

            <div class="flex justify-center">
              <UButton
                class="mt-4"
                size="md"
                color="primary"
                variant="solid"
                label="Select Location"
                @click="validateAndAddLocation"
                :disabled="isSubmitDisabled"
              />
            </div>
          </div>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
const { get } = useApi();
const isOpen = ref(false);
const location = useCookie("location");
const showErrors = ref(false);

if (!location.value) {
  isOpen.value = true;
}
const form = ref({
  country: "Bangladesh",
  state: "",
  city: "",
  upazila: "",
});

// Computed property to check if all fields are filled
const isSubmitDisabled = computed(() => {
  return !form.value.state || !form.value.city || !form.value.upazila;
});

// geo filter
const regions = ref([]);
const cities = ref([]);
const upazilas = ref([]);

const regions_response = await get(
  `/geo/regions/?country_name_eng=${form.value.country}`
);
regions.value = regions_response.data;

watch(
  () => form.value.state,
  async (newState) => {
    if (newState) {
      const cities_response = await get(
        `/geo/cities/?region_name_eng=${newState}`
      );
      cities.value = cities_response.data;
      form.value.city = ""; // Reset city when state changes
      form.value.upazila = ""; // Reset upazila when state changes
    }
  }
);

watch(
  () => form.value.city,
  async (newCity) => {
    if (newCity) {
      const thana_response = await get(
        `/geo/upazila/?city_name_eng=${newCity}`
      );
      upazilas.value = thana_response.data;
      form.value.upazila = ""; // Reset upazila when city changes
    }
  }
);

// New function to validate and add location
function validateAndAddLocation() {
  showErrors.value = true; // Show validation errors

  if (!isSubmitDisabled.value) {
    location.value = form.value;
    isOpen.value = false;
    window.location.reload();
  }
}
</script>
