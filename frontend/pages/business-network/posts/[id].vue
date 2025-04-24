<template>
    <UContainer class="mt-16 flex-1 ">
        <BusinessNetworkPost :posts="posts" :id="user?.user?.id" />
    </UContainer>
</template>
<script setup>
definePageMeta({
  layout: "adsy-business-network",
});
const posts = ref([])
const {get} = useApi()
const {user} = useAuth()
const { id } = useRoute().params
const { data, error } = await get(`/bn/posts/${id}/`)
posts.value.push(data)
if (error) {
    console.error('Error fetching post:', error)
}
</script>