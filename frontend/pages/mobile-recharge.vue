<template>
  <div class="min-h-screen bg-gray-50 py-8 px-4 sm:px-6 lg:px-8">
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="text-center mb-6">
        <h1 class="text-xl font-semibold text-gray-700 sm:text-xl">
          {{ $t("mobile_recharge") }}
        </h1>
        <p class="mt-2 text-base sm:text-xl text-gray-500">
          {{ $t("recharge_package_choice") }}
        </p>
      </div>

      <!-- Search and Filter -->
      <div class="max-w-md mx-auto">
        <div class="relative">
          <input
            v-model="searchQuery"
            type="text"
            class="w-full px-4 py-1.5 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent"
            :placeholder="t('search_packages')"
          />
          <span class="absolute right-3 top-2.5 text-gray-500">
            <UIcon name="i-gg-search" class="size-4" />
          </span>
        </div>

        <!-- Operator Filter -->
        <div class="my-6 text-center">
          <h3 class="text-sm font-medium text-gray-700 mb-3">
            {{ $t("select_operator") }}
          </h3>
          <div class="flex justify-center gap-4">
            <button
              v-for="(operator, index) in operators"
              :key="index"
              @click="selectedOperator = operator.id"
              :class="[
                'flex flex-col items-center justify-center p-3 rounded-lg border transition-all',
                selectedOperator === operator.id
                  ? 'border-green-500 bg-green-50'
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
        <div class="my-4 flex gap-1.5 justify-center">
          <button
            v-for="(filter, index) in filters"
            :key="index"
            @click="activeFilter = filter.value"
            :class="[
              'px-3.5 py-2 rounded-full text-xs sm:text-sm font-medium transition-colors',
              activeFilter === filter.value
                ? 'bg-green-500 text-white'
                : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50',
            ]"
          >
            {{ filter.label }}
          </button>
        </div>
      </div>
      <div class="text-slate-700">
        <span>{{ $t("available_balance") }}</span
        >:&nbsp;
        <span><span class="text-xl">৳</span> {{ user?.user.balance }}</span>
      </div>
      <!-- Popular Packages -->
      <div class="mb-10 mt-3">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold text-gray-700 mb-4">
            {{ $t("popular_packages") }}
          </h2>
          <UButton
            :label="t('recharge_history')"
            icon="i-icon-park-outline-history-query"
            @click="isHistory = true"
            size="md"
          />
        </div>
        <div
          class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 mx-auto max-w-7xl"
        >
          <div
            v-for="(pack, index) in popularPackages"
            :key="index"
            class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow-sm transition-shadow duration-300"
          >
            <div class="p-2 relative">
              <div class="flex justify-between items-start">
                <div class="w-full">
                  <span
                    class="inline-block px-2 py-0.5 text-xs font-semibold rounded-full capitalize"
                    :class="getTagClass(pack.type)"
                  >
                    {{ pack.type }}
                  </span>
                  <div class="flex justify-between px-0.5 mt-1">
                    <h3 class="mt-1 text-base font-semibold text-gray-700">
                      {{ pack.price }}
                    </h3>
                    <NuxtImg
                      v-if="pack.operator_details"
                      :src="pack.operator_details.icon"
                      :alt="pack.operator_details.name"
                      class="size-5"
                    />
                  </div>
                </div>
                <span
                  v-if="pack.popular"
                  class="bg-amber-100 text-amber-800 text-xs px-2 py-0.5 rounded-full font-medium absolute top-2 right-2"
                  >Popular</span
                >
              </div>

              <div class="mt-2 space-y-1">
                <div class="flex items-center text-sm text-gray-500">
                  <UIcon
                    name="i-material-symbols-light-wifi-sharp"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-500"
                  />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-500">
                  <UIcon
                    name="i-uit-calender"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-500"
                  />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-500">
                  <UIcon
                    name="i-material-symbols-call-outline-rounded"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-500"
                  />
                  <span>{{ pack.calls }}</span>
                </div>
              </div>

              <div class="mt-3">
                <button
                  @click="selectPackage(pack)"
                  class="w-full py-1.5 px-3 bg-green-500 hover:bg-green-600 text-white text-sm font-medium rounded-md transition-colors duration-200"
                >
                  {{ $t("recharge_now") }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- All Packages -->
      <div>
        <h2 class="text-xl font-semibold text-gray-700 mb-4">
          {{ $t("all_packages") }}
        </h2>
        <div
          class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 mx-auto max-w-7xl"
        >
          <div
            v-for="(pack, index) in filteredPackages"
            :key="index"
            class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow-sm transition-shadow duration-300"
          >
            <div class="p-2 relative">
              <div class="flex justify-between items-start">
                <div class="w-full">
                  <span
                    class="inline-block px-2 py-0.5 text-xs font-semibold rounded-full capitalize"
                    :class="getTagClass(pack.type)"
                  >
                    {{ pack.type }}
                  </span>
                  <div class="flex justify-between px-0.5 mt-1">
                    <h3 class="mt-1 text-base font-semibold text-gray-700">
                      {{ pack.price }}
                    </h3>
                    <NuxtImg
                      v-if="pack.operator_details"
                      :src="pack.operator_details.icon"
                      :alt="pack.operator_details.name"
                      class="size-5"
                    />
                  </div>
                </div>
              </div>

              <div class="mt-2 space-y-1">
                <div class="flex items-center text-sm text-gray-500">
                  <UIcon
                    name="i-material-symbols-light-wifi-sharp"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-500"
                  />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-500">
                  <UIcon
                    name="i-uit-calender"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-500"
                  />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-500">
                  <UIcon
                    name="i-material-symbols-call-outline-rounded"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-500"
                  />
                  <span>{{ pack.calls }}</span>
                </div>
              </div>

              <div class="mt-3">
                <button
                  @click="selectPackage(pack)"
                  class="w-full py-1.5 px-3 bg-green-500 hover:bg-emerald-600 text-white text-sm font-medium rounded-md transition-colors duration-200"
                >
                  {{ $t("recharge_now") }}
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
      class="fixed inset-0 top-10 bottom-10 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
    >
      <div class="bg-white rounded-lg max-w-md w-full p-6 shadow-sm">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-xl font-semibold text-gray-700">Confirm Recharge</h3>
          <button
            @click="selectedPackage = null"
            class="text-gray-500 hover:text-gray-500"
          >
            <x-icon class="w-5 h-5" />
          </button>
        </div>

        <div class="mb-6 p-4 bg-gray-50 rounded-lg">
          <div class="flex justify-between mb-2">
            <span class="text-gray-500">Package</span>
            <span class="font-medium">{{ selectedPackage.type }}</span>
          </div>
          <div class="flex justify-between mb-2">
            <span class="text-gray-500">Amount</span>
            <span class="font-medium">{{ selectedPackage.price }}</span>
          </div>
          <div class="flex justify-between mb-2">
            <span class="text-gray-500">Data</span>
            <span class="font-medium">{{ selectedPackage.data }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-500">Validity</span>
            <span class="font-medium">{{ selectedPackage.validity }}</span>
          </div>
        </div>

        <!-- Balance warning -->
        <div
          v-if="!hasSufficientBalance"
          class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-600 text-sm"
        >
          <div class="flex items-center">
            <UIcon
              name="i-heroicons-exclamation-triangle"
              class="w-5 h-5 mr-2"
            />
            <span>
              Insufficient balance for this recharge. Please add funds to your
              account.
            </span>
          </div>

          <!-- Add a button to navigate to deposit page -->
          <UButton
            to="/deposit-withdraw"
            color="emerald"
            variant="soft"
            class="w-full mt-3"
            size="sm"
          >
            Add Funds
          </UButton>
        </div>

        <!-- Only show phone input field if balance is sufficient -->
        <div v-if="hasSufficientBalance" class="mb-4">
          <label
            for="phone"
            class="block text-sm font-medium text-gray-700 mb-1"
            >Mobile Number</label
          >
          <input
            v-model="phoneNumber"
            type="tel"
            id="phone"
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-green-500 focus:border-green-500"
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
            @click="handleRecharge"
            :disabled="!hasSufficientBalance"
            class="flex-1 py-2 px-4 text-white font-medium rounded-md transition"
            :class="[
              hasSufficientBalance
                ? 'bg-green-500 hover:bg-green-600'
                : 'bg-gray-400 cursor-not-allowed',
            ]"
          >
            {{ hasSufficientBalance ? "Recharge" : "Insufficient Balance" }}
          </button>
        </div>
      </div>
    </div>

    <!-- Success Toast -->
    <div
      v-if="showToast"
      class="fixed bottom-4 right-4 bg-green-500 text-white px-4 py-3 rounded-lg shadow-sm flex items-center"
    >
      <check-circle-icon class="w-5 h-5 mr-2" />
      <span>Recharge successful!</span>
    </div>
    <UModal v-model="isHistory" class="relative">
      <UButton
        icon="i-heroicons-x-mark"
        size="sm"
        variant="solid"
        class="m-3 absolute top-0 right-0 bg-slate-500"
        :trailing="false"
        @click="isHistory = false"
      />
      <MobileRechargeHistory />
    </UModal>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { user, jwtLogin } = useAuth();
const { post } = useApi();
const { t } = useI18n();

const toast = useToast();
const isHistory = ref(false);

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
  { value: "balance", label: "Balance" },
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
      return "bg-gray-100 text-gray-700";
  }
}

