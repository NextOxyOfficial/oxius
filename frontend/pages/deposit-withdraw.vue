<template>
  <PublicSection>
    <h1 class="text-center text-2xl md:text-4xl my-8">
      {{ $t("deposit_withdraw") }}
    </h1>
    <UContainer>
      <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
      <UDivider label="" class="mb-8" />

      <div class="my-5 flex justify-center">
        <UButton
          :color="`${currentTab == 1 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-e-none',
          }"
          @click="currentTab = 1"
          >{{ $t("diposit") }}</UButton
        >
        <UButton
          :color="`${currentTab == 2 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-s-none rounded-e-none',
          }"
          @click="currentTab = 2"
          >{{ $t("withdraw") }}</UButton
        >
        <UButton
          :color="`${currentTab == 3 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-s-none',
          }"
          @click="currentTab = 3"
          >{{ $t("transfer") }}</UButton
        >
      </div>
      <div class="flex items-center">
        <div v-if="currentTab === 1">
          <div class="space-y-2">
            <UInput
              placeholder="Enter Amount"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="amount"
              amount
            />
          </div>
          <p v-if="depositErrors.amount" class="text-sm text-red-500">Please enter an amount</p>
          <div class="mt-4">
            <img src="/static/frontend/images/payment.png" class="w-60" alt="Payment Method" />
          </div>
          <div class="my-5">
            <UFormGroup
              class="flex flex-row-reverse gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
            >
              <template #label>
                I accept
                <ULink
                  to="/terms/"
                  active-class="text-primary"
                  inactive-class="text-gray-500 dark:text-gray-400"
                  >Terms & Condition</ULink
                >,
                <ULink
                  to="/privacy/"
                  active-class="text-primary"
                  inactive-class="text-gray-500 dark:text-gray-400"
                  >Privacy Policy</ULink
                >.
              </template>
              <UCheckbox name="check" v-model="policy" />
            </UFormGroup>
          </div>
          <p v-if="depositErrors.policy" class="text-sm text-red-500">Please select this field</p>
          <div class="my-2 space-x-3">
            <UButton
              v-if="
                user.user.name &&
                user.user.address &&
                user.user.phone &&
                user.user.city &&
                user.user.zip
              "
              size="sm"
              @click="deposit"
              :loading="isLoading"
              >{{ $t("diposit") }}</UButton
            >
            <UButton v-else size="sm" @click="isOpen = true">Deposit</UButton>
          </div>
        </div>
        <div v-if="currentTab === 2">
          <div class="my-3">
            <URadioGroup
              v-model="selected"
              :options="options"
              :ui="{}"
              :ui-radio="{
                wrapper: 'items-center',
              }"
              class="radio-center"
            >
              <template #label="{ option }">
                <img
                  :src="'/static/frontend/images/' + option.icon"
                  class="size-10 object-contain inline-block"
                />
              </template>
            </URadioGroup>
          </div>
          <p v-if="errors?.selected" class="text-sm text-red-500">Please enter a payment method</p>
          <div class="mb-3">
            <UInput
              v-if="selected === 'nagad'"
              placeholder="Enter Nagad Number"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="payment_number"
            />

            <UInput
              v-if="selected === 'bkash'"
              placeholder="Enter Bkash Number"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="payment_number"
            />
            <UInput
              v-if="selected === 'rocket'"
              placeholder="Enter Rocket Number"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="rocket"
            />
            <p v-if="errors?.payment_number" class="text-sm text-red-500">
              Please enter a payment number
            </p>
          </div>
          <div class="space-y-2">
            <UInput
              placeholder="Enter Amount"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="withdrawAmount"
              amount
            />
            <p v-if="errors?.withdrawAmount" class="text-sm text-red-500">
              Please enter an amount
            </p>
            <p class="text-sm">
              Total Deduction:
              {{ withdrawAmount * 1 + (withdrawAmount * 2.95) / 100 }}
            </p>
            <p class="text-sm pt-2">
              <span class="text-red-500">* </span>
              <span class="inline-flex items-center">
                Minimum withdrawal
                <UIcon name="i-mdi:currency-bdt" class="text-base" />200</span
              >
            </p>
            <p class="text-sm"><span class="text-red-500">*</span> 2.95% Charges applicable</p>

            <p v-if="errors?.insufficient" class="text-sm text-red-500">
              You do not have enough balance
            </p>
          </div>
          <div class="my-5">
            <UFormGroup
              class="flex flex-row-reverse gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
            >
              <template #label>
                I accept
                <ULink
                  to="/terms/"
                  active-class="text-primary"
                  inactive-class="text-gray-500 dark:text-gray-400"
                  >terms & condition</ULink
                >,
                <ULink
                  to="/privacy/"
                  active-class="text-primary"
                  inactive-class="text-gray-500 dark:text-gray-400"
                  >privacy policy</ULink
                >.
              </template>
              <UCheckbox name="check" v-model="policy" />
            </UFormGroup>

            <p v-if="errors?.policy" class="text-sm text-red-500">Check this field</p>
          </div>
          <div class="my-2 space-x-3 mb-4">
            <!-- <UButton size="sm" @click="deposit">Deposit</UButton> -->
            <UButton
              @click="withdraw"
              variant="solid"
              v-if="
                user.user.name &&
                user.user.address &&
                user.user.phone &&
                user.user.city &&
                user.user.zip
              "
              >{{ $t("withdraw") }}</UButton
            >
            <UButton v-else size="sm" @click="isOpen = true">{{ $t("withdraw") }}</UButton>
          </div>
        </div>
        <div v-if="currentTab === 3">
          <UFormGroup label="User Email/Phone" class="mb-4">
            <UInput
              type="text"
              size="md"
              color="white"
              placeholder="Email/Phone"
              v-model="transfer.contact"
            />
            <p class="text-sm text-red-500">{{ transferErrors.contact }}</p>
            <UInput
              type="text"
              size="md"
              color="white"
              placeholder="Amount"
              class="my-3"
              v-model="transfer.payable_amount"
            />
            <p class="text-sm text-red-500">
              {{ transferErrors.payable_amount }}
            </p>
            <UButton
              :loading="isLoading"
              size="md"
              color="primary"
              variant="solid"
              @click="sendToUser"
              >{{ $t("transfer") }}</UButton
            >
          </UFormGroup>
          <p class="text-sm text-red-500">{{ transferErrors.user }}</p>
        </div>
      </div>
      <div class="flex flex-col md:flex-row justify-between">
        <p class="text-lg py-2 max-w-72 w-full mb-3 text-green-800 dark:text-green-600 font-bold">
          <span class="inline-flex items-center"
            >{{ $t("available_balance") }}:&nbsp;
            <UIcon name="i-mdi:currency-bdt" class="" />
            {{ user.user.balance }}
          </span>
        </p>
      </div>
      <h3 class="text-center text-lg md:text-3xl font-semibold mt-8" v-if="statements?.length">
        {{ $t("transaction_history") }}
      </h3>

      <UTable
        :rows="statements"
        :columns="columns"
        class="mb-8 mt-4"
        v-if="statements?.length"
        :ui="{
          th: {
            color: 'text-gray-900 dark:text-slate-700',
          },
          td: {
            color: 'text-gray-500 dark:text-slate-500',
          },
        }"
      >
        <template #created_at-data="{ row }">
          <p>{{ formatDate(row.created_at) }}</p>
        </template>
        <template #payment_method-data="{ row }">
          <p class="uppercase">
            {{ row.transaction_type }} -
            {{ row.payment_method }}
          </p>
        </template>
        <template #bank_status-data="{ row }">
          <p
            class="capitalize font-semibold"
            :class="
              row.bank_status.toLowerCase() === 'pending' ? 'text-yellow-500' : 'text-green-500'
            "
          >
            {{ row.bank_status }}
          </p>
        </template>
      </UTable>
      <UCard v-else class="py-16 text-center">
        <p>{{ $t("no_transactions_found") }}</p>
      </UCard>
    </UContainer>
    <UModal v-model="isOpen">
      <div class="p-4 text-center space-y-3">
        <h3 class="text-lg font-semibold">Profile Incomplete!</h3>
        <p>Please complete your profile to make transactions.</p>

        <UButton
          size="md"
          color="primary"
          variant="solid"
          to="/my-account"
          label="Complete Profile"
        />
      </div>
    </UModal>
    <UModal
      prevent-close
      v-model="isOpenTransfer"
      :ui="{
        inner: 'fixed inset-0 overflow-y-auto flex item-center justify-center',
        container:
          'flex min-h-full items-end sm:items-center justify-center text-center max-w-sm w-full',
      }"
    >
      <div class="flex items-center justify-center" v-if="!showSuccess">
        <div class="w-full max-w-sm">
          <!-- Glass Card Effect -->
          <div
            class="backdrop-blur-lg rounded-xl bg-slate-100 p-2 shadow-lg border border-white/20"
          >
            <div class="border p-4 bg-slate-50 rounded-xl">
              <!-- Title -->
              <h2 class="text-lg font-semibold text-gray-800 mb-4">Confirm Transfer</h2>

              <!-- Transfer Details -->
              <div class="space-y-4 mb-6">
                <div class="flex justify-between items-center">
                  <p class="text-gray-500 text-xs">Transfer amount</p>
                  <p class="text-gray-900 text-lg font-semibold">
                    <UIcon name="i-mdi:currency-bdt" class="" />
                    {{ transfer?.payable_amount }}
                  </p>
                </div>

                <div class="space-y-3">
                  <!-- Recipient Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Recipient:</label>
                    <p class="text-sm text-gray-800 font-medium" v-if="transfer?.to_user">
                      {{ transfer?.to_user }}
                    </p>
                  </div>

                  <!-- Email Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Email:</label>
                    <p class="text-sm text-gray-800 font-medium">
                      {{ transfer?.contact }}
                    </p>
                  </div>

                  <!-- Name Field -->
                  <!-- <div class="space-y-1">
                  <label class="text-xs text-gray-500">Name:</label>
                  <p class="text-sm text-gray-800 font-medium">John Smith</p>
                </div> -->

                  <!-- Time Field -->
                  <div class="flex items-center gap-2">
                    <label class="text-xs text-gray-500">Time:</label>
                    <span
                      class="px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium"
                    >
                      Instant
                    </span>
                  </div>
                </div>
              </div>

              <!-- Final Amount -->
              <div class="flex justify-between items-center mb-6 pt-4 border-t border-gray-200">
                <p class="text-xs text-gray-500">Final amount</p>
                <p class="text-gray-900 font-semibold">
                  <UIcon name="i-mdi:currency-bdt" class="" />
                  {{ transfer?.payable_amount }}
                </p>
              </div>

              <!-- Confirm Button -->
              <UButton
                @click="handleTransfer"
                :class="[
                  'w-full py-2.5 rounded-lg text-sm font-medium transition-all duration-200',
                  'bg-black text-white hover:bg-gray-800 active:scale-98',
                  'focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2',
                  'disabled:opacity-50 disabled:cursor-not-allowed justify-center',
                ]"
                :loading="isLoading"
              >
                <div class="flex items-center justify-center gap-2">
                  {{ isLoading ? "Processing..." : "Confirm Transfer" }}
                </div>
              </UButton>
            </div>
          </div>

          <!-- Success Message -->
        </div>
      </div>

      <div class="flex items-center justify-center" v-else>
        <div class="w-full max-w-sm flex-1">
          <!-- Glass Card Effect -->
          <div
            class="backdrop-blur-lg bg-slate-100 rounded-xl p-2 shadow-lg border border-white/20 w-full"
          >
            <div class="border bg-slate-50 p-4 rounded-xl">
              <!-- Title and Success Icon -->
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-lg sm:text-2xl font-semibold text-green-700">
                  Transfer Successful
                </h2>
                <UIcon name="i-rivet-icons-check-circle-breakout" class="size-7 text-green-700" />
              </div>

              <!-- Transfer Details -->
              <div class="space-y-4 mb-6">
                <div class="flex justify-between items-center">
                  <p class="text-gray-500 text-xs">Transferred amount</p>
                  <p class="text-gray-900 text-lg font-semibold">
                    <UIcon name="i-mdi:currency-bdt" class="" />
                    {{ transfer?.payable_amount }}
                  </p>
                </div>

                <div class="space-y-3">
                  <!-- Recipient Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Recipient:</label>
                    <p class="text-sm sm:text-lg text-gray-800 font-medium">
                      {{ transfer?.to_user }}
                    </p>
                  </div>

                  <!-- Email Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Email:</label>
                    <p class="text-sm text-gray-800 font-medium">
                      {{ transfer?.contact }}
                    </p>
                  </div>

                  <div class="flex items-center gap-2">
                    <label class="text-xs text-gray-500">Time:</label>
                    <span
                      class="px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium"
                    >
                      Completed
                    </span>
                  </div>
                </div>
              </div>

              <!-- Final Amount -->
              <div class="flex justify-between items-center mb-6 pt-4 border-t border-gray-200">
                <p class="text-xs text-gray-500">Final amount</p>
                <p class="text-gray-900 font-semibold sm:text-lg">
                  <UIcon name="i-mdi:currency-bdt" class="" />
                  {{ transfer?.payable_amount }}
                </p>
              </div>

              <!-- Action Buttons -->
              <div class="flex gap-3">
                <button
                  @click="reset"
                  class="flex-1 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 bg-gray-100 text-gray-800 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-gray-300"
                >
                  View History
                </button>
                <button
                  @click="reset"
                  class="flex-1 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 bg-black text-white hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UModal>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const showSuccess = ref(false);
