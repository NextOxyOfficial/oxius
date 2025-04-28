<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 pt-3 flex-1">
    <!-- Header with gradient background -->
    <div
      class="relative overflow-hidden rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 p-6 mb-8 shadow-lg"
    >
      <div
        class="flex flex-col md:flex-row justify-between items-start md:items-center z-10 relative"
      >
        <div class="text-white w-full">
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center w-full">
            <div>
              <h1 class="text-3xl font-bold">MindForce</h1>
              <p class="text-blue-100 mt-1">
                Collaborative problem-solving network
              </p>
            </div>
            <button
              @click="openCreateModal"
              class="mt-4 sm:mt-0 inline-flex items-center justify-center rounded-md text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-white text-blue-700 hover:bg-blue-50 h-11 px-6 py-2 shadow-md hover:shadow-lg transform hover:-translate-y-0.5"
              :disabled="isCreating"
            >
              <span v-if="isCreating" class="flex items-center">
                <svg
                  class="animate-spin -ml-1 mr-2 h-4 w-4"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                Loading...
              </span>
              <span v-else class="flex items-center">
                <Plus class="h-4 w-4 mr-2" /> Post a Problem
              </span>
            </button>
          </div>
        </div>
      </div>

      <!-- Decorative elements -->
      <div class="absolute right-0 bottom-0 opacity-10">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="180"
          height="180"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="text-white"
        >
          <path
            d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"
          ></path>
          <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
          <line x1="12" y1="22.08" x2="12" y2="12"></line>
        </svg>
      </div>
    </div>

    <!-- Main Content -->
    <div
      class="bg-white rounded-xl shadow-md border border-gray-100 transition-all"
    >
      <!-- Tabs -->
      <div
        class="flex flex-col sm:flex-row justify-between items-center px-5 py-4 border-b border-gray-100 gap-4"
      >
        <div class="bg-gray-50 p-1 rounded-lg inline-flex shadow-sm w-full sm:w-auto">
          <button
            v-for="tab in tabs"
            :key="tab.value"
            @click="activeTab = tab.value"
            :class="[
              'relative px-4 py-2 text-xs font-medium transition-all duration-200 ease-in-out flex-1 sm:flex-initial whitespace-nowrap',
              activeTab === tab.value
                ? 'text-blue-700 bg-white rounded-md shadow-sm'
                : 'text-gray-500 hover:text-gray-700',
            ]"
          >
            {{ tab.label }}
          </button>
        </div>

        <div class="w-full sm:w-64 md:w-80">
          <div class="relative w-full">
            <Search class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
            <svg
              v-if="isSearching"
              class="animate-spin absolute right-3 top-2.5 h-4 w-4 text-gray-400"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              ></circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              ></path>
            </svg>
            <input
              type="text"
              placeholder="Search problems..."
              class="flex h-10 w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 pl-10 pr-10 transition-all"
              v-model="searchQuery"
              @input="handleSearch"
            />
          </div>
        </div>
      </div>

      <div class="px-2 py-3">
        <!-- Active Problems Tab -->
        <div v-if="activeTab === 'active'" class="space-y-4">
          <!-- Skeleton loading state -->
          <div v-if="isLoading" class="space-y-4">
            <div
              v-for="i in 3"
              :key="i"
              class="bg-white border border-gray-100 rounded-lg px-2 py-3 animate-pulse"
            >
              <div class="flex justify-between items-start mb-3">
                <div class="flex items-center">
                  <div class="h-10 w-10 rounded-full bg-gray-200"></div>
                  <div class="ml-3">
                    <div class="h-4 w-32 bg-gray-200 rounded"></div>
                    <div class="h-3 w-24 bg-gray-200 rounded mt-2"></div>
                  </div>
                </div>
                <div class="h-6 w-24 bg-gray-200 rounded-full"></div>
              </div>
              <div class="h-4 w-16 bg-gray-200 rounded-full mb-3"></div>
              <div class="h-5 w-3/4 bg-gray-200 rounded mb-4"></div>
              <div class="flex justify-between items-center">
                <div class="flex space-x-3">
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                </div>
              </div>
            </div>
          </div>

          <div v-else-if="activeProblems?.length > 0" class="space-y-4">
            <div
              v-for="problem in activeProblems"
              :key="problem.id"
              class="bg-white border border-gray-100 rounded-lg px-2 py-3 hover:shadow-lg transition-all duration-300 cursor-pointer relative overflow-hidden"
              @click="openProblemDetail(problem)"
            >
              <!-- Highlight effect on hover that doesn't obscure text -->
              <div
                class="absolute inset-0 bg-blue-50 opacity-0 hover:opacity-10 transition-opacity duration-300 pointer-events-none"
              ></div>

              <div class="flex justify-between items-start mb-3 relative">
                <div class="flex items-center">
                  <div
                    class="h-10 w-10 rounded-full overflow-hidden border-2 border-white shadow-sm"
                  >
                    <img
                      :src="problem?.user_details?.images || '/placeholder.svg'"
                      :alt="problem?.user_details?.name"
                      class="h-full w-full object-cover"
                    />
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium">
                      {{ problem?.user_details?.name }}
                    </p>
                    <p class="text-xs text-gray-500">
                      {{ formatTimeAgo(problem?.created_at) }}
                    </p>
                  </div>
                </div>
                <div>
                  <span
                    v-if="problem?.payment_option === 'paid'"
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-all border-0 bg-green-50 text-green-700"
                  >
                    {{
                      problem?.payment_amount > 0 ? `I can pay ` : "Paid Help"
                    }}
                    <span
                      v-if="problem?.payment_amount > 0"
                      class="inline-flex items-center"
                    >
                      <UIcon name="i-mdi-currency-bdt" class="text-green-600" />
                      {{ problem?.payment_amount }}
                    </span>
                    &nbsp;for help!
                  </span>
                  <span
                    v-else
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-all border-0 bg-blue-50 text-blue-700"
                  >
                    I need free help!
                  </span>
                </div>
              </div>

              <!-- Category badge with subtle shadow -->
              <span
                class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium transition-all mb-3 bg-gray-100 text-gray-800 shadow-sm"
              >
                {{ problem?.category_details?.name }}
              </span>

              <h3
                class="text-base font-medium text-gray-900 hover:text-blue-700 transition-colors"
              >
                {{ problem?.title }}
              </h3>

              <div class="mt-4 flex items-center justify-between relative">
                <div class="flex items-center space-x-4">
                  <span class="text-xs text-gray-600 flex items-center">
                    <MessageSquare class="h-3.5 w-3.5 mr-1.5" />
                    {{ problem?.comments?.length }} Advices
                  </span>

                  <span class="text-xs text-gray-500 flex items-center">
                    <Eye class="h-3.5 w-3.5 mr-1.5" />
                    {{ problem?.views }} views
                  </span>
                </div>

                <span
                  v-if="problem?.status === 'solved'"
                  class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-100 text-green-800"
                >
                  <CheckCircle class="h-3 w-3 mr-1" /> Solved
                </span>
              </div>
            </div>
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="mx-auto text-gray-400 mb-4"
              >
                <path
                  d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"
                ></path>
                <path d="M3 3v5h5"></path>
                <path
                  d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0-6.74-2.74L21 16"
                ></path>
                <path d="M16 16h5v5"></path>
              </svg>
              <p class="text-gray-500 mb-2">
                No active problems at the moment.
              </p>
              <button
                @click="openCreateModal"
                class="inline-flex items-center justify-center rounded-md text-sm font-medium text-blue-600 underline-offset-4 hover:text-blue-800 hover:underline transition-colors"
              >
                Post a problem
              </button>
            </div>
          </div>
        </div>

        <!-- Solved Problems Tab -->
        <div v-if="activeTab === 'solved'" class="space-y-4">
          <!-- Skeleton loading state -->
          <div v-if="isLoading" class="space-y-4">
            <div
              v-for="i in 3"
              :key="i"
              class="bg-white border border-gray-100 rounded-lg px-2 py-3 animate-pulse"
            >
              <div class="flex justify-between items-start mb-3">
                <div class="flex items-center">
                  <div class="h-10 w-10 rounded-full bg-gray-200"></div>
                  <div class="ml-3">
                    <div class="h-4 w-32 bg-gray-200 rounded"></div>
                    <div class="h-3 w-24 bg-gray-200 rounded mt-2"></div>
                  </div>
                </div>
                <div class="h-6 w-24 bg-gray-200 rounded-full"></div>
              </div>
              <div class="h-4 w-16 bg-gray-200 rounded-full mb-3"></div>
              <div class="h-5 w-3/4 bg-gray-200 rounded mb-4"></div>
              <div class="flex justify-between items-center">
                <div class="flex space-x-3">
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                </div>
                <div class="h-5 w-16 bg-gray-200 rounded-full"></div>
              </div>
            </div>
          </div>

          <div v-else-if="solvedProblems?.length > 0" class="space-y-4">
            <!-- same card layout as active problems but with solved styling -->
            <div
              v-for="problem in solvedProblems"
              :key="problem.id"
              class="bg-white border border-gray-100 rounded-lg px-2 py-3 hover:shadow-lg transition-all duration-300 cursor-pointer relative overflow-hidden"
              @click="openProblemDetail(problem)"
            >
              <!-- Highlight effect on hover that doesn't obscure text -->
              <div
                class="absolute inset-0 bg-green-50 opacity-0 hover:opacity-10 transition-opacity duration-300 pointer-events-none"
              ></div>

              <div class="flex justify-between items-start mb-3 relative">
                <div class="flex items-center">
                  <div
                    class="h-10 w-10 rounded-full overflow-hidden border-2 border-white shadow-sm"
                  >
                    <img
                      :src="problem?.user_details?.image || '/placeholder.svg'"
                      :alt="problem?.user_details?.name"
                      class="h-full w-full object-cover"
                    />
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium">
                      {{ problem?.user_details?.name }}
                    </p>
                    <p class="text-xs text-gray-500">
                      {{ formatTimeAgo(problem?.created_at) }}
                    </p>
                  </div>
                </div>
                <div>
                  <span
                    v-if="problem.payment_amount > 0"
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-all border-0 bg-green-50 text-green-700"
                  >
                    <DollarSign class="h-3 w-3 mr-1" />
                    {{
                      problem.payment_amount > 0
                        ? `$${problem.payment_amount}`
                        : "Paid Help"
                    }}
                  </span>
                  <span
                    v-else
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-all border-0 bg-blue-50 text-blue-700"
                  >
                    Free Help
                  </span>
                </div>
              </div>

              <span
                class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium transition-all mb-3 bg-gray-100 text-gray-800 shadow-sm"
              >
                {{ problem?.category_details?.name }}
              </span>

              <h3
                class="text-base font-medium text-gray-900 hover:text-green-700 transition-colors line-clamp-2"
              >
                {{ problem?.title }}
              </h3>

              <!-- Problem Photos (if any) -->
              <div
                v-if="problem?.media && problem?.media?.length > 0"
                class="mt-4 grid grid-cols-1 gap-2"
              >
                <div
                  v-for="(photo, index) in problem?.media"
                  :key="index"
                  class="relative rounded-lg overflow-hidden cursor-pointer"
                  @click="openPhotoViewer(index)"
                >
                  <img
                    :src="photo?.image"
                    alt="Problem illustration"
                    class="w-full h-24 object-cover"
                  />
                </div>
              </div>

              <div class="mt-4 flex items-center justify-between relative">
                <div class="flex items-center space-x-4">
                  <span class="text-xs text-gray-600 flex items-center">
                    <MessageSquare class="h-3.5 w-3.5 mr-1.5" />
                    {{ problem.comments?.length }} Advices
                  </span>

                  <span class="text-xs text-gray-500 flex items-center">
                    <Eye class="h-3.5 w-3.5 mr-1.5" />
                    {{ problem?.views }} views
                  </span>
                </div>

                <span
                  class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-600 text-white shadow-sm"
                >
                  <CheckCircle class="h-3 w-3 mr-1" /> Solved
                </span>
              </div>
            </div>
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="mx-auto text-gray-400 mb-4"
              >
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
              </svg>
              <p class="text-gray-500">No solved problems yet.</p>
            </div>
          </div>
        </div>

        <!-- My Problems Tab -->
        <div v-if="activeTab === 'my-problems' && user" class="space-y-4">
          <!-- Similar structure to other tabs with appropriate styling -->
          <div v-if="myProblems?.length > 0" class="space-y-4">
            <div
              v-for="problem in myProblems"
              :key="problem.id"
              class="bg-white border border-gray-100 rounded-lg px-2 py-3 hover:shadow-lg transition-all duration-300 cursor-pointer relative overflow-hidden"
              @click="openProblemDetail(problem)"
            >
              <!-- Highlight effect on hover that doesn't obscure text -->
              <div
                class="absolute inset-0 bg-indigo-50 opacity-0 hover:opacity-10 transition-opacity duration-300 pointer-events-none"
              ></div>

              <div class="flex justify-between items-start mb-3 relative">
                <div class="flex items-center">
                  <div
                    class="h-10 w-10 rounded-full overflow-hidden border-2 border-white shadow-sm"
                  >
                    <img
                      :src="problem?.user_details?.image || '/placeholder.svg'"
                      :alt="problem?.user_details?.name"
                      class="h-full w-full object-cover"
                    />
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium">
                      {{ problem?.user_details?.name }}
                    </p>
                    <p class="text-xs text-gray-500">
                      {{ formatTimeAgo(problem?.created_at) }}
                    </p>
                  </div>
                </div>
                <div>
                  <span
                    v-if="problem?.payment_option === 'paid'"
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-all border-0 bg-green-50 text-green-700"
                  >
                    {{
                      problem?.payment_amount > 0 ? `I can pay ` : "Paid Help"
                    }}
                    <span
                      v-if="problem?.payment_amount > 0"
                      class="inline-flex items-center"
                    >
                      <UIcon name="i-mdi-currency-bdt" class="text-green-600" />
                      {{ problem?.payment_amount }}
                    </span>
                    &nbsp;for help!
                  </span>
                  <span
                    v-else
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-all border-0 bg-blue-50 text-blue-700"
                  >
                    Free Help
                  </span>
                </div>
              </div>

              <span
                class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium transition-all mb-3 bg-gray-100 text-gray-800 shadow-sm"
              >
                {{ problem?.category_details?.name }}
              </span>

              <h3
                class="text-base font-medium text-gray-900 hover:text-indigo-700 transition-colors line-clamp-2"
              >
                {{ problem?.title }}
              </h3>

              <!-- Problem Photos (if any) -->
              <div
                v-if="problem?.media && problem?.media?.length > 0"
                class="mt-4 grid grid-cols-1 gap-2"
              >
                <div
                  v-for="(photo, index) in problem?.media"
                  :key="index"
                  class="relative rounded-lg overflow-hidden cursor-pointer"
                  @click="openPhotoViewer(index)"
                >
                  <img
                    :src="photo.image"
                    alt="Problem illustration"
                    class="w-full h-24 object-cover"
                  />
                </div>
              </div>

              <div class="mt-4 flex items-center justify-between relative">
                <div class="flex items-center space-x-4">
                  <span class="text-xs text-gray-600 flex items-center">
                    <MessageSquare class="h-3.5 w-3.5 mr-1.5" />
                    {{ problem?.comments?.length }} Advices
                  </span>

                  <span class="text-xs text-gray-500 flex items-center">
                    <Eye class="h-3.5 w-3.5 mr-1.5" />
                    {{ problem?.views }} views
                  </span>
                </div>

                <span
                  v-if="problem.status === 'solved'"
                  class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-600 text-white shadow-sm"
                >
                  <CheckCircle class="h-3 w-3 mr-1" /> Solved
                </span>
              </div>
            </div>
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="mx-auto text-gray-400 mb-4"
              >
                <path
                  d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"
                ></path>
                <line x1="12" y1="9" x2="12" y2="13"></line>
                <line x1="12" y1="17" x2="12.01" y2="17"></line>
              </svg>
              <p class="text-gray-500 mb-2">
                You haven't posted any problems yet.
              </p>
              <button
                @click="openCreateModal"
                class="inline-flex items-center justify-center rounded-md text-sm font-medium text-blue-600 underline-offset-4 hover:text-blue-800 hover:underline transition-colors"
              >
                Post your first problem
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Problem Modal with improved design -->
    <Transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div
        v-if="isCreateModalOpen"
        class="fixed inset-0 z-50 flex items-center justify-center"
      >
        <!-- Backdrop with blur -->
        <div
          class="absolute inset-0 bg-black/50 backdrop-blur-sm"
          @click="isCreateModalOpen = false"
        ></div>

        <!-- Modal -->
        <div
          class="relative bg-white rounded-xl shadow-xl w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto"
        >
          <!-- Close button (X) at top right -->
          <button
            @click="isCreateModalOpen = false"
            class="absolute top-4 right-4 p-1 rounded-full hover:bg-gray-100 transition-colors"
            aria-label="Close"
          >
            <X class="h-5 w-5 text-gray-500" />
          </button>

          <div class="flex flex-col p-6">
            <h2 class="text-xl font-semibold mb-1 text-gray-900">
              Post a New Problem
            </h2>
            <p class="text-gray-500 text-sm mb-4">
              Share your problem with the community and get expert help.
            </p>

            <div class="space-y-4">
              <div class="space-y-2">
                <label for="title" class="text-sm font-medium text-gray-700"
                  >Problem Title</label
                >
                <input
                  id="title"
                  v-model="createForm.title"
                  placeholder="Enter a clear, specific title for your problem"
                  class="flex h-10 w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 transition-all"
                />
              </div>

              <div class="space-y-2">
                <label
                  for="description"
                  class="text-sm font-medium text-gray-700"
                  >Description</label
                >
                <textarea
                  id="description"
                  v-model="createForm.description"
                  placeholder="Describe your problem in detail. Include what you've tried so far and what you're trying to achieve."
                  rows="5"
                  class="flex w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all"
                ></textarea>
              </div>

              <!-- Photo Upload Section -->
              <div class="space-y-2">
                <label
                  class="text-sm font-medium text-gray-700 flex justify-between"
                >
                  <span>Photos (Optional)</span>
                  <span class="text-xs text-gray-500"
                    >{{ createForm.images?.length }}/4 photos</span
                  >
                </label>

                <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  <!-- Existing photos -->
                  <div
                    v-for="(photo, index) in createForm?.images"
                    :key="index"
                    class="relative aspect-square rounded-lg border border-gray-200 overflow-hidden"
                  >
                    <img
                      :src="photo"
                      alt="Problem photo"
                      class="w-full h-full object-cover"
                    />
                    <button
                      @click="removePhoto(index)"
                      class="absolute top-1 right-1 bg-black/50 rounded-full p-1 hover:bg-black/75 transition-colors"
                      aria-label="Remove photo"
                    >
                      <X class="h-3 w-3 text-white" />
                    </button>
                  </div>

                  <!-- Add photo button (only show if less than 4 photos) -->
                  <label
                    v-if="createForm.images.length < 4"
                    class="flex flex-col items-center justify-center cursor-pointer aspect-square rounded-lg border-2 border-dashed border-gray-300 hover:border-gray-400 transition-colors bg-gray-50"
                  >
                    <input
                      type="file"
                      accept="image/*"
                      class="hidden"
                      @change="handlePhotoUpload"
                    />
                    <ImagePlus class="h-6 w-6 text-gray-400" />
                    <span class="mt-1 text-xs text-gray-500">Add Photo</span>
                  </label>
                </div>
              </div>

              <div class="space-y-2">
                <label for="category" class="text-sm font-medium text-gray-700"
                  >Category</label
                >
                <select
                  id="category"
                  v-model="createForm.category"
                  class="flex h-10 w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 transition-all"
                >
                  <option value="" disabled>Select a category</option>
                  <option
                    v-for="cat in categories"
                    :key="cat.id"
                    :value="cat.id"
                  >
                    {{ cat.name }}
                  </option>
                </select>
              </div>

              <div class="space-y-2">
                <label class="text-sm font-medium text-gray-700"
                  >Help Type</label
                >
                <div class="grid grid-cols-2 gap-3 mt-1">
                  <div
                    @click="createForm.payment_option = 'free'"
                    :class="[
                      'flex items-center space-x-2 p-3 rounded-lg border cursor-pointer transition-all',
                      createForm.payment_option === 'free'
                        ? 'bg-blue-50 border-blue-200 ring-1 ring-blue-400'
                        : 'border-gray-200 hover:bg-gray-50',
                    ]"
                  >
                    <input
                      type="radio"
                      id="free"
                      value="free"
                      v-model="createForm.payment_option"
                      class="h-4 w-4 border-blue-500 text-blue-600 focus:ring-blue-500"
                    />
                    <label for="free" class="text-sm cursor-pointer"
                      >I need help for free</label
                    >
                  </div>
                  <div
                    @click="createForm.payment_option = 'paid'"
                    :class="[
                      'flex items-center space-x-2 p-3 rounded-lg border cursor-pointer transition-all',
                      createForm.payment_option === 'paid'
                        ? 'bg-green-50 border-green-200 ring-1 ring-green-400'
                        : 'border-gray-200 hover:bg-gray-50',
                    ]"
                  >
                    <input
                      type="radio"
                      id="paid"
                      value="paid"
                      v-model="createForm.payment_option"
                      class="h-4 w-4 border-green-500 text-green-600 focus:ring-green-500"
                    />
                    <label for="paid" class="text-sm cursor-pointer"
                      >I can pay for help</label
                    >
                  </div>
                </div>
              </div>

              <div
                v-if="createForm.payment_option === 'paid'"
                class="space-y-2"
              >
                <label
                  for="paymentAmount"
                  class="text-sm font-medium text-gray-700"
                  >Payment Amount ($)</label
                >
                <div class="relative">
                  <span class="absolute left-3 top-2.5 text-gray-500">$</span>
                  <input
                    id="paymentAmount"
                    v-model="createForm.payment_amount"
                    type="number"
                    placeholder="Enter amount"
                    class="flex h-10 w-full rounded-lg border border-gray-200 bg-white pl-7 pr-3 py-2 text-sm ring-offset-background placeholder:text-gray-400 focus:border-green-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-green-400 disabled:cursor-not-allowed disabled:opacity-50 transition-all"
                  />
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-3 mt-6 mb-8">
              <button
                @click="isCreateModalOpen = false"
                class="inline-flex items-center justify-center rounded-lg text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-gray-200 bg-white text-gray-900 hover:bg-gray-100 h-10 px-4 py-2"
              >
                Cancel
              </button>
              <button
                @click="handleCreateProblem"
                :disabled="!isCreateFormValid || isSubmittingCreate"
                :class="[
                  'inline-flex items-center justify-center rounded-lg text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-5 py-2',
                  isCreateFormValid && !isSubmittingCreate
                    ? 'bg-blue-600 text-white hover:bg-blue-700 shadow-md hover:shadow-lg'
                    : 'bg-gray-200 text-gray-500',
                ]"
              >
                <span v-if="isSubmittingCreate" class="flex items-center">
                  <svg
                    class="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    ></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  Posting...
                </span>
                <span v-else>Post Problem</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Problem Detail Modal with improved design -->
    <Transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="opacity-0 translate-y-4"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 translate-y-4"
    >
      <div
        v-if="isDetailModalOpen && selectedProblem"
        class="fixed inset-0 z-50 flex items-center justify-center"
      >
        <!-- Backdrop with blur -->
        <div
          class="absolute inset-0 bg-black/50 backdrop-blur-sm"
          @click="isDetailModalOpen = false"
        ></div>

        <!-- Modal -->
        <div
          class="relative bg-white rounded-xl shadow-xl w-full max-w-3xl mx-4 max-h-[90vh] overflow-y-auto"
        >
          <!-- Close button (X) -->

          <div class="p-6">
            <!-- Problem Header -->
            <div class="flex justify-between items-start">
              <div class="flex items-center">
                <div
                  class="h-12 w-12 rounded-full overflow-hidden border-2 border-white shadow-sm"
                >
                  <img
                    :src="
                      selectedProblem.user_details?.image || '/placeholder.svg'
                    "
                    :alt="selectedProblem.user_details?.name"
                    class="h-full w-full object-cover"
                  />
                </div>
                <div class="ml-3">
                  <p class="text-sm font-medium">
                    {{ selectedProblem.user_details?.name }}
                  </p>
                  <div class="flex items-center text-xs text-gray-500">
                    <Clock class="h-3 w-3 mr-1" />
                    <span>{{ formatTimeAgo(selectedProblem.created_at) }}</span>
                  </div>
                </div>
              </div>

              <div v-if="isOwner" class="relative">
                <div class="flex items-center gap-1">
                  <button
                    @click="isMenuOpen = !isMenuOpen"
                    class="inline-flex items-center justify-center rounded-lg text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-gray-100 h-8 w-8 p-0"
                  >
                    <MoreHorizontal class="h-4 w-4" />
                  </button>
                  <button
                    @click="isDetailModalOpen = false"
                    class="p-1 rounded-full hover:bg-gray-100 transition-colors"
                    aria-label="Close"
                  >
                    <X class="h-5 w-5 text-gray-500" />
                  </button>
                </div>

                <Transition
                  enter-active-class="transition duration-200 ease-out"
                  enter-from-class="opacity-0 scale-95"
                  enter-to-class="opacity-100 scale-100"
                  leave-active-class="transition duration-100 ease-in"
                  leave-from-class="opacity-100 scale-100"
                  leave-to-class="opacity-0 scale-95"
                >
                  <div
                    v-if="isMenuOpen"
                    class="absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                  >
                    <div class="py-1">
                      <button
                        class="flex w-full items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        <Edit class="h-4 w-4 mr-2" /> Edit Problem
                      </button>
                      <button
                        @click="confirmDelete"
                        class="flex w-full items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                      >
                        <Trash2 class="h-4 w-4 mr-2" /> Delete Problem
                      </button>
                    </div>
                  </div>
                </Transition>
              </div>
            </div>

            <!-- Problem Category & Payment -->
            <div class="flex flex-wrap gap-2 mt-4">
              <span
                class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium bg-gray-100 text-gray-800 shadow-sm"
              >
                {{ selectedProblem.category_details?.name }}
              </span>

              <span
                v-if="selectedProblem?.payment_option === 'paid'"
                class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-all border-0 bg-green-50 text-green-700"
              >
                {{
                  selectedProblem?.payment_amount > 0
                    ? `I can pay `
                    : "Paid Help"
                }}
                <span
                  v-if="selectedProblem?.payment_amount > 0"
                  class="inline-flex items-center"
                >
                  <UIcon name="i-mdi-currency-bdt" class="text-green-600" />
                  {{ selectedProblem?.payment_amount }}
                </span>
                &nbsp;for help!
              </span>
              <span
                v-else
                class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium bg-blue-50 text-blue-700"
              >
                I need help for free
              </span>

              <span
                v-if="selectedProblem.status === 'solved'"
                class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium bg-green-600 text-white shadow-sm"
              >
                <CheckCircle class="h-3 w-3 mr-1" />
                Solved
              </span>
            </div>

            <!-- Problem Title & Content -->
            <h1 class="text-2xl font-semibold mt-4 text-gray-900">
              {{ selectedProblem.title }}
            </h1>
            <p class="mt-3 text-gray-700 whitespace-pre-line leading-relaxed">
              {{ selectedProblem.description }}
            </p>

            <!-- Problem Photos (if any) -->
            <div
              v-if="selectedProblem.media && selectedProblem.media.length > 0"
              class="mt-4"
            >
              <div class="grid grid-cols-2 gap-2">
                <div
                  v-for="(photo, index) in selectedProblem.media"
                  :key="index"
                  class="relative rounded-lg overflow-hidden cursor-pointer"
                  @click="openPhotoViewer(index)"
                >
                  <img
                    :src="photo.image"
                    alt="Problem illustration"
                    class="w-full h-48 object-cover"
                  />
                </div>
              </div>
            </div>

            <!-- Problem Stats -->
            <div
              class="mt-6 flex items-center justify-between border-t border-b border-gray-200 py-3"
            >
              <div class="flex items-center space-x-4">
                <span class="text-sm text-gray-600 flex items-center">
                  <MessageSquare class="h-4 w-4 mr-1.5" />
                  {{ selectedProblem.comments?.length }} Advices
                </span>

                <span class="text-sm text-gray-600 flex items-center">
                  <Eye class="h-4 w-4 mr-1.5" />
                  {{ selectedProblem?.views }}
                </span>
              </div>
            </div>

            <!-- Comments Section -->
            <div class="mt-6">
              <h3 class="text-lg font-medium mb-4 text-gray-900">
                Comments ({{ selectedProblem.comments?.length }})
              </h3>

              <!-- Comment List -->
              <div class="space-y-4">
                <div
                  v-if="selectedProblem.comments?.length > 0"
                  v-for="comment in selectedProblem?.comments"
                  :key="comment.id"
                  :class="[
                    'px-2 py-3 rounded-lg transition-all',
                    comment.isSolution
                      ? 'bg-green-50 border border-green-100 shadow-sm'
                      : 'bg-gray-50 hover:bg-gray-100',
                  ]"
                >
                  <div class="flex justify-between">
                    <div class="flex items-center">
                      <div
                        class="h-10 w-10 rounded-full overflow-hidden border-2 border-white shadow-sm"
                      >
                        <img
                          :src="comment.author.avatar || '/placeholder.svg'"
                          :alt="comment.author.name"
                          class="h-full w-full object-cover"
                        />
                      </div>
                      <div class="ml-3">
                        <div class="flex items-center">
                          <p class="text-sm font-medium">
                            {{ comment.author.name }}
                          </p>
                          <span
                            v-if="comment.isSolution"
                            class="ml-2 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-600 text-white shadow-sm"
                          >
                            <CheckCircle class="h-3 w-3 mr-1" /> Solution
                          </span>
                        </div>
                        <p class="text-xs text-gray-500">
                          {{ comment.createdAt }}
                        </p>
                      </div>
                    </div>

                    <button
                      v-if="isOwner"
                      @click="markAsSolution(comment.id)"
                      :class="[
                        'inline-flex items-center justify-center rounded-md text-xs font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-8 px-3',
                        comment.isSolution
                          ? 'bg-green-600 text-white shadow-sm'
                          : 'border border-gray-200 bg-white hover:bg-gray-50 text-gray-700',
                      ]"
                    >
                      <CheckCircle class="h-3 w-3 mr-1" />
                      {{ comment.isSolution ? "Solution" : "Mark as Solution" }}
                    </button>
                  </div>

                  <p class="mt-3 text-sm text-gray-700 leading-relaxed">
                    {{ comment.content }}
                  </p>
                </div>

                <div
                  v-else
                  class="flex flex-col items-center justify-center py-12 bg-gray-50 rounded-lg"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="40"
                    height="40"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="1"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="text-gray-400 mb-3"
                  >
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="8" y1="12" x2="16" y2="12"></line>
                  </svg>
                  <p class="text-gray-500">
                    No advice have been posted yet. Be the first to help!
                  </p>
                </div>
              </div>

              <!-- Add Comment with improved design -->
              <div class="mt-8">
                <h4 class="text-sm font-medium mb-2">Add a advice</h4>
                <textarea
                  v-model="newComment"
                  placeholder="Share your solution or ask for clarification..."
                  class="flex w-full rounded-lg border border-gray-200 bg-white px-4 py-3 text-sm ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all"
                  rows="3"
                ></textarea>
                <div class="flex justify-end mt-3">
                  <button
                    @click="addComment"
                    :disabled="!newComment.trim() || isSubmittingComment"
                    :class="[
                      'inline-flex items-center justify-center rounded-lg text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-5 py-2',
                      newComment.trim() && !isSubmittingComment
                        ? 'bg-blue-600 text-white hover:bg-blue-700 shadow-md hover:shadow-lg'
                        : 'bg-gray-200 text-gray-500',
                    ]"
                  >
                    <span v-if="isSubmittingComment" class="flex items-center">
                      <svg
                        class="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          class="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="4"
                        ></circle>
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        ></path>
                      </svg>
                      Submitting...
                    </span>
                    <span v-else class="flex items-center">
                      <Send class="h-4 w-4 mr-1.5" />
                      Submit
                    </span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Delete Confirmation Dialog with improved design -->
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div
        v-if="isDeleteDialogOpen"
        class="fixed inset-0 z-[60] flex items-center justify-center"
      >
        <div
          class="absolute inset-0 bg-black/50 backdrop-blur-sm"
          @click="isDeleteDialogOpen = false"
        ></div>
        <div
          class="relative bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6"
        >
          <div class="flex items-center mb-4 text-red-500">
            <AlertTriangle class="h-6 w-6 mr-2" />
            <h3 class="text-lg font-semibold">Are you sure?</h3>
          </div>
          <p class="mt-2 text-gray-600">
            This action cannot be undone. This will permanently delete your
            problem and all associated advices.
          </p>
          <div class="flex justify-end gap-3 mt-8">
            <button
              @click="isDeleteDialogOpen = false"
              class="inline-flex items-center justify-center rounded-lg text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-gray-200 bg-white text-gray-900 hover:bg-gray-100 h-10 px-4 py-2"
            >
              Cancel
            </button>
            <button
              @click="deleteProblem"
              class="inline-flex items-center justify-center rounded-lg text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-red-600 text-white hover:bg-red-700 h-10 px-4 py-2 shadow-md hover:shadow-lg"
            >
              <AlertTriangle class="h-4 w-4 mr-2" />
              Delete
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Photo Viewer Modal -->
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isPhotoViewerOpen"
        class="fixed inset-0 z-[70] flex items-center justify-center bg-black/90"
      >
        <button
          @click="isPhotoViewerOpen = false"
          class="absolute top-4 right-4 p-1.5 rounded-full text-white hover:bg-white/10 transition-colors"
          aria-label="Close"
        >
          <X class="h-6 w-6" />
        </button>

        <div class="relative w-full max-w-4xl px-4">
          <img
            :src="selectedProblem?.photos[currentPhotoIndex]?.url"
            alt="Problem photo"
            class="mx-auto max-h-[80vh] max-w-full object-contain"
          />

          <div
            class="absolute top-1/2 left-0 right-0 flex justify-between transform -translate-y-1/2 px-2"
          >
            <button
              v-if="selectedProblem?.photos.length > 1"
              @click="prevPhoto"
              class="p-2 rounded-full bg-black/30 text-white hover:bg-black/50 transition-colors"
              aria-label="Previous photo"
            >
              <ChevronLeft class="h-6 w-6" />
            </button>
            <div class="flex-1"></div>
            <button
              v-if="selectedProblem?.photos.length > 1"
              @click="nextPhoto"
              class="p-2 rounded-full bg-black/30 text-white hover:bg-black/50 transition-colors"
              aria-label="Next photo"
            >
              <ChevronRight class="h-6 w-6" />
            </button>
          </div>

          <div
            class="absolute bottom-4 left-0 right-0 flex justify-center gap-2"
          >
            <button
              v-for="(_, i) in selectedProblem?.photos"
              :key="i"
              @click="currentPhotoIndex = i"
              :class="[
                'w-2 h-2 rounded-full transition-all',
                currentPhotoIndex === i
                  ? 'bg-white scale-125'
                  : 'bg-white/50 hover:bg-white/70',
              ]"
              :aria-label="`View photo ${i + 1}`"
            ></button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import {
  Search,
  Plus,
  MessageSquare,
  Eye,
  CheckCircle,
  DollarSign,
  Clock,
  Send,
  MoreHorizontal,
  Edit,
  Trash2,
  AlertTriangle,
  X,
  ImagePlus,
  ChevronLeft,
  ChevronRight,
} from "lucide-vue-next";

