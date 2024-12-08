<template>
	<div class="min-h-[50vh]">
		<UContainer>
			<p class="text-2xl font-bold pb-6 border-b text-center mx-auto">In Box</p>
			<!-- showing message -->
			<div>
				<div class="flex items-center justify-between gap-3 py-2">
					<p>ID: 45648798</p>
					<p class="font-semibold">
						Subject: Lorem ipsum dolor sit amet consectetur adipisicing elit.
						Sint, neque.
					</p>
					<p><span>Time: 12.00 PM</span> / Date: 12-08-24</p>
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
							Lorem ipsum dolor sit amet consectetur adipisicing elit. Iusto
							numquam expedita, dolorem ratione dolore amet. Quidem error animi
							voluptatem. Doloremque repudiandae eum iure reprehenderit
							recusandae unde, repellat praesentium autem qui.
						</p>
					</UCard>
				</div>
			</div>
			<div>
				<div class="flex items-center justify-between gap-3 py-2">
					<p>ID: 45648798</p>
					<p class="font-semibold">
						Subject: Lorem ipsum dolor sit amet consectetur adipisicing elit.
						Sint, neque.
					</p>
					<p><span>Time: 12.00 PM</span> / Date: 12-08-24</p>
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
							Lorem ipsum dolor sit amet consectetur adipisicing elit. Iusto
							numquam expedita, dolorem ratione dolore amet. Quidem error animi
							voluptatem. Doloremque repudiandae eum iure reprehenderit
							recusandae unde, repellat praesentium autem qui.
						</p>
					</UCard>
				</div>
			</div>
		</UContainer>
	</div>
</template>

<script setup>
const toggleMsg = ref(false);
</script>

<style lang="scss" scoped></style>
