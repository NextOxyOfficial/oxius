<template>
  <div class="inline-block">
    <UPopover :ui="{ width: 'w-auto' }">
      <UButton
        color="white"
        variant="ghost"
        class="p-1.5 min-w-0 rounded-md transition-all duration-200 hover:bg-gray-100 dark:hover:bg-gray-800"
        :aria-label="currentLanguage?.label || 'Select language'"
      >
        <div class="flex items-center gap-2">
          <UIcon
            v-if="currentLanguage?.icon"
            :name="currentLanguage.icon"
            class="w-6 h-5 rounded shadow transition-transform duration-200 hover:scale-110"
          />
          <span v-if="showText" class="text-sm font-medium">{{ currentLanguage?.label }}</span>
        </div>
      </UButton>

      <template #panel>
        <div class="flex flex-col gap-1 py-1">
          <UButton
            v-for="lang in languageOption"
            :key="lang.value"
            variant="ghost"
            color="gray"
            class="w-full flex items-center justify-start p-1.5 gap-2 rounded"
            @click="currentLanguage = lang"
          >
            <UIcon :name="lang.icon" class="w-6 h-5 rounded shadow transition-transform duration-200 group-hover:scale-110" />
            <span v-if="showText" class="text-sm">{{ lang.label }}</span>
          </UButton>
        </div>
      </template>
    </UPopover>
  </div>
</template>

<script setup>
// Define props to control whether to show text
const props = defineProps({
  showText: {
    type: Boolean,
    default: false
  }
});

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

<!-- No custom CSS needed, using Tailwind classes instead -->

