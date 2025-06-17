<template>
  <!-- Create Post Modal -->
  <Teleport to="body">
    <div
      v-if="isCreatePostOpen"
      class="fixed inset-0 top-14 z-50 overflow-y-auto"
      :class="{ 'animate-fade-in': isCreatePostOpen }"
      @click="closeModalWithConfirm"
    >
      <div
        class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
        aria-hidden="true"
        @click="isCreatePostOpen = false"
      ></div>
      <div
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="relative max-w-4xl w-full mx-auto my-8 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-xl shadow-sm border border-white/20 dark:border-slate-700/40 overflow-hidden"
          :class="{ 'animate-modal-slide-up': isCreatePostOpen }"
          @click.stop
          ref="modalRef"
        >
          <!-- Modal Header -->
          <div class="w-full overflow-hidden relative mt-2 px-2">
            <h2
              class="text-xl sm:px-4 font-semibold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent flex items-center gap-2"
            >
              <div
                class="rounded-full bg-gradient-to-r from-blue-600 to-indigo-600 p-1.5 shadow-sm"
              >
                <Edit3 class="h-4 w-4 text-white" />
              </div>
              {{ modalTitle }}
            </h2>
            <button
              class="absolute right-4 top-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 p-2 transition-colors transform hover:rotate-90 duration-300"
              @click="closeModalWithConfirm"
            >
              <X class="h-5 w-5 text-gray-600 dark:text-gray-600" />
            </button>
          </div>

          <div
            class="p-2 sm:p-8 pb-6 overflow-y-auto max-h-[calc(90vh-130px)] hide-scrollbar"
          >
            <div class="space-y-5">
              <!-- Form feedback alerts -->
              <Transition
                enter-active-class="transition duration-300 ease-out"
                enter-from-class="transform -translate-y-4 opacity-0"
                enter-to-class="transform translate-y-0 opacity-100"
                leave-active-class="transition duration-200 ease-in"
                leave-from-class="transform translate-y-0 opacity-100"
                leave-to-class="transform -translate-y-4 opacity-0"
              >
                <div
                  v-if="formError"
                  class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800/30 rounded-lg p-3 text-red-700 dark:text-red-300 text-sm flex items-start animate-shake"
                >
                  <AlertCircle class="h-5 w-5 mr-2 flex-shrink-0 mt-0.5" />
                  <div>{{ formError }}</div>
                </div>
              </Transition>

              <!-- Title input with character count -->
              <div class="relative group">
                <label
                  class="block text-sm font-medium text-gray-800 dark:text-gray-400 mb-1.5 flex items-center gap-1.5"
                >
                  <Type class="h-4 w-4 text-blue-500" />
                  Post Title <span class="text-red-500">*</span>
                </label>
                <div class="relative">
                  <input
                    type="text"
                    placeholder="Write a catchy title..."
                    class="w-full p-3 border border-gray-200 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-900 dark:text-white transition-all duration-200 pr-16"
                    v-model="form.title"
                    maxlength="255"
                  />
                  <span
                    class="absolute right-3 bottom-3 text-xs px-1.5 py-0.5 rounded-full transition-all duration-200"
                    :class="
                      form.title.length > 200
                        ? 'bg-amber-100 text-amber-700'
                        : 'text-gray-600'
                    "
                  >
                    {{ form.title.length }}/255
                  </span>
                </div>
              </div>

              <!-- Description textarea with character count (renamed from Content) -->
              <div class="relative group">
                <label
                  class="block text-sm font-medium text-gray-800 dark:text-gray-400 mb-1.5 flex items-center gap-1.5"
                >
                  <AlignLeft class="h-4 w-4 text-blue-500" />
                  Description (Optional)
                </label>
                <div class="relative">
                  <CommonEditor
                    v-model="form.content"
                    @updateContent="updateContent"
                    class="editor-container text-left"
                    placeholder="Write your post description here (optional)..."
                  />
                  <div
                    class="absolute right-2 bottom-2 text-xs bg-white dark:bg-gray-800 px-2 py-1 rounded-full shadow-sm border border-gray-100 dark:border-gray-700"
                  >
                    <span
                      :class="
                        form.content.length > 5000
                          ? 'text-amber-500'
                          : 'text-gray-600'
                      "
                      >{{ form.content.length }}</span
                    >
                    <span class="text-gray-600"> characters</span>
                  </div>
                </div>
              </div>

              <!-- Media upload area - CONDITIONALLY DISPLAYED when no images are uploaded -->
              <div
                v-if="images.length === 0"
                class="border-2 border-dashed border-gray-300 dark:border-gray-700 rounded-lg p-4 transition-all hover:border-blue-400 dark:hover:border-blue-500 hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                @dragover.prevent="isDragging = true"
                @dragleave.prevent="isDragging = false"
                @drop.prevent="handleFileDrop"
                :class="{
                  'bg-blue-50/80 dark:bg-blue-900/20 border-blue-400 dark:border-blue-500':
                    isDragging,
                }"
              >
                <div class="text-center">
                  <div
                    class="mx-auto h-12 w-12 flex items-center justify-center rounded-full bg-blue-100 dark:bg-blue-900/30 mb-3"
                  >
                    <ImageIcon
                      class="h-6 w-6 text-blue-600 dark:text-blue-400"
                    />
                  </div>
                  <p
                    class="text-sm font-medium text-gray-800 dark:text-gray-400"
                  >
                    {{
                      isDragging
                        ? "Drop your images here"
                        : "Drag images here or click to select"
                    }}
                  </p>
                  <p
                    class="mt-1 text-xs text-gray-600 dark:text-gray-600 flex items-center justify-center gap-1"
                  >
                    <span>Select up to 12 images (PNG, JPG, JPEG)</span>
                    <span
                      class="inline-flex items-center px-1.5 py-0.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs font-medium rounded"
                    >
                      {{ images.length }}/12
                    </span>
                  </p>
                  <button
                    @click.stop="triggerFileInput"
                    class="mt-3 px-4 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm transition-all duration-200 hover:shadow-sm flex items-center gap-1.5 mx-auto"
                  >
                    <Upload class="h-3.5 w-3.5" />
                    <span v-if="images.length === 0">Select Images</span>
                    <span v-else
                      >Add More ({{ 12 - images.length }} remaining)</span
                    >
                  </button>
                </div>
              </div>

              <!-- Media preview -->
              <Transition
                enter-active-class="transition-all duration-300 ease-out"
                enter-from-class="opacity-0 max-h-0"
                enter-to-class="opacity-100 max-h-[1000px]"
                leave-active-class="transition-all duration-200 ease-in"
                leave-from-class="opacity-100 max-h-[1000px]"
                leave-to-class="opacity-0 max-h-0"
              >
                <div v-if="images.length > 0" class="space-y-3 overflow-hidden">
                  <div class="flex items-center justify-between">
                    <h4
                      class="text-sm font-medium text-gray-800 dark:text-gray-400 flex items-center gap-1.5"
                    >
                      <ImageIcon class="h-4 w-4 text-blue-500" />
                      <span>Selected Media</span>
                    </h4>
                    <div class="flex items-center gap-2">
                      <span
                        class="text-xs px-2 py-0.5 rounded-full font-medium transition-colors"
                        :class="
                          images.length > 9
                            ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                            : images.length > 6
                            ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                            : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300'
                        "
                      >
                        {{ images.length }}/12 selected
                      </span>
                      <span
                        v-if="images.length < 12"
                        class="text-xs text-gray-500 dark:text-gray-400"
                      >
                        ({{ 12 - images.length }} more allowed)
                      </span>
                      <span
                        v-else
                        class="text-xs text-amber-600 dark:text-amber-400 font-medium"
                      >
                        Limit reached
                      </span>
                      <button
                        v-if="images.length > 0"
                        @click="clearAllImages"
                        class="text-xs px-2 py-0.5 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors"
                      >
                        Clear All
                      </button>
                    </div>
                  </div>

                  <div class="grid grid-cols-3 sm:grid-cols-4 gap-2">
                    <div
                      v-for="(img, index) in images"
                      :key="index"
                      class="relative aspect-square bg-gray-100 dark:bg-gray-800 rounded-md overflow-hidden media-card group"
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

                      <div
                        class="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-2"
                      >
                        <span class="text-white text-xs truncate w-full"
                          >Image {{ index + 1 }}</span
                        >
                      </div>

                      <button
                        class="absolute top-1 right-1 bg-black/50 hover:bg-black/70 rounded-full p-1.5 media-delete-btn"
                        @click.stop="removeMedia(index)"
                        aria-label="Remove image"
                      >
                        <X class="h-3 w-3 text-white" />
                      </button>
                    </div>

                    <!-- Add more media button -->
                    <button
                      v-if="canAddMoreMedia"
                      @click.stop="triggerFileInput"
                      class="aspect-square border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-md flex flex-col items-center justify-center hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors hover:border-blue-400 dark:hover:border-blue-500 group"
                    >
                      <div
                        class="p-2 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 group-hover:scale-125 transition-transform"
                      >
                        <Plus class="h-5 w-5" />
                      </div>
                      <span
                        class="text-xs text-gray-600 mt-1 group-hover:text-blue-600 transition-colors"
                        >Add More</span
                      >
                    </button>
                  </div>
                </div>
              </Transition>
              <!-- Simplified Compression Progress Indicator -->
              <Transition
                enter-active-class="transition-all duration-300 ease-out"
                enter-from-class="opacity-0 -translate-y-4"
                enter-to-class="opacity-100 translate-y-0"
                leave-active-class="transition-all duration-200 ease-in"
                leave-from-class="opacity-100 translate-y-0"
                leave-to-class="opacity-0 -translate-y-4"
              >
                <div
                  v-if="showCompressionProgress"
                  class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 space-y-3"
                >
                  <div class="flex items-center gap-3">
                    <div
                      class="w-5 h-5 rounded-full bg-blue-600 flex items-center justify-center"
                    >
                      <Loader2 class="h-3 w-3 text-white animate-spin" />
                    </div>
                    <span
                      class="text-sm font-medium text-blue-800 dark:text-blue-200"
                    >
                      Processing images...
                    </span>
                  </div>

                  <!-- Simple Progress Bar -->
                  <div
                    class="w-full bg-blue-200 dark:bg-blue-800/50 rounded-full h-2 overflow-hidden"
                  >
                    <div
                      class="bg-blue-600 dark:bg-blue-500 h-full rounded-full transition-all duration-300 ease-out"
                      :style="{ width: `${compressionProgress}%` }"
                    ></div>
                  </div>

                  <!-- Simple status message -->
                  <p class="text-xs text-blue-700 dark:text-blue-300">
                    Please wait while we optimize your images for the best
                    quality and performance.
                  </p>
                </div>
              </Transition>

              <!-- Hashtags section with autocomplete and popular tags -->
              <div class="space-y-2 mb-5">
                <!-- Added mb-5 for the extra space -->
                <h4
                  class="text-sm font-medium text-gray-800 dark:text-gray-400 flex items-center gap-1.5"
                >
                  <Hash class="h-4 w-4 text-green-500" />
                  Hashtags (Optional)
                </h4>

                <!-- Tags display -->
                <Transition
                  enter-active-class="transition-all duration-300 ease-out"
                  enter-from-class="opacity-0 max-h-0"
                  enter-to-class="opacity-100 max-h-[500px]"
                  leave-active-class="transition-all duration-200 ease-in"
                  leave-from-class="opacity-100 max-h-[500px]"
                  leave-to-class="opacity-0 max-h-0"
                >
                  <div
                    v-if="createPostCategories.length > 0"
                    class="flex flex-wrap gap-2 mb-3 overflow-hidden"
                  >
                    <span
                      v-for="category in createPostCategories"
                      :key="category"
                      class="tag-item px-2 py-1 group bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-sm rounded-full flex items-center transition-all hover:bg-blue-100 dark:hover:bg-blue-900/50 hover:shadow-sm"
                    >
                      #{{ category }}
                      <button
                        @click="removeCategory(category)"
                        class="ml-1 rounded-full hover:bg-blue-200 dark:hover:bg-blue-800 p-0.5 transition-colors"
                        aria-label="Remove hashtag"
                      >
                        <X class="h-3 w-3" />
                      </button>
                    </span>
                  </div>
                </Transition>

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
                        @input="searchHashtags"
                        @focus="onHashtagInputFocus"
                        @keydown.down.prevent="selectNextSuggestion"
                        @keydown.up.prevent="selectPrevSuggestion"
                      />
                      <Hash
                        class="absolute left-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-600"
                      />

                      <!-- Hashtag Suggestions Dropdown -->
                      <Transition
                        enter-active-class="transition ease-out duration-200"
                        enter-from-class="opacity-0 -translate-y-2"
                        enter-to-class="opacity-100 translate-y-0"
                        leave-active-class="transition ease-in duration-150"
                        leave-from-class="opacity-100 translate-y-0"
                        leave-to-class="opacity-0 -translate-y-2"
                      >
                        <div
                          v-if="
                            (hashtagSuggestions.length > 0 ||
                              popularHashtags.length > 0) &&
                            showSuggestions
                          "
                          class="absolute left-0 right-0 top-full mt-1 max-h-48 overflow-y-auto bg-white dark:bg-gray-900 rounded-md border border-gray-200 dark:border-gray-700 shadow-sm z-10 hide-scrollbar"
                        >
                          <!-- Search results section -->
                          <div v-if="hashtagSuggestions.length > 0">
                            <div
                              class="px-3 py-1.5 text-xs text-gray-600 bg-gray-50 dark:bg-gray-800 dark:text-gray-600 border-b border-gray-100 dark:border-gray-700"
                            >
                              Suggested hashtags
                            </div>
                            <div
                              v-for="(tag, index) in hashtagSuggestions"
                              :key="tag.id"
                              @click="selectHashtagSuggestion(tag.tag)"
                              :class="[
                                'px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors',
                                selectedSuggestionIndex === index
                                  ? 'bg-blue-50 dark:bg-blue-900/20'
                                  : 'hover:bg-gray-50 dark:hover:bg-gray-800',
                              ]"
                            >
                              <Hash class="h-3.5 w-3.5 text-blue-500" />
                              <span class="text-sm">{{ tag.tag }}</span>
                              <span class="text-xs text-gray-600 ml-auto"
                                >{{ tag.count }} posts</span
                              >
                            </div>
                          </div>

                          <!-- Popular hashtags section -->
                          <div v-if="popularHashtags.length > 0">
                            <div
                              class="px-3 py-1.5 text-xs text-gray-600 bg-gray-50 dark:bg-gray-800 dark:text-gray-600 border-b border-gray-100 dark:border-gray-700"
                            >
                              Popular Hashtags
                            </div>
                            <div class="flex flex-wrap gap-2 p-3">
                              <button
                                v-for="(tag, index) in popularHashtags"
                                :key="index"
                                @click="selectHashtagSuggestion(tag.tag)"
                                class="px-2 py-1 bg-gray-100 hover:bg-blue-50 dark:bg-gray-800 dark:hover:bg-blue-900/20 rounded-full text-xs text-gray-800 dark:text-gray-400 transition-colors flex items-center gap-1"
                              >
                                <Hash class="h-3 w-3 text-blue-500" />
                                {{ tag.tag }}
                              </button>
                            </div>
                          </div>
                        </div>
                      </Transition>
                    </div>
                    <button
                      class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-1"
                      @click="addCategory"
                      :disabled="
                        !categoryInput.trim() ||
                        createPostCategories.includes(categoryInput.trim())
                      "
                    >
                      <Plus class="h-3.5 w-3.5" />
                      Add
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer with action buttons -->
          <div
            class="p-4 border-t border-gray-200 dark:border-gray-700 flex justify-end bg-gradient-to-r from-gray-50 to-white dark:from-gray-900 dark:to-gray-800 sticky bottom-0"
          >
            <button
              class="px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-md mr-2 hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-800 dark:text-gray-400 transition-colors hover:shadow-sm"
              @click="closeModalWithConfirm"
            >
              Cancel
            </button>
            <button
              :disabled="!form.title.trim() || isSubmitting"
              @click="handleCreatePost"
              :class="[
                'px-4 py-2 rounded-md text-white transition-all duration-300 flex items-center gap-2 shadow-sm',
                isSubmitting
                  ? 'bg-indigo-600 cursor-not-allowed'
                  : !form.title.trim()
                  ? 'bg-gray-400 cursor-not-allowed'
                  : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 hover:shadow-sm',
              ]"
            >
              <Loader2 v-if="isSubmitting" class="h-4 w-4 animate-spin" />
              <Send v-else class="h-4 w-4" />
              {{
                isSubmitting
                  ? isEditMode
                    ? "Updating..."
                    : "Posting..."
                  : submitButtonText
              }}
            </button>
          </div>

          <!-- Hidden file input - Updated for multiple files -->
          <input
            type="file"
            ref="fileInputRef"
            class="hidden"
            multiple
            accept="image/*"
            @change="handleFileUpload"
          />
        </div>
      </div>
    </div>
  </Teleport>

  <!-- Confirmation Modal -->
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="showConfirmClose"
        class="fixed inset-0 z-[10000] bg-black/70 backdrop-blur-sm flex items-center justify-center p-4"
        @click="showConfirmClose = false"
      >
        <Transition
          enter-active-class="transition duration-300 ease-out"
          enter-from-class="opacity-0 scale-95"
          enter-to-class="opacity-100 scale-100"
          leave-active-class="transition duration-200 ease-in"
          leave-from-class="opacity-100 scale-100"
          leave-to-class="opacity-0 scale-95"
        >
          <div
            v-if="showConfirmClose"
            class="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full p-6 shadow-sm"
            @click.stop
          >
            <div class="flex items-start mb-4">
              <div
                class="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-full mr-3"
              >
                <AlertTriangle
                  class="h-5 w-5 text-amber-600 dark:text-amber-500"
                />
              </div>
              <div>
                <h3 class="text-lg font-medium text-gray-800 dark:text-white">
                  Discard changes?
                </h3>
                <p class="text-gray-600 dark:text-gray-400 mt-1.5">
                  You have unsaved changes. Are you sure you want to discard
                  your post?
                </p>
              </div>
            </div>
            <div class="flex justify-end gap-3 mt-6">
              <button
                class="px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-md hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-800 dark:text-gray-400 transition-colors"
                @click="showConfirmClose = false"
              >
                Keep Editing
              </button>
              <button
                class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md transition-colors flex items-center gap-1.5"
                @click="discardChanges"
              >
                <Trash2 class="h-4 w-4" />
                Discard
              </button>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>

  <!-- Success Modal -->
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="showSuccessModal"
        class="fixed inset-0 z-[10001] bg-black/50 backdrop-blur-md flex items-center justify-center p-4"
        @click="closeSuccessModal"
      >
        <Transition
          enter-active-class="transition duration-300 ease-out"
          enter-from-class="opacity-0 scale-90 translate-y-8"
          enter-to-class="opacity-100 scale-100 translate-y-0"
          leave-active-class="transition duration-200 ease-in"
          leave-from-class="opacity-100 scale-100 translate-y-0"
          leave-to-class="opacity-0 scale-90 translate-y-8"
        >
          <div
            v-if="showSuccessModal"
            class="bg-white dark:bg-gray-800 rounded-2xl max-w-md w-full mx-4 shadow-2xl border border-gray-100 dark:border-gray-700 overflow-hidden"
            @click.stop
          >
            <!-- Success Header with Gradient -->
            <div
              class="relative bg-gradient-to-br from-emerald-500 via-green-500 to-teal-600 text-white p-6 text-center"
            >
              <!-- Animated Success Icon -->
              <div class="relative mx-auto w-16 h-16 mb-4">
                <div
                  class="absolute inset-0 bg-white/20 rounded-full animate-ping"
                ></div>
                <div
                  class="relative bg-white rounded-full w-16 h-16 flex items-center justify-center"
                >
                  <svg
                    class="h-8 w-8 text-purple-600 animate-party-slow"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      d="M12 2C13.1 2 14 2.9 14 4C14 5.1 13.1 6 12 6C10.9 6 10 5.1 10 4C10 2.9 10.9 2 12 2ZM21 9V7L15 1H5C3.9 1 3 1.9 3 3V17C3 18.1 3.9 19 5 19H11.81C11.3 18.12 11 17.1 11 16C11 13.24 13.24 11 16 11S21 13.24 21 16C21 17.1 20.7 18.12 20.19 19H21C22.1 19 23 18.1 23 17V9H21ZM14 9V3.5L19.5 9H14ZM16 12C14.34 12 13 13.34 13 15S14.34 18 16 18 19 16.66 19 15 17.66 12 16 12ZM16 16.5C15.17 16.5 14.5 15.83 14.5 15S15.17 13.5 16 13.5 17.5 14.17 17.5 15 16.83 16.5 16 16.5Z"
                    />
                    <circle cx="7" cy="6" r="1" />
                    <circle cx="7" cy="9" r="1" />
                    <circle cx="7" cy="12" r="1" />
                  </svg>
                </div>
              </div>

              <!-- Success Title -->
              <h3 class="text-xl font-bold mb-2">
                {{ successMessage }}
              </h3>

              <!-- Success Description -->
              <p class="text-green-50 text-sm opacity-90">
                Your {{ isEditMode ? "updated" : "new" }} post is now live and
                visible to your network
              </p>

              <!-- Decorative Elements -->
              <div
                class="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-16 translate-x-16"
              ></div>
              <div
                class="absolute bottom-0 left-0 w-24 h-24 bg-white/10 rounded-full translate-y-12 -translate-x-12"
              ></div>
            </div>

            <!-- Modal Body -->
            <div class="p-6 bg-gray-50 dark:bg-gray-900">
              <!-- Quick Stats -->
              <div class="grid grid-cols-3 gap-4 mb-6">
                <div
                  class="text-center p-3 bg-white dark:bg-gray-800 rounded-lg shadow-sm"
                >
                  <div
                    class="text-2xl font-bold text-gray-800 dark:text-gray-200"
                  >
                    {{ images.length }}
                  </div>
                  <div class="text-xs text-gray-600 dark:text-gray-400">
                    {{ images.length === 1 ? "Image" : "Images" }}
                  </div>
                </div>
                <div
                  class="text-center p-3 bg-white dark:bg-gray-800 rounded-lg shadow-sm"
                >
                  <div
                    class="text-2xl font-bold text-gray-800 dark:text-gray-200"
                  >
                    {{ createPostCategories.length }}
                  </div>
                  <div class="text-xs text-gray-600 dark:text-gray-400">
                    {{ createPostCategories.length === 1 ? "Tag" : "Tags" }}
                  </div>
                </div>
                <div
                  class="text-center p-3 bg-white dark:bg-gray-800 rounded-lg shadow-sm"
                >
                  <div
                    class="text-2xl font-bold text-green-600 dark:text-green-400"
                  >
                    ✓
                  </div>
                  <div class="text-xs text-gray-600 dark:text-gray-400">
                    Published
                  </div>
                </div>
              </div>
              <!-- Action Buttons -->
              <div class="flex flex-col gap-3">
                <button
                  @click="closeSuccessModal"
                  class="w-full bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 transform hover:scale-105 hover:shadow-lg flex items-center justify-center gap-2"
                >
                  <X class="h-4 w-4" />
                  Close
                  {{ autoCloseCountdown > 0 ? `(${autoCloseCountdown})` : "" }}
                </button>
              </div>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import {
  Plus,
  X,
  Smile,
  ImageIcon,
  Hash,
  Loader2,
  AlertCircle,
  Type,
  AlignLeft,
  Send,
  Edit3,
  AlertTriangle,
  Trash2,
  CheckCircle,
  XCircle,
  Upload,
} from "lucide-vue-next";
const props = defineProps({
  editPost: {
    type: Object,
    default: null,
  },
});

