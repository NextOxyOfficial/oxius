<template>
  <div class="min-h-screen bg-gray-50 py-8 px-4 sm:px-6 lg:px-8">
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="text-center mb-6">
        <h1 class="text-xl font-semibold text-gray-800 sm:text-xl">
          {{ $t("mobile_recharge") }}
        </h1>
        <p class="mt-2 text-base sm:text-xl text-gray-600">
          {{ $t("recharge_package_choice") }}
        </p>
      </div>
      <!-- Search and Filter -->
      <div class="max-w-md mx-auto">
        <div class="relative">
          <UInput
            v-model="searchQuery"
            type="text"
            :placeholder="t('search_packages')"
            class="w-full"
            size="md"
            icon="i-heroicons-magnifying-glass"
          />
        </div>
        <!-- Operator Filter -->
        <div class="my-6 text-center">
          <h3 class="text-sm font-medium text-gray-800 mb-3">
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
                <img :src="operator.icon" alt="operator-logo" class="h-5 w-5" />
              </div>
              <span class="mt-2 text-xs md:text-base font-medium">{{
                operator.name
              }}</span>
            </button>
          </div>
        </div>
        <div class="my-4 flex gap-2 justify-center flex-wrap">
          <UButton
            v-for="(filter, index) in filters"
            :key="index"
            @click="activeFilter = filter.value"
            :variant="activeFilter === filter.value ? 'solid' : 'outline'"
            :color="activeFilter === filter.value ? 'green' : 'gray'"
            size="sm"
            class="transition-all duration-200 hover:scale-105"
          >
            {{ filter.label }}
          </UButton>
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
          <h2 class="text-xl font-semibold text-gray-800 mb-4">
            {{ $t("popular_packages") }}
          </h2>
          <UButton
            :label="t('recharge_history')"
            icon="i-heroicons-clock"
            @click="isHistory = true"
            size="md"
            variant="outline"
            color="blue"
            class="transition-all duration-200 hover:scale-105"
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
                    {{ capitalizeFirstLetter(pack.type) }}
                  </span>
                  <div class="flex justify-between px-0.5 mt-1">
                    <h3 class="mt-1 text-base font-semibold text-gray-800">
                      {{ pack.price }}
                    </h3>
                    <img
                      v-if="pack.operator_details && pack.operator_details.icon"
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
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-light-wifi-sharp"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-600"
                  />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-uit-calender"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-600"
                  />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-call-outline-rounded"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-600"
                  />
                  <span>{{ pack.calls }}</span>
                </div>
              </div>
              <div class="mt-3">
                <UButton
                  @click="selectPackage(pack)"
                  color="green"
                  size="sm"
                  class="w-full transition-all duration-200 hover:scale-105 shadow-sm hover:shadow-md"
                  :ui="{ rounded: 'rounded-lg' }"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-bolt" class="w-4 h-4" />
                  </template>
                  {{ $t("recharge_now") }}
                </UButton>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- All Packages -->
      <div>
        <h2 class="text-xl font-semibold text-gray-800 mb-4">
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
                    {{ capitalizeFirstLetter(pack.type) }}
                  </span>
                  <div class="flex justify-between px-0.5 mt-1">
                    <h3 class="mt-1 text-base font-semibold text-gray-800">
                      {{ pack.price }}
                    </h3>
                    <img
                      v-if="pack.operator_details && pack.operator_details.icon"
                      :src="pack.operator_details.icon"
                      :alt="pack.operator_details.name"
                      class="size-5"
                    />
                  </div>
                </div>
              </div>

              <div class="mt-2 space-y-1">
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-light-wifi-sharp"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-600"
                  />
                  <span>{{ pack.data }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-uit-calender"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-600"
                  />
                  <span>{{ pack.validity }}</span>
                </div>
                <div class="flex items-center text-sm text-gray-600">
                  <UIcon
                    name="i-material-symbols-call-outline-rounded"
                    class="w-3.5 h-3.5 mr-1.5 text-gray-600"
                  />
                  <span>{{ pack.calls }}</span>
                </div>
              </div>
              <div class="mt-3">
                <UButton
                  @click="selectPackage(pack)"
                  color="green"
                  size="sm"
                  class="w-full transition-all duration-200 hover:scale-105 shadow-sm hover:shadow-md"
                  :ui="{ rounded: 'rounded-lg' }"
                  block
                >
                  <template #leading>
                    <UIcon name="i-heroicons-bolt" class="w-4 h-4" />
                  </template>
                  {{ $t("recharge_now") }}
                </UButton>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recharge Modal -->
    <UModal
      v-model="showRechargeModal"
      fullscreen
      :ui="{
        fullscreen: 'max-w-xl w-full h-auto',
      }"
    >
      <UCard
        :ui="{
          ring: '',
          divide: 'divide-y divide-gray-100 dark:divide-gray-800',
        }"
      >
        <template #header>
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              Confirm Recharge
            </h3>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark-20-solid"
              class="-my-1"
              @click="showRechargeModal = false"
            />
          </div>
        </template>

        <div class="space-y-4">
          <!-- Package Details -->
          <div class="p-4 bg-gray-50 rounded-lg">
            <div class="flex justify-between mb-2">
              <span class="text-gray-600">Package</span>
              <span class="font-medium">{{
                capitalizeFirstLetter(selectedPackage?.type)
              }}</span>
            </div>
            <div class="flex justify-between mb-2">
              <span class="text-gray-600">Amount</span>
              <span class="font-medium">{{ selectedPackage?.price }}</span>
            </div>
            <div class="flex justify-between mb-2">
              <span class="text-gray-600">Data</span>
              <span class="font-medium">{{ selectedPackage?.data }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600">Validity</span>
              <span class="font-medium">{{ selectedPackage?.validity }}</span>
            </div>
          </div>

          <!-- Balance warning -->
          <div
            v-if="!hasSufficientBalance"
            class="p-3 bg-red-50 border border-red-200 rounded-md text-red-600 text-sm"
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
              class="w-full mt-3 transition-all duration-200 hover:scale-105"
              size="sm"
              block
            >
              <template #leading>
                <UIcon name="i-heroicons-plus" class="w-4 h-4" />
              </template>
              Add Funds
            </UButton>
          </div>

          <!-- Only show phone input field if balance is sufficient -->
          <div v-if="hasSufficientBalance">
            <label
              for="phone"
              class="block text-sm font-medium text-gray-800 mb-2"
              >Mobile Number</label
            >
            <UInput
              v-model="phoneNumber"
              type="tel"
              id="phone"
              placeholder="Enter mobile number"
              class="w-full"
            />
          </div>
          <!-- Action Buttons -->
          <div class="flex space-x-3 pt-4">
            <UButton
              @click="showRechargeModal = false"
              color="gray"
              variant="outline"
              class="flex-1 transition-all duration-200 hover:scale-105"
              block
              size="lg"
            >
              <template #leading>
                <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
              </template>
              Cancel
            </UButton>
            <UButton
              @click="handleRecharge"
              :disabled="!hasSufficientBalance"
              color="green"
              class="flex-1 transition-all duration-200 hover:scale-105"
              :class="{
                'opacity-50 cursor-not-allowed': !hasSufficientBalance,
              }"
              block
              size="lg"
            >
              <template #leading>
                <UIcon name="i-heroicons-bolt" class="w-4 h-4" />
              </template>
              {{ hasSufficientBalance ? "Recharge" : "Insufficient Balance" }}
            </UButton>
          </div>
        </div>
      </UCard>
    </UModal>
    <!-- Success Toast -->
    <UNotification
      v-if="showToast"
      title="Recharge Successful!"
      description="Your mobile recharge has been processed successfully."
      icon="i-heroicons-check-circle"
      color="green"
      :timeout="3000"
      @close="showToast = false"
      class="fixed bottom-4 right-4 z-50 shadow-lg"
    />
    <UModal
      v-model="isHistory"
      :ui="{
        wrapper: 'fixed inset-0 z-50 overflow-y-auto',
        inner: 'fixed inset-0 overflow-y-auto',
        container: 'flex min-h-full items-start justify-center text-center',
        padding: 'sm:p-6',
        margin: 'mt-20 sm:mt-16',
      }"
    >
      <UCard
        :ui="{
          ring: '',
          divide: 'divide-y divide-gray-100 dark:divide-gray-800',
        }"
      >
        <template #header>
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              {{ $t("recharge_history") }}
            </h3>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark-20-solid"
              class="-my-1"
              @click="isHistory = false"
            />
          </div>
        </template>

        <LazyMobileRechargeHistory />
      </UCard>
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
const showRechargeModal = ref(false);

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

function capitalizeFirstLetter(str) {
  return str ? str.charAt(0).toUpperCase() + str.slice(1) : "";
}

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
  showRechargeModal.value = true;
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
    const res = await post("/mobile-recharge/recharges/", submitValues);
    if (res.data) {
      toast.add({ title: "Recharge successful!", color: "green" });
      showRechargeModal.value = false;
      selectedPackage.value = null;
      phoneNumber.value = "";
      showToast.value = true;
      setTimeout(() => {
        showToast.value = false;
      }, 3000);
      jwtLogin(); // Refresh user balance
    }
  } catch (err) {
    console.error(err);
    toast.add({
      title: err.response?.data?.message || "Recharge failed",
      color: "red",
    });
  }
}

// Add this computed property to check balance sufficiency
const hasSufficientBalance = computed(() => {
  if (!selectedPackage.value) return true;
  const packagePrice = parseFloat(selectedPackage.value.price);
  const userBalance = parseFloat(user.value?.user.balance || 0);
  return packagePrice <= userBalance;
});
</script>
