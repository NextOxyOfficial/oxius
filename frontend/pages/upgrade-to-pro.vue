<template>
  <UContainer>
    <div
      class="min-h-screen bg-slate-50 py-12 px-4 sm:px-6 font-sans antialiased"
    >
      <div class="max-w-4xl mx-auto">
        <!-- Pricing Cards Container -->
        <div class="flex flex-col md:flex-row gap-6">
          <!-- Free Plan -->
          <div
            class="w-full md:w-1/2 bg-white rounded-xl overflow-hidden shadow-sm hover:shadow-lg transition-all duration-300 relative"
          >
            <!-- Card Header -->
            <div class="p-5 bg-slate-800 text-white">
              <h3 class="text-lg font-bold">Free Plan</h3>
              <div class="mt-2 flex items-baseline">
                <span class="text-3xl font-bold">$0</span>
                <span class="ml-1 text-sm opacity-80">/month</span>
              </div>
            </div>

            <!-- Card Body -->
            <div class="p-5">
              <ul class="space-y-3 mb-6">
                <li class="flex items-center text-sm">
                  <div
                    class="w-5 h-5 rounded-full bg-slate-100 flex items-center justify-center mr-3 flex-shrink-0"
                  >
                    <svg
                      class="w-3 h-3 text-slate-500"
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
                  <span>Basic store setup</span>
                </li>
                <li class="flex items-center text-sm">
                  <div
                    class="w-5 h-5 rounded-full bg-slate-100 flex items-center justify-center mr-3 flex-shrink-0"
                  >
                    <svg
                      class="w-3 h-3 text-slate-500"
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
                  <span>Up to 10 products</span>
                </li>
                <li class="flex items-center text-sm">
                  <div
                    class="w-5 h-5 rounded-full bg-slate-100 flex items-center justify-center mr-3 flex-shrink-0"
                  >
                    <svg
                      class="w-3 h-3 text-slate-500"
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
                  <span>Community support</span>
                </li>
              </ul>

              <button
                class="w-full py-2 bg-slate-100 text-slate-800 rounded-lg text-sm font-medium hover:bg-slate-200 transition-colors duration-200"
              >
                Get Started
              </button>
            </div>
          </div>

          <!-- Pro Plan -->
          <div
            class="w-full md:w-1/2 bg-white rounded-xl overflow-hidden shadow-md hover:shadow-xl transition-all duration-300 relative transform hover:-translate-y-1 group"
          >
            <!-- Most Popular Badge - RIGHT SIDE -->
            <div class="absolute top-0 right-0 w-full h-8 overflow-hidden">
              <div
                class="absolute -right-12 top-6 transform rotate-45 w-40 bg-purple-600 text-white text-xs font-bold py-1 text-center shadow-md"
              >
                MOST POPULAR
              </div>
            </div>

            <!-- Card Header -->
            <div
              class="p-5 bg-gradient-to-r from-purple-600 to-violet-600 text-white"
            >
              <h3 class="text-lg font-bold">Pro Plan</h3>
              <div class="mt-2 flex items-baseline">
                <span class="text-3xl font-bold">$29</span>
                <span class="ml-1 text-sm opacity-80">/month</span>
              </div>
            </div>

            <!-- Card Body -->
            <div class="p-5 relative overflow-hidden">
              <!-- Background Effect -->
              <div
                class="absolute -right-10 -bottom-10 w-40 h-40 rounded-full bg-gradient-to-br from-purple-100 to-violet-100 opacity-0 group-hover:opacity-30 transition-opacity duration-500"
              ></div>

              <ul class="space-y-3 mb-6 relative z-10">
                <li class="flex items-center text-sm">
                  <div
                    class="w-5 h-5 rounded-full bg-purple-100 flex items-center justify-center mr-3 flex-shrink-0"
                  >
                    <svg
                      class="w-3 h-3 text-purple-600"
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
                  <span class="font-medium">Create store</span>
                </li>
                <li class="flex items-center text-sm">
                  <div
                    class="w-5 h-5 rounded-full bg-purple-100 flex items-center justify-center mr-3 flex-shrink-0"
                  >
                    <svg
                      class="w-3 h-3 text-purple-600"
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
                  <span class="font-medium">Add unlimited products</span>
                </li>
                <li class="flex items-center text-sm">
                  <div
                    class="w-5 h-5 rounded-full bg-purple-100 flex items-center justify-center mr-3 flex-shrink-0"
                  >
                    <svg
                      class="w-3 h-3 text-purple-600"
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
                  <span class="font-medium">Priority support</span>
                </li>
                <li class="flex items-center text-sm">
                  <div
                    class="w-5 h-5 rounded-full bg-purple-100 flex items-center justify-center mr-3 flex-shrink-0"
                  >
                    <svg
                      class="w-3 h-3 text-purple-600"
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
                  <span class="font-medium">Advanced analytics</span>
                </li>
              </ul>

              <button
                class="w-full py-2 bg-gradient-to-r from-purple-600 to-violet-600 text-white rounded-lg text-sm font-medium hover:from-purple-700 hover:to-violet-700 transition-colors duration-200 relative z-10 shadow-sm hover:shadow group-hover:animate-pulse-subtle"
              >
                Upgrade Now
              </button>
            </div>

            <!-- Border Glow Effect -->
            <div
              class="absolute inset-0 rounded-xl border-2 border-transparent opacity-0 group-hover:opacity-100 group-hover:border-purple-400/30 transition-all duration-300"
            ></div>
          </div>
        </div>

        <!-- Footer Text -->
        <p class="text-center text-xs text-slate-500 mt-6">
          All plans include 14-day free trial. No credit card required.
        </p>
      </div>
    </div>
  </UContainer>
</template>

<style scoped>
@keyframes pulse-subtle {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.02);
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s infinite;
}

/* Shimmer effect for Pro card */
.group:hover::before {
  content: "";
  position: absolute;
  top: 0;
  left: -100%;
  width: 50%;
  height: 100%;
  background: linear-gradient(
    to right,
    rgba(255, 255, 255, 0) 0%,
    rgba(255, 255, 255, 0.3) 50%,
    rgba(255, 255, 255, 0) 100%
  );
  animation: shimmer 2s infinite;
  z-index: 1;
}

@keyframes shimmer {
  0% {
    left: -100%;
  }
  100% {
    left: 200%;
  }
}
</style>
