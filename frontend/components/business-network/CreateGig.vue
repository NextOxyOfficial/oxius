<template>
  <div class="space-y-6">
    <div class="max-w-2xl mx-auto">
      <div class="bg-gray-50 rounded-lg p-8 text-center">
        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <Plus class="h-8 w-8 text-green-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Create Your Gig</h3>
        <p class="text-gray-600 mb-6">
          Start earning by offering your services to our community of professionals.
        </p>
        
        <form class="space-y-4 text-left">
          <div>
            <label for="gig-title" class="block text-sm font-medium text-gray-700 mb-1">
              Gig Title
            </label>
            <input
              id="gig-title"
              v-model="newGig.title"
              type="text"
              placeholder="I will design a professional logo for your business"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500"
            />
          </div>
          
          <div>
            <label for="gig-category" class="block text-sm font-medium text-gray-700 mb-1">
              Category
            </label>
            <select
              id="gig-category"
              v-model="newGig.category"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500"
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
            <label for="gig-price" class="block text-sm font-medium text-gray-700 mb-1">
              Starting Price ($)
            </label>
            <input
              id="gig-price"
              v-model="newGig.price"
              type="number"
              min="5"
              placeholder="25"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500"
            />
          </div>
          
          <div>
            <label for="gig-description" class="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              id="gig-description"
              v-model="newGig.description"
              rows="4"
              placeholder="Describe your service in detail..."
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500"
            ></textarea>
          </div>
          
          <div class="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              @click="resetForm"
              class="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="button"
              @click="submitGig"
              :disabled="!isFormValid"
              :class="[
                'px-4 py-2 rounded-md transition-colors',
                isFormValid
                  ? 'bg-green-600 text-white hover:bg-green-700'
                  : 'bg-gray-300 text-gray-500 cursor-not-allowed'
              ]"
            >
              Create Gig
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
defineEmits(['gigCreated', 'switchTab']);

// Composables
const { user } = useAuth();
const toast = useToast();

// Form state
const newGig = ref({
  title: '',
  category: '',
  price: '',
  description: ''
});

// Computed
const isFormValid = computed(() => {
  return newGig.value.title && 
         newGig.value.category && 
         newGig.value.price && 
         newGig.value.description;
});

// Methods
const submitGig = () => {
  if (!isFormValid.value) {
    toast.add({
      title: "Form Error",
      description: "Please fill in all required fields",
      color: "red",
    });
    return;
  }

  // Create gig data
  const gigData = {
    title: newGig.value.title,
    category: newGig.value.category,
    price: parseInt(newGig.value.price),
    description: newGig.value.description,
    user: {
      name: user.value?.user?.username || "You",
      avatar: user.value?.user?.avatar || "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=100&h=100&fit=crop&crop=face",
    }
  };

  // Emit the gig creation event to parent
  $emit('gigCreated', gigData);
  
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
    description: ''
  };
};
</script>
