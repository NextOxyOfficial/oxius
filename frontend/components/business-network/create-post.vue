<template>
  <div>
    <!-- Create Post Button -->
    <button
      class="fixed bottom-24 right-4 lg:right-[22%] md:bottom-4 rounded-full h-14 w-14 shadow-lg bg-gradient-to-r from-blue-600 to-indigo-700 hover:from-blue-700 hover:to-indigo-800 transition-all duration-300 hover:scale-105 border-none z-40 flex items-center justify-center text-white"
      @click="openCreatePostModal"
    >
      <Plus class="h-6 w-6" />
    </button>

    <!-- Create Post Modal -->
    <Teleport to="body">
      <div
        v-if="isCreatePostOpen"
        class="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 transition-opacity duration-300"
        @click="closeModalWithConfirm"
      >
        <div
          class="bg-white dark:bg-gray-800 rounded-xl max-w-lg w-full max-h-[90vh] overflow-hidden shadow-2xl transform transition-all duration-300 scale-100 opacity-100"
          @click.stop
        >
          <!-- Modal Header -->
          <div
            class="p-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between bg-gradient-to-r from-white to-gray-50 dark:from-gray-800 dark:to-gray-900"
          >
            <h2
              class="text-xl font-semibold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent"
            >
              Create Post
            </h2>
            <button
              class="rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 p-2 transition-colors"
              @click="closeModalWithConfirm"
            >
              <X class="h-5 w-5 text-gray-500 dark:text-gray-400" />
            </button>
          </div>

          <div class="p-4 overflow-y-auto max-h-[calc(90vh-130px)]">
            <div class="space-y-4">
              <!-- Form feedback alerts -->
              <div
                v-if="formError"
                class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800/30 rounded-lg p-3 text-red-700 dark:text-red-300 text-sm flex items-start"
              >
                <AlertCircle class="h-5 w-5 mr-2 flex-shrink-0 mt-0.5" />
                <div>{{ formError }}</div>
              </div>

              <!-- Title input with character count -->
              <div class="relative group">
                <label
                  class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >Post Title*</label
                >
                <div class="relative">
                  <input
                    type="text"
                    placeholder="Write a catchy title..."
                    class="w-full p-3 border border-gray-200 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-900 dark:text-white transition-all duration-200"
                    v-model="form.title"
                    maxlength="255"
                  />
                  <span class="absolute right-2 bottom-2 text-xs text-gray-400">
                    {{ form.title.length }}/255
                  </span>
                </div>
              </div>

              <!-- Content textarea with character count -->
              <div class="relative group">
                <label
                  class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >Post Content*</label
                >
                <div class="relative">
                  <CommonEditor
                    v-model="form.content"
                    @updateContent="updateContent"
                  />
                  <div
                    class="absolute right-2 bottom-2 text-xs text-gray-400 flex items-center gap-1"
                  >
                    <span>{{ form.content.length }}</span>
                    <span>characters</span>
                  </div>
                </div>
              </div>

              <!-- Quick actions toolbar -->
              <div
                class="flex items-center gap-2 pt-3 border-t border-gray-100 dark:border-gray-800"
              >
                <button
                  class="p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex items-center gap-1 text-sm text-gray-700 dark:text-gray-300"
                  title="Add Image or Video"
                  @click="triggerFileInput"
                >
                  <ImageIcon class="h-5 w-5 text-blue-500" />
                  <span>Media</span>
                </button>

                <div class="relative">
                  <button
                    class="p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex items-center gap-1 text-sm text-gray-700 dark:text-gray-300"
                    title="Add Emoji"
                    @click.stop="showEmojiPicker = !showEmojiPicker"
                  >
                    <Smile class="h-5 w-5 text-amber-500" />
                    <span>Emoji</span>
                  </button>

                  <!-- Emoji Picker -->
                  <div
                    v-if="showEmojiPicker"
                    class="absolute bottom-12 left-0 bg-white dark:bg-gray-900 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 p-2 z-50 w-64"
                    v-click-outside="() => (showEmojiPicker = false)"
                  >
                    <div class="grid grid-cols-8 gap-1">
                      <button
                        v-for="(emoji, index) in commonEmojis"
                        :key="index"
                        class="w-7 h-7 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-800 rounded text-lg"
                        @click="handleEmojiClick(emoji)"
                      >
                        {{ emoji }}
                      </button>
                    </div>
                  </div>
                </div>

                <div class="relative">
                  <button
                    class="p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex items-center gap-1 text-sm text-gray-700 dark:text-gray-300"
                    title="Add Hashtag"
                    @click.stop="focusHashtagInput"
                  >
                    <Hash class="h-5 w-5 text-green-500" />
                    <span>Hashtags</span>
                  </button>
                </div>
              </div>

              <!-- Media preview -->
              <div v-if="images.length > 0" class="space-y-3">
                <h4
                  class="text-sm font-medium text-gray-700 dark:text-gray-300 flex items-center justify-between"
                >
                  <span>Selected Media ({{ images.length }})</span>
                  <span class="text-xs text-gray-500">
                    {{ images.length }}/12 images,
                  </span>
                </h4>

                <div class="grid grid-cols-3 sm:grid-cols-4 gap-2">
                  <div
                    v-for="(img, index) in images"
                    :key="index"
                    class="relative aspect-square bg-gray-100 dark:bg-gray-800 rounded-md overflow-hidden group transition-all duration-200"
                  >
                    <img
                      v-if="img.image"
                      :src="img.data"
                      :alt="`Selected media ${index + 1}`"
                      class="object-cover w-full h-full"
                    />
                    <img
                      v-else
                      :src="img"
                      :alt="`Selected media ${index + 1}`"
                      class="object-cover w-full h-full"
                    />
                    <!-- <div
                      v-else-if="file.type.startsWith('video/')"
                      class="flex items-center justify-center h-full bg-gray-800"
                    >
                      <video
                        :src="getFilePreview(file)"
                        class="h-full w-full object-contain"
                      ></video>
                      <div
                        class="absolute inset-0 flex items-center justify-center"
                      >
                        <div class="bg-black/50 rounded-full p-2">
                          <Film class="h-5 w-5 text-white" />
                        </div>
                      </div>
                    </div> -->
                    <button
                      class="absolute top-1 right-1 bg-black/50 hover:bg-black/70 rounded-full p-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
                      @click.stop="removeMedia(index)"
                    >
                      <X class="h-3 w-3 text-white" />
                    </button>

                    <!-- File size indicator -->
                    <!-- <div
                      class="absolute bottom-1 left-1 bg-black/50 px-1.5 py-0.5 rounded text-xs text-white"
                    >
                      {{ formatFileSize(img.size) }}
                    </div> -->
                  </div>

                  <!-- Add more media button -->
                  <button
                    v-if="canAddMoreMedia"
                    @click.stop="triggerFileInput"
                    class="aspect-square border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-md flex flex-col items-center justify-center hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                  >
                    <Plus class="h-6 w-6 text-gray-400" />
                    <span class="text-xs text-gray-500">Add More</span>
                  </button>
                </div>
              </div>

              <!-- Hashtags section -->
              <div class="space-y-2">
                <h4
                  class="text-sm font-medium text-gray-700 dark:text-gray-300"
                >
                  Hashtags (Optional)
                </h4>

                <!-- Tags display -->
                <div
                  v-if="createPostCategories.length > 0"
                  class="flex flex-wrap gap-2 mb-3"
                >
                  <span
                    v-for="category in createPostCategories"
                    :key="category"
                    class="px-2 py-1 group bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-sm rounded-full flex items-center transition-all hover:bg-blue-100 dark:hover:bg-blue-900/50"
                  >
                    #{{ category }}
                    <button
                      @click="removeCategory(category)"
                      class="ml-1 rounded-full hover:bg-blue-200 dark:hover:bg-blue-800 p-0.5 transition-colors"
                    >
                      <X class="h-3 w-3" />
                    </button>
                  </span>
                </div>

                <div class="relative">
                  <div class="flex gap-2">
                    <div class="relative flex-1">
                      <input
                        type="text"
                        ref="hashtagInputRef"
                        placeholder="Add hashtags without # symbol..."
                        v-model="categoryInput"
                        class="pl-8 pr-4 py-2 w-full border border-gray-200 dark:border-gray-700 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 bg-white dark:bg-gray-900 dark:text-white"
                        @keydown.enter.prevent="addCategory"
                      />
                      <Hash
                        class="absolute left-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400"
                      />
                    </div>
                    <button
                      class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                      @click="addCategory"
                      :disabled="
                        !categoryInput.trim() ||
                        createPostCategories.includes(categoryInput.trim())
                      "
                    >
                      Add
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer with action buttons -->
          <div
            class="p-4 border-t border-gray-200 dark:border-gray-700 flex justify-end bg-gradient-to-r from-gray-50 to-white dark:from-gray-900 dark:to-gray-800"
          >
            <button
              class="px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-md mr-2 hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 transition-colors"
              @click="closeModalWithConfirm"
            >
              Cancel
            </button>
            <button
              :disabled="
                !form.title.trim() || !form.content.trim() || isSubmitting
              "
              @click="handleCreatePost"
              :class="[
                'px-4 py-2 rounded-md text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 transition-all duration-300 flex items-center gap-2',
                (isSubmitting || !form.title.trim() || !form.content.trim()) &&
                  'opacity-80 cursor-not-allowed',
              ]"
            >
              <Loader2 v-if="isSubmitting" class="h-4 w-4 animate-spin" />
              {{ isSubmitting ? "Posting..." : "Post" }}
            </button>
          </div>

          <!-- Hidden file input -->
          <input
            type="file"
            ref="fileInputRef"
            class="hidden"
            multiple
            accept="image/*,video/*"
            @change="handleFileUpload"
          />
        </div>
      </div>
    </Teleport>

    <!-- Confirmation Modal -->
    <Teleport to="body">
      <div
        v-if="showConfirmClose"
        class="fixed inset-0 z-[10000] bg-black/70 backdrop-blur-sm flex items-center justify-center p-4"
        @click="showConfirmClose = false"
      >
        <div
          class="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full p-6 shadow-2xl"
          @click.stop
        >
          <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
            Discard changes?
          </h3>
          <p class="text-gray-600 dark:text-gray-300 mb-6">
            You have unsaved changes. Are you sure you want to discard your
            post?
          </p>
          <div class="flex justify-end gap-3">
            <button
              class="px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-md hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 transition-colors"
              @click="showConfirmClose = false"
            >
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md transition-colors"
              @click="discardChanges"
            >
              Discard
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import {
  Plus,
  X,
  Smile,
  ImageIcon,
  Paperclip,
  Hash,
  Tag,
  Film,
  Loader2,
  AlertCircle,
} from "lucide-vue-next";

