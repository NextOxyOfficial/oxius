<template>
  <div class="min-h-screen bg-gray-50 dark:bg-slate-900">
    <!-- Container -->
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <!-- Breadcrumb -->
      <nav class="flex items-center gap-2 text-sm mb-6">
        <NuxtLink to="/" class="text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 transition">
          Home
        </NuxtLink>
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 text-slate-400" />
        <NuxtLink to="/raise-up" class="text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 transition">
          Raise Up
        </NuxtLink>
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 text-slate-400" />
        <span class="text-gray-900 dark:text-white font-medium">Post Idea</span>
      </nav>

      <!-- Page Header -->
      <div class="flex items-center gap-3 mb-8">
        <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-purple-500/25">
          <UIcon name="i-heroicons-light-bulb" class="w-6 h-6 text-white" />
        </div>
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
            Post Your Idea
          </h1>
          <p class="text-sm text-slate-500 dark:text-slate-400">
            Share your business idea and get funding support
          </p>
        </div>
      </div>

      <!-- Form Card -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 p-6">
      <form @submit.prevent="handleSubmit" class="space-y-6">
        <!-- Title -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Business Title <span class="text-red-500">*</span>
          </label>
          <UInput
            v-model="form.title"
            placeholder="e.g., Solar Water Purifier Micro-Business"
            size="lg"
            :ui="{ rounded: 'rounded-xl' }"
          />
        </div>

        <!-- Summary -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Short Summary <span class="text-red-500">*</span>
          </label>
          <UTextarea
            v-model="form.summary"
            placeholder="Briefly describe your business idea and what you're seeking..."
            :rows="3"
            :ui="{ rounded: 'rounded-xl' }"
          />
        </div>

        <!-- Sector & Location -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Sector <span class="text-red-500">*</span>
            </label>
            <USelect
              v-model="form.sector"
              :options="sectorOptions"
              placeholder="Select sector"
              :ui="{ rounded: 'rounded-xl' }"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Stage <span class="text-red-500">*</span>
            </label>
            <USelect
              v-model="form.stage"
              :options="stageOptions"
              placeholder="Select stage"
              :ui="{ rounded: 'rounded-xl' }"
            />
          </div>
        </div>

        <!-- City & Area -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              City <span class="text-red-500">*</span>
            </label>
            <UInput
              v-model="form.city"
              placeholder="e.g., Dhaka"
              :ui="{ rounded: 'rounded-xl' }"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Area/Upazila
            </label>
            <UInput
              v-model="form.area"
              placeholder="e.g., Mirpur"
              :ui="{ rounded: 'rounded-xl' }"
            />
          </div>
        </div>

        <!-- Funding Details -->
        <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4">
          <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4">Funding Details</h3>
          
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Funding Type <span class="text-red-500">*</span>
              </label>
              <USelect
                v-model="form.fundingType"
                :options="fundingTypeOptions"
                placeholder="Select funding type"
                :ui="{ rounded: 'rounded-xl' }"
              />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Funding Goal (৳) <span class="text-red-500">*</span>
                </label>
                <UInput
                  v-model="form.goal"
                  type="number"
                  placeholder="e.g., 100000"
                  :ui="{ rounded: 'rounded-xl' }"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Min Investment (৳)
                </label>
                <UInput
                  v-model="form.minInvestment"
                  type="number"
                  placeholder="e.g., 5000"
                  :ui="{ rounded: 'rounded-xl' }"
                />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Expected Return
                </label>
                <UInput
                  v-model="form.expectedReturn"
                  placeholder="e.g., 15-20%"
                  :ui="{ rounded: 'rounded-xl' }"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Risk Level
                </label>
                <USelect
                  v-model="form.riskLevel"
                  :options="riskOptions"
                  placeholder="Select risk"
                  :ui="{ rounded: 'rounded-xl' }"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Video URL -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Pitch Video URL (YouTube)
          </label>
          <UInput
            v-model="form.videoUrl"
            placeholder="https://www.youtube.com/watch?v=..."
            :ui="{ rounded: 'rounded-xl' }"
          />
          <p class="mt-1 text-xs text-slate-500">Add a YouTube video to showcase your pitch</p>
        </div>

        <!-- Overview -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Detailed Overview
          </label>
          <UTextarea
            v-model="form.overview"
            placeholder="Explain your business model, target market, and growth plans..."
            :rows="4"
            :ui="{ rounded: 'rounded-xl' }"
          />
        </div>

        <!-- Use of Funds -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Use of Funds
          </label>
          <UTextarea
            v-model="form.useOfFunds"
            placeholder="How will you use the funding? (One item per line)"
            :rows="3"
            :ui="{ rounded: 'rounded-xl' }"
          />
          <p class="mt-1 text-xs text-slate-500">Enter each item on a new line</p>
        </div>

        <!-- Milestones -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Milestones
          </label>
          <UTextarea
            v-model="form.milestones"
            placeholder="Key milestones you plan to achieve (One per line)"
            :rows="3"
            :ui="{ rounded: 'rounded-xl' }"
          />
          <p class="mt-1 text-xs text-slate-500">Enter each milestone on a new line</p>
        </div>

        <!-- Submit Button -->
        <div class="pt-4">
          <UButton
            type="submit"
            size="lg"
            block
            :loading="isSubmitting"
            class="bg-gradient-to-r from-purple-500 to-indigo-600 hover:from-purple-600 hover:to-indigo-700 text-white border-0"
          >
            <UIcon name="i-heroicons-rocket-launch" class="w-5 h-5 mr-2" />
            Submit Your Idea
          </UButton>
        </div>
      </form>
      </div>
    </div>
  </div>
