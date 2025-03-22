<template>
	<div
		class="py-3 sticky z-50 top-2 bg-slate-100/80 shadow-sm md:shadow-md rounded-2xl mx-2 mt-2 dark:bg-black max-w-[1280px] md:mx-auto"
	>
		<UContainer>
			<!-- <PublicDonation /> -->
			<USlideover
				v-model="isOpen"
				side="left"
				:ui="{
					width: 'w-screen max-w-[270px]',
				}"
			>
				<UCard
					:ui="{
						header: {
							padding: 'pb-0.5',
						},
						ring: '',
						rounded: '',
						shadow: '',
					}"
				>
					<template #header>
						<div class="w-full flex justify-end">
							<UButton
								color="gray"
								variant="ghost"
								icon="i-heroicons-x-mark-20-solid"
								class="-my-1"
								@click="isOpen = false"
							/>
						</div>
					</template>
				</UCard>
				<PublicLogo
					:logo="logo"
					class="text-center mx-auto mb-4"
				/>
				<UVerticalNavigation
					:links="[
						{
							label: $t('home'),
							to: '/',
							icon: 'i-heroicons-home',
						},
						{
							label: $t('classified_service'),
							to: '#classified-services',
							icon: 'i-heroicons-clipboard-document-list',
						},
						{
							label: $t('earn_money'),
							to: '#micro-gigs',
							icon: 'i-healthicons:money-bag-outline',
						},
						{
							label: $t('faq'),
							to: '/faq/',
							icon: 'i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question',
						},
						{
							label: 'মোবাইল রিচার্জ',
							to: '/mobile-recharge',
							icon: 'i-ic-baseline-install-mobile',
						},
					]"
					:ui="{
						inactive: 'after:hidden before:hidden',
						active: 'after:hidden before:hidden',
						padding: 'py-2',
					}"
				/>
				<PublicTranslateHandler class="px-2 mt-3" />
			</USlideover>
			<div class="flex items-center justify-between gap-3 lg:gap-6">
				<div class="block md:hidden">
					<UButton
						@click="isOpen = true"
						icon="i-ci-hamburger-md"
						variant="outline"
						color="gray"
					/>
				</div>
				<PublicLogo
					:logo="logo"
					class="max-sm:mr-auto"
				/>
				<div class="hidden md:block">
					<UHorizontalNavigation
						:links="[
							{
								label: $t('home'),
								to: '/',
								icon: 'i-heroicons-home',
							},
							{
								label: $t('classified_service'),
								to: '/#classified-services',
								icon: 'i-heroicons-clipboard-document-list',
							},
							{
								label: $t('earn_money'),
								to: '/#micro-gigs',
								icon: 'i-healthicons:money-bag-outline',
							},
							{
								label: $t('faq'),
								to: '/faq',
								icon: 'i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question',
							},
							{
								label: $t('mobile_recharge'),
								to: '/mobile-recharge',
								icon: 'i-uil-mobile-vibrate',
							},
						]"
						class="border-b border-gray-200 dark:border-gray-800 text-lg"
						:ui="{
							wrapper: 'w-auto',
							label: 'text-base',
							active: 'after:hidden',
						}"
					/>
				</div>
				<div
					v-if="!user"
					class="flex relative menu-container"
				>
					<PublicTranslateHandler class="px-2 max-sm:hidden" />
					<UButton
						to="/auth/login/"
						label="Login/Register"
						color="gray"
						:ui="{
							size: {
								sm: 'text-xs md:text-sm',
							},
							padding: {
								sm: 'px-2 py-1 md:px-2.5 md:py-1.5',
							},
							icon: {
								size: {
									sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
								},
							},
						}"
						size="md"
					>
						<template #trailing>
							<UIcon
								name="i-heroicons-arrow-right-20-solid"
								class="w-5 h-5"
							/>
						</template>
					</UButton>
				</div>
				<div
					v-else
					class="flex relative menu-container"
				>
					<PublicTranslateHandler class="px-2 max-sm:hidden" />
					<UButton
						size="sm"
						color="primary"
						variant="outline"
						@click="openMenu = !openMenu"
						:ui="{
							size: {
								sm: 'text-sm',
							},
							padding: {
								sm: 'px-1.5 py-1 md:px-2.5 md:py-1.5',
							},
							icon: {
								size: {
									sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
								},
							},
						}"
					>
						<UIcon
							v-if="user?.user?.kyc"
							name="mdi:check-decagram"
							class="w-5 h-5 text-blue-600"
						/>
						<UIcon
							v-else
							name="i-heroicons-user-circle"
							class="text-xl"
						/>
						Hi {{ (user?.user?.first_name).slice(0, 12) }}
						<UIcon
							name="i-heroicons-chevron-down-16-solid"
							v-if="!openMenu"
						/>
						<UIcon
							name="i-heroicons-chevron-up-16-solid"
							v-if="openMenu"
						/>
					</UButton>

					<div
						class="absolute right-3 top-11 w-64 overflow-hidden transition-all duration-300 origin-top-right"
						:class="
							openMenu
								? 'opacity-100 scale-100 translate-y-0'
								: 'opacity-0 scale-95 translate-y-2 pointer-events-none'
						"
					>
						<!-- Glass-morphism container -->
						<div
							class="backdrop-blur-md bg-white/90 dark:bg-slate-800/90 rounded-xl shadow-lg border border-slate-200/50 dark:border-slate-700/50 overflow-hidden"
						>
							<!-- User info section -->
							<div
								class="p-4 bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 border-b border-slate-200/70 dark:border-slate-700/70"
							>
								<div class="flex items-center gap-3">
									<div class="relative">
										<!-- Profile avatar -->
										<div
											class="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-100 to-emerald-200 dark:from-emerald-800 dark:to-emerald-900 flex items-center justify-center text-emerald-600 dark:text-emerald-400 text-base font-semibold border-2 border-white dark:border-slate-700"
										>
											{{
												user?.user?.first_name
													? user.user.first_name[0].toUpperCase()
													: "U"
											}}
										</div>

										<!-- Verification badge if KYC -->
										<div
											v-if="user?.user?.kyc"
											class="absolute -bottom-1 -right-1 bg-white dark:bg-slate-800 rounded-full p-0.5 shadow-sm"
										>
											<UIcon
												name="mdi:check-decagram"
												class="w-4 h-4 text-blue-600"
											/>
										</div>
									</div>

									<div class="flex-1 min-w-0">
										<p
											class="font-medium text-slate-800 dark:text-white truncate"
										>
											{{ user?.user?.first_name }} {{ user?.user?.last_name }}
										</p>
										<p
											class="text-xs text-slate-500 dark:text-slate-400 truncate"
										>
											{{ user?.user?.email }}
										</p>
									</div>
								</div>
							</div>

							<!-- Menu items with hover effects -->
							<div class="py-1.5">
								<!-- Main account actions -->
								<div class="px-1.5 pb-1">
									<!-- Professional Pro/Free Toggle -->
									<div class="px-1.5 py-2">
										<!-- Free User Version (shows when user is not Pro) -->
										<div
											v-if="!user?.user?.is_pro"
											class="relative rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700"
										>
											<!-- Top Section: Current Plan -->
											<div
												class="bg-slate-50 dark:bg-slate-800/60 px-3 py-2 border-b border-slate-200 dark:border-slate-700"
											>
												<div class="flex items-center justify-between">
													<div class="flex items-center gap-1.5">
														<UIcon
															name="i-heroicons-user"
															class="w-4 h-4 text-slate-500 dark:text-slate-400"
														/>
														<span
															class="text-xs font-medium text-slate-600 dark:text-slate-300"
															>Current Plan</span
														>
													</div>
													<span
														class="text-xs px-2 py-0.5 bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 rounded font-medium"
														>Free</span
													>
												</div>
											</div>

											<!-- Bottom Section: Upgrade Action -->
											<div
												@click="upgradeToPro"
												class="p-3 cursor-pointer group"
											>
												<div class="flex items-center gap-3">
													<!-- Pro Badge Icon -->
													<div
														class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-blue-900/20 dark:to-indigo-900/30 flex items-center justify-center border border-indigo-200 dark:border-indigo-800/50 shadow-sm"
													>
														<UIcon
															name="i-heroicons-star"
															class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
														/>
													</div>

													<!-- Upgrade Text -->
													<div class="flex-1">
														<div class="flex items-center gap-2">
															<h4
																class="font-medium text-slate-800 dark:text-white"
															>
																Upgrade to Pro
															</h4>
														</div>
														<p
															class="text-xs text-slate-600 dark:text-slate-400"
														>
															Get premium features, priority support & more
														</p>
													</div>

													<!-- Switch Toggle Design -->
													<div
														class="w-11 h-6 rounded-full bg-slate-200 dark:bg-slate-700 p-0.5 flex items-center cursor-pointer relative group-hover:bg-slate-300 dark:group-hover:bg-slate-600 transition-colors"
													>
														<div
															class="absolute left-0.5 w-5 h-5 rounded-full bg-white shadow-sm transform group-hover:translate-x-1 transition-transform"
														></div>
													</div>
												</div>
											</div>
										</div>

										<!-- Pro User Version (shows when user is Pro) -->
										<div
											v-else
											class="relative rounded-lg overflow-hidden border border-indigo-200 dark:border-indigo-800/40"
										>
											<!-- Top Section: Current Plan -->

											<div
												class="bg-indigo-50 dark:bg-indigo-900/30 px-3 py-2 border-b border-indigo-100 dark:border-indigo-800/30"
											>
												<div class="flex items-center justify-between">
													<div class="flex items-center gap-1.5">
														<UIcon
															name="i-heroicons-sparkles"
															class="w-4 h-4 text-indigo-600 dark:text-indigo-400"
														/>
														<span
															class="text-xs font-medium text-indigo-700 dark:text-indigo-300"
															>Current Plan</span
														>
													</div>
													<span
														class="text-xs px-2 py-0.5 bg-indigo-200 dark:bg-indigo-800/50 text-indigo-700 dark:text-indigo-300 rounded font-medium"
														><div class="flex items-center gap-1">
															<UIcon
																name="i-heroicons-shield-check"
																class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
															/>
															<span class="text-sm">Pro</span>
														</div>
													</span>
												</div>
											</div>

											<!-- Bottom Section: Pro Status -->
											<div
												@click="manageSubscription"
												class="p-3 cursor-pointer group"
											>
												<div class="flex items-center gap-3">
													<!-- Pro Badge Icon -->
													<div
														class="w-10 h-10 rounded-lg bg-gradient-to-br from-indigo-500/10 to-purple-500/10 dark:from-indigo-600/20 dark:to-purple-600/20 flex items-center justify-center border border-indigo-200 dark:border-indigo-700/50 shadow-sm"
													>
														<UIcon
															name="i-heroicons-shield-check"
															class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
														/>
													</div>

													<!-- Pro Status Text -->
													<div class="flex-1">
														<h4
															class="font-medium text-slate-800 dark:text-white"
														>
															Pro Membership
														</h4>
														<p
															class="text-xs text-slate-600 dark:text-slate-400"
														>
															Valid until
															{{ formatDate(user?.user?.pro_validity) }}
														</p>
													</div>

													<!-- Active Switch Toggle -->
													<div
														class="w-11 h-6 rounded-full bg-indigo-200 dark:bg-indigo-700/70 p-0.5 flex items-center justify-end cursor-pointer"
													>
														<div
															class="w-5 h-5 rounded-full bg-indigo-600 dark:bg-indigo-500 shadow-sm"
														></div>
													</div>
												</div>
											</div>
										</div>
									</div>
									<NuxtLink
										v-for="(link, index) in [
											{
												label: $t('transaction'),
												to: '/deposit-withdraw',
												icon: 'i-heroicons-currency-dollar',
												color: 'text-emerald-600 dark:text-emerald-400',
												bg: 'bg-emerald-50 dark:bg-emerald-900/20',
											},
											{
												label: $t('upload_center'),
												icon: 'material-symbols:drive-folder-upload-outline-sharp',
												to: '/upload-center',
												color: 'text-blue-600 dark:text-blue-400',
												bg: 'bg-blue-50 dark:bg-blue-900/20',
											},
											{
												label: $t('mobile_recharge'),
												to: '/mobile-recharge',
												icon: 'i-uil-mobile-vibrate',
												color: 'text-orange-600 dark:text-orange-400',
												bg: 'bg-orange-50 dark:bg-orange-900/20',
											},
											{
												label: $t('refer_friend'),
												to: '/refer-a-friend',
												icon: 'i-solar-users-group-rounded-broken',
												color: 'text-purple-600 dark:text-purple-400',
												bg: 'bg-purple-50 dark:bg-purple-900/20',
											},
										]"
										:key="index"
										:to="link.to"
										class="flex items-center gap-3 px-3 py-2 rounded-lg my-0.5 group transition-colors text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700/50"
										@click="openMenu = false"
									>
										<!-- Icon with colored background -->
										<div
											:class="`w-8 h-8 rounded-full ${link.bg} flex items-center justify-center ${link.color} transition-transform group-hover:scale-110`"
										>
											<UIcon
												:name="link.icon"
												class="w-4 h-4"
											/>
										</div>

										<!-- Label with hover underline -->
										<span class="text-sm relative overflow-hidden">
											{{ link.label }}
											<span
												class="absolute bottom-0 left-0 w-full h-0.5 bg-current transform scale-x-0 origin-left transition-transform group-hover:scale-x-100"
											></span>
										</span>
									</NuxtLink>
								</div>

								<!-- Divider -->
								<div
									class="h-px bg-slate-200 dark:bg-slate-700 my-1 mx-3"
								></div>

								<!-- Settings and support -->
								<div class="px-1.5 py-1">
									<NuxtLink
										v-for="(link, index) in [
											{
												label: $t('settings'),
												icon: 'material-symbols:settings-outline',
												to: '/settings',
											},
											{
												label: $t('support'),
												icon: 'i-heroicons-question-mark-circle',
												to: '/contact-us',
											},
										]"
										:key="index"
										:to="link.to"
										class="flex items-center gap-3 px-3 py-2 rounded-lg my-0.5 group transition-colors text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700/50"
										@click="openMenu = false"
									>
										<UIcon
											:name="link.icon"
											class="w-5 h-5 text-slate-500 dark:text-slate-400 group-hover:text-slate-700 dark:group-hover:text-slate-300"
										/>
										<span class="text-sm">{{ link.label }}</span>
									</NuxtLink>
								</div>

								<!-- Divider -->
								<div
									class="h-px bg-slate-200 dark:bg-slate-700 my-1 mx-3"
								></div>

								<!-- Logout button -->
								<div class="px-1.5 pt-1">
									<button
										@click="
											logout();
											openMenu = false;
										"
										class="flex items-center gap-3 px-3 py-2 rounded-lg w-full text-left group transition-colors text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
									>
										<UIcon
											name="bitcoin-icons:exit-filled"
											class="w-5 h-5 transition-transform group-hover:-translate-x-0.5"
										/>
										<span class="text-sm font-medium">{{ $t("logout") }}</span>
									</button>
								</div>
							</div>
						</div>
					</div>
					<div
						class="ml-2"
						v-if="user && user.user"
					>
						<UButton
							icon="i-ic:twotone-qr-code-scanner"
							size="md"
							color="primary"
							variant="outline"
							@click="showQr = !showQr"
							block
						/>
						<UModal
							v-model="showQr"
							:ui="{
								width: 'w-full sm:max-w-md',
								background: 'bg-slate-100',
							}"
						>
							<div
								class="px-4 py-12 flex flex-col gap-4 items-center justify-center relative rounded-3xl overflow-hidden"
							>
								<UButton
									icon="i-heroicons-x-mark"
									size="md"
									color="primary"
									variant="solid"
									@click="showQr = false"
									class="absolute top-1 right-1 rounded-full"
								/>

								<h3 class="text-2xl font-semibold text-green-700">AdsyPay</h3>
								<h3 class="text-xl font-semibold">Scan My QR Code</h3>
								<div class="border p-4 rounded-lg shadow-md bg-white">
									<NuxtImg
										class="w-[250px]"
										:src="`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${user.user.phone}`"
									></NuxtImg>
								</div>
							</div>
						</UModal>
					</div>
				</div>
			</div>
		</UContainer>
	</div>