// Auth and API
const { post } = useApi();

const form = ref({
  title: "",
  content: "",
});

const images = ref([]);
// Refs
const isCreatePostOpen = ref(false);
const createPostTitle = ref("");
const createPostContent = ref("");
const createPostCategories = ref([]);
const categoryInput = ref("");
const showEmojiPicker = ref(false);
const selectedMedia = ref([]);
const fileInputRef = ref(null);
const hashtagInputRef = ref(null);
const isSubmitting = ref(false);
const formError = ref("");
const showConfirmClose = ref(false);
const uploadError = ref("");
const isUploading = ref(false);

// Common emojis for quick access
const commonEmojis = [
  "😀",
  "😃",
  "😄",
  "😁",
  "😆",
  "😅",
  "🤣",
  "😂",
  "🙂",
  "🙃",
  "😉",
  "😊",
  "😇",
  "🥰",
  "😍",
  "🤩",
  "😘",
  "😗",
  "😚",
  "😙",
  "👍",
  "👎",
  "👏",
  "🙌",
  "🤝",
  "👊",
  "✌️",
  "🤞",
  "🤟",
  "🤘",
  "❤️",
  "🧡",
  "💛",
  "💚",
  "💙",
  "💜",
  "🖤",
  "💔",
  "❣️",
  "💕",
];