definePageMeta({
  layout: "adsy-business-network",
  title: "MindForce - Business Network",
  meta: [
    {
      name: "description",
      content: "Connect with like-minded individuals and share your knowledge.",
    },
    {
      name: "keywords",
      content: "business, network, connect, share, knowledge",
    },
  ],
});

const { get, post, patch } = useApi();
const { user } = useAuth();
// State
const isCreating = ref(false);
const isSearching = ref(false);
const searchQuery = ref("");
const activeTab = ref("active");
const isCreateModalOpen = ref(false);
const isDetailModalOpen = ref(false);
const selectedProblem = ref(null);
const isMenuOpen = ref(false);
const isDeleteDialogOpen = ref(false);
const newComment = ref("");
const isSubmittingComment = ref(false);
const isSubmittingCreate = ref(false);
const isLoading = ref(true);

// Create form state with photos array
const createForm = ref({
  title: "",
  description: "",
  category: "",
  payment_option: "free",
  payment_amount: "",
  images: [],
});

// Additional state for photos
const isPhotoViewerOpen = ref(false);
const currentPhotoIndex = ref(0);

// Computed
const isCreateFormValid = computed(() => {
  return (
    createForm.value.title.trim() &&
    createForm.value.description.trim() &&
    createForm.value.category
  );
});

