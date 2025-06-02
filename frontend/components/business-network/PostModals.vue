<template>
  <!-- Likes Modal -->
  <div>
    <Teleport to="body">
      <div
        v-if="activeLikesPost"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center"
        @click="$emit('close-likes-modal')"
      >
        <div
          class="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-hidden shadow-sm"
          @click.stop
        >
          <div class="p-4 sm:p-5 border-b border-gray-200">
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-semibold">Liked by</h3>
              <button
                @click="$emit('close-likes-modal')"
                class="hover:bg-gray-100 p-1 rounded-full transition-colors"
              >
                <X class="h-5 w-5" />
              </button>
            </div>
            <p class="text-sm text-gray-600 truncate">
              {{ activeLikesPost.title }}
            </p>
          </div>
          <div class="overflow-y-auto max-h-[60vh]">
            <div
              v-for="user in activeLikesPost.post_likes"
              :key="user.id"
              class="flex items-center justify-between p-4 sm:p-5 border-b border-gray-100"
            >
              <div class="flex items-center space-x-3">
                <NuxtLink :to="`/business-network/profile/${user.user}`">
                  <div class="relative">
                    <!-- Pro user badge with improved color ring around profile picture -->
                    <div
                      v-if="user.user_details?.is_pro"
                      class="absolute inset-0 rounded-full border-2 pro-border-ring z-10"
                    ></div>
                    <img
                      :src="
                        user.user_details.image || '/static/frontend/images/placeholder.jpg'
                      "
                      :alt="user.user_details.name"
                      class="w-10 h-10 rounded-full cursor-pointer object-cover"
                    />
                    <!-- Pro text badge -->
                    <div
                      v-if="user.user_details?.is_pro"
                      class="absolute -bottom-1 -right-1 bg-gradient-to-r from-[#7f00ff] to-[#e100ff] text-white rounded-full px-1.5 py-0.5 flex items-center justify-center shadow-sm z-20 text-xs font-semibold"
                    >
                      PRO
                    </div>
                  </div>
                </NuxtLink>
                <div>
                  <NuxtLink
                    :to="`/business-network/profile/${user.user}`"
                    class="font-medium hover:underline flex items-center gap-1"
                  >
                    {{ user.user_details.name }}
                  </NuxtLink>
                  <p class="text-sm text-gray-600">
                    @{{
                      user.user_details.name.toLowerCase().replace(/\s+/g, "")
                    }}
                  </p>
                </div>
              </div>
              <button
                v-if="currentUser && user.user !== currentUser.user.id"
                :class="[
                  'text-sm h-8 rounded-full px-4 flex items-center gap-1.5 font-medium shadow-sm transition-all duration-200',
                  user.isFollowing
                    ? 'bg-gradient-to-r from-gray-50 to-gray-100 text-gray-800 border border-gray-200 hover:shadow-sm hover:border-gray-300'
                    : 'bg-gradient-to-r from-blue-600 to-blue-700 text-white hover:from-blue-700 hover:to-blue-800 hover:shadow-sm hover:shadow-blue-500/20',
                ]"
                @click.stop="$emit('toggle-user-follow', user)"
              >
                <component
                  :is="user.isFollowing ? Check : UserPlus"
                  class="h-3.5 w-3.5"
                />
                {{ user.isFollowing ? "Following" : "Follow" }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Comments Modal -->
    <Teleport to="body">
      <div
        v-if="activeCommentsPost"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center"
        @click="$emit('close-comments-modal')"
      >
        <div
          class="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-hidden shadow-sm"
          @click.stop
        >
          <div class="p-4 sm:p-5 border-b border-gray-200">
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-semibold">Comments</h3>
              <button
                @click="$emit('close-comments-modal')"
                class="hover:bg-gray-100 p-1 rounded-full transition-colors"
              >
                <X class="h-5 w-5" />
              </button>
            </div>
            <p class="text-sm text-gray-600 truncate">
              {{ activeCommentsPost.title }}
            </p>
          </div>
          <div
            ref="commentsContainerRef"
            class="overflow-y-auto max-h-[60vh] p-3 sm:p-5 space-y-3"
          >
            <!-- Comments with premium glassmorphism design -->
            <div
              v-for="(comment, index) in [
                ...activeCommentsPost.post_comments,
              ].reverse()"
              :key="comment.id"
              class="flex items-start space-x-2.5"
            >
              <div class="flex items-start space-x-2.5 w-full">
                <NuxtLink :to="`/business-network/profile/${comment?.author}`">
                  <div class="relative group">
                    <img
                      :src="comment.author_details?.image"
                      :alt="comment.author_details?.name"
                      class="w-8 h-8 rounded-full mt-0.5 cursor-pointer object-cover border border-gray-200/70 dark:border-slate-700/70 shadow-sm group-hover:shadow-sm transition-all duration-300"
                    />
                  </div>
                </NuxtLink>

                <div class="flex-1">
                  <div
                    class="bg-gray-50/80 dark:bg-slate-800/70 backdrop-blur-[2px] rounded-xl pb-2 pt-0.5 px-3 shadow-sm border border-gray-100/50 dark:border-slate-700/50"
                  >
                    <div class="flex items-center justify-between">
                      <div class="flex items-center gap-1">
                        <NuxtLink
                          :to="`/business-network/profile/${comment.author}`"
                          class="text-sm font-medium text-gray-800 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                        >
                          {{ comment.author_details?.name }}
                        </NuxtLink>
                        <!-- Verified Badge -->
                        <div
                          v-if="comment.author_details?.kyc"
                          class="text-blue-500 flex items-center"
                        >
                          <UIcon name="i-mdi-check-decagram" class="w-3 h-3" />
                        </div>
                      </div>

                      <!-- Only edit/delete buttons for comment owner - Fixing action buttons -->
                      <div
                        v-if="comment.author === user?.user?.id"
                        class="relative"
                      >
                        <button
                          type="button"
                          @click.stop="toggleDropdown(comment)"
                          class="p-1.5 rounded-full text-gray-600 dark:text-gray-600 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all"
                          aria-label="Comment options"
                        >
                          <UIcon
                            name="i-heroicons-ellipsis-horizontal"
                            class="size-4"
                          />
                        </button>

                        <!-- Dropdown menu -->
                        <div
                          v-if="comment.showDropdown"
                          class="absolute right-0 -mt-10 w-36 bg-white/95 dark:bg-slate-800/95 rounded-lg shadow-sm border border-gray-100/50 dark:border-slate-700/50 backdrop-blur-sm z-20 transition-all duration-200 origin-top-right"
                          @click.stop
                        >
                          <div class="py-1">
                            <button
                              @click.stop="
                                editComment(activeCommentsPost, comment);
                                comment.showDropdown = false;
                              "
                              class="flex items-center w-full px-4 py-2 text-sm text-gray-800 dark:text-gray-300 hover:bg-blue-50/50 dark:hover:bg-blue-900/20 transition-colors"
                            >
                              <UIcon
                                name="i-heroicons-pencil-square"
                                class="h-4 w-4 mr-2 text-blue-600 dark:text-blue-400"
                              />
                              <span>Edit</span>
                            </button>

                            <button
                              @click.stop="
                                deleteComment(activeCommentsPost, comment);
                                comment.showDropdown = false;
                              "
                              class="flex items-center w-full px-4 py-2 text-sm text-gray-800 dark:text-gray-300 hover:bg-red-50/50 dark:hover:bg-red-900/20 transition-colors"
                              :disabled="comment.isDeleting"
                            >
                              <div v-if="comment.isDeleting" class="mr-2">
                                <Loader2
                                  class="h-4 w-4 text-red-500 animate-spin"
                                />
                              </div>
                              <UIcon
                                v-else
                                name="i-heroicons-trash"
                                class="h-4 w-4 mr-2 text-red-500 dark:text-red-400"
                              />
                              <span>Delete</span>
                            </button>
                          </div>
                        </div>

                        <!-- Click outside directive to close dropdown -->
                        <div
                          v-if="comment.showDropdown"
                          class="fixed inset-0 z-10"
                          @click="comment.showDropdown = false"
                        ></div>
                      </div>
                    </div>

                    <!-- Comment editing form with glassmorphism -->
                    <div v-if="comment.isEditing">
                      <textarea
                        :id="`comment-edit-${comment.id}`"
                        v-model="comment.editText"
                        class="w-full text-sm p-2 bg-white/90 dark:bg-slate-700/90 border border-blue-200/70 dark:border-blue-700/50 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500/50 dark:focus:ring-blue-400/50 backdrop-blur-sm shadow-sm transition-all duration-300"
                        rows="2"
                      ></textarea>
                      <div class="flex justify-end space-x-2 mt-2">
                        <button
                          type="button"
                          @click.prevent="$emit('cancel-edit-comment', comment)"
                          class="text-xs text-gray-600 dark:text-gray-600 hover:text-gray-800 dark:hover:text-gray-300 px-3 py-1.5 rounded-lg hover:bg-gray-100/80 dark:hover:bg-gray-700/80 transition-colors"
                        >
                          Cancel
                        </button>
                        <button
                          type="button"
                          @click.prevent="
                            saveEditComment(activeCommentsPost, comment)
                          "
                          class="text-xs bg-gradient-to-r from-blue-500 to-blue-600 dark:from-blue-600 dark:to-blue-700 text-white rounded-lg px-3 py-1.5 hover:from-blue-600 hover:to-blue-700 dark:hover:from-blue-500 dark:hover:to-blue-600 disabled:opacity-50 shadow-sm hover:shadow transition-all flex items-center justify-center gap-1.5"
                          :disabled="
                            !comment.editText?.trim() ||
                            comment.editText === comment.content ||
                            comment.isSaving
                          "
                        >
                          <Loader2
                            v-if="comment.isSaving"
                            class="h-3 w-3 animate-spin"
                          />
                          <span v-if="comment.isSaving">Saving...</span>
                          <span v-else>Save</span>
                        </button>
                      </div>
                    </div>

                    <!-- Comment content with premium styling and special gift display -->
                    <div v-else>
                      <!-- Gift comment with enhanced styling -->
                      <div v-if="comment?.is_gift_comment" class="gift-comment">
                        <!-- "Sent X diamonds" label -->
                        <div class="gift-sender-info flex items-center gap-1">
                          <UIcon
                            name="material-symbols:diamond-outline"
                            class="w-4 h-4 text-pink-500"
                          />
                          <span
                            class="text-sm font-medium text-pink-600 dark:text-pink-400"
                          >
                            Sent {{ comment?.diamond_amount }} diamonds to
                            {{ activeCommentsPost.author_details.name }}
                          </span>
                        </div>

                        <!-- Gift message content with improved styling -->
                        <div class="gift-content">
                          <p class="gift-message-text">
                            {{ extractGiftMessage(comment?.content) }}
                          </p>
                        </div>
                      </div>
                      <!-- Regular comment -->
                      <p
                        v-else
                        class="text-sm sm:text-sm text-gray-800 dark:text-gray-300"
                        style="word-break: break-word"
                      >
                        {{ comment?.content }}
                      </p>
                    </div>
                  </div>

                  <!-- Timestamp with premium styling -->
                  <div class="flex items-center mt-1 pl-1">
                    <UIcon
                      name="i-heroicons-clock"
                      class="w-3 h-3 text-gray-600 dark:text-gray-600 mr-1"
                    />
                    <span class="text-sm text-gray-600 dark:text-gray-600">
                      {{ formatTimeAgo(comment?.created_at) }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="p-4 sm:p-5 border-t border-gray-200" v-if="user?.user">
            <div class="flex items-center gap-2">
              <div class="relative">
                <!-- Pro user badge with improved color ring around profile picture -->
                <div
                  v-if="user?.user?.is_pro"
                  class="absolute inset-0 rounded-full border-2 pro-border-ring z-10"
                ></div>
                <img
                  :src="user?.user?.image || '/static/frontend/images/placeholder.jpg'"
                  :alt="user?.user?.name"
                  class="w-6 h-6 rounded-full object-cover"
                />
                <!-- Pro text badge -->
                <div
                  v-if="user?.user?.is_pro"
                  class="absolute -bottom-1 -right-1 bg-gradient-to-r from-[#7f00ff] to-[#e100ff] text-white rounded-full px-1 py-0.5 flex items-center justify-center shadow-sm z-20 text-xs font-semibold"
                >
                  PRO
                </div>
              </div>
              <div class="flex-1 relative">
                <!-- <input
                  type="text"
                  placeholder="Add a comment..."
                  class="w-full text-sm py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                  v-model="activeCommentsPost.commentText"
                  @input="
                    $emit('handle-comment-input', $event, activeCommentsPost)
                  "
                  @keydown="
                    $emit('handle-mention-keydown', $event, activeCommentsPost)
                  "
                  @keyup.enter="
                    !showMentions && $emit('add-comment', activeCommentsPost)
                  "
                  @click.stop
                /> -->
                <textarea
                  v-model="activeCommentsPost.commentText"
                  placeholder="Add a comment..."
                  rows="1"
                  class="w-full text-sm py-2.5 pr-28 pl-4 bg-gray-50/80 dark:bg-slate-800/70 border border-gray-200/70 dark:border-slate-700/50 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-400/40 shadow-sm hover:shadow-sm focus:shadow-sm transition-all duration-300 backdrop-blur-[2px] text-gray-800 dark:text-gray-300 placeholder-gray-500 dark:placeholder-gray-400 resize-none overflow-y-auto leading-5 max-h-[6.5rem] no-scrollbar"
                  @input="
                    autoResize();
                    $emit('handle-comment-input', $event, activeCommentsPost);
                  "
                  @focus="activeCommentsPost.showCommentInput = true"
                  @keydown="
                    $emit('handle-mention-keydown', $event, activeCommentsPost)
                  "
                />
                <!-- Mention suggestions dropdown -->
                <div
                  v-if="
                    showMentions &&
                    mentionSuggestions.length > 0 &&
                    activeCommentsPost === mentionInputPosition?.post
                  "
                  class="absolute left-0 bottom-full mb-1 w-64 bg-white rounded-lg shadow-sm border border-gray-200 z-20 max-h-48 overflow-y-auto"
                >
                  <div class="py-1">
                    <div
                      v-for="(user, index) in mentionSuggestions"
                      :key="user.id"
                      @click="$emit('select-mention', user, activeCommentsPost)"
                      :class="[
                        'flex items-center px-3 py-2 cursor-pointer hover:bg-gray-100',
                        index === activeMentionIndex ? 'bg-gray-100' : '',
                      ]"
                    >
                      <div class="relative">
                        <!-- Pro user badge with improved color ring around profile picture -->
                        <div
                          v-if="user?.follower_details?.is_pro"
                          class="absolute inset-0 rounded-full border-2 pro-border-ring z-10"
                        ></div>
                        <img
                          :src="
                            user?.follower_details?.image ||
                            '/static/frontend/images/placeholder.jpg'
                          "
                          :alt="user?.follower_details?.name"
                          class="w-7 h-7 rounded-full mr-2 object-cover"
                        />
                        <!-- Pro text badge -->
                        <div
                          v-if="user?.follower_details?.is_pro"
                          class="absolute -bottom-1 -right-1 bg-gradient-to-r from-[#7f00ff] to-[#e100ff] text-white rounded-full px-1 py-0.5 flex items-center justify-center shadow-sm z-20 text-xs font-semibold"
                        >
                          PRO
                        </div>
                      </div>
                      <span class="text-sm font-medium flex items-center gap-1">
                        {{ user?.follower_details?.name }}
                      </span>
                    </div>
                  </div>
                </div>
                <div
                  v-if="activeCommentsPost.commentText"
                  class="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-1"
                >
                  <button
                    class="p-1 rounded-full text-gray-600 hover:text-gray-600 dark:text-gray-600 dark:hover:text-gray-400 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all duration-300"
                    @click="activeCommentsPost.commentText = ''"
                    aria-label="Clear comment"
                  >
                    <UIcon name="i-heroicons-x-mark" class="h-4 w-4" />
                  </button>
                  <button
                    class="p-1 rounded-full bg-blue-500/90 mb-1 hover:bg-blue-600 text-white shadow-sm hover:shadow transform hover:scale-105 transition-all duration-300"
                    @click="$emit('add-comment', activeCommentsPost)"
                    aria-label="Post comment"
                  >
                    <Send class="h-3.5 w-3.5" />
                    <!-- Subtle glow effect -->
                    <div
                      class="absolute inset-0 rounded-full bg-blue-400/50 blur-md opacity-0 hover:opacity-60 transition-opacity duration-300 -z-10"
                    ></div>
                  </button>
                  <button
                    class="p-1 rounded-full text-gray-600 hover:text-gray-600 dark:text-gray-600 dark:hover:text-gray-400 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all duration-300"
                    aria-label="Clear comment"
                  >
                    <UIcon
                      name="i-streamline-gift-2"
                      class="size-4 text-pink-500"
                    />
                  </button>
                </div>
                <!-- <button
                  v-if="activeCommentsPost.commentText"
                  class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-600 flex items-center gap-1"
                  @click.stop="$emit('add-comment', activeCommentsPost)"
                  :disabled="activeCommentsPost.isCommentLoading"
                >
                  <Loader2
                    v-if="activeCommentsPost.isCommentLoading"
                    class="h-5 w-5 animate-spin"
                  />
                  <Send v-else class="h-3 w-3" />
                </button> -->
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Delete Comment Modal -->
    <Teleport to="body">
      <div
        v-if="commentToDelete"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center"
        @click="$emit('cancel-delete-comment')"
      >
        <div
          class="bg-white rounded-lg max-w-sm w-full p-4 shadow-sm"
          @click.stop
        >
          <h3 class="text-base font-semibold mb-2">Delete Comment</h3>
          <p class="text-gray-600 mb-4">
            Are you sure you want to delete this comment? This action cannot be
            undone.
          </p>
          <div class="flex justify-end space-x-2">
            <button
              @click="$emit('cancel-delete-comment')"
              class="px-4 py-2 border border-gray-200 text-gray-800 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              @click="$emit('confirm-delete-comment')"
              class="px-4 py-2 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg hover:from-red-700 hover:to-red-800 shadow-sm transition-colors"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Photo Gallery Viewer -->
    <Teleport to="body">
      <div
        v-if="activePhotoViewer"
        class="fixed inset-0 z-[9999] bg-black/90 flex items-center justify-center p-4"
        @click="$emit('close-photo-viewer')"
      >
        <div
          class="max-w-4xl w-full max-h-[80vh] overflow-hidden flex flex-col"
          @click.stop
        >
          <!-- Header with close and download buttons -->
          <div class="flex items-center justify-between p-4 text-white">
            <h3 class="font-medium text-base truncate">
              {{ activePhotoViewer.title || "Photo" }}
            </h3>
            <div class="flex items-center gap-3">
              <button
                @click="downloadImage(activePhotoViewer.currentPhoto)"
                class="p-2 rounded-full hover:bg-white/10 flex items-center justify-center transition-colors"
                title="Download"
              >
                <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5" />
              </button>
              <button
                @click="$emit('close-photo-viewer')"
                class="p-2 rounded-full hover:bg-white/10 flex items-center justify-center transition-colors"
              >
                <X class="h-5 w-5" />
              </button>
            </div>
          </div>

          <!-- Photo display -->
          <div
            class="relative overflow-hidden flex-1 flex items-center justify-center"
          >
            <img
              :src="activePhotoViewer.currentPhoto"
              :alt="activePhotoViewer.title || 'Photo'"
              class="max-h-[80vh] max-w-full object-contain"
            />

            <!-- Navigation buttons if multiple photos -->
            <div
              v-if="
                activePhotoViewer.photos && activePhotoViewer.photos.length > 1
              "
              class="absolute inset-x-0 top-1/2 -translate-y-1/2 flex justify-between px-4"
            >
              <button
                @click.stop="$emit('prev-photo', activePhotoViewer)"
                class="p-2 rounded-full bg-black/30 text-white hover:bg-black/50 transition-colors"
              >
                <UIcon name="i-heroicons-chevron-left" class="w-5 h-5" />
              </button>
              <button
                @click.stop="$emit('next-photo', activePhotoViewer)"
                class="p-2 rounded-full bg-black/30 text-white hover:bg-black/50 transition-colors"
              >
                <UIcon name="i-heroicons-chevron-right" class="w-5 h-5" />
              </button>
            </div>
          </div>

          <!-- Thumbnails if multiple photos -->
          <div
            v-if="
              activePhotoViewer.photos && activePhotoViewer.photos.length > 1
            "
            class="p-2 flex justify-center gap-2 bg-black/80"
          >
            <button
              v-for="(photo, index) in activePhotoViewer.photos"
              :key="index"
              @click.stop="$emit('select-photo', activePhotoViewer, index)"
              :class="[
                'h-12 w-12 rounded overflow-hidden border-2',
                activePhotoViewer.currentPhotoIndex === index
                  ? 'border-blue-500'
                  : 'border-transparent hover:border-gray-400',
              ]"
            >
              <img :src="photo" class="h-full w-full object-cover" />
            </button>
          </div>

          <!-- Photo info -->
          <div class="p-3 text-white/80 text-sm bg-black/80">
            <p v-if="activePhotoViewer.caption" class="mb-1">
              {{ activePhotoViewer.caption }}
            </p>
            <p>
              {{
                activePhotoViewer.photoIndex
                  ? `${activePhotoViewer.photoIndex + 1}/${
                      activePhotoViewer.totalPhotos
                    }`
                  : ""
              }}
            </p>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { X, Check, UserPlus, Loader2, Send } from "lucide-vue-next";

