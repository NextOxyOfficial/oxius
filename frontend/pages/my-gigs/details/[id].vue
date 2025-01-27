<template>
  <PublicSection>
    <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
    <h1 class="text-center text-4xl my-8">
      {{ submittedTasks[0]?.gig.title }}
    </h1>
    <UContainer>
      <USelect
        color="white"
        size="md"
        :options="filterOptions"
        v-model="selectedFilter"
        placeholder="Search"
        class="w-40 capitalize ml-auto"
      />
      <UTable :rows="submittedTasks" :columns="columns" class="mb-8 mt-3">
        <template #index-data="{ row }">
          <p>
            {{ row.id }}
          </p>
        </template>
        <template #created_at-data="{ row }">
          <p>
            {{ formatDate(row.created_at) }}
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
          <div class="flex gap-1.5">
            <UButton
              size="xs"
              class="w-[67px] justify-center"
              color="primary"
              @click="handleOperation(row.id, 'approve')"
              variant="outline"
              :label="row.approved ? 'Approved' : 'Approve'"
              :disabled="row.rejected || row.approved"
            />
            <UButton
              size="xs"
              class="w-[67px] justify-center"
              color="red"
              @click="openModal(row.id, 'reject')"
              variant="outline"
              :label="row.rejected ? 'Rejected' : 'Reject'"
              :disabled="row.rejected || row.approved"
            />
          </div>
        </template>
      </UTable>
    </UContainer>
    <UModal v-model="isOpen" prevent-close>
      <UCard
        :ui="{
          ring: '',
          divide: 'divide-y divide-gray-100 dark:divide-gray-800',
        }"
      >
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold leading-6 text-gray-900 dark:text-white">Modal</h3>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark-20-solid"
              class="-my-1"
              @click="isOpen = false"
            />
          </div>
        </template>

        <UTextarea
          color="white"
          variant="outline"
          class="w-full"
          resize
          placeholder="Rejection Reason"
          v-model="rejectionReason"
        />
        <UButton
          size="md"
          color="primary"
          variant="solid"
          label="Submit Rejection"
          class="mt-4"
          @click="submitRejection"
        />
      </UCard>
    </UModal>
  </PublicSection>
</template>

<script setup>
const isOpen = ref(false);
const rejectionReason = ref("");
const selectedTaskId = ref(null);
const filterOptions = ["All", "Approved", "Rejected"];

const selectedFilter = ref("");
const { get, del, put } = useApi();
const { formatDate } = useUtils();
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
  const res = await put(`/update-task-by-micro-gig-post/${route.params.id}/tasks/`, {
    tasks: [
      {
        id: taskId,
        approved: operation === "approve" ? true : false,
        rejected: operation === "reject" ? true : false,
      },
    ],
  });
  console.log(res);
  if (res.error) {
  } else {
    getUserGigs();
  }
}

function openModal(taskId, operation) {
  isOpen.value = true;
  console.log(taskId, operation);
  selectedTaskId.value = taskId;
  rejectionReason.value = "";
}

async function submitRejection() {
  if (!selectedTaskId.value || !rejectionReason.value) {
    console.log("Task ID or rejection reason is missing");
    return;
  }

  try {
    const res = await put(`/update-task-by-micro-gig-post/${route.params.id}/tasks/`, {
      tasks: [
        {
          id: selectedTaskId.value,
          approved: false,
          rejected: true,
          reason: rejectionReason.value,
        },
      ],
    });
    console.log(res);
    if (res.error) {
      console.log("Error:", res.error);
    } else {
      getUserGigs(); // Refresh the data
      isOpen.value = false; // Close the modal
    }
  } catch (error) {
    console.log("Error submitting rejection:", error);
  }
}

watch(selectedFilter, () => {
  if (selectedFilter.value === "Approved") {
    submittedTasks.value = submittedTasks.value.filter(task => task.approved);
    console.log("approved");
  } else if (selectedFilter.value === "Rejected") {
    submittedTasks.value = submittedTasks.value.filter(task => task.rejected);
    console.log("rejected");
  }
});

const columns = [
  {
    key: "index",
    label: "ID",
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
    label: "Time",
  },
  {
    key: "approve",
    label: "Action",
  },
  {
    key: "reject",
    label: "",
  },
];
</script>

<style scoped></style>
