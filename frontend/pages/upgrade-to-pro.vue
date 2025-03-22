<template>
	<UContainer>
		<div
			class="min-h-screen py-16 px-4 sm:px-6 bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800"
		>
			<div class="max-w-5xl mx-auto">
				<!-- Section Header -->
				{{ user?.user?.is_pro }}
				<div class="text-center mb-12">
					<h2
						class="text-3xl font-bold text-slate-700 dark:text-white md:text-4xl"
					>
						Choose Your <span class="text-sky-500 dark:text-sky-400">Plan</span>
					</h2>
					<p class="mt-4 text-slate-500 dark:text-slate-300 max-w-2xl mx-auto">
						Select the perfect plan for your needs. Upgrade anytime as your
						business grows.
					</p>
				</div>

				<!-- Pricing Cards Container with Perspective Effect -->
				<div class="flex flex-col md:flex-row gap-8 perspective-[1000px]">
					<!-- Free Plan - Lighter Design -->
					<div
						class="w-full md:w-1/2 bg-white dark:bg-slate-800 rounded-2xl overflow-hidden shadow-sm hover:shadow-xl transition-all duration-500 transform hover:-translate-y-1 border border-slate-100 dark:border-slate-700 group"
					>
						<!-- Card Header -->
						<div
							class="p-6 bg-gradient-to-r from-sky-50 to-blue-50 dark:from-sky-900/20 dark:to-blue-900/20 border-b border-slate-100 dark:border-slate-700"
						>
							<h3
								class="text-xl font-bold text-slate-700 dark:text-white flex items-center"
							>
								<span class="bg-sky-50 dark:bg-sky-900/30 p-2 rounded-lg mr-3">
									<svg
										xmlns="http://www.w3.org/2000/svg"
										class="h-5 w-5 text-sky-400 dark:text-sky-400"
										viewBox="0 0 20 20"
										fill="currentColor"
									>
										<path
											fill-rule="evenodd"
											d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
											clip-rule="evenodd"
										/>
									</svg>
								</span>
								Free Plan
							</h3>

							<div class="mt-4 flex items-baseline">
								<span class="text-4xl font-bold text-slate-700 dark:text-white"
									>$0</span
								>
								<span class="ml-2 text-sm text-slate-500 dark:text-slate-400"
									>/month</span
								>
							</div>

							<p class="mt-2 text-sm text-slate-500 dark:text-slate-400">
								Perfect for getting started
							</p>
						</div>

						<!-- Card Body with Enhanced Features List -->
						<div class="p-6">
							<ul class="space-y-4 mb-8">
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300"
										>Basic store setup</span
									>
								</li>
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300"
										>Up to 10 products</span
									>
								</li>
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300"
										>Community support</span
									>
								</li>
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300"
										>Basic analytics</span
									>
								</li>
							</ul>

							<button
								class="w-full py-3 bg-gradient-to-r from-sky-50 to-blue-50 dark:from-sky-900/20 dark:to-blue-900/20 text-sky-500 dark:text-sky-400 rounded-xl text-sm font-medium hover:shadow-md border border-sky-100 dark:border-sky-800/30 transition-all duration-300 relative overflow-hidden group-hover:border-sky-200 dark:group-hover:border-sky-700/50"
							>
								<span
									class="relative z-10 flex items-center justify-center gap-2"
								>
									Get Started
									<svg
										xmlns="http://www.w3.org/2000/svg"
										class="h-4 w-4 transform transition-transform group-hover:translate-x-1"
										fill="none"
										viewBox="0 0 24 24"
										stroke="currentColor"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M13 7l5 5m0 0l-5 5m5-5H6"
										/>
									</svg>
								</span>
							</button>
						</div>
					</div>

					<!-- Pro Plan - Lighter Premium Effects -->
					<div
						class="w-full md:w-1/2 rounded-2xl overflow-hidden shadow-lg hover:shadow-2xl transition-all duration-500 transform hover:-translate-y-2 border-2 border-sky-200/70 dark:border-sky-700/30 bg-white dark:bg-slate-800 relative group"
					>
						<!-- Premium Badge -->
						<div class="absolute -top-0.5 -right-0.5 z-10">
							<div
								class="bg-gradient-to-r from-sky-400 to-blue-400 text-white text-xs font-bold py-1 px-3 rounded-bl-lg rounded-tr-lg shadow-md flex items-center gap-1"
							>
								<svg
									xmlns="http://www.w3.org/2000/svg"
									class="h-4 w-4"
									viewBox="0 0 20 20"
									fill="currentColor"
								>
									<path
										d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
									/>
								</svg>
								RECOMMENDED
							</div>
						</div>

						<!-- Glow Effect -->
						<div
							class="absolute -inset-0.5 bg-gradient-to-r from-sky-300 to-blue-300 dark:from-sky-500 dark:to-blue-500 rounded-2xl blur-lg opacity-0 group-hover:opacity-10 transition-all duration-700 animate-pulse"
						></div>

						<!-- Card Header -->
						<div
							class="p-6 bg-gradient-to-r from-sky-400 to-blue-400 dark:from-sky-500 dark:to-blue-500 relative"
						>
							<h3 class="text-xl font-bold text-white flex items-center">
								<span class="bg-white/20 p-2 rounded-lg mr-3 backdrop-blur-sm">
									<svg
										xmlns="http://www.w3.org/2000/svg"
										class="h-5 w-5 text-white"
										viewBox="0 0 20 20"
										fill="currentColor"
									>
										<path
											fill-rule="evenodd"
											d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
											clip-rule="evenodd"
										/>
									</svg>
								</span>
								Pro Plan
							</h3>

							<div class="mt-4 flex items-baseline">
								<span class="text-4xl font-bold text-white">$29</span>
								<span class="ml-2 text-sm text-sky-100">/month</span>
							</div>

							<p class="mt-2 text-sm text-sky-100">
								For businesses ready to grow
							</p>

							<!-- Animated Particles -->
							<div
								class="absolute top-4 right-4 w-2 h-2 rounded-full bg-sky-100 opacity-75 animate-ping"
							></div>
							<div
								class="absolute bottom-4 right-12 w-1.5 h-1.5 rounded-full bg-blue-100 opacity-75"
								style="
									animation: ping 2.5s cubic-bezier(0, 0, 0.2, 1) infinite 0.5s;
								"
							></div>
						</div>

						<!-- Card Body -->
						<div class="p-6 relative">
							<!-- Animated Background Effect -->
							<div
								class="absolute inset-0 bg-gradient-to-br from-sky-50 to-blue-50 dark:from-sky-900/5 dark:to-blue-900/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
							></div>

							<ul class="space-y-4 mb-8 relative z-10">
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300 font-medium"
										>Unlimited store setup</span
									>
								</li>
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300 font-medium"
										>Unlimited products</span
									>
								</li>
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300 font-medium"
										>Priority support 24/7</span
									>
								</li>
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300 font-medium"
										>Advanced analytics & reporting</span
									>
								</li>
								<li class="flex items-center text-sm group/item">
									<div
										class="w-6 h-6 rounded-full bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center mr-3 flex-shrink-0 group-hover/item:scale-110 transition-transform"
									>
										<svg
											class="w-3.5 h-3.5 text-sky-400 dark:text-sky-400"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											xmlns="http://www.w3.org/2000/svg"
										>
											<path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M5 13l4 4L19 7"
											></path>
										</svg>
									</div>
									<span class="text-slate-600 dark:text-slate-300 font-medium"
										>Custom branding options</span
									>
								</li>
							</ul>

							<!-- Enhanced CTA Button -->
							<button
								class="w-full py-3 bg-gradient-to-r from-sky-400 to-blue-400 hover:from-sky-500 hover:to-blue-500 text-white rounded-xl text-sm font-medium transition-all duration-300 shadow-sm hover:shadow-md relative overflow-hidden group-hover:scale-[1.02]"
								@click="showModal"
							>
								<span
									class="relative z-10 flex items-center justify-center gap-2"
								>
									Upgrade Now
									<svg
										xmlns="http://www.w3.org/2000/svg"
										class="h-4 w-4 transform transition-transform group-hover:translate-x-1"
										fill="none"
										viewBox="0 0 24 24"
										stroke="currentColor"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M13 7l5 5m0 0l-5 5m5-5H6"
										/>
									</svg>
								</span>
								<div
									class="absolute inset-0 w-full h-full bg-gradient-to-r from-white/0 via-white/20 to-white/0 -translate-x-full group-hover:animate-shimmer"
								></div>
							</button>
						</div>

						<!-- Best Value Tag -->
						<div
							class="absolute -rotate-90 -end-9 top-12 bg-gradient-to-r from-sky-400 to-blue-400 text-xs text-white py-1 px-8 font-medium"
						>
							BEST VALUE
						</div>
					</div>
				</div>

				<!-- Trust Indicators Section -->
				<div class="mt-16 flex flex-col items-center">
					<p
						class="text-center text-sm text-slate-500 dark:text-slate-400 mb-6"
					>
						Trusted by thousands of businesses worldwide
					</p>

					<div
						class="flex flex-wrap justify-center gap-6 items-center opacity-70"
					>
						<!-- Replace with actual brand logos -->
						<div
							class="h-8 w-24 bg-slate-200/50 dark:bg-slate-600/30 rounded-md"
						></div>
						<div
							class="h-8 w-20 bg-slate-200/50 dark:bg-slate-600/30 rounded-md"
						></div>
						<div
							class="h-8 w-28 bg-slate-200/50 dark:bg-slate-600/30 rounded-md"
						></div>
						<div
							class="h-8 w-24 bg-slate-200/50 dark:bg-slate-600/30 rounded-md"
						></div>
					</div>

					<!-- Enhanced Footer -->
					<div class="mt-12 text-center max-w-2xl mx-auto">
						<p class="text-sm text-slate-500 dark:text-slate-400 mb-2">
							All plans include 14-day free trial. No credit card required.
						</p>
						<p class="text-xs text-slate-400 dark:text-slate-500">
							Cancel anytime. Questions?
							<a
								href="#"
								class="text-sky-500 dark:text-sky-400 hover:underline"
								>Contact our team</a
							>
						</p>
					</div>
				</div>
			</div>
		</div>

		<!-- Main subscription modal -->
		<UModal
			v-model="openModal"
			:ui="{
				width: 'sm:max-w-md',
				overlay: {
					background: 'bg-slate-900/30 backdrop-blur-sm',
				},
				container: 'transition-all duration-300 ease-out-cubic',
			}"
			transition="fade-scale"
		>
			<div class="modal-subscription overflow-hidden rounded-xl">
				<!-- Animated Header -->
				<div class="relative overflow-hidden">
					<div
						class="absolute inset-0 bg-gradient-to-r from-sky-500/20 to-blue-500/20 animate-gradient"
					></div>
					<div
						class="relative px-6 py-5 bg-gradient-to-r from-sky-500 to-blue-500"
					>
						<!-- Animated particles -->
						<div
							class="absolute top-3 right-3 w-2 h-2 rounded-full bg-white/30 animate-ping-slow"
						></div>
						<div
							class="absolute top-10 right-12 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
							style="animation-delay: 0.5s"
						></div>
						<div
							class="absolute bottom-5 left-10 w-1.5 h-1.5 rounded-full bg-white/20 animate-ping-slow"
							style="animation-delay: 1s"
						></div>

						<div class="flex items-center gap-3">
							<div
								class="bg-white/20 p-2.5 rounded-lg flex items-center justify-center backdrop-blur-sm"
							>
								<UIcon
									name="i-heroicons-star"
									class="text-white w-5 h-5"
								/>
							</div>
							<div>
								<h2 class="text-white font-semibold text-xl flex items-center">
									Upgrade to Pro
									<div class="ml-2 flex">
										<span class="animate-shimmer-star">✨</span>
									</div>
								</h2>
								<p class="text-sky-100 text-sm mt-0.5">
									Unlock premium features for your business
								</p>
							</div>
						</div>
					</div>
				</div>

				<div class="p-0">
					<!-- Loading State -->
					<div
						v-if="isLoading"
						class="flex flex-col items-center justify-center py-16 px-6"
					>
						<div class="relative">
							<div
								class="w-12 h-12 rounded-full border-2 border-sky-500/20"
							></div>
							<div
								class="absolute inset-0 w-12 h-12 rounded-full border-t-2 border-sky-500 animate-spin"
							></div>
						</div>
						<p class="mt-4 text-slate-600 dark:text-slate-400">
							Loading plan details...
						</p>
					</div>

					<!-- Content -->
					<div
						v-else
						class="px-6 py-5"
					>
						<!-- Plan Details -->
						<div class="mb-6">
							<h3 class="text-base font-medium mb-3 flex items-center">
								<UIcon
									name="i-heroicons-document-text"
									class="mr-2 text-sky-500 w-4 h-4"
								/>
								Plan Details
							</h3>
							<div class="">
								<UButton
									icon="i-heroicons-bell-solid"
									size="md"
									color="primary"
									variant="solid"
									label="Pay Monthly"
									v-if="months == 12"
									@click="
										() => {
											months = 1;
										}
									"
								/>
								<UButton
									icon="i-heroicons-bell-solid"
									size="md"
									color="primary"
									variant="solid"
									label="Pay yearly"
									v-else
									@click="
										() => {
											months = 12;
										}
									"
								/>
							</div>
							<div
								class="p-4 rounded-lg bg-gradient-to-r from-slate-50 to-sky-50 dark:from-slate-800/80 dark:to-sky-900/30 border border-slate-100 dark:border-slate-700/50 relative overflow-hidden group"
							>
								<!-- Shimmer effect on hover -->
								<div
									class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/20 dark:via-white/5 to-transparent -translate-x-full group-hover:animate-shimmer"
								></div>

								<!-- Plan content -->
								<div class="flex justify-between items-center mb-3">
									<span class="text-slate-600 dark:text-slate-300">Plan:</span>
									<span
										class="font-semibold bg-gradient-to-r from-sky-600 to-blue-600 dark:from-sky-400 dark:to-blue-400 bg-clip-text text-transparent"
										>Pro Plan</span
									>
								</div>
								<div class="flex justify-between items-center mb-3">
									<span class="text-slate-600 dark:text-slate-300">Price:</span>
									<span
										class="font-semibold"
										v-if="months == 1"
										>৳{{ months * price }} / month
									</span>
									<span
										class="font-semibold"
										v-else
										>৳{{ months * price - yearly_discount }} / year
									</span>
								</div>
								<div class="flex justify-between items-center">
									<span class="text-slate-600 dark:text-slate-300"
										>Duration:</span
									>
									<span class="font-semibold">{{ months * 30 }} days</span>
								</div>

								<!-- Benefits -->
								<div
									class="mt-4 pt-3 border-t border-slate-200 dark:border-slate-700/50"
								>
									<div
										class="flex items-center gap-2 mb-2 text-xs text-slate-600 dark:text-slate-400"
									>
										<UIcon
											name="i-heroicons-check-circle"
											class="text-green-500 w-4 h-4"
										/>
										<span>Unlimited products</span>
									</div>
									<div
										class="flex items-center gap-2 text-xs text-slate-600 dark:text-slate-400"
									>
										<UIcon
											name="i-heroicons-check-circle"
											class="text-green-500 w-4 h-4"
										/>
										<span>Priority support with 24/7 access</span>
									</div>
								</div>
							</div>
						</div>

						<!-- Payment Method Selection -->
						<div class="mb-6">
							<h3 class="text-base font-medium mb-3 flex items-center">
								<UIcon
									name="i-heroicons-credit-card"
									class="mr-2 text-sky-500 w-4 h-4"
								/>
								Payment Method
							</h3>

							<!-- Account Funds Option -->
							<div class="payment-option-container mb-3">
								<URadio
									v-model="paymentMethod"
									name="payment"
									value="account_funds"
									class="sr-only"
									id="account_funds"
								/>
								<label
									for="account_funds"
									class="block p-4 border rounded-lg transition-all duration-200 cursor-pointer relative"
									:class="
										paymentMethod === 'account_funds'
											? 'border-sky-500 dark:border-sky-500 bg-sky-50 dark:bg-sky-900/20 ring-1 ring-sky-500/30'
											: 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800/50'
									"
								>
									<div class="flex items-center justify-between">
										<div class="flex items-center gap-3">
											<div
												class="w-10 h-10 flex-shrink-0 rounded-md bg-slate-100 dark:bg-slate-700 flex items-center justify-center"
											>
												<UIcon
													name="i-heroicons-wallet"
													class="w-5 h-5 text-sky-600 dark:text-sky-400"
												/>
											</div>
											<div>
												<p class="font-medium">Account Funds</p>
												<p class="text-xs text-slate-500 dark:text-slate-400">
													Available balance: ৳{{ user?.user?.balance }}
												</p>
											</div>
										</div>
										<div
											class="flex items-center justify-center w-5 h-5 rounded-full border-2"
											:class="
												paymentMethod === 'account_funds'
													? 'bg-sky-500 border-sky-500 flex items-center justify-center'
													: 'border-slate-300 dark:border-slate-600'
											"
										>
											<div
												v-if="paymentMethod === 'account_funds'"
												class="w-2 h-2 bg-white rounded-full animate-scale-in"
											></div>
										</div>
									</div>

									<!-- Instant badge -->
									<div class="absolute top-2 right-2">
										<span
											class="px-1.5 py-0.5 text-[10px] uppercase tracking-wider font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 rounded"
											>Instant</span
										>
									</div>
								</label>
							</div>
						</div>

						<!-- Action Buttons -->
						<div class="flex flex-col gap-3">
							<button
								class="w-full py-3 font-medium relative overflow-hidden group"
								:class="[
									isSubscribing
										? 'cursor-not-allowed opacity-80'
										: 'cursor-pointer',
									'bg-gradient-to-r from-sky-500 to-blue-500 hover:from-sky-600 hover:to-blue-600 text-white rounded-xl transition-all duration-300',
								]"
								@click="createSubscription"
								:disabled="isSubscribing"
							>
								<span
									class="relative z-10 flex items-center justify-center gap-2"
								>
									<span
										v-if="isSubscribing"
										class="flex items-center"
									>
										<UIcon
											name="i-heroicons-arrow-path"
											class="w-4 h-4 animate-spin mr-2"
										/>
										Processing...
									</span>
									<span v-else>
										Confirm Upgrade
										<UIcon
											name="i-heroicons-arrow-right"
											class="w-4 h-4 transition-transform group-hover:translate-x-1"
										/>
									</span>
								</span>
								<div
									class="absolute inset-0 w-full h-full bg-gradient-to-r from-white/0 via-white/20 to-white/0 -translate-x-full group-hover:animate-shimmer"
								></div>
							</button>

							<button
								class="w-full py-3 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 transition-all duration-200 font-medium"
								@click="openModal = false"
							>
								Cancel
							</button>
						</div>
					</div>
				</div>
			</div>
		</UModal>

		<!-- Success Modal -->
		<UModal
			v-model="showSuccessModal"
			:ui="{
				width: 'sm:max-w-md',
				overlay: {
					background: 'bg-slate-900/40 backdrop-blur-sm',
				},
				container: 'transition-all duration-300 ease-out-cubic',
			}"
			transition="zoom-fade"
		>
			<div class="success-modal rounded-xl overflow-hidden">
				<!-- Animated Success Header -->
				<div class="relative overflow-hidden">
					<div
						class="absolute inset-0 bg-gradient-to-r from-emerald-500/20 to-green-500/20 animate-gradient"
					></div>
					<div
						class="relative px-6 pt-8 pb-6 bg-gradient-to-r from-emerald-500 to-green-500 flex flex-col items-center"
					>
						<!-- Animated confetti -->
						<div
							class="absolute top-3 right-10 w-1.5 h-1.5 rounded-full bg-white/30 animate-ping-slow"
						></div>
						<div
							class="absolute bottom-10 left-8 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
							style="animation-delay: 0.8s"
						></div>
						<div
							class="absolute top-12 left-10 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
							style="animation-delay: 1.2s"
						></div>
						<div
							class="absolute bottom-4 right-12 w-2 h-2 rounded-full bg-white/20 animate-ping-slow"
							style="animation-delay: 0.4s"
						></div>

						<!-- Success icon with animations -->
						<div class="relative mb-4">
							<!-- Outer rings animation -->
							<div
								class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/20 animate-pulse-slow"
							></div>
							<div
								class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/10 animate-pulse-slower"
								style="animation-delay: 0.5s"
							></div>

							<!-- Icon container -->
							<div
								class="w-20 h-20 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center z-10 relative"
							>
								<UIcon
									name="i-heroicons-check"
									class="w-10 h-10 text-white"
								/>

								<!-- Success rays -->
								<div class="absolute inset-0 success-rays"></div>
							</div>
						</div>

						<h2 class="text-white font-bold text-2xl mb-1">
							Payment Successful!
						</h2>
						<div class="flex items-center gap-1">
							<UIcon
								name="i-heroicons-shield-check"
								class="w-4 h-4 text-white/80"
							/>
							<p class="text-green-50 text-sm">
								Transaction processed securely
							</p>
						</div>
					</div>
				</div>

				<!-- Success Content -->
				<div class="p-6 bg-white dark:bg-slate-800">
					<div class="mb-6">
						<div class="flex flex-col gap-4">
							<!-- Success details card -->
							<div
								class="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/30 border border-slate-100 dark:border-slate-700/50"
							>
								<div class="flex justify-between items-center mb-3">
									<span class="text-slate-500 dark:text-slate-400">Plan:</span>
									<span class="font-semibold text-slate-800 dark:text-white"
										>Pro Plan</span
									>
								</div>
								<div class="flex justify-between items-center mb-3">
									<span class="text-slate-500 dark:text-slate-400"
										>Amount:</span
									>
									<span class="font-semibold text-slate-800 dark:text-white"
										>৳2,900</span
									>
								</div>
								<div class="flex justify-between items-center">
									<span class="text-slate-500 dark:text-slate-400"
										>Active until:</span
									>
									<span class="font-semibold text-slate-800 dark:text-white">{{
										new Date(
											Date.now() + 30 * 24 * 60 * 60 * 1000
										).toLocaleDateString()
									}}</span>
								</div>

								<!-- Animated tick marks -->
								<div
									class="mt-4 pt-3 border-t border-slate-200 dark:border-slate-600/50"
								>
									<div
										class="flex items-center gap-2 mb-2 animate-fade-in"
										style="animation-delay: 0.2s"
									>
										<div
											class="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center"
										>
											<UIcon
												name="i-heroicons-check"
												class="w-3 h-3 text-green-500"
											/>
										</div>
										<span class="text-sm text-slate-600 dark:text-slate-300"
											>Unlimited products activated</span
										>
									</div>
									<div
										class="flex items-center gap-2 animate-fade-in"
										style="animation-delay: 0.4s"
									>
										<div
											class="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center"
										>
											<UIcon
												name="i-heroicons-check"
												class="w-3 h-3 text-green-500"
											/>
										</div>
										<span class="text-sm text-slate-600 dark:text-slate-300"
											>Priority support enabled</span
										>
									</div>
								</div>
							</div>

							<!-- Receipt ID -->
							<div class="flex items-center justify-between text-sm">
								<span class="text-slate-500 dark:text-slate-400"
									>Transaction ID:</span
								>
								<code
									class="bg-slate-100 dark:bg-slate-700/50 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-mono"
									>{{
										"TXN_" +
										Math.random().toString(36).substring(2, 10).toUpperCase()
									}}</code
								>
							</div>
						</div>
					</div>

					<button
						class="w-full py-3.5 group relative rounded-xl font-medium overflow-hidden transform transition-all duration-300 active:scale-[0.98] hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-emerald-500/30 dark:focus:ring-emerald-400/30 flex justify-center"
						@click="goToDashboard"
					>
						<!-- Layered background with 3D effect -->
						<div
							class="absolute inset-0 bg-gradient-to-br from-emerald-600 to-green-600 shadow-lg"
						></div>
						<div
							class="absolute inset-[1px] bg-gradient-to-r from-emerald-500 to-green-500 rounded-[10px]"
						></div>
						<div
							class="absolute inset-0 bg-gradient-to-r from-emerald-400/0 via-white/30 to-emerald-400/0 -translate-x-full group-hover:animate-shimmer-slow"
						></div>

						<!-- Button content -->
						<div
							class="relative z-10 flex items-center justify-center gap-2 text-white"
						>
							<!-- Particle effects that appear on hover -->
							<div
								class="absolute -top-2 -left-2 w-1 h-1 rounded-full bg-white/80 opacity-0 group-hover:opacity-100 group-hover:animate-float-up-left transition-opacity"
							></div>
							<div
								class="absolute -top-1 left-1/4 w-1.5 h-1.5 rounded-full bg-white/60 opacity-0 group-hover:opacity-100 group-hover:animate-float-up-slow transition-opacity"
								style="animation-delay: 0.2s"
							></div>
							<div
								class="absolute -top-1.5 right-1/3 w-1 h-1 rounded-full bg-white/70 opacity-0 group-hover:opacity-100 group-hover:animate-float-up transition-opacity"
								style="animation-delay: 0.5s"
							></div>

							<!-- Success check icon that appears on hover -->
							<span
								class="flex items-center justify-center absolute -left-6 opacity-0 group-hover:opacity-100 group-hover:left-3 transition-all duration-300"
							>
								<UIcon
									name="i-heroicons-check-circle"
									class="w-5 h-5 text-white"
								/>
							</span>

							<!-- Text with slide effect -->
							<span
								class="transform group-hover:translate-x-2 transition-transform duration-300"
							>
								Continue to Home
							</span>

							<!-- Animated arrow -->
							<span
								class="relative flex items-center transform group-hover:translate-x-1.5 transition-all duration-300"
							>
								<UIcon
									name="i-heroicons-arrow-right"
									class="w-5 h-5"
								/>

								<!-- Arrow trail effect -->
								<span
									class="absolute inset-0 opacity-0 group-hover:opacity-70 group-hover:animate-ping-fast"
								></span>
							</span>
						</div>

						<!-- Bottom highlight for 3D effect -->
						<div
							class="absolute bottom-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-emerald-300 to-transparent opacity-50 group-hover:opacity-80 transition-opacity"
						></div>
					</button>
				</div>
			</div>
		</UModal>

		<!-- Failure Modal -->
		<UModal
			v-model="showFailureModal"
			:ui="{
				width: 'sm:max-w-md',
				overlay: {
					background: 'bg-slate-900/40 backdrop-blur-sm',
				},
				container: 'transition-all duration-300 ease-out-cubic',
			}"
			transition="zoom-fade"
		>
			<div class="failure-modal rounded-xl overflow-hidden">
				<!-- Animated Failure Header -->
				<div class="relative overflow-hidden">
					<div
						class="absolute inset-0 bg-gradient-to-r from-red-500/20 to-orange-500/20 animate-gradient"
					></div>
					<div
						class="relative px-6 pt-8 pb-6 bg-gradient-to-r from-red-500 to-orange-500 flex flex-col items-center"
					>
						<!-- Animated particles -->
						<div
							class="absolute top-5 right-12 w-1.5 h-1.5 rounded-full bg-white/20 animate-ping-slow"
						></div>
						<div
							class="absolute bottom-8 left-10 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
							style="animation-delay: 0.6s"
						></div>

						<!-- Error icon with animations -->
						<div class="relative mb-4">
							<!-- Pulsing effect -->
							<div
								class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/20 animate-pulse-slow"
							></div>

							<!-- Icon container -->
							<div
								class="w-20 h-20 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center z-10 relative"
							>
								<UIcon
									name="i-heroicons-exclamation-triangle"
									class="w-10 h-10 text-white animate-subtle-bounce"
								/>
							</div>
						</div>

						<h2 class="text-white font-bold text-2xl mb-1">Payment Failed</h2>
						<p class="text-red-50 text-sm">We couldn't process your payment</p>
					</div>
				</div>

				<!-- Failure Content -->
				<div class="p-6 bg-white dark:bg-slate-800">
					<div class="mb-6">
						<!-- Error message card -->
						<div
							class="p-4 rounded-lg bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/20 mb-4"
						>
							<div class="flex items-start gap-3">
								<UIcon
									name="i-heroicons-information-circle"
									class="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5"
								/>
								<div>
									<p class="text-sm text-red-700 dark:text-red-300">
										{{
											errorMessage ||
											"We couldn't process your payment. Your account hasn't been charged."
										}}
									</p>
								</div>
							</div>
						</div>

						<!-- Suggested solutions -->
						<div class="space-y-2 mb-5">
							<p class="text-sm font-medium text-slate-700 dark:text-slate-300">
								Suggested solutions:
							</p>
							<div
								class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
							>
								<UIcon
									name="i-heroicons-arrow-right"
									class="w-3 h-3 text-slate-400"
								/>
								<span>Try a different payment method</span>
							</div>
							<div
								class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
							>
								<UIcon
									name="i-heroicons-arrow-right"
									class="w-3 h-3 text-slate-400"
								/>
								<span>Check your account balance</span>
							</div>
							<div
								class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
							>
								<UIcon
									name="i-heroicons-arrow-right"
									class="w-3 h-3 text-slate-400"
								/>
								<span>Contact customer support if the issue persists</span>
							</div>
						</div>
					</div>

					<!-- Action Buttons -->
					<div class="flex flex-col gap-3">
						<UButton
							class="w-full"
							:ui="{
								rounded: 'rounded-xl',
								padding: 'py-3',
								variant: {
									solid:
										'bg-gradient-to-r from-red-500 to-orange-500 hover:from-red-600 hover:to-orange-600 text-white shadow-sm',
								},
							}"
							variant="solid"
							@click="showFailureModal = false"
						>
							<span class="flex items-center justify-center gap-1">
								<UIcon
									name="i-heroicons-arrow-path"
									class="w-4 h-4"
								/>
								Try Again
							</span>
						</UButton>

						<UButton
							color="gray"
							variant="soft"
							class="rounded-xl py-2.5"
							@click="handleFailureClose"
						>
							Cancel
						</UButton>
					</div>
				</div>
			</div>
		</UModal>
	</UContainer>
