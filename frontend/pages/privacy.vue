<template>
	<div class="bg-gradient-to-b from-white to-gray-50 dark:from-slate-900 dark:to-slate-800 min-h-screen">
		<!-- Header Section with Decorative Element -->
		<div class="relative bg-indigo-600 dark:bg-indigo-800 py-12 mb-8 overflow-hidden">
			<div class="absolute inset-0 overflow-hidden">
				<div class="absolute -right-10 -top-20 w-72 h-72 rounded-full bg-indigo-500 opacity-20"></div>
				<div class="absolute -left-20 -bottom-20 w-80 h-80 rounded-full bg-indigo-400 opacity-10"></div>
				<div class="absolute right-1/4 bottom-1/4 w-40 h-40 rounded-full bg-white opacity-10"></div>
			</div>
			<UContainer class="relative z-10">
				<div class="text-center">
					<h1 class="text-3xl md:text-4xl font-bold text-white mb-2">Privacy Policy</h1>
					<p class="text-indigo-100 max-w-3xl mx-auto">
						Last Updated: May 23, 2025
					</p>
				</div>
			</UContainer>
		</div>

		<!-- Main Content -->
		<UContainer class="mb-16">
			<!-- Introduction Card -->
			<div class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 p-6 mb-8">
				<div class="flex items-start">
					<div class="bg-indigo-50 dark:bg-indigo-900/30 p-3 rounded-lg mr-4">
						<UIcon name="i-heroicons-shield-check" class="w-6 h-6 text-indigo-600 dark:text-indigo-400"/>
					</div>
					<div>
						<h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Your Privacy Matters</h2>
						<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
							Adsy Club ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy outlines how we collect, use, disclose, and safeguard your information when you visit our website <span class="text-indigo-600 dark:text-indigo-400">www.adsyclub.com</span> and use our services. Please read this Privacy Policy carefully to understand our practices regarding your personal data.
						</p>
					</div>
				</div>
			</div>
			
			<!-- Main Privacy Content -->
			<div class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 overflow-hidden">
				<!-- Table of Contents -->
				<div class="border-b border-gray-100 dark:border-slate-700 bg-gray-50 dark:bg-slate-800/80 p-5">
					<h3 class="font-medium text-gray-900 dark:text-white mb-3 flex items-center">
						<UIcon name="i-heroicons-list-bullet" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
						Table of Contents
					</h3>
					<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
						<a href="#section-1" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">1</span>
							Information We Collect
						</a>
						<a href="#section-2" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">2</span>
							How We Use Your Information
						</a>
						<a href="#section-3" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">3</span>
							Information Sharing
						</a>
						<a href="#section-4" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">4</span>
							Data Security
						</a>
						<a href="#section-5" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">5</span>
							Your Privacy Rights
						</a>
						<a href="#section-6" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">6</span>
							Cookies & Tracking
						</a>
						<a href="#section-7" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">7</span>
							Children's Privacy
						</a>
						<a href="#section-8" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">8</span>
							Changes to Policy
						</a>
						<a href="#section-9" class="text-indigo-600 dark:text-indigo-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-indigo-100 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full mr-2 text-xs font-medium">9</span>
							Contact Information
						</a>
					</div>
				</div>
				
				<!-- Privacy Content -->
				<div class="p-3">
					<div class="space-y-8">
						<!-- Information We Collect -->
						<section id="section-1" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">1</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Information We Collect</h2>
							</div>
							<div class="pl-6">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									We collect several types of information from and about users of our platform:
								</p>

								<div class="space-y-4 mb-4">
									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h3 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-user-circle" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Personal Information
										</h3>
										<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
											When you register an account, post ads, or contact us, you may provide us with personally identifiable information such as your:
										</p>
										<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-1 mt-2">
											<li>Full name</li>
											<li>Email address</li>
											<li>Phone number</li>
											<li>Physical address or location</li>
											<li>Profile pictures</li>
											<li>Payment information (processed securely through our payment processors)</li>
											<li>Communication preferences</li>
										</ul>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h3 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-server" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Usage and Technical Data
										</h3>
										<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
											We automatically collect certain information when you visit, use or navigate our platform. This information does not reveal your specific identity but may include:
										</p>
										<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-1 mt-2">
											<li>Device and connection information (IP address, browser type, operating system)</li>
											<li>Usage patterns and browsing history on our platform</li>
											<li>Time spent on specific pages</li>
											<li>Referring websites or applications</li>
											<li>Click-stream data and interaction patterns</li>
											<li>Device identifiers and attributes</li>
										</ul>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h3 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-photo" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Content and Media
										</h3>
										<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
											When posting ads or engaging with our platform, you may provide:
										</p>
										<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-1 mt-2">
											<li>Images and photos of items for sale</li>
											<li>Text descriptions and details</li>
											<li>Price information and product specifications</li>
											<li>Comments, reviews, and messaging content</li>
										</ul>
									</div>
								</div>
							</div>
						</section>
						
						<!-- How We Use Your Information -->
						<section id="section-2" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">2</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">How We Use Your Information</h2>
							</div>
							<div class="pl-6">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									We use the information we collect for various legitimate business purposes:
								</p>

								<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-cog-6-tooth" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Service Provision</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">To provide and maintain our platform, process transactions, and manage your account</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-bell-alert" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Communications</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">To contact you regarding your account, updates, security alerts, and support messages</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-chart-bar" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Analytics & Improvement</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">To understand usage patterns and enhance user experience through site analytics</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-megaphone" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Marketing</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">To deliver relevant content, promotions, and advertising based on your preferences</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-shield-exclamation" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Security</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">To detect, prevent, and address technical issues, fraud, and security breaches</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-scale" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Legal Compliance</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">To comply with applicable laws, regulations, and legal processes</p>
											</div>
										</div>
									</div>
								</div>

								<div class="bg-gray-50 dark:bg-slate-700/50 rounded-lg p-4 border border-gray-100 dark:border-slate-600/50">
									<h4 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
										<UIcon name="i-heroicons-information-circle" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
										Legal Basis for Processing
									</h4>
									<p class="text-gray-600 dark:text-gray-300 text-sm leading-relaxed">
										We process your personal information based on legitimate interests, consent, contractual necessity, and/or compliance with legal obligations. You can withdraw consent at any time by contacting us, though this will not affect the lawfulness of processing prior to withdrawal.
									</p>
								</div>
							</div>
						</section>
						
						<!-- Information Sharing and Disclosure -->
						<section id="section-3" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">3</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Information Sharing and Disclosure</h2>
							</div>
							<div class="pl-6">
								<div class="flex items-center mb-3">
									<span class="inline-flex items-center justify-center p-1 bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded-full mr-2">
										<UIcon name="i-heroicons-check" class="w-4 h-4"/>
									</span>
									<p class="text-gray-900 dark:text-white font-medium">
										We do not sell or rent your personal information to third parties.
									</p>
								</div>
								
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									However, we may share your information in the following circumstances:
								</p>

								<div class="space-y-4 mb-4">
									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h3 class="font-medium text-gray-900 dark:text-white mb-2">Service Providers</h3>
										<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
											We may share your information with third-party vendors, service providers, contractors, or agents who perform services for us or on our behalf. These entities include:
										</p>
										<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-1 mt-2">
											<li>Cloud hosting and storage providers</li>
											<li>Payment processors</li>
											<li>Customer support services</li>
											<li>Analytics providers</li>
											<li>Email and communication service providers</li>
											<li>Security and fraud prevention services</li>
										</ul>
										<p class="text-gray-600 dark:text-gray-300 text-sm italic mt-2">
											These third parties are contractually obligated to use personal information only for the purposes for which we disclose it to them.
										</p>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h3 class="font-medium text-gray-900 dark:text-white mb-2">Legal Requirements</h3>
										<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
											We may disclose your information if required to do so by law or in response to valid requests by public authorities (e.g., a court or government agency). These circumstances may include:
										</p>
										<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-1 mt-2">
											<li>Compliance with legal obligations</li>
											<li>Response to legal processes such as court orders or subpoenas</li>
											<li>Protection against legal liability</li>
											<li>Protection of the rights, property, or safety of our users or others</li>
										</ul>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h3 class="font-medium text-gray-900 dark:text-white mb-2">Business Transfers</h3>
										<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
											If Adsy Club is involved in a merger, acquisition, or sale of all or a portion of its assets, your information may be transferred as part of that transaction. We will notify you via email and/or a prominent notice on our website of any change in ownership or uses of your personal information, as well as any choices you may have regarding your personal information.
										</p>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h3 class="font-medium text-gray-900 dark:text-white mb-2">With Your Consent</h3>
										<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
											We may share your information with third parties when you have given us your consent to do so. For example, if you choose to make your profile or listings public, this information will be visible to other users of our platform.
										</p>
									</div>
								</div>

								<div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4 border border-yellow-100 dark:border-yellow-900/30">
									<div class="flex">
										<UIcon name="i-heroicons-exclamation-triangle" class="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5 mr-3 flex-shrink-0"/>
										<p class="text-gray-800 dark:text-gray-300 text-sm">
											When you post content publicly on our platform, that information may be viewed by any user of the platform. We cannot control what other users do with information you voluntarily disclose in public areas.
										</p>
									</div>
								</div>
							</div>
						</section>
						
						<!-- Data Security -->
						<section id="section-4" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">4</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Data Security</h2>
							</div>
							<div class="pl-6">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									We implement appropriate technical and organizational security measures to protect your personal information from unauthorized access, use, alteration, or destruction. Our security practices include:
								</p>

								<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-lock-closed" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Encryption</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">Using industry-standard encryption to protect data transmission and storage</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-finger-print" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Access Controls</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">Restricting access to personal information to authorized personnel only</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-server-stack" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Secure Infrastructure</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">Hosting data in secure, certified data centers with physical and network security</p>
											</div>
										</div>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<div class="flex items-start">
											<span class="bg-indigo-100 dark:bg-indigo-900/50 p-2 rounded-md mr-3">
												<UIcon name="i-heroicons-eye" class="w-5 h-5 text-indigo-600 dark:text-indigo-400"/>
											</span>
											<div>
												<h4 class="font-medium text-gray-900 dark:text-white">Regular Monitoring</h4>
												<p class="text-gray-600 dark:text-gray-300 text-sm mt-1">Continuously monitoring systems for suspicious activities and potential vulnerabilities</p>
											</div>
										</div>
									</div>
								</div>

								<div class="bg-red-50 dark:bg-red-900/20 rounded-lg p-4 border border-red-100 dark:border-red-900/30 mb-4">
									<h4 class="font-medium text-red-700 dark:text-red-400 mb-2 flex items-center">
										<UIcon name="i-heroicons-exclamation-circle" class="w-5 h-5 mr-2"/>
										Security Limitation Notice
									</h4>
									<p class="text-gray-800 dark:text-gray-300 text-sm">
										Despite our efforts to protect your information, no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal information, we cannot guarantee its absolute security. By using our Services, you acknowledge this inherent risk.
									</p>
								</div>

								<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
									<h4 class="font-medium text-gray-900 dark:text-white mb-2">Data Breach Procedures</h4>
									<p class="text-gray-600 dark:text-gray-300 text-sm">
										In the event of a data breach that affects your personal information, we will notify you and the relevant authorities as required by applicable law. We maintain incident response procedures to ensure timely and appropriate action in response to data breaches.
									</p>
								</div>
							</div>
						</section>
						
						<!-- Your Privacy Rights -->
						<section id="section-5" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">5</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Your Privacy Rights</h2>
							</div>
							<div class="pl-6">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									Depending on your location, you may have certain rights regarding your personal information. These may include:
								</p>

								<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h4 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-document-text" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Access Rights
										</h4>
										<p class="text-gray-600 dark:text-gray-300 text-sm">
											You have the right to request copies of your personal information. We may charge a small fee for this service if allowed by law.
										</p>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h4 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-pencil-square" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Rectification Rights
										</h4>
										<p class="text-gray-600 dark:text-gray-300 text-sm">
											You have the right to request that we correct inaccurate or incomplete information about you.
										</p>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h4 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-trash" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Erasure Rights
										</h4>
										<p class="text-gray-600 dark:text-gray-300 text-sm">
											You have the right to request that we delete your personal information in certain circumstances, subject to legal retention requirements.
										</p>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h4 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-arrow-path" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Data Portability
										</h4>
										<p class="text-gray-600 dark:text-gray-300 text-sm">
											You have the right to request that we transfer your data to another organization or directly to you in a machine-readable format.
										</p>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h4 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-hand-raised" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Restriction Rights
										</h4>
										<p class="text-gray-600 dark:text-gray-300 text-sm">
											You have the right to request that we restrict the processing of your data in certain circumstances.
										</p>
									</div>

									<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
										<h4 class="font-medium text-gray-900 dark:text-white mb-2 flex items-center">
											<UIcon name="i-heroicons-x-mark" class="w-5 h-5 mr-2 text-indigo-600 dark:text-indigo-400"/>
											Objection Rights
										</h4>
										<p class="text-gray-600 dark:text-gray-300 text-sm">
											You have the right to object to our processing of your personal information for direct marketing purposes or based on legitimate interests.
										</p>
									</div>
								</div>

								<div class="bg-indigo-50 dark:bg-indigo-900/20 rounded-lg p-4 border border-indigo-100 dark:border-indigo-900/30 mb-4">
									<h4 class="font-medium text-gray-900 dark:text-white mb-2">How to Exercise Your Rights</h4>
									<p class="text-gray-600 dark:text-gray-300 text-sm mb-3">
										To exercise any of these rights, please contact us using the information provided in the "Contact Information" section. We will respond to your request within the timeframe required by applicable law.
									</p>
									<p class="text-gray-600 dark:text-gray-300 text-sm">
										You will not be discriminated against for exercising any of your privacy rights. However, we may not be able to fulfill some requests if doing so would prevent us from complying with legal obligations or providing the services you have requested.
									</p>
								</div>
							</div>
						</section>
						
						<!-- Cookies & Tracking -->
						<section id="section-6" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">6</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Cookies & Tracking Technologies</h2>
							</div>
							<div class="pl-6">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									We use cookies and similar tracking technologies to enhance your experience on our platform. These technologies allow us to remember your preferences, understand how you use our site, and personalize content.
								</p>

								<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm mb-4">
									<h4 class="font-medium text-gray-900 dark:text-white mb-2">Types of Cookies We Use</h4>
									<div class="space-y-3">
										<div>
											<p class="font-medium text-gray-800 dark:text-gray-200">Essential Cookies</p>
											<p class="text-gray-600 dark:text-gray-300 text-sm">
												Necessary for the operation of our platform. They enable basic functions like page navigation and access to secure areas.
											</p>
										</div>
										<div>
											<p class="font-medium text-gray-800 dark:text-gray-200">Functional Cookies</p>
											<p class="text-gray-600 dark:text-gray-300 text-sm">
												Allow us to remember choices you make and provide enhanced, personalized features.
											</p>
										</div>
										<div>
											<p class="font-medium text-gray-800 dark:text-gray-200">Analytics Cookies</p>
											<p class="text-gray-600 dark:text-gray-300 text-sm">
												Help us understand how visitors interact with our platform by collecting and reporting information anonymously.
											</p>
										</div>
										<div>
											<p class="font-medium text-gray-800 dark:text-gray-200">Advertising Cookies</p>
											<p class="text-gray-600 dark:text-gray-300 text-sm">
												Used to deliver relevant advertisements based on your interests and to measure the effectiveness of marketing campaigns.
											</p>
										</div>
									</div>
								</div>

								<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm mb-4">
									<h4 class="font-medium text-gray-900 dark:text-white mb-2">Cookie Management</h4>
									<p class="text-gray-600 dark:text-gray-300 text-sm mb-3">
										Most web browsers allow you to control cookies through their settings. You can typically delete cookies and adjust your cookie preferences at any time. However, if you disable cookies, some features of our platform may not function properly.
									</p>
									<p class="text-gray-600 dark:text-gray-300 text-sm">
										You can learn more about cookies and how to manage them in your browser at <a href="http://www.allaboutcookies.org" class="text-indigo-600 dark:text-indigo-400 hover:underline">www.allaboutcookies.org</a>.
									</p>
								</div>

								<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm">
									<h4 class="font-medium text-gray-900 dark:text-white mb-2">Do Not Track Signals</h4>
									<p class="text-gray-600 dark:text-gray-300 text-sm">
										Some browsers have a "Do Not Track" feature that signals to websites that you visit that you do not want to have your online activity tracked. Given that there is not yet a common understanding of how to interpret these signals, our platform does not currently respond to "Do Not Track" signals.
									</p>
								</div>
							</div>
						</section>
						
						<!-- Children's Privacy -->
						<section id="section-7" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">7</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Children's Privacy</h2>
							</div>
							<div class="pl-6">
								<div class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-4 border border-orange-100 dark:border-orange-900/30 mb-4">
									<div class="flex">
										<UIcon name="i-heroicons-exclamation-triangle" class="w-5 h-5 text-orange-600 dark:text-orange-400 mt-0.5 mr-3 flex-shrink-0"/>
										<div>
											<h4 class="font-medium text-orange-800 dark:text-orange-400 mb-1">Age Restriction</h4>
											<p class="text-gray-800 dark:text-gray-300 text-sm">
												Our Services are not directed to individuals under the age of 18. We do not knowingly collect personal information from children. If you are a parent or guardian and believe that your child has provided us with personal information, please contact us immediately.
											</p>
										</div>
									</div>
								</div>

								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									If we learn that we have collected personal information from a child under the age of 18, we will take steps to delete that information as quickly as possible. If you believe we might have any information from or about a child, please contact us using the information provided in the "Contact Information" section.
								</p>
							</div>
						</section>
						
						<!-- Changes to This Privacy Policy -->
						<section id="section-8" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">8</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Changes to This Privacy Policy</h2>
							</div>
							<div class="pl-6">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									We may update our Privacy Policy from time to time to reflect changes in our practices, technologies, legal requirements, and other factors. When we make changes, we will update the "Last Updated" date at the top of this Privacy Policy.
								</p>

								<div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-gray-100 dark:border-slate-600 shadow-sm mb-4">
									<h4 class="font-medium text-gray-900 dark:text-white mb-2">Notification of Changes</h4>
									<p class="text-gray-600 dark:text-gray-300 text-sm">
										For significant changes to this Privacy Policy, we will make reasonable efforts to notify you, such as by sending an email to the address associated with your account (if applicable) or by placing a prominent notice on our website. We encourage you to periodically review this Privacy Policy to stay informed about our information practices.
									</p>
								</div>

								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									Your continued use of our Services after changes to this Privacy Policy have been posted constitutes your acceptance of the updated Privacy Policy.
								</p>
							</div>
						</section>
						
						<!-- Contact Information -->
						<section id="section-9" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-indigo-100 dark:bg-indigo-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-indigo-600 dark:text-indigo-400 font-semibold">9</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Contact Information</h2>
							</div>
							<div class="pl-6">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									If you have any questions, concerns, or requests regarding this Privacy Policy or our privacy practices, please contact us at:
								</p>

								<div class="bg-indigo-50 dark:bg-indigo-900/20 rounded-lg p-5 border border-indigo-100 dark:border-indigo-900/30">
									<div class="space-y-3">
										<div class="flex items-start">
											<UIcon name="i-heroicons-envelope" class="w-5 h-5 text-indigo-600 dark:text-indigo-400 mt-0.5 mr-3"/>
											<div>
												<p class="font-medium text-gray-900 dark:text-white">Email</p>
												<p class="text-gray-600 dark:text-gray-300">privacy@adsyclub.com</p>
											</div>
										</div>
										<div class="flex items-start">
											<UIcon name="i-heroicons-phone" class="w-5 h-5 text-indigo-600 dark:text-indigo-400 mt-0.5 mr-3"/>
											<div>
												<p class="font-medium text-gray-900 dark:text-white">Phone</p>
												<p class="text-gray-600 dark:text-gray-300">+880 1234 567890</p>
											</div>
										</div>
										<div class="flex items-start">
											<UIcon name="i-heroicons-map-pin" class="w-5 h-5 text-indigo-600 dark:text-indigo-400 mt-0.5 mr-3"/>
											<div>
												<p class="font-medium text-gray-900 dark:text-white">Address</p>
												<p class="text-gray-600 dark:text-gray-300">123 Business Avenue, Dhaka, Bangladesh</p>
											</div>
										</div>
									</div>
								</div>
							</div>
						</section>
					</div>
				</div>
			</div>
			
			<!-- Footer Section -->
			<div class="mt-10 text-center">
				<p class="text-gray-500 dark:text-gray-400 text-sm">
					© 2025 Adsy Club. All Rights Reserved.
				</p>
			</div>
		</UContainer>
	</div>