// Tabs
const tabs = [
  { label: "Active Problems", value: "active" },
  { label: "Solved Problems", value: "solved" },
  { label: "My Problems", value: "my-problems" },
];

// Categories
const categories = ref([]);

async function fetchCategories() {
  try {
    const { data } = await get("/bn/mindforce/categories/");
    categories.value = data;
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}
await fetchCategories();
// Sample data
const problems = ref([]);

async function fetchProblems() {
  try {
    const { data } = await get("/bn/mindforce/");
    problems.value = data;
    console.log(problems.value);
  } catch (error) {
    console.error("Error fetching problems:", error);
  }
}
await fetchProblems();

// Computed properties
const activeProblems = computed(() =>
  problems.value.filter((problem) => problem.status === "active")
);

const solvedProblems = computed(() =>
  problems.value.filter((problem) => problem.status === "solved")
);

const myProblems = computed(() =>
  problems.value.filter(
    (problem) => problem.user_details.id === user.value?.user?.id
  )
);

const isOwner = computed(
  () =>
    selectedProblem.value &&
    selectedProblem.value.user_details.id === user.value?.user?.id
);

// Methods
const openCreateModal = () => {
  isCreating.value = true;
  setTimeout(() => {
    isCreating.value = false;
    isCreateModalOpen.value = true;
  }, 500);
};

const openProblemDetail = (problem) => {
  if (!problem) return;

  try {
    setTimeout(async () => {
      const res = await patch(`/bn/mindforce/${selectedProblem.value.id}/`, {
        views: selectedProblem.value.views + 1,
      });
      console.log("viewupdated", res);
    }, 7000);
  } catch (error) {
    console.log(error);
  }

  selectedProblem.value = problem;
  isDetailModalOpen.value = true;
};

const handleSearch = () => {
  isSearching.value = true;
  setTimeout(() => {
    isSearching.value = false;
  }, 500);
};

const formatTimeAgo = (dateString) => {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds} ${diffInSeconds === 1 ? "second" : "seconds"} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${diffInMonths} ${diffInMonths === 1 ? "month" : "months"} ago`;
};

// Handle photo upload
const handlePhotoUpload = (event) => {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    createForm.value.images.push(reader.result);
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
};

// Remove photo
const removePhoto = (index) => {
  createForm.value.images.splice(index, 1);
};

// Photo viewer functions
const openPhotoViewer = (photoIndex) => {
  currentPhotoIndex.value = photoIndex;
  isPhotoViewerOpen.value = true;
};

const nextPhoto = () => {
  if (!selectedProblem.value?.photos?.length) return;
  currentPhotoIndex.value =
    (currentPhotoIndex.value + 1) % selectedProblem.value.photos.length;
};

const prevPhoto = () => {
  if (!selectedProblem.value?.photos?.length) return;
  currentPhotoIndex.value =
    (currentPhotoIndex.value - 1 + selectedProblem.value.photos.length) %
    selectedProblem.value.photos.length;
};

// Modified create problem function
const handleCreateProblem = async () => {
  if (!isCreateFormValid.value) return;

  isSubmittingCreate.value = true;

  try {
    const res = await post("/bn/mindforce/", createForm.value);
    if (res.data) {
      isCreateModalOpen.value = false;
      await fetchProblems();
      // Reset form
      createForm.value = {
        title: "",
        description: "",
        category: "",
        payment_option: "free",
        payment_amount: "",
        images: [],
      };
    }
  } finally {
    isSubmittingCreate.value = false;
  }
};

const confirmDelete = () => {
  isMenuOpen.value = false;
  isDeleteDialogOpen.value = true;
};

const deleteProblem = () => {
  problems.value = problems.value.filter(
    (problem) => problem.id !== selectedProblem.value.id
  );
  isDeleteDialogOpen.value = false;
  isDetailModalOpen.value = false;
};

const markAsSolution = (commentId) => {
  problems.value = problems.value.map((problem) => {
    if (problem.id === selectedProblem.value.id) {
      // Toggle the solution status for this comment
      const updatedComments = problem.comments.map((comment) => ({
        ...comment,
        isSolution:
          comment.id === commentId ? !comment.isSolution : comment.isSolution,
      }));

      // Check if any comments are marked as solutions
      const hasSolution = updatedComments.some((comment) => comment.isSolution);

      // Update the selected problem reference
      if (selectedProblem.value.id === problem.id) {
        selectedProblem.value = {
          ...problem,
          status: hasSolution ? "Solved" : "Problem",
          comments: updatedComments,
        };
      }

      return {
        ...problem,
        status: hasSolution ? "Solved" : "Problem",
        comments: updatedComments,
      };
    }
    return problem;
  });
};

const addComment = async () => {
  if (!newComment.value.trim()) return;

  isSubmittingComment.value = true;

  try {
    // Simulate network delay
    await new Promise((resolve) => setTimeout(resolve, 500));

    problems.value = problems.value.map((problem) => {
      if (problem.id === selectedProblem.value.id) {
        const newCommentObj = {
          id: Math.max(0, ...problem.comments.map((c) => c.id)) + 1,
          author: {
            name: "You",
            avatar: "/mystical-forest-spirit.png",
          },
          content: newComment.value,
          createdAt: "Just now",
          isSolution: false,
        };

        const updatedProblem = {
          ...problem,
          comments: [...problem.comments, newCommentObj],
        };

        // Update the selected problem reference
        if (selectedProblem.value.id === problem.id) {
          selectedProblem.value = updatedProblem;
        }

        return updatedProblem;
      }
      return problem;
    });

    newComment.value = "";
  } finally {
    isSubmittingComment.value = false;
  }
};

// Close dropdown when clicking outside
const handleClickOutside = (event) => {
  if (isMenuOpen.value) {
    isMenuOpen.value = false;
  }
};

// Add event listener when component is mounted
onMounted(() => {
  // Show loading state first
  isLoading.value = true;

  // Simulate network request
  setTimeout(() => {
    isLoading.value = false;
  }, 1000);

  document.addEventListener("click", handleClickOutside);
});

// Remove event listener when component is unmounted
onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
});
</script>

<style scoped>
/* Add smooth transition for all elements */
* {
  transition-property: background-color, border-color, color, fill, stroke,
    opacity, box-shadow, transform;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}
</style>