function selectPackage(pack) {
  selectedPackage.value = pack;
}

async function handleRecharge() {
  // Skip recharge if balance is insufficient
  if (!hasSufficientBalance.value) {
    toast.add({
      title: "Insufficient balance for this recharge",
      color: "red",
    });
    return;
  }

  // Validate phone number

  const phoneNumberValid = /^(?:\+?88)?01[3-9]\d{8}$/;
  if (!phoneNumber.value || !phoneNumberValid.test(phoneNumber.value)) {
    toast.add({ title: "Please enter a valid phone number", color: "red" });
    return;
  }

  // Proceed with recharge
  const submitValues = {
    package: selectedPackage.value.id,
    phone_number: phoneNumber.value,
    operator: selectedPackage.value.operator,
    amount: selectedPackage.value.price,
  };

  try {
    console.log(submitValues);
    const res = await post("/mobile-recharge/recharges/", submitValues);
    if (res.data) {
      toast.add({ title: "Recharge successful!" });
      isHistory.value = false;
      selectedPackage.value = null;
      jwtLogin();
    }
  } catch (err) {
    console.log(err);
    toast.error(err.response?.data?.message || "Recharge failed");
  }
}

// Add this computed property to check balance sufficiency
const hasSufficientBalance = computed(() => {
  if (!selectedPackage.value) return true;
  const packagePrice = parseFloat(
    selectedPackage.value.price.replace(/[^\d.]/g, "")
  );
  const userBalance = parseFloat(user.value?.user.balance || 0);
  return packagePrice <= userBalance;
});
</script>
