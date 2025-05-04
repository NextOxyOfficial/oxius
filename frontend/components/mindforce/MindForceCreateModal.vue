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
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <!-- Backdrop with blur -->
      <div
        class="absolute inset-0 bg-black/50 backdrop-blur-sm"
        @click="$emit('update:modelValue', false)"
      ></div>

      <!-- Modal -->
      <div
        class="relative bg-white rounded-xl shadow-xl w-full max-w-xl mx-4 max-h-[80vh] overflow-y-auto"
      >
        <!-- Close button (X) at top right -->
        <button
          @click="$emit('update:modelValue', false)"
          class="absolute top-4 right-4 p-1 rounded-full hover:bg-gray-100 transition-colors"
          aria-label="Close"
        >
          <X class="h-5 w-5 text-gray-500" />
        </button>

        <div class="flex flex-col px-2 py-6">
          <h2 class="text-xl font-semibold mb-1 text-gray-700">
            Post a New Problem
          </h2>
          <p class="text-gray-500 text-md mb-4">
            Share your problem with the community and get expert help.
          </p>

          <div class="space-y-4">
            <div class="space-y-2">
              <label for="title" class="text-md font-medium text-gray-700"
                >Problem Title</label
              >
              <input
                id="title"
                v-model="formData.title"
                placeholder="Enter a clear, specific title for your problem"
                class="flex h-10 w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-md ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 transition-all"
              />
            </div>

            <div class="space-y-2">
              <label
                for="description"
                class="text-md font-medium text-gray-700"
                >Description</label
              >
              <textarea
                id="description"
                v-model="formData.description"
                placeholder="Describe your problem in detail. Include what you've tried so far and what you're trying to achieve."
                rows="5"
                class="flex w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-md ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all"
              ></textarea>
            </div>

            <!-- Photo Upload Section -->
            <div class="space-y-2">
              <label
                class="text-md font-medium text-gray-700 flex justify-between"
              >
                <span>Photos (Optional)</span>
                <span class="text-sm text-gray-500"
                  >{{ formData.images?.length }}/4 photos</span
                >
              </label>

              <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                <!-- Existing photos -->
                <div
                  v-for="(photo, index) in formData.images"
                  :key="index"
                  class="relative aspect-square rounded-lg border border-gray-200 overflow-hidden"
                >
                  <img
                    :src="photo"
                    alt="Problem photo"
                    class="w-full h-full object-cover"
                  />
                  <button
                    @click="removePhoto(index)"
                    class="absolute top-1 right-1 bg-black/50 rounded-full p-1 hover:bg-black/75 transition-colors"
                    aria-label="Remove photo"
                  >
                    <X class="h-3 w-3 text-white" />
                  </button>
                </div>

                <!-- Add photo button (only show if less than 4 photos) -->
                <label
                  v-if="formData.images.length < 4"
                  class="flex flex-col items-center justify-center cursor-pointer aspect-square rounded-lg border-2 border-dashed border-gray-300 hover:border-gray-400 transition-colors bg-gray-50"
                >
                  <input
                    type="file"
                    accept="image/*"
                    class="hidden"
                    @change="handlePhotoUpload"
                  />
                  <ImagePlus class="h-6 w-6 text-gray-400" />
                  <span class="mt-1 text-sm text-gray-500">Add Photo</span>
                </label>
              </div>
            </div>

            <div class="space-y-2">
              <label for="category" class="text-md font-medium text-gray-700"
                >Category</label
              >
              <select
                id="category"
                v-model="formData.category"
                class="flex h-10 w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-md ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 transition-all"
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
            </div>

            <div class="space-y-2">
              <label class="text-md font-medium text-gray-700"
                >Help Type</label
              >
              <div class="grid grid-cols-2 gap-3 mt-1">
                <div
                  @click="formData.payment_option = 'free'"
                  :class="[
                    'flex items-center space-x-2 px-3 rounded-lg border cursor-pointer transition-all',
                    formData.payment_option === 'free'
                      ? 'bg-blue-50 border-blue-200 ring-1 ring-blue-400'
                      : 'border-gray-200 hover:bg-gray-50',
                  ]"
                >
                  <input
                    type="radio"
                    id="free"
                    value="free"
                    v-model="formData.payment_option"
                    class="h-4 w-4 border-blue-500 text-blue-600 focus:ring-blue-500"
                  />
                  <label for="free" class="text-md cursor-pointer"
                    >I need help for free</label
                  >
                </div>
                <div
                  @click="formData.payment_option = 'paid'"
                  :class="[
                    'flex items-center space-x-2 p-3 rounded-lg border cursor-pointer transition-all',
                    formData.payment_option === 'paid'
                      ? 'bg-green-50 border-green-200 ring-1 ring-green-400'
                      : 'border-gray-200 hover:bg-gray-50',
                  ]"
                >
                  <input
                    type="radio"
                    id="paid"
                    value="paid"
                    v-model="formData.payment_option"
                    class="h-4 w-4 border-green-500 text-green-600 focus:ring-green-500"
                  />
                  <label for="paid" class="text-md cursor-pointer"
                    >I can pay for help</label
                  >
                </div>
              </div>
            </div>

            <div
              v-if="formData.payment_option === 'paid'"
              class="space-y-2"
            >
              <label
                for="paymentAmount"
                class="text-md font-medium text-gray-700"
                >Payment Amount ৳</label
              >
              <div class="relative">
                <span class="absolute left-3 top-2.5 text-gray-500">৳</span>
                <input
                  id="paymentAmount"
                  v-model="formData.payment_amount"
                  type="number"
                  placeholder="Enter amount"
                  class="flex h-10 w-full rounded-lg border border-gray-200 bg-white pl-7 pr-3 py-2 text-md ring-offset-background placeholder:text-gray-400 focus:border-green-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-green-400 disabled:cursor-not-allowed disabled:opacity-50 transition-all"
                />
              </div>
            </div>
          </div>

          <div class="flex justify-end gap-3 mt-6 mb-8">
            <button
              @click="$emit('update:modelValue', false)"
              class="inline-flex items-center justify-center rounded-lg text-md font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-gray-200 bg-white text-gray-700 hover:bg-gray-100 h-10 px-4 py-2"
            >
              Cancel
            </button>
            <button
              @click="handleSubmit"
              :disabled="!isFormValid || isSubmitting"
              :class="[
                'inline-flex items-center justify-center rounded-lg text-md font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-5 py-2',
                isFormValid && !isSubmitting
                  ? 'bg-blue-600 text-white hover:bg-blue-700 shadow-md hover:shadow-sm'
                  : 'bg-gray-200 text-gray-500',
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
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                Posting...
              </span>
              <span v-else>Post Problem</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { X, ImagePlus } from "lucide-vue-next";
import { ref, computed } from "vue";

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true
  },
  categories: {
    type: Array,
    default: () => []
  },
  isSubmitting: {
    type: Boolean,
    default: false
  },
  initialFormData: {
    type: Object,
    default: () => ({
      title: "",
      description: "",
      category: "",
      payment_option: "free",
      payment_amount: "",
      images: []
    })
  }
});

const emit = defineEmits(['update:modelValue', 'submit']);

// Create a local reactive form data object that is initialized from props
const formData = ref({...props.initialFormData});

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
    emit('submit', formData.value);
  }
};
</script>