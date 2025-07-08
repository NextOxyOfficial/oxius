<template>
  <div
    class="bg-white rounded-xl border border-gray-200 overflow-hidden transition-all duration-300"
  >
    <div class="px-3 py-5">
      <!-- Post Header -->
      <PostHeader
        :post="post"
        :user="user"
        @toggle-follow="$emit('toggle-follow', post)"
        @toggle-dropdown="$emit('toggle-dropdown', post)"
        @toggle-save="$emit('toggle-save', post)"
        @copy-link="$emit('copy-link', post)"
        @post-updated="$emit('post-updated', $event)"
      />

      <!-- Post Title -->
      <NuxtLink
        :to="`/business-network/posts/${post.slug}`"
        class="block text-base font-semibold mb-1 hover:text-blue-600 transition-colors"
      >
        {{ post.title }}
      </NuxtLink>

      <!-- Tags -->
      <div v-if="post?.post_tags?.length > 0" class="flex flex-wrap gap-1 mb-2">
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
            'text-base text-gray-800',
            !post.showFullDescription && 'line-clamp-4',
          ]"
          v-html="post.content"
        ></p>
        <button
          v-if="post?.content?.length > 160"
          class="text-sm text-blue-600 font-medium mt-1"
          @click="$emit('toggle-description', post)"
        >
          {{ post.showFullDescription ? "Read less" : "Read more" }}
        </button>
      </div>

      <!-- Media Gallery with Professional Layout -->
      <PostMediaGallery
        v-if="post?.post_media?.length > 0"
        :post="post"
        @open-media="$emit('open-media', post, $event)"
      />

      <!-- Post Actions -->
      <PostActions
        :post="post"
        :user="user"
        @toggle-like="$emit('toggle-like', post)"
        @open-likes-modal="$emit('open-likes-modal', post)"
        @open-comments-modal="$emit('open-comments-modal', post)"
        @share-post="$emit('share-post', post)"
        @toggle-save="$emit('toggle-save', post)"
      />
      <!-- Comments Preview -->
      <PostComments
        v-if="(post?.comment_count || 0) > 0"
        :post="post"
        :user="user"
        @open-comments-modal="$emit('open-comments-modal', post)"
        @edit-comment="$emit('edit-comment', post, $event)"
        @delete-comment="$emit('delete-comment', post, $event)"
        @cancel-edit-comment="$emit('cancel-edit-comment', $event)"
        @save-edit-comment="$emit('save-edit-comment', post, $event)"
      /><!-- Add Comment Input -->
      <PostCommentInput
        v-if="user"
        :post="post"
        :user="user"
        @add-comment="$emit('add-comment', post)"
        @handle-comment-input="$emit('handle-comment-input', $event, post)"
        @handle-mention-keydown="$emit('handle-mention-keydown', $event, post)"
        @select-mention="$emit('select-mention', $event, post)"
      />
    </div>
  </div>
</template>

<script setup>
defineProps({
  post: {
    type: Object,
    required: true,
  },
  user: {
    type: Object,
    default: null,
  },
});

defineEmits([
  "toggle-follow",
  "toggle-dropdown",
  "toggle-save",
  "copy-link",
  "toggle-description",
  "open-media",
  "toggle-like",
  "open-likes-modal",
  "open-comments-modal",
  "share-post",
  "edit-comment",
  "delete-comment",
  "cancel-edit-comment",
  "save-edit-comment",
  "add-comment",
  "handle-comment-input",
  "handle-mention-keydown",
  "select-mention",
  "post-updated",
]);
</script>
