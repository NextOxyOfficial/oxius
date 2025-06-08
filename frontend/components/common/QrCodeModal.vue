<template>
  <UModal
    v-model="isOpen"
    :ui="{ width: 'w-full sm:max-w-md', background: 'bg-slate-100' }"
  >
    <div
      class="px-4 py-12 flex flex-col gap-4 items-center justify-center relative rounded-3xl overflow-hidden"
    >
      <UButton
        icon="i-heroicons-x-mark"
        size="sm"
        color="primary"
        variant="solid"
        @click="closeModal"
        class="absolute top-2 right-2 rounded-full"
      />
      <h3 class="text-xl font-semibold text-green-700">AdsyPay</h3>
      <h3 class="text-xl font-semibold">{{ title }}</h3>
      <div class="border p-4 rounded-lg shadow-sm bg-white">
        <NuxtImg
          class="w-[250px]"
          :src="qrCodeUrl"
          :alt="title"
        />
      </div>
    </div>
  </UModal>
</template>

<script setup>
const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: 'Scan My QR Code'
  },
  qrData: {
    type: String,
    required: true
  },
  size: {
    type: String,
    default: '250x250'
  }
});

const emit = defineEmits(['update:modelValue']);

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
});

const qrCodeUrl = computed(() => {
  return `https://api.qrserver.com/v1/create-qr-code/?size=${props.size}&data=${encodeURIComponent(props.qrData)}`;
});

const closeModal = () => {
  isOpen.value = false;
};
</script>
