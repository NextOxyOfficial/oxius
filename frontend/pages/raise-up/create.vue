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
              Location <span class="text-red-500">*</span>
            </label>
            <UInput
              v-model="form.location"
              placeholder="e.g., Bangladesh"
              :ui="{ rounded: 'rounded-xl' }"
            />
          </div>
        </div>

        <!-- Stage & Stage Color -->
        <div class="grid grid-cols-2 gap-4">
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
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Stage Color <span class="text-red-500">*</span>
            </label>
            <USelect
              v-model="form.stageColor"
              :options="stageColorOptions"
              placeholder="Select color"
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

        <!-- Traction -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Traction <span class="text-red-500">*</span>
          </label>
          <UInput
            v-model="form.traction"
            placeholder="e.g., 500+ Users, $10K Revenue"
            :ui="{ rounded: 'rounded-xl' }"
          />
          <p class="mt-1 text-xs text-slate-500">Current achievements, users, revenue, etc.</p>
        </div>

        <!-- Media Upload -->
        <div class="bg-slate-50 dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700 p-4">
          <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4">Media Content</h3>
          
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Media Type <span class="text-red-500">*</span>
              </label>
              <USelect
                v-model="form.mediaType"
                :options="mediaTypeOptions"
                placeholder="Select media type"
                :ui="{ rounded: 'rounded-xl' }"
              />
            </div>

            <!-- Thumbnail Upload -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Thumbnail Image <span class="text-red-500">*</span>
              </label>
              
              <!-- Upload Button -->
              <div v-if="!thumbnailPreview" class="border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-xl p-6 text-center hover:border-purple-400 dark:hover:border-purple-500 transition cursor-pointer" @click="$refs.thumbnailInput.click()">
                <UIcon name="i-heroicons-photo" class="w-12 h-12 mx-auto text-slate-400 mb-2" />
                <p class="text-sm text-slate-600 dark:text-slate-400 mb-1">Click to upload thumbnail image</p>
                <p class="text-xs text-slate-500">PNG, JPG, GIF up to 10MB</p>
              </div>
              
              <!-- Preview -->
              <div v-else class="relative rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700">
                <img :src="thumbnailPreview" alt="Thumbnail preview" class="w-full h-48 object-cover" />
                <button @click.prevent="removeThumbnail" class="absolute flex top-2 right-2 bg-red-500 hover:bg-red-600 text-white rounded-full p-2 transition">
                  <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
                </button>
              </div>
              
              <input ref="thumbnailInput" type="file" accept="image/*" @change="handleThumbnailUpload" class="hidden" />
              
              <!-- Or use URL -->
              <div class="mt-3">
                <label class="flex items-center gap-2 text-xs text-slate-600 dark:text-slate-400 mb-2">
                  <input type="checkbox" v-model="useThumbnailUrl" class="rounded" />
                  Or paste image URL instead
                </label>
                <UInput
                  v-if="useThumbnailUrl"
                  v-model="form.thumbnail"
                  placeholder="https://example.com/image.jpg"
                  :ui="{ rounded: 'rounded-xl' }"
                />
              </div>
            </div>

            <!-- Video Upload/URL -->
            <div v-if="form.mediaType === 'video'">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Video Content
              </label>
              
              <!-- Video Upload -->
              <div v-if="!videoPreview && !useVideoUrl" class="border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-xl p-6 text-center hover:border-purple-400 dark:hover:border-purple-500 transition cursor-pointer" @click="$refs.videoInput.click()">
                <UIcon name="i-heroicons-film" class="w-12 h-12 mx-auto text-slate-400 mb-2" />
                <p class="text-sm text-slate-600 dark:text-slate-400 mb-1">Click to upload video</p>
                <p class="text-xs text-slate-500">MP4, MOV, AVI up to 100MB</p>
              </div>
              
              <!-- Video Preview -->
              <div v-else-if="videoPreview" class="relative rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700">
                <video :src="videoPreview" controls class="w-full h-64" />
                <button @click.prevent="removeVideo" class="absolute flex top-2 right-2 bg-red-500 hover:bg-red-600 text-white rounded-full p-2 transition">
                  <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
                </button>
              </div>
              
              <input ref="videoInput" type="file" accept="video/*" @change="handleVideoUpload" class="hidden" />
              
              <!-- Or use YouTube URL -->
              <div class="mt-3">
                <label class="flex items-center gap-2 text-xs text-slate-600 dark:text-slate-400 mb-2">
                  <input type="checkbox" v-model="useVideoUrl" class="rounded" />
                  Or paste YouTube URL instead
                </label>
                <UInput
                  v-if="useVideoUrl"
                  v-model="form.videoUrl"
                  placeholder="https://www.youtube.com/watch?v=..."
                  :ui="{ rounded: 'rounded-xl' }"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Overview -->
        <div>
          <label class="flex items-center justify-between text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            <span>Detailed Overview</span>
            <button @click.prevent="expandOverview = !expandOverview" class="text-xs text-purple-600 dark:text-purple-400 hover:underline">
              {{ expandOverview ? 'Collapse' : 'Expand' }}
            </button>
          </label>
          <UTextarea
            v-model="form.overview"
            placeholder="Explain your business model, target market, and growth plans..."
            :rows="expandOverview ? 10 : 4"
            :ui="{ rounded: 'rounded-xl' }"
            autoresize
          />
        </div>

        <!-- Use of Funds -->
        <div>
          <label class="flex items-center justify-between text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            <span>Use of Funds</span>
            <button @click.prevent="expandFunds = !expandFunds" class="text-xs text-purple-600 dark:text-purple-400 hover:underline">
              {{ expandFunds ? 'Collapse' : 'Expand' }}
            </button>
          </label>
          <UTextarea
            v-model="form.useOfFunds"
            placeholder="How will you use the funding? (One item per line)"
            :rows="expandFunds ? 8 : 3"
            :ui="{ rounded: 'rounded-xl' }"
            autoresize
          />
          <p class="mt-1 text-xs text-slate-500">Enter each item on a new line</p>
        </div>

        <!-- Milestones -->
        <div>
          <label class="flex items-center justify-between text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            <span>Milestones</span>
            <button @click.prevent="expandMilestones = !expandMilestones" class="text-xs text-purple-600 dark:text-purple-400 hover:underline">
              {{ expandMilestones ? 'Collapse' : 'Expand' }}
            </button>
          </label>
          <UTextarea
            v-model="form.milestones"
            placeholder="Key milestones you plan to achieve (One per line)"
            :rows="expandMilestones ? 8 : 3"
            :ui="{ rounded: 'rounded-xl' }"
            autoresize
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

