<template>
  <!-- Tabs - Improved Responsiveness -->
  <div class="">
    <UTabs v-model="activeTab" :items="tabItems">
      <!-- Reviews Tab -->
      <template #reviews>
        <div>
          <!-- Reviews Summary -->
          <div class="mb-4 p-3 bg-slate-50/70 dark:bg-slate-800/70 rounded-lg">
            <div class="flex flex-col sm:flex-row gap-4">
              <div
                class="flex flex-col items-center sm:border-r sm:border-slate-200 sm:dark:border-slate-700 sm:pr-6"
              >
                <div class="text-2xl font-bold text-slate-800 dark:text-white">
                  {{ currentProduct.rating }}
                </div>
                <div class="flex text-yellow-400 my-1">
                  <UIcon
                    v-for="i in 5"
                    :key="i"
                    name="i-heroicons-star-solid"
                    class="w-4 h-4"
                  />
                </div>
                <div class="text-xs text-slate-500">
                  {{ currentProduct.reviews?.length || 0 }} reviews
                </div>
              </div>

              <div class="flex-1 space-y-1.5">
                <div v-for="n in 5" :key="n" class="flex items-center">
                  <div class="text-xs w-5 text-right mr-2">
                    {{ 6 - n }}
                  </div>
                  <UIcon
                    name="i-heroicons-star"
                    class="w-3.5 h-3.5 text-yellow-400 mr-1.5"
                  />
                  <div
                    class="flex-1 h-2 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden"
                  >
                    <div
                      class="h-full bg-yellow-400"
                      :style="{ width: getRatingPercentage(6 - n) }"
                    ></div>
                  </div>
                  <div class="text-xs w-5 text-right ml-2">
                    {{ getRatingCount(6 - n) }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Reviews List -->
          <div class="space-y-3 max-h-60 overflow-y-auto pr-2">
            <div
              v-for="(review, index) in currentProduct.reviews || []"
              :key="index"
              class="p-3 bg-white dark:bg-slate-800 rounded-lg shadow-sm"
            >
              <div class="flex justify-between mb-2">
                <div class="flex items-center gap-2">
                  <div
                    class="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center"
                  >
                    <span class="font-medium text-sm">{{
                      review.name?.charAt(0) || "?"
                    }}</span>
                  </div>
                  <div>
                    <div class="font-medium text-slate-800 dark:text-white">
                      {{ review.name }}
                    </div>
                    <div class="text-xs text-slate-500">
                      {{ review.date }}
                    </div>
                  </div>
                </div>
                <div class="flex">
                  <UIcon
                    v-for="n in 5"
                    :key="n"
                    :name="
                      n <= review.rating
                        ? 'i-heroicons-star-solid'
                        : 'i-heroicons-star'
                    "
                    class="w-3.5 h-3.5"
                    :class="
                      n <= review.rating ? 'text-yellow-400' : 'text-gray-200'
                    "
                  />
                </div>
              </div>
              <p class="text-sm text-slate-600 dark:text-slate-300">
                {{ review.comment }}
              </p>
            </div>
          </div>
          <!-- Write a Review Section -->
          <div class="mb-6 p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg">
            <h4 class="font-medium text-slate-800 dark:text-white mb-3">
              Write a Review
            </h4>
            <div class="space-y-4">
              <div>
                <label
                  class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                >
                  Rating
                </label>
                <div class="flex gap-1">
                  <UButton
                    v-for="star in 5"
                    :key="star"
                    variant="ghost"
                    color="gray"
                    class="p-1"
                    @click="reviewForm.rating = star"
                  >
                    <UIcon
                      :name="
                        star <= reviewForm.rating
                          ? 'i-heroicons-star-solid'
                          : 'i-heroicons-star'
                      "
                      class="w-6 h-6 transition-colors duration-200"
                      :class="
                        star <= reviewForm.rating
                          ? 'text-yellow-400'
                          : 'text-slate-300 dark:text-slate-600'
                      "
                    />
                  </UButton>
                </div>
              </div>
              <div>
                <label
                  class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                >
                  Your Name
                </label>
                <UInput
                  v-model="reviewForm.name"
                  placeholder="Enter your name"
                />
              </div>
              <div>
                <label
                  class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                >
                  Review Comment
                </label>
                <UTextarea
                  v-model="reviewForm.comment"
                  placeholder="Share your thoughts about this product"
                  :ui="{ rounded: 'rounded-lg' }"
                  rows="3"
                />
              </div>
              <UButton
                color="primary"
                @click="submitReview"
                :disabled="!isReviewValid"
                block
              >
                Submit Review
              </UButton>
            </div>
          </div>
        </div>
      </template>

      <!-- Details Tab -->
      <template #details>
        <div
          class="prose prose-sm max-w-none text-slate-600 dark:text-slate-300"
        >
          <div v-html="currentProduct.description"></div>
          <p class="mt-3">
            Experience the perfect blend of design and functionality with our
            {{ currentProduct.name }}. Designed with the modern consumer in
            mind.
          </p>

          <h4
            class="text-base font-semibold mt-4 mb-2 text-slate-800 dark:text-white"
          >
            Specifications
          </h4>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-2">
            <div
              class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
            >
              <span class="text-slate-500 dark:text-slate-400">Brand:</span>
              <span class="font-medium">Premium Selection</span>
            </div>
            <div
              class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
            >
              <span class="text-slate-500 dark:text-slate-400">Model:</span>
              <span class="font-medium"
                >X-{{ 1000 + Math.floor(Math.random() * 9000) }}</span
              >
            </div>
            <div
              class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
            >
              <span class="text-slate-500 dark:text-slate-400"
                >Dimensions:</span
              >
              <span class="font-medium">24 x 12 x 8 cm</span>
            </div>
            <div
              class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
            >
              <span class="text-slate-500 dark:text-slate-400">Weight:</span>
              <span class="font-medium">1.2 kg</span>
            </div>
          </div>
        </div>
      </template>
    </UTabs>
  </div>
</template>
