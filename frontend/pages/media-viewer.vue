<template>
	<section>
		{{ router.query.url }}

		<NuxtImg
			:src="router.query.url"
			class="w-full max-w-xl"
			v-if="router.query.type == 'image'"
		/>

		<video
			:src="router.query.url"
			class="w-full max-w-xl"
			v-if="router.query.type == 'video'"
			controls
			autoplay
		></video>
	</section>
</template>

<script setup>
const router = useRoute();
console.log(router);
</script>

<style scoped></style>