// Computed properties for media validation
const imageCount = computed(
  () =>
    selectedMedia.value.filter((file) => file.type.startsWith("image/")).length
);

const videoCount = computed(
  () =>
    selectedMedia.value.filter((file) => file.type.startsWith("video/")).length
);

const canAddMoreMedia = computed(
  () => imageCount.value < 12 || videoCount.value < 2
);

const hasUnsavedChanges = computed(
  () =>
    createPostTitle.value.trim() ||
    createPostContent.value.trim() ||
    selectedMedia.value.length > 0 ||
    createPostCategories.value.length > 0
);

// Methods
const openCreatePostModal = () => {
  isCreatePostOpen.value = true;
};

const closeModalWithConfirm = () => {
  if (hasUnsavedChanges.value) {
    showConfirmClose.value = true;
  } else {
    isCreatePostOpen.value = false;
  }
};

const discardChanges = () => {
  showConfirmClose.value = false;
  isCreatePostOpen.value = false;
  resetForm();
};

const resetForm = () => {
  createPostTitle.value = "";
  createPostContent.value = "";
  selectedMedia.value = [];
  createPostCategories.value = [];
  categoryInput.value = "";
  formError.value = "";
};

const triggerFileInput = () => {
  fileInputRef.value?.click();
};

const focusHashtagInput = () => {
  nextTick(() => {
    hashtagInputRef.value?.focus();
  });
};