const props = defineProps({
  activeLikesPost: {
    type: Object,
    default: null,
  },
  activeCommentsPost: {
    type: Object,
    default: null,
  },
  commentToDelete: {
    type: Object,
    default: null,
  },
  user: {
    type: Object,
    default: null,
  },
  showMentions: {
    type: Boolean,
    default: false,
  },
  mentionSuggestions: {
    type: Array,
    default: () => [],
  },
  activeMentionIndex: {
    type: Number,
    default: 0,
  },
  mentionInputPosition: {
    type: Object,
    default: null,
  },
  activePhotoViewer: {
    type: Object,
    default: null,
  },
});

const { user: currentUser } = useAuth();
// Export a reference to the comments container for scrolling
const commentsContainerRef = ref(null);

const emit = defineEmits([
  "close-likes-modal",
  "toggle-user-follow",
  "close-comments-modal",
  "handle-comment-input",
  "handle-mention-keydown",
  "add-comment",
  "cancel-delete-comment",
  "confirm-delete-comment",
  "edit-comment",
  "delete-comment",
  "cancel-edit-comment",
  "save-edit-comment",
  "select-mention",
  "close-photo-viewer",
  "prev-photo",
  "next-photo",
  "select-photo",
]);

defineExpose({ commentsContainerRef });

