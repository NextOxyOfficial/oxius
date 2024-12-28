<template>
  <UFormGroup>
    <USelectMenu
      v-model="state"
      :options="regions"
      placeholder="State"
      :ui="{
        size: {
          md: 'text-base',
        },
      }"
      option-attribute="name"
      value-attribute="name"
    />
  </UFormGroup>
</template>

<script setup>
const { get } = useApi();

const state = ref("");
const regions = ref([]);

const country = ref("Bangladesh"); // Default country or pass it as a prop
onMounted(async () => {
  const regions_response = await get(
    `/cities-light/regions/?country=${country.value}`
  );
  regions.value = regions_response.data;
});

defineProps({
  modelValue: String,
});
defineEmits(["update:modelValue"]);

watch(
  () => state.value,
  (newState) => {
    emit("update:modelValue", newState);
  }
);
</script>
