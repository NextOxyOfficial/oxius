<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-4xl">
    <!-- Header Section -->
    <div class="mb-6">
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
      <div class="sm:p-8 p-4">
        <form @submit.prevent="submitGig" class="space-y-8">
          <!-- Gig Image Upload Section -->
          <div>
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Gig Gallery</h3>
            <div class="space-y-4">
              <!-- Main Image Upload -->
              <div class="aspect-video rounded-lg border-2 border-dashed border-gray-300 hover:border-purple-400 transition-colors bg-gray-50 flex items-center justify-center cursor-pointer">
                <div class="text-center">
                  <div class="w-12 h-12 bg-gray-200 rounded-lg flex items-center justify-center mx-auto mb-3">
                    <Plus class="h-6 w-6 text-gray-400" />
                  </div>
                  <p class="text-sm text-gray-600 mb-1">Upload main gig image</p>
                  <p class="text-xs text-gray-500">Recommended: 1280x720px</p>
                </div>
              </div>
              
              <!-- Additional Images -->
              <div class="flex space-x-2">
                <div
                  v-for="i in 4"
                  :key="i"
                  class="w-16 h-16 rounded-md border-2 border-dashed border-gray-300 hover:border-purple-400 transition-colors bg-gray-50 flex items-center justify-center cursor-pointer"
                >
                  <Plus class="h-4 w-4 text-gray-400" />
                </div>
              </div>
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
                  >
                    <option value="">Select a category</option>
                    <option value="design">Design & Creative</option>
                    <option value="development">Programming & Tech</option>
                    <option value="writing">Writing & Translation</option>
                    <option value="marketing">Digital Marketing</option>
                    <option value="business">Business & Consulting</option>
                  </select>
                </div>

                <div>
                  <label for="gig-price" class="block text-sm font-medium text-gray-700 mb-2">
                    Starting Price ($) *
                  </label>
                  <input
                    id="gig-price"
                    v-model="newGig.price"
                    type="number"
                    min="5"
                    placeholder="25"
                    class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                    required
                  />
                  <p class="text-xs text-gray-500 mt-1">Minimum $5</p>
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
                  >
                    <option value="1">1 Day</option>
                    <option value="3">3 Days</option>
                    <option value="7">1 Week</option>
                    <option value="14">2 Weeks</option>
                    <option value="30">1 Month</option>
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
                  >
                    <option value="1">1 Revision</option>
                    <option value="2">2 Revisions</option>
                    <option value="3">3 Revisions</option>
                    <option value="unlimited">Unlimited</option>
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

// Props and emits
const emit = defineEmits(['gigCreated', 'switchTab']);

// Composables
const { user } = useAuth();
const toast = useToast();

// Form state
const newGig = ref({
  title: '',
  category: '',
  price: '',
  description: '',
  deliveryTime: '7',
  revisions: '2',
  features: [
    { text: '' },
    { text: '' },
    { text: '' }
  ]
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

// Methods
const submitGig = () => {
  if (!isFormValid.value) {
    toast.add({
      title: "Form Error",
      description: "Please fill in all required fields and add at least 3 features",
      color: "red",
    });
    return;
  }

  // Filter out empty features
  const validFeatures = newGig.value.features
    .filter(f => f.text.trim())
    .map(f => f.text.trim());

  // Create gig data
  const gigData = {
    id: Date.now(), // Simple ID generation
    title: newGig.value.title,
    category: newGig.value.category,
    price: parseInt(newGig.value.price),
    description: newGig.value.description,
    deliveryTime: newGig.value.deliveryTime,
    revisions: newGig.value.revisions,
    features: validFeatures,
    image: "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=500&h=300&fit=crop",
    rating: 5.0,
    reviews: 0,
    user: {
      name: user.value?.user?.username || "You",
      avatar: user.value?.user?.avatar || "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=100&h=100&fit=crop&crop=face",
    }
  };

  // Emit the gig creation event to parent
  emit('gigCreated', gigData);
  
  // Reset form
  resetForm();

  toast.add({
    title: "Gig Created!",
    description: `"${gigData.title}" has been created successfully`,
    color: "green",
  });
};

const resetForm = () => {
  newGig.value = {
    title: '',
    category: '',
    price: '',
    description: '',
    deliveryTime: '7',
    revisions: '2',
    features: [
      { text: '' },
      { text: '' },
      { text: '' }
    ]
  };
};
</script>
