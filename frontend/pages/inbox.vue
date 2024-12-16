<template>
	<div class="min-h-[50vh]">
		<UContainer>
			<p class="text-2xl font-bold pb-6 border-b text-center mx-auto">In Box</p>
			<!-- showing message -->
			<div v-for="message in messages" :key="message.id">
				<div class="flex items-center justify-between gap-3 py-2">
					<!-- <p>ID: 45648798</p> -->
					<p class="font-semibold">
						{{ message.title }}
					</p>
					<p>{{ message.created_at }}</p>
					<UButton
						color="white"
						label="Show Message"
						trailing-icon="i-heroicons-chevron-down-20-solid"
						class="button"
						@click="toggleMsg = !toggleMsg"
					/>
				</div>
				<div class="message" v-if="toggleMsg">
					<UCard>
						<p>
							{{ message.message }}
						</p>
					</UCard>
				</div>
			</div>
		</UContainer>
	</div>
</template>

<script setup>
const toggleMsg = ref(false);
const messages = ref([]);
const { get } = useApi();

async function getAdminMessages() {
	const res = await get("/admin-notice/");
	console.log(res);
	messages.value = res.data;
}
getAdminMessages();
</script>

<style lang="scss" scoped></style>
