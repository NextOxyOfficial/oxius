<template>
	<div>
		<section v-if="!result">
			<div class="flex items-center gap-4 w-full">
				<USkeleton class="h-16 w-16 rounded-full" />

				<div class="grid gap-2 w-full">
					<USkeleton class="h-7 w-[90%]" />
					<USkeleton class="h-7 w-[60%]" />
				</div>
			</div>
		</section>

		<section v-else>
			<div
				class="flex gap-4 py-2 border-b"
				v-for="b in result"
			>
				<UIcon
					size="56"
					name="i-solar:shop-2-bold-duotone"
				/>
				<div class="text-left">
					<h1 class="text-lg font-semibold">{{ b.name }}</h1>
					<p>{{ b.address }}</p>
					<div class="flex gap-2">
						<span v-if="b.phone">{{ b.phone }}</span>
						<span v-if="b.email">{{ b.email }}</span>
						<span v-if="b.website">{{ b.website }}</span>
					</div>
				</div>
			</div>
		</section>
	</div>
</template>

<script setup>
	const props = defineProps({
		country: String,
		city: String,
		state: String,
		business_type: String,
	});
	const result = ref();
	const url =
		"https://jolly-snow-f5d0.shimul929.workers.dev/business-finder?key=pk00xaytupk7";
	let extra_command =
		"search for fields: name,description,address,phone,email,website";
	let hidden_fields = ["phone"];
	onMounted(async () => {
		const { data, pending, error, refresh } = await useFetch(
			`${url}&country=${props.country}&city=${props.city}&state=${props.state}&business_type=${props.business_type}&extra_command=${extra_command}`,
			{
				method: "get",
			}
		);
		console.log("Business data", data.value);
		if (Array.isArray(data.value.data)) {
			result.value = data.value.data;
		} else {
			result.value = data.value.data.businesses;
		}
	});
</script>

<style scoped></style>
