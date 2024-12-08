<template>
	<UCard
		:ui="{
			ring: '',
			divide: 'divide-y divide-gray-100 dark:divide-gray-800',
			header: {
				background: 'bg-slate-50',
			},
			rounded: 'rounded-lg',
		}"
		v-if="gig"
	>
		<template #header>
			<div class="flex items-start justify-between">
				<div>
					<div
						class="text-base font-semibold leading-6 text-gray-900 dark:text-white mb-4 flex gap-3"
					>
						<div class="w-8">
							<UIcon name="i-unjs:giget" class="text-3xl mt-1.5" />
						</div>
						<span class="text-2xl flex-1">
							{{ gig.title }}
						</span>
					</div>
					<p
						class="text-lg font-bold text-green-900 inline-flex items-center pl-5"
					>
						Earn:
						<span class="inline-flex items-center"
							><UIcon name="i-mdi:currency-bdt" class="text-xl" />{{
								gig.price
							}}</span
						>
					</p>
				</div>
				<UButton
					color="gray"
					variant="ghost"
					icon="i-heroicons-x-mark-20-solid"
					class="-my-1"
					@click="emit('close')"
				/>
			</div>
		</template>

		<div class="space-y-2 px-6 pb-8">
			<p class="text-2xl font-medium">Instruction</p>

			<p class="text-base text-justify">
				{{ gig.instructions }}
			</p>
			<!-- <UDivider label="" class="pt-4" /> -->
			<p class="text-2xl font-medium !mt-8">Reference Photo/Video</p>
			<div class="!mb-6 flex gap-1 cursor-pointer">
				<div class="" v-for="m in gig.medias" :key="m.id">
					<a
						class=""
						v-if="m.image"
						target="_blank"
						:href="'/media-viewer?url=' + baseURL + m.image + '&type=image'"
					>
						<NuxtImg
							class="h-48 w-64 object-cover shadow"
							:src="baseURL + m.image"
						/>
					</a>
					<a
						class=""
						target="_blank"
						:href="'/media-viewer?url=' + baseURL + m.video + '&type=video'"
						v-if="m.video"
					>
						<video
							class="h-48 w-64 object-cover shadow"
							:src="baseURL + m.video"
						></video>
					</a>
				</div>
			</div>
			<UCheckbox name="notifications" label="I accept Terms & Conditions" />
			<UCheckbox
				name="notifications"
				label="I am aware that fake and fraud submission may lead to account ban!"
			/>
			<UDivider label="" class="pt-4" />
			<div>
				<p class="text-2xl font-medium !mb-2 !mt-8">Upload Proof</p>
				<UInput type="file" size="sm" icon="i-heroicons-folder" />
			</div>
			<div class="text-center">
				<UButton
					class="mt-8"
					icon="i-heroicons-check-solid"
					size="md"
					color="primary"
					variant="solid"
					label="I Completed!"
				/>
			</div>
			{{ gid }}
			{{ gig }}
		</div>
	</UCard>
</template>

<script setup>
const emit = defineEmits(["close"]);
const props = defineProps(["gid"]);
const { get } = useApi();
const baseURL = "http://127.0.0.1:8000";
onMounted(() => {
	getGigData();
});
const gig = ref();
async function getGigData() {
	const res = await get(`/micro-gigs/${props.gid}`);
	gig.value = res.data;
}
</script>

<style scoped></style>
