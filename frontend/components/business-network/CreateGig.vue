<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-4xl">
    <!-- Header Section -->
    <div class="px-2 mb-6">
      <h1 class="text-2xl font-bold text-gray-900 flex items-center mb-2">
        <div class="w-8 h-8 bg-gradient-to-r from-green-500 to-green-600 rounded-lg flex items-center justify-center mr-3">
          <Plus class="h-5 w-5 text-white" />
        </div>
        Create Your Gig
      </h1>
      <p class="text-gray-600">Start earning by offering your services to our community of professionals.</p>
    </div>

    <!-- Main Content -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="sm:p-8 p-2">
        <form @submit.prevent="submitGig" class="space-y-8">
          <!-- Gig Image Upload Section -->
          <div>
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Gig Image</h3>
            <div class="space-y-4">
              <!-- Main Image Upload -->
              <div 
                @click="triggerImageUpload"
                class="aspect-video rounded-lg border-2 border-dashed border-gray-300 hover:border-purple-400 transition-colors bg-gray-50 flex items-center justify-center cursor-pointer overflow-hidden relative"
              >
                <!-- Image Preview -->
                <img 
                  v-if="imagePreview" 
                  :src="imagePreview" 
                  alt="Gig preview" 
                  class="w-full h-full object-cover"
                />
                <!-- Upload Placeholder -->
                <div v-else class="text-center">
                  <div class="w-12 h-12 bg-gray-200 rounded-lg flex items-center justify-center mx-auto mb-3">
                    <Plus class="h-6 w-6 text-gray-400" />
                  </div>
                  <p class="text-sm text-gray-600 mb-1">Upload main gig image</p>
                  <p class="text-xs text-gray-500">Recommended: 1280x720px</p>
                </div>
                <!-- Remove Button -->
                <button 
                  v-if="imagePreview"
                  @click.stop="removeImage"
                  type="button"
                  class="absolute top-2 right-2 p-1.5 bg-red-500 text-white rounded-full hover:bg-red-600 transition-colors"
                >
                  <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
                </button>
              </div>
              <input 
                ref="imageInput"
                type="file" 
                accept="image/*" 
                class="hidden" 
                @change="handleImageUpload"
              />
            </div>
          </div>

          <!-- Gig Details Section -->
          <div>
            <h3 class="text-lg font-semibold text-gray-900 mb-6">Gig Details</h3>
            <div class="space-y-6">
              <!-- Title -->
              <div>
                <label for="gig-title" class="block text-sm font-medium text-gray-700 mb-2">
                  Gig Title *
                </label>
                <input
                  id="gig-title"
                  v-model="newGig.title"
                  type="text"
                  placeholder="I will design a professional logo for your business"
                  class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                  required
                />
                <p class="text-xs text-gray-500 mt-1">Make it clear and descriptive</p>
              </div>

              <!-- Category and Price Row -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label for="gig-category" class="block text-sm font-medium text-gray-700 mb-2">
                    Category *
                  </label>
                  <select
                    id="gig-category"
                    v-model="newGig.category"
                    class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                    required
                    :disabled="isLoadingOptions"
                  >
                    <option value="">{{ isLoadingOptions ? 'Loading...' : 'Select a category' }}</option>
                    <option 
                      v-for="category in gigOptions.categories" 
                      :key="category.id" 
                      :value="category.id"
                    >
                      {{ category.name }}
                    </option>
                  </select>
                </div>

                <div>
                  <label for="gig-price" class="block text-sm font-medium text-gray-700 mb-2">
                    <span class="inline-flex items-center">Starting Price (<UIcon name="i-mdi:currency-bdt" />) *</span>
                  </label>
                  <div class="relative">
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <UIcon name="i-mdi:currency-bdt" class="text-gray-400" />
                    </div>
                    <input
                      id="gig-price"
                      v-model="newGig.price"
                      type="number"
                      min="5"
                      placeholder="25"
                      class="w-full pl-8 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                      required
                    />
                  </div>
                  <p class="text-xs text-gray-500 mt-1 inline-flex items-center">Minimum <UIcon name="i-mdi:currency-bdt" class="mx-0.5" />5</p>
                </div>
              </div>

              <!-- Description -->
              <div>
                <label for="gig-description" class="block text-sm font-medium text-gray-700 mb-2">
                  Description *
                </label>
                <textarea
                  id="gig-description"
                  v-model="newGig.description"
                  rows="6"
                  placeholder="Describe your service in detail. What will you deliver? What makes your service unique?"
                  class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors resize-none"
                  required
                ></textarea>
                <p class="text-xs text-gray-500 mt-1">Be specific about what you'll deliver</p>
              </div>

              <!-- Skills & Expertise Section -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Skills & Expertise
                </label>
                <div class="space-y-3">
                  <!-- Skill Input -->
                  <div class="flex items-center space-x-2">
                    <input
                      v-model="skillInput"
                      type="text"
                      placeholder="e.g., Logo Design, Photoshop, Illustrator"
                      class="flex-1 px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                      @keydown.enter.prevent="addSkill"
                    />
                    <button
                      type="button"
                      @click="addSkill"
                      :disabled="!skillInput.trim() || newGig.skills.length >= 10"
                      :class="[
                        'px-4 py-3 rounded-lg font-medium transition-colors',
                        skillInput.trim() && newGig.skills.length < 10
                          ? 'bg-purple-600 text-white hover:bg-purple-700'
                          : 'bg-gray-200 text-gray-400 cursor-not-allowed'
                      ]"
                    >
                      <Plus class="w-5 h-5" />
                    </button>
                  </div>
                  
                  <!-- Skills Tags -->
                  <div v-if="newGig.skills.length > 0" class="flex flex-wrap gap-2">
                    <span
                      v-for="(skill, index) in newGig.skills"
                      :key="index"
                      class="inline-flex items-center px-3 py-1.5 bg-purple-50 text-purple-700 rounded-full text-sm font-medium"
                    >
                      {{ skill }}
                      <button
                        type="button"
                        @click="removeSkill(index)"
                        class="ml-2 text-purple-500 hover:text-purple-700 transition-colors"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                      </button>
                    </span>
                  </div>
                  
                  <!-- Suggested Skills -->
                  <div v-if="suggestedSkills.length > 0" class="pt-2">
                    <p class="text-xs text-gray-500 mb-2">Suggested skills:</p>
                    <div class="flex flex-wrap gap-2">
                      <button
                        v-for="skill in suggestedSkills"
                        :key="skill"
                        type="button"
                        @click="addSuggestedSkill(skill)"
                        :disabled="newGig.skills.includes(skill) || newGig.skills.length >= 10"
                        :class="[
                          'px-3 py-1 rounded-full text-xs font-medium transition-colors',
                          newGig.skills.includes(skill)
                            ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                            : 'bg-gray-100 text-gray-600 hover:bg-purple-100 hover:text-purple-700'
                        ]"
                      >
                        + {{ skill }}
                      </button>
                    </div>
                  </div>
                </div>
                <p class="text-xs text-gray-500 mt-2">Add up to 10 skills that describe your expertise (press Enter to add)</p>
              </div>

              <!-- Delivery Time and Revisions Row -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label for="delivery-time" class="block text-sm font-medium text-gray-700 mb-2">
                    Delivery Time
                  </label>
                  <select
                    id="delivery-time"
                    v-model="newGig.deliveryTime"
                    class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                    :disabled="isLoadingOptions"
                  >
                    <option value="" disabled>{{ isLoadingOptions ? 'Loading...' : 'Select delivery time' }}</option>
                    <option 
                      v-for="time in gigOptions.delivery_times" 
                      :key="time.id" 
                      :value="String(time.days)"
                    >
                      {{ time.label }}
                    </option>
                  </select>
                </div>

                <div>
                  <label for="revisions" class="block text-sm font-medium text-gray-700 mb-2">
                    Revisions
                  </label>
                  <select
                    id="revisions"
                    v-model="newGig.revisions"
                    class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                    :disabled="isLoadingOptions"
                  >
                    <option value="" disabled>{{ isLoadingOptions ? 'Loading...' : 'Select revisions' }}</option>
                    <option 
                      v-for="revision in gigOptions.revision_options" 
                      :key="revision.id" 
                      :value="String(revision.count)"
                    >
                      {{ revision.label }}
                    </option>
                  </select>
                </div>
              </div>

              <!-- What You'll Get Section -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  What Buyers will Get *
                </label>
                <div class="space-y-3">
                  <!-- Existing features list -->
                  <div
                    v-for="(feature, index) in newGig.features"
                    :key="index"
                    class="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg"
                  >
                    <div class="w-5 h-5 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0">
                      <svg class="w-3 h-3 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                      </svg>
                    </div>
                    <input
                      v-model="feature.text"
                      type="text"
                      placeholder="e.g., High-quality logo design"
                      class="flex-1 px-3 py-2 border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                      @blur="updateFeature(index)"
                    />
                    <button
                      type="button"
                      @click="removeFeature(index)"
                      class="w-8 h-8 flex items-center justify-center text-red-500 hover:bg-red-50 rounded-md transition-colors"
                      :disabled="newGig.features.length <= 1"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                      </svg>
                    </button>
                  </div>
                  
                  <!-- Add new feature button -->
                  <button
                    type="button"
                    @click="addFeature"
                    class="w-full flex items-center justify-center space-x-2 p-3 border-2 border-dashed border-gray-300 hover:border-purple-400 rounded-lg transition-colors text-gray-600 hover:text-purple-600"
                  >
                    <Plus class="w-5 h-5" />
                    <span class="font-medium">Add feature</span>
                  </button>
                </div>
                <p class="text-xs text-gray-500 mt-2">Add at least 3 features that buyers will receive</p>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex justify-end space-x-3 pt-6 border-t border-gray-100">
            <button
              type="button"
              @click="resetForm"
              class="flex-1 sm:flex-none px-4 sm:px-6 py-3 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium text-center"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="!isFormValid"
              :class="[
                'flex-1 sm:flex-none px-4 sm:px-8 py-3 rounded-lg font-medium transition-colors text-center',
                isFormValid
                  ? 'bg-green-600 text-white hover:bg-green-700 shadow-sm'
                  : 'bg-gray-300 text-gray-500 cursor-not-allowed'
              ]"
            >
              <span class="flex items-center justify-center">
                <Plus class="h-4 w-4 mr-2" />
                <span class="hidden sm:inline">Create Gig</span>
                <span class="sm:hidden">Create</span>
              </span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