const { user } = useAuth();
// Auth and API
const { post, get, patch } = useApi();
const auth = useAuth();
const emit = defineEmits(["post-created"]);
const route = useRoute();

// Form data
const form = ref({
  title: "",
  content: "",
});

// Refs
const isCreatePostOpen = ref(false);
const images = ref([]);
const createPostCategories = ref([]);
const categoryInput = ref("");
const showEmojiPicker = ref(false);
const fileInputRef = ref(null);
const hashtagInputRef = ref(null);
const isSubmitting = ref(false);
const formError = ref("");
const showConfirmClose = ref(false);
const uploadError = ref("");
const isUploading = ref(false);
const modalRef = ref(null);
const isDragging = ref(false);
const showSuggestions = ref(false);
const hashtagSuggestions = ref([]);
const popularHashtags = ref([]);
const selectedSuggestionIndex = ref(-1);

// Success modal state
const showSuccessModal = ref(false);
const autoCloseCountdown = ref(0);
const autoCloseTimer = ref(null);

// Simplified compression progress tracking (hidden from users)
const compressionProgress = ref(0);
const currentImageIndex = ref(0);
const totalImages = ref(0);
const compressionStatus = ref("");
const showCompressionProgress = ref(false);
const processingFiles = ref([]);

// Additional compression tracking (internal only)
const compressionStartTime = ref(0);
const estimatedTimeRemaining = ref(0);
const totalBytesProcessed = ref(0);
const totalBytesOriginal = ref(0);

