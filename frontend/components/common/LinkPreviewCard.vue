<template>
  <a
    v-if="data"
    :href="data.url"
    target="_blank"
    rel="noopener noreferrer"
    class="block rounded-xl border border-slate-200 bg-white overflow-hidden hover:bg-slate-50 transition-colors"
  >
    <div class="flex">
      <div class="w-[92px] h-[92px] bg-slate-100 flex items-center justify-center overflow-hidden">
        <img
          v-if="data.imageUrl"
          :src="data.imageUrl"
          alt="preview"
          class="w-full h-full object-cover"
          @error="onImageError"
        />
        <UIcon
          v-else
          name="i-heroicons-link"
          class="w-6 h-6 text-slate-400"
        />
      </div>

      <div class="flex-1 p-3">
        <div v-if="data.siteName" class="text-[11px] font-semibold text-slate-500 truncate">
          {{ data.siteName }}
        </div>
        <div v-if="data.title" class="mt-1 text-[13px] font-bold text-slate-900 line-clamp-2">
          {{ data.title }}
        </div>
        <div v-if="data.description" class="mt-1 text-[12px] text-slate-600 line-clamp-2">
          {{ data.description }}
        </div>
      </div>
    </div>
  </a>

  <div
    v-else-if="loading"
    class="h-[78px] rounded-xl border border-slate-200 bg-slate-100 p-3"
  >
    <div class="flex items-center gap-3">
      <div class="w-[54px] h-[54px] rounded-lg bg-slate-200"></div>
      <div class="flex-1">
        <div class="h-3 rounded bg-slate-200 w-5/6"></div>
        <div class="h-3 rounded bg-slate-200 w-2/3 mt-2"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  url: {
    type: String,
    required: true,
  },
})

const { getPreview } = useLinkPreview()

const loading = ref(false)
const data = ref(null)

watchEffect(async () => {
  const url = props.url
  if (!url) return

  loading.value = true
  try {
    data.value = await getPreview(url)
  } finally {
    loading.value = false
  }
})

const onImageError = (e) => {
  if (e?.target) {
    e.target.style.display = 'none'
  }
}
</script>
