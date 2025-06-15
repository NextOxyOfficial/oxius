<template>
  <Teleport to="body">    
    <Transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="modelValue"
        class="fixed inset-0 z-50 overflow-y-auto"
        @click="$emit('update:modelValue', false)"
      >
        <!-- Enhanced backdrop with gradient and blur -->
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-all duration-300 backdrop-blur-sm"
          aria-hidden="true"
          @click="$emit('update:modelValue', false)"
        ></div>

        <!-- Modal container matching UModal structure -->
        <div class="flex flex-col h-auto my-20 p-0 sm:p-0">        
          <Transition            
            enter-active-class="transition ease-out duration-200"
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-active-class="transition ease-in duration-150"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
          >
            <div v-if="modelValue">
              <!-- Modal with enhanced styling -->
              <div
                class="relative w-full sm:max-w-4xl mx-auto bg-white dark:bg-slate-800 rounded-xl shadow-sm"
                @click.stop
              >
                <!-- Close button with enhanced styling -->
                <button
                  @click="$emit('update:modelValue', false)"
                  class="absolute top-4 z-30 right-4 p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-700 transition-all duration-200 group hover:scale-110 active:scale-95"
                  aria-label="Close"
                >
                  <X
                    class="h-5 w-5 text-slate-500 dark:text-slate-400 group-hover:rotate-90 transition-all duration-300"
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
                class="text-lg font-semibold mb-1 text-gray-800 dark:text-white relative z-10 flex items-center"
              >
                <div
                  class="h-6 w-6 rounded-full bg-blue-500 mr-2.5 flex items-center justify-center"
                >
                  <Plus class="h-4 w-4 text-white" />
                </div>
                Post a New Problem
              </h2>
              <p class="text-slate-500 dark:text-slate-400 text-sm text-start ml-8.5">
                Share your problem with the community and get expert help.
              </p>
            </div>
            
            <!-- Form content -->
            <div class="flex flex-col px-6 py-5 space-y-6">
              <Transition
                appear
                enter-active-class="transition-all duration-500 ease-out"
                enter-from-class="opacity-0 transform translate-y-4"
                enter-to-class="opacity-100 transform translate-y-0"
              >
                <div class="space-y-2">
                  <label
                    for="title"
                    class="text-sm font-medium text-slate-700 dark:text-slate-300 flex items-center group"
                  >
                    <Hash class="h-4 w-4 mr-1.5 text-blue-500 group-hover:scale-110 transition-transform duration-200" />
                    Problem Title
                  </label>
                  <input
                    id="title"
                    v-model="formData.title"
                    placeholder="Enter a clear, specific title for your problem"
                    class="flex h-11 w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2 text-sm ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400/30 dark:focus-visible:ring-blue-500/30 disabled:cursor-not-allowed disabled:opacity-50 transition-all duration-200 shadow-sm hover:shadow-sm focus:shadow-sm"
                    @focus="handleInputFocus"
                    @blur="handleInputBlur"
                  />
                </div>
              </Transition>              
              <Transition
                appear
                enter-active-class="transition-all duration-500 ease-out"
                enter-from-class="opacity-0 transform translate-y-4"
                enter-to-class="opacity-100 transform translate-y-0"
                :style="{ 'transition-delay': '100ms' }"
              >
                <div class="space-y-2">
                  <label
                    for="description"
                    class="text-sm font-medium text-slate-700 dark:text-slate-300 flex items-center group"
                  >
                    <FileText class="h-4 w-4 mr-1.5 text-blue-500 group-hover:scale-110 transition-transform duration-200" />
                    Description
                  </label>
                  <textarea
                    id="description"
                    v-model="formData.description"
                    placeholder="Describe your problem in detail. Include what you've tried so far and what you're trying to achieve."
                    rows="5"
                    class="flex w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-3 text-sm ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400/30 dark:focus-visible:ring-blue-500/30 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all duration-200 shadow-sm hover:shadow-sm focus:shadow-sm resize-none"
                    @focus="handleInputFocus"
                    @blur="handleInputBlur"
                  ></textarea>
                </div>
              </Transition>              
              <!-- Enhanced Photo Upload Section -->
              <Transition
                appear
                enter-active-class="transition-all duration-500 ease-out"
                enter-from-class="opacity-0 transform translate-y-4"
                enter-to-class="opacity-100 transform translate-y-0"
                :style="{ 'transition-delay': '200ms' }"
              >
                <div class="space-y-3">
                  <label
                    class="text-sm font-medium text-slate-700 dark:text-slate-300 flex justify-between items-center group"
                  >
                    <span class="flex items-center">
                      <Image class="h-4 w-4 mr-1.5 text-blue-500 group-hover:scale-110 transition-transform duration-200" />
                      Photos (Optional)
                    </span>
                    <span
                      class="text-sm text-slate-500 dark:text-slate-400 px-3 py-1 rounded-full bg-slate-100 dark:bg-slate-700 transition-all duration-200 hover:bg-slate-200 dark:hover:bg-slate-600"
                      >{{ formData.images?.length }}/4 photos</span
                    >
                  </label>
                  
                  <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    <!-- Existing photos with enhanced styling -->
                    <TransitionGroup
                      enter-active-class="transition-all duration-300 ease-out"
                      enter-from-class="opacity-0 transform scale-90"
                      enter-to-class="opacity-100 transform scale-100"
                      leave-active-class="transition-all duration-200 ease-in"
                      leave-from-class="opacity-100 transform scale-100"
                      leave-to-class="opacity-0 transform scale-90"
                      move-class="transition-transform duration-300"
                    >
                      <div
                        v-for="(photo, index) in formData.images"
                        :key="`photo-${index}`"
                        class="relative aspect-square rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden group shadow-sm hover:shadow-sm transition-all duration-300 hover:scale-105"
                        data-photo-index="index"
                      >
                        <img
                          :src="photo"
                          alt="Problem photo"
                          class="w-full h-full object-cover transition-all duration-500 group-hover:scale-110"
                        />
                        <div
                          class="absolute inset-0 bg-gradient-to-t from-slate-900/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-all duration-300"
                        ></div>
                        <button
                          @click="removePhoto(index)"
                          class="absolute bottom-2 right-2 bg-red-500/90 backdrop-blur-sm rounded-full p-2 hover:bg-red-600 transition-all duration-200 transform opacity-0 group-hover:opacity-100 scale-75 group-hover:scale-100 hover:scale-110 active:scale-95"
                          aria-label="Remove photo"
                        >
                          <Trash class="h-3.5 w-3.5 text-white" />
                        </button>
                      </div>
                    </TransitionGroup>                    
                    <!-- Add photo button with premium styling -->
                    <label
                      v-if="formData.images.length < 4"
                      :class="[
                        'flex flex-col items-center justify-center cursor-pointer aspect-square rounded-xl border-2 border-dashed transition-all duration-300 bg-slate-50 dark:bg-slate-800/50 group hover:scale-105 active:scale-95',
                        isCompressing 
                          ? 'border-blue-400 dark:border-blue-500 bg-blue-50 dark:bg-blue-900/20 cursor-wait scale-105' 
                          : 'border-slate-300 dark:border-slate-600 hover:border-blue-400 dark:hover:border-blue-500 hover:bg-blue-50/50 dark:hover:bg-blue-900/10'
                      ]"
                    >
                      <input
                        type="file"
                        accept="image/*"
                        class="hidden"
                        :disabled="isCompressing"
                        @change="handlePhotoUpload"
                      />
                      <div
                        v-if="isCompressing"
                        class="p-3 rounded-full bg-blue-100 dark:bg-blue-900/30"
                      >
                        <svg
                          class="animate-spin h-6 w-6 text-blue-500"
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
                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 012 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                          ></path>
                        </svg>
                      </div>
                      <div
                        v-else
                        class="p-3 rounded-full bg-slate-100 dark:bg-slate-700 group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30 transition-all duration-300 group-hover:scale-110"
                      >
                        <ImagePlus
                          class="h-6 w-6 text-slate-400 dark:text-slate-500 group-hover:text-blue-500 transition-colors duration-300"
                        />
                      </div>
                      <span
                        :class="[
                          'mt-2 text-sm font-medium transition-all duration-300',
                          isCompressing
                            ? 'text-blue-500'
                            : 'text-slate-500 dark:text-slate-400 group-hover:text-blue-500'
                        ]"
                      >{{ isCompressing ? 'Compressing...' : 'Add Photo' }}</span>
                    </label>
                  </div>
                </div>
              </Transition>              
              <!-- Category selector with premium styling -->
              <Transition
                appear
                enter-active-class="transition-all duration-500 ease-out"
                enter-from-class="opacity-0 transform translate-y-4"
                enter-to-class="opacity-100 transform translate-y-0"
                :style="{ 'transition-delay': '300ms' }"
              >
                <div class="space-y-2">
                  <label
                    for="category"
                    class="text-sm font-medium text-slate-700 dark:text-slate-300 flex items-center group"
                  >
                    <TagIcon class="h-4 w-4 mr-1.5 text-blue-500 group-hover:scale-110 transition-transform duration-200" />
                    Category
                  </label>
                  <div class="relative">
                    <select
                      id="category"
                      v-model="formData.category"
                      class="flex h-11 w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2 text-sm ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400/30 dark:focus-visible:ring-blue-500/30 disabled:cursor-not-allowed disabled:opacity-50 transition-all duration-200 shadow-sm hover:shadow-sm focus:shadow-sm appearance-none pr-12"
                      @focus="handleInputFocus"
                      @blur="handleInputBlur"
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
                      class="absolute right-4 top-3.5 h-4 w-4 text-slate-500 dark:text-slate-400 pointer-events-none transition-transform duration-200 group-hover:scale-110"
                    />
                  </div>
                </div>
              </Transition>              
              <!-- Help Type selector with premium styling -->
              <Transition
                appear
                enter-active-class="transition-all duration-500 ease-out"
                enter-from-class="opacity-0 transform translate-y-4"
                enter-to-class="opacity-100 transform translate-y-0"
                :style="{ 'transition-delay': '400ms' }"
              >
                <div class="space-y-3">
                  <label
                    class="text-sm font-medium text-slate-700 dark:text-slate-300 flex items-center group"
                  >
                    <HelpCircle class="h-4 w-4 mr-1.5 text-blue-500 group-hover:scale-110 transition-transform duration-200" />
                    Help Type
                  </label>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-2">
                    <div
                      @click="formData.payment_option = 'free'"
                      :class="[
                        'flex items-center space-x-3 px-5 py-4 rounded-xl border cursor-pointer transition-all duration-300 hover:scale-105 active:scale-95',
                        formData.payment_option === 'free'
                          ? 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700 ring-2 ring-blue-400/30 dark:ring-blue-600/30 shadow-sm scale-105'
                          : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/50 hover:border-blue-300 dark:hover:border-blue-600 shadow-sm hover:shadow-sm',
                      ]"
                    >                      
                    <input
                        type="radio"
                        id="free"
                        value="free"
                        v-model="formData.payment_option"
                        class="h-5 w-5 border-blue-500 text-blue-600 focus:ring-blue-500 transition-all duration-200"
                      />
                      <label
                        for="free"
                        class="text-sm cursor-pointer text-slate-700 dark:text-slate-300 font-medium select-none"
                        >I need help for free</label
                      >
                    </div>
                    <div
                      @click="formData.payment_option = 'paid'"
                      :class="[
                        'flex items-center space-x-3 px-5 py-4 rounded-xl border cursor-pointer transition-all duration-300 hover:scale-105 active:scale-95',
                        formData.payment_option === 'paid'
                          ? 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-900/30 ring-2 ring-emerald-400/30 dark:ring-emerald-700/30 shadow-sm scale-105'
                          : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/50 hover:border-emerald-300 dark:hover:border-emerald-600 shadow-sm hover:shadow-sm',
                      ]"
                    >
                      <input
                        type="radio"
                        id="paid"
                        value="paid"
                        v-model="formData.payment_option"
                        class="h-5 w-5 border-emerald-500 text-emerald-600 focus:ring-emerald-500 transition-all duration-200"
                      />
                      <label
                        for="paid"
                        class="text-sm cursor-pointer text-slate-700 dark:text-slate-300 font-medium select-none"
                        >I can pay for help</label
                      >
                    </div>
                  </div>
                </div>
              </Transition>              
              <!-- Payment amount with premium styling -->
              <Transition
                enter-active-class="transition-all duration-400 ease-out"
                enter-from-class="opacity-0 transform translate-y-4 scale-95"
                enter-to-class="opacity-100 transform translate-y-0 scale-100"
                leave-active-class="transition-all duration-200 ease-in"
                leave-from-class="opacity-100 transform translate-y-0 scale-100"
                leave-to-class="opacity-0 transform translate-y-4 scale-95"
              >
                <div v-if="formData.payment_option === 'paid'" class="space-y-2">
                  <label
                    for="paymentAmount"
                    class="text-sm font-medium text-slate-700 dark:text-slate-300 flex items-center group"
                  >
                    <DollarSign class="h-4 w-4 mr-1.5 text-emerald-500 group-hover:scale-110 transition-transform duration-200" />
                    Payment Amount
                  </label>
                  <div class="relative">
                    <span
                      class="absolute left-4 top-3 text-emerald-600 dark:text-emerald-400 font-semibold"
                      >৳</span
                    >
                    <input
                      id="paymentAmount"
                      v-model="formData.payment_amount"
                      type="number"
                      placeholder="Enter amount"
                      class="flex h-11 w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 pl-8 pr-4 py-2 text-sm ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-emerald-400 dark:focus:border-emerald-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-400/30 dark:focus-visible:ring-emerald-500/30 disabled:cursor-not-allowed disabled:opacity-50 transition-all duration-200 shadow-sm hover:shadow-sm focus:shadow-sm"
                      @focus="handleInputFocus"
                      @blur="handleInputBlur"
                    />
                  </div>
                </div>
              </Transition>
            </div>
            
            <!-- Action buttons with premium styling -->
            <div
              class="flex justify-end gap-4 p-6 border-t border-slate-100 dark:border-slate-700 bg-gradient-to-r from-slate-50 to-white dark:from-slate-800/50 dark:to-slate-800/80"
            >
              <button
                @click="$emit('update:modelValue', false)"
                class="inline-flex items-center justify-center rounded-xl text-sm font-medium ring-offset-background transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 h-11 px-6 py-2 shadow-sm hover:shadow-sm active:scale-95 hover:scale-105"
              >
                Cancel
              </button>
              <button
                @click="handleSubmit"
                :disabled="!isFormValid || isSubmitting"
                :class="[
                  'inline-flex items-center justify-center rounded-xl text-sm font-medium ring-offset-background transition-all duration-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-11 px-8 py-2 shadow-sm hover:shadow-sm transform active:scale-95',
                  isFormValid && !isSubmitting
                    ? 'bg-gradient-to-r from-blue-500 via-blue-600 to-violet-600 hover:from-blue-600 hover:via-blue-700 hover:to-violet-700 text-white hover:scale-105 hover:-translate-y-0.5'
                    : 'bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400 cursor-not-allowed',
                ]"
              >
                <span v-if="isSubmitting" class="flex items-center">
                  <svg
                    class="animate-spin -ml-1 mr-2 h-5 w-5 text-white"
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
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 012 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>                  </svg>
                  Posting...
                </span>                
                <span v-else class="flex items-center">
                  <Send class="h-4 w-4 mr-2" />
                  Post Problem                </span>              
              </button>
            </div>
              </div>
            </div>
          </Transition>
        </div>
      </div>
    </Transition>
  </Teleport>
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
  formRefresh: {
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

defineExpose({
  resetFormData,
});

function resetFormData() {
  formData.value = {
    title: "",
    description: "",
    category: "",
    payment_option: "free",
    payment_amount: "",
    images: [],
  };
  isCompressing.value = false;
}

const emit = defineEmits(["update:modelValue", "submit"]);

// Create a local reactive form data object that is initialized from props
const formData = ref({ ...props.initialFormData });
const isCompressing = ref(false);

// Computed property to check if form is valid
const isFormValid = computed(() => {
  return (
    formData.value.title.trim() &&
    formData.value.description.trim() &&
    formData.value.category
  );
});

// Image compression utility function
const compressImage = (file, quality = 0.8, maxWidth = 1200, maxHeight = 1200) => {
  return new Promise((resolve, reject) => {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();
    
    img.onload = () => {
      // Calculate new dimensions while maintaining aspect ratio
      let { width, height } = img;
      
      if (width > height) {
        if (width > maxWidth) {
          height = (height * maxWidth) / width;
          width = maxWidth;
        }
      } else {
        if (height > maxHeight) {
          width = (width * maxHeight) / height;
          height = maxHeight;
        }
      }
      
      // Set canvas dimensions
      canvas.width = width;
      canvas.height = height;
      
      // Enable image smoothing for better quality
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';
      
      // Draw and compress the image
      ctx.drawImage(img, 0, 0, width, height);
      
      // Convert to blob with specified quality
      canvas.toBlob(
        (blob) => {
          if (blob) {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
          } else {
            reject(new Error('Canvas to Blob conversion failed'));
          }
        },
        file.type.startsWith('image/') ? file.type : 'image/jpeg',
        quality
      );
    };
    
    img.onerror = reject;
    img.src = URL.createObjectURL(file);
  });
};

// Handle photo upload with compression
const handlePhotoUpload = async (event) => {
  const files = Array.from(event.target.files);
  if (!files.length) return;

  const file = files[0];
  
  // Check file type
  if (!file.type.startsWith('image/')) {
    console.error('Please select a valid image file');
    return;
  }
  
  // Check file size (limit to 10MB before compression)
  if (file.size > 10 * 1024 * 1024) {
    console.error('File size too large. Please select an image under 10MB');
    return;
  }
  
  try {
    isCompressing.value = true;
    // Compress the image with high quality settings
    const compressedDataUrl = await compressImage(file, 0.85, 1200, 1200);
    formData.value.images.push(compressedDataUrl);
  } catch (error) {
    console.error('Error compressing image:', error);
    // Fallback to original file if compression fails
    const reader = new FileReader();
    reader.onload = () => {
      formData.value.images.push(reader.result);
    };
    reader.onerror = (error) => console.error("Error reading file:", error);
    reader.readAsDataURL(file);
  } finally {
    isCompressing.value = false;
  }
  
  // Clear the input for re-upload of same file
  event.target.value = '';
};

// Smooth interaction handlers for professional UX
const handleInputFocus = (event) => {
  event.target.style.transform = 'scale(1.02)';
  event.target.style.transition = 'transform 0.2s ease-out';
};

const handleInputBlur = (event) => {
  event.target.style.transform = 'scale(1)';
  event.target.style.transition = 'transform 0.2s ease-out';
};

// Enhanced photo removal with smooth animation
const removePhoto = (index) => {
  // Add a slight scale animation before removal
  const photoElement = document.querySelector(`[data-photo-index="${index}"]`);
  if (photoElement) {
    photoElement.style.transform = 'scale(0.8)';
    photoElement.style.opacity = '0.5';
    setTimeout(() => {
      formData.value.images.splice(index, 1);
    }, 150);
  } else {
    formData.value.images.splice(index, 1);
  }
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

/* Enhanced smooth scrolling for professional experience */
.smooth-scroll {
  scroll-behavior: smooth;
  scroll-padding-top: 2rem;
}

/* Advanced hover effects and micro-interactions */
.group:hover .group-hover\:scale-110 {
  transform: scale(1.1);
}

/* Enhanced focus states for accessibility */
*:focus-visible {
  outline: 2px solid rgb(59 130 246 / 0.5);
  outline-offset: 2px;
  border-radius: 0.375rem;
}

/* Smooth state transitions */
* {
  transition-property: transform, opacity, box-shadow, background-color, border-color;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}

/* Professional button hover effects */
button:hover {
  transform: translateY(-1px);
}

button:active {
  transform: translateY(0);
}

/* Enhanced loading states */
@keyframes pulse-soft {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.animate-pulse-soft {
  animation: pulse-soft 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Smooth modal animations */
@keyframes modal-enter {
  0% {
    opacity: 0;
    transform: scale(0.95) translateY(10px);
  }
  100% {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

@keyframes backdrop-enter {
  0% {
    opacity: 0;
    backdrop-filter: blur(0px);
  }
  100% {
    opacity: 1;
    backdrop-filter: blur(4px);
  }
}

/* Enhanced card hover effects */
.card-hover:hover {
  transform: translateY(-2px);
  box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 10px 10px -5px rgb(0 0 0 / 0.04);
}

/* Professional input animations */
input:focus, textarea:focus, select:focus {
  transform: scale(1.01);
  box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -2px rgb(0 0 0 / 0.05);
}

/* Smooth photo grid animations */
.photo-grid-item {
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.photo-grid-item:hover {
  transform: scale(1.05) rotate(1deg);
}

/* Enhanced button gradient animations */
@keyframes gradient-shift {
  0%, 100% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
}

.gradient-animate {
  background-size: 200% 200%;
  animation: gradient-shift 3s ease infinite;
}

/* Professional loading spinner */
@keyframes spin-smooth {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.animate-spin-smooth {
  animation: spin-smooth 1s linear infinite;
}

/* Enhanced text selection */
::selection {
  background-color: rgb(59 130 246 / 0.3);
  color: inherit;
}

/* Smooth page transitions */
.page-transition-enter-active,
.page-transition-leave-active {
  transition: all 0.3s ease-out;
}

.page-transition-enter-from {
  opacity: 0;
  transform: translateX(10px);
}

.page-transition-leave-to {
  opacity: 0;
  transform: translateX(-10px);
}

/* Professional form validation states */
.form-input-valid {
  border-color: rgb(34 197 94);
  box-shadow: 0 0 0 1px rgb(34 197 94 / 0.3);
}

.form-input-invalid {
  border-color: rgb(239 68 68);
  box-shadow: 0 0 0 1px rgb(239 68 68 / 0.3);
  animation: shake 0.5s ease-in-out;
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-4px); }
  75% { transform: translateX(4px); }
}
</style>
