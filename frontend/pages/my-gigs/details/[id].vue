<template>
  <PublicSection>
    <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
    <h1 class="text-center text-4xl my-8">
      {{ submittedTasks[0]?.gig.title }}
    </h1>
    <UContainer>
      <UTable :rows="submittedTasks" :columns="columns" class="my-8">
        <template #index-data="{ row }">
          <p>
            {{ row.id }}
          </p>
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

        <template #approve-data="{ row }">
          <UButton
            size="xs"
            class="w-[67px] justify-center"
            color="primary"
            @click="handleOperation(row.id, 'approve')"
            variant="outline"
            :label="row.approved ? 'Approved' : 'Approve'"
            :disabled="row.rejected || row.approved"
          />
        </template>
        <template #reject-data="{ row }">
          <UButton
            size="xs"
            class="w-[67px] justify-center"
            color="red"
            @click="handleOperation(row.id, 'reject')"
            variant="outline"
            :label="row.rejected ? 'Rejected' : 'Reject'"
            :disabled="row.rejected || row.approved"
          />
        </template>
      </UTable>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get, staticURL, del, put } = useApi();
const { user } = useAuth();
const submittedTasks = ref([]);
const route = useRoute();
async function getUserGigs() {
  try {
    const res = await get(`/task-by-micro-gig-post/${route.params.id}/tasks/`);
    console.log(res);
    submittedTasks.value = res.data;
  } catch (error) {
    console.log(error);
  }
}
getUserGigs();

async function handleOperation(taskId, operation) {
  const res = await put(
    `/update-task-by-micro-gig-post/${route.params.id}/tasks/`,
    {
      tasks: [
        {
          id: taskId,
          approved: operation === "approve" ? true : false,
          rejected: operation === "reject" ? true : false,
        },
      ],
    }
  );
  console.log(res);
  if (res.error) {
  } else {
    getUserGigs();
  }
}

const columns = [
  {
    key: "index",
    label: "ID",
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
    key: "approve",
    label: "",
  },
  {
    key: "reject",
    label: "",
  },
];
</script>

<style scoped></style>
