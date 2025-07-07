<template>
  <div class="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
    <CommonGeoSelector />
    <UContainer class="py-3">
      <div class="location-breadcrumb relative mb-3 overflow-hidden">
        <!-- Subtle background effect -->
        <div
          class="absolute inset-0 bg-gradient-to-r from-gray-50 to-primary-50 opacity-70 rounded-lg"
        ></div>

        <!-- Decorative map pin -->
        <div class="absolute -left-3 top-1/2 -translate-y-1/2 text-primary-400">
          <UIcon name="i-heroicons-map-pin" class="w-16 h-16" />
        </div>

        <div
          class="relative z-10 flex items-center justify-between px-3 pl-12 rounded-lg border border-primary-100"
        >
          <!-- Location path with icons -->
          <div class="location-breadcrumb relative my-3 overflow-hidden">
            <!-- Subtle background effect -->
            <div
              class="relative z-10 flex items-center justify-between p-1 rounded-lg border border-primary-100"
            >
              <!-- Location path with icons -->
              <div class="flex items-center flex-wrap location-path">
                <!-- Show country if allOverBangladesh is true or only country is set -->
                <div
                  v-if="
                    location?.allOverBangladesh ||
                    (location?.country && !location?.state)
                  "
                  class="location-segment flex items-center"
                  data-location="country"
                >
                  <UIcon
                    name="i-heroicons-globe-asia-australia"
                    class="text-primary-600 mr-1.5 animate-pulse-slow"
                  />
                  <span class="font-medium text-gray-800">{{
                    location?.country || "Bangladesh"
                  }}</span>
                  <span
                    v-if="location?.allOverBangladesh"
                    class="ml-2 text-xs bg-primary-100 text-primary-700 px-2 py-0.5 rounded-full"
                  >
                    All over {{ location?.country || "Bangladesh" }}
                  </span>
                </div>

                <!-- Show state, city, upazila only if not allOverBangladesh -->
                <template v-if="!location?.allOverBangladesh">
                  <div
                    v-if="location?.state"
                    class="location-segment flex items-center"
                    data-location="state"
                  >
                    <UIcon
                      name="i-heroicons-map"
                      class="text-primary-600 mr-1.5 animate-pulse-slow"
                    />
                    <span class="font-medium text-gray-800">{{
                      location?.state
                    }}</span>
                    <UIcon
                      v-if="location?.city"
                      name="i-heroicons-chevron-right"
                      class="mx-1.5 text-gray-600"
                    />
                  </div>

                  <div
                    v-if="location?.city"
                    class="location-segment flex items-center"
                    data-location="city"
                  >
                    <UIcon
                      name="i-heroicons-building-office-2"
                      class="text-primary-600 mr-1.5 location-icon"
                    />
                    <span class="font-medium text-gray-800">{{
                      location?.city
                    }}</span>
                    <UIcon
                      v-if="location?.upazila"
                      name="i-heroicons-chevron-right"
                      class="mx-1.5 text-gray-600"
                    />
                  </div>

                  <div
                    v-if="location?.upazila"
                    class="location-segment flex items-center"
                    data-location="upazila"
                  >
                    <UIcon
                      name="i-heroicons-home-modern"
                      class="text-primary-600 mr-1.5 location-icon"
                    />
                    <span class="font-medium text-gray-800">{{
                      location?.upazila
                    }}</span>
                  </div>
                </template>
              </div>
            </div>
          </div>
          <UTooltip text="Change Location" class="me-auto">
            <UButton
              icon="i-heroicons-map-pin"
              size="md"
              color="primary"
              variant="ghost"
              trailing-icon="i-heroicons-pencil-square"
              class="edit-location-btn ml-2 relative overflow-hidden"
              @click="handleClearLocation"
            >
              <span class="sr-only">Edit Location</span>
            </UButton>
          </UTooltip>
          <UButtonGroup size="md" class="flex-1 hidden md:flex md:w-2/4">
            <UInput
              icon="i-heroicons-magnifying-glass-20-solid"
              size="md"
              color="white"
              :trailing="false"
              placeholder="Search..."
              v-model="searchTerm"
              @keyup.enter="handleSearch"
              class="w-full"
              :ui="{
                padding: {
                  md: 'sm:py-2.5',
                },
              }"
            />

            <UButton
              size="md"
              :loading="isSearching"
              variant="solid"
              :label="t('search')"
              @click="handleSearch"
              class="sm:h-10 max-sm:!text-base w-24 justify-center bg-primary-600 text-white hover:bg-primary-700 transition-colors duration-200"
              :ui="{
                padding: {
                  md: 'sm:py-2.5',
                },
              }"
            />
          </UButtonGroup>
        </div>
      </div>
      <UButtonGroup size="md" class="flex-1 flex md:hidden md:w-2/4 px-2 pb-2">
        <UInput
          icon="i-heroicons-magnifying-glass-20-solid"
          size="md"
          color="white"
          :trailing="false"
          placeholder="Search..."
          v-model="searchTerm"
          @keyup.enter="handleSearch"
          class="w-full"
          :ui="{
            padding: {
              md: 'sm:py-2.5',
            },
          }"
        />

        <UButton
          size="md"
          :loading="isSearching"
          color="primary"
          variant="solid"
          icon="i-heroicons-magnifying-glass-20-solid"
          @click="handleSearch"
          class="sm:h-10 max-sm:!text-base w-12 justify-center"
          :ui="{
            padding: {
              md: 'sm:py-2.5',
            },
          }"
        />
      </UButtonGroup>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed } from "vue";

// Define props
const props = defineProps({
  initialSearchTerm: {
    type: String,
    default: "",
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
});

// Define emits
const emit = defineEmits(["search", "clear-location"]);

// Composables
const { location, clearLocation } = useLocation();
const { t } = useI18n();

// Reactive data
const searchTerm = ref(props.initialSearchTerm);

// Watch for prop changes
watch(
  () => props.initialSearchTerm,
  (newValue) => {
    searchTerm.value = newValue;
  }
);

// Methods
const handleSearch = () => {
  emit("search", searchTerm.value?.trim() || "");
};

const handleClearLocation = () => {
  clearLocation();
  emit("clear-location");
};
</script>

<style scoped>
.location-icon {
  transition: transform 0.2s ease;
}

.location-segment:hover .location-icon {
  transform: scale(1.1);
}

.edit-location-btn {
  transition: all 0.2s ease;
}

.edit-location-btn:hover {
  transform: translateY(-1px);
}

/* Animation for pulse effect */
@keyframes pulse-slow {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse-slow {
  animation: pulse-slow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>
