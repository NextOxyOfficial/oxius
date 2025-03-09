<template>
  <div class="transaction-history h-max">
    <h1 class="text-3xl font-bold text-center mb-2">Transaction History</h1>
    <p class="text-center text-gray-600 mb-6">
      View your recent mobile recharge transactions
    </p>

    <div class="filters mb-6">
      <div class="filter-buttons flex flex-wrap gap-2">
        <button
          @click="activeFilter = 'all'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'all'
              ? 'bg-emerald-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          All Transactions
        </button>
        <button
          @click="activeFilter = 'data'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'data'
              ? 'bg-emerald-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          Data
        </button>
        <button
          @click="activeFilter = 'voice'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'voice'
              ? 'bg-emerald-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          Voice
        </button>
        <button
          @click="activeFilter = 'combo'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'combo'
              ? 'bg-emerald-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          Combo
        </button>
      </div>
    </div>

    <div class="transactions overflow-auto h-[460px]">
      <div
        v-if="filteredTransactions.length === 0"
        class="text-center py-8 text-gray-500"
      >
        No transactions found
      </div>

      <div
        v-for="(transaction, index) in filteredTransactions"
        :key="index"
        class="transaction-item border rounded-lg p-3 mb-3 hover:shadow-md transition-shadow"
      >
        <div class="flex justify-between items-start">
          <div>
            <div class="flex items-center gap-2">
              <div
                class="operator-icon w-6 h-6 rounded-full flex items-center justify-center"
                :class="getOperatorClass(transaction.operator)"
              >
                <component
                  :is="getOperatorIcon(transaction.operator)"
                  class="w-4 h-4"
                />
              </div>
              <div>
                <h3 class="font-semibold">{{ transaction.operator }}</h3>
                <p class="text-sm text-gray-600">
                  {{ formatDate(transaction.date) }}
                </p>
              </div>
            </div>
          </div>
          <div class="text-right">
            <span class="text-base font-bold">${{ transaction.amount }}</span>
            <div
              class="package-type text-xs px-2 py-1 rounded-full inline-block mt-1 ml-1"
              :class="getPackageClass(transaction.packageType)"
            >
              {{ transaction.packageType }}
            </div>
          </div>
        </div>

        <div class="mt-2 text-xs text-gray-700">
          <div class="grid grid-cols-2 gap-1">
            <div>
              <span class="text-gray-500">Data:</span> {{ transaction.data }}
            </div>
            <div>
              <span class="text-gray-500">Duration:</span>
              {{ transaction.duration }} days
            </div>
            <div>
              <span class="text-gray-500">Calls:</span> {{ transaction.calls }}
            </div>
            <div>
              <span class="text-gray-500">Status: </span>
              <span
                :class="
                  transaction.status === 'Completed'
                    ? 'text-green-600'
                    : 'text-orange-500'
                "
              >
                {{ transaction.status }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="pagination flex justify-center mt-6 gap-2">
      <button
        @click="currentPage = Math.max(1, currentPage - 1)"
        :disabled="currentPage === 1"
        class="px-3 py-1 rounded border disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Previous
      </button>
      <button
        v-for="page in totalPages"
        :key="page"
        @click="currentPage = page"
        :class="[
          'px-3 py-1 rounded border',
          currentPage === page ? 'bg-emerald-500 text-white' : '',
        ]"
      >
        {{ page }}
      </button>
      <button
        @click="currentPage = Math.min(totalPages, currentPage + 1)"
        :disabled="currentPage === totalPages"
        class="px-3 py-1 rounded border disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Next
      </button>
    </div>
  </div>
</template>

<script setup>
import { WifiIcon, PhoneIcon, ZapIcon } from "lucide-vue-next";
definePageMeta({
  layout: "dashboard",
});
const { get } = useApi();
const { user } = useAuth();

const searchQuery = ref("");
const activeFilter = ref("all");
const currentPage = ref(1);
const itemsPerPage = 5;