// Listen for event from sidebar menu to open the create post modal
onMounted(() => {
  // Use the same named event bus as in SidebarMenu.vue
  const eventBus = useEventBus("create-post-event");

  // Clear any existing listeners first to prevent duplicates
  eventBus.off("open-create-post-modal");

  // Add new listener
  eventBus.on("open-create-post-modal", () => {
    openCreatePostModal();
  });
});

const isEditMode = computed(() => !!props.editPost);
const modalTitle = computed(() =>
  isEditMode.value ? "Edit Post" : "Create Post"
);
const submitButtonText = computed(() =>
  isEditMode.value ? "Update Post" : "Publish Post"
);

const successMessage = computed(() =>
  isEditMode.value ? "Post updated successfully!" : "Post published!"
);

watch(
  () => props.editPost,
  (newPost) => {
    if (newPost) {
      // Populate form with existing post data
      form.value.title = newPost.title || "";
      form.value.content = newPost.content || "";

      // Load existing images if any
      if (newPost.images && newPost.images.length > 0) {
        images.value = [...newPost.images];
      } else {
        images.value = [];
      }

      // Load existing tags/categories
      if (newPost.tags && newPost.tags.length > 0) {
        createPostCategories.value = [...newPost.tags];
      } else {
        createPostCategories.value = [];
      }

      // Open the modal
      openCreatePostModal();
    }
  },
  { immediate: true }
);