const isOpenTransfer = ref(false);
const isOpen = ref(false);
const toast = useToast();
const { post, get } = useApi();
const { user, jwtLogin } = useAuth();
const { formatDate } = useUtils();
const policy = ref(false);
const amount = ref(null);
const withdrawAmount = ref(null);
const currentTab = ref(1);
const selected = ref("nagad");
const payment_number = ref(null);
const bkash_number = ref(null);
const rocket = ref(null);
const errors = ref({});
const options = [
  { value: "bkash", label: "BKash", icon: "bkash.png" },
  { value: "nagad", label: "Nagad", icon: "nagad.png" },
  // { value: "rocket", label: "Rocket", icon: "i-heroicons-bell" },
];
const columns = [
  {
    key: "created_at",
    label: "Time",
  },
  {
    key: "payment_method",
    label: "Deposit/Withdraw",
  },
  {
    key: "payable_amount",
    label: "Amount",
  },
  {
    key: "bank_status",
    label: "Status",
  },
];

const statements = ref([
  // {
  //   id: 1,
  //   time: "2:35",
  //   deposit_withdraw: "Deposit",
  //   amount: "300",
  //   status: "Pending",
  //   class: "text-yellow-400",
  // },
  // {
  //   id: 2,
  //   time: "2:35",
  //   deposit_withdraw: "Withdraw",
  //   amount: "300",
  //   status: "Completed",
  // },
  // function getStatusClass(status) {
  //   if (status === 'Pending') {
  //     return 'text-yellow-400'; // Yellow for Pending
  //   } else if (status === 'Completed') {
  //     return 'text-green-500'; // Green for Completed
  //   }
  //   return ''; // Default class
  // },
]);
const depositErrors = ref({});
const isLoading = ref(false);
const deposit = async () => {
  isLoading.value = true;
  if (!amount.value) {
    depositErrors.value = { ...depositErrors.value, amount: true };
  }

  if (!policy.value) {
    depositErrors.value = { ...depositErrors.value, policy: true };
  }
  if (!amount.value || !policy.value) {
    toast.add({ title: "Please fill in all required fields." });
    isLoading.value = false;
    return;
  }

  const payment = await get(
    `/pay/?amount=${amount.value}&order_id=123&currency=BDT&customer_name=${user.value.user.first_name}+${user.value.user.last_name}&customer_address=${user.value.user.address}&customer_phone=${user.value.user.phone}&customer_city=${user.value.user.city}&customer_post_code=${user.value.user.zip}`
  );

  console.log(payment.data);
  if (payment.data.checkout_url) {
    isLoading.value = false;
    window.open(payment.data.checkout_url, "_blank");
  }

  getTransactionHistory();
  amount.value = "";
  policy.value = false;
};

