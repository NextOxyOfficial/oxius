<template>
  <div class="flag-selector">
    <UPopover :ui="{ width: 'w-auto' }">
      <UButton
        color="white"
        variant="ghost"
        class="flag-button p-1.5 min-w-0"
        :aria-label="currentLanguage?.label || 'Select language'"
      >
        <UIcon
          v-if="currentLanguage?.icon"
          :name="currentLanguage.icon"
          class="flag-icon w-6 h-5"
        />
      </UButton>

      <template #panel>
        <div class="flag-options py-1">
          <UButton
            v-for="lang in languageOption"
            :key="lang.value"
            variant="ghost"
            color="gray"
            class="flag-option w-full flex items-center justify-center p-1.5"
            @click="currentLanguage = lang"
          >
            <UIcon :name="lang.icon" class="flag-icon w-6 h-5" />
          </UButton>
        </div>
      </template>
    </UPopover>
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
  if (language.value) {
    currentLanguage.value = language.value;
    setLocale(language.value.value);
  } else {
    setLocale("bn");
  }
});
</script>

<style scoped>
.flag-selector {
  display: inline-block;
}

.flag-button {
  padding: 0.25rem;
  border-radius: 0.375rem;
  transition: all 0.2s ease;
}

.flag-button:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

.dark .flag-button:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.flag-icon {
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  border-radius: 2px;
  transition: transform 0.2s ease;
}

.flag-button:hover .flag-icon {
  transform: scale(1.1);
}

.flag-options {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.flag-option {
  border-radius: 0.25rem;
}

.flag-option:hover .flag-icon {
  transform: scale(1.1);
}
</style>
