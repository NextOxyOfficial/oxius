<template>
  <PublicSection>
    <UContainer>
      <AccountBalance v-if="user" :user="user" :isUser="true" />
      <p class="text-center text-2xl md:text-3xl font-semibold">
        Pending Tasks List
      </p>
      <UTable
        :rows="pendingGigs"
        :columns="columns"
        class="mb-8"
        :ui="{
          th: { base: 'truncate' },
        }"
      >
        <template #amount-data="{ row }">
          <p>
            {{ row.gig.price }}
          </p>
        </template>
        <template #created_at-data="{ row }">
          <p>
            {{ formatDate(row.created_at) }}
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
const { formatDate } = useUtils();

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
    label: "Title",
  },
  {
    key: "amount",
    label: "Price",
  },
  {
    key: "created_at",
    label: "Created",
  },
  {
    key: "completed",
    label: "Status",
  },
];
</script>
