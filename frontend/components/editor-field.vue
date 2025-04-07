<!-- filepath: c:\Users\NextOxy\Desktop\office\oxy-us\frontend\components\common\EditorField.vue -->
<template>
  <div class="editor-field mb-3">
    <label
      v-if="label"
      class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
    >
      {{ label }}
    </label>

    <!-- Text input -->
    <input
      v-if="type === 'text'"
      v-model="localValue"
      :placeholder="placeholder"
      class="form-input w-full border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:border-primary-500 focus:ring focus:ring-primary-500 focus:ring-opacity-50 transition duration-150 ease-in-out text-sm dark:bg-slate-800 dark:text-white"
      :class="{
        'border-primary-500 bg-primary-50 dark:bg-primary-900/10': hasChanged,
      }"
    />

    <!-- Number input -->
    <input
      v-else-if="type === 'number'"
      v-model="localValue"
      type="number"
      :min="min"
      :max="max"
      :placeholder="placeholder"
      class="form-input w-full border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:border-primary-500 focus:ring focus:ring-primary-500 focus:ring-opacity-50 transition duration-150 ease-in-out text-sm dark:bg-slate-800 dark:text-white"
      :class="{
        'border-primary-500 bg-primary-50 dark:bg-primary-900/10': hasChanged,
      }"
    />

    <!-- Textarea -->
    <textarea
      v-else-if="type === 'textarea'"
      v-model="localValue"
      :placeholder="placeholder"
      class="form-textarea w-full border-slate-300 dark:border-slate-600 rounded-md shadow-sm focus:border-primary-500 focus:ring focus:ring-primary-500 focus:ring-opacity-50 transition duration-150 ease-in-out text-sm dark:bg-slate-800 dark:text-white"
      :class="{
        'border-primary-500 bg-primary-50 dark:bg-primary-900/10': hasChanged,
      }"
      rows="3"
    ></textarea>

    <div v-if="hasChanged" class="mt-1 flex items-center justify-end">
      <span class="text-xs text-primary-600 dark:text-primary-400 mr-2">
        <UIcon
          name="i-heroicons-pencil-square"
          class="w-3 h-3 mr-1 inline-block"
        />
        Modified
      </span>
      <UButton size="xs" color="gray" variant="soft" @click="resetToOriginal">
        Reset
      </UButton>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from "vue";

const props = defineProps({
  modelValue: {
    type: [String, Number],
    default: "",
  },
  label: {
    type: String,
    default: "",
  },
  placeholder: {
    type: String,
    default: "",
  },
  type: {
    type: String,
    default: "text",
    validator: (value) => ["text", "textarea", "number"].includes(value),
  },
  min: {
    type: [Number, String],
    default: undefined,
  },
  max: {
    type: [Number, String],
    default: undefined,
  },
});

const emit = defineEmits(["update:modelValue"]);

const localValue = ref(props.modelValue);
const originalValue = ref(props.modelValue);

// Check if the value has been modified
const hasChanged = computed(() => {
  return localValue.value !== originalValue.value;
});

// Reset to original value
function resetToOriginal() {
  localValue.value = originalValue.value;
}

// Watch for changes from parent
watch(
  () => props.modelValue,
  (newValue) => {
    // Only update if it wasn't changed by the user
    if (localValue.value === originalValue.value) {
      localValue.value = newValue;
      originalValue.value = newValue;
    }
  }
);

// Watch for local changes and emit to parent
watch(localValue, (newValue) => {
  emit("update:modelValue", newValue);
});
</script>

<style scoped>
.editor-field {
  transition: all 0.2s ease;
}

.editor-field:hover {
  @apply bg-slate-50/80 dark:bg-slate-800/50 -mx-1 px-1 py-1 rounded;
}
</style>
