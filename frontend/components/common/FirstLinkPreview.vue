<template>
  <div v-if="url" :class="marginClass">
    <CommonLinkPreviewCard :url="url" />
  </div>
</template>

<script setup>
const props = defineProps({
  text: {
    type: String,
    required: true,
  },
  marginClass: {
    type: String,
    default: 'mt-2',
  },
})

const { extractFirstUrl } = useLinkPreview()

const url = computed(() => extractFirstUrl(props.text))
</script>