<script setup>
import { Plus } from 'lucide-vue-next';
import { ref, computed, onMounted, watch } from 'vue';

// Props and emits
const emit = defineEmits(['gigCreated', 'switchTab']);

// Composables
const { user } = useAuth();
const { get, post } = useApi();
const toast = useToast();

// Loading state
const isSubmitting = ref(false);
const isLoadingOptions = ref(true);

// Dynamic options from API
const gigOptions = ref({
  categories: [],
  skills: [],
  delivery_times: [],
  revision_options: []
});

// Image handling
const imageInput = ref(null);
const selectedImage = ref(null);
const imagePreview = ref(null);

// Form state
const newGig = ref({
  title: '',
  category: '',
  price: '',
  description: '',
  deliveryTime: '',
  revisions: '',
  skills: [],
  features: [
    { text: '' },
    { text: '' },
    { text: '' }
  ]
});

// Skills input
const skillInput = ref('');

// Image methods
const triggerImageUpload = () => {
  imageInput.value?.click();
};

const handleImageUpload = (event) => {
  const file = event.target.files[0];
  if (file) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast.add({
        title: 'Invalid File',
        description: 'Please upload an image file',
        color: 'red'
      });
      return;
    }
    
    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast.add({
        title: 'File Too Large',
        description: 'Image must be less than 5MB',
        color: 'red'
      });
      return;
    }
    
    selectedImage.value = file;
    imagePreview.value = URL.createObjectURL(file);
  }
};

