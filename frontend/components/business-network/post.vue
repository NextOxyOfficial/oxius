<template>
  <div class="max-w-3xl pb-20">
    <div class="space-y-4">
      <div
        v-for="(post, index) in posts"
        :key="post.id"
        class="transform transition-all duration-300"
        :style="{
          animationDelay: `${index * 0.05}s`,
          animation: 'fadeIn 0.5s ease-out forwards',
        }"
      >
        <!-- Post Card -->
        <div
          class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden transition-all duration-300"
        >
          <div class="p-5">
            <!-- Post Header -->
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center space-x-3 flex-1">
                <div class="relative">
                  <img
                    :src="post?.author_details?.image"
                    :alt="post?.author_details?.name"
                    class="size-10 rounded-full"
                  />
                </div>
                <div class="flex-1">
                  <NuxtLink
                    :to="`/business-network/profile/${post.author}`"
                    class="font-semibold text-gray-900 text-md hover:cursor-pointer flex gap-1 w-full"
                  >
                    <p class="">
                      {{ post?.author_details?.name }}
                    </p>
                    <div
                      v-if="post?.author_details?.kyc"
                      class="text-blue-500 flex items-center"
                    >
                      <UIcon name="i-mdi-check-decagram" class="w-3.5 h-3.5" />
                      <span
                        v-if="post?.author_details?.is_pro"
                        class="text-2xs px-1 py-0.5 font-medium"
                      >
                        <div class="flex items-center gap-0.5">
                          <UIcon
                            name="i-heroicons-shield-check"
                            class="size-4 text-indigo-700 font-semibold"
                          />
                          <span class="text-xs font-semibold text-indigo-700"
                            >Pro</span
                          >
                        </div>
                      </span>
                    </div>
                  </NuxtLink>
                  <p
                    class="text-xs font-semibold bg-white py-0.5 text-slate-500"
                  >
                    {{ post?.author_details?.profession }}
                  </p>
                  <p class="text-xs text-gray-500">
                    {{ formatTimeAgo(post?.created_at) }}
                  </p>
                </div>
              </div>

              <div class="flex items-center gap-2">
                <button
                  v-if="post?.author !== id"
                  :class="[
                    'text-sm h-7 rounded-full px-3 flex items-center gap-1',
                    post.isFollowing
                      ? 'border border-gray-200 text-gray-700'
                      : 'bg-blue-600 text-white',
                  ]"
                  @click="toggleFollow(post)"
                >
                  <component
                    :is="post.isFollowing ? Check : UserPlus"
                    class="h-3 w-3"
                  />
                  {{ post.isFollowing ? "Following" : "Follow" }}
                </button>

                <div class="relative">
                  <button
                    class="h-8 w-8 rounded-full hover:bg-gray-100 flex items-center justify-center"
                    @click="toggleDropdown(post)"
                  >
                    <MoreHorizontal class="h-4 w-4" />
                  </button>

                  <!-- Dropdown Menu -->
                  <div
                    v-if="post.showDropdown"
                    class="absolute right-0 mt-1 w-56 bg-white rounded-lg shadow-lg border border-gray-200 z-10"
                  >
                    <div class="py-1">
                      <button
                        class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        @click="toggleSave(post)"
                      >
                        <Bookmark
                          :class="[
                            'h-4 w-4 mr-2',
                            post.isSaved ? 'text-blue-600 fill-blue-600' : '',
                          ]"
                        />
                        {{ post.isSaved ? "Unsave post" : "Save post" }}
                      </button>
                      <button
                        class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        @click="copyLink(post)"
                      >
                        <Link2 class="h-4 w-4 mr-2" />
                        Copy link
                      </button>
                      <hr class="my-1 border-gray-200" />
                      <button
                        class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        <UserX class="h-4 w-4 mr-2" />
                        Unfollow @{{
                          post.author.fullName.toLowerCase().replace(/\s+/g, "")
                        }}
                      </button>
                      <button
                        class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        <Flag class="h-4 w-4 mr-2" />
                        Report post
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Post Title -->
            <NuxtLink
              :to="`/business-network/posts/${post.slug}`"
              class="block text-base font-semibold mb-1 hover:text-blue-600 transition-colors"
            >
              {{ post.title }}
            </NuxtLink>

            <!-- Tags -->
            <div
              v-if="post?.post_tags?.length > 0"
              class="flex flex-wrap gap-1 mb-2"
            >
              <span
                v-for="(tag, idx) in post?.post_tags"
                :key="idx"
                class="text-sm bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full"
              >
                #{{ tag.tag }}
              </span>
            </div>

            <!-- Post Content -->
            <div class="mb-2 min-w-full">
              <p
                :class="[
                  'text-sm text-gray-700',
                  !post.showFullDescription && 'line-clamp-4',
                ]"
                v-html="post.content"
              ></p>
              <button
                v-if="post?.content?.length > 160"
                class="text-sm text-blue-600 font-medium mt-1"
                @click="toggleDescription(post)"
              >
                {{ post.showFullDescription ? "Read less" : "Read more" }}
              </button>
            </div>

            <!-- Media Gallery -->
            <div v-if="post?.post_media?.length > 0" class="mb-3">
              <!-- Grid layout: 2 columns on mobile, 3 columns on desktop -->
              <div class="grid gap-1 grid-cols-2 md:grid-cols-3">
                <!-- Limit to 6 media items total -->
                <div
                  v-for="(media, mediaIndex) in post.post_media.slice(0, 6)"
                  :key="media.id"
                  class="relative aspect-square cursor-pointer overflow-hidden rounded-md bg-gray-100 transition-transform hover:scale-[1.02]"
                  @click="openMedia(post, mediaIndex)"
                >
                  <img
                    :src="media.image"
                    :alt="`Media ${mediaIndex + 1}`"
                    class="h-full w-full object-cover"
                  />
                  <div
                    v-if="media.type === 'video'"
                    class="absolute inset-0 flex items-center justify-center"
                  >
                    <div
                      class="h-4 w-4 rounded-full bg-black/50 flex items-center justify-center"
                    >
                      <div
                        class="h-0 w-0 border-y-2 border-y-transparent border-l-3 border-l-white ml-0.5"
                      ></div>
                    </div>
                  </div>
                  <div
                    v-if="mediaIndex === 5 && post.post_media.length > 6"
                    class="absolute inset-0 bg-black/50 flex items-center justify-center"
                  >
                    <span class="text-white font-medium text-sm"
                      >+{{ post?.post_media?.length - 6 }}</span
                    >
                  </div>
                </div>
              </div>
            </div>

            <!-- Post Actions -->
            <div
              class="flex items-center justify-between pt-2 border-t border-gray-100 mb-3"
            >
              <div class="flex items-center space-x-4">
                <div class="flex items-center space-x-1">
                  <!-- Update like button with loading state -->
                  <button
                    class="p-1 rounded-full hover:bg-gray-100 transition-colors disabled:opacity-50"
                    @click="toggleLike(post)"
                    :disabled="post.isLikeLoading"
                  >
                    <div
                      v-if="post.isLikeLoading"
                      class="animate-pulse h-4 w-4"
                    >
                      <Loader2 class="h-4 w-4 text-gray-400 animate-spin" />
                    </div>
                    <Heart
                      v-else
                      :class="[
                        'h-4 w-4',
                        post.post_likes?.find(
                          (like) => like.user === user?.user?.id
                        )
                          ? 'text-red-500 fill-red-500'
                          : 'text-gray-500',
                      ]"
                    />
                  </button>
                  <button
                    class="text-sm text-gray-600 hover:underline"
                    @click="openLikesModal(post)"
                  >
                    {{ post?.post_likes?.length }} likes
                  </button>
                </div>
                <button
                  class="flex items-center space-x-1"
                  @click="openCommentsModal(post)"
                >
                  <MessageCircle class="h-4 w-4 text-gray-500" />
                  <span class="text-sm text-gray-600"
                    >{{ post?.post_comments?.length }} comments</span
                  >
                </button>
                <button
                  class="flex items-center space-x-1"
                  @click="sharePost(post)"
                >
                  <Share2 class="h-4 w-4 text-gray-500" />
                  <span class="text-sm text-gray-600">Share</span>
                </button>
                <button
                  class="flex items-center space-x-1"
                  @click="toggleSave(post)"
                >
                  <Bookmark
                    :class="[
                      'h-4 w-4',
                      post.isSaved
                        ? 'text-blue-600 fill-blue-600'
                        : 'text-gray-500',
                    ]"
                  />
                  <span class="text-sm text-gray-600">Save</span>
                </button>
              </div>
            </div>

            <!-- Comments Preview -->
            <div v-if="post?.post_comments?.length > 0" class="space-y-2">
              <!-- See all comments button moved to the top -->
              <button
                v-if="post?.post_comments?.length > 3"
                class="text-sm text-blue-600 font-medium"
                @click="openCommentsModal(post)"
              >
                See all {{ post?.post_comments?.length }} comments
              </button>

              <!-- Comments in reverse order (oldest first, newest last) -->
              <div
                v-for="comment in [...post.post_comments].slice(0, 3).reverse()"
                :key="comment.id"
                class="flex items-start space-x-2"
              >
                <img
                  :src="comment.author_details?.image"
                  :alt="comment.author_details?.name"
                  class="size-8 rounded-full mt-0.5"
                />
                <div class="flex-1">
                  <div class="bg-gray-50 rounded-lg pt-1 px-2">
                    <div class="flex items-center justify-between mb-0.5">
                      <NuxtLink
                        :to="`/business-network/profile/${comment.author}`"
                        class="text-sm font-medium hover:underline"
                      >
                        {{ comment.author_details?.name }}
                      </NuxtLink>
                      <!-- Comment Actions (Edit/Delete) -->
                      <div
                        v-if="comment.author === user?.user?.id"
                        class="flex items-center space-x-1"
                      >
                        <button
                          @click="editComment(post, comment)"
                          class="p-0.5 text-gray-500 hover:text-blue-600"
                        >
                          <UIcon
                            name="i-heroicons-pencil-square"
                            class="size-3.5"
                          />
                        </button>
                        <button
                          @click="deleteComment(post, comment)"
                          class="p-0.5 text-gray-500 hover:text-red-600"
                        >
                          <UIcon name="i-heroicons-trash" class="size-3.5" />
                        </button>
                      </div>
                    </div>
                    <!-- Comment Content -->
                    <div v-if="comment.isEditing">
                      <textarea
                        :id="`comment-edit-${comment.id}`"
                        v-model="comment.editText"
                        class="w-full text-sm p-2 border border-gray-200 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                        rows="2"
                      ></textarea>
                      <div class="flex justify-end space-x-2 mt-1">
                        <button
                          @click="cancelEditComment(comment)"
                          class="text-xs text-gray-500 hover:underline"
                        >
                          Cancel
                        </button>
                        <button
                          @click="saveEditComment(post, comment)"
                          class="text-xs bg-blue-600 text-white rounded-md px-3 py-1 hover:bg-blue-700 disabled:opacity-50"
                          :disabled="
                            !comment.editText?.trim() ||
                            comment.editText === comment.content ||
                            comment.isSaving
                          "
                        >
                          <span v-if="comment.isSaving">Saving...</span>
                          <span v-else>Save</span>
                        </button>
                      </div>
                    </div>
                    <p v-else class="text-sm">{{ comment?.content }}</p>
                  </div>
                  <span class="text-sm text-gray-500 mt-1 inline-block">
                    {{ formatTimeAgo(comment?.created_at) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Add Comment Input -->
            <div
              class="flex items-center gap-2 mt-3 pt-2 border-t border-gray-100"
            >
              <img
                :src="user?.user?.image"
                alt="Your avatar"
                class="size-7 rounded-full"
              />
              <!-- Update the comment input -->
              <div class="flex-1 relative">
                <input
                  type="text"
                  placeholder="Add a comment..."
                  class="w-full text-sm py-1.5 pr-10 pl-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600 transition-all"
                  v-model="post.commentText"
                  @keyup.enter="addComment(post)"
                  @focus="post.showCommentInput = true"
                  @input="handleCommentInput($event, post)"
                  @keydown="handleMentionKeydown($event, post)"
                />
                <div
                  v-if="post.commentText"
                  class="absolute right-2 top-1/2 -translate-y-1/2 flex items-center space-x-1"
                >
                  <button
                    class="p-1 text-gray-400 hover:text-gray-500 transition-colors"
                    @click="post.commentText = ''"
                    aria-label="Clear comment"
                  >
                    <UIcon name="i-heroicons-x-mark" class="h-4 w-4" />
                  </button>
                  <button
                    class="p-1 text-blue-600 hover:text-blue-700 transition-colors"
                    @click="addComment(post)"
                    aria-label="Post comment"
                  >
                    <Send class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="loading" class="flex justify-center py-6">
        <div class="h-6 w-6 animate-spin text-blue-600">
          <Loader2 />
        </div>
      </div>

      <div
        v-if="!loading && posts?.length === 0"
        class="flex flex-col items-center justify-center py-12 text-center"
      >
        <p class="text-gray-500 mb-2">No posts available</p>
      </div>
    </div>

    <!-- Media Viewer -->
    <Teleport to="body">
      <div
        v-if="activeMedia"
        class="fixed inset-0 z-[9999] bg-black/80 flex items-center justify-center p-4"
        @click="activeMedia = null"
      >
        <div
          class="relative max-w-3xl w-full max-h-[80vh] bg-white rounded-lg overflow-hidden flex flex-col"
          @click.stop
        >
          <button
            class="absolute right-2 top-2 z-10 p-1 rounded-full bg-black/50 text-white"
            @click="activeMedia = null"
          >
            <X class="h-6 w-6" />
          </button>

          <div class="flex-1 overflow-hidden relative">
            <div
              v-if="activeMedia.type === 'image' || !activeMedia.type"
              class="relative h-[45vh] w-full"
            >
              <img
                :src="activeMedia.image"
                alt="Media preview"
                class="w-full h-full object-contain"
              />
              <a
                :href="activeMedia.image"
                :download="`media-${activeMedia.id}`"
                class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
                @click.stop
              >
                <Download class="h-5 w-5" />
              </a>
            </div>
            <div v-else-if="activeMedia.type === 'video'" class="relative">
              <video
                :src="activeMedia.url || activeMedia.video"
                controls
                class="w-full h-auto max-h-[45vh]"
              ></video>
              <a
                :href="activeMedia.url || activeMedia.video"
                :download="`video-${activeMedia.id}`"
                class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
                @click.stop
              >
                <Download class="h-5 w-5" />
              </a>
            </div>
          </div>

          <!-- Media navigation -->
          <div v-if="activePost && activePost.post_media.length > 1">
            <button
              class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 rounded-full p-2 text-white touch-manipulation transition-all hover:scale-110"
              @click.stop="navigateMedia('prev')"
            >
              <ChevronLeft class="h-5 w-5" />
            </button>
            <button
              class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 rounded-full p-2 text-white touch-manipulation transition-all hover:scale-110"
              @click.stop="navigateMedia('next')"
            >
              <ChevronRight class="h-5 w-5" />
            </button>
            <div
              class="absolute bottom-2 left-1/2 -translate-x-1/2 bg-black/50 backdrop-blur-sm rounded-full px-3 py-1 text-white text-sm"
            >
              {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
            </div>
          </div>

          <div class="p-4 border-t border-gray-200">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center space-x-4">
                <div class="flex items-center space-x-1">
                  <button
                    class="p-1 rounded-full hover:bg-gray-100 transition-colors"
                    @click.stop="toggleMediaLike"
                  >
                    <Heart
                      :class="[
                        'h-4 w-4',
                        activeMedia.isLiked
                          ? 'text-red-500 fill-red-500'
                          : 'text-gray-500',
                      ]"
                    />
                  </button>
                  <button
                    class="text-sm text-gray-600 hover:underline"
                    @click.stop="openMediaLikesModal"
                  >
                    {{ activeMedia.likeCount }} likes
                  </button>
                </div>
                <div class="flex items-center space-x-1">
                  <MessageCircle class="h-4 w-4 text-gray-500" />
                  <span class="text-sm text-gray-600">
                    {{ activeMedia.comments?.length || 0 }} comments
                  </span>
                </div>
              </div>
            </div>

            <!-- Media comments -->
            <div
              v-if="activeMedia.comments && activeMedia.comments.length > 0"
              class="max-h-[20vh] overflow-y-auto mb-3"
            >
              <h4 class="text-sm font-medium text-gray-500 mb-2">Comments</h4>
              <div class="space-y-2">
                <div
                  v-for="comment in activeMedia.comments"
                  :key="comment.id"
                  class="flex items-start space-x-2"
                >
                  <img
                    :src="comment.user.avatar"
                    alt="User"
                    class="w-6 h-6 rounded-full"
                  />
                  <div class="flex-1">
                    <div class="bg-gray-50 rounded-lg p-2">
                      <div class="flex items-center justify-between">
                        <NuxtLink
                          :to="`/business-network/profile/${comment.user.id}`"
                          class="text-sm font-medium hover:underline"
                        >
                          {{ comment.user.fullName }}
                        </NuxtLink>
                        <button
                          v-if="comment.user.id !== 'current-user'"
                          :class="[
                            'text-sm h-5 rounded-full px-2 flex items-center',
                            comment.user.isFollowing
                              ? 'border border-gray-200 text-gray-700'
                              : 'bg-blue-600 text-white',
                          ]"
                          @click.stop="toggleUserFollow(comment.user)"
                        >
                          {{
                            comment.user.isFollowing ? "Following" : "Follow"
                          }}
                        </button>
                      </div>
                      <p class="text-sm mt-1">{{ comment.text }}</p>
                    </div>
                    <div class="flex items-center mt-1 space-x-3">
                      <span class="text-sm text-gray-500">{{
                        formatTimeAgo(comment.timestamp)
                      }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="flex items-center gap-2">
              <img
                src="https://adsyclub.com/media/images/uploaded_image_lkQNPnN.png?height=24&width=24"
                alt="Your avatar"
                class="w-6 h-6 rounded-full"
              />
              <div class="flex-1 relative">
                <input
                  type="text"
                  placeholder="Add a comment..."
                  class="w-full text-sm py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                  v-model="mediaCommentText"
                  @click.stop
                />
                <button
                  v-if="mediaCommentText"
                  class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-600"
                  @click.stop="addMediaComment"
                >
                  <Send class="h-3 w-3" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Create Post Modal -->
    <BusinessNetworkCreatePost
      :createPostContent="createPostContent"
      :createPostCategories="createPostCategories"
      :isSubmitting="isSubmitting"
      :isCreatePostOpen="isCreatePostOpen"
      :createPostTitle="createPostTitle"
    />

    <!-- Likes Modal -->
    <Teleport to="body">
      <div
        v-if="activeLikesPost"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="activeLikesPost = null"
      >
        <div
          class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden"
          @click.stop
        >
          <div class="p-4 sm:p-5 border-b border-gray-200">
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-semibold">Liked by</h3>
              <button @click="activeLikesPost = null">
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
                <img
                  :src="user.user_details.image"
                  :alt="user.user_details.name"
                  class="w-10 h-10 rounded-full"
                />
                <div>
                  <NuxtLink
                    :to="`/business-network/profile/${user.user}`"
                    class="font-medium hover:underline"
                  >
                    {{ user.user_details.name }}
                  </NuxtLink>
                  <p class="text-sm text-gray-500">
                    @{{
                      user.user_details.name.toLowerCase().replace(/\s+/g, "")
                    }}
                  </p>
                </div>
              </div>
              <button
                v-if="user.id !== 'current-user'"
                :class="[
                  'text-sm h-7 rounded-full px-3 flex items-center gap-1',
                  user.isFollowing
                    ? 'border border-gray-200 text-gray-700'
                    : 'bg-blue-600 text-white',
                ]"
                @click.stop="toggleUserFollow(user)"
              >
                <component
                  :is="user.isFollowing ? Check : UserPlus"
                  class="h-3 w-3"
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
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="activeCommentsPost = null"
      >
        <div
          class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden"
          @click.stop
        >
          <div class="p-4 sm:p-5 border-b border-gray-200">
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-semibold">Comments</h3>
              <button @click="activeCommentsPost = null">
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
            <!-- Display comments with oldest first and newest last -->
            <div
              v-for="comment in [...activeCommentsPost.post_comments].reverse()"
              :key="comment.id"
              class="flex items-start space-x-2"
            >
              <img
                :src="comment.author_details?.image"
                :alt="comment.author_details?.name"
                class="w-8 h-8 rounded-full mt-0.5"
              />
              <div class="flex-1">
                <div class="bg-gray-50 rounded-lg p-2">
                  <div class="flex items-center justify-between mb-1">
                    <NuxtLink
                      :to="`/business-network/profile/${comment?.author}`"
                      class="text-sm font-medium hover:underline"
                    >
                      {{ comment.author_details.name }}
                    </NuxtLink>
                    <!-- Comment Actions for owner -->
                    <div class="flex items-center space-x-1">
                      <button
                        v-if="comment.author !== user?.user?.id"
                        :class="[
                          'text-sm h-5 rounded-full px-2 flex items-center',
                          comment.user?.isFollowing
                            ? 'border border-gray-200 text-gray-700'
                            : 'bg-blue-600 text-white',
                        ]"
                        @click.stop="toggleUserFollow(comment.user)"
                      >
                        {{ comment.user?.isFollowing ? "Following" : "Follow" }}
                      </button>

                      <!-- Edit/Delete buttons -->
                      <div
                        v-if="comment.author === user?.user?.id"
                        class="flex items-center"
                      >
                        <button
                          @click="editComment(activeCommentsPost, comment)"
                          class="p-0.5 text-gray-500 hover:text-blue-600"
                        >
                          <UIcon
                            name="i-heroicons-pencil-square"
                            class="size-4"
                          />
                        </button>
                        <button
                          @click="deleteComment(activeCommentsPost, comment)"
                          class="p-0.5 text-gray-500 hover:text-red-600"
                        >
                          <UIcon name="i-heroicons-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                  <!-- Editable comment content -->
                  <div v-if="comment.isEditing">
                    <textarea
                      :id="`comment-edit-${comment.id}`"
                      v-model="comment.editText"
                      class="w-full text-sm p-2 border border-gray-200 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                      rows="2"
                    ></textarea>
                    <div class="flex justify-end space-x-2 mt-1">
                      <button
                        @click="cancelEditComment(comment)"
                        class="text-xs text-gray-500 hover:underline"
                      >
                        Cancel
                      </button>
                      <button
                        @click="saveEditComment(activeCommentsPost, comment)"
                        class="text-xs bg-blue-600 text-white rounded-md px-3 py-1 hover:bg-blue-700 disabled:opacity-50"
                        :disabled="
                          !comment.editText?.trim() ||
                          comment.editText === comment.content ||
                          comment.isSaving
                        "
                      >
                        <span v-if="comment.isSaving">Saving...</span>
                        <span v-else>Save</span>
                      </button>
                    </div>
                  </div>
                  <p v-else class="text-sm">{{ comment.content }}</p>
                </div>
                <div class="flex items-center mt-1 space-x-3">
                  <span class="text-sm text-gray-500">{{
                    formatTimeAgo(comment.created_at)
                  }}</span>
                </div>
              </div>
            </div>
          </div>
          <div class="p-4 sm:p-5 border-t border-gray-200">
            <div class="flex items-center gap-2">
              <img
                :src="user.user.image"
                :alt="user.user.name"
                class="w-6 h-6 rounded-full"
              />
              <div class="flex-1 relative">
                <!-- Update the comments modal input -->
                <input
                  type="text"
                  placeholder="Add a comment..."
                  class="w-full text-sm py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                  v-model="activeCommentsPost.commentText"
                  @input="handleCommentInput($event, activeCommentsPost)"
                  @keydown="handleMentionKeydown($event, activeCommentsPost)"
                  @keyup.enter="!showMentions && addComment(activeCommentsPost)"
                  @click.stop
                />
                <!-- Add mention dropdown in modal too -->
                <div
                  v-if="
                    showMentions &&
                    mentionSuggestions.length > 0 &&
                    activeCommentsPost === mentionInputPosition?.post
                  "
                  class="absolute left-0 bottom-full mb-1 w-64 bg-white rounded-lg shadow-lg border border-gray-200 z-20 max-h-48 overflow-y-auto"
                >
                  <div class="py-1">
                    <div
                      v-for="(user, index) in mentionSuggestions"
                      :key="user.id"
                      @click="selectMention(user, activeCommentsPost)"
                      :class="[
                        'flex items-center px-3 py-2 cursor-pointer hover:bg-gray-100',
                        index === activeMentionIndex ? 'bg-gray-100' : '',
                      ]"
                    >
                      <img
                        :src="user.image"
                        :alt="user.name"
                        class="w-6 h-6 rounded-full mr-2"
                      />
                      <span class="text-sm font-medium">{{ user.name }}</span>
                    </div>
                  </div>
                </div>
                <button
                  v-if="activeCommentsPost.commentText"
                  class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-600"
                  @click.stop="addComment(activeCommentsPost)"
                >
                  <Send class="h-3 w-3" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Media Likes Modal -->
    <Teleport to="body">
      <div
        v-if="activeMediaLikes"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="activeMediaLikes = null"
      >
        <div
          class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden"
          @click.stop
        >
          <div
            class="p-4 sm:p-5 border-b border-gray-200 flex items-center justify-between"
          >
            <h3 class="font-semibold">Liked by</h3>
            <button @click="activeMediaLikes = null">
              <X class="h-5 w-5" />
            </button>
          </div>
          <div class="overflow-y-auto max-h-[60vh]">
            <div
              v-for="(user, index) in mediaLikedUsers"
              :key="index"
              class="flex items-center justify-between p-4 sm:p-5 border-b border-gray-100"
            >
              <div class="flex items-center space-x-3">
                <img
                  :src="user.avatar"
                  :alt="user.fullName"
                  class="w-10 h-10 rounded-full"
                />
                <div>
                  <NuxtLink
                    :to="`/business-network/profile/${user.id}`"
                    class="font-medium hover:underline"
                  >
                    {{ user.fullName }}
                  </NuxtLink>
                  <p class="text-sm text-gray-500">
                    @{{ user.fullName.toLowerCase().replace(/\s+/g, "") }}
                  </p>
                </div>
              </div>
              <button
                v-if="user.id !== 'current-user'"
                :class="[
                  'text-sm h-7 rounded-full px-3 flex items-center gap-1',
                  user.isFollowing
                    ? 'border border-gray-200 text-gray-700'
                    : 'bg-blue-600 text-white',
                ]"
                @click.stop="toggleUserFollow(user)"
              >
                <component
                  :is="user.isFollowing ? Check : UserPlus"
                  class="h-3 w-3"
                />
                {{ user.isFollowing ? "Following" : "Follow" }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Delete Comment Modal -->
    <Teleport to="body">
      <div
        v-if="commentToDelete"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="commentToDelete = null"
      >
        <div class="bg-white rounded-lg max-w-sm w-full p-4" @click.stop>
          <h3 class="text-lg font-semibold mb-2">Delete Comment</h3>
          <p class="text-gray-600 mb-4">
            Are you sure you want to delete this comment? This action cannot be
            undone.
          </p>
          <div class="flex justify-end space-x-2">
            <button
              @click="commentToDelete = null"
              class="px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              @click="confirmDeleteComment()"
              class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
const props = defineProps({
  posts: {
    type: Array,
    default: () => [],
  },
  id: {
    type: String,
    required: true,
  },
});

import {
  Search,
  X,
  Clock,
  ArrowRight,
  Heart,
  MessageCircle,
  Share2,
  Bookmark,
  Check,
  UserPlus,
  MoreHorizontal,
  Link2,
  Flag,
  Send,
  Plus,
  Home,
  Bell,
  User,
  BarChart2,
  Download,
  ChevronLeft,
  ChevronRight,
  Loader2,
  ImageIcon,
  Smile,
  Paperclip,
  Tag,
  UserX,
} from "lucide-vue-next";
const { user } = useAuth();
const { post, del, put, get } = useApi();

// State
const loading = ref(false);
const isSearchOpen = ref(false);

const searchInputRef = ref(null);
const activeMedia = ref(null);
const activePost = ref(null);
const activeMediaIndex = ref(0);
const mediaCommentText = ref("");
const isCreatePostOpen = ref(false);
const createPostTitle = ref("");
const createPostContent = ref("");
const createPostCategories = ref([]);
const categoryInput = ref("");
const showEmojiPicker = ref(false);
const selectedMedia = ref([]);
const fileInputRef = ref(null);
const isSubmitting = ref(false);
const activeLikesPost = ref(null);
const activeCommentsPost = ref(null);
const activeMediaLikes = ref(null);
const mediaLikedUsers = ref([]);
const commentToDelete = ref(null);
const postWithCommentToDelete = ref(null);
const commentsContainerRef = ref(null);

// Add these to your existing refs
const mentionSearchText = ref("");
const mentionSuggestions = ref([]);
const showMentions = ref(false);
const mentionInputPosition = ref(null);
const activeMentionIndex = ref(0);

// Format time ago
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds} ${diffInSeconds === 1 ? "second" : "seconds"} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${diffInMonths} ${diffInMonths === 1 ? "month" : "months"} ago`;
};

// Toggle follow
const toggleFollow = async (currentPost) => {
  try {
    // Make API call to toggle follow
    const response = await post(`/bn/posts/${currentPost.id}/follow/`, {
      user_id: user?.user?.id,
    });
    console.log("Follow response:", response);
    // Update UI based on response
    if (response && response.data) {
      console.log("Follow toggled successfully:", response.data);
    } else {
      console.error("Failed to toggle follow:", response);
    }
  } catch (error) {
    console.error("Error toggling follow:", error);
  }
};

// Toggle user follow
const toggleUserFollow = (user) => {
  user.isFollowing = !user.isFollowing;
};

// Toggle like
const toggleLike = async (currentPost) => {
  // Check if user is logged in
  if (!user?.value?.user?.id) {
    showNotification("Please log in to like posts", "error");
    return;
  }

  // Prevent multiple clicks
  if (currentPost.isLikeLoading) return;
  currentPost.isLikeLoading = true;

  // Store the original state to revert in case of API error
  const wasLiked = currentPost.post_likes?.some(
    (like) => like.user === user.value?.user?.id
  );

  try {
    if (wasLiked) {
      // Optimistically update UI first
      currentPost.post_likes = currentPost.post_likes.filter(
        (like) => like.user !== user.value?.user?.id
      );

      // Then make API call
      const response = await del(`/bn/posts/${currentPost.id}/unlike/`);

      // Check if API call failed (no need to check status property)
      if (!response) {
        // Revert UI if API fails
        if (
          !currentPost.post_likes.some(
            (like) => like.user === user.value?.user?.id
          )
        ) {
          currentPost.post_likes.push({
            user: user.value?.user?.id,
            user_details: {
              name: user.value?.user?.name,
              image: user.value?.user?.image,
            },
          });
        }
      }
    } else {
      // Optimistically update UI first
      if (!currentPost.post_likes) {
        currentPost.post_likes = [];
      }

      currentPost.post_likes.push({
        user: user.value?.user?.id,
        user_details: {
          name: user.value?.user?.name,
          image: user.value?.user?.image,
        },
      });

      // Then make API call
      const response = await post(`/bn/posts/${currentPost.id}/like/`);
      if (!response) {
        // Revert UI if API fails
        currentPost.post_likes = currentPost.post_likes.filter(
          (like) => like.user !== user.value?.user?.id
        );
      }
    }
  } catch (error) {
    console.error("Error toggling like:", error);

    // Revert UI on error
    if (wasLiked) {
      // Re-add like if we were removing it
      if (
        !currentPost.post_likes.some(
          (like) => like.user === user.value?.user?.id
        )
      ) {
        currentPost.post_likes.push({
          user: user.value?.user?.id,
          user_details: {
            name: user.value?.user?.name,
            image: user.value?.user?.image,
          },
        });
      }
    } else {
      // Remove like if we were adding it
      currentPost.post_likes = currentPost.post_likes.filter(
        (like) => like.user !== user.value?.user?.id
      );
    }
    showNotification("Failed to update like", "error");
  } finally {
    currentPost.isLikeLoading = false;
  }
};

// Toggle media like
const toggleMediaLike = async () => {
  if (!activeMedia.value) return;

  try {
    // Assuming media has a post_id and media_id
    const postId = activePost.value?.id;
    const mediaId = activeMedia.value?.id;

    if (!postId) {
      console.error("Post ID not available for media like");
      return;
    }

    // Make API call to toggle media like (modify endpoint as needed)
    const response = await $fetch(
      `/api/posts/${postId}/media/${mediaId}/like/`,
      {
        method: "POST",
        body: {
          user_id: user?.user?.id,
        },
      }
    );

    // Update UI based on response
    if (response && response.success) {
      activeMedia.value.isLiked = !activeMedia.value.isLiked;
      activeMedia.value.likeCount += activeMedia.value.isLiked ? 1 : -1;

      // Update likedBy array for the media
      if (activeMedia.value.isLiked) {
        if (!activeMedia.value.likedBy) {
          activeMedia.value.likedBy = [];
        }
        activeMedia.value.likedBy.unshift({
          id: user?.user?.id || "current-user",
          fullName: user?.user?.name || "You",
          avatar:
            user?.user?.image || "/images/placeholder.jpg?height=40&width=40",
          isFollowing: false,
        });
      } else if (activeMedia.value.likedBy) {
        activeMedia.value.likedBy = activeMedia.value.likedBy.filter(
          (u) => u.id !== (user?.user?.id || "current-user")
        );
      }
    } else {
      console.error("Failed to toggle media like:", response);
    }
  } catch (error) {
    console.error("Error toggling media like:", error);
    // You may want to show an error notification here
  }
};

// Toggle save
const toggleSave = (post) => {
  post.isSaved = !post.isSaved;
  post.showDropdown = false;
};

// Toggle dropdown
const toggleDropdown = (post) => {
  // Close all other dropdowns first
  posts.value.forEach((p) => {
    if (p.id !== post.id) p.showDropdown = false;
  });

  post.showDropdown = !post.showDropdown;
};

// Toggle description
const toggleDescription = (post) => {
  post.showFullDescription = !post.showFullDescription;
};

// Copy link
const copyLink = (post) => {
  const postUrl = `${window.location.origin}/post/${post.id}`;
  navigator.clipboard.writeText(postUrl);
  alert("Link copied to clipboard");
  post.showDropdown = false;
};

// Share post
const sharePost = (post) => {
  const postUrl = `${window.location.origin}/post/${post.slug}`;

  if (navigator.share && navigator.canShare) {
    navigator
      .share({
        title: post.title,
        text:
          post.content.substring(0, 100) +
          (post.content.length > 100 ? "..." : ""),
        url: postUrl,
      })
      .catch((error) => console.error("Error sharing:", error));
  } else {
    alert(`Share URL: ${postUrl}`);
  }
};

// Open likes modal
const openLikesModal = (post) => {
  activeLikesPost.value = post;
};

// Open comments modal
const openCommentsModal = (post) => {
  activeCommentsPost.value = post;

  // Wait for DOM update then scroll to bottom
  nextTick(() => {
    scrollToLatestComment();
  });
};

// Scroll to latest comment
const scrollToLatestComment = () => {
  if (commentsContainerRef.value) {
    commentsContainerRef.value.scrollTop =
      commentsContainerRef.value.scrollHeight;
  }
};

// Open media likes modal
const openMediaLikesModal = () => {
  if (!activeMedia.value || !activeMedia.value.likedBy) return;

  mediaLikedUsers.value = activeMedia.value.likedBy;
  activeMediaLikes.value = activeMedia.value;
};

// Add comment
const addComment = async (currentPost) => {
  // Check if user is logged in
  if (!user?.value?.user?.id) {
    console.error("User not logged in");
    return;
  }

  if (!currentPost?.commentText?.trim()) return;

  const commentText = currentPost.commentText.trim();

  // Create a temporary comment to show immediately
  const tempComment = {
    id: `temp-${Date.now()}`,
    author: user.value.user.id,
    content: commentText,
    created_at: new Date().toISOString(),
    author_details: {
      name: user.value.user.name,
      image: user.value.user.image,
    },
    // Add needed properties for UI
    user: {
      isFollowing: false,
    },
  };

  // Format mentions in the content if any
  const formattedContent = commentText.replace(
    /@(\w+)/g,
    '<span class="text-blue-600">@$1</span>'
  );

  // Update the tempComment with formatted content
  tempComment.content = formattedContent;

  // Add to UI immediately
  if (!currentPost.post_comments) {
    currentPost.post_comments = [];
  }

  // Add to beginning of array for newest first
  currentPost.post_comments.unshift(tempComment);

  // Clear input field
  currentPost.commentText = "";

  // Scroll to the latest comment if in modal view
  if (currentPost === activeCommentsPost.value) {
    nextTick(() => {
      scrollToLatestComment();
    });
  }

  try {
    // Make API call to add comment
    const response = await post(`/bn/posts/${currentPost.id}/comments/`, {
      content: commentText,
    });

    // If successful, replace temp comment with real one from API
    if (response.data) {
      const index = currentPost.post_comments.findIndex(
        (c) => c.id === tempComment.id
      );
      if (index !== -1) {
        // Replace with actual comment data from API
        currentPost.post_comments[index] = response.data;
      }
    } else {
      // Remove temp comment if API failed
      currentPost.post_comments = currentPost.post_comments.filter(
        (comment) => comment.id !== tempComment.id
      );
      console.error("Failed to add comment:", response);
    }
  } catch (error) {
    // Remove temp comment on error
    currentPost.post_comments = currentPost.post_comments.filter(
      (comment) => comment.id !== tempComment.id
    );
    console.error("Error adding comment:", error);
  }
};

// Edit comment
const editComment = (post, comment) => {
  if (!post || !comment || !user?.value?.user?.id) return;

  // Set editing mode and store original text for cancellation
  comment.isEditing = true;
  comment.editText = comment.content;

  // Focus on textarea after Vue updates the DOM
  nextTick(() => {
    const textarea = document.querySelector(`#comment-edit-${comment.id}`);
    if (textarea) {
      textarea.focus();
    }
  });
};

