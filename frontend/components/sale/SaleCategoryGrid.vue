<template>
  <section v-if="categories && categories.length" class="bg-white rounded-xl border border-gray-200 p-3 sm:p-3.5">
    <div class="flex items-center justify-between mb-2.5">
      <h2 class="text-[14px] sm:text-[15px] font-bold text-gray-900 flex items-center gap-1.5">
        <UIcon name="i-heroicons-squares-2x2" class="h-4 w-4 text-emerald-600" />
        ক্যাটাগরি থেকে খুঁজুন
      </h2>
      <div class="flex items-center gap-1.5">
        <button
          v-if="activeId"
          @click="$emit('clear')"
          class="text-[11px] font-medium text-emerald-600 hover:text-emerald-700 flex items-center gap-0.5"
        >
          <UIcon name="i-heroicons-x-mark" class="h-3.5 w-3.5" />
          সব
        </button>
        <button
          @click="scrollBy(-1)"
          class="h-6 w-6 rounded-full border border-gray-200 flex items-center justify-center text-gray-500 hover:bg-gray-50 hover:text-emerald-600"
          aria-label="আগের"
        >
          <UIcon name="i-heroicons-chevron-left" class="h-3.5 w-3.5" />
        </button>
        <button
          @click="scrollBy(1)"
          class="h-6 w-6 rounded-full border border-gray-200 flex items-center justify-center text-gray-500 hover:bg-gray-50 hover:text-emerald-600"
          aria-label="পরের"
        >
          <UIcon name="i-heroicons-chevron-right" class="h-3.5 w-3.5" />
        </button>
      </div>
    </div>

    <div
      ref="rail"
      class="flex gap-2 overflow-x-auto pb-0.5 snap-x [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
    >
      <button
        v-for="cat in categories"
        :key="cat.id"
        @click="$emit('select', cat.id)"
        :class="[
          'group flex-shrink-0 w-28 snap-start flex flex-col items-center gap-1.5 py-3 px-1.5 rounded-lg border transition-all duration-150',
          isActive(cat.id)
            ? 'border-emerald-500 bg-emerald-50'
            : 'border-gray-200 bg-gray-50/60 hover:border-emerald-300 hover:bg-emerald-50/50',
        ]"
      >
        <span
          :class="[
            'h-14 w-14 rounded-full flex items-center justify-center overflow-hidden transition-colors',
            isActive(cat.id) ? 'bg-emerald-100' : 'bg-white group-hover:bg-emerald-50 border border-gray-100',
          ]"
        >
          <img
            v-if="cat.icon && !failed[cat.id]"
            :src="cat.icon"
            :alt="cat.name"
            loading="lazy"
            class="h-9 w-9 object-contain"
            @error="failed[cat.id] = true"
          />
          <UIcon
            v-else
            :name="iconFor(cat.name)"
            :class="['h-7 w-7', isActive(cat.id) ? 'text-emerald-600' : 'text-gray-500 group-hover:text-emerald-600']"
          />
        </span>
        <span class="text-[11.5px] font-medium text-gray-700 leading-tight text-center break-words w-full min-h-[2.4em] flex items-center justify-center">{{ cat.name }}</span>
        <span class="text-[10px] text-gray-400 leading-none">{{ cat.post_count || 0 }}টি</span>
      </button>
    </div>
  </section>
</template>

<script setup>
import { ref, reactive } from "vue";

const props = defineProps({
  categories: { type: Array, default: () => [] },
  activeId: { type: [String, Number], default: null },
});
defineEmits(["select", "clear"]);

// Tracks category ids whose icon image failed to load, so we fall back to a glyph.
const failed = reactive({});

const rail = ref(null);
function scrollBy(dir) {
  if (rail.value) rail.value.scrollBy({ left: dir * 360, behavior: "smooth" });
}

function isActive(id) {
  return props.activeId != null && String(props.activeId) === String(id);
}

// Map a Bangla/English category name to a sensible Heroicon by keyword.
const ICON_RULES = [
  { kw: ["মোবাইল", "ফোন", "mobile", "phone"], icon: "i-heroicons-device-phone-mobile" },
  { kw: ["গাড়ি", "কার", "car", "vehicle", "যান"], icon: "i-heroicons-truck" },
  { kw: ["বাইক", "মোটর", "bike", "motor", "সাইকেল", "cycle"], icon: "i-heroicons-rocket-launch" },
  { kw: ["কম্পিউটার", "ল্যাপটপ", "computer", "laptop", "pc"], icon: "i-heroicons-computer-desktop" },
  { kw: ["ইলেকট্রন", "electronic", "টিভি", "tv", "gadget", "গ্যাজেট"], icon: "i-heroicons-tv" },
  { kw: ["ফার্নিচার", "আসবাব", "furniture", "sofa", "চেয়ার"], icon: "i-heroicons-rectangle-group" },
  { kw: ["বাড়ি", "প্রপার্টি", "জমি", "property", "home", "flat", "ফ্ল্যাট", "rent", "ভাড়া"], icon: "i-heroicons-home-modern" },
  { kw: ["পোশাক", "কাপড়", "fashion", "cloth", "dress", "ফ্যাশন", "জুতা", "shoe"], icon: "i-heroicons-shopping-bag" },
  { kw: ["চাকরি", "job", "নিয়োগ", "career"], icon: "i-heroicons-briefcase" },
  { kw: ["পশু", "pet", "animal", "প্রাণী", "পাখি", "bird"], icon: "i-heroicons-bug-ant" },
  { kw: ["বই", "book", "শিক্ষা", "education", "course", "কোর্স"], icon: "i-heroicons-book-open" },
  { kw: ["খাবার", "food", "grocery", "মুদি"], icon: "i-heroicons-cake" },
  { kw: ["সেবা", "service"], icon: "i-heroicons-wrench-screwdriver" },
  { kw: ["ক্যামেরা", "camera"], icon: "i-heroicons-camera" },
  { kw: ["খেলা", "sport", "game", "গেম", "খেলনা", "toy"], icon: "i-heroicons-trophy" },
  { kw: ["গহনা", "jewel", "ঘড়ি", "watch"], icon: "i-heroicons-sparkles" },
  { kw: ["স্বাস্থ্য", "health", "beauty", "সৌন্দর্য"], icon: "i-heroicons-heart" },
  { kw: ["কৃষি", "agri", "farm"], icon: "i-heroicons-sun" },
  { kw: ["সংগীত", "music", "যন্ত্র", "instrument"], icon: "i-heroicons-musical-note" },
];

function iconFor(name) {
  const n = (name || "").toLowerCase();
  for (const rule of ICON_RULES) {
    if (rule.kw.some((k) => n.includes(k.toLowerCase()))) return rule.icon;
  }
  return "i-heroicons-tag";
}
</script>
