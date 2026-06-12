<template>
  <NuxtLink
    :to="`/sale/${post.slug}`"
    class="group flex flex-col bg-white rounded-lg border border-gray-200 overflow-hidden hover:border-emerald-300 hover:shadow-[0_2px_12px_rgba(16,185,129,0.12)] transition-all duration-150"
  >
    <!-- Image -->
    <div class="relative aspect-[4/3] bg-gray-100 overflow-hidden">
      <img
        v-if="image"
        :src="image"
        :alt="title"
        loading="lazy"
        class="w-full h-full object-cover group-hover:scale-[1.04] transition-transform duration-300"
      />
      <div v-else class="absolute inset-0 flex items-center justify-center text-gray-300">
        <UIcon name="i-heroicons-photo" class="h-8 w-8" />
      </div>

      <span
        v-if="conditionLabel"
        class="absolute top-1.5 left-1.5 px-1.5 py-0.5 rounded bg-black/65 text-white text-[10px] font-semibold tracking-wide"
      >{{ conditionLabel }}</span>

      <span
        v-if="post.negotiable"
        class="absolute bottom-1.5 left-1.5 px-1.5 py-0.5 rounded bg-emerald-600/90 text-white text-[10px] font-semibold"
      >{{ t("sale_card_negotiable") }}</span>
    </div>

    <!-- Body -->
    <div class="p-2 sm:p-2.5 flex flex-col gap-0.5 flex-1">
      <p class="font-bold text-[15px] leading-tight text-gray-900">
        <span v-if="post.price">৳{{ formatPrice(post.price) }}</span>
        <span v-else class="text-[13px] font-semibold text-gray-500">{{ t("sale_card_contact") }}</span>
      </p>
      <h3 class="text-[13px] text-gray-700 leading-snug line-clamp-2 group-hover:text-emerald-700 min-h-[34px]">
        {{ title }}
      </h3>
      <div class="mt-auto pt-1 flex items-center justify-between text-[11px] text-gray-400">
        <span class="flex items-center gap-0.5 truncate max-w-[58%]">
          <UIcon name="i-heroicons-map-pin" class="h-3 w-3 flex-shrink-0" />
          <span class="truncate">{{ location }}</span>
        </span>
        <span class="flex-shrink-0">{{ time }}</span>
      </div>
    </div>
  </NuxtLink>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  post: { type: Object, required: true },
});

const { t, locale } = useI18n();

const image = computed(
  () => props.post.main_image || (props.post.images && props.post.images[0]) || null
);

const title = computed(() => {
  const t = props.post.title || "";
  return t.charAt(0).toUpperCase() + t.slice(1);
});

const location = computed(
  () => props.post.district || props.post.division || props.post.area || t("all_over_bangladesh")
);

const CONDITION_KEYS = {
  brand_new: "sale_cond_brand_new",
  new: "sale_cond_new",
  like_new: "sale_cond_like_new",
  used: "sale_cond_used",
  good: "sale_cond_good",
  fair: "sale_cond_fair",
  for_parts: "sale_cond_for_parts",
  refurbished: "sale_cond_refurbished",
  poor: "sale_cond_poor",
};
const conditionLabel = computed(() => {
  const c = (props.post.condition || "").toString().toLowerCase().replace(/[\s-]+/g, "_");
  if (!c) return "";
  const key = CONDITION_KEYS[c];
  return key ? t(key) : props.post.condition;
});

const time = computed(() => {
  const d = props.post.created_at ? new Date(props.post.created_at) : null;
  if (!d || isNaN(d)) return "";
  const diff = (Date.now() - d.getTime()) / 1000;
  if (diff < 3600) return `${Math.max(1, Math.floor(diff / 60))} ${t("sale_time_min")}`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} ${t("sale_time_hr")}`;
  if (diff < 2592000) return `${Math.floor(diff / 86400)} ${t("sale_time_day")}`;
  return d.toLocaleDateString(locale.value === "bn" ? "bn-BD" : "en-US", {
    day: "numeric",
    month: "short",
  });
});

function formatPrice(price) {
  return Number(price || 0).toLocaleString("en-US");
}
</script>