// Cancel comment edit
const cancelEditComment = (comment) => {
  comment.isEditing = false;
  comment.editText = null;
};

// Save edited comment
const saveEditComment = async (currentPost, comment) => {
  if (!comment.editText?.trim() || comment.editText === comment.content) {
    cancelEditComment(comment);
    return;
  }

  // Add saving state
  comment.isSaving = true;
  const originalContent = comment.content;

  try {
    // Optimistically update UI
    comment.content = comment.editText.trim();
    comment.isEditing = false;

    // Make API call to update comment
    const response = await put(`/bn/comments/${comment.id}/`, {
      ...comment,
      content: comment.editText.trim(),
    });

    if (!response || !response.data) {
      // Revert on failure
      comment.content = originalContent;
      console.error("Failed to update comment");
    }
  } catch (error) {
    // Revert on error
    comment.content = originalContent;
    console.error("Error updating comment:", error);
  } finally {
    // Always reset the saving state
    comment.isSaving = false;
  }
};

// Delete comment
const deleteComment = (post, comment) => {
  if (!post || !comment || !user?.value?.user?.id) return;

  commentToDelete.value = comment;
  postWithCommentToDelete.value = post;
};

const confirmDeleteComment = async () => {
  if (
    !commentToDelete.value ||
    !postWithCommentToDelete.value ||
    !user?.value?.user?.id
  )
    return;

  const comment = commentToDelete.value;
  const post = postWithCommentToDelete.value;

  try {
    // Close modal first
    commentToDelete.value = null;
    postWithCommentToDelete.value = null;

    // Make API call to delete comment
    const response = await del(`/bn/comments/${comment.id}/`);

    // On success, remove from UI
    if (response) {
      // Update the UI by filtering out the deleted comment
      post.post_comments = post.post_comments.filter(
        (c) => c.id !== comment.id
      );
      console.log("Comment deleted successfully");
    } else {
      console.error("Failed to delete comment - API returned no response");
    }
  } catch (error) {
    console.error("Error deleting comment:", error);

    // Show error notification (optional)
    // You might want to add a toast notification system
    // toast.error('Failed to delete comment. Please try again.');
  }
};