</template>

<script setup>
import { ref, onMounted } from 'vue';

// Track whether the page has been loaded
const pageLoaded = ref(false);

// Scroll to section when clicking on table of contents links
const scrollToSection = (event, sectionId) => {
  event.preventDefault();
  const element = document.getElementById(sectionId);
  if (element) {
    window.scrollTo({
      top: element.offsetTop - 80,
      behavior: 'smooth'
    });
  }
};

// Highlight the current section based on scroll position
const highlightCurrentSection = () => {
  const sections = document.querySelectorAll('section[id^="section-"]');
  const scrollPosition = window.scrollY + 100;
  
  sections.forEach(section => {
    const sectionTop = section.offsetTop;
    const sectionHeight = section.offsetHeight;
    
    if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
      const id = section.getAttribute('id');
      const link = document.querySelector(`a[href="#${id}"]`);
      
      if (link) {
        document.querySelectorAll('a[href^="#section-"]').forEach(a => {
          a.classList.remove('font-medium', 'bg-indigo-50', 'dark:bg-indigo-900/30', 'px-2', 'py-1', 'rounded');
        });
        
        link.classList.add('font-medium', 'bg-indigo-50', 'dark:bg-indigo-900/30', 'px-2', 'py-1', 'rounded');
      }
    }
  });
};

