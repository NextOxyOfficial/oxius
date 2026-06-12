<template>
  <section v-if="posts && posts.length" class="bg-white rounded-xl border border-gray-200 p-3 sm:p-4">
    <div class="flex items-center justify-between mb-3">
      <h2 class="text-[15px] sm:text-base font-bold text-gray-900 flex items-center gap-1.5">
        <UIcon :name="icon" :class="['h-5 w-5', iconColor]" />
        {{ title }}
      </h2>
      <div class="flex items-center gap-1">
        <button
          @click="scrollBy(-1)"
          class="h-7 w-7 rounded-full border border-gray-200 flex items-center justify-center text-gray-500 hover:bg-gray-50 hover:text-emerald-600"
          aria-label="আগের"
        >
          <UIcon name="i-heroicons-chevron-left" class="h-4 w-4" />
        </button>
        <button
          @click="scrollBy(1)"
          class="h-7 w-7 rounded-full border border-gray-200 flex items-center justify-center text-gray-500 hover:bg-gray-50 hover:text-emerald-600"
          aria-label="পরের"
        >
          <UIcon name="i-heroicons-chevron-right" class="h-4 w-4" />
        </button>
      </div>
    </div>

    <div
      ref="rail"
      class="flex gap-2 overflow-x-auto pb-1 snap-x [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
    >
      <div
        v-for="post in posts"
        :key="post.id || post.slug"
        class="relative w-40 sm:w-44 flex-shrink-0 snap-start"
      >
        <span
          v-if="post.views"
          class="absolute z-10 top-1.5 right-1.5 px-1.5 py-0.5 rounded bg-white/90 text-gray-700 text-[10px] font-semibold flex items-center gap-0.5 shadow-sm"
        >
          <UIcon name="i-heroicons-eye" class="h-3 w-3" />{{ post.views }}
        </span>
        <SaleProductCard :post="post" />
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref } from "vue";
import SaleProductCard from "~/components/sale/SaleProductCard.vue";

defineProps({
  posts: { type: Array, default: () => [] },
  title: { type: String, default: "ট্রেন্ডিং পণ্য" },
  icon: { type: String, default: "i-heroicons-fire" },
  iconColor: { type: String, default: "text-orange-500" },
});

const rail = ref(null);
function scrollBy(dir) {
  if (rail.value) rail.value.scrollBy({ left: dir * 320, behavior: "smooth" });
}
</script>
