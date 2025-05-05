<template>
  <Transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="opacity-0 scale-95"
    enter-to-class="opacity-100 scale-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="opacity-100 scale-100"
    leave-to-class="opacity-0 scale-95"
  >
    <div
      v-if="modelValue"
      class="fixed inset-0 z-50 flex items-center justify-center perspective-1000"
    >
      <!-- Enhanced backdrop with gradient and blur -->
      <div
        class="absolute inset-0 bg-gradient-to-br from-slate-900/70 to-blue-900/70 backdrop-blur-md"
        @click="$emit('update:modelValue', false)"
      ></div>

      <!-- Modal with premium styling -->
      <div
        class="relative bg-white dark:bg-slate-800 rounded-xl shadow-2xl w-full max-w-xl mx-4 max-h-[85vh] overflow-hidden border border-slate-100 dark:border-slate-700 animate-fade-in-up"
      >
        <!-- Premium scrollbar styling -->
        <div class="overflow-y-auto custom-scrollbar max-h-[80vh]">
          <!-- Close button with enhanced styling -->
          <button
            @click="$emit('update:modelValue', false)"
            class="absolute top-4 z-30 right-4 p-1.5 rounded-full hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors group"
            aria-label="Close"
          >
            <X
              class="h-5 w-5 text-slate-500 dark:text-slate-400 group-hover:rotate-90 transition-transform"
            />
          </button>

          <!-- Modal header with subtle decorative elements -->
          <div
            class="relative px-6 py-6 border-b border-slate-100 dark:border-slate-700"
          >
            <div
              class="absolute inset-0 bg-grid-pattern opacity-5 pointer-events-none"
            ></div>
            <h2
              class="text-xl font-bold mb-1 text-slate-800 dark:text-white relative z-10 flex items-center"
            >
              <div
                class="h-6 w-6 rounded-full bg-blue-500 mr-2.5 flex items-center justify-center"
              >
                <Plus class="h-4 w-4 text-white" />
              </div>
              Post a New Problem
            </h2>
            <p class="text-slate-500 dark:text-slate-400 text-md ml-8.5">
              Share your problem with the community and get expert help.
            </p>
          </div>

          <!-- Form content -->
          <div class="flex flex-col px-6 py-5 space-y-5">
            <div class="space-y-2">
              <label
                for="title"
                class="text-md font-medium text-slate-700 dark:text-slate-300 flex items-center"
              >
                <Hash class="h-4 w-4 mr-1.5 text-blue-500" />
                Problem Title
              </label>
              <input
                id="title"
                v-model="formData.title"
                placeholder="Enter a clear, specific title for your problem"
                class="flex h-10 w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-md ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 dark:focus-visible:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 transition-all shadow-sm"
              />
            </div>

            <div class="space-y-2">
              <label
                for="description"
                class="text-md font-medium text-slate-700 dark:text-slate-300 flex items-center"
              >
                <FileText class="h-4 w-4 mr-1.5 text-blue-500" />
                Description
              </label>
              <textarea
                id="description"
                v-model="formData.description"
                placeholder="Describe your problem in detail. Include what you've tried so far and what you're trying to achieve."
                rows="5"
                class="flex w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-md ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 dark:focus-visible:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all shadow-sm resize-none"
              ></textarea>
            </div>

            <!-- Enhanced Photo Upload Section -->
            <div class="space-y-2">
              <label
                class="text-md font-medium text-slate-700 dark:text-slate-300 flex justify-between items-center"
              >
                <span class="flex items-center">
                  <Image class="h-4 w-4 mr-1.5 text-blue-500" />
                  Photos (Optional)
                </span>
                <span
                  class="text-sm text-slate-500 dark:text-slate-400 px-2 py-0.5 rounded-full bg-slate-100 dark:bg-slate-700"
                  >{{ formData.images?.length }}/4 photos</span
                >
              </label>

              <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                <!-- Existing photos with enhanced styling -->
                <div
                  v-for="(photo, index) in formData.images"
                  :key="index"
                  class="relative aspect-square rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden group shadow-sm hover:shadow-md transition-all"
                >
                  <img
                    :src="photo"
                    alt="Problem photo"
                    class="w-full h-full object-cover transition-transform group-hover:scale-105"
                  />
                  <div
                    class="absolute inset-0 bg-gradient-to-t from-slate-900/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"
                  ></div>
                  <button
                    @click="removePhoto(index)"
                    class="absolute bottom-2 right-2 bg-red-500 rounded-full p-1.5 hover:bg-red-600 transition-colors transform opacity-0 group-hover:opacity-100 scale-75 group-hover:scale-100"
                    aria-label="Remove photo"
                  >
                    <Trash class="h-3 w-3 text-white" />
                  </button>
                </div>

                <!-- Add photo button with premium styling -->
                <label
                  v-if="formData.images.length < 4"
                  class="flex flex-col items-center justify-center cursor-pointer aspect-square rounded-lg border-2 border-dashed border-slate-300 dark:border-slate-600 hover:border-blue-400 dark:hover:border-blue-500 transition-colors bg-slate-50 dark:bg-slate-800/50 group"
                >
                  <input
                    type="file"
                    accept="image/*"
                    class="hidden"
                    @change="handlePhotoUpload"
                  />
                  <div
                    class="p-2 rounded-full bg-slate-100 dark:bg-slate-700 group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30 transition-colors"
                  >
                    <ImagePlus
                      class="h-5 w-5 text-slate-400 dark:text-slate-500 group-hover:text-blue-500 transition-colors"
                    />
                  </div>
                  <span
                    class="mt-2 text-sm text-slate-500 dark:text-slate-400 group-hover:text-blue-500 transition-colors"
                    >Add Photo</span
                  >
                </label>
              </div>
            </div>

            <!-- Category selector with premium styling -->
            <div class="space-y-2">
              <label
                for="category"
                class="text-md font-medium text-slate-700 dark:text-slate-300 flex items-center"
              >
                <TagIcon class="h-4 w-4 mr-1.5 text-blue-500" />
                Category
              </label>
              <div class="relative">
                <select
                  id="category"
                  v-model="formData.category"
                  class="flex h-10 w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-md ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 dark:focus-visible:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 transition-all shadow-sm appearance-none pr-10"
                >
                  <option value="" disabled>Select a category</option>
                  <option
                    v-for="cat in categories"
                    :key="cat.id"
                    :value="cat.id"
                  >
                    {{ cat.name }}
                  </option>
                </select>
                <ChevronDown
                  class="absolute right-3 top-3 h-4 w-4 text-slate-500 dark:text-slate-400 pointer-events-none"
                />
              </div>
            </div>

            <!-- Help Type selector with premium styling -->
            <div class="space-y-2">
              <label
                class="text-md font-medium text-slate-700 dark:text-slate-300 flex items-center"
              >
                <HelpCircle class="h-4 w-4 mr-1.5 text-blue-500" />
                Help Type
              </label>
              <div class="grid grid-cols-2 gap-3 mt-1">
                <div
                  @click="formData.payment_option = 'free'"
                  :class="[
                    'flex items-center space-x-2 px-4 py-3 rounded-lg border cursor-pointer transition-all',
                    formData.payment_option === 'free'
                      ? 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700 ring-1 ring-blue-400 dark:ring-blue-600 shadow-sm'
                      : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/50',
                  ]"
                >
                  <input
                    type="radio"
                    id="free"
                    value="free"
                    v-model="formData.payment_option"
                    class="h-4 w-4 border-blue-500 text-blue-600 focus:ring-blue-500"
                  />
                  <label
                    for="free"
                    class="text-md cursor-pointer text-slate-700 dark:text-slate-300"
                    >I need help for free</label
                  >
                </div>
                <div
                  @click="formData.payment_option = 'paid'"
                  :class="[
                    'flex items-center space-x-2 p-3 rounded-lg border cursor-pointer transition-all',
                    formData.payment_option === 'paid'
                      ? 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-900/30 ring-1 ring-emerald-400 dark:ring-emerald-700 shadow-sm'
                      : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/50',
                  ]"
                >
                  <input
                    type="radio"
                    id="paid"
                    value="paid"
                    v-model="formData.payment_option"
                    class="h-4 w-4 border-emerald-500 text-emerald-600 focus:ring-emerald-500"
                  />
                  <label
                    for="paid"
                    class="text-md cursor-pointer text-slate-700 dark:text-slate-300"
                    >I can pay for help</label
                  >
                </div>
              </div>
            </div>

            <!-- Payment amount with premium styling -->
            <div v-if="formData.payment_option === 'paid'" class="space-y-2">
              <label
                for="paymentAmount"
                class="text-md font-medium text-slate-700 dark:text-slate-300 flex items-center"
              >
                <DollarSign class="h-4 w-4 mr-1.5 text-emerald-500" />
                Payment Amount
              </label>
              <div class="relative">
                <span
                  class="absolute left-3 top-2.5 text-emerald-600 dark:text-emerald-400"
                  >৳</span
                >
                <input
                  id="paymentAmount"
                  v-model="formData.payment_amount"
                  type="number"
                  placeholder="Enter amount"
                  class="flex h-10 w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 pl-7 pr-3 py-2 text-md ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-emerald-400 dark:focus:border-emerald-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-emerald-400 dark:focus-visible:ring-emerald-500 disabled:cursor-not-allowed disabled:opacity-50 transition-all shadow-sm"
                />
              </div>
            </div>
          </div>

          <!-- Action buttons with premium styling -->
          <div
            class="flex justify-end gap-3 p-6 border-t border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50"
          >
            <button
              @click="$emit('update:modelValue', false)"
              class="inline-flex items-center justify-center rounded-lg text-md font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 h-10 px-4 py-2 shadow-sm"
            >
              Cancel
            </button>
            <button
              @click="handleSubmit"
              :disabled="!isFormValid || isSubmitting"
              :class="[
                'inline-flex items-center justify-center rounded-lg text-md font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-5 py-2 shadow-md hover:shadow-lg transform hover:-translate-y-0.5 active:translate-y-0',
                isFormValid && !isSubmitting
                  ? 'bg-gradient-to-r from-blue-500 to-violet-500 hover:from-blue-600 hover:to-violet-600 text-white'
                  : 'bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400',
              ]"
            >
              <span v-if="isSubmitting" class="flex items-center">
                <svg
                  class="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                Posting...
              </span>
              <span v-else class="flex items-center">
                <Send class="h-4 w-4 mr-1.5" />
                Post Problem
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import {
  X,
  ImagePlus,
  Hash,
  FileText,
  Image,
  TagIcon,
  ChevronDown,
  HelpCircle,
  Send,
  DollarSign,
  Trash,
  Plus,
} from "lucide-vue-next";
import { ref, computed } from "vue";

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
  categories: {
    type: Array,
    default: () => [],
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
  initialFormData: {
    type: Object,
    default: () => ({
      title: "",
      description: "",
      category: "",
      payment_option: "free",
      payment_amount: "",
      images: [],
    }),
  },
});