</template>

<script setup>
const router = useRouter()
const toast = useToast()
const { user: currentUser } = useAuth()

const isSubmitting = ref(false)

const form = ref({
  title: '',
  summary: '',
  sector: '',
  stage: '',
  city: '',
  area: '',
  fundingType: '',
  goal: '',
  minInvestment: '',
  expectedReturn: '',
  riskLevel: '',
  videoUrl: '',
  overview: '',
  useOfFunds: '',
  milestones: '',
})

const sectorOptions = [
  'CleanTech',
  'HealthTech',
  'EdTech',
  'FinTech',
  'AgriTech',
  'E-commerce',
  'Food & Beverage',
  'Manufacturing',
  'Services',
  'Other',
]

const stageOptions = [
  'Idea',
  'Seed',
  'Early',
  'Growth',
  'Expansion',
]

const fundingTypeOptions = [
  'Investment',
  'Donation',
  'Investment + Donation',
  'Revenue-share',
  'Donation + Revenue-share',
]

const riskOptions = [
  'Low',
  'Medium',
  'High',
]

const handleSubmit = async () => {
  if (!currentUser.value) {
    toast.add({
      title: 'Login Required',
      description: 'Please login to post your idea',
      color: 'orange',
    })
    router.push('/auth/login')
    return
  }

  if (!form.value.title || !form.value.summary || !form.value.sector || !form.value.stage || !form.value.city || !form.value.fundingType || !form.value.goal) {
    toast.add({
      title: 'Missing Fields',
      description: 'Please fill in all required fields',
      color: 'red',
    })
    return
  }

  isSubmitting.value = true

  try {
    // Mock submission - replace with actual API call
    await new Promise(resolve => setTimeout(resolve, 1500))

    toast.add({
      title: 'Success!',
      description: 'Your idea has been submitted for review',
      color: 'green',
    })

    router.push('/raise-up')
  } catch (error) {
    toast.add({
      title: 'Error',
      description: 'Failed to submit your idea. Please try again.',
      color: 'red',
    })
  } finally {
    isSubmitting.value = false
  }
}
</script>
