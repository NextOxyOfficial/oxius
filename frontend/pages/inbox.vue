<template>
  <PublicSection class="min-h-[50vh]">
    <h1 class="text-center text-4xl mt-4 mb-8">Message Center</h1>
    <UContainer>
      <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
      <div v-if="messages && messages.length">
        <!-- showing message -->
        <div v-for="message in messages" :key="message.id">
          <div
            class="flex max-sm:flex-wrap items-center justify-between gap-2 sm:gap-3 py-2"
          >
            <p class="font-medium max-sm:w-full text-sm sm:text-base">
              <span>#50{{ message.id }}</span> {{ message.title }}
            </p>

            <UButton
              color="white"
              label="Show Message"
              trailing-icon="i-heroicons-chevron-down-20-solid"
              class="button !font-normal"
              @click="toggleMsg = !toggleMsg"
            />
            <p class="max-sm:w-1/2 text-sm sm:text-base">
              {{ formatDate(message.created_at) }}
            </p>
          </div>
          <div class="message" v-if="toggleMsg">
            <UCard>
              <p>
                {{ message.message }}
              </p>
            </UCard>
          </div>
        </div>
      </div>
      <UCard v-else class="py-16 text-center">
        <p>Inbox is empty!</p>
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { user } = useAuth();
const toggleMsg = ref(false);
const messages = ref([]);
const { get } = useApi();
const { formatDate } = useUtils();

async function getAdminMessages() {
  const res = await get("/admin-notice/");
  console.log(res);
  messages.value = res.data;
}
getAdminMessages();
</script>

<style lang="scss" scoped></style>
