<template>
  <div
    v-if="modelValue"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4"
    @click="close"
  >
    <div
      class="w-full max-w-md rounded-lg border border-gray-200 bg-white shadow-xl"
      @click.stop
    >
      <div class="flex items-center justify-between border-b p-5">
        <h3 class="font-semibold text-gray-800">{{ title }}</h3>
        <button
          class="text-gray-400 transition-colors duration-200 hover:text-gray-600"
          :disabled="submitting"
          @click="close"
        >
          <X class="h-5 w-5" />
        </button>
      </div>

      <div class="p-5">
        <p class="mb-4 text-sm text-gray-600">{{ prompt }}</p>

        <div class="space-y-2">
          <label
            v-for="option in normalizedOptions"
            :key="option.value"
            class="flex cursor-pointer items-center space-x-2"
          >
            <input
              v-model="reason"
              type="radio"
              :value="option.value"
              class="text-emerald-600"
              :disabled="submitting"
            />
            <span class="text-sm text-gray-800">{{ option.label }}</span>
          </label>
        </div>

        <textarea
          v-model="details"
          :placeholder="detailsPlaceholder"
          class="mt-4 h-24 w-full resize-none rounded-md border border-gray-200 p-2 text-sm text-gray-800 focus:outline-none focus:ring-1 focus:ring-emerald-500"
          :disabled="submitting"
        />

        <div class="mt-6 flex justify-end space-x-3">
          <button
            class="rounded-md border border-gray-200 px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="submitting"
            @click="close"
          >
            Cancel
          </button>
          <button
            class="rounded-md bg-emerald-600 px-4 py-2 text-sm text-white transition-colors duration-200 hover:bg-emerald-700 disabled:cursor-not-allowed disabled:bg-gray-300"
            :disabled="!reason || submitting"
            @click="submit"
          >
            {{ submitting ? "Submitting..." : submitLabel }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { X } from "lucide-vue-next";

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: "Report",
  },
  prompt: {
    type: String,
    default: "Please select a reason for reporting this item:",
  },
  options: {
    type: Array,
    default: () => [
      { label: "Spam or misleading", value: "spam" },
      { label: "Inappropriate content", value: "inappropriate" },
      { label: "Fraudulent or scam", value: "fraud" },
      { label: "Other", value: "other" },
    ],
  },
  detailsPlaceholder: {
    type: String,
    default: "Additional details (optional)",
  },
  submitLabel: {
    type: String,
    default: "Submit Report",
  },
  successMessage: {
    type: String,
    default: "Thank you for your report. We will review it shortly.",
  },
  failureMessage: {
    type: String,
    default: "Failed to submit report. Please try again.",
  },
  onSubmit: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(["update:modelValue", "submitted"]);
const toast = useToast();

const reason = ref("");
const details = ref("");
const submitting = ref(false);

const normalizedOptions = computed(() =>
  props.options.map((option) =>
    typeof option === "string" ? { label: option, value: option } : option
  )
);

watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen) {
      reason.value = "";
      details.value = "";
      submitting.value = false;
    }
  }
);

const close = () => {
  if (submitting.value) return;
  emit("update:modelValue", false);
};

const submit = async () => {
  if (!reason.value || submitting.value) return;

  submitting.value = true;
  const selected = normalizedOptions.value.find(
    (option) => option.value === reason.value
  );

  try {
    const ok = await props.onSubmit({
      reason: reason.value,
      label: selected?.label || reason.value,
      details: details.value.trim(),
    });

    if (ok === false) {
      throw new Error("Report submission failed");
    }

    toast.add({
      title: "Report Submitted",
      description: props.successMessage,
      color: "green",
      icon: "i-heroicons-check-circle",
    });
    emit("submitted");
    emit("update:modelValue", false);
  } catch (error) {
    toast.add({
      title: "Report Failed",
      description: props.failureMessage,
      color: "red",
      icon: "i-heroicons-exclamation-triangle",
    });
  } finally {
    submitting.value = false;
  }
};
</script>