const removeImage = () => {
  selectedImage.value = null;
  imagePreview.value = null;
  if (imageInput.value) {
    imageInput.value.value = '';
  }
};

// Fetch gig options from API
const fetchGigOptions = async () => {
  isLoadingOptions.value = true;
  try {
    const { data, error } = await get('/workspace/gig-options/');
    if (data && !error) {
      gigOptions.value = data;
      // Set default values if available
      if (data.delivery_times?.length > 0) {
        newGig.value.deliveryTime = String(data.delivery_times[0].days);
      }
      if (data.revision_options?.length > 0) {
        newGig.value.revisions = String(data.revision_options[0].count);
      }
    }
  } catch (err) {
    console.error('Error fetching gig options:', err);
  } finally {
    isLoadingOptions.value = false;
  }
};

// Computed suggested skills based on selected category
const suggestedSkills = computed(() => {
  if (!newGig.value.category) {
    // Show all skills if no category selected
    return gigOptions.value.skills.slice(0, 8).map(skill => skill.name);
  }
  // Filter skills by selected category
  const categorySkills = gigOptions.value.skills
    .filter(skill => skill.category === newGig.value.category)
    .map(skill => skill.name);
  
  // If no skills for this category, show some general skills
  if (categorySkills.length === 0) {
    return gigOptions.value.skills.slice(0, 8).map(skill => skill.name);
  }
  return categorySkills;
});