</template>

<script setup>
	const { t } = useI18n();
	const { user, logout } = useAuth();
	const { get } = useApi();
	const openMenu = ref(false);
	const router = useRouter();
	const open = ref(true);
	const logo = ref({});
	const isOpen = ref(false);
	const showQr = ref(false);

	const colorMode = useColorMode();
	colorMode.preference = "light";
	onMounted(() => {
		localStorage.setItem("nuxt-color-mode", "light");
	});

	async function getLogo() {
		const res = await get("/logo/");
		logo.value = res.data;
	}
	function upgradeToPro() {
		openMenu.value = false;
		router.push("/upgrade-to-pro");
	}

	function manageSubscription() {
		openMenu.value = false;
		router.push("/account/subscription");
	}

	function formatDate(date) {
		return new Date(date).toLocaleDateString(undefined, {
			year: "numeric",
			month: "short",
			day: "numeric",
		});
	}
	getLogo();

	defineShortcuts({
		o: () => (open.value = !open.value),
	});

	const handleClickOutside = (event) => {
		const menuContainer = document.querySelector(".menu-container");
		if (menuContainer && !menuContainer.contains(event.target)) {
			openMenu.value = false;
		}
	};

	onMounted(() => {
		document.addEventListener("click", handleClickOutside);
	});

	onUnmounted(() => {
		document.removeEventListener("click", handleClickOutside);
	});

	// if sidebar clicked and route changes, close sidebar if opened
	watch(router.currentRoute, () => {
		if (openMenu.value) {
			openMenu.value = false;
			isOpen.value = false;
		}
	});
</script>