// Add media comment
const addMediaComment = () => {
  if (!mediaCommentText.value.trim() || !activeMedia.value) return;

  const newComment = {
    id: `media-comment-${Date.now()}`,
    user: {
      id: "current-user",
      fullName: "You",
      avatar: "/images/placeholder.jpg?height=40&width=40",
    },
    text: mediaCommentText.value,
    timestamp: new Date().toISOString(),
  };

  if (!activeMedia.value.comments) {
    activeMedia.value.comments = [];
  }

  activeMedia.value.comments.unshift(newComment);
  mediaCommentText.value = "";
};

// Open media
const openMedia = (post, index) => {
  activePost.value = post;
  activeMediaIndex.value = index;
  activeMedia.value = post.post_media[index];
};

// Navigate media
const navigateMedia = (direction) => {
  if (!activePost.value || !activeMedia.value) return;

  const currentIndex = activeMediaIndex.value;
  const totalMedia = activePost.value.post_media.length;

  if (direction === "prev") {
    activeMediaIndex.value = (currentIndex - 1 + totalMedia) % totalMedia;
  } else {
    activeMediaIndex.value = (currentIndex + 1) % totalMedia;
  }

  activeMedia.value = activePost.value.post_media[activeMediaIndex.value];
};

// Create post functions
const triggerFileInput = () => {
  fileInputRef.value?.click();
};

