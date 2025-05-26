<template>
  <PublicSection>
    <UContainer class="py-8">
      <h1 class="text-3xl font-bold mb-2">Online Classes</h1>
      <p class="text-gray-600 mb-8">Choose your class to explore study materials and video lessons</p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- SSC Class Card -->
        <UCard 
          class="transform transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer"
          @click="navigateTo('/online-classes/ssc')"
        >
          <template #header>
            <div class="bg-gradient-to-r from-blue-50 to-blue-100 p-3">
              <h2 class="text-2xl font-bold text-blue-700 flex items-center">
                <UIcon name="i-heroicons-academic-cap" class="mr-2 text-3xl" />
                SSC (Secondary School Certificate)
              </h2>
            </div>
          </template>
          <div class="p-5">
            <p class="text-gray-600 mb-4">Access video lessons and study materials for SSC examination preparation.</p>
            <div class="flex flex-wrap gap-2 mb-4">
              <UBadge color="blue" class="font-medium">Class 9-10</UBadge>
              <UBadge color="gray" class="font-medium">All Subjects</UBadge>
              <UBadge color="gray" class="font-medium">Video Lessons</UBadge>
            </div>
            <div class="flex justify-between items-center">
              <p class="text-sm text-gray-500">
                <UIcon name="i-heroicons-video-camera" class="mr-1" /> 300+ Video Lessons
              </p>
              <UButton 
                icon="i-heroicons-arrow-right" 
                color="blue" 
                variant="soft" 
                class="ml-auto"
                label="Start Learning"
              />
            </div>
          </div>
        </UCard>

        <!-- HSC Class Card -->
        <UCard 
          class="transform transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer"
          @click="navigateTo('/online-classes/hsc')"
        >
          <template #header>
            <div class="bg-gradient-to-r from-purple-50 to-purple-100 p-3">
              <h2 class="text-2xl font-bold text-purple-700 flex items-center">
                <UIcon name="i-heroicons-academic-cap" class="mr-2 text-3xl" />
                HSC (Higher Secondary Certificate)
              </h2>
            </div>
          </template>
          <div class="p-5">
            <p class="text-gray-600 mb-4">Access video lessons and study materials for HSC examination preparation.</p>
            <div class="flex flex-wrap gap-2 mb-4">
              <UBadge color="purple" class="font-medium">Class 11-12</UBadge>
              <UBadge color="gray" class="font-medium">All Subjects</UBadge>
              <UBadge color="gray" class="font-medium">Video Lessons</UBadge>
            </div>
            <div class="flex justify-between items-center">
              <p class="text-sm text-gray-500">
                <UIcon name="i-heroicons-video-camera" class="mr-1" /> 450+ Video Lessons
              </p>
              <UButton 
                icon="i-heroicons-arrow-right" 
                color="purple" 
                variant="soft"
                class="ml-auto"
                label="Start Learning"
              />
            </div>
          </div>
        </UCard>
      </div>

      <!-- Features Section -->
      <div class="mt-16">
        <h2 class="text-2xl font-bold mb-6 text-center">Features of Our Online Classes</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="p-5 bg-white rounded-lg shadow-md">
            <div class="flex items-center justify-center h-12 w-12 rounded-md bg-primary-100 text-primary-600 mb-4">
              <UIcon name="i-heroicons-video-camera" class="text-2xl" />
            </div>
            <h3 class="text-lg font-medium mb-2">High Quality Video Lessons</h3>
            <p class="text-gray-600">Learn with HD quality video lessons created by experienced teachers.</p>
          </div>

          <div class="p-5 bg-white rounded-lg shadow-md">
            <div class="flex items-center justify-center h-12 w-12 rounded-md bg-primary-100 text-primary-600 mb-4">
              <UIcon name="i-heroicons-document-text" class="text-2xl" />
            </div>
            <h3 class="text-lg font-medium mb-2">Comprehensive Study Materials</h3>
            <p class="text-gray-600">Access detailed notes, examples, and practice questions for each topic.</p>
          </div>

          <div class="p-5 bg-white rounded-lg shadow-md">
            <div class="flex items-center justify-center h-12 w-12 rounded-md bg-primary-100 text-primary-600 mb-4">
              <UIcon name="i-heroicons-user-group" class="text-2xl" />
            </div>
            <h3 class="text-lg font-medium mb-2">Expert Teachers</h3>
            <p class="text-gray-600">Learn from experienced teachers with proven track records of success.</p>
          </div>
        </div>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
// navigateTo is a global helper in Nuxt 3
</script>