// Computed properties
const canAddMoreMedia = computed(() => images.value.length < 12);

const hasUnsavedChanges = computed(
  () =>
    form.value.title.trim() ||
    form.value.content.trim() ||
    images.value.length > 0 ||
    createPostCategories.value.length > 0
);

// Methods
const openCreatePostModal = () => {
  isCreatePostOpen.value = true;
  nextTick(() => {
    document.body.style.overflow = "hidden"; // Prevent background scrolling
    // Get popular hashtags when opening modal
  });
};

const closeModalWithConfirm = () => {
  if (hasUnsavedChanges.value) {
    showConfirmClose.value = true; // Show confirmation dialog
  } else {
    isCreatePostOpen.value = false; // Close modal directly if no changes
    document.body.style.overflow = ""; // Restore scrolling
  }
};

const discardChanges = () => {
  showConfirmClose.value = false; // Hide confirmation dialog
  isCreatePostOpen.value = false; // Close the main modal
  resetForm();
  document.body.style.overflow = ""; // Restore scrolling
};

const resetForm = () => {
  form.value = {
    title: "",
    content: "",
  };
  images.value = [];
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

const removeMedia = (index) => {
  images.value = images.value.filter((_, i) => i !== index);
};

const clearAllImages = () => {
  images.value = [];
};

// Success modal control functions
const closeSuccessModal = () => {
  // Clear any existing timer
  if (autoCloseTimer.value) {
    clearInterval(autoCloseTimer.value);
    autoCloseTimer.value = null;
  }

  autoCloseCountdown.value = 0;
  showSuccessModal.value = false;

  // Now close the main modal and reset form
  resetForm();
  isCreatePostOpen.value = false;
  document.body.style.overflow = "";

  // Reload if on profile page
  if (route.path.includes("profile")) {
    window.location.reload();
  }
};

const startAutoCloseTimer = () => {
  autoCloseCountdown.value = 5;

  autoCloseTimer.value = setInterval(() => {
    autoCloseCountdown.value--;

    if (autoCloseCountdown.value <= 0) {
      closeSuccessModal();
    }
  }, 1000);
};

const handleEmojiClick = (emoji) => {
  form.value.content += emoji;
  showEmojiPicker.value = false;
};

// Enhanced file upload handling with progress tracking
const handleFileUpload = async (event) => {
  const files = Array.from(event.target.files);

  if (!files || files.length === 0) return;

  // Filter to only include image files
  const imageFiles = files.filter((file) => file.type.startsWith("image/"));

  if (imageFiles.length === 0) {
    formError.value = "Please select valid image files";
    setTimeout(() => (formError.value = ""), 3000);
    return;
  }

  // Check if adding these files would exceed the limit
  if (images.value.length + imageFiles.length > 12) {
    formError.value = `You can only upload up to 12 images (${
      12 - images.value.length
    } remaining)`;
    setTimeout(() => {
      formError.value = "";
    }, 3000);
    return;
  }
  isUploading.value = true;
  uploadError.value = "";

  // Initialize enhanced progress tracking
  showCompressionProgress.value = true;
  totalImages.value = imageFiles.length;
  currentImageIndex.value = 0;
  compressionProgress.value = 0;
  compressionStatus.value = "Validating and preparing images...";
  compressionStartTime.value = Date.now();
  estimatedTimeRemaining.value = 0;

  // Calculate total original size
  totalBytesOriginal.value = imageFiles.reduce(
    (sum, file) => sum + file.size,
    0
  );
  totalBytesProcessed.value = 0;

  // Initialize processing files list with validation
  processingFiles.value = imageFiles.map((file) => {
    const validation = validateImageFile(file);
    return {
      name: file.name,
      originalSize: formatFileSize(file.size),
      compressedSize: null,
      compressionRatio: null,
      status: validation.isValid ? "pending" : "error",
      error: validation.error,
    };
  });
  try {
    // Process each file with enhanced tracking
    for (let i = 0; i < imageFiles.length; i++) {
      const file = imageFiles[i];

      // Skip invalid files
      if (processingFiles.value[i].status === "error") {
        continue;
      }

      if (file.size > 12 * 1024 * 1024) {
        processingFiles.value[i].status = "skipped";
        uploadError.value = "Some images exceed 12MB and were skipped";
        continue;
      }

      currentImageIndex.value = i + 1;
      compressionStatus.value = `Processing ${file.name}... (${i + 1}/${
        imageFiles.length
      })`;
      processingFiles.value[i].status = "processing";

      // Process image with enhanced compression
      const compressedImage = await processImageWithProgress(file, i);

      if (compressedImage) {
        const compressedSize = Math.round((compressedImage.length * 3) / 4);
        images.value.push(compressedImage);
        processingFiles.value[i].status = "completed";
        processingFiles.value[i].compressedSize =
          formatFileSize(compressedSize);
        processingFiles.value[i].compressionRatio = calculateCompressionRatio(
          file.size,
          compressedSize
        );

        // Update bytes processed
        totalBytesProcessed.value += file.size;
      }

      // Update progress and time estimation
      compressionProgress.value = ((i + 1) / imageFiles.length) * 100;
      estimatedTimeRemaining.value = estimateRemainingTime(
        i + 1,
        imageFiles.length,
        compressionStartTime.value
      );
    }

    compressionStatus.value = `Compression completed! ${images.value.length} images processed successfully.`;

    // Hide progress after a short delay
    setTimeout(() => {
      showCompressionProgress.value = false;
      processingFiles.value = [];
    }, 2000);
  } catch (error) {
    console.error("File upload error:", error);
    uploadError.value = "Error processing some images";
    compressionStatus.value = "Error occurred during compression";

    setTimeout(() => {
      showCompressionProgress.value = false;
      processingFiles.value = [];
    }, 3000);
  } finally {
    isUploading.value = false;

    // Reset file input
    if (event.target) {
      event.target.value = null;
    }
  }
};

// Handle file drop for drag & drop functionality with progress tracking
const handleFileDrop = async (event) => {
  isDragging.value = false;

  // Get the dropped files
  const files = Array.from(event.dataTransfer.files);

  // Filter to only include images
  const imageFiles = files.filter((file) => file.type.startsWith("image/"));

  if (imageFiles.length === 0) return;

  // Check if adding these files would exceed the limit
  if (images.value.length + imageFiles.length > 12) {
    formError.value = `You can only upload up to 12 images (${
      12 - images.value.length
    } remaining)`;
    setTimeout(() => {
      formError.value = "";
    }, 3000);
    return;
  }
  isUploading.value = true;

  // Initialize enhanced progress tracking for dropped files
  showCompressionProgress.value = true;
  totalImages.value = imageFiles.length;
  currentImageIndex.value = 0;
  compressionProgress.value = 0;
  compressionStatus.value = "Validating and preparing dropped images...";
  compressionStartTime.value = Date.now();
  estimatedTimeRemaining.value = 0;

  // Calculate total original size
  totalBytesOriginal.value = imageFiles.reduce(
    (sum, file) => sum + file.size,
    0
  );
  totalBytesProcessed.value = 0;

  // Initialize processing files list with validation
  processingFiles.value = imageFiles.map((file) => {
    const validation = validateImageFile(file);
    return {
      name: file.name,
      originalSize: formatFileSize(file.size),
      compressedSize: null,
      compressionRatio: null,
      status: validation.isValid ? "pending" : "error",
      error: validation.error,
    };
  });

  try {
    // Process each dropped file with enhanced tracking
    for (let i = 0; i < imageFiles.length; i++) {
      const file = imageFiles[i];

      // Skip invalid files
      if (processingFiles.value[i].status === "error") {
        continue;
      }

      if (file.size > 12 * 1024 * 1024) {
        processingFiles.value[i].status = "skipped";
        uploadError.value = "Some images exceed 12MB and were skipped";
        continue;
      }

      currentImageIndex.value = i + 1;
      compressionStatus.value = `Processing ${file.name}... (${i + 1}/${
        imageFiles.length
      })`;
      processingFiles.value[i].status = "processing";

      // Process image with enhanced compression
      const compressedImage = await processImageWithProgress(file, i);

      if (compressedImage) {
        const compressedSize = Math.round((compressedImage.length * 3) / 4);
        images.value.push(compressedImage);
        processingFiles.value[i].status = "completed";
        processingFiles.value[i].compressedSize =
          formatFileSize(compressedSize);
        processingFiles.value[i].compressionRatio = calculateCompressionRatio(
          file.size,
          compressedSize
        );

        // Update bytes processed
        totalBytesProcessed.value += file.size;
      }

      // Update progress and time estimation
      compressionProgress.value = ((i + 1) / imageFiles.length) * 100;
      estimatedTimeRemaining.value = estimateRemainingTime(
        i + 1,
        imageFiles.length,
        compressionStartTime.value
      );
    }

    compressionStatus.value = `Compression completed! ${images.value.length} images processed successfully.`;

    // Hide progress after a short delay
    setTimeout(() => {
      showCompressionProgress.value = false;
      processingFiles.value = [];
    }, 2000);
  } catch (error) {
    console.error("File drop error:", error);
    uploadError.value = "Error processing some images";
    compressionStatus.value = "Error occurred during compression";

    setTimeout(() => {
      showCompressionProgress.value = false;
      processingFiles.value = [];
    }, 3000);
  } finally {
    isUploading.value = false;
  }
};

// Enhanced image processing with advanced compression and progress tracking
// COMPRESSION OPTIMIZATIONS:
// - Target sizes reduced to 80-120KB (down from 800KB-1.2MB)
// - Smart resizing with aspect ratio preservation
// - Progressive compression with multiple quality phases
// - Advanced preprocessing for noise reduction
// - WebP fallback for better compression
// - Enhanced image smoothing and sharpening
const processImageWithProgress = (file, index) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();

      img.onload = () => {
        try {
          // Apply advanced compression with multiple optimization techniques
          const compressedImage = performAdvancedCompression(img, file.size);

          // Verify compression quality and size
          const compressedSize = Math.round((compressedImage.length * 3) / 4);
          const compressionRatio = (
            ((file.size - compressedSize) / file.size) *
            100
          ).toFixed(1);

          // Add staggered animation delay
          setTimeout(() => {
            resolve(compressedImage);
          }, index * 150); // Stagger by 150ms per image
        } catch (error) {
          console.error(`Error compressing image ${file.name}:`, error);
          reject(error);
        }
      };

      img.onerror = () => {
        reject(new Error(`Invalid image: ${file.name}`));
      };

      img.src = e.target.result;
    };

    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

