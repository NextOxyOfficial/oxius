<template>
  <UCard
    v-if="user?.user"
    class="md:w-[700px] mx-auto mb-8 bg-green-100 border-dashed border border-green-500"
    :ui="{
      rounded: 'rounded-2xl',
      ring: '',
    }"
  >
    <div class="flex flex-col md:flex-row justify-between gap-6">
      <div>
        <h3 class="text-2xl font-bold max-sm:text-center">
          <span class="text-green-900 inline-flex items-center gap-1">
            <UIcon
              name="i-material-symbols:account-balance-wallet-outline"
              class="mt-1"
            />
            {{ $t("balance") }}:
            <UIcon name="i-mdi:currency-bdt" class="text-2xl" />{{
              user?.user.balance
            }}</span
          >
        </h3>
      </div>

      <div class="flex items-center justify-between">
        <h3 class="text-xl font-bold inline-flex items-center">
          {{ $t("pending_task") }}:
          <UIcon name="i-mdi:currency-bdt" class="text-2xl" />{{
            user?.user.pending_balance
          }}
        </h3>

        <UButton
          size="xs"
          color="primary"
          variant="outline"
          :label="t('view')"
          class="ml-2"
          :to="`/pending-tasks/${user?.user.id}`"
        />
      </div>
    </div>
    <div
      class="grid grid-cols-2 md:grid-cols-[auto_auto_auto_auto] justify-center gap-2 md:gap-4 mt-8 w-full"
    >
      <UButton
        icon="i-token:cusd"
        size="md"
        color="primary"
        variant="solid"
        :label="t('deposit_withdraw')"
        to="/deposit-withdraw/"
        :ui="{
          size: { md: 'text-xs md:text-sm' },
          gap: { md: 'gap-x-1 md:gap-x-2' },
          padding: { md: 'px-1.5 py-0.5 md:px-3 md:py-2' },
        }"
        class="justify-center"
      />
      <UButton
        icon="i-material-symbols:mark-email-unread-outline"
        size="md"
        color="primary"
        variant="solid"
        :label="t('inbox')"
        to="/inbox/"
        :ui="{
          size: { md: 'text-xs md:text-sm' },
        }"
        class="justify-center"
      />
      <UButton
        icon="i-material-symbols:list-rounded"
        size="md"
        color="primary"
        variant="solid"
        :label="t('my_gigs')"
        :to="isUser ? '/my-gigs/' + user?.user.id : '/my-gigs/'"
        :ui="{
          size: { md: 'text-xs md:text-sm' },
        }"
        class="justify-center"
      />
      <UButton
        icon="i-heroicons-plus-circle"
        size="md"
        color="black"
        variant="solid"
        :label="t('post_gigs')"
        to="/post-a-gig"
        :ui="{
          size: { md: 'text-xs md:text-sm' },
        }"
        class="justify-center"
      />
    </div>
    <UDivider label="" class="my-5" />
    <div class="flex flex-col gap-4">
      <div class="text-center text-xl font-bold">
        {{ $t("refer") }}
        <ULink
          class="cursor-pointer text-blue-500 block"
          @click="CopyToClip('/coming-soon/')"
          to="/coming-soon/"
        >
          {{ $t("coming_soon") }}
        </ULink>
      </div>
      <div class="flex gap-4 justify-center">
        <p class="text-sm md:text-base">{{ $t("refer_user") }}: 0</p>
        <div>|</div>
        <p class="text-sm md:text-base">{{ $t("earnings") }}: 0</p>
      </div>
    </div>
  </UCard>
</template>

<script setup>
const { t } = useI18n();
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
