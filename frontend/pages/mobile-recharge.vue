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
            <search-icon class="w-5 h-5" />
          </span>
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

        <!-- Operator Filter -->
        <div class="mt-6 text-center">
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
                  <wifi-icon class="w-3.5 h-3.5 mr-1.5 text-gray-400" />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <calendar-icon class="w-3.5 h-3.5 mr-1.5 text-gray-400" />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <phone-icon class="w-3.5 h-3.5 mr-1.5 text-gray-400" />
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
                  <wifi-icon class="w-3.5 h-3.5 mr-1.5 text-gray-400" />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <calendar-icon class="w-3.5 h-3.5 mr-1.5 text-gray-400" />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <phone-icon class="w-3.5 h-3.5 mr-1.5 text-gray-400" />
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
import { ref, computed } from "vue";
import {
  Search as SearchIcon,
  Wifi as WifiIcon,
  Calendar as CalendarIcon,
  Phone as PhoneIcon,
  X as XIcon,
  CheckCircle as CheckCircleIcon,
  Signal as SignalIcon,
  Globe as GlobeIcon,
  Zap as ZapIcon,
  Radio as RadioIcon,
} from "lucide-vue-next";

// State
const searchQuery = ref("");
const activeFilter = ref("all");
const selectedPackage = ref(null);
const phoneNumber = ref("");
const showToast = ref(false);
const selectedOperator = ref(1); // Default to first operator

// Filters
const filters = [
  { label: "All Packages", value: "all" },
  { label: "Data", value: "data" },
  { label: "Voice", value: "voice" },
  { label: "Combo", value: "combo" },
];

// Operators
const operators = [
  {
    id: 1,
    name: "Grameenphone",
    icon: "/gp-logo.png",
    bgColor: "bg-green-100",
    iconColor: "text-green-600",
  },
  {
    id: 2,
    name: "Banglalink",
    icon: "/banglalink-logo.png",
    bgColor: "bg-orange-100",
    iconColor: "text-orange-600",
  },
  {
    id: 3,
    name: "Robi",
    icon: "/robi.png",
    bgColor: "bg-red-100",
    iconColor: "text-red-600",
  },
];

// Package data
const allPackages = [
  {
    id: 1,
    type: "data",
    price: "$10",
    data: "5 GB",
    validity: "28 days",
    calls: "No calls included",
    popular: true,
  },
  {
    id: 2,
    type: "voice",
    price: "$15",
    data: "1 GB",
    validity: "30 days",
    calls: "Unlimited calls",
    popular: false,
  },
  {
    id: 3,
    type: "combo",
    price: "$20",
    data: "10 GB",
    validity: "30 days",
    calls: "100 minutes",
    popular: true,
  },
  {
    id: 4,
    type: "data",
    price: "$25",
    data: "20 GB",
    validity: "30 days",
    calls: "No calls included",
    popular: false,
  },
  {
    id: 5,
    type: "combo",
    price: "$30",
    data: "30 GB",
    validity: "30 days",
    calls: "Unlimited calls",
    popular: true,
  },
  {
    id: 6,
    type: "voice",
    price: "$5",
    data: "500 MB",
    validity: "7 days",
    calls: "50 minutes",
    popular: false,
  },
  {
    id: 7,
    type: "data",
    price: "$8",
    data: "3 GB",
    validity: "14 days",
    calls: "No calls included",
    popular: false,
  },
  {
    id: 8,
    type: "combo",
    price: "$40",
    data: "50 GB",
    validity: "60 days",
    calls: "Unlimited calls",
    popular: false,
  },
];

// Computed properties
const popularPackages = computed(() => {
  return allPackages.filter((pack) => pack.popular);
});

const filteredPackages = computed(() => {
  let filtered = allPackages;

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(
      (pack) =>
        pack.type.toLowerCase().includes(query) ||
        pack.price.toLowerCase().includes(query) ||
        pack.data.toLowerCase().includes(query)
    );
  }

  // Apply type filter
  if (activeFilter.value !== "all") {
    filtered = filtered.filter((pack) => pack.type === activeFilter.value);
  }

  // In a real app, you would filter by operator here
  // For demo purposes, we'll just return the filtered packages

  return filtered;
});

// Methods
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

function processRecharge() {
  if (!phoneNumber.value) {
    alert("Please enter a valid phone number");
    return;
  }

  // Here you would typically make an API call to process the recharge
  // For demo purposes, we'll just show a success message
  selectedPackage.value = null;
  showToast.value = true;

  // Hide toast after 3 seconds
  setTimeout(() => {
    showToast.value = false;
  }, 3000);
}
</script>
