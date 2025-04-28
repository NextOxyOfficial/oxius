<template>
  <div class="mb-3">
    <div
      class="relative overflow-hidden rounded-lg"
      :class="{
        'grid gap-1': post.post_media.length > 1,
        'grid-cols-2':
          post.post_media.length === 2 || post.post_media.length >= 4,
        'grid-rows-2': post.post_media.length >= 4,
        'h-[320px] sm:h-[400px]': post.post_media.length === 1,
        'h-[460px] sm:h-[520px]':
          post.post_media.length >= 2 && post.post_media.length <= 3,
        'h-[400px] sm:h-[500px]': post.post_media.length >= 4,
      }"
    >
      <!-- Single Image Layout -->
      <template v-if="post.post_media.length === 1">
        <div
          class="relative w-full h-full cursor-pointer overflow-hidden transition-transform hover:scale-[1.02]"
          @click="$emit('open-media', post, 0)"
        >
          <img
            :src="post.post_media[0].image"
            alt="Media"
            class="h-full w-full object-cover"
          />
          <div
            v-if="post.post_media[0].type === 'video'"
            class="absolute inset-0 flex items-center justify-center"
          >
            <div
              class="h-12 w-12 rounded-full bg-black/50 flex items-center justify-center"
            >
              <div
                class="h-0 w-0 border-y-8 border-y-transparent border-l-12 border-l-white ml-1"
              ></div>
            </div>
          </div>
        </div>
      </template>

      <!-- Two Images Layout -->
      <template v-else-if="post.post_media.length === 2">
        <div
          v-for="(media, mediaIndex) in post.post_media.slice(0, 2)"
          :key="media.id"
          class="relative h-full cursor-pointer overflow-hidden transition-transform hover:scale-[1.02]"
          @click="$emit('open-media', post, mediaIndex)"
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
              class="h-8 w-8 rounded-full bg-black/50 flex items-center justify-center"
            >
              <div
                class="h-0 w-0 border-y-4 border-y-transparent border-l-6 border-l-white ml-0.5"
              ></div>
            </div>
          </div>
        </div>
      </template>

      <!-- Three Images Layout -->
      <template v-else-if="post.post_media.length === 3">
        <!-- First image - large, full width -->
        <div
          class="relative col-span-2 h-[240px] sm:h-[300px] cursor-pointer overflow-hidden transition-transform hover:scale-[1.02]"
          @click="$emit('open-media', post, 0)"
        >
          <img
            :src="post.post_media[0].image"
            :alt="'Media 1'"
            class="h-full w-full object-cover"
          />
          <div
            v-if="post.post_media[0].type === 'video'"
            class="absolute inset-0 flex items-center justify-center"
          >
            <div
              class="h-8 w-8 rounded-full bg-black/50 flex items-center justify-center"
            >
              <div
                class="h-0 w-0 border-y-4 border-y-transparent border-l-6 border-l-white ml-0.5"
              ></div>
            </div>
          </div>
        </div>

        <!-- Second and third images - side by side -->
        <div class="grid grid-cols-2 gap-1" style="height: 200px">
          <div
            v-for="(media, mediaIndex) in post.post_media.slice(1, 3)"
            :key="media.id"
            class="relative h-full cursor-pointer overflow-hidden transition-transform hover:scale-[1.02]"
            @click="$emit('open-media', post, mediaIndex + 1)"
          >
            <img
              :src="media.image"
              :alt="`Media ${mediaIndex + 2}`"
              class="h-full w-full object-cover"
            />
            <div
              v-if="media.type === 'video'"
              class="absolute inset-0 flex items-center justify-center"
            >
              <div
                class="h-6 w-6 rounded-full bg-black/50 flex items-center justify-center"
              >
                <div
                  class="h-0 w-0 border-y-3 border-y-transparent border-l-4 border-l-white ml-0.5"
                ></div>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- Four or more images - Grid Layout -->
      <template v-else>
        <div
          v-for="(media, mediaIndex) in post.post_media.slice(0, 4)"
          :key="media.id"
          class="relative aspect-square cursor-pointer overflow-hidden transition-transform hover:scale-[1.02]"
          @click="$emit('open-media', post, mediaIndex)"
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
              class="h-6 w-6 rounded-full bg-black/50 flex items-center justify-center"
            >
              <div
                class="h-0 w-0 border-y-3 border-y-transparent border-l-4 border-l-white ml-0.5"
              ></div>
            </div>
          </div>

          <!-- Show +X more overlay on the 4th image if there are more than 4 -->
          <div
            v-if="mediaIndex === 3 && post.post_media.length > 4"
            class="absolute inset-0 bg-black/60 flex items-center justify-center"
          >
            <span class="text-white font-medium text-lg"
              >+{{ post.post_media.length - 4 }}</span
            >
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
defineProps({
  post: {
    type: Object,
    required: true
  }
});

defineEmits(['open-media']);
</script>