// Fetch options on mount
onMounted(() => {
  fetchGigOptions();
});

// Computed
const isFormValid = computed(() => {
  const hasBasicInfo = newGig.value.title && 
         newGig.value.category && 
         newGig.value.price && 
         newGig.value.description;
  
  const hasValidFeatures = newGig.value.features.filter(f => f.text.trim()).length >= 3;
  
  return hasBasicInfo && hasValidFeatures;
});

// Methods
const addFeature = () => {
  if (newGig.value.features.length < 10) { // Limit to 10 features
    newGig.value.features.push({ text: '' });
  }
};

const removeFeature = (index) => {
  if (newGig.value.features.length > 1) {
    newGig.value.features.splice(index, 1);
  }
};

const updateFeature = (index) => {
  // Remove empty features except if it's the last one and there are multiple
  if (!newGig.value.features[index].text.trim() && newGig.value.features.length > 3) {
    removeFeature(index);
  }
};

// Skills methods
const addSkill = () => {
  const skill = skillInput.value.trim();
  if (skill && !newGig.value.skills.includes(skill) && newGig.value.skills.length < 10) {
    newGig.value.skills.push(skill);
    skillInput.value = '';
  }
};

const removeSkill = (index) => {
  newGig.value.skills.splice(index, 1);
};

const addSuggestedSkill = (skill) => {
  if (!newGig.value.skills.includes(skill) && newGig.value.skills.length < 10) {
    newGig.value.skills.push(skill);
  }
};

// Methods
const submitGig = async () => {
  if (!isFormValid.value) {
    toast.add({
      title: "Form Error",
      description: "Please fill in all required fields and add at least 3 features",
      color: "red",
    });
    return;
  }

  isSubmitting.value = true;

  try {
    // Create FormData for multipart upload
    const formData = new FormData();
    formData.append('title', newGig.value.title);
    formData.append('category', newGig.value.category);
    formData.append('price', parseFloat(newGig.value.price));
    formData.append('description', newGig.value.description);
    formData.append('delivery_time', parseInt(newGig.value.deliveryTime));
    formData.append('revisions', parseInt(newGig.value.revisions));
    formData.append('skills', JSON.stringify(newGig.value.skills));
    
    // Add features (filter out empty ones)
    const features = newGig.value.features
      .map(f => f.text.trim())
      .filter(f => f);
    formData.append('features', JSON.stringify(features));
    
    // Add image if selected
    if (selectedImage.value) {
      formData.append('image', selectedImage.value);
    }

    const { data, error } = await post('/workspace/gigs/create/', formData);

    if (error) {
      console.error('Error creating gig:', error);
      toast.add({
        title: "Error",
        description: error.message || "Failed to create gig. Please try again.",
        color: "red",
      });
      return;
    }

    // Store title before reset
    const gigTitle = newGig.value.title;
    
    // Emit the gig creation event to parent
    emit('gigCreated', data);
    
    // Reset form
    resetForm();

    toast.add({
      title: "Gig Created! 🎉",
      description: `"${gigTitle}" has been created successfully`,
      color: "green",
    });
    
    // Switch to My Gigs tab
    emit('switchTab', 'my-gigs');
  } catch (err) {
    console.error('Error creating gig:', err);
    toast.add({
      title: "Error",
      description: "An unexpected error occurred.",
      color: "red",
    });
  } finally {
    isSubmitting.value = false;
  }
};

const resetForm = () => {
  newGig.value = {
    title: '',
    category: '',
    price: '',
    description: '',
    deliveryTime: gigOptions.value.delivery_times?.[0]?.days?.toString() || '7',
    revisions: gigOptions.value.revision_options?.[0]?.count?.toString() || '2',
    skills: [],
    features: [
      { text: '' },
      { text: '' },
      { text: '' }
    ]
  };
  skillInput.value = '';
  
  // Clear image
  selectedImage.value = null;
  imagePreview.value = null;
  if (imageInput.value) {
    imageInput.value.value = '';
  }
};
</script>