const withdraw = async () => {
  if (!withdrawAmount.value) {
    errors.value = { ...errors.value, withdrawAmount: true };
  }

  if (!selected.value) {
    errors.value = { ...errors.value, selected: true };
  }
  if (withdrawAmount.value > user.value.user.balance) {
    errors.value = { ...errors.value, insufficient: true };
  }

  if (!payment_number.value) {
    errors.value = { ...errors.value, payment_number: true };
  }

  if (!policy.value) {
    errors.value = { ...errors.value, policy: true };
  }

  if (Object.keys(errors.value).length > 0) {
    console.log("Errors:", errors.value);
    return;
  }
  errors.value = {};
  console.log(withdrawAmount.value * 1 + (withdrawAmount.value * 2.95) / 100);

  const res = await post(`/add-user-balance/`, {
    payment_method: selected.value,
    card_number: payment_number.value,
    payable_amount: withdrawAmount.value * 1 + (withdrawAmount.value * 2.95) / 100,
    transaction_type: "Withdraw",
  });
  console.log(res);
  getTransactionHistory();
  jwtLogin();
  withdrawAmount.value = "";
  policy.value = false;
};

const transfer = ref({
  contact: "",
  payable_amount: "",
  transaction_type: "Transfer",
  payment_method: "p2p",
  bank_status: "completed",
});

