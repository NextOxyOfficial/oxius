<template>
  <div>
    <USelectMenu
      color="white"
      size="md"
      v-model="currentLanguage"
      :options="languageOption"
      value-attribute="value"
      option-attribute="label"
    >
      <!-- <template #leading>
        <UIcon
          v-if="currentLanguage.icon"
          :name="currentLanguage.icon"
          class="w-5 h-5"
        />
      </template> -->
      <template #option="{ option: language }">
        <UIcon :name="language.icon" />
        <span>{{ language.label }}</span>
      </template>
    </USelectMenu>
  </div>
</template>

<script setup>
const { setLocale } = useI18n();
const languageOption = [
  {
    value: "en",
    label: "English",
    icon: "i-flagpack:us",
  },
  {
    value: "bn",
    label: "Bangla",
    icon: "i-flagpack:bd",
  },
];
const currentLanguage = ref(languageOption[1]);

watch(currentLanguage, () => {
  setLocale(currentLanguage.value);
});
</script>

<style scoped></style>
