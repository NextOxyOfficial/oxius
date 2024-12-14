<template>
  <UCard
    v-if="user?.user"
    class="w-[700px] mx-auto mb-8 bg-primary/10"
    :ui="{
      rounded: 'rounded-2xl',
    }"
  >
    <div class="flex justify-between gap-6">
      <div>
        <h3 class="text-2xl font-bold">
          <span class="text-green-900 inline-flex items-center gap-1">
            <UIcon
              name="i-material-symbols:account-balance-wallet-outline"
              class="mt-1"
            />
            Balance :
            <UIcon name="i-mdi:currency-bdt" class="text-2xl" />{{
              user?.user.balance
            }}</span
          >
        </h3>
      </div>

      <div class="flex items-center">
        <h3 class="text-xl font-bold inline-flex items-center">
          Pending Task:
          <UIcon name="i-mdi:currency-bdt" class="text-2xl" />{{
            user?.user.pending_balance
          }}
        </h3>

        <UButton
          size="xs"
          color="primary"
          variant="solid"
          label="View"
          class="ml-2"
          :to="`/pending-tasks/${user?.user.id}`"
        />
      </div>
    </div>
    <div class="flex justify-center gap-4 mt-8">
      <UButton
        icon="i-token:cusd"
        size="md"
        color="primary"
        variant="solid"
        label="Deposit / Withdraw"
        to="/deposit-withdraw/"
      />
      <UButton
        icon="i-material-symbols:mark-email-unread-outline"
        size="md"
        color="primary"
        variant="solid"
        label="Inbox"
        to="/inbox/"
      />
      <UButton
        icon="i-material-symbols:list-rounded"
        size="md"
        color="primary"
        variant="solid"
        label="My Gigs"
        :to="isUser ? '/my-gigs/' + user?.user.id : '/my-gigs/'"
      />
      <UButton
        icon="i-heroicons-plus-circle"
        size="md"
        color="black"
        variant="solid"
        label="Post A Gig"
        to="/post-a-gig"
      />
    </div>
    <UDivider label="" class="my-5" />
    <div class="flex flex-col gap-4">
      <div class="text-center text-xl font-bold">
        Referral Link:
        <p
          class="cursor-pointer"
          @click="CopyToClip('https://localhost:3000/')"
        >
          https://localhost:3000/
        </p>
      </div>
      <div class="flex gap-4 justify-center">
        <UButton size="md" color="primary" variant="solid" label="Referred" />
        <div>|</div>
        <UButton size="md" color="primary" variant="solid" label="50" />
      </div>
    </div>
  </UCard>
</template>

<script setup>
defineProps({
  user: {
    type: Object,
    required: true,
  },
  isUser: {
    type: Boolean,
    required: true,
  },
});
function CopyToClip(text) {
  //Copy text to clipboard
  navigator.clipboard.writeText(text);
}
</script>