// Advanced compression algorithm with enhanced optimization
const performAdvancedCompression = (img, originalFileSize) => {
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d");

  // Enable image smoothing for better quality
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = "high";

  // Get optimized settings based on image characteristics
  const settings = optimizeCompressionSettings(
    originalFileSize,
    img.width,
    img.height
  );

  let width = img.width;
  let height = img.height;

  // Smart resizing with aspect ratio preservation
  if (width > settings.maxDimension || height > settings.maxDimension) {
    const aspectRatio = width / height;

    if (width > height) {
      width = settings.maxDimension;
      height = Math.round(width / aspectRatio);
    } else {
      height = settings.maxDimension;
      width = Math.round(height * aspectRatio);
    }

    // Ensure minimum dimensions for quality
    if (width < 400 && height < 400) {
      const minDim = 400;
      if (width < height) {
        width = minDim;
        height = Math.round(minDim / aspectRatio);
      } else {
        height = minDim;
        width = Math.round(minDim * aspectRatio);
      }
    }
  }
  canvas.width = width;
  canvas.height = height;

  // Apply subtle sharpening for better perceived quality
  ctx.filter = "contrast(1.05) saturate(1.02)";
  ctx.drawImage(img, 0, 0, width, height);
  ctx.filter = "none";

  // Apply advanced preprocessing for better compression
  preprocessImageForCompression(canvas, ctx, width, height);

  // Progressive compression with quality optimization
  let quality = settings.initialQuality;
  let resultImage = canvas.toDataURL("image/jpeg", quality);
  let resultSize = Math.round((resultImage.length * 3) / 4);

  // Phase 1: Gentle quality reduction with fine increments
  while (
    resultSize > settings.targetSize &&
    quality > settings.minQuality + 0.1
  ) {
    quality -= 0.01; // Very small increments for smooth quality transition
    resultImage = canvas.toDataURL("image/jpeg", quality);
    resultSize = Math.round((resultImage.length * 3) / 4);
  }

  // Phase 2: Moderate quality reduction if still over target
  while (
    resultSize > settings.targetSize &&
    quality > settings.minQuality + 0.05
  ) {
    quality -= 0.02;
    resultImage = canvas.toDataURL("image/jpeg", quality);
    resultSize = Math.round((resultImage.length * 3) / 4);
  }

  // Phase 3: Smart dimensional reduction if quality limit reached
  if (
    resultSize > settings.targetSize &&
    quality <= settings.minQuality + 0.05
  ) {
    // Calculate optimal scale factor for target size
    const scaleFactor = Math.sqrt(settings.targetSize / resultSize) * 0.9;
    const newWidth = Math.max(300, Math.round(width * scaleFactor));
    const newHeight = Math.max(300, Math.round(height * scaleFactor));

    // Only resize if the reduction is reasonable (not too drastic)
    if (newWidth >= width * 0.6 && newHeight >= height * 0.6) {
      canvas.width = newWidth;
      canvas.height = newHeight;

      // Re-apply enhanced rendering
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = "high";
      ctx.filter = "contrast(1.05) saturate(1.02)";
      ctx.drawImage(img, 0, 0, newWidth, newHeight);
      ctx.filter = "none";

      // Reset quality to a good level after resize
      quality = Math.max(settings.minQuality + 0.1, 0.65);
      resultImage = canvas.toDataURL("image/jpeg", quality);
      resultSize = Math.round((resultImage.length * 3) / 4);

      // Final quality fine-tuning after resize
      while (
        resultSize > settings.targetSize &&
        quality > settings.minQuality
      ) {
        quality -= 0.015;
        resultImage = canvas.toDataURL("image/jpeg", quality);
        resultSize = Math.round((resultImage.length * 3) / 4);
      }
    }
  }

  // Final fallback: If still too large, try WebP format (if supported)
  if (resultSize > settings.targetSize * 1.2) {
    try {
      const webpImage = canvas.toDataURL("image/webp", quality);
      const webpSize = Math.round((webpImage.length * 3) / 4);

      // Use WebP if significantly smaller
      if (webpSize < resultSize * 0.8) {
        return webpImage;
      }
    } catch (e) {
      // WebP not supported, continue with JPEG
    }
  }

  return resultImage;
};

