<template>
  <div>
    <UModal v-model="isOpen" prevent-close>
      <div
        class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4"
      >
        <div class="bg-white rounded-xl shadow-sm w-full max-w-md">
          <!-- Header -->
          <div class="bg-primary-50 p-5 rounded-t-xl border-b border-gray-100">
            <h2 class="text-xl font-semibold text-gray-800">
              <UIcon
                name="i-heroicons-map-pin"
                class="inline-block mr-2 text-primary-500"
              />
              {{ $t("select_location") }}
            </h2>
            <p class="text-sm text-gray-600 mt-1">
              {{ $t("relevant_content") }}
            </p>
          </div>

          <div class="p-5">
            <!-- All Bangladesh Option -->
            <div class="mb-4 pb-4 border-b border-gray-100">
              <UCheckbox
                v-model="allOverBangladesh"
                name="all-bangladesh"
                :label="t('all_over_bangladesh') || 'Show content from all over Bangladesh'"
                color="primary"
              />
            </div>

            <!-- Form Fields -->
            <div class="space-y-4" v-if="!allOverBangladesh">
              <UFormGroup :label="t('division')" required>
                <USelectMenu
                  v-model="form.state"
                  color="primary"
                  size="md"
                  :options="regions"
                  :placeholder="t('select_division')"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                  class="location-select"
                />
                <p
                  v-if="showErrors && !form.state"
                  class="text-red-500 text-sm mt-1"
                >
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="inline-block w-4 h-4 mr-1"
                  />
                  Please select a state
                </p>
              </UFormGroup>

              <UFormGroup :label="t('city')" required>
                <USelectMenu
                  v-model="form.city"
                  color="primary"
                  size="md"
                  :options="cities"
                  :placeholder="t('select_city')"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                  class="location-select"
                  :disabled="!form.state"
                />
                <p
                  v-if="showErrors && !form.city"
                  class="text-red-500 text-sm mt-1"
                >
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="inline-block w-4 h-4 mr-1"
                  />
                  Please select a city
                </p>
              </UFormGroup>

              <UFormGroup :label="t('area_upozila')" required>
                <USelectMenu
                  v-model="form.upazila"
                  color="primary"
                  size="md"
                  :options="upazilas"
                  :placeholder="t('select_area_upozila')"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                  class="location-select"
                  :disabled="!form.city"
                />
                <p
                  v-if="showErrors && !form.upazila"
                  class="text-red-500 text-sm mt-1"
                >
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="inline-block w-4 h-4 mr-1"
                  />
                  Please select an area
                </p>
              </UFormGroup>
            </div>

            <!-- Action Button -->
            <UButton
              class="mt-6 w-48 mx-auto"
              size="lg"
              color="primary"
              variant="solid"
              :label="t('set_location')"
              @click="validateAndAddLocation"
              :disabled="isSubmitDisabled && !allOverBangladesh"
              :loading="isLoading"
              block
            />
          </div>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
const { t } = useI18n();
const { get } = useApi();
const isOpen = ref(false);
const location = useCookie("location");
const showErrors = ref(false);
const isLoading = ref(false);
const allOverBangladesh = ref(false);

if (!location.value) {
  isOpen.value = true;
}

const form = ref({
  country: "Bangladesh",
  state: "",
  city: "",
  upazila: "",
});

// Simple step tracking
const getCurrentStep = () => {
  if (!form.value.state) return 0;
  if (!form.value.city) return 1;
  if (!form.value.upazila) return 2;
  return 3;
};

const getCurrentStepClass = (index) => {
  if (index < getCurrentStep()) {
    return "border-primary-500 bg-primary-500 text-white";
  }
  if (index === getCurrentStep()) {
    return "border-primary-500 text-primary-500";
  }
  return "border-gray-200 text-gray-600";
};

// Computed property to check if all fields are filled
const isSubmitDisabled = computed(() => {
  return !allOverBangladesh.value && (!form.value.state || !form.value.city || !form.value.upazila);
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
      form.value.city = "";
      form.value.upazila = "";
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
      form.value.upazila = "";
    }
  }
);

// Function to validate and add location
function validateAndAddLocation() {
  showErrors.value = true;

  // If all over Bangladesh is selected, or if all required fields are filled
  if (allOverBangladesh.value || !isSubmitDisabled.value) {
    isLoading.value = true;

    // Short delay for better UX
    setTimeout(() => {
      if (allOverBangladesh.value) {
        // Set location with national scope flag
        location.value = {
          country: form.value.country,
          allOverBangladesh: true,
          state: "",
          city: "",
          upazila: ""
        };
      } else {
        // Set location with specific location data
        location.value = form.value;
      }
      isOpen.value = false;
      isLoading.value = false;
      window.location.reload();
    }, 500);
  }
}
</script>

<style scoped>
.location-select {
  transition: all 0.2s ease;
}

.location-select:hover:not(:disabled) {
  border-color: #4f46e5;
}

/* Simple animation for validation errors */
p.text-red-500 {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
</style>
