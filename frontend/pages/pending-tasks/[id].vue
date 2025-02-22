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
        <template #auto_approve-data="{ row }">
          <p
            class="text-sm"
            :class="{
              'text-red-500':
                getRemainingTime(row.created_at) === 'Auto Approved',
              'text-orange-500': getRemainingTime(row.created_at),
            }"
          >
            {{ getRemainingTime(row.created_at) }}
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
        <template #action-data="{ row }">
          <UButton
            size="md"
            color="primary"
            variant="solid"
            label="View Details"
            @click="showDetails(row.id)"
          />
        </template>
      </UTable>
    </UContainer>
    <UModal v-model="isOpen">
      <div class="p-6 bg-slate-100 border rounded-xl space-y-4">
        <p>
          {{ currentTaskDetails.approved ? "Approved" : "Pending" }} ||
          {{ formatDate(currentTaskDetails.created_at) }}
        </p>
        <div class="bg-slate-50 p-4 rounded-xl space-y-3">
          <div v-html="currentTaskDetails.submit_details"></div>
          <p>{{ currentTaskDetails.media }}</p>
        </div>

        <div v-if="currentTaskDetails.medias">
          <NuxtImg
            v-for="media in currentTaskDetails.medias"
            :key="media.id"
            :src="media.image"
            :alt="media.image"
          />
        </div>
        <UButton
          size="md"
          color="gray"
          variant="outline"
          label="Close"
          class="max-w-fit"
          @click="isOpen = false"
        />
      </div>
    </UModal>
  </PublicSection>
</template>
<script setup>
const { user } = useAuth();
const { get } = useApi();
const { formatDate } = useUtils();
const isOpen = ref(false);
const currentTaskDetails = ref({});

const pendingGigs = ref([]);

async function getPendingTasks() {
  const { data, error } = await get(`/user-pending-tasks/`);
  console.log(data);
  pendingGigs.value = data;
}
getPendingTasks();

async function showDetails(id) {
  isOpen.value = true;
  currentTaskDetails.value = pendingGigs.value.find((task) => task.id === id);
}

function getRemainingTime(createdAt) {
  const created = new Date(createdAt);
  const deadline = new Date(created.getTime() + 48 * 60 * 60 * 1000); // 48 hours in milliseconds
  const now = new Date();
  const remaining = deadline - now;

  if (remaining <= 0) {
    return "Time expired";
  }

  const hours = Math.floor(remaining / (60 * 60 * 1000));
  const minutes = Math.floor((remaining % (60 * 60 * 1000)) / (60 * 1000));

  return `${hours}h ${minutes}m`;
}

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
    key: "auto_approve",
    label: "Auto Approval",
  },
  {
    key: "completed",
    label: "Status",
  },
  {
    key: "action",
    label: "",
  },
];
</script>
