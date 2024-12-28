<template>
  <div>
    <USelectMenu
      color="white"
      size="md"
      v-model="currentLanguage"
      :options="languageOption"
      option-attribute="label"
      class="w-32"
    >
      <template #leading>
        <UIcon
          v-if="currentLanguage.icon === 'i-flag:us-4x3'"
          name="i-flag:us-4x3"
        />
        <UIcon v-else name="i-flag:bd-4x3" />
        <!-- <UIcon :name="currentLanguage.icon" /> -->
      </template>
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
    icon: "i-flag:us-4x3",
  },
  {
    value: "bn",
    label: "বাংলা",
    icon: "i-flag:bd-4x3",
  },
];
const currentLanguage = ref(languageOption[1]);

watch(currentLanguage, () => {
  setLocale(currentLanguage.value.value);
  language.value = currentLanguage.value;
});
onMounted(() => {
  currentLanguage.value = language.value;

  if (language.value) {
    setLocale(language.value.value);
  } else {
    setLocale("bn");
  }
});
</script>

<style scoped></style>