const handleFileChange = (e) => {
  const files = e.target.files;
  if (!files) return;

  const newFiles = Array.from(files);

  // Check file type and size constraints
  const validFiles = newFiles.filter((file) => {
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
  const currentImages = selectedMedia.value.filter((file) =>
    file.type.startsWith("image/")
  ).length;
  const currentVideos = selectedMedia.value.filter((file) =>
    file.type.startsWith("video/")
  ).length;

  const newImages = validFiles.filter((file) => file.type.startsWith("image/"));
  const newVideos = validFiles.filter((file) => file.type.startsWith("video/"));

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

const handleEmojiClick = (emoji) => {
  createPostContent.value += emoji;
  showEmojiPicker.value = false;
};

const addCategory = () => {
  if (
    categoryInput.value.trim() &&
    !createPostCategories.value.includes(categoryInput.value.trim())
  ) {
    createPostCategories.value.push(categoryInput.value.trim());
    categoryInput.value = "";
  }
};

const removeCategory = (category) => {
  createPostCategories.value = createPostCategories.value.filter(
    (c) => c !== category
  );
};

// Detect @ mentions while typing
const handleCommentInput = (e, currentPost) => {
  const input = e.target;
  const text = input.value;
  const cursorPosition = input.selectionStart;

  // Check if we're typing a mention
  const textBeforeCursor = text.slice(0, cursorPosition);
  const mentionMatch = textBeforeCursor.match(/(?:^|\s)@(\w*)$/);

  if (mentionMatch) {
    // Extract the search text after @
    const searchText = mentionMatch[1].toLowerCase();
    mentionSearchText.value = searchText;

    // Calculate dropdown position based on @ symbol
    const atIndex = textBeforeCursor.lastIndexOf("@");
    const textBeforeAt = textBeforeCursor.slice(0, atIndex);
    const linePosition = textBeforeAt.split("\n").length - 1;

    // Search for users matching the text
    searchMentionUsers(searchText);

    // Show mention dropdown
    showMentions.value = true;
    activeMentionIndex.value = 0;

    // Store input element for positioning dropdown
    mentionInputPosition.value = input;
  } else {
    // Hide mentions when not typing @
    showMentions.value = false;
  }
};

// Function to search for users
const searchMentionUsers = async (searchText) => {
  try {
    // Replace with your actual user search API
    const response = await post(`/bn/users/search/`, {
      search: searchText,
      limit: 5,
    });

    if (response?.data) {
      mentionSuggestions.value = response.data;
    } else {
      // Fallback to mock data for testing
      mentionSuggestions.value = [
        { id: 1, name: "John Smith", image: "https://via.placeholder.com/40" },
        { id: 2, name: "Jane Doe", image: "https://via.placeholder.com/40" },
        { id: 3, name: "James Brown", image: "https://via.placeholder.com/40" },
      ].filter((user) =>
        user.name.toLowerCase().includes(searchText.toLowerCase())
      );
    }
  } catch (error) {
    console.error("Error searching users:", error);
    mentionSuggestions.value = [];
  }
};

// Function to select a mentioned user
const selectMention = (user, currentPost) => {
  if (!mentionInputPosition.value) return;

  const input = mentionInputPosition.value;
  const text = input.value;
  const cursorPosition = input.selectionStart;

  // Find the start of the mention
  const textBeforeCursor = text.slice(0, cursorPosition);
  const atIndex = textBeforeCursor.lastIndexOf("@");

  // Replace the @searchText with the selected user
  const newText =
    text.slice(0, atIndex) +
    `@${user.name.replace(/\s+/g, "")} ` +
    text.slice(cursorPosition);

  // Update the input value
  currentPost.commentText = newText;

  // Close the mentions dropdown
  showMentions.value = false;

  // Move cursor after the inserted mention
  nextTick(() => {
    const newPosition = atIndex + user.name.replace(/\s+/g, "").length + 2; // +2 for @ and space
    input.setSelectionRange(newPosition, newPosition);
    input.focus();
  });
};

// Handle keyboard navigation in mentions dropdown
const handleMentionKeydown = (e, currentPost) => {
  if (!showMentions.value || mentionSuggestions.value.length === 0) return;

  // Arrow down
  if (e.key === "ArrowDown") {
    e.preventDefault(); // Prevent cursor movement
    activeMentionIndex.value =
      (activeMentionIndex.value + 1) % mentionSuggestions.value.length;
  }

  // Arrow up
  else if (e.key === "ArrowUp") {
    e.preventDefault(); // Prevent cursor movement
    activeMentionIndex.value =
      (activeMentionIndex.value - 1 + mentionSuggestions.value.length) %
      mentionSuggestions.value.length;
  }

  // Enter or Tab to select
  else if ((e.key === "Enter" || e.key === "Tab") && showMentions.value) {
    e.preventDefault();
    selectMention(
      mentionSuggestions.value[activeMentionIndex.value],
      currentPost
    );
  }

  // Escape to cancel
  else if (e.key === "Escape") {
    showMentions.value = false;
  }
};

// Add a method to refresh posts
const refreshPosts = async () => {
  try {
    const response = await get("/bn/posts/");
    posts.value = response.data.results;
  } catch (error) {
    console.error("Failed to refresh posts:", error);
  }
};

// Expose the method to parent components
defineExpose({ refreshPosts });





// Initialize
onMounted(() => {
  // Implement infinite scroll
  window.addEventListener("scroll", () => {
    if (
      window.innerHeight + window.scrollY >= document.body.offsetHeight - 500 &&
      !loading.value
    ) {
      // loadMorePosts();
    }
  });

  // Focus search input when overlay opens
  watch(isSearchOpen, (newVal) => {
    if (newVal) {
      nextTick(() => {
        searchInputRef.value?.focus();
      });
    }
  });
});
</script>

<style scoped>
.border-l-3 {
  border-left-width: 3px;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>