// Add smooth fade-in animation on page load
onMounted(() => {
  setTimeout(() => {
    pageLoaded.value = true;
    
    // Apply animation delays to sections
    document.querySelectorAll('section[id^="section-"]').forEach(section => {
      const sectionNumber = parseInt(section.id.split('-')[1]);
      section.style.animationDelay = `${sectionNumber * 0.1}s`;
    });
  }, 100);
  
  // Add scroll event listener for section highlighting
  window.addEventListener('scroll', highlightCurrentSection);
  
  // Initial highlighting
  highlightCurrentSection();
  
  // Fix table of contents links
  document.querySelectorAll('a[href^="#section-"]').forEach(link => {
    link.addEventListener('click', (e) => {
      scrollToSection(e, link.getAttribute('href').substring(1));
    });
  });
  
  // Clean up event listener
  return () => {
    window.removeEventListener('scroll', highlightCurrentSection);
  };
});
</script>

<style scoped>
/* Smooth transitions for theme changes */
* {
  transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease, box-shadow 0.3s ease;
}

/* Scrollbar styling for webkit browsers */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.05);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb {
  background: rgba(79, 70, 229, 0.5);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(79, 70, 229, 0.7);
}

/* Animations */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes pulseGlow {
  0% { box-shadow: 0 0 0 0 rgba(79, 70, 229, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(79, 70, 229, 0); }
  100% { box-shadow: 0 0 0 0 rgba(79, 70, 229, 0); }
}

/* Apply animations to sections */
section {
  animation: fadeIn 0.6s ease forwards;
  opacity: 0;
}

/* Enhance focus styles for better accessibility */
a:focus, button:focus {
  outline: 2px solid rgba(79, 70, 229, 0.5);
  outline-offset: 2px;
}

/* Gradient animation for links */
a[href^="#section-"] {
  position: relative;
  transition: all 0.3s ease;
}

a[href^="#section-"]:hover {
  background: linear-gradient(90deg, rgba(79, 70, 229, 0.1) 0%, rgba(79, 70, 229, 0) 100%);
  padding-left: 0.5rem;
  padding-right: 0.5rem;
  border-radius: 4px;
}

/* Card hover effects */
.bg-white, .bg-slate-800 {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.bg-white:hover, .bg-slate-800:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
}

/* Print styles */
@media print {
  .bg-gradient-to-b {
    background: white !important;
    color: black !important;
  }
  
  .bg-indigo-600, .bg-indigo-800 {
    background: #f0f0f0 !important;
    color: black !important;
  }
  
  * {
    color: black !important;
    background-color: transparent !important;
  }
  
  a {
    text-decoration: underline;
  }
  
  section {
    page-break-inside: avoid;
  }
}
</style>