const emit = defineEmits(["update:modelValue", "submit"]);

// Create a local reactive form data object that is initialized from props
const formData = ref({ ...props.initialFormData });

// Computed property to check if form is valid
const isFormValid = computed(() => {
  return (
    formData.value.title.trim() &&
    formData.value.description.trim() &&
    formData.value.category
  );
});

// Handle photo upload
const handlePhotoUpload = (event) => {
  const files = Array.from(event.target.files);
  if (!files.length) return;

  const reader = new FileReader();
  reader.onload = () => {
    formData.value.images.push(reader.result);
  };
  reader.onerror = (error) => console.error("Error reading file:", error);
  reader.readAsDataURL(files[0]);
};

// Remove photo
const removePhoto = (index) => {
  formData.value.images.splice(index, 1);
};

// Submit form
const handleSubmit = () => {
  if (isFormValid.value && !props.isSubmitting) {
    emit("submit", formData.value);
  }
};
</script>

<style scoped>
/* Grid background pattern */
.bg-grid-pattern {
  background-image: linear-gradient(
      to right,
      rgba(0, 0, 0, 0.05) 1px,
      transparent 1px
    ),
    linear-gradient(to bottom, rgba(0, 0, 0, 0.05) 1px, transparent 1px);
  background-size: 20px 20px;
}

@media (prefers-color-scheme: dark) {
  .bg-grid-pattern {
    background-image: linear-gradient(
        to right,
        rgba(255, 255, 255, 0.05) 1px,
        transparent 1px
      ),
      linear-gradient(to bottom, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
  }
}

/* Premium scrollbar styling */
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background-color: rgba(0, 0, 0, 0.05);
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, 0.15);
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background-color: rgba(0, 0, 0, 0.25);
}

/* Dark mode scrollbar */
@media (prefers-color-scheme: dark) {
  .custom-scrollbar::-webkit-scrollbar-track {
    background-color: rgba(255, 255, 255, 0.05);
  }

  .custom-scrollbar::-webkit-scrollbar-thumb {
    background-color: rgba(255, 255, 255, 0.15);
  }

  .custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background-color: rgba(255, 255, 255, 0.25);
  }
}

/* Animations */
.animate-fade-in-up {
  animation: fadeInUp 0.3s ease-out forwards;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Perspective for 3D effects */
.perspective-1000 {
  perspective: 1000px;
}
</style>
