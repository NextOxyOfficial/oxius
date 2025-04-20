<template>
    <div 
      class="fixed inset-0 z-[9999] bg-black/50 backdrop-blur-sm flex items-center justify-center p-4"
      @click="$emit('close')"
    >
      <div 
        class="bg-white rounded-xl max-w-lg w-full max-h-[90vh] overflow-hidden shadow-2xl transform transition-all duration-300 scale-100 opacity-100"
        @click.stop
      >
        <div class="p-4 border-b border-gray-100 flex items-center justify-between bg-gradient-to-r from-white to-gray-50">
          <h2 class="text-xl font-semibold bg-gradient-to-r from-blue-500 to-blue-600 bg-clip-text text-transparent">
            Create Post
          </h2>
          <button class="rounded-full hover:bg-gray-100 p-2" @click="$emit('close')">
            <XIcon class="h-5 w-5" />
          </button>
        </div>
  
        <div class="p-4 overflow-y-auto max-h-[calc(90vh-130px)]">
          <div class="space-y-4">
            <!-- Title input -->
            <div class="relative group">
              <input
                ref="titleInput"
                type="text"
                placeholder="Post title"
                class="w-full p-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-transparent bg-gray-50 transition-all duration-200 group-hover:bg-white"
                v-model="postForm.title"
              />
              <div class="absolute bottom-0 left-0 w-0 h-0.5 bg-blue-500 transition-all duration-300 group-hover:w-full"></div>
            </div>
  
            <!-- Content textarea -->
            <div class="relative group">
              <textarea
                ref="contentTextarea"
                placeholder="What's on your mind?"
                class="min-h-[180px] w-full resize-none border border-gray-200 rounded-lg p-2 bg-gray-50 transition-all duration-200 group-hover:bg-white focus:bg-white focus:outline-none focus:ring-1 focus:ring-blue-500"
                v-model="postForm.content"
                @select="handleTextareaSelect"
                @click="handleTextareaSelect"
              ></textarea>
              <div class="absolute bottom-0 left-0 w-0 h-0.5 bg-blue-500 transition-all duration-300 group-hover:w-full"></div>
            </div>
  
            <!-- Quick actions -->
            <div class="flex items-center gap-2 pt-2 border-t border-gray-100">
              <button
                class="p-2 rounded-full hover:bg-gray-100 transition-colors"
                title="Add Image"
                @click="triggerFileInput"
              >
                <ImageIcon class="h-5 w-5 text-gray-500" />
              </button>
  
              <div class="relative">
                <button
                  class="p-2 rounded-full hover:bg-gray-100 transition-colors emoji-trigger"
                  title="Add Emoji"
                  @click.stop="toggleEmojiPicker"
                >
                  <SmileIcon class="h-5 w-5 text-gray-500" />
                </button>
  
                <div
                  v-if="showEmojiPicker"
                  class="absolute bottom-12 left-0 bg-white rounded-lg shadow-lg border border-gray-200 p-2 z-50 w-64"
                  @click.stop
                >
                  <div class="grid grid-cols-8 gap-1">
                    <button
                      v-for="(emoji, index) in commonEmojis"
                      :key="index"
                      class="w-7 h-7 flex items-center justify-center hover:bg-gray-100 rounded text-lg"
                      @click="handleEmojiClick(emoji)"
                    >
                      {{ emoji }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
  
            <!-- Media preview -->
            <div v-if="selectedMedia.length > 0" class="space-y-3">
              <div class="grid grid-cols-4 gap-2">
                <div
                  v-for="(file, index) in selectedMedia"
                  :key="index"
                  class="relative aspect-square bg-gray-100 rounded-md overflow-hidden group hover:shadow-md transition-all duration-200"
                >
                  <img
                    v-if="file.type.startsWith('image/')"
                    :src="getFilePreview(file)"
                    :alt="`Selected media ${index}`"
                    class="h-full w-full object-cover"
                  />
                  <div v-else class="flex items-center justify-center h-full">
                    <video :src="getFilePreview(file)" class="h-full w-full object-cover"></video>
                  </div>
                  <button
                    class="absolute top-1 right-1 bg-black/50 rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
                    @click.stop="removeMedia(index)"
                  >
                    <XIcon class="h-3 w-3 text-white" />
                  </button>
                </div>
              </div>
  
              <div class="flex items-center justify-between">
                <button
                  class="text-xs border border-gray-200 rounded-md px-3 py-1.5 flex items-center gap-1 hover:bg-gray-50"
                  @click.stop="triggerFileInput"
                  :disabled="selectedMedia.length >= 14"
                >
                  <PaperclipIcon class="h-3 w-3" />
                  Add More
                </button>
                <div class="text-xs text-gray-500">
                  {{ selectedMedia.filter(f => f.type.startsWith('image/')).length }}/12 images,
                  {{ selectedMedia.filter(f => f.type.startsWith('video/')).length }}/2 videos
                </div>
              </div>
            </div>
  
            <!-- Categories section -->
            <div class="space-y-3">
              <h4 class="text-sm font-medium text-gray-700">Categories</h4>
              <div class="flex flex-wrap gap-2">
                <div 
                  v-for="category in postForm.categories" 
                  :key="category"
                  class="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded-full flex items-center gap-1 group"
                >
                  {{ category }}
                  <button
                    @click="removeCategory(category)"
                    class="ml-1 rounded-full hover:bg-gray-200 p-0.5 transition-colors"
                  >
                    <XIcon class="h-3 w-3 text-gray-500 group-hover:text-gray-700" />
                  </button>
                </div>
              </div>
  
              <div class="relative">
                <div class="flex gap-2">
                  <div class="relative flex-1">
                    <input
                      type="text"
                      placeholder="Add a category..."
                      v-model="categoryInput"
                      class="pl-8 pr-4 py-2 w-full border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500"
                    />
                    <TagIcon class="absolute left-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                  </div>
                  <button
                    class="px-3 py-1 bg-blue-500 text-white rounded-md hover:bg-blue-600 text-sm"
                    @click="addCategory"
                    :disabled="!categoryInput.trim() || postForm.categories.includes(categoryInput.trim())"
                  >
                    Add
                  </button>
                  <button
                    class="p-2 border border-gray-200 rounded-md hover:bg-gray-50"
                    @click.stop="toggleCategoryBrowser"
                  >
                    <SearchIcon class="h-4 w-4" />
                  </button>
                </div>
  
                <!-- Category browser -->
                <div
                  v-if="showCategoryBrowser"
                  class="absolute left-0 top-full mt-1 w-full bg-white rounded-lg shadow-lg border border-gray-200 z-50 max-h-48 overflow-y-auto"
                  @click.stop
                >
                  <div v-if="filteredCategories.length > 0" class="p-1">
                    <div
                      v-for="category in filteredCategories"
                      :key="category"
                      class="flex items-center justify-between p-2 hover:bg-gray-50 rounded-md cursor-pointer"
                      @click="selectCategory(category)"
                    >
                      <span class="text-sm">{{ category }}</span>
                      <PlusIcon class="h-4 w-4 text-gray-400" />
                    </div>
                  </div>
                  <div v-else class="p-3 text-center text-gray-500 text-sm">
                    {{ categoryInput.trim()
                      ? "No matching categories found"
                      : "Type to search or select from available categories" }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
  
        <div class="p-4 border-t border-gray-100 flex justify-end bg-gradient-to-r from-gray-50 to-white">
          <button 
            class="px-4 py-2 border border-gray-200 rounded-md mr-2 hover:bg-gray-50"
            @click="$emit('close')"
          >
            Cancel
          </button>
          <button
            :disabled="!postForm.title.trim() || !postForm.content.trim() || isSubmitting"
            @click="submitPost"
            :class="[
              'px-4 py-2 rounded-md text-white bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-500/90 hover:to-blue-600/90 transition-all duration-300',
              (isSubmitting || !postForm.title.trim() || !postForm.content.trim()) && 'opacity-70 cursor-not-allowed'
            ]"
          >
            <span v-if="isSubmitting" class="flex items-center">
              <span class="mr-2 h-4 w-4 rounded-full border-2 border-white border-t-transparent animate-spin"></span>
              Posting...
            </span>
            <span v-else>Post</span>
          </button>
        </div>
  
        <input
          type="file"
          ref="fileInput"
          class="hidden"
          multiple
          accept="image/*,video/*"
          @change="handleFileChange"
        />
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, computed, onMounted, nextTick } from 'vue';
  import { 
    X as XIcon,
    Image as ImageIcon,
    Smile as SmileIcon,
    Paperclip as PaperclipIcon,
    Tag as TagIcon,
    Plus as PlusIcon,
    Search as SearchIcon
  } from 'lucide-vue-next';
  import { usePost } from '../../composables/usePost';
  
  const emit = defineEmits(['close', 'post-created']);
  const { createPost } = usePost();
  
  // Refs
  const titleInput = ref(null);
  const contentTextarea = ref(null);
  const fileInput = ref(null);
  
  // State
  const postForm = ref({
    title: '',
    content: '',
    categories: [],
  });
  const categoryInput = ref('');
  const selectedMedia = ref([]);
  const showEmojiPicker = ref(false);
  const showCategoryBrowser = ref(false);
  const cursorPosition = ref(0);
  const isSubmitting = ref(false);
  
  // Available categories
  const availableCategories = [
    "Marketing",
    "Finance",
    "Operations",
    "Leadership",
    "Technology",
    "HR",
    "Sales",
    "Strategy",
    "Innovation",
    "Management",
    "Entrepreneurship",
    "Digital Transformation",
    "Customer Experience",
    "Data Analytics",
    "Sustainability",
  ];
  
  // Common emojis for quick access
  const commonEmojis = [
    "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", 
    "👍", "👎", "👏", "🙌", "🤝", "👊", "✌️", "🤞", "🤟", "🤘", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "💔", "❣️", "💕", 
    "😢", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗", "🤔", "🤭", "🤫", "🤥"
  ];
  
  // Computed
  const filteredCategories = computed(() => {
    return availableCategories.filter(
      category => 
        !postForm.value.categories.includes(category) && 
        category.toLowerCase().includes(categoryInput.value.toLowerCase())
    );
  });
  
  // Methods
  const triggerFileInput = () => {
    fileInput.value?.click();
  };
  
  const handleFileChange = (e) => {
    const files = e.target.files;
    if (!files) return;
  
    const newFiles = Array.from(files);
  
    // Check file type and size constraints
    const validFiles = newFiles.filter(file => {
      const isImage = file.type.startsWith("image/");
      const isVideo = file.type.startsWith("video/");
  
      if (isImage && file.size > 5 * 1024 * 1024) {
        alert(`Image ${file.name} exceeds 5MB limit`);
        return false;
      }
  
      if (isVideo && file.size > 250 * 1024 * 1024) {
        alert(`Video ${file.name} exceeds 250MB limit`);
        return false;
      }
  
      return isImage || isVideo;
    });
  
    // Check total media count constraints
    const currentImages = selectedMedia.value.filter(file => file.type.startsWith("image/")).length;
    const currentVideos = selectedMedia.value.filter(file => file.type.startsWith("video/")).length;
  
    const newImages = validFiles.filter(file => file.type.startsWith("image/"));
    const newVideos = validFiles.filter(file => file.type.startsWith("video/"));
  
    if (currentImages + newImages.length > 12) {
      alert("Maximum 12 images allowed");
      return;
    }
  
    if (currentVideos + newVideos.length > 2) {
      alert("Maximum 2 videos allowed");
      return;
    }
  
    selectedMedia.value = [...selectedMedia.value, ...validFiles];
  };
  
  const getFilePreview = (file) => {
    return URL.createObjectURL(file);
  };
  
  const removeMedia = (index) => {
    selectedMedia.value = selectedMedia.value.filter((_, i) => i !== index);
  };
  
  const toggleEmojiPicker = () => {
    showEmojiPicker.value = !showEmojiPicker.value;
    if (showCategoryBrowser.value) {
      showCategoryBrowser.value = false;
    }
  };
  
  const handleEmojiClick = (emoji) => {
    if (contentTextarea.value) {
      const start = contentTextarea.value.selectionStart || cursorPosition.value;
      const end = contentTextarea.value.selectionEnd || cursorPosition.value;
  
      const newContent = postForm.value.content.substring(0, start) + emoji + postForm.value.content.substring(end);
      postForm.value.content = newContent;
  
      // Set cursor position after the inserted emoji
      const newPosition = start + emoji.length;
      cursorPosition.value = newPosition;
  
      // Focus back on textarea and set cursor position
      nextTick(() => {
        if (contentTextarea.value) {
          contentTextarea.value.focus();
          contentTextarea.value.selectionStart = newPosition;
          contentTextarea.value.selectionEnd = newPosition;
        }
      });
    }
  
    // Close emoji picker
    showEmojiPicker.value = false;
  };
  
  const handleTextareaSelect = () => {
    if (contentTextarea.value) {
      cursorPosition.value = contentTextarea.value.selectionStart || 0;
    }
  };
  
  const addCategory = () => {
    if (categoryInput.value.trim() && !postForm.value.categories.includes(categoryInput.value.trim())) {
      postForm.value.categories.push(categoryInput.value.trim());
      categoryInput.value = "";
    }
  };
  
  const removeCategory = (category) => {
    postForm.value.categories = postForm.value.categories.filter(c => c !== category);
  };
  
  const toggleCategoryBrowser = () => {
    showCategoryBrowser.value = !showCategoryBrowser.value;
    if (showEmojiPicker.value) {
      showEmojiPicker.value = false;
    }
  };
  
  const selectCategory = (category) => {
    if (!postForm.value.categories.includes(category)) {
      postForm.value.categories.push(category);
    }
    showCategoryBrowser.value = false;
  };
  
  const submitPost = async () => {
    if (!postForm.value.title.trim() || !postForm.value.content.trim()) return;
  
    isSubmitting.value = true;
  
    try {
      // Process media files
      const mediaFiles = await Promise.all(
        selectedMedia.value.map(async (file, index) => {
          // In a real app, you would upload the file to a server
          // and get back a URL. Here we're just using the local preview.
          return {
            id: `new-${Date.now()}-${index}`,
            type: file.type.startsWith('image/') ? 'image' : 'video',
            url: getFilePreview(file),
            thumbnail: getFilePreview(file)
          };
        })
      );
  
      // Create post data
      const postData = {
        title: postForm.value.title,
        content: postForm.value.content,
        categories: postForm.value.categories,
        media: mediaFiles
      };
  
      // Send to API
      const newPost = await createPost(postData);
      
      // Emit event to parent
      emit('post-created', newPost);
      
      // Close modal
      emit('close');
    } catch (error) {
      console.error('Error creating post:', error);
      alert('Failed to create post. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  };
  
  // Focus title input when modal opens
  onMounted(() => {
    nextTick(() => {
      titleInput.value?.focus();
    });
  });
  </script>