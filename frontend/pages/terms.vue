<template>
	<div class="bg-gradient-to-b from-white to-gray-50 dark:from-slate-900 dark:to-slate-800 min-h-screen">
		<!-- Header Section with Decorative Element -->
		<div class="relative bg-blue-600 dark:bg-blue-800 py-12 mb-8 overflow-hidden">
			<div class="absolute inset-0 overflow-hidden">
				<div class="absolute -right-10 -top-20 w-72 h-72 rounded-full bg-blue-500 opacity-20"></div>
				<div class="absolute -left-20 -bottom-20 w-80 h-80 rounded-full bg-blue-400 opacity-10"></div>
				<div class="absolute right-1/4 bottom-1/4 w-40 h-40 rounded-full bg-white opacity-10"></div>
			</div>
			<UContainer class="relative z-10">
				<div class="text-center">
					<h1 class="text-3xl md:text-4xl font-bold text-white mb-2">Terms and Conditions</h1>
					<p class="text-blue-100 max-w-3xl mx-auto">
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
					<div class="bg-blue-50 dark:bg-blue-900/30 p-3 rounded-lg mr-4">
						<UIcon name="i-heroicons-document-text" class="w-6 h-6 text-blue-600 dark:text-blue-400"/>
					</div>
					<div>
						<h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Welcome to Adsy Club</h2>
						<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
							These Terms and Conditions ("Terms") govern your access to and use of the Adsy Club platform, including any content, functionality, and services offered on or through our website. Please read these Terms carefully before using our services.
						</p>
					</div>
				</div>
			</div>
			
			<!-- Main Terms Content -->
			<div class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 overflow-hidden">
				<!-- Table of Contents -->
				<div class="border-b border-gray-100 dark:border-slate-700 bg-gray-50 dark:bg-slate-800/80 p-5">
					<h3 class="font-medium text-gray-900 dark:text-white mb-3 flex items-center">
						<UIcon name="i-heroicons-list-bullet" class="w-5 h-5 mr-2 text-blue-600 dark:text-blue-400"/>
						Table of Contents
					</h3>
					<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
						<a href="#section-1" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">1</span>
							Introduction
						</a>
						<a href="#section-2" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">2</span>
							Acceptance of Terms
						</a>
						<a href="#section-3" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">3</span>
							User Accounts
						</a>
						<a href="#section-4" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">4</span>
							Content Policies
						</a>
						<a href="#section-5" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">5</span>
							Prohibited Activities
						</a>
						<a href="#section-6" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">6</span>
							Intellectual Property
						</a>
						<a href="#section-7" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">7</span>
							Termination
						</a>
						<a href="#section-8" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">8</span>
							Disclaimers
						</a>
						<a href="#section-9" class="text-blue-600 dark:text-blue-400 hover:underline text-sm flex items-center">
							<span class="w-5 h-5 inline-flex items-center justify-center bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full mr-2 text-xs font-medium">9</span>
							Contact Information
						</a>
					</div>
				</div>
				
				<!-- Terms Content -->
				<div class="p-3">
					<div class="space-y-8">
						<!-- Introduction -->
						<section id="section-1" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">1</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Introduction</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									Welcome to Adsy Club, a premium platform for classified advertisements and business networking. By accessing or using our website at <span class="text-blue-600 dark:text-blue-400">www.adsyclub.com</span> (the "Site"), mobile applications, or any other services provided by Adsy Club (collectively, the "Services"), you agree to comply with and be bound by these Terms and Conditions.
								</p>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									These Terms constitute a legally binding agreement between you and Adsy Club regarding your use of the Services. If you do not agree with these Terms, please refrain from using our Services.
								</p>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									We may update these Terms from time to time to reflect changes in our practices or for legal, operational, or regulatory reasons. The most current version will always be available on our website.
								</p>
							</div>
						</section>
						
						<!-- Acceptance of Terms -->
						<section id="section-2" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">2</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Acceptance of Terms</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									By using our Services, you confirm that:
								</p>
								<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-2 mb-4">
									<li>You are at least 18 years of age or the legal age of majority in your jurisdiction, whichever is greater.</li>
									<li>You possess the legal capacity to enter into binding agreements.</li>
									<li>If you are using the Services on behalf of an organization or entity, you have the authority to bind that entity to these Terms.</li>
									<li>You will comply with all applicable local, state, national, and international laws and regulations.</li>
								</ul>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									Your continued use of our Services following any changes to these Terms constitutes your acceptance of those changes. It is your responsibility to review these Terms periodically.
								</p>
							</div>
						</section>
						
						<!-- User Accounts -->
						<section id="section-3" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">3</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">User Accounts</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									To access certain features of our Services, you may need to create a user account. You agree to:
								</p>
								<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-2 mb-4">
									<li>Provide accurate, current, and complete information during registration.</li>
									<li>Maintain and promptly update your account information.</li>
									<li>Keep your password confidential and secure.</li>
									<li>Be solely responsible for all activities that occur under your account.</li>
									<li>Notify us immediately of any unauthorized use of your account or any other security breach.</li>
									<li>Ensure that you log out from your account at the end of each session when accessing our Services from a shared computer or public device.</li>
								</ul>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									You may not transfer or sell your account to another party. We reserve the right to suspend or terminate your account if any information provided during registration or thereafter proves to be inaccurate, incomplete, or fraudulent.
								</p>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									Adsy Club is not responsible for any loss or damage arising from your failure to comply with these account security obligations.
								</p>
							</div>
						</section>
						
						<!-- Content Policies -->
						<section id="section-4" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">4</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Content Policies</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									Users may post classified advertisements, business profiles, and other content on our platform. By posting content, you:
								</p>
								<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-2 mb-4">
									<li>Grant Adsy Club a non-exclusive, worldwide, royalty-free, sublicensable, and transferable license to use, reproduce, modify, adapt, publish, translate, distribute, and display such content across our Services and promotional channels.</li>
									<li>Represent and warrant that you own or have the necessary rights to grant us the license described above.</li>
									<li>Agree that your content does not violate the privacy rights, publicity rights, intellectual property rights, or any other rights of any third party.</li>
									<li>Understand that you are solely responsible for all content you post.</li>
								</ul>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									While we do not claim ownership of your content, the license you grant allows us to use your content to operate, promote, and improve our Services.
								</p>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									Adsy Club reserves the right to review, monitor, and remove any content that violates these Terms or that we find objectionable, at our sole discretion and without prior notice.
								</p>
							</div>
						</section>
						
						<!-- Prohibited Activities -->
						<section id="section-5" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">5</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Prohibited Activities</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									You agree not to engage in any of the following prohibited activities:
								</p>
								<div class="bg-red-50 dark:bg-red-900/20 rounded-lg p-4 border border-red-100 dark:border-red-900/30 mb-4">
									<h4 class="font-medium text-red-700 dark:text-red-400 mb-2">Content Violations</h4>
									<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-1.5">
										<li>Posting false, misleading, deceptive, or fraudulent information.</li>
										<li>Posting content that is defamatory, obscene, pornographic, vulgar, offensive, threatening, or harassing.</li>
										<li>Posting content that promotes discrimination, bigotry, racism, or harm against any individual or group.</li>
										<li>Posting content that infringes upon intellectual property rights, including copyrights and trademarks.</li>
										<li>Posting content that violates any person's right to privacy or publicity.</li>
									</ul>
								</div>
								<div class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-4 border border-orange-100 dark:border-orange-900/30 mb-4">
									<h4 class="font-medium text-orange-700 dark:text-orange-400 mb-2">Operational Violations</h4>
									<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-1.5">
										<li>Using our Services for any illegal purpose or in violation of any local, state, national, or international law.</li>
										<li>Attempting to interfere with, compromise, or disrupt the systems or security of our Services.</li>
										<li>Circumventing, disabling, or otherwise interfering with security-related features of our Services.</li>
										<li>Using any automated system (bots, scrapers, crawlers) to access our Services without our express written permission.</li>
										<li>Attempting to impersonate another user, person, or entity, or falsely stating or misrepresenting your affiliation with a person or entity.</li>
									</ul>
								</div>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									Violation of these prohibitions may result in the removal of content, suspension or termination of your account, and potentially legal action, depending on the severity and nature of the violation.
								</p>
							</div>
						</section>
						
						<!-- Intellectual Property -->
						<section id="section-6" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">6</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Intellectual Property</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									The Adsy Club platform, including its logo, trademarks, service marks, design elements, text, software, graphics, layout, and other content contained on the Site (collectively, "Adsy Club Content"), is owned by or licensed to Adsy Club and is protected by copyright, trademark, and other intellectual property laws.
								</p>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									Subject to your compliance with these Terms, Adsy Club grants you a limited, non-exclusive, non-transferable, and revocable license to access and use the Services and Adsy Club Content for personal and non-commercial purposes.
								</p>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									You may not:
								</p>
								<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-2 mb-4">
									<li>Modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell any Adsy Club Content.</li>
									<li>Use any Adsy Club Content for commercial purposes without our express written consent.</li>
									<li>Remove any copyright, trademark, or other proprietary notices from Adsy Club Content.</li>
									<li>Use any data mining, robots, or similar data gathering or extraction methods on our Services.</li>
								</ul>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									If you believe that any content on our Site infringes upon your copyright, please contact us with details of the alleged infringement.
								</p>
							</div>
						</section>
						
						<!-- Termination -->
						<section id="section-7" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">7</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Termination</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									Adsy Club reserves the right to suspend, disable, or terminate your account and access to our Services at our sole discretion, without prior notice or liability, for any reason, including but not limited to:
								</p>
								<ul class="list-disc pl-5 text-gray-600 dark:text-gray-300 space-y-2 mb-4">
									<li>A breach of these Terms or any other policies referenced herein.</li>
									<li>Upon request by law enforcement or other government agencies.</li>
									<li>Due to unexpected technical or security issues.</li>
									<li>Extended periods of inactivity.</li>
									<li>Engagement in fraudulent or illegal activities.</li>
									<li>Any other conduct that we believe, in our sole discretion, violates these Terms or is harmful to other users or third parties, or the business interests of Adsy Club.</li>
								</ul>
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
									Upon termination, your right to use the Services will immediately cease. All provisions of these Terms that by their nature should survive termination shall survive, including without limitation, ownership provisions, warranty disclaimers, indemnity, and limitations of liability.
								</p>
							</div>
						</section>
						
						<!-- Disclaimers and Limitations -->
						<section id="section-8" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">8</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Disclaimers and Limitations</h2>
							</div>
							<div class="pl-11">
								<div class="bg-gray-50 dark:bg-slate-700/50 rounded-lg p-4 border border-gray-100 dark:border-slate-600/50 mb-4">
									<h4 class="font-medium text-gray-800 dark:text-white mb-2">Disclaimer of Warranties</h4>
									<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
										THE SERVICES ARE PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. ADSY CLUB EXPRESSLY DISCLAIMS ALL WARRANTIES, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
									</p>
								</div>
								<div class="bg-gray-50 dark:bg-slate-700/50 rounded-lg p-4 border border-gray-100 dark:border-slate-600/50 mb-4">
									<h4 class="font-medium text-gray-800 dark:text-white mb-2">Limitation of Liability</h4>
									<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
										TO THE FULLEST EXTENT PERMITTED BY LAW, ADSY CLUB SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO, DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR OTHER INTANGIBLE LOSSES, RESULTING FROM: (I) YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE SERVICES; (II) ANY CONDUCT OR CONTENT OF ANY THIRD PARTY ON THE SERVICES; (III) ANY CONTENT OBTAINED FROM THE SERVICES; AND (IV) UNAUTHORIZED ACCESS, USE, OR ALTERATION OF YOUR TRANSMISSIONS OR CONTENT.
									</p>
								</div>
								<div class="bg-gray-50 dark:bg-slate-700/50 rounded-lg p-4 border border-gray-100 dark:border-slate-600/50 mb-4">
									<h4 class="font-medium text-gray-800 dark:text-white mb-2">Indemnification</h4>
									<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
										You agree to defend, indemnify, and hold harmless Adsy Club and its affiliates, officers, directors, employees, and agents, from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney's fees) arising from: (i) your use of and access to the Services; (ii) your violation of any term of these Terms; (iii) your violation of any third-party right, including without limitation any copyright, property, or privacy right; or (iv) any claim that your content caused damage to a third party.
									</p>
								</div>
								<div class="bg-gray-50 dark:bg-slate-700/50 rounded-lg p-4 border border-gray-100 dark:border-slate-600/50">
									<h4 class="font-medium text-gray-800 dark:text-white mb-2">Governing Law</h4>
									<p class="text-gray-600 dark:text-gray-300 leading-relaxed">
										These Terms shall be governed by and construed in accordance with the laws of Bangladesh, without regard to its conflict of law provisions. Any legal action or proceeding arising out of these Terms or your use of the Services shall be brought exclusively in the courts located in Dhaka, Bangladesh, and you consent to the personal jurisdiction of such courts.
									</p>
								</div>
							</div>
						</section>
						
						<!-- Contact Information -->
						<section id="section-9" class="scroll-mt-24">
							<div class="flex items-center mb-3">
								<div class="bg-blue-100 dark:bg-blue-900/50 w-8 h-8 rounded-full flex items-center justify-center mr-3">
									<span class="text-blue-600 dark:text-blue-400 font-semibold">9</span>
								</div>
								<h2 class="text-xl font-semibold text-gray-900 dark:text-white">Contact Information</h2>
							</div>
							<div class="pl-11">
								<p class="text-gray-600 dark:text-gray-300 leading-relaxed mb-4">
									If you have any questions, concerns, or feedback regarding these Terms or our Services, please contact us at:
								</p>
								<div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-5 border border-blue-100 dark:border-blue-900/30">
									<div class="space-y-3">
										<div class="flex items-start">
											<UIcon name="i-heroicons-envelope" class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-3"/>
											<div>
												<p class="font-medium text-gray-900 dark:text-white">Email</p>
												<p class="text-gray-600 dark:text-gray-300">support@adsyclub.com</p>
											</div>
										</div>
										<div class="flex items-start">
											<UIcon name="i-heroicons-phone" class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-3"/>
											<div>
												<p class="font-medium text-gray-900 dark:text-white">Phone</p>
												<p class="text-gray-600 dark:text-gray-300">+880 1234 567890</p>
											</div>
										</div>
										<div class="flex items-start">
											<UIcon name="i-heroicons-map-pin" class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-3"/>
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
          a.classList.remove('font-medium', 'bg-blue-50', 'dark:bg-blue-900/30', 'px-2', 'py-1', 'rounded');
        });
        
        link.classList.add('font-medium', 'bg-blue-50', 'dark:bg-blue-900/30', 'px-2', 'py-1', 'rounded');
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
  background: rgba(59, 130, 246, 0.5);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(59, 130, 246, 0.7);
}

/* Animations */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes pulseGlow {
  0% { box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(59, 130, 246, 0); }
  100% { box-shadow: 0 0 0 0 rgba(59, 130, 246, 0); }
}

/* Apply animations to sections */
section {
  animation: fadeIn 0.6s ease forwards;
  opacity: 0;
}

/* Enhance focus styles for better accessibility */
a:focus, button:focus {
  outline: 2px solid rgba(59, 130, 246, 0.5);
  outline-offset: 2px;
}

/* Gradient animation for links */
a[href^="#section-"] {
  position: relative;
  transition: all 0.3s ease;
}

a[href^="#section-"]:hover {
  background: linear-gradient(90deg, rgba(59, 130, 246, 0.1) 0%, rgba(59, 130, 246, 0) 100%);
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
  
  .bg-blue-600, .bg-blue-800 {
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
}
</style>
