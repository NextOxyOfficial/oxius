<template>
	<div class="py-10">
		<PublicSection id="classified-services">
			<UContainer>
				<h2 class="text-2xl md:text-4xl mb-12">Classified Services</h2>
				<div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
					<UCard
						class="text-center"
						v-for="service in services"
						:key="service.id"
						:ui="{
							body: {
								padding: 'px-3 py-3 sm:p-5',
							},
						}"
					>
						<ULink
							:to="`/classified-categories/${service.id}`"
							active-class="text-primary"
							inactive-class="text-gray-500 dark:text-gray-400"
						>
							<NuxtImg
								:src="service.image"
								:title="service.title"
								class="size-10 mx-auto"
							/>
							<h3 class="text-xl mt-4">{{ service.title }}</h3>
						</ULink>
					</UCard>
				</div>
			</UContainer>
		</PublicSection>
		<PublicSection id="micro-gigs">
			<UContainer>
				<h2 class="text-2xl md:text-4xl mb-12 text-center">
					Micro Gigs (Quick Earn)
				</h2>
				<UCard
					v-if="user?.user"
					class="w-[700px] mx-auto mb-8 bg-primary/10"
					:ui="{
						rounded: 'rounded-2xl',
					}"
				>
					<div class="flex justify-between gap-6">
						<div>
							<h3 class="text-2xl font-bold">
								<span class="text-green-900 inline-flex items-center gap-1">
									<UIcon
										name="i-material-symbols:account-balance-wallet-outline"
										class="mt-1"
									/>
									Balance :
									<UIcon name="i-mdi:currency-bdt" class="text-2xl" />{{
										userBalance[0]?.amount
									}}</span
								>
							</h3>
						</div>
						<div class="flex items-center">
							<h3 class="text-xl font-bold inline-flex items-center">
								Pending Task:
								<UIcon name="i-mdi:currency-bdt" class="text-2xl" />500
							</h3>
							<UButton
								size="xs"
								color="primary"
								variant="solid"
								label="View"
								class="ml-2"
							/>
						</div>
					</div>
					<div class="flex justify-center gap-4 mt-8">
						<UButton
							icon="i-token:cusd"
							size="md"
							color="primary"
							variant="solid"
							label="Deposit / Withdraw"
							@click="isOpen = true"
						/>
						<UButton
							icon="i-material-symbols:mark-email-unread-outline"
							size="md"
							color="primary"
							variant="solid"
							label="Inbox"
							@click="isOpen = true"
						/>
						<UButton
							icon="i-material-symbols:list-rounded"
							size="md"
							color="primary"
							variant="solid"
							label="My Gigs"
							@click="isOpen = true"
						/>
						<UButton
							icon="i-heroicons-plus-circle"
							size="md"
							color="black"
							variant="solid"
							label="Post A Gig"
							to="/post-a-gig"
						/>
					</div>
				</UCard>
				<UCard
					:ui="{
						body: 'p-0',
						rounded: 'rounded-md overflow-hidden',
					}"
				>
					<div class="flex">
						<div class="w-60 bg-slate-50/70">
							<ul class="py-2">
								<li>
									<p class="px-2 font-semibold pb-2">All Categories</p>
									<UDivider label="" class="mb-2 px-4" />
								</li>
								<li v-for="microGig in microGigs" :key="microGig.id">
									<UButton
										:ui="{
											rounded: '',
										}"
										size="md"
										variant="ghost"
										color="white"
										class="w-full text-base px-4 py-0 font-normal"
										>{{ microGig.category_details.title }} (15)</UButton
									>
								</li>
							</ul>
						</div>
						<div class="space-y-[0.5px] flex-1">
							<UCard
								v-for="(gig, i) in microGigs"
								:key="i"
								:ui="{
									rounded: '',
									body: {
										padding: 'p-0 sm:p-0 flex-1 w-full',
									},
									header: {
										padding: 'p-0',
									},
									footer: {
										padding: 'p-0',
									},
								}"
								class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full bg-slate-50/70"
							>
								<div class="flex justify-between">
									<div class="flex gap-4">
										<div>
											<NuxtImg :src="gig.image" class="size-14 rounded-full" />
										</div>
										<div>
											<h3 class="text-base font-semibold mb-1.5">
												{{ gig.title }}
											</h3>
											<div class="flex gap-4">
												<div class="flex gap-1 items-center">
													<UIcon name="i-heroicons-bell-solid" />
													<p class="text-sm">
														<span class="">{{ gig.filled_quantity }}</span> /
														<span class="text-green-600">{{
															gig.required_quantity
														}}</span>
													</p>
												</div>
											</div>
										</div>
									</div>
									<div class="flex gap-16 items-center">
										<p
											class="font-bold text-base text-green-900 inline-flex items-center"
										>
											<UIcon name="i-mdi:currency-bdt" class="text-base" />{{
												gig.price
											}}
										</p>
										<UButton
											size="sm"
											color="primary"
											variant="outline"
											@click="showGig(gig.id)"
										>
											Earn
										</UButton>
									</div>
								</div>
							</UCard>
						</div>
					</div>
				</UCard>
			</UContainer>
		</PublicSection>
		<UModal
			v-model="isOpen"
			prevent-close
			:ui="{
				width: 'w-full sm:max-w-4xl',
			}"
		>
			<GigsViewer @close="isOpen = false" :gid="previewGid" />
		</UModal>
	</div>
</template>

<script setup>
const isOpen = ref(false);
const { get } = useApi();
const { user } = useAuth();
const services = ref([]);
const microGigs = ref([]);
const userBalance = ref([]);

async function getClassifiedCategories() {
	const res = await get("/classified-categories/");
	services.value = res.data;
	const res2 = await get("/micro-gigs/");
	microGigs.value = res2.data;
	const res3 = await get(`/user-balance/${user.value.user.email}/`);
	userBalance.value = res3.data;
}
const previewGid = ref();
function showGig(gid) {
	previewGid.value = gid;
	isOpen.value = true;
}

setTimeout(() => {
	getClassifiedCategories();
});
</script>