const transferErrors = ref({});

async function sendToUser() {
  isLoading.value = true;
  transferErrors.value = {};

  if (!transfer.value.contact) {
    transferErrors.value.contact = "Contact is required.";
  }

  if (!transfer.value.payable_amount) {
    transferErrors.value.payable_amount = "Payable amount is required.";
  }

  if (Object.keys(transferErrors.value).length > 0) {
    isLoading.value = false;
    return;
  }
  const { data, error } = await get(`/user/${transfer.value.contact}/`);
  console.log(data, error);
  if (data) {
    isOpenTransfer.value = true;
  } else {
    transferErrors.value.user = "User not found";
  }
  transfer.value.to_user = data.name;
  isLoading.value = false;
}

async function handleTransfer() {
  isLoading.value = true;
  const { to_user, ...rest } = transfer.value;
  if (to_user) {
    const { data, error } = await post(`/add-user-balance/`, rest);
    console.log(data, error);
    if (data) {
      showSuccess.value = true;
    }
    jwtLogin();
    getTransactionHistory();
  }
  isLoading.value = false;
}

function reset() {
  isOpenTransfer.value = false;
  showSuccess.value = false;
  transfer.value = {
    contact: "",
    payable_amount: "",
    transaction_type: "p2p",
    bank_status: "completed",
    to_user: null,
  };
}

const getTransactionHistory = async () => {
  const res = await get(`/user-balance/${user.value.user.email}/`);
  console.log(res.data);
  statements.value = res.data;
};
getTransactionHistory();
</script>

<style>
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fade-in 0.2s ease-out;
}

.active\:scale-98:active {
  transform: scale(0.98);
}

/* Glass morphism effect */
.backdrop-blur-lg {
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}
</style>