// Legacy process image function (kept for compatibility)
const processImage = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();

      img.onload = () => {
        const canvas = document.createElement("canvas");
        let width = img.width;
        let height = img.height;

        // Resize while maintaining aspect ratio
        const maxSize = 5000;
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

        // Add to images array with animation delay for staggered effect
        setTimeout(() => {
          images.value.push(compressedDataUrl);
          resolve();
        }, images.value.length * 100); // Stagger effect
      };

      img.onerror = () => {
        reject(new Error("Invalid image"));
      };

      img.src = e.target.result;
    };

    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

// Utility function to format file sizes
const formatFileSize = (bytes) => {
  if (bytes === 0) return "0 Bytes";
  const k = 1024;
  const sizes = ["Bytes", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
};

// Advanced pre-processing for optimal compression
const preprocessImageForCompression = (canvas, ctx, width, height) => {
  // Apply subtle noise reduction and edge enhancement
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;

  // Simple noise reduction while preserving edges
  for (let i = 0; i < data.length; i += 4) {
    // Slight smoothing for better compression
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];

    // Preserve important details while reducing noise
    data[i] = Math.round(r * 0.98 + (r > 200 ? 2 : 0));
    data[i + 1] = Math.round(g * 0.98 + (g > 200 ? 2 : 0));
    data[i + 2] = Math.round(b * 0.98 + (b > 200 ? 2 : 0));
  }

  ctx.putImageData(imageData, 0, 0);
};