// Sample transaction data based on the packages shown in the screenshot
const transactions = ref([
  {
    id: "TRX-78945",
    date: new Date(2023, 9, 15, 14, 30),
    operator: "Grameenphone",
    packageType: "data",
    amount: 10,
    data: "5GB",
    duration: 28,
    calls: "No calls included",
    status: "Completed",
  },
  {
    id: "TRX-78946",
    date: new Date(2023, 9, 10, 9, 15),
    operator: "Banglalink",
    packageType: "combo",
    amount: 20,
    data: "10GB",
    duration: 30,
    calls: "100 minutes",
    status: "Completed",
  },
  {
    id: "TRX-78947",
    date: new Date(2023, 9, 5, 18, 45),
    operator: "Robi",
    packageType: "combo",
    amount: 30,
    data: "30GB",
    duration: 30,
    calls: "Unlimited calls",
    status: "Completed",
  },
  {
    id: "TRX-78948",
    date: new Date(2023, 8, 25, 11, 20),
    operator: "Grameenphone",
    packageType: "voice",
    amount: 15,
    data: "1GB",
    duration: 30,
    calls: "Unlimited calls",
    status: "Completed",
  },
  {
    id: "TRX-78949",
    date: new Date(2023, 8, 20, 16, 10),
    operator: "Banglalink",
    packageType: "data",
    amount: 25,
    data: "20GB",
    duration: 30,
    calls: "No calls included",
    status: "Completed",
  },
  {
    id: "TRX-78950",
    date: new Date(2023, 8, 15, 10, 5),
    operator: "Robi",
    packageType: "combo",
    amount: 30,
    data: "30GB",
    duration: 30,
    calls: "Unlimited calls",
    status: "Completed",
  },
  {
    id: "TRX-78951",
    date: new Date(2023, 8, 10, 9, 30),
    operator: "Grameenphone",
    packageType: "data",
    amount: 10,
    data: "5GB",
    duration: 28,
    calls: "No calls included",
    status: "Completed",
  },
  {
    id: "TRX-78952",
    date: new Date(2023, 8, 5, 14, 45),
    operator: "Banglalink",
    packageType: "combo",
    amount: 20,
    data: "10GB",
    duration: 30,
    calls: "100 minutes",
    status: "Processing",
  },
]);

const { data } = await get(`/mobile-recharge/recharges/`);
transactions.value = data;

const filteredTransactions = computed(() => {
  let result = transactions.value;

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      (t) =>
        t.operator.toLowerCase().includes(query) ||
        t.packageType.toLowerCase().includes(query) ||
        t.amount.toString().includes(query) ||
        t.id.toLowerCase().includes(query)
    );
  }

  // Apply package type filter
  if (activeFilter.value !== "all") {
    result = result.filter((t) => t.packageType === activeFilter.value);
  }

  // Apply pagination
  const startIndex = (currentPage.value - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;

  return result.slice(startIndex, endIndex);
});

const totalTransactions = computed(() => {
  let result = transactions.value;

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      (t) =>
        t.operator.toLowerCase().includes(query) ||
        t.packageType.toLowerCase().includes(query) ||
        t.amount.toString().includes(query) ||
        t.id.toLowerCase().includes(query)
    );
  }

  // Apply package type filter
  if (activeFilter.value !== "all") {
    result = result.filter((t) => t.packageType === activeFilter.value);
  }

  return result.length;
});

const totalPages = computed(() => {
  return Math.ceil(totalTransactions.value / itemsPerPage);
});

// Helper functions
const formatDate = (date) => {
  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
};

const getPackageClass = (packageType) => {
  switch (packageType) {
    case "data":
      return "bg-green-100 text-green-800";
    case "voice":
      return "bg-purple-100 text-purple-800";
    case "combo":
      return "bg-amber-100 text-amber-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getOperatorClass = (operator) => {
  switch (operator) {
    case "Grameenphone":
      return "bg-green-100 text-green-800";
    case "Banglalink":
      return "bg-orange-100 text-orange-800";
    case "Robi":
      return "bg-red-100 text-red-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getOperatorIcon = (operator) => {
  switch (operator) {
    case "Grameenphone":
      return WifiIcon;
    case "Banglalink":
      return ZapIcon;
    case "Robi":
      return PhoneIcon;
    default:
      return WifiIcon;
  }
};
</script>

<style scoped>
.transaction-history {
  max-width: 800px;
  margin: 0 auto;
  padding: 1.5rem;
}

@media (max-width: 640px) {
  .transaction-history {
    padding: 1rem;
  }
}
</style>
