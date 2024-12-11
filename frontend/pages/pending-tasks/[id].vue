<template>
  <PublicSection>
    <AccountBalance v-if="user" :user="user" :isUser="true" />

    <UContainer>
      <UTable :rows="pendingGigs" :columns="columns" class="my-8">
        <template #caption>
          <caption class="text-center text-3xl font-semibold mb-4">
            Task Details
          </caption>
        </template>

        <template #amount-data="{ row }">
          <p>
            {{ row.gig.price }}
          </p>
        </template>
        <template #title-data="{ row }">
          <p>
            {{ row.gig.title }}
          </p>
        </template>
        <template #completed-data="{ row }">
          <p v-if="row.approved">Approved</p>
          <p v-else-if="row.rejected">Rejected</p>
          <p v-else>Under Review</p>
        </template>
      </UTable>
    </UContainer>
  </PublicSection>
</template>
<script setup>
const { user } = useAuth();
const { get } = useApi();

const route = useRoute();

const pendingGigs = ref([]);

async function getPendingTasks() {
  const { data, error } = await get(`/user-pending-tasks/`);
  console.log(data);
  pendingGigs.value = data;
}
getPendingTasks();

const columns = [
  {
    key: "id",
    label: "#ID",
  },

  {
    key: "title",
    label: "Gig Title",
  },
  {
    key: "amount",
    label: "Gig Price",
  },
  {
    key: "created_at",
    label: "Created At",
  },
  {
    key: "completed",
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
];
</script>
