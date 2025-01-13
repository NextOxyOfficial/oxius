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
              <!-- <div class="relative">
                <label class="block text-sm font-medium text-gray-700 mb-1"
                  >State</label
                >
                <div class="relative">
                  <select
                    v-model="state"
                    class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg appearance-none cursor-pointer focus:outline-none focus:ring-2 focus:ring-primary/10 focus:border-primary transition-all duration-200"
                    :class="{ 'border-red-300': errors.state }"
                  >
                    <option value="" disabled>Select a state</option>
                    <option v-for="s in states" :key="s" :value="s">
                      {{ s }}
                    </option>
                  </select>
                  <ChevronDownIcon
                    class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400 pointer-events-none"
                  />
                </div>
                <p v-if="errors.state" class="mt-1 text-sm text-red-500">
                  {{ errors.state }}
                </p>
              </div> -->

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
              </UFormGroup>
              <!-- <div class="relative">
                <label class="block text-sm font-medium text-gray-700 mb-1"
                  >City</label
                >
                <div class="relative">
                  <select
                    v-model="city"
                    :disabled="!state"
                    class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg appearance-none cursor-pointer focus:outline-none focus:ring-2 focus:ring-primary/10 focus:border-primary transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                    :class="{ 'border-red-300': errors.city }"
                  >
                    <option value="" disabled>Select a city</option>
                    <option v-for="c in cities" :key="c" :value="c">
                      {{ c }}
                    </option>
                  </select>
                  <ChevronDownIcon
                    class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400 pointer-events-none"
                  />
                </div>
                <p v-if="errors.city" class="mt-1 text-sm text-red-500">
                  {{ errors.city }}
                </p>
              </div> -->

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
              </UFormGroup>
              <!-- <div class="relative">
                <label class="block text-sm font-medium text-gray-700 mb-1"
                  >Area</label
                >
                <div class="relative">
                  <select
                    v-model="area"
                    :disabled="!city"
                    class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg appearance-none cursor-pointer focus:outline-none focus:ring-2 focus:ring-primary/10 focus:border-primary transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                    :class="{ 'border-red-300': errors.area }"
                  >
                    <option value="" disabled>Select an area</option>
                    <option v-for="a in areas" :key="a" :value="a">
                      {{ a }}
                    </option>
                  </select>
                  <ChevronDownIcon
                    class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400 pointer-events-none"
                  />
                </div>
                <p v-if="errors.area" class="mt-1 text-sm text-red-500">
                  {{ errors.area }}
                </p>
              </div> -->
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
              </UFormGroup>
            </div>

            <div class="flex justify-center">
              <UButton
                class="mt-4"
                size="md"
                color="primary"
                variant="solid"
                label="Select Location"
                @click="addLocation"
              />
              <!-- <button
                type="button"
                @click="$emit('close')"
                class="flex-1 px-4 py-2.5 border border-gray-200 rounded-lg text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-200 transition-all duration-200"
              >
                Cancel
              </button>
              <button
                type="submit"
                :disabled="isLoading"
                class="flex-1 px-4 py-2.5 bg-primary text-white rounded-lg hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all duration-200 disabled:opacity-50"
              >
                <span
                  v-if="isLoading"
                  class="flex items-center justify-center gap-2"
                >
                  <LoaderIcon class="h-4 w-4 animate-spin" />
                  Adding...
                </span>
                <span v-else>Add Location</span>
              </button> -->
            </div>
          </div>
        </div>
      </div>
    </UModal>
    <!-- <UModal v-model="isOpen" prevent-close>
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
    </UModal> -->
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
console.log(regions.value);

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
