<template>
  <UContainer>
    <div
      class="min-h-screen py-16 px-4 sm:px-6 bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800"
    >
      <div class="max-w-5xl mx-auto">
        <!-- Section Header -->
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
              <a href="#" class="text-sky-500 dark:text-sky-400 hover:underline"
                >Contact our team</a
              >
            </p>
          </div>
        </div>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
// Animation for shimmer effect
</script>

<style>
/* Using Tailwind's built-in classes for animations */
@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 1.5s infinite;
}

@keyframes ping {
  75%,
  100% {
    transform: scale(2);
    opacity: 0;
  }
}
</style>
