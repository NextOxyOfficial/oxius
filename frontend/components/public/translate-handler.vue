<template>
  <div>
    <USelectMenu
      color="white"
      size="md"
      v-model="currentLanguage"
      :options="languageOption"
      option-attribute="label"
    >
      <template #leading> <UIcon :name="currentLanguage.icon" /> </template>
      <template #option="{ option: language }">
        <UIcon :name="language.icon" />
        <span>{{ language.label }}</span>
      </template>
    </USelectMenu>
  </div>
</template>

<script setup>
const { setLocale } = useI18n();
const language = useCookie("language");
const languageOption = [
  {
    value: "en",
    label: "English",
    icon: "i-flagpack:us",
  },
  {
    value: "bn",
    label: "বাংলা",
    icon: "i-flagpack:bd",
  },
];
const currentLanguage = ref(languageOption[1]);

watch(currentLanguage, () => {
  setLocale(currentLanguage.value.value);
  language.value = currentLanguage.value;
  // window.location.reload();
});
onMounted(() => {
  console.log(language.value);
  currentLanguage.value = language.value;

  if (language.value) {
    setLocale(language.value.value);
  } else {
    setLocale("bn");
  }
});
</script>

<style scoped></style>