const formatFileSize = (bytes) => {
  if (bytes < 1024) return bytes + " B";
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
  return (bytes / 1048576).toFixed(1) + " MB";
};

const removeMedia = (index) => {
  images.value = images.value.filter((_, i) => i !== index);
};

const handleEmojiClick = (emoji) => {
  createPostContent.value += emoji;
  showEmojiPicker.value = false;
};

const addCategory = () => {
  if (!categoryInput.value.trim()) return;

  // Remove hashtag symbol if user entered it
  let category = categoryInput.value.trim();
  if (category.startsWith("#")) {
    category = category.substring(1);
  }

  // Don't add duplicate tags
  if (!createPostCategories.value.includes(category)) {
    createPostCategories.value.push(category);
  }

  categoryInput.value = "";
};

const removeCategory = (category) => {
  createPostCategories.value = createPostCategories.value.filter(
    (c) => c !== category
  );
};

function updateContent(p) {
  form.value.content = p;
}

async function handleCreatePost() {
  isSubmitting.value = true;
  try {
    const { data } = await post("/bn/posts/", {
      ...form.value,
      images: images.value,
      tags: createPostCategories.value,
    });
    if (data) {
      form.value = {
        title: "",
        content: "",
      };
      images.value = [];
    }
  } catch (error) {
    console.error("Error creating post:", error);
  } finally {
    isSubmitting.value = false;
  }
}

function handleFileUpload(event) {
  isUploading.value = true;
  uploadError.value = "";

  try {
    const files = Array.from(event.target.files);

    if (!files || files.length === 0) {
      uploadError.value = "No file selected";
      isUploading.value = false;
      return;
    }

    const file = files[0];

    if (!file.type.startsWith("image/")) {
      uploadError.value = "Please select a valid image file";
      isUploading.value = false;
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      uploadError.value = "Image size must be less than 5MB";
      isUploading.value = false;
      return;
    }

    if (!images.value) {
      images.value = [];
    }

    if (images.value.length >= 12) {
      uploadError.value = "Maximum 12 images allowed";
      isUploading.value = false;
      return;
    }

    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement("canvas");
        let width = img.width;
        let height = img.height;

        // Resize while maintaining aspect ratio
        const maxSize = 1000;
        if (width > maxSize || height > maxSize) {
          if (width > height) {
            height = height * (maxSize / width);
            width = maxSize;
          } else {
            width = width * (maxSize / height);
            height = maxSize;
          }
        }

        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, width, height);

        const compressedDataUrl = canvas.toDataURL("image/jpeg", 0.8); // 80% quality

        images.value.push(compressedDataUrl);
        isUploading.value = false;

        if (event.target) {
          event.target.value = null;
        }
      };

      img.onerror = () => {
        uploadError.value = "Invalid image. Please try again.";
        isUploading.value = false;
      };

      img.src = e.target.result;
    };

    reader.onerror = (error) => {
      console.error("FileReader error:", error);
      uploadError.value = "Error uploading image. Please try again.";
      isUploading.value = false;
    };

    reader.readAsDataURL(file);
  } catch (error) {
    console.error("File upload error:", error);
    uploadError.value = "Unexpected error occurred during upload";
    isUploading.value = false;
  }
}

// Click outside directive
const vClickOutside = {
  beforeMount(el, binding) {
    el.clickOutsideEvent = (event) => {
      if (!(el === event.target || el.contains(event.target))) {
        binding.value(event);
      }
    };
    document.addEventListener("click", el.clickOutsideEvent);
  },
  unmounted(el) {
    document.removeEventListener("click", el.clickOutsideEvent);
  },
};

// Lifecycle hooks
onMounted(() => {
  // Close emoji picker when clicking outside
  document.addEventListener("click", (event) => {
    const emojiTrigger = event.target.closest(".emoji-trigger");
    const emojiPicker = event.target.closest(".emoji-picker");
    if (!emojiTrigger && !emojiPicker && showEmojiPicker.value) {
      showEmojiPicker.value = false;
    }
  });
});
</script>

<style scoped>
/* Cool animations */
@keyframes slideIn {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.emoji-picker {
  animation: slideIn 0.2s ease-out;
}

/* Smooth transitions */
input,
textarea,
button {
  transition: all 0.2s ease-in-out;
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.05);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 10px;
}
</style>