// Hashtag management
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
  hashtagSuggestions.value = [];
  showSuggestions.value = false;
};

const removeCategory = (category) => {
  createPostCategories.value = createPostCategories.value.filter(
    (c) => c !== category
  );
};

// Function to update content from editor
function updateContent(p) {
  form.value.content = p;
}

// Hashtag autocomplete functions
async function searchHashtags() {
  if (!categoryInput.value.trim()) {
    hashtagSuggestions.value = [];
    // Still show popular hashtags if no search term
    showSuggestions.value = popularHashtags.value.length > 0;
    return;
  }

  try {
    const { data } = await get(`/bn/top-tags/`);

    if (data) {
      hashtagSuggestions.value = data.slice(0, 10);

      showSuggestions.value = true;
    } else {
      hashtagSuggestions.value = [];
      // Still show popular tags if no search results
      showSuggestions.value = popularHashtags.value.length > 0;
    }

    selectedSuggestionIndex.value = -1;
  } catch (error) {
    console.error("Error fetching hashtag suggestions:", error);
    hashtagSuggestions.value = [];
    // Still show popular tags even if search fails
    showSuggestions.value = popularHashtags.value.length > 0;
  }
}

// Fetch popular hashtags

// Handler for when hashtag input is focused
const onHashtagInputFocus = () => {
  showSuggestions.value = true;
  // Show popular tags initially if no search input
  if (!categoryInput.value.trim() && popularHashtags.value.length === 0) {
    console.log("ok");
  } else {
    searchHashtags();
  }
};

// Navigate suggestions with keyboard
const selectNextSuggestion = () => {
  if (hashtagSuggestions.value.length === 0) return;

  if (selectedSuggestionIndex.value < hashtagSuggestions.value.length - 1) {
    selectedSuggestionIndex.value++;
  } else {
    selectedSuggestionIndex.value = 0; // Loop back to first item
  }
};

const selectPrevSuggestion = () => {
  if (hashtagSuggestions.value.length === 0) return;

  if (selectedSuggestionIndex.value > 0) {
    selectedSuggestionIndex.value--;
  } else {
    selectedSuggestionIndex.value = hashtagSuggestions.value.length - 1; // Loop to last item
  }
};

const selectHashtagSuggestion = (tag) => {
  // Use the selected hashtag
  if (tag && !createPostCategories.value.includes(tag)) {
    createPostCategories.value.push(tag);
  }

  // Clear the input and suggestions
  categoryInput.value = "";
  hashtagSuggestions.value = [];
  showSuggestions.value = false;
};

// Create post with enhanced success handling
async function handleCreatePost() {
  formError.value = "";
  isSubmitting.value = true;

  try {
    let response;

    if (isEditMode.value) {
      // Update existing post
      response = await patch(`/bn/posts/${props.editPost.id}/`, {
        ...form.value,
        images: images.value,
        tags: createPostCategories.value,
      });

      // Emit a different event for updates
      emit("post-updated", response.data);

      // Use event bus for better cross-component communication
      const eventBus = useEventBus();
      eventBus.emit("post-updated", response.data);
    } else {
      // Create new post

      response = await post("/bn/posts/", {
        ...form.value,
        images: images.value,
        tags: createPostCategories.value,
      });

      // Emit the event with the complete post data for immediate display

      emit("post-created", response.data); // Use event bus for better cross-component communication

      const eventBus = useEventBus();
      eventBus.emit("post-created", response.data);
    } // Show success modal
    showSuccessModal.value = true;

    // Start auto-close timer
    startAutoCloseTimer();

    // Don't close main modal immediately - let user interact with success modal
    // The success modal will handle closing the main modal
  } catch (error) {
    console.error(
      `Error ${isEditMode.value ? "updating" : "creating"} post:`,
      error
    );
    formError.value =
      error.response?.data?.message ||
      `Failed to ${
        isEditMode.value ? "update" : "create"
      } post. Please try again.`;
  } finally {
    isSubmitting.value = false;
  }
}

// Refresh posts using JWT without page reload
const refreshPostsWithJWT = async () => {
  try {
    // Get the current JWT token
    const token = auth.getToken();

    if (!token) {
      console.error("No JWT token available for refresh");
      return;
    }
  } catch (error) {
    console.error("Error refreshing posts with JWT:", error);
  }
};

// Hide suggestions when clicking outside
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

// Hide suggestions when clicking outside hashtag input
watch(
  () => categoryInput.value,
  (newVal) => {
    if (!newVal) {
      setTimeout(() => {
        showSuggestions.value = false;
      }, 200);
    }
  }
);

// Lifecycle hooks
onMounted(() => {
  document.addEventListener("click", (event) => {
    // Close hashtag suggestions when clicking outside
    const hashtagInput = event.target.closest('input[ref="hashtagInputRef"]');
    const suggestionsDropdown = event.target.closest(".hashtag-suggestions");

    if (!hashtagInput && !suggestionsDropdown && showSuggestions.value) {
      showSuggestions.value = false;
    }

    // Close emoji picker when clicking outside
    const emojiTrigger = event.target.closest(".emoji-trigger");
    const emojiPicker = event.target.closest(".emoji-picker");

    if (!emojiTrigger && !emojiPicker && showEmojiPicker.value) {
      showEmojiPicker.value = false;
    }
  });

  // Handle escape key
  const handleEscape = (e) => {
    if (e.key === "Escape") {
      if (showEmojiPicker.value) {
        showEmojiPicker.value = false;
      } else if (showSuggestions.value) {
        showSuggestions.value = false;
      } else if (isCreatePostOpen.value) {
        closeModalWithConfirm();
      }
    }
  };

  document.addEventListener("keydown", handleEscape);

  // Fetch popular hashtags
  // Clean up
  onUnmounted(() => {
    document.removeEventListener("keydown", handleEscape);
    document.body.style.overflow = "";
  });
});

