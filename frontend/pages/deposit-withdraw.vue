<template>
  <UContainer>
    <h1 class="text-center text-4xl my-8">Deposit/Withdraw</h1>

    <UDivider label="" class="mb-8" />
    <div class="flex items-center justify-between">
      <p
        class="text-lg bg-green-100 border-green-500 border py-2 max-w-72 w-full px-3 rounded-md mb-3 text-green-800 font-bold"
      >
        <span class="inline-flex items-center"
          >Available Balance:&nbsp;
          <UIcon name="i-mdi:currency-bdt" class="" />
          {{ user.user.balance }}
        </span>
      </p>
      <div class="text-lg">
        <p
          class="text-lg bg-green-100 border-green-500 border py-2 max-w-72 w-full px-3 rounded-md mb-3 text-green-800 font-bold"
        >
          <span class="inline-flex items-center"
            >Total Earnings:&nbsp;
            <UIcon name="i-mdi:currency-bdt" class="" />500</span
          >
        </p>
      </div>
    </div>
    <div class="flex items-center">
      <div>
        <div class="space-y-2">
          <UInput
            placeholder="Enter amount"
            size="md"
            :ui="{
              padding: { md: 'px-3 py-2' },
            }"
            v-model="amount"
            amount
          />
          <UInputMenu
            placeholder="Select payment method"
            :options="methods"
            v-model="method"
            size="md"
            :ui="{
              padding: { md: 'px-3 py-2' },
            }"
          />
        </div>
        <div class="mt-3">
          <UCheckbox name="notifications" label="I accept terms & policy." />
        </div>
        <div class="my-2 space-x-3">
          <UButton size="sm" @click="deposit">Deposit</UButton>
          <UButton color="gray" @click="withdraw" variant="solid"
            >Withdraw</UButton
          >
        </div>
      </div>
    </div>

    <UTable :rows="statements" :columns="columns" class="my-8">
      <template #caption>
        <caption class="text-center text-3xl font-semibold mb-4">
          Deposit/Withdraw Statements
        </caption>
      </template>
      <!-- <template v-slot:body="{ row }">
        <tr v-for="(row, index) in statements" :key="row.id">
          <td>{{ row.id }}</td>
          <td>{{ row.time }}</td>
          <td>{{ row.deposit_withdraw }}</td>
          <td>{{ row.amount }}</td>
          <td :class="getStatusClass(row.status)">
            {{ row.status }}
          </td>
        </tr>
      </template> -->
      <template #status-data="{ row }">
        <p
          :class="
            row.status.toLowerCase() === 'pending'
              ? 'text-yellow-500'
              : 'text-green-500'
          "
        >
          {{ row.status }}
        </p>
      </template>
    </UTable>
  </UContainer>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const toast = useToast();
const { put } = useApi();
const { user } = useAuth();
const methods = ["bkash", "nagad", "rocket", "upay"];
const method = ref([]);
const amount = ref(null);
const columns = [
  {
    key: "id",
    label: "#ID",
  },
  {
    key: "time",
    label: "Time",
  },
  {
    key: "deposit_withdraw",
    label: "Deposit/Withdraw",
  },
  {
    key: "amount",
    label: "Amount",
  },
  {
    key: "status",
    label: "Status",
  },
];

const statements = [
  {
    id: 1,
    time: "2:35",
    deposit_withdraw: "Deposit",
    amount: "300",
    status: "Pending",
    class: "text-yellow-400",
  },
  {
    id: 2,
    time: "2:35",
    deposit_withdraw: "Withdraw",
    amount: "300",
    status: "Completed",
  },

  // function getStatusClass(status) {
  //   if (status === 'Pending') {
  //     return 'text-yellow-400'; // Yellow for Pending
  //   } else if (status === 'Completed') {
  //     return 'text-green-500'; // Green for Completed
  //   }
  //   return ''; // Default class
  // },
];

const deposit = async () => {
  // Add deposit logic here
  toast.add({ title: "Deposit clicked" });
  console.log(user.value);

  const res = await put(`/persons/update/${user.value.user.email}/`, {
    deposit: amount.value,
    method: method.value,
  });
  console.log(res);
};

const withdraw = async () => {
  // Add withdraw logic here
  toast.add({ title: "Withdraw clicked" });
  const res = await put(`/persons/update/${user.value.user.email}/`, {
    withdraw: amount.value,
    method: method.value,
  });
  console.log(res);
};
</script>