// File upload states
const thumbnailFile = ref(null)
const videoFile = ref(null)
const thumbnailPreview = ref(null)
const videoPreview = ref(null)
const useThumbnailUrl = ref(false)
const useVideoUrl = ref(false)

// Expandable textarea states
const expandOverview = ref(false)
const expandFunds = ref(false)
const expandMilestones = ref(false)

const form = ref({
  title: '',
  summary: '',
  sector: '',
  location: '',
  stage: '',
  stageColor: '',
  city: '',
  area: '',
  fundingType: '',
  goal: '',
  minInvestment: '',
  expectedReturn: '',
  riskLevel: '',
  traction: '',
  mediaType: 'image',
  thumbnail: '',
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
  { label: 'Seed', value: 'seed' },
  { label: 'Early', value: 'early' },
  { label: 'Growth', value: 'growth' },
]

const stageColorOptions = [
  { label: 'Purple', value: 'purple' },
  { label: 'Blue', value: 'blue' },
  { label: 'Emerald', value: 'emerald' },
  { label: 'Amber', value: 'amber' },
]

const fundingTypeOptions = [
  { label: 'Investment', value: 'investment' },
  { label: 'Donation', value: 'donation' },
  { label: 'Investment + Donation', value: 'investment_donation' },
  { label: 'Revenue Share', value: 'revenue_share' },
]

const riskOptions = [
  { label: 'Low', value: 'low' },
  { label: 'Medium', value: 'medium' },
  { label: 'High', value: 'high' },
]

const mediaTypeOptions = [
  { label: 'Image', value: 'image' },
  { label: 'Video', value: 'video' },
]

// File upload handlers
const handleThumbnailUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    if (file.size > 10 * 1024 * 1024) {
      toast.add({
        title: 'File too large',
        description: 'Thumbnail must be less than 10MB',
        color: 'red',
      })
      return
    }
    thumbnailFile.value = file
    thumbnailPreview.value = URL.createObjectURL(file)
    useThumbnailUrl.value = false
    form.value.thumbnail = '' // Clear URL if file is uploaded
  }
}

const handleVideoUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    if (file.size > 100 * 1024 * 1024) {
      toast.add({
        title: 'File too large',
        description: 'Video must be less than 100MB',
        color: 'red',
      })
      return
    }
    videoFile.value = file
    videoPreview.value = URL.createObjectURL(file)
    useVideoUrl.value = false
    form.value.videoUrl = '' // Clear URL if file is uploaded
  }
}

const removeThumbnail = () => {
  thumbnailFile.value = null
  thumbnailPreview.value = null
  form.value.thumbnail = ''
  useThumbnailUrl.value = false
}

const removeVideo = () => {
  videoFile.value = null
  videoPreview.value = null
  form.value.videoUrl = ''
  useVideoUrl.value = false
}

// Upload file to server
const uploadFile = async (file, type) => {
  const config = useRuntimeConfig()
  const formData = new FormData()
  formData.append('file', file)
  
  try {
    const response = await $fetch(`${config.public.baseURL}/api/upload/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${currentUser.value.access}`,
      },
      body: formData
    })
    return response.url
  } catch (error) {
    console.error(`Error uploading ${type}:`, error)
    throw error
  }
}

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

  // Validate required fields
  const requiredFields = [
    { field: 'title', name: 'Title' },
    { field: 'summary', name: 'Summary' },
    { field: 'sector', name: 'Sector' },
    { field: 'location', name: 'Location' },
    { field: 'stage', name: 'Stage' },
    { field: 'stageColor', name: 'Stage Color' },
    { field: 'city', name: 'City' },
    { field: 'fundingType', name: 'Funding Type' },
    { field: 'goal', name: 'Funding Goal' },
    { field: 'traction', name: 'Traction' },
    { field: 'mediaType', name: 'Media Type' },
    { field: 'thumbnail', name: 'Thumbnail' },
  ]

  const missingFields = requiredFields.filter(({ field }) => !form.value[field])
  
  if (missingFields.length > 0) {
    toast.add({
      title: 'Missing Fields',
      description: `Please fill in: ${missingFields.map(f => f.name).join(', ')}`,
      color: 'red',
    })
    return
  }

  isSubmitting.value = true

  try {
    const config = useRuntimeConfig()
    
    // Upload files if present
    let thumbnailUrl = form.value.thumbnail
    let videoUrl = form.value.videoUrl
    
    if (thumbnailFile.value && !useThumbnailUrl.value) {
      toast.add({
        title: 'Uploading thumbnail...',
        color: 'blue',
      })
      thumbnailUrl = await uploadFile(thumbnailFile.value, 'thumbnail')
    }
    
    if (videoFile.value && !useVideoUrl.value && form.value.mediaType === 'video') {
      toast.add({
        title: 'Uploading video...',
        color: 'blue',
      })
      videoUrl = await uploadFile(videoFile.value, 'video')
    }
    
    // Prepare data for API
    const postData = {
      title: form.value.title,
      summary: form.value.summary,
      sector: form.value.sector,
      location: form.value.location,
      city: form.value.city,
      area: form.value.area || '',
      stage: form.value.stage,
      stage_color: form.value.stageColor,
      funding_type: form.value.fundingType,
      min_investment: parseFloat(form.value.minInvestment) || 0,
      expected_return: form.value.expectedReturn || '',
      risk_level: form.value.riskLevel || 'medium',
      traction: form.value.traction,
      goal: parseFloat(form.value.goal),
      thumbnail: thumbnailUrl,
      video_embed_url: videoUrl || '',
      media_type: form.value.mediaType,
      overview: form.value.overview || '',
      use_of_funds: form.value.useOfFunds ? form.value.useOfFunds.split('\n').filter(item => item.trim()) : [],
      milestones: form.value.milestones ? form.value.milestones.split('\n').filter(item => item.trim()) : [],
    }

    const response = await $fetch(`${config.public.baseURL}/api/raise-up/posts/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${currentUser.value.access}`,
        'Content-Type': 'application/json',
      },
      body: postData
    })

    if (response.success) {
      toast.add({
        title: 'Success!',
        description: 'Your idea has been posted successfully',
        color: 'green',
      })
      router.push('/raise-up')
    } else {
      throw new Error(response.message || 'Failed to create post')
    }
  } catch (error) {
    console.error('Error creating post:', error)
    toast.add({
      title: 'Error',
      description: error.message || 'Failed to submit your idea. Please try again.',
      color: 'red',
    })
  } finally {
    isSubmitting.value = false
  }
}
</script>