// Format time ago function
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${Math.abs(diffInSeconds)} ${
      diffInSeconds === 1 ? "second" : "seconds"
    } ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${Math.abs(diffInMinutes)} ${
      diffInMinutes === 1 ? "minute" : "minutes"
    } ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${Math.abs(diffInHours)} ${
      diffInHours === 1 ? "hour" : "hours"
    } ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${Math.abs(diffInDays)} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${Math.abs(diffInMonths)} ${
    diffInMonths === 1 ? "month" : "months"
  } ago`;
};

// Function to download an image
const downloadImage = (url) => {
  if (!url) return;

  const link = document.createElement("a");
  link.href = url;
  link.download = url.split("/").pop() || "download.jpg";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

function autoResize() {
  const el = this.$refs.activeCommentsPost.commentTextarea;
  if (el) {
    el.style.height = "auto";
    el.style.height = Math.min(el.scrollHeight, 104) + "px"; // 3 lines ~ 104px
  }
}

// Extract clean gift message from content
const extractGiftMessage = (content) => {
  if (!content) return "";

  // Remove common prefixes like "Sent X diamonds as a gift! ✨"
  if (content.includes("diamonds as a gift")) {
    return content.replace(/^Sent \d+ diamonds as a gift! ✨/, "").trim();
  }

  return content;
};

// Toggle dropdown visibility
const toggleDropdown = (comment) => {
  // First, close all other dropdowns
  if (props.activeCommentsPost?.post_comments) {
    props.activeCommentsPost?.post_comments.forEach((c) => {
      if (c.id !== comment.id) {
        c.showDropdown = false;
      }
    });
  }

  // Toggle this dropdown
  if (comment.showDropdown === undefined) {
    comment.showDropdown = true;
  } else {
    comment.showDropdown = !comment.showDropdown;
  }
};

const editComment = (post, comment) => {
  // Initialize edit text if not already set
  if (!comment.editText) {
    comment.editText = comment.content;
  }

  // Set editing state
  comment.isEditing = true;

  // Emit event for parent components
  emit("edit-comment", post, comment);
};
const saveEditComment = (post, comment) => {
  // Emit save event to parent
  emit("save-edit-comment", post, comment);
};
</script>

<style scoped>
/* Improved Pro user border with proper rounded style */
.pro-border-ring {
  border-radius: 9999px; /* Ensure full circle */
  border: 2px solid transparent;
  background: linear-gradient(to right, #7f00ff, #e100ff, #9500ff, #d700ff)
    border-box;
  -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
}

/* Hide scrollbar for Chrome, Safari and Opera */
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
/* Hide scrollbar for IE, Edge and Firefox */
.no-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}

/* Premium Gift Comment Styling */
.gift-comment {
  @apply relative my-2 p-3 rounded-xl overflow-hidden bg-gradient-to-r from-pink-100/90 via-pink-50/80 to-fuchsia-100/70 border border-pink-200/60 shadow-sm transition-all duration-300;
}

.dark .gift-comment {
  @apply from-pink-900/30 via-pink-800/25 to-fuchsia-900/30 border-pink-700/40;
}

.gift-comment:hover {
  @apply -translate-y-0.5 shadow-sm;
}

/* Gift sender info styling */
.gift-sender-info {
  @apply text-xs text-pink-600 dark:text-pink-400;
}

/* Gift message styling */
.gift-message-text {
  @apply text-sm leading-relaxed text-gray-800 dark:text-gray-300 mt-1;
}

/* Top Gift Comment Styling */
.gift-comment-premium {
  @apply relative p-3 rounded-xl overflow-hidden border-pink-300/40 shadow-sm transition-all duration-300;
  background: linear-gradient(
    135deg,
    rgba(253, 242, 248, 0.9) 0%,
    rgba(249, 168, 212, 0.15) 50%,
    rgba(253, 242, 248, 0.7) 100%
  );
}

.dark .gift-comment-premium {
  @apply border-pink-700/40;
  background: linear-gradient(
    135deg,
    rgba(131, 24, 67, 0.3) 0%,
    rgba(219, 39, 119, 0.2) 50%,
    rgba(131, 24, 67, 0.3) 100%
  );
}
</style>
