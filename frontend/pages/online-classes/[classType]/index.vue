<template>
  <PublicSection>
    <UContainer class="py-8">
      <UBreadcrumb :links="breadcrumbs" class="mb-6" />
      
      <h1 class="text-3xl font-bold mb-2 flex items-center">
        <UIcon 
          :name="classType === 'ssc' ? 'i-heroicons-academic-cap' : 'i-heroicons-book-open'" 
          class="mr-3 text-3xl" 
          :class="classType === 'ssc' ? 'text-blue-700' : 'text-purple-700'"
        />
        {{ classTitle }} Categories
      </h1>
      <p class="text-gray-600 mb-8">Select your study category to explore subjects and video lessons</p>

      <!-- Categories Section -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        <!-- Science Category -->
        <UCard 
          class="transform transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer"
          @click="navigateTo(`/online-classes/${classType}/science`)"
        >
          <template #header>
            <div class="bg-gradient-to-r from-green-50 to-green-100 p-3">
              <h2 class="text-xl font-bold text-green-700 flex items-center">
                <UIcon name="i-heroicons-beaker" class="mr-2 text-2xl" />
                Science
              </h2>
            </div>
          </template>
          <div class="p-4">
            <p class="text-gray-600 mb-4">Physics, Chemistry, Biology, Higher Mathematics and more.</p>
            <div class="flex flex-wrap gap-1 mb-4">
              <UBadge color="green" size="sm" class="font-medium">Physics</UBadge>
              <UBadge color="green" size="sm" class="font-medium">Chemistry</UBadge>
              <UBadge color="green" size="sm" class="font-medium">Biology</UBadge>
              <UBadge color="green" size="sm" class="font-medium">Mathematics</UBadge>
            </div>
            <UButton 
              icon="i-heroicons-arrow-right" 
              color="green" 
              variant="soft" 
              class="w-full"
              label="Explore Science"
            />
          </div>
        </UCard>

        <!-- Humanities Category -->
        <UCard 
          class="transform transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer"
          @click="navigateTo(`/online-classes/${classType}/humanities`)"
        >
          <template #header>
            <div class="bg-gradient-to-r from-amber-50 to-amber-100 p-3">
              <h2 class="text-xl font-bold text-amber-700 flex items-center">
                <UIcon name="i-heroicons-language" class="mr-2 text-2xl" />
                Humanities
              </h2>
            </div>
          </template>
          <div class="p-4">
            <p class="text-gray-600 mb-4">History, Geography, Social Science, Literature and more.</p>
            <div class="flex flex-wrap gap-1 mb-4">
              <UBadge color="amber" size="sm" class="font-medium">History</UBadge>
              <UBadge color="amber" size="sm" class="font-medium">Geography</UBadge>
              <UBadge color="amber" size="sm" class="font-medium">Sociology</UBadge>
              <UBadge color="amber" size="sm" class="font-medium">Literature</UBadge>
            </div>
            <UButton 
              icon="i-heroicons-arrow-right" 
              color="amber" 
              variant="soft" 
              class="w-full"
              label="Explore Humanities"
            />
          </div>
        </UCard>

        <!-- Commerce Category -->
        <UCard 
          class="transform transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer"
          @click="navigateTo(`/online-classes/${classType}/commerce`)"
        >
          <template #header>
            <div class="bg-gradient-to-r from-blue-50 to-blue-100 p-3">
              <h2 class="text-xl font-bold text-blue-700 flex items-center">
                <UIcon name="i-heroicons-currency-dollar" class="mr-2 text-2xl" />
                Commerce
              </h2>
            </div>
          </template>
          <div class="p-4">
            <p class="text-gray-600 mb-4">Accounting, Finance, Business Studies, Economics and more.</p>
            <div class="flex flex-wrap gap-1 mb-4">
              <UBadge color="blue" size="sm" class="font-medium">Accounting</UBadge>
              <UBadge color="blue" size="sm" class="font-medium">Finance</UBadge>
              <UBadge color="blue" size="sm" class="font-medium">Economics</UBadge>
              <UBadge color="blue" size="sm" class="font-medium">Business</UBadge>
            </div>
            <UButton 
              icon="i-heroicons-arrow-right" 
              color="blue" 
              variant="soft" 
              class="w-full"
              label="Explore Commerce"
            />
          </div>
        </UCard>
      </div>

      <!-- Teachers Section -->
      <div>
        <h2 class="text-2xl font-bold mb-6 flex items-center">
          <UIcon name="i-heroicons-user-group" class="mr-2" />
          Meet Our {{ classTitle }} Teachers
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <!-- Teacher 1 -->
          <UCard class="hover:shadow-lg transition-shadow">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <img src="https://i.pravatar.cc/150?img=1" alt="Teacher" class="w-20 h-20 rounded-full object-cover border-2 border-primary-100">
              </div>
              <div class="ml-4">
                <h3 class="text-lg font-semibold">Dr. Farhan Ahmed</h3>
                <p class="text-sm text-primary-600 font-medium">Science Specialist</p>
                <div class="flex items-center mt-1">
                  <div class="flex">
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star-half" class="text-amber-400" />
                  </div>
                  <span class="text-xs ml-1">(4.5)</span>
                </div>
              </div>
            </div>
            <div class="mt-3 text-sm text-gray-600">
              <p>Ph.D in Physics with 10+ years of teaching experience. Expert in simplifying complex scientific concepts.</p>
            </div>
            <template #footer>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Physics, Chemistry</span>
                <UButton size="sm" color="primary" variant="soft" label="View Profile" />
              </div>
            </template>
          </UCard>

          <!-- Teacher 2 -->
          <UCard class="hover:shadow-lg transition-shadow">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <img src="https://i.pravatar.cc/150?img=5" alt="Teacher" class="w-20 h-20 rounded-full object-cover border-2 border-primary-100">
              </div>
              <div class="ml-4">
                <h3 class="text-lg font-semibold">Prof. Nusrat Jahan</h3>
                <p class="text-sm text-amber-600 font-medium">Humanities Expert</p>
                <div class="flex items-center mt-1">
                  <div class="flex">
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                  </div>
                  <span class="text-xs ml-1">(5.0)</span>
                </div>
              </div>
            </div>
            <div class="mt-3 text-sm text-gray-600">
              <p>M.A. in History with specialization in Bengali literature. Award-winning educator with engaging teaching style.</p>
            </div>
            <template #footer>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">History, Literature</span>
                <UButton size="sm" color="primary" variant="soft" label="View Profile" />
              </div>
            </template>
          </UCard>

          <!-- Teacher 3 -->
          <UCard class="hover:shadow-lg transition-shadow">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <img src="https://i.pravatar.cc/150?img=3" alt="Teacher" class="w-20 h-20 rounded-full object-cover border-2 border-primary-100">
              </div>
              <div class="ml-4">
                <h3 class="text-lg font-semibold">Kamal Hossain</h3>
                <p class="text-sm text-blue-600 font-medium">Commerce Specialist</p>
                <div class="flex items-center mt-1">
                  <div class="flex">
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-amber-400" />
                    <UIcon name="i-heroicons-star" class="text-gray-300" />
                  </div>
                  <span class="text-xs ml-1">(4.0)</span>
                </div>
              </div>
            </div>
            <div class="mt-3 text-sm text-gray-600">
              <p>MBA in Finance with extensive industry experience. Makes accounting and finance concepts easy to understand.</p>
            </div>
            <template #footer>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Accounting, Business</span>
                <UButton size="sm" color="primary" variant="soft" label="View Profile" />
              </div>
            </template>
          </UCard>
        </div>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const route = useRoute();
const classType = computed(() => route.params.classType); // 'ssc' or 'hsc'

// Dynamically set class title based on URL param
const classTitle = computed(() => {
  if (classType.value === 'ssc') {
    return 'SSC (Secondary School Certificate)';
  } else if (classType.value === 'hsc') {
    return 'HSC (Higher Secondary Certificate)';
  }
  return 'Online Classes';
});

// Dynamic breadcrumbs based on current path
const breadcrumbs = computed(() => [
  {
    label: 'Home',
    to: '/'
  },
  {
    label: 'Online Classes',
    to: '/online-classes'
  },
  {
    label: classTitle.value,
    to: `/online-classes/${classType.value}`
  }
]);
</script>

<style scoped>
/* Add any specific styles you need here */
</style>
