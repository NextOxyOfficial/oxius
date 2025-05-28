<template>
  <div v-if="subject" class="bg-white rounded-lg shadow-md p-4 mt-3">
    <!-- Header with title and icon -->
    <div class="flex items-center mb-4">
      <div
        class="bg-gradient-to-br from-red-500 to-rose-600 text-white rounded-full p-1.5 mr-2.5 shadow-sm"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
          />
        </svg>
      </div>
      <div>
        <h2 class="text-lg font-bold">{{ $t("video_lessons") }}</h2>
        <p class="text-xs text-gray-500 hidden sm:block">
          {{ $t("video_lessons_desc") }}
        </p>
      </div>      <!-- Session Status and Controls -->
      <div class="ml-auto flex items-center gap-3">
        <!-- Time Remaining for Non-Pro Users -->
        <div
          v-if="hasTimeLimit && isSessionActive"
          class="text-xs bg-amber-50 text-amber-700 px-2.5 py-1 rounded-full border border-amber-200 shadow-sm flex items-center"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-3.5 w-3.5 mr-1 text-amber-600"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z"
              clip-rule="evenodd"
            />
          </svg>
          <span>{{ Math.floor(timeRemaining / 60) }}:{{ String(timeRemaining % 60).padStart(2, '0') }} left</span>
        </div>

        <!-- Session Status Indicator -->        <div
          v-if="isSessionActive"
          class="text-xs bg-green-50 text-green-700 px-2.5 py-1 rounded-full border border-green-200 shadow-sm flex items-center"
        >
          <div class="w-2 h-2 bg-green-500 rounded-full mr-1.5 animate-pulse"></div>
          <span>Active Session</span>
        </div>

        <!-- Total videos count badge -->
        <span
          class="text-xs bg-gray-50 text-gray-700 px-2.5 py-1 rounded-full border border-gray-100 shadow-sm flex items-center"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-3.5 w-3.5 mr-1 text-gray-500"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
              clip-rule="evenodd"
            />
          </svg>
          <span v-if="loading">Loading...</span>
          <span v-else>{{ subjectVideos.length }} {{ $t("videos") }}</span>
        </span>
      </div>
    </div>

    <!-- Modern search and filter card -->
    <div
      class="bg-gradient-to-r from-gray-50 to-slate-50 rounded-lg border border-gray-100 p-4 mb-5 shadow-sm"
    >
      <!-- Top section title -->
      <div class="flex items-center mb-3 pb-2 border-b border-gray-200">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5 text-blue-600 mr-2"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path
            fill-rule="evenodd"
            d="M3 3a1 1 0 011-1h12a1 1 0 011 1v3a1 1 0 01-.293.707L12 11.414V15a1 1 0 01-.293.707l-2 2A1 1 0 018 17v-5.586L3.293 6.707A1 1 0 013 6V3z"
            clip-rule="evenodd"
          />
        </svg>
        <h3 class="text-sm font-semibold text-gray-700">
          {{ $t("filter_and_search") }}
        </h3>
      </div>

      <!-- Search and filter controls - redesigned layout -->
      <div class="space-y-4 md:space-y-0 md:grid md:grid-cols-12 md:gap-4">
        <!-- Lesson filter - styled select with icon -->
        <div class="md:col-span-5">
          <label
            class="block text-xs font-medium text-gray-700 mb-1.5 flex items-center"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-3.5 w-3.5 text-gray-500 mr-1"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z" />
              <path
                fill-rule="evenodd"
                d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z"
                clip-rule="evenodd"
              />
            </svg>
            {{ $t("elearning_filter_by") }} {{ $t("elearning_lesson") }}:
          </label>
          <div class="relative">
            <select
              v-model="selectedLesson"
              class="appearance-none block w-full bg-white border border-gray-200 rounded-md py-2 pl-3.5 pr-8 text-sm text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">
                {{ $t("all_lessons") }}
              </option>
              <option v-for="lesson in lessons" :key="lesson" :value="lesson">
                {{ lesson }}
              </option>
            </select>
            <div
              class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700"
            >
              <svg
                class="h-4 w-4 text-gray-400"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
          </div>
        </div>

        <!-- Search input - modern design with context indicator -->
        <div class="md:col-span-7">
          <label
            class="block text-xs font-medium text-gray-700 mb-1.5 flex items-center"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-3.5 w-3.5 text-gray-500 mr-1"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z"
                clip-rule="evenodd"
              />
            </svg>
            {{ $t("search") }}:
            <span
              v-if="selectedLesson !== 'all'"
              class="ml-1.5 bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 rounded-md font-medium"
            >
              {{ selectedLesson }}
            </span>
          </label>
          <div class="relative">
            <input
              v-model="searchKeyword"
              type="text"
              :placeholder="searchPlaceholder"
              class="block w-full bg-white border border-gray-200 rounded-md py-2 pl-10 pr-9 text-sm text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <!-- Search icon positioned inside input -->
            <div
              class="absolute left-0 inset-y-0 flex items-center pl-3 pointer-events-none"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
            </div>

            <!-- Clear search button with animation -->
            <button
              v-if="searchKeyword.trim()"
              @click="searchKeyword = ''"
              class="absolute right-2 inset-y-0 flex items-center text-gray-400 hover:text-gray-600 transition-colors duration-200"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Filter actions and status -->
      <div class="mt-3 flex items-center justify-between">
        <!-- Filter status badges -->
        <div
          v-if="searchKeyword.trim() || selectedLesson !== 'all'"
          class="flex flex-wrap gap-1.5"
        >
          <div
            v-if="selectedLesson !== 'all'"
            class="inline-flex items-center px-2 py-1 rounded-md text-xs bg-green-50 text-green-700 border border-green-100"
          >
            <span>{{ $t("lesson") }}:</span>
            <span class="font-medium ml-1">{{ selectedLesson }}</span>
            <button
              @click="selectedLesson = 'all'"
              class="ml-1.5 text-green-500 hover:text-green-700"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-3.5 w-3.5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>

          <div
            v-if="searchKeyword.trim()"
            class="inline-flex items-center px-2 py-1 rounded-md text-xs bg-blue-50 text-blue-700 border border-blue-100"
          >
            <span>{{ isBengaliLocale ? "কীওয়ার্ড:" : "Keyword:" }}</span>
            <span class="font-medium ml-1">"{{ searchKeyword }}"</span>
            <button
              @click="searchKeyword = ''"
              class="ml-1.5 text-blue-500 hover:text-blue-700"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-3.5 w-3.5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>
        </div>

        <!-- Results count and clear all button -->
        <div class="flex items-center gap-2">
          <div v-if="filteredVideos.length > 0" class="text-xs text-gray-500">
            <span class="font-medium text-gray-700">{{
              filteredVideos.length
            }}</span>
            {{ filteredVideos.length === 1 ? "result" : "results" }}
          </div>

          <button
            v-if="searchKeyword.trim() || selectedLesson !== 'all'"
            @click="clearFilters"
            class="text-xs bg-gray-100 hover:bg-gray-200 text-gray-600 px-2.5 py-1.5 rounded-md flex items-center transition-colors duration-200 border border-gray-200"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-3.5 w-3.5 mr-1"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
            {{ $t("clear_filters") }}
          </button>
        </div>
      </div>
    </div>

    <!-- No results message - Styled -->
    <div
      v-if="filteredVideos.length === 0"
      class="text-center py-8 px-4 bg-gray-50 rounded-lg border border-gray-100"
    >
      <div
        class="bg-white w-16 h-16 mx-auto mb-3 rounded-full shadow-sm flex items-center justify-center"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-8 w-8 text-gray-300"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="1.5"
            d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
          />
        </svg>
      </div>
      <h3 class="text-sm font-semibold text-gray-700">
        {{ $t("no_videos_found") }}
      </h3>
      <p class="mt-2 text-xs text-gray-500 max-w-sm mx-auto">
        {{
          searchKeyword.trim() ? $t("no_search_results") : $t("no_videos_found")
        }}
      </p>
      <button
        v-if="searchKeyword.trim() || selectedLesson !== 'all'"
        @click="clearFilters"
        class="mt-4 inline-flex items-center px-3 py-1.5 border border-blue-300 text-xs font-medium rounded-md text-blue-700 bg-blue-50 hover:bg-blue-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="-ml-0.5 mr-1.5 h-4 w-4"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path
            fill-rule="evenodd"
            d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z"
            clip-rule="evenodd"
          />
        </svg>
        {{ $t("clear_filters") }}
      </button>
    </div>

    <!-- Video grid - Keep the existing grid but with minor styling improvements -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
      <div
        v-for="video in filteredVideos"
        :key="video.id"
        class="overflow-hidden rounded-lg border transition-all hover:shadow-sm"
      >        <!-- Video player -->
        <div class="aspect-w-16 aspect-h-9 bg-gray-100">          <youtube-player 
            :video-id="getYoutubeId(video.url)" 
            :video="video" 
            :session-manager="{ 
              isSessionActive, 
              hasTimeLimit, 
              timeRemaining, 
              startVideoTracking, 
              pauseVideoTracking, 
              resumeVideoTracking, 
              stopVideoTracking,
              showAccessModal,
              requiresLogin,
              requiresSubscription,
              closeAccessModal,
              checkVideoAccess
            }"
            @video-start="handleVideoStart"
            @video-pause="handleVideoPause"
            @video-resume="handleVideoResume"
            @video-stop="handleVideoStop"
            @login-required="handleLoginRequired"
            @subscription-required="handleSubscriptionRequired"
          />
        </div>

        <!-- Video metadata -->
        <div class="p-3">
          <h3
            class="font-medium text-gray-900 text-sm"
            v-html="
              highlightText(
                isBengaliLocale && video.title_bn ? video.title_bn : video.title
              )
            "
          ></h3>
          <p class="text-xs text-gray-600 mt-1">
            {{ $t("lesson") }}:
            <span
              v-html="
                highlightText(
                  isBengaliLocale && video.lesson_bn
                    ? video.lesson_bn
                    : video.lesson
                )
              "
            ></span>
          </p>
          <!-- Description with enhanced View More button -->
          <div class="relative mt-1">
            <p
              class="text-xs text-gray-600 line-clamp-2"
              v-html="
                highlightText(
                  isBengaliLocale && video.description_bn
                    ? video.description_bn
                    : video.description
                )
              "
            ></p>
            <button
              @click="openDescriptionModal(video)"
              class="text-xs text-blue-600 hover:text-blue-800 font-medium mt-1.5 flex items-center transition-all duration-200 hover:translate-x-0.5"
            >
              <span
                class="border-b border-blue-300 hover:border-blue-600 pb-0.5"
                >{{ $t("view_more") }}</span
              >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-3 w-3 ml-0.5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>

          <!-- Match indicators when searching -->
          <div v-if="searchKeyword.trim()" class="flex flex-wrap gap-1 mt-1.5">
            <span
              v-if="hasMatch(video.title)"
              class="text-xs px-1.5 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200"
            >
              {{ isBengaliLocale ? "শিরোনাম মিল" : "Title match" }}
            </span>
            <span
              v-if="hasMatch(video.description)"
              class="text-xs px-1.5 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200"
            >
              {{ isBengaliLocale ? "বিবরণে মিল" : "Description match" }}
            </span>
            <span
              v-if="hasMatch(video.lesson)"
              class="text-xs px-1.5 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200"
            >
              {{ isBengaliLocale ? "পাঠ মিল" : "Lesson match" }}
            </span>
          </div>

          <!-- Video stats -->
          <div class="flex items-center mt-2">
            <span
              class="text-xs bg-blue-100 text-blue-800 px-2 py-0.5 rounded-full"
            >
              {{ video.duration }}
            </span>
            <span class="ml-2 text-xs text-gray-500">
              {{ video.views }} {{ $t("videos_count") }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Description Modal with enhanced styling -->
    <Teleport to="body">
      <div
        v-if="showDescriptionModal"
        class="fixed inset-0 z-50 overflow-y-auto"
        aria-labelledby="modal-title"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:pt-20"
        >
          <!-- Background overlay with improved animation -->
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity modal-backdrop"
            aria-hidden="true"
            @click="closeDescriptionModal"
          ></div>

          <!-- Modal panel with enhanced styling and animation -->
          <div
            class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full modal-content"
          >
            <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <!-- Modal header with video title -->
              <div class="flex items-start justify-between mb-3">
                <h3
                  class="text-lg leading-6 font-medium text-gray-900 pr-6"
                  id="modal-title"
                >
                  {{
                    isBengaliLocale && activeVideo?.title_bn
                      ? activeVideo?.title_bn
                      : activeVideo?.title
                  }}
                </h3>
                <!-- Close button (X) in top-right corner -->
                <button
                  @click="closeDescriptionModal"
                  class="text-gray-400 hover:text-gray-500 focus:outline-none"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </button>
              </div>

              <!-- Subject and lesson info -->
              <div
                class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4"
              >
                <div>
                  <span
                    class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded"
                  >
                    {{
                      isBengaliLocale && activeVideo?.lesson_bn
                        ? activeVideo?.lesson_bn
                        : activeVideo?.lesson
                    }}
                  </span>
                </div>
                <div
                  class="mt-1 sm:mt-0 text-xs text-gray-500 flex items-center"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-3.5 w-3.5 mr-1 text-gray-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span class="mr-2">{{ activeVideo?.duration }}</span>

                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-3.5 w-3.5 mr-1 ml-1 text-gray-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                    />
                  </svg>
                  <span>{{ activeVideo?.views }} {{ $t("videos_count") }}</span>
                </div>
              </div>

              <!-- Full description with scrollable area if content is too long -->
              <div class="border-t border-gray-100 pt-3">
                <h4
                  class="text-sm font-medium text-gray-700 mb-1.5 flex items-center"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-1 text-gray-500"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  {{ $t("description") }}:
                </h4>
                <div class="max-h-60 overflow-y-auto pr-1">
                  <p
                    class="text-sm text-gray-600"
                    v-html="
                      highlightText(
                        isBengaliLocale && activeVideo?.description_bn
                          ? activeVideo?.description_bn
                          : activeVideo?.description
                      )
                    "
                  ></p>
                </div>
              </div>
            </div>

            <div
              class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse"
            >
              <!-- Close button -->
              <button
                @click="closeDescriptionModal"
                type="button"
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm transition-colors duration-200"
              >
                {{ isBengaliLocale ? "বন্ধ করুন" : "Close" }}
              </button>
            </div>
          </div>
        </div>      </div>
    </Teleport>

    <!-- Upgrade Prompt Modal -->
    <Teleport to="body">
      <div
        v-if="showUpgradePrompt"
        class="fixed inset-0 z-50 overflow-y-auto"
        aria-labelledby="upgrade-modal-title"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:pt-20"
        >
          <!-- Background overlay -->
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity modal-backdrop"
            aria-hidden="true"
            @click="closeUpgradePrompt"
          ></div>

          <!-- Modal panel -->
          <div
            class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-md sm:w-full modal-content"
          >
            <!-- Header with gradient -->
            <div class="bg-gradient-to-r from-blue-600 to-purple-600 px-6 py-4">
              <div class="flex items-center justify-between">
                <h3
                  class="text-lg leading-6 font-semibold text-white flex items-center"
                  id="upgrade-modal-title"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6 mr-2"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 10V3L4 14h7v7l9-11h-7z"
                    />
                  </svg>
                  Upgrade to Pro
                </h3>
                <button
                  @click="closeUpgradePrompt"
                  class="text-white/80 hover:text-white focus:outline-none transition-colors"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Body -->
            <div class="bg-white px-6 py-4">
              <div class="text-center">
                <!-- Icon -->
                <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-gradient-to-br from-amber-100 to-orange-100 mb-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-8 w-8 text-amber-600"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>

                <!-- Message -->
                <h4 class="text-lg font-semibold text-gray-900 mb-2">
                  Time limit reached!
                </h4>
                <p class="text-sm text-gray-600 mb-6">
                  You've reached your daily viewing limit of 1 minute. Upgrade to Pro for unlimited access to all video content.
                </p>

                <!-- Features list -->
                <div class="text-left bg-gray-50 rounded-lg p-4 mb-6">
                  <h5 class="text-sm font-medium text-gray-900 mb-3">Pro Benefits:</h5>
                  <ul class="space-y-2 text-sm text-gray-600">
                    <li class="flex items-center">
                      <svg class="h-4 w-4 text-green-500 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      Unlimited video viewing time
                    </li>
                    <li class="flex items-center">
                      <svg class="h-4 w-4 text-green-500 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      Access to premium content
                    </li>
                    <li class="flex items-center">
                      <svg class="h-4 w-4 text-green-500 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      Multiple device access
                    </li>
                    <li class="flex items-center">
                      <svg class="h-4 w-4 text-green-500 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      Priority support
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <!-- Footer -->
            <div class="bg-gray-50 px-6 py-4 flex flex-col space-y-3 sm:flex-row sm:space-y-0 sm:space-x-3">
              <button
                @click="goToUpgrade"
                type="button"
                class="w-full inline-flex justify-center items-center rounded-lg border border-transparent shadow-sm px-4 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 text-base font-medium text-white hover:from-blue-700 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  />
                </svg>
                Upgrade to Pro
              </button>
              <button
                @click="closeUpgradePrompt"
                type="button"
                class="w-full inline-flex justify-center items-center rounded-lg border border-gray-300 shadow-sm px-4 py-2.5 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors duration-200"
              >
                Maybe Later
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from "vue";
import { useI18n } from "vue-i18n";
import YoutubePlayer from "~/components/courses/YoutubePlayer.vue";
import {
  fetchVideoLessonsForSubject,
  incrementVideoViews,
  fetchVideoById,
} from "~/services/elearningApi";

// Authentication
const { isAuthenticated } = useAuth();

// Session management
const {
  session,
  isSessionActive,
  timeRemaining,
  timeRemainingFormatted,
  isProUser,
  hasTimeLimit,
  startSession,
  endSession,
  startVideoTracking,
  pauseVideoTracking,
  resumeVideoTracking,
  stopVideoTracking,
  trackActivity,
  showAccessModal,
  requiresLogin,
  requiresSubscription,
  closeAccessModal,
  checkVideoAccess
} = useELearningSession();

const props = defineProps({
  subject: {
    type: String,
    default: null,
  },
});

// Get runtime config for API base URL
const config = useRuntimeConfig();

// State variables
const apiVideos = ref([]);
const loading = ref(false);
const error = ref(null);

// Function to load videos from API with improved error handling
async function loadVideos() {
  if (!props.subject) return;

  try {
    loading.value = true;
    error.value = null;
    apiVideos.value = await fetchVideoLessonsForSubject(
      props.subject,
      config.public.baseURL
    );
    console.log("Loaded videos:", apiVideos.value);
  } catch (err) {
    console.error(`Error loading videos for subject ${props.subject}:`, err);
    error.value = $t("no_videos_found"); // Use translated error message
    apiVideos.value = [];

    // Retry loading after a delay if the error might be temporary
    setTimeout(() => {
      if (error.value && props.subject) {
        loadVideos();
      }
    }, 5000);
  } finally {
    loading.value = false;
  }
}

// Watch for subject changes
watch(
  () => props.subject,
  async (newSubject) => {
    if (newSubject) {
      // Always load videos, but only initialize session for authenticated users
      loadVideos();
      if (isAuthenticated.value) {
        await initializeSession();
      }
    }
  }
);

// Session management functions
const showUpgradePrompt = ref(false);

async function initializeSession() {
  try {
    // Only initialize session for authenticated users
    if (!isAuthenticated.value) {
      console.log('User not authenticated, skipping session initialization');
      return;
    }
    
    const currentUrl = window.location.href;
    await startSession(currentUrl, props.subject);
    trackActivity('page_access', { subject_id: props.subject });
  } catch (error) {
    console.error('Failed to initialize session:', error);
    
    if (error.message.includes('upgrade')) {
      showUpgradePrompt.value = true;
    }
  }
}

function closeUpgradePrompt() {
  showUpgradePrompt.value = false;
}

function goToUpgrade() {
  navigateTo('/upgrade-to-pro');
}

// Video event handlers
function handleVideoStart(success, errorMessage) {
  if (!success) {
    console.error('Failed to start video:', errorMessage);
    
    if (errorMessage && errorMessage.includes('limit')) {
      showUpgradePrompt.value = true;
    }
  }
}

function handleVideoPause() {
  // Video paused - tracking is handled by session manager
  console.log('Video paused');
}

function handleVideoResume() {
  // Video resumed - tracking is handled by session manager
  console.log('Video resumed');
}

function handleVideoStop() {
  // Video stopped - tracking is handled by session manager
  console.log('Video stopped');
}

// Access control event handlers
function handleLoginRequired() {
  // Redirect to login page
  navigateTo('/auth/login');
}

function handleSubscriptionRequired() {
  // Show upgrade prompt or redirect to subscription page
  showUpgradePrompt.value = true;
}

// Initial load if subject is already available
onMounted(async () => {
  if (props.subject) {
    loadVideos();
    // Only initialize session for authenticated users
    if (isAuthenticated.value) {
      await initializeSession();
    }
  }
});

// Function to track video views with enhanced error handling
async function trackVideoView(videoId) {
  try {
    const response = await incrementVideoViews(videoId);

    if (response && response.success) {
      // Update the local view count if the API returns the updated count
      if (
        response.views &&
        activeVideo.value &&
        activeVideo.value.id === videoId
      ) {
        activeVideo.value.views = response.views.toString();

        // Also update the view count in the list of videos
        const videoIndex = subjectVideos.value.findIndex(
          (v) => v.id === videoId
        );
        if (videoIndex >= 0) {
          subjectVideos.value[videoIndex].views = response.views.toString();
        }
      }
      return true;
    }
    return false;
  } catch (err) {
    console.error(`Error tracking view for video ${videoId}:`, err);
    return false;
  }
}

// Preload video details for better user experience when opening videos
async function preloadVideoDetails(videoId) {
  try {
    // Check if the video details are already in the cache or loaded videos
    const existingVideo = subjectVideos.value.find((v) => v.id === videoId);
    if (existingVideo) {
      return existingVideo;
    }

    // Fetch the video details if not available in the component state
    const videoDetails = await fetchVideoById(videoId);

    if (videoDetails) {
      // Format the video data to match the expected structure
      return {
        id: videoDetails.id,
        subjectId: videoDetails.subject,
        title: videoDetails.title,
        title_bn: videoDetails.title_bn,
        lesson: videoDetails.lesson_name,
        lesson_bn: videoDetails.lesson_name_bn,
        description: videoDetails.description,
        description_bn: videoDetails.description_bn,
        url: videoDetails.youtube_url,
        youtube_id: videoDetails.youtube_id,
        duration: videoDetails.duration,
        views: videoDetails.views_count ? `${videoDetails.views_count}` : "0",
        thumbnail_url: videoDetails.thumbnail_url,
      };
    }

    return null;
  } catch (err) {
    console.error(`Error preloading video details for ${videoId}:`, err);
    return null;
  }
}

const selectedLesson = ref("all");
const searchKeyword = ref("");

// Function to clear all filters
function clearFilters() {
  selectedLesson.value = "all";
  searchKeyword.value = "";
}

// Dynamic placeholder text based on selected lesson
const searchPlaceholder = computed(() => {
  if (selectedLesson.value === "all") {
    return $t("search_placeholder") || "Search in all lessons...";
  } else {
    return `${$t("search")} "${selectedLesson.value}" ${$t("lesson")}...`;
  }
});

// Get the current locale
const { locale } = useI18n();

// Check if the current locale is Bengali
const isBengaliLocale = computed(() => {
  return locale.value === "bn";
});

// Filter videos based on selected subject
const subjectVideos = computed(() => {
  if (!props.subject) return [];

  // Use API data if available
  if (apiVideos.value.length > 0) {
    return apiVideos.value.map((video) => ({
      id: video.id,
      subjectId: props.subject,
      title: video.title,
      title_bn: video.title_bn,
      lesson: video.lesson_name,
      lesson_bn: video.lesson_name_bn,
      description: video.description,
      description_bn: video.description_bn,
      url: video.youtube_url,
      youtube_id: video.youtube_id,
      duration: video.duration,
      views: video.views_count ? `${video.views_count}` : "0",
      thumbnail_url: video.thumbnail_url,
    }));
  }

  // Return empty array instead of falling back to static data
  return [];
});

// Get all lessons for the selected subject
const lessons = computed(() => {
  const uniqueLessons = new Set();
  subjectVideos.value.forEach((video) => uniqueLessons.add(video.lesson));
  return [...uniqueLessons];
});

// Filter videos based on both selected lesson and search keyword
const filteredVideos = computed(() => {
  let result = subjectVideos.value;

  // Filter by lesson if not "all"
  if (selectedLesson.value !== "all") {
    result = result.filter((video) => video.lesson === selectedLesson.value);
  }
  // Filter by search keyword if provided with Unicode support
  if (searchKeyword.value.trim()) {
    // Normalize the search term for better Unicode handling (especially for Bangla)
    const keyword = searchKeyword.value.trim().normalize("NFC").toLowerCase();
    result = result.filter((video) => {
      // Normalize all text fields for consistent Unicode comparison
      const normalizedTitle = (
        isBengaliLocale.value && video.title_bn
          ? video.title_bn
          : video.title || ""
      )
        .normalize("NFC")
        .toLowerCase();
      const normalizedDescription = (
        isBengaliLocale.value && video.description_bn
          ? video.description_bn
          : video.description || ""
      )
        .normalize("NFC")
        .toLowerCase();
      const normalizedLesson = (
        isBengaliLocale.value && video.lesson_bn
          ? video.lesson_bn
          : video.lesson || ""
      )
        .normalize("NFC")
        .toLowerCase();

      return (
        normalizedTitle.includes(keyword) ||
        normalizedDescription.includes(keyword) ||
        normalizedLesson.includes(keyword)
      );
    });
  }

  return result;
});

// State for modal dialog
const showDescriptionModal = ref(false);
const activeVideo = ref(null);

// Function to open the description modal with preloading and access control
async function openDescriptionModal(video) {
  try {
    // Check if user is authenticated first
    if (!isAuthenticated.value) {
      // For non-authenticated users, don't check session - just show the video details
      activeVideo.value = video;
      showDescriptionModal.value = true;
      return;
    }    // Check session status and access control only for authenticated users
    if (isSessionActive && !isSessionActive.value) {
      console.error('Session expired. Please refresh the page.');
      return;
    }

    // For non-pro users, check time limit
    if (hasTimeLimit && hasTimeLimit.value && timeRemaining && timeRemaining.value <= 0) {
      showUpgradePrompt.value = true;
      return;
    }    // Show the modal immediately with current video data
    activeVideo.value = video;
    showDescriptionModal.value = true;

    // Start video tracking when modal opens (only for authenticated users)
    if (video.id && isAuthenticated.value && startVideoTracking) {
      startVideoTracking(video.id);
    }

    // Try to get the latest video data (including up-to-date view count)
    // This provides a smoother UX since the modal is shown immediately
    if (video.id) {
      try {
        const updatedVideoDetails = await preloadVideoDetails(video.id);
        if (updatedVideoDetails && showDescriptionModal.value) {
          // Only update if the modal is still open and for the same video
          activeVideo.value = updatedVideoDetails;
        }
      } catch (err) {
        // Silently fail - we already have the basic video data showing
        console.warn("Could not fetch updated video details:", err);
      }
    }  } catch (error) {
    console.error('Failed to open video:', error);
    
    if (error.message.includes('upgrade') || error.message.includes('limit')) {
      showUpgradePrompt.value = true;
    }
  }
}

// Function to close the description modal
function closeDescriptionModal() {
  // Stop video tracking when modal closes (only for authenticated users)
  if (isAuthenticated.value && stopVideoTracking) {
    stopVideoTracking();
  }
  
  showDescriptionModal.value = false;
  setTimeout(() => {
    activeVideo.value = null;
  }, 300); // Delay clearing the video for smoother animation
}

// Cleanup on component unmount
onUnmounted(async () => {
  // Only cleanup session-related stuff for authenticated users
  if (isAuthenticated.value) {
    if (stopVideoTracking) {
      stopVideoTracking();
    }
    if (isSessionActive && isSessionActive.value && endSession) {
      await endSession();
    }
  }
});

// Helper function to extract YouTube video ID from URL
function getYoutubeId(url) {
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  const match = url.match(regExp);
  return match && match[2].length === 11 ? match[2] : null;
}

// Check if search keyword is found in a text
function hasMatch(text) {
  if (!text || !searchKeyword.value.trim()) return false;
  return text.toLowerCase().includes(searchKeyword.value.trim().toLowerCase());
}

// Highlight search term in text
function highlightText(text) {
  if (!text || !searchKeyword.value.trim()) return text;

  const keyword = searchKeyword.value.trim();
  const regex = new RegExp(`(${keyword})`, "gi");

  return text.replace(
    regex,
    '<mark class="bg-yellow-200 rounded px-0.5">$1</mark>'
  );
}

// Note: Modal state and functions are already defined above
</script>

<style scoped>
.aspect-w-16 {
  position: relative;
  padding-bottom: 56.25%; /* 16:9 Aspect Ratio */
}
.aspect-w-16 > * {
  position: absolute;
  height: 100%;
  width: 100%;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
}

/* Line clamp utility for truncating text at 2 lines */
.line-clamp-2 {
  display: -webkit-box;
  display: -moz-box;
  display: flex;
  -webkit-line-clamp: 2;
  -moz-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  -moz-box-orient: vertical;
  box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  max-height: 2.5rem; /* Fallback for browsers that don't support line-clamp */
}

/* Background gradient animation for search card */
.bg-gradient-to-r {
  background-size: 200% 200%;
  animation: gradientShift 15s ease infinite;
}

@keyframes gradientShift {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

/* Modal animations */
.modal-backdrop {
  animation: fadeIn 0.3s ease forwards;
}

.modal-content {
  animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translate3d(0, 40px, 0);
  }
  to {
    opacity: 1;
    transform: translate3d(0, 0, 0);
  }
}

/* Custom scrollbar for modal description */
.max-h-60::-webkit-scrollbar {
  width: 6px;
}

.max-h-60::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 8px;
}

.max-h-60::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 8px;
  border: 1px solid #f1f1f1;
}

.max-h-60::-webkit-scrollbar-thumb:hover {
  background-color: #94a3b8;
}
</style>