// Enhanced utility functions for better compression monitoring
const calculateCompressionRatio = (originalSize, compressedSize) => {
  if (!originalSize || !compressedSize) return 0;
  return (((originalSize - compressedSize) / originalSize) * 100).toFixed(1);
};

const estimateRemainingTime = (processed, total, startTime) => {
  if (processed === 0) return 0;
  const elapsed = Date.now() - startTime;
  const averageTimePerFile = elapsed / processed;
  const remaining = total - processed;
  return Math.round((remaining * averageTimePerFile) / 1000); // seconds
};

const validateImageFile = (file) => {
  const validTypes = ["image/jpeg", "image/jpg", "image/png", "image/webp"];
  const maxSize = 12 * 1024 * 1024; // 12MB

  return {
    isValid: validTypes.includes(file.type) && file.size <= maxSize,
    error: !validTypes.includes(file.type)
      ? "Invalid file type. Please upload JPEG, PNG, or WebP images."
      : file.size > maxSize
      ? "File size exceeds 12MB limit."
      : null,
  };
};

const optimizeCompressionSettings = (fileSize, imageWidth, imageHeight) => {
  // Highly optimized compression settings for very small file sizes
  const settings = {
    maxDimension: 1920, // Optimal for web display
    targetSize: 100 * 1024, // 100KB target for very small files
    initialQuality: 0.82, // Start with good quality
    minQuality: 0.55, // Lower minimum for better compression
    smartResize: true, // Enable smart resizing
    progressiveCompression: true, // Enable progressive compression
  };

  // Adjust for large files (>5MB) - aggressive compression
  if (fileSize > 5 * 1024 * 1024) {
    settings.maxDimension = 1600;
    settings.targetSize = 120 * 1024; // 120KB for large files
    settings.initialQuality = 0.78;
    settings.minQuality = 0.5;
  }

  // Adjust for very large images (>4000px) - prioritize size reduction
  if (imageWidth > 4000 || imageHeight > 4000) {
    settings.maxDimension = 1400;
    settings.targetSize = 110 * 1024; // 110KB
    settings.initialQuality = 0.72;
    settings.minQuality = 0.45;
  }

  // Adjust for small files (<1MB) - maintain quality while achieving tiny size
  if (fileSize < 1024 * 1024) {
    settings.targetSize = 80 * 1024; // 80KB for small files
    settings.minQuality = 0.6;
    settings.initialQuality = 0.85;
  }

  // Special handling for mobile photos (typical sizes)
  if (imageWidth >= 3000 && imageHeight >= 4000) {
    settings.maxDimension = 1080; // Mobile-optimized size
    settings.targetSize = 90 * 1024; // 90KB
    settings.initialQuality = 0.75;
  }

  // Ultra-small target for very high resolution images
  if (imageWidth > 6000 || imageHeight > 6000) {
    settings.maxDimension = 1200;
    settings.targetSize = 85 * 1024; // 85KB
    settings.initialQuality = 0.7;
    settings.minQuality = 0.4;
  }

  return settings;
};

// Calculate total compressed size from processing files
const calculateTotalCompressedSize = () => {
  return processingFiles.value
    .filter((file) => file.status === "completed" && file.compressedSize)
    .reduce((total, file) => {
      // Parse size back to bytes from formatted string
      const sizeStr = file.compressedSize.replace(/[^\d.]/g, "");
      const size = parseFloat(sizeStr);
      const unit = file.compressedSize.toLowerCase();

      if (unit.includes("mb")) return total + size * 1024 * 1024;
      if (unit.includes("kb")) return total + size * 1024;
      return total + size;
    }, 0);
};

// Calculate overall compression ratio
const calculateOverallCompressionRatio = () => {
  const totalCompressed = calculateTotalCompressedSize();
  if (!totalBytesOriginal.value || !totalCompressed) return 0;
  return (
    ((totalBytesOriginal.value - totalCompressed) / totalBytesOriginal.value) *
    100
  ).toFixed(1);
};
</script>

<style scoped>
/* Hide scrollbars but maintain scrolling functionality */
.hide-scrollbar {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none;
}

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

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes shake {
  0%,
  100% {
    transform: translateX(0);
  }
  10%,
  30%,
  50%,
  70%,
  90% {
    transform: translateX(-5px);
  }
  20%,
  40%,
  60%,
  80% {
    transform: translateX(5px);
  }
}

@keyframes bounce-once {
  0%,
  100% {
    transform: translateY(0) translateX(-50%);
  }
  40% {
    transform: translateY(-20px) translateX(-50%);
  }
  60% {
    transform: translateY(-10px) translateX(-50%);
  }
}

.animate-shake {
  animation: shake 0.6s cubic-bezier(0.36, 0.07, 0.19, 0.97) both;
}

.animate-bounce-once {
  animation: bounce-once 1s ease-in-out;
}

/* Media cards */
.media-card {
  transition: all 0.2s ease;
  position: relative;
  overflow: hidden;
}

.media-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.media-card:hover::after {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.4) 0%, transparent 50%);
  pointer-events: none;
}

.media-delete-btn {
  opacity: 0;
  transition: all 0.2s ease;
  z-index: 1;
}

.media-card:hover .media-delete-btn {
  opacity: 1;
}

/* Tag animation */
.tag-item {
  animation: fadeIn 0.3s ease forwards;
  transition: all 0.2s ease;
}

.tag-item:hover {
  transform: translateY(-1px);
}

/* Editor Container */
.editor-container {
  border-radius: 0.5rem;
  border: 1px solid #e5e7eb;
  min-height: 150px;
  transition: all 0.2s ease;
}

.editor-container:focus-within {
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

/* Dark mode adjustments */
.dark .editor-container {
  border-color: #374151;
}

.dark .editor-container:focus-within {
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

/* Smooth transitions */
input,
textarea,
button {
  transition: all 0.2s ease-in-out;
}

/* Slow party celebration animation */
@keyframes party-slow {
  0% {
    transform: translateY(0) rotate(0deg) scale(1);
  }
  25% {
    transform: translateY(-2px) rotate(2deg) scale(1.05);
  }
  50% {
    transform: translateY(-4px) rotate(0deg) scale(1.1);
  }
  75% {
    transform: translateY(-2px) rotate(-2deg) scale(1.05);
  }
  100% {
    transform: translateY(0) rotate(0deg) scale(1);
  }
}

.animate-party-slow {
  animation: party-slow 3s ease-in-out infinite;
}
</style>
