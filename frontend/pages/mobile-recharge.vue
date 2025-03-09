<template>
  <div class="min-h-screen bg-gray-50 py-8 px-4 sm:px-6 lg:px-8">
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="text-center mb-10">
        <h1 class="text-3xl font-bold text-gray-900 sm:text-4xl">
          Mobile Recharge
        </h1>
        <p class="mt-3 text-xl text-gray-500">
          Choose the perfect recharge package for your needs
        </p>
      </div>

      <!-- Search and Filter -->
      <div class="mb-8 max-w-md mx-auto">
        <div class="relative">
          <input
            v-model="searchQuery"
            type="text"
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
            placeholder="Search packages..."
          />
          <span class="absolute right-3 top-3 text-gray-400">
            <UIcon name="i-gg-search" class="w-5 h-5" />
          </span>
        </div>

        <!-- Operator Filter -->
        <div class="my-6 text-center">
          <h3 class="text-sm font-medium text-gray-700 mb-3">
            Select Operator
          </h3>
          <div class="flex justify-center gap-4">
            <button
              v-for="(operator, index) in operators"
              :key="index"
              @click="selectedOperator = operator.id"
              :class="[
                'flex flex-col items-center justify-center p-3 rounded-lg border transition-all',
                selectedOperator === operator.id
                  ? 'border-emerald-500 bg-emerald-50'
                  : 'border-gray-200 bg-white hover:border-gray-300',
              ]"
            >
              <div
                class="w-8 h-8 flex items-center justify-center rounded-full"
                :class="operator.bgColor"
              >
                <img :src="operator.icon" alt="gp-logo" class="h-5 w-5" />
              </div>
              <span class="mt-2 text-xs md:text-base font-medium">{{
                operator.name
              }}</span>
            </button>
          </div>
        </div>
        <div class="mt-4 flex flex-wrap gap-2">
          <button
            v-for="(filter, index) in filters"
            :key="index"
            @click="activeFilter = filter.value"
            :class="[
              'px-4 py-2 rounded-full text-sm font-medium transition-colors',
              activeFilter === filter.value
                ? 'bg-emerald-500 text-white'
                : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50',
            ]"
          >
            {{ filter.label }}
          </button>
        </div>
      </div>

      <!-- Popular Packages -->
      <div class="mb-10">
        <h2 class="text-xl font-semibold text-gray-800 mb-4">
          Popular Packages
        </h2>
        <div
          class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 mx-auto max-w-7xl"
        >
          <div
            v-for="(pack, index) in popularPackages"
            :key="index"
            class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow duration-300"
          >
            <div class="p-2">
              <div class="flex justify-between items-start">
                <div>
                  <span
                    class="inline-block px-2 py-0.5 text-xs font-semibold rounded-full"
                    :class="getTagClass(pack.type)"
                  >
                    {{ pack.type }}
                  </span>
                  <h3 class="mt-1 text-base font-bold text-gray-900">
                    {{ pack.price }}
                  </h3>
                </div>
                <span
                  v-if="pack.popular"
                  class="bg-amber-100 text-amber-800 text-xs px-2 py-0.5 rounded-full font-medium"
                  >Popular</span
                >
              </div>

              <div class="mt-2 space-y-1">
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-light-wifi-sharp"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-400"
                  />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-uit-calender"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-400"
                  />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-call-outline-rounded"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-400"
                  />
                  <span>{{ pack.calls }}</span>
                </div>
              </div>

              <div class="mt-3">
                <button
                  @click="selectPackage(pack)"
                  class="w-full py-1.5 px-3 bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-medium rounded-md transition-colors duration-200"
                >
                  Recharge Now
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- All Packages -->
      <div>
        <h2 class="text-xl font-semibold text-gray-800 mb-4">All Packages</h2>
        <div
          class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 mx-auto max-w-7xl"
        >
          <div
            v-for="(pack, index) in filteredPackages"
            :key="index"
            class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow duration-300"
          >
            <div class="p-2">
              <div class="flex justify-between items-start">
                <div>
                  <span
                    class="inline-block px-2 py-0.5 text-xs font-semibold rounded-full"
                    :class="getTagClass(pack.type)"
                  >
                    {{ pack.type }}
                  </span>
                  <h3 class="mt-1 text-base font-bold text-gray-900">
                    {{ pack.price }}
                  </h3>
                </div>
              </div>

              <div class="mt-2 space-y-1">
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-light-wifi-sharp"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-400"
                  />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-uit-calender"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-400"
                  />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-call-outline-rounded"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-400"
                  />
                  <span>{{ pack.calls }}</span>
                </div>
              </div>

              <div class="mt-3">
                <button
                  @click="selectPackage(pack)"
                  class="w-full py-1.5 px-3 bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-medium rounded-md transition-colors duration-200"
                >
                  Recharge Now
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recharge Modal -->
    <div
      v-if="selectedPackage"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
    >
      <div class="bg-white rounded-lg max-w-md w-full p-6 shadow-xl">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-xl font-bold text-gray-900">Confirm Recharge</h3>
          <button
            @click="selectedPackage = null"
            class="text-gray-400 hover:text-gray-500"
          >
            <x-icon class="w-5 h-5" />
          </button>
        </div>

        <div class="mb-6 p-4 bg-gray-50 rounded-lg">
          <div class="flex justify-between mb-2">
            <span class="text-gray-600">Package</span>
            <span class="font-medium">{{ selectedPackage.type }}</span>
          </div>
          <div class="flex justify-between mb-2">
            <span class="text-gray-600">Amount</span>
            <span class="font-medium">{{ selectedPackage.price }}</span>
          </div>
          <div class="flex justify-between mb-2">
            <span class="text-gray-600">Data</span>
            <span class="font-medium">{{ selectedPackage.data }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600">Validity</span>
            <span class="font-medium">{{ selectedPackage.validity }}</span>
          </div>
        </div>

        <div class="mb-4">
          <label
            for="phone"
            class="block text-sm font-medium text-gray-700 mb-1"
            >Mobile Number</label
          >
          <input
            v-model="phoneNumber"
            type="tel"
            id="phone"
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-emerald-500 focus:border-emerald-500"
            placeholder="Enter mobile number"
          />
        </div>

        <div class="flex space-x-3">
          <button
            @click="selectedPackage = null"
            class="flex-1 py-2 px-4 border border-gray-300 rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            @click="processRecharge"
            class="flex-1 py-2 px-4 bg-emerald-600 hover:bg-emerald-700 text-white font-medium rounded-md"
          >
            Recharge
          </button>
        </div>
      </div>
    </div>

    <!-- Success Toast -->
    <div
      v-if="showToast"
      class="fixed bottom-4 right-4 bg-emerald-500 text-white px-4 py-3 rounded-lg shadow-lg flex items-center"
    >
      <check-circle-icon class="w-5 h-5 mr-2" />
      <span>Recharge successful!</span>
    </div>
  </div>
</template>

<script setup>
const toast = useToast();

const {
  operators,
  popularPackages,
  filteredPackages,
  isLoading,
  error,
  searchQuery,
  activeFilter,
  selectedOperator,
  fetchOperators,
  fetchPackages,
  processRecharge,
} = useMobileRecharge();

const selectedPackage = ref(null);
const phoneNumber = ref("");
const showToast = ref(false);
const filters = ref([
  { value: "all", label: "All" },
  { value: "data", label: "Data" },
  { value: "voice", label: "Voice" },
  { value: "combo", label: "Combo" },
]);
onMounted(() => {
  fetchOperators();
  fetchPackages();
});

function getTagClass(type) {
  switch (type) {
    case "data":
      return "bg-emerald-100 text-emerald-800";
    case "voice":
      return "bg-purple-100 text-purple-800";
    case "combo":
      return "bg-amber-100 text-amber-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
}

function selectPackage(pack) {
  selectedPackage.value = pack;
}

async function handleRecharge() {
  if (!phoneNumber.value) {
    toast.error("Please enter a valid phone number");
    return;
  }

  try {
    await processRecharge(selectedPackage.value.id, phoneNumber.value);
    selectedPackage.value = null;
    showToast.value = true;
    toast.success("Recharge successful!");

    setTimeout(() => {
      showToast.value = false;
    }, 3000);
  } catch (err) {
    toast.error(err || "Recharge failed. Please try again.");
  }
}
</script>