</template>

<script setup>
	// Import and initialize required composables
	const { user } = useAuth();
	const router = useRouter();
	const toast = useToast();
	const { $api } = useNuxtApp();
	const { get, post } = useApi();

	// State variables
	const openModal = ref(false);
	const showSuccessModal = ref(false);
	const showFailureModal = ref(false);
	const isLoading = ref(false);
	const isSubscribing = ref(false);
	const paymentMethod = ref("account_funds");
	const autoRenew = ref(true);
	const errorMessage = ref("");
	const transactionId = ref("");
	const price = ref(149);
	const months = ref(1);
	const yearly_discount = ref(289);

	// For future API implementation
	// const userSubscriptionDetails = ref({});

	/**
	 * Opens the subscription modal
	 */
	function showModal() {
		openModal.value = true;
		// Reset form state when opening modal
		paymentMethod.value = "account_funds";
		autoRenew.value = true;
		isLoading.value = true;

		// Simulate loading data
		setTimeout(() => {
			isLoading.value = false;
		}, 800);

		console.log("Modal opened");
	}

	/**
	 * Fetch user data including balance
	 */
	async function fetchUserData() {
		try {
			// In the future, replace this with actual API call:
			// const { data } = await $api.get("/api/user/balance");
			// const subscriptionData = await $api.get("/api/subscriptions/");
			// userSubscriptionDetails.value = subscriptionData.data;

			// Simulated data for now
			const userBalance = 3500;
			console.log("User balance:", userBalance);
		} catch (error) {
			console.error("Error fetching user data:", error);
		}
	}

	/**
	 * Process subscription creation based on selected payment method
	 */
	async function createSubscription() {
		if (isSubscribing.value) return; // Prevent double submission

		isSubscribing.value = true;

		try {
			if (paymentMethod.value === "account_funds") {
				// Account funds path - process immediately
				let total = months.value * price.value;
				if (months.value === 12) {
					total -= yearly_discount.value;
				}
				const result = await get(
					`/subscribe/?months=${months.value}&total=${total}`
				);
				console.log(result);
				// Simulate successful payment
				const response = {
					success: true,
					data: {
						subscription_id:
							"sub_" + Math.random().toString(36).substring(2, 9),
						status: "active",
						start_date: new Date().toISOString(),
						end_date: new Date(
							Date.now() + 30 * 24 * 60 * 60 * 1000
						).toISOString(),
					},
				};

				// Generate transaction ID for display in success modal
				transactionId.value =
					"TXN_" + Math.random().toString(36).substring(2, 10).toUpperCase();

				// Show success modal
				showSuccessModal.value = true;
				openModal.value = false;
			} else if (paymentMethod.value === "surjopay") {
				// SurjoPay path - redirect to payment gateway
				await new Promise((resolve) => setTimeout(resolve, 1000));

				// In production, this would be:
				// const sessionResponse = await $api.post("/api/payment/create-session", {
				//   plan_id: 1,
				//   payment_method: paymentMethod.value,
				//   auto_renew: autoRenew.value
				// });
				// window.location.href = sessionResponse.data.payment_url;

				window.location.href = "/simulate-surjopay-redirect";
				return;
			}
		} catch (error) {
			console.error("Payment failed:", error);

			// Show error message
			errorMessage.value = error.message || "Payment processing failed";
			showFailureModal.value = true;
		} finally {
			isSubscribing.value = false;
		}
	}

	/**
	 * Navigate to dashboard after successful payment
	 */
	function goToDashboard() {
		showSuccessModal.value = false;

		// Show toast notification
		toast.add({
			title: "Subscription Active",
			description: "Your account has been upgraded to Pro!",
			icon: "i-heroicons-check-circle",
			color: "green",
		});

		router.push("/");
	}

	/**
	 * Handle failure modal close
	 */
	function handleFailureClose() {
		showFailureModal.value = false;
		openModal.value = false;
	}

	// Fetch data when component mounts
	onMounted(() => {
		fetchUserData();
	});
</script>

<style scoped>
	@keyframes shimmer-slow {
		100% {
			transform: translateX(100%);
		}
	}

	.animate-shimmer-slow {
		animation: shimmer-slow 2s ease-in-out infinite;
	}

	@keyframes float-up {
		0% {
			transform: translateY(0);
			opacity: 1;
		}
		100% {
			transform: translateY(-20px);
			opacity: 0;
		}
	}

	.animate-float-up {
		animation: float-up 1.5s ease-out forwards;
	}

	.animate-float-up-slow {
		animation: float-up 2s ease-out forwards;
	}

	.animate-float-up-left {
		animation: float-up-left 1.8s ease-out forwards;
	}

	@keyframes float-up-left {
		0% {
			transform: translate(0, 0);
			opacity: 1;
		}
		100% {
			transform: translate(-15px, -20px);
			opacity: 0;
		}
	}

	@keyframes ping-fast {
		0% {
			transform: scale(1);
			opacity: 0.7;
		}
		70%,
		100% {
			transform: scale(2);
			opacity: 0;
		}
	}

	.animate-ping-fast {
		animation: ping-fast 0.8s cubic-bezier(0, 0, 0.2, 1) infinite;
	}
</style>
