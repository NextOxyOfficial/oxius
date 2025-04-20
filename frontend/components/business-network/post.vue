

<template>
<div class="max-w-3xl mx-auto pb-20">
        <div class="space-y-4 p-2 sm:px-4">
          <div
            v-for="(post, index) in posts"
            :key="post.id"
            class="transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-md"
            :style="{
              animationDelay: `${index * 0.05}s`,
              animation: 'fadeIn 0.5s ease-out forwards'
            }"
          >
            <!-- Post Card -->
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-all duration-300">
              <div class="p-3">
                <!-- Post Header -->
                <div class="flex items-center justify-between mb-2">
                  <div class="flex items-center space-x-3">
                    <div class="relative">
                      <img :src="post.author.avatar" :alt="post.author.fullName" class="w-8 h-8 rounded-full" />
                      <div v-if="post.author.verified" class="absolute -right-0.5 -bottom-0.5 bg-blue-500 text-white rounded-full p-0.5">
                        <Check class="h-2.5 w-2.5" />
                      </div>
                    </div>
                    <div>
                      <NuxtLink :to="`/business-network/profile/${post.author.id}`" class="font-medium text-gray-900 text-sm hover:underline flex items-center gap-1">
                        {{ post.author.fullName }}
                        <div v-if="post.author.verified" class="text-blue-500">
                          <Check class="h-3.5 w-3.5" />
                        </div>
                      </NuxtLink>
                      <p class="text-xs text-gray-500">{{ formatTimeAgo(post.timestamp) }}</p>
                    </div>
                  </div>
  
                  <div class="flex items-center gap-2">
                    <button
                      :class="[
                        'text-xs h-7 rounded-full px-3 flex items-center gap-1',
                        post.isFollowing ? 'border border-gray-200 text-gray-700' : 'bg-blue-600 text-white'
                      ]"
                      @click="toggleFollow(post)"
                    >
                      <component :is="post.isFollowing ? Check : UserPlus" class="h-3 w-3" />
                      {{ post.isFollowing ? 'Following' : 'Follow' }}
                    </button>
  
                    <div class="relative">
                      <button class="h-8 w-8 rounded-full hover:bg-gray-100 flex items-center justify-center" @click="toggleDropdown(post)">
                        <MoreHorizontal class="h-4 w-4" />
                      </button>
  
                      <!-- Dropdown Menu -->
                      <div v-if="post.showDropdown" class="absolute right-0 mt-1 w-56 bg-white rounded-lg shadow-lg border border-gray-200 z-10">
                        <div class="py-1">
                          <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" @click="toggleSave(post)">
                            <Bookmark :class="['h-4 w-4 mr-2', post.isSaved ? 'text-blue-600 fill-blue-600' : '']" />
                            {{ post.isSaved ? 'Unsave post' : 'Save post' }}
                          </button>
                          <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" @click="copyLink(post)">
                            <Link2 class="h-4 w-4 mr-2" />
                            Copy link
                          </button>
                          <hr class="my-1 border-gray-200" />
                          <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                            <UserX class="h-4 w-4 mr-2" />
                            Unfollow @{{ post.author.fullName.toLowerCase().replace(/\s+/g, "") }}
                          </button>
                          <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                            <Flag class="h-4 w-4 mr-2" />
                            Report post
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
  
                <!-- Post Title -->
                <NuxtLink :to="`/post/${post.id}`" class="block text-base font-semibold mb-1 hover:text-blue-600 transition-colors">
                  {{ post.title }}
                </NuxtLink>
  
                <!-- Categories -->
                <div v-if="post.categories && post.categories.length > 0" class="flex flex-wrap gap-1 mb-2">
                  <span v-for="(category, idx) in post.categories" :key="idx" class="text-[10px] bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                    {{ category }}
                  </span>
                </div>
  
                <!-- Post Content -->
                <div class="mb-2">
                  <p :class="['text-sm text-gray-700', !post.showFullDescription && 'line-clamp-4']">
                    {{ post.content }}
                  </p>
                  <button v-if="post.content.length > 160" class="text-xs text-blue-600 font-medium mt-1" @click="toggleDescription(post)">
                    {{ post.showFullDescription ? 'Read less' : 'Read more' }}
                  </button>
                </div>
  
                <!-- Media Gallery -->
                <div v-if="post.media.length > 0" class="mb-3">
                  <div class="grid grid-cols-4 gap-1">
                    <div
                      v-for="(media, mediaIndex) in post.media.slice(0, 8)"
                      :key="media.id"
                      class="relative aspect-square cursor-pointer overflow-hidden rounded-md bg-gray-100 transition-transform hover:scale-[1.02]"
                      @click="openMedia(post, mediaIndex)"
                    >
                      <img :src="media.thumbnail" :alt="`Media ${mediaIndex + 1}`" class="h-full w-full object-cover" />
                      <div v-if="media.type === 'video'" class="absolute inset-0 flex items-center justify-center">
                        <div class="h-4 w-4 rounded-full bg-black/50 flex items-center justify-center">
                          <div class="h-0 w-0 border-y-2 border-y-transparent border-l-3 border-l-white ml-0.5"></div>
                        </div>
                      </div>
                      <div v-if="mediaIndex === 7 && post.media.length > 8" class="absolute inset-0 bg-black/50 flex items-center justify-center">
                        <span class="text-white font-medium text-xs">+{{ post.media.length - 8 }}</span>
                      </div>
                    </div>
                  </div>
                </div>
  
                <!-- Post Actions -->
                <div class="flex items-center justify-between pt-2 border-t border-gray-100 mb-3">
                  <div class="flex items-center space-x-4">
                    <div class="flex items-center space-x-1">
                      <button class="p-1 rounded-full hover:bg-gray-100 transition-colors" @click="toggleLike(post)">
                        <Heart :class="['h-4 w-4', post.isLiked ? 'text-red-500 fill-red-500' : 'text-gray-500']" />
                      </button>
                      <button class="text-xs text-gray-600 hover:underline" @click="openLikesModal(post)">
                        {{ post.likeCount }} likes
                      </button>
                    </div>
                    <button class="flex items-center space-x-1" @click="openCommentsModal(post)">
                      <MessageCircle class="h-4 w-4 text-gray-500" />
                      <span class="text-xs text-gray-600">{{ post.comments.length }} comments</span>
                    </button>
                    <button class="flex items-center space-x-1" @click="sharePost(post)">
                      <Share2 class="h-4 w-4 text-gray-500" />
                      <span class="text-xs text-gray-600">Share</span>
                    </button>
                    <button class="flex items-center space-x-1" @click="toggleSave(post)">
                      <Bookmark :class="['h-4 w-4', post.isSaved ? 'text-blue-600 fill-blue-600' : 'text-gray-500']" />
                      <span class="text-xs text-gray-600">Save</span>
                    </button>
                  </div>
                </div>
  
                <!-- Comments Preview -->
                <div v-if="post.comments.length > 0" class="space-y-2">
                  <div v-for="comment in post.comments.slice(0, 2)" :key="comment.id" class="flex items-start space-x-2">
                    <img :src="comment.user.avatar" :alt="comment.user.fullName" class="w-5 h-5 rounded-full mt-0.5" />
                    <div class="flex-1">
                      <div class="bg-gray-50 rounded-lg p-2">
                        <NuxtLink :to="`/profile/${comment.user.id}`" class="text-xs font-medium hover:underline">
                          {{ comment.user.fullName }}
                        </NuxtLink>
                        <p class="text-xs">{{ comment.text }}</p>
                      </div>
                      <span class="text-[10px] text-gray-500 mt-1 inline-block">
                        {{ formatTimeAgo(comment.timestamp) }}
                      </span>
                    </div>
                  </div>
  
                  <button v-if="post.comments.length > 2" class="text-xs text-blue-600 font-medium mt-1" @click="openCommentsModal(post)">
                    See all {{ post.comments.length }} comments
                  </button>
                </div>
  
                <!-- Add Comment Input -->
                <div class="flex items-center gap-2 mt-3 pt-2 border-t border-gray-100">
                  <img src="/images/placeholder.jpg?height=24&width=24" alt="Your avatar" class="w-6 h-6 rounded-full" />
                  <div class="flex-1 relative">
                    <input
                      type="text"
                      placeholder="Add a comment..."
                      class="w-full text-xs py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                      v-model="post.commentText"
                      @keyup.enter="addComment(post)"
                    />
                    <button v-if="post.commentText" class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-600" @click="addComment(post)">
                      <Send class="h-3 w-3" />
                    </button>
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
  
          <div v-if="!loading && posts.length === 0" class="flex flex-col items-center justify-center py-12 text-center">
            <p class="text-gray-500 mb-2">No posts available</p>
          </div>
        </div>
  
        <!-- Create Post Button -->
        <button
          class="fixed bottom-24 right-4 lg:right-[35%] md:bottom-4 rounded-full h-14 w-14 shadow-lg bg-gradient-to-r from-blue-600 to-blue-600 hover:shadow-xl transition-all duration-300 hover:scale-105 border-none z-40 flex items-center justify-center text-white"
          @click="isCreatePostOpen = true"
        >
          <Plus class="h-6 w-6" />
        </button>

         <!-- Media Viewer -->
      <Teleport to="body">
        <div v-if="activeMedia" class="fixed inset-0 z-[9999] bg-black/80 flex items-center justify-center p-4" @click="activeMedia = null">
          <div class="relative max-w-3xl w-full max-h-[80vh] bg-white rounded-lg overflow-hidden flex flex-col" @click.stop>
            <button class="absolute right-2 top-2 z-10 p-1 rounded-full bg-black/50 text-white" @click="activeMedia = null">
              <X class="h-6 w-6" />
            </button>
  
            <div class="flex-1 overflow-hidden relative">
              <div v-if="activeMedia.type === 'image'" class="relative h-[45vh] w-full">
                <img :src="activeMedia.url" alt="Media preview" class="w-full h-full object-contain" />
                <a
                  :href="activeMedia.url"
                  :download="`media-${activeMedia.id}`"
                  class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
                  @click.stop
                >
                  <Download class="h-5 w-5" />
                </a>
              </div>
              <div v-else class="relative">
                <video :src="activeMedia.url" controls class="w-full h-auto max-h-[45vh]"></video>
                <a
                  :href="activeMedia.url"
                  :download="`video-${activeMedia.id}`"
                  class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
                  @click.stop
                >
                  <Download class="h-5 w-5" />
                </a>
              </div>
  
              <!-- Media navigation -->
              <div v-if="activePost && activePost.media.length > 1">
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
                <div class="absolute bottom-2 left-1/2 -translate-x-1/2 bg-black/50 backdrop-blur-sm rounded-full px-3 py-1 text-white text-xs">
                  {{ activeMediaIndex + 1 }} / {{ activePost.media.length }}
                </div>
              </div>
            </div>
  
            <div class="p-4 border-t border-gray-200">
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center space-x-4">
                  <div class="flex items-center space-x-1">
                    <button class="p-1 rounded-full hover:bg-gray-100 transition-colors" @click.stop="toggleMediaLike">
                      <Heart :class="['h-4 w-4', activeMedia.isLiked ? 'text-red-500 fill-red-500' : 'text-gray-500']" />
                    </button>
                    <button class="text-xs text-gray-600 hover:underline" @click.stop="openMediaLikesModal">
                      {{ activeMedia.likeCount }} likes
                    </button>
                  </div>
                  <div class="flex items-center space-x-1">
                    <MessageCircle class="h-4 w-4 text-gray-500" />
                    <span class="text-xs text-gray-600">
                      {{ activeMedia.comments?.length || 0 }} comments
                    </span>
                  </div>
                </div>
              </div>
  
              <!-- Media comments -->
              <div v-if="activeMedia.comments && activeMedia.comments.length > 0" class="max-h-[20vh] overflow-y-auto mb-3">
                <h4 class="text-xs font-medium text-gray-500 mb-2">Comments</h4>
                <div class="space-y-2">
                  <div v-for="comment in activeMedia.comments" :key="comment.id" class="flex items-start space-x-2">
                    <img :src="comment.user.avatar" alt="User" class="w-6 h-6 rounded-full" />
                    <div class="flex-1">
                      <div class="bg-gray-50 rounded-lg p-2">
                        <div class="flex items-center justify-between">
                          <NuxtLink :to="`/profile/${comment.user.id}`" class="text-xs font-medium hover:underline">
                            {{ comment.user.fullName }}
                          </NuxtLink>
                          <button
                            v-if="comment.user.id !== 'current-user'"
                            :class="[
                              'text-[10px] h-5 rounded-full px-2 flex items-center',
                              comment.user.isFollowing ? 'border border-gray-200 text-gray-700' : 'bg-blue-600 text-white'
                            ]"
                            @click.stop="toggleUserFollow(comment.user)"
                          >
                            {{ comment.user.isFollowing ? 'Following' : 'Follow' }}
                          </button>
                        </div>
                        <p class="text-xs mt-1">{{ comment.text }}</p>
                      </div>
                      <div class="flex items-center mt-1 space-x-3">
                        <span class="text-[10px] text-gray-500">{{ formatTimeAgo(comment.timestamp) }}</span>
                        
                        
                      </div>
                    </div>
                  </div>
                </div>
              </div>
  
              <div class="flex items-center gap-2">
                <img src="/images/placeholder.jpg?height=24&width=24" alt="Your avatar" class="w-6 h-6 rounded-full" />
                <div class="flex-1 relative">
                  <input
                    type="text"
                    placeholder="Add a comment..."
                    class="w-full text-xs py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                    v-model="mediaCommentText"
                    @click.stop
                  />
                  <button v-if="mediaCommentText" class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-600" @click.stop="addMediaComment">
                    <Send class="h-3 w-3" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
  
      <!-- Create Post Modal -->
      <Teleport to="body">
        <div v-if="isCreatePostOpen" class="fixed inset-0 z-[9999] bg-black/50 backdrop-blur-sm flex items-center justify-center p-4" @click="isCreatePostOpen = false">
          <div class="bg-white rounded-xl max-w-lg w-full max-h-[90vh] overflow-hidden shadow-2xl transform transition-all duration-300 scale-100 opacity-100" @click.stop>
            <div class="p-4 border-b border-gray-100 flex items-center justify-between bg-gradient-to-r from-white to-gray-50">
              <h2 class="text-xl font-semibold bg-gradient-to-r from-blue-600 to-blue-600 bg-clip-text text-transparent">
                Create Post
              </h2>
              <button class="rounded-full hover:bg-gray-100 p-2" @click="isCreatePostOpen = false">
                <X class="h-5 w-5" />
              </button>
            </div>
  
            <div class="p-4 overflow-y-auto max-h-[calc(90vh-130px)]">
              <div class="space-y-4">
                <!-- Title input -->
                <div class="relative group">
                  <input
                    type="text"
                    placeholder="Post title"
                    class="w-full p-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-600 focus:border-transparent bg-gray-50 transition-all duration-200 group-hover:bg-white"
                    v-model="createPostTitle"
                  />
                  <div class="absolute bottom-0 left-0 w-0 h-0.5 bg-blue-600 transition-all duration-300 group-hover:w-full"></div>
                </div>
  
                <!-- Content textarea -->
                <div class="relative group">
                  <textarea
                    placeholder="What's on your mind?"
                    class="min-h-[180px] w-full resize-none border border-gray-200 bg-gray-50 transition-all duration-200 group-hover:bg-white focus:bg-white p-2 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-600"
                    v-model="createPostContent"
                  ></textarea>
                  <div class="absolute bottom-0 left-0 w-0 h-0.5 bg-blue-600 transition-all duration-300 group-hover:w-full"></div>
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
                      @click.stop="showEmojiPicker = !showEmojiPicker"
                    >
                      <Smile class="h-5 w-5 text-gray-500" />
                    </button>
  
                    <div
                      v-if="showEmojiPicker"
                      class="absolute bottom-12 left-0 bg-white rounded-lg shadow-lg border border-gray-200 p-2 z-50 w-64"
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
                        class="object-cover w-full h-full"
                      />
                      <div v-else class="flex items-center justify-center h-full">
                        <video :src="getFilePreview(file)" class="h-full w-full object-cover"></video>
                      </div>
                      <button
                        class="absolute top-1 right-1 bg-black/50 rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
                        @click.stop="removeMedia(index)"
                      >
                        <X class="h-3 w-3 text-white" />
                      </button>
                    </div>
                  </div>
  
                  <div class="flex items-center justify-between">
                    <button
                      class="border border-gray-200 rounded-md px-3 py-1 text-xs flex items-center gap-1 hover:bg-gray-50"
                      @click.stop="triggerFileInput"
                      :disabled="selectedMedia.length >= 14"
                    >
                      <Paperclip class="h-3 w-3" />
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
                    <span
                      v-for="category in createPostCategories"
                      :key="category"
                      class="px-2 py-1 gap-1 group bg-gray-100 text-gray-700 text-xs rounded-full flex items-center"
                    >
                      {{ category }}
                      <button
                        @click="removeCategory(category)"
                        class="ml-1 rounded-full hover:bg-gray-200 p-0.5 transition-colors"
                      >
                        <X class="h-3 w-3 text-gray-500 group-hover:text-gray-700" />
                      </button>
                    </span>
                  </div>
  
                  <div class="relative">
                    <div class="flex gap-2">
                      <div class="relative flex-1">
                        <input
                          type="text"
                          placeholder="Add a category..."
                          v-model="categoryInput"
                          class="pl-8 pr-4 py-2 w-full border border-gray-200 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                        />
                        <Tag class="absolute left-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                      </div>
                      <button
                        class="px-3 py-1 bg-blue-600 text-white rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                        @click="addCategory"
                        :disabled="!categoryInput.trim() || createPostCategories.includes(categoryInput.trim())"
                      >
                        Add
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
  
            <div class="p-4 border-t border-gray-100 flex justify-end bg-gradient-to-r from-gray-50 to-white">
              <button class="px-4 py-2 border border-gray-200 rounded-md mr-2 hover:bg-gray-50" @click="isCreatePostOpen = false">
                Cancel
              </button>
              <button
                :disabled="!createPostTitle.trim() || !createPostContent.trim() || isSubmitting"
                @click="handleCreatePost"
                :class="[
                  'px-4 py-2 rounded-md text-white bg-gradient-to-r from-blue-600 to-blue-600 hover:from-blue-700 hover:to-blue-700 transition-all duration-300',
                  (isSubmitting || !createPostTitle.trim() || !createPostContent.trim()) && 'opacity-80 cursor-not-allowed'
                ]"
              >
                <span v-if="isSubmitting" class="mr-2 h-4 w-4 rounded-full border-2 border-white border-t-transparent animate-spin inline-block"></span>
                {{ isSubmitting ? 'Posting...' : 'Post' }}
              </button>
            </div>
  
            <input
              type="file"
              ref="fileInputRef"
              class="hidden"
              multiple
              accept="image/*,video/*"
              @change="handleFileChange"
            />
          </div>
        </div>
      </Teleport>
  
      <!-- Likes Modal -->
      <Teleport to="body">
        <div v-if="activeLikesPost" class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4" @click="activeLikesPost = null">
          <div class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden" @click.stop>
            <div class="p-3 border-b border-gray-200 flex items-center justify-between">
              <h3 class="font-semibold">Liked by</h3>
              <button @click="activeLikesPost = null">
                <X class="h-5 w-5" />
              </button>
            </div>
            <div class="overflow-y-auto max-h-[60vh]">
              <div v-for="user in activeLikesPost.likedBy" :key="user.id" class="flex items-center justify-between p-3 border-b border-gray-100">
                <div class="flex items-center space-x-3">
                  <img
                    :src="user.avatar"
                    :alt="user.fullName"
                    class="w-10 h-10 rounded-full"
                  />
                  <div>
                    <NuxtLink :to="`/profile/${user.id}`" class="font-medium hover:underline">
                      {{ user.fullName }}
                    </NuxtLink>
                    <p class="text-xs text-gray-500">@{{ user.fullName.toLowerCase().replace(/\s+/g, "") }}</p>
                  </div>
                </div>
                <button
                  v-if="user.id !== 'current-user'"
                  :class="[
                    'text-xs h-7 rounded-full px-3 flex items-center gap-1',
                    user.isFollowing ? 'border border-gray-200 text-gray-700' : 'bg-blue-600 text-white'
                  ]"
                  @click.stop="toggleUserFollow(user)"
                >
                  <component :is="user.isFollowing ? Check : UserPlus" class="h-3 w-3" />
                  {{ user.isFollowing ? 'Following' : 'Follow' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
  
      <!-- Comments Modal -->
      <Teleport to="body">
        <div v-if="activeCommentsPost" class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4" @click="activeCommentsPost = null">
          <div class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden" @click.stop>
            <div class="p-3 border-b border-gray-200 flex items-center justify-between">
              <h3 class="font-semibold">Comments</h3>
              <button @click="activeCommentsPost = null">
                <X class="h-5 w-5" />
              </button>
            </div>
            <div class="overflow-y-auto max-h-[60vh] p-3 space-y-3">
              <div v-for="comment in activeCommentsPost.comments" :key="comment.id" class="flex items-start space-x-2">
                <img
                  :src="comment.user.avatar"
                  :alt="comment.user.fullName"
                  class="w-8 h-8 rounded-full mt-0.5"
                />
                <div class="flex-1">
                  <div class="bg-gray-50 rounded-lg p-2">
                    <div class="flex items-center justify-between mb-1">
                      <NuxtLink :to="`/profile/${comment.user.id}`" class="text-xs font-medium hover:underline">
                        {{ comment.user.fullName }}
                      </NuxtLink>
                      <button
                        v-if="comment.user.id !== 'current-user'"
                        :class="[
                          'text-[10px] h-5 rounded-full px-2 flex items-center',
                          comment.user.isFollowing ? 'border border-gray-200 text-gray-700' : 'bg-blue-600 text-white'
                        ]"
                        @click.stop="toggleUserFollow(comment.user)"
                      >
                        {{ comment.user.isFollowing ? 'Following' : 'Follow' }}
                      </button>
                    </div>
                    <p class="text-xs">{{ comment.text }}</p>
                  </div>
                  <div class="flex items-center mt-1 space-x-3">
                    <span class="text-[10px] text-gray-500">{{ formatTimeAgo(comment.timestamp) }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="p-3 border-t border-gray-200">
              <div class="flex items-center gap-2">
                <img src="/images/placeholder.jpg?height=24&width=24" alt="Your avatar" class="w-6 h-6 rounded-full" />
                <div class="flex-1 relative">
                  <input
                    type="text"
                    placeholder="Add a comment..."
                    class="w-full text-xs py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                    v-model="activeCommentsPost.commentText"
                    @click.stop
                  />
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
        <div v-if="activeMediaLikes" class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4" @click="activeMediaLikes = null">
          <div class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden" @click.stop>
            <div class="p-3 border-b border-gray-200 flex items-center justify-between">
              <h3 class="font-semibold">Liked by</h3>
              <button @click="activeMediaLikes = null">
                <X class="h-5 w-5" />
              </button>
            </div>
            <div class="overflow-y-auto max-h-[60vh]">
              <div v-for="(user, index) in mediaLikedUsers" :key="index" class="flex items-center justify-between p-3 border-b border-gray-100">
                <div class="flex items-center space-x-3">
                  <img
                    :src="user.avatar"
                    :alt="user.fullName"
                    class="w-10 h-10 rounded-full"
                  />
                  <div>
                    <NuxtLink :to="`/profile/${user.id}`" class="font-medium hover:underline">
                      {{ user.fullName }}
                    </NuxtLink>
                    <p class="text-xs text-gray-500">@{{ user.fullName.toLowerCase().replace(/\s+/g, "") }}</p>
                  </div>
                </div>
                <button
                  v-if="user.id !== 'current-user'"
                  :class="[
                    'text-xs h-7 rounded-full px-3 flex items-center gap-1',
                    user.isFollowing ? 'border border-gray-200 text-gray-700' : 'bg-blue-600 text-white'
                  ]"
                  @click.stop="toggleUserFollow(user)"
                >
                  <component :is="user.isFollowing ? Check : UserPlus" class="h-3 w-3" />
                  {{ user.isFollowing ? 'Following' : 'Follow' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
      </div>


</template>

<script setup>
  import { 
    Search, X, Clock, ArrowRight, Heart, MessageCircle, Share2, 
    Bookmark, Check, UserPlus, MoreHorizontal, Link2, Flag, Send,
    Plus, Home, Bell, User, BarChart2, Download, ChevronLeft, 
    ChevronRight, Loader2, ImageIcon, Smile, Paperclip, Tag, UserX
  } from 'lucide-vue-next';
  
  // State
  const posts = ref([]);
  const loading = ref(false);
  const page = ref(1);
  const isSearchOpen = ref(false);
 
 
  const searchInputRef = ref(null);
  const activeMedia = ref(null);
  const activePost = ref(null);
  const activeMediaIndex = ref(0);
  const mediaCommentText = ref('');
  const isCreatePostOpen = ref(false);
  const createPostTitle = ref('');
  const createPostContent = ref('');
  const createPostCategories = ref([]);
  const categoryInput = ref('');
  const showEmojiPicker = ref(false);
  const selectedMedia = ref([]);
  const fileInputRef = ref(null);
  const isSubmitting = ref(false);
  const activeLikesPost = ref(null);
  const activeCommentsPost = ref(null);
  const activeMediaLikes = ref(null);
  const mediaLikedUsers = ref([]);
  
  // Common emojis for quick access
  const commonEmojis = [
    "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙",
    "👍", "👎", "👏", "🙌", "🤝", "👊", "✌️", "🤞", "🤟", "🤘", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "💔", "❣️", "💕",
  ];
  
  // Sample user data with full names
  const users = Array.from({ length: 20 }, (_, i) => ({
    id: `user-${i + 1}`,
    fullName: [
      "Emma Johnson",
      "Liam Smith",
      "Olivia Williams",
      "Noah Brown",
      "Ava Jones",
      "Elijah Davis",
      "Sophia Miller",
      "James Wilson",
      "Charlotte Moore",
      "Benjamin Taylor",
      "Amelia Anderson",
      "Lucas Thomas",
      "Mia Jackson",
      "Mason White",
      "Harper Harris",
      "Ethan Martin",
      "Evelyn Thompson",
      "Alexander Garcia",
      "Abigail Martinez",
      "Michael Robinson",
    ][i],
    avatar: `/images/placeholder.jpg?height=40&width=40`,
    isFollowing: Math.random() > 0.5,
  }));
  
  // Generate replies for comments
  const generateReplies = (commentId, count) => {
    return Array.from({ length: count }, (_, i) => {
      return {
        id: `reply-${commentId}-${i}`,
        user: users[Math.floor(Math.random() * users.length)],
        text: [
          "Thanks for your insight!",
          "I agree with your point.",
          "Let's discuss this further in our next meeting.",
          "Great observation!",
          "I've been thinking the same thing.",
          "This is exactly what we need to focus on.",
        ][Math.floor(Math.random() * 6)],
        timestamp: new Date(Date.now() - Math.floor(Math.random() * 86400000 * 3)).toISOString(),
      }
    });
  };
  
  // Sample comments with replies
  const generateComments = (postId, count) => {
    return Array.from({ length: count }, (_, i) => {
      const comment = {
        id: `comment-${postId}-${i}`,
        user: users[Math.floor(Math.random() * users.length)],
        text: [
          "Great insight! Thanks for sharing.",
          "I completely agree with your analysis.",
          "This is exactly what our team needed to hear.",
          "Looking forward to discussing this further in our next meeting.",
          "Could you elaborate more on the second point?",
          "I've been thinking about this approach as well.",
          "Have you considered the impact on our Q4 strategy?",
          "This aligns perfectly with our company vision.",
        ][Math.floor(Math.random() * 8)],
        timestamp: new Date(Date.now() - Math.floor(Math.random() * 86400000 * 7)).toISOString(),
      };
      
      // Add replies to some comments
      if (Math.random() > 0.7) {
        comment.replies = generateReplies(comment.id, Math.floor(Math.random() * 3) + 1);
      }
      
      return comment;
    });
  };
  
  // Generate posts
  const generatePosts = (start, count) => {
    const categories = ["Marketing", "Finance", "Operations", "Leadership", "Technology", "HR", "Sales", "Strategy"];
  
    return Array.from({ length: count }, (_, i) => {
      const postId = start + i;
      const likeCount = Math.floor(Math.random() * 30);
      const commentCount = Math.floor(Math.random() * 15);
      const mediaCount = Math.floor(Math.random() * 14) + 1;
  
      // Assign 1-2 random categories to each post
      const numCategories = Math.floor(Math.random() * 2) + 1;
      const postCategories = Array.from(
        { length: numCategories },
        () => categories[Math.floor(Math.random() * categories.length)],
      ).filter((value, index, self) => self.indexOf(value) === index); // Remove duplicates
  
      // Generate random likes
      const likedBy = Array.from({ length: likeCount }, () => {
        const user = { ...users[Math.floor(Math.random() * users.length)] };
        user.isFollowing = Math.random() > 0.5;
        return user;
      });
  
      // Generate random comments
      const comments = generateComments(postId, commentCount);
  
      // Generate media with likes and comments
      const media = Array.from({ length: mediaCount }, (_, j) => {
        const mediaLikeCount = Math.floor(Math.random() * 20);
        const mediaCommentCount = Math.floor(Math.random() * 10);
        
        // Generate liked users for media
        const mediaLikedBy = Array.from({ length: mediaLikeCount }, () => {
          const user = { ...users[Math.floor(Math.random() * users.length)] };
          user.isFollowing = Math.random() > 0.5;
          return user;
        });
  
        return {
          id: `${postId}-${j}`,
          type: j < 12 ? "image" : "video",
          url: j < 12 ? `/images/placeholder.jpg?height=300&width=400` : "https://example.com/video.mp4",
          thumbnail: `/images/placeholder.jpg?height=150&width=200`,
          likeCount: mediaLikeCount,
          isLiked: false,
          comments: generateComments(`${postId}-${j}`, mediaCommentCount),
          likedBy: mediaLikedBy
        }
      }).slice(0, 14);
  
      return {
        id: postId,
        title: `Business Strategy Update ${postId}: ${["Market Analysis", "Quarterly Report", "Team Building", "Product Launch", "Industry Trends"][Math.floor(Math.random() * 5)]}`,
        author: users[Math.floor(Math.random() * users.length)],
        timestamp: new Date(Date.now() - postId * 3600000).toISOString(),
        content: [
          "Our latest market analysis shows significant growth opportunities in the APAC region. The consumer behavior data indicates a shift towards sustainable products, with a 27% increase in eco-friendly purchases over the last quarter. This trend is particularly strong among the 25-34 demographic, suggesting we should adjust our marketing strategy accordingly.",
          "The Q3 financial results exceeded expectations with a 15% revenue increase year-over-year. Our cost-cutting initiatives have resulted in a 7% reduction in operational expenses, improving our overall profit margins. The board has approved the expansion plan for the European market, with implementation scheduled to begin next month.",
          "I'm excited to share that our team building workshop last week was a tremendous success. The cross-departmental collaboration exercises resulted in three innovative product ideas that we're now exploring further. The feedback from participants was overwhelmingly positive, with 92% reporting improved communication with colleagues from other departments.",
          "We're thrilled to announce that our new product line will launch on November 15th. The marketing campaign will begin next week, focusing on digital channels and influencer partnerships. Early focus group testing shows a 85% positive response rate, significantly higher than our previous launches.",
          "The latest industry report highlights a shift towards AI-powered solutions in our sector. Our R&D team has prepared a comprehensive analysis of how we can leverage these technologies to enhance our product offerings. I've attached the full report for those interested in the technical details.",
        ][Math.floor(Math.random() * 5)],
        likeCount,
        likedBy,
        comments,
        media,
        categories: postCategories,
        isFollowing: Math.random() > 0.5,
        isLiked: false,
        isSaved: false,
        showDropdown: false,
        showFullDescription: false,
        showLikes: false,
        showComments: false,
        commentText: '',
      }
    });
  };
  
  // Load more posts
  const loadMorePosts = () => {
    if (loading.value) return;
  
    loading.value = true;
  
    // Simulate API call with timeout
    setTimeout(() => {
      const newPosts = generatePosts(page.value * 25 + 1, 25);
      posts.value = [...posts.value, ...newPosts];
      page.value++;
      loading.value = false;
    }, 1000);
  };
  
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
  const toggleFollow = (post) => {
    post.isFollowing = !post.isFollowing;
  };
  
  // Toggle user follow
  const toggleUserFollow = (user) => {
    user.isFollowing = !user.isFollowing;
  };
  
  // Toggle like
  const toggleLike = (post) => {
    post.isLiked = !post.isLiked;
    post.likeCount += post.isLiked ? 1 : -1;
    
    if (post.isLiked) {
      post.likedBy.unshift({
        id: 'current-user',
        fullName: 'You',
        avatar: '/images/placeholder.jpg?height=40&width=40',
        isFollowing: false
      });
    } else {
      post.likedBy = post.likedBy.filter(user => user.id !== 'current-user');
    }
  };
  
  // Toggle media like
  const toggleMediaLike = () => {
    if (!activeMedia.value) return;
    
    activeMedia.value.isLiked = !activeMedia.value.isLiked;
    activeMedia.value.likeCount += activeMedia.value.isLiked ? 1 : -1;
    
    // Update likedBy array for the media
    if (activeMedia.value.isLiked) {
      if (!activeMedia.value.likedBy) {
        activeMedia.value.likedBy = [];
      }
      activeMedia.value.likedBy.unshift({
        id: 'current-user',
        fullName: 'You',
        avatar: '/images/placeholder.jpg?height=40&width=40',
        isFollowing: false
      });
    } else if (activeMedia.value.likedBy) {
      activeMedia.value.likedBy = activeMedia.value.likedBy.filter(user => user.id !== 'current-user');
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
    posts.value.forEach(p => {
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
    alert('Link copied to clipboard');
    post.showDropdown = false;
  };
  
  // Share post
  const sharePost = (post) => {
    const postUrl = `${window.location.origin}/post/${post.id}`;
    
    if (navigator.share && navigator.canShare) {
      navigator.share({
        title: post.title,
        text: post.content.substring(0, 100) + (post.content.length > 100 ? "..." : ""),
        url: postUrl,
      }).catch(error => console.error("Error sharing:", error));
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
  };
  
  // Open media likes modal
  const openMediaLikesModal = () => {
    if (!activeMedia.value || !activeMedia.value.likedBy) return;
    
    mediaLikedUsers.value = activeMedia.value.likedBy;
    activeMediaLikes.value = activeMedia.value;
  };
  
  // Add comment
  const addComment = (post) => {
    if (!post.commentText.trim()) return;
    
    const newComment = {
      id: `comment-${Date.now()}`,
      user: {
        id: 'current-user',
        fullName: 'You',
        avatar: '/images/placeholder.jpg?height=40&width=40'
      },
      text: post.commentText,
      timestamp: new Date().toISOString()
    };
    
    post.comments.unshift(newComment);
    post.commentText = '';
    
    if (activeCommentsPost.value === post) {
      activeCommentsPost.value = { ...post };
    }
  };
  
  // Add media comment
  const addMediaComment = () => {
    if (!mediaCommentText.value.trim() || !activeMedia.value) return;
    
    const newComment = {
      id: `media-comment-${Date.now()}`,
      user: {
        id: 'current-user',
        fullName: 'You',
        avatar: '/images/placeholder.jpg?height=40&width=40'
      },
      text: mediaCommentText.value,
      timestamp: new Date().toISOString()
    };
    
    if (!activeMedia.value.comments) {
      activeMedia.value.comments = [];
    }
    
    activeMedia.value.comments.unshift(newComment);
    mediaCommentText.value = '';
  };
  
  // Open media
  const openMedia = (post, index) => {
    activePost.value = post;
    activeMediaIndex.value = index;
    activeMedia.value = post.media[index];
  };
  
  // Navigate media
  const navigateMedia = (direction) => {
    if (!activePost.value || !activeMedia.value) return;
    
    const currentIndex = activeMediaIndex.value;
    const totalMedia = activePost.value.media.length;
    
    if (direction === 'prev') {
      activeMediaIndex.value = (currentIndex - 1 + totalMedia) % totalMedia;
    } else {
      activeMediaIndex.value = (currentIndex + 1) % totalMedia;
    }
    
    activeMedia.value = activePost.value.media[activeMediaIndex.value];
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
    const validFiles = newFiles.filter(file => {
      const isImage = file.type.startsWith('image/');
      const isVideo = file.type.startsWith('video/');
  
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
    const currentImages = selectedMedia.value.filter(file => file.type.startsWith('image/')).length;
    const currentVideos = selectedMedia.value.filter(file => file.type.startsWith('video/')).length;
  
    const newImages = validFiles.filter(file => file.type.startsWith('image/'));
    const newVideos = validFiles.filter(file => file.type.startsWith('video/'));
  
    if (currentImages + newImages.length > 12) {
      alert('Maximum 12 images allowed');
      return;
    }
  
    if (currentVideos + newVideos.length > 2) {
      alert('Maximum 2 videos allowed');
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
    if (categoryInput.value.trim() && !createPostCategories.value.includes(categoryInput.value.trim())) {
      createPostCategories.value.push(categoryInput.value.trim());
      categoryInput.value = '';
    }
  };
  
  const removeCategory = (category) => {
    createPostCategories.value = createPostCategories.value.filter(c => c !== category);
  };
  
  const handleCreatePost = () => {
    if (!createPostTitle.value.trim() || !createPostContent.value.trim()) return;
  
    isSubmitting.value = true;
  
    // Simulate post creation
    setTimeout(() => {
      // Create new post
      const newPost = {
        id: Date.now(),
        title: createPostTitle.value,
        author: {
          id: 'current-user',
          fullName: 'You',
          avatar: '/images/placeholder.jpg?height=40&width=40',
          verified: false
        },
        timestamp: new Date().toISOString(),
        content: createPostContent.value,
        likeCount: 0,
        likedBy: [],
        comments: [],
        media: selectedMedia.value.map((file, index) => ({
          id: `new-${Date.now()}-${index}`,
          type: file.type.startsWith('image/') ? 'image' : 'video',
          url: getFilePreview(file),
          thumbnail: getFilePreview(file),
          likeCount: 0,
          isLiked: false,
          comments: [],
          likedBy: []
        })),
        categories: createPostCategories.value,
        isFollowing: false,
        isLiked: false,
        isSaved: false,
        showDropdown: false,
        showFullDescription: false,
        showLikes: false,
        showComments: false,
        commentText: '',
      };
  
      // Add to posts
      posts.value.unshift(newPost);
      
      // Reset form
      createPostTitle.value = '';
      createPostContent.value = '';
      selectedMedia.value = [];
      createPostCategories.value = [];
      categoryInput.value = '';
      isSubmitting.value = false;
      isCreatePostOpen.value = false;
    }, 1500);
  };
  
  // Initialize
  onMounted(() => {
    // Initialize posts
    posts.value = generatePosts(1, 25);
    
    // Implement infinite scroll
    window.addEventListener('scroll', () => {
      if (window.innerHeight + window.scrollY >= document.body.offsetHeight - 500 && !loading.value) {
        loadMorePosts();
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