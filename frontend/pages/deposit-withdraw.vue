<template>
  <PublicSection>
    <h1 class="text-center text-2xl md:text-4xl my-8">Deposit/Withdraw</h1>
    <UContainer>
      <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
      <UDivider label="" class="mb-8" />
      <div class="flex flex-col md:flex-row justify-between">
        <p
          class="text-lg py-2 max-w-72 w-full mb-3 text-green-800 dark:text-green-600 font-bold"
        >
          <span class="inline-flex items-center"
            >Available Balance:&nbsp;
            <UIcon name="i-mdi:currency-bdt" class="" />
            {{ user.user.balance }}
          </span>
        </p>
        <!-- <div class="text-lg">
          <p
            class="text-lg bg-green-100 border-green-500 border py-2 max-w-72 w-full px-3 rounded-md mb-3 text-green-800 font-bold"
          >
            <span class="inline-flex items-center"
              >Total Earnings:&nbsp;
              <UIcon name="i-mdi:currency-bdt" class="" />500</span
            >
          </p>
        </div> -->
      </div>
      <div class="my-5 flex justify-center">
        <UButton
          :color="`${currentTab == 1 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-e-none',
          }"
          @click="currentTab = 1"
          >Deposit</UButton
        >
        <UButton
          :color="`${currentTab == 2 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-s-none',
          }"
          @click="currentTab = 2"
          >Withdraw</UButton
        >
      </div>
      <div class="flex items-center">
        <div v-if="currentTab === 1">
          <div class="space-y-2">
            <UInput
              placeholder="Enter amount"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="amount"
              amount
            />
          </div>
          <div class="mt-4">
            <img
              src="/static/frontend/images/payment.png"
              class="w-60"
              alt="Payment Method"
            />
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
              >Deposit</UButton
            >
            <UButton v-else size="sm" @click="isOpen = true">Deposit</UButton>

            <!-- <UButton color="gray" @click="withdraw" variant="solid"
              >Withdraw</UButton
            > -->
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
          <p v-if="errors?.selected" class="text-sm text-red-500">
            Please enter a payment method
          </p>
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
              placeholder="Enter amount"
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
            <p v-if="errors?.policy" class="text-sm text-red-500">
              Check this field
            </p>
          </div>
          <div class="my-2 space-x-3">
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
              >Withdraw</UButton
            >
            <UButton v-else size="sm" @click="isOpen = true">Withdraw</UButton>
          </div>
        </div>
      </div>
      <h3
        class="text-center text-lg md:text-3xl font-semibold mt-8"
        v-if="statements?.length"
      >
        Transaction History
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
          <p class="capitalize">
            {{ row.transaction_type }} -
            {{ row.payment_method }}
          </p>
        </template>
        <template #bank_status-data="{ row }">
          <p
            class="capitalize font-semibold"
            :class="
              row.bank_status.toLowerCase() === 'pending'
                ? 'text-yellow-500'
                : 'text-green-500'
            "
          >
            {{ row.bank_status }}
          </p>
        </template>
      </UTable>
      <UCard v-else class="py-16 text-center">
        <p>No transactions have been found!</p>
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
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
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

const deposit = async () => {
  if (!amount.value || !policy.value) {
    toast.add({ title: "Please fill in all required fields." });
    return;
  }
  // Add deposit logic here
  // toast.add({ title: "Deposit clicked" });
  // console.log(user.value);

  const payment = await get(
    `/pay/?amount=${amount.value}&order_id=123&currency=BDT&customer_name=${user.value.user.first_name}+${user.value.user.last_name}&customer_address=${user.value.user.address}&customer_phone=${user.value.user.phone}&customer_city=${user.value.user.city}&customer_post_code=${user.value.user.zip}`
  );
  console.log(payment.data);
  if (payment.data.checkout_url)
    window.open(payment.data.checkout_url, "_blank");

  // const res = await put(`/persons/update/${user.value.user.email}/`, {
  //   deposit: amount.value,
  //   transaction_type: "Deposit",
  // });
  // console.log(res);
  userBalance();
  amount.value = "";
  policy.value = false;
};

const withdraw = async () => {
  errors.value = {};

  // Check each field and add an error if invalid
  if (!withdrawAmount.value) {
    errors.value.withdrawAmount = true;
  }
  if (!selected.value) {
    errors.value.selected = true;
  }
  if (!payment_number.value) {
    errors.value.payment_number = true;
  }
  if (!policy.value) {
    errors.value.policy = true;
  }

  // If there are any errors, stop execution
  if (Object.keys(errors.value).length > 0) {
    return;
  }
  errors.value = {};
  // Add withdraw logic here

  // toast.add({ title: "Withdraw clicked" });
  const res = await post(`/add-user-balance/`, {
    payment_method: selected.value,
    card_number: payment_number.value,
    payable_amount: withdrawAmount.value,
    transaction_type: "Withdraw",
  });
  console.log(res);
  userBalance();
  jwtLogin();
  withdrawAmount.value = "";
  policy.value = false;
};

const userBalance = async () => {
  const res = await get(`/user-balance/${user.value.user.email}/`);
  console.log(res.data);
  statements.value = res.data;
};
userBalance();
</script>
