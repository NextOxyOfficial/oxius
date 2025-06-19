<template>
  <div class="camera-component">
    <div class="mb-4">
      <button 
        @click="takePhoto" 
        :disabled="isLoading"
        class="bg-blue-500 hover:bg-blue-700 disabled:bg-gray-400 text-white font-bold py-2 px-4 rounded mr-2"
      >
        {{ isLoading ? 'Taking Photo...' : 'Take Photo' }}
      </button>
      <button 
        @click="selectImage" 
        :disabled="isLoading"
        class="bg-green-500 hover:bg-green-700 disabled:bg-gray-400 text-white font-bold py-2 px-4 rounded"
      >
        {{ isLoading ? 'Selecting...' : 'Select from Gallery' }}
      </button>
    </div>
    
    <div v-if="capturedImage" class="mt-4">
      <img 
        :src="capturedImage" 
        alt="Captured image" 
        class="max-w-full h-auto rounded-lg shadow-lg"
      />
      <button 
        @click="clearImage" 
        class="mt-2 bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-3 rounded text-sm"
      >
        Clear Image
      </button>
    </div>
    
    <div v-if="error" class="mt-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded">
      {{ error }}
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const capturedImage = ref(null)
const { isLoading, error, checkPermissions, requestPermissions, takePhotoFromCamera, selectFromGallery } = useCamera()

const takePhoto = async () => {
  try {
    const image = await takePhotoFromCamera()
    capturedImage.value = image.dataUrl
  } catch (err) {
    console.error('Failed to take photo:', err)
  }
}

const selectImage = async () => {
  try {
    const image = await selectFromGallery()
    capturedImage.value = image.dataUrl
  } catch (err) {
    console.error('Failed to select image:', err)
  }
}

const clearImage = () => {
  capturedImage.value = null
}

// Check permissions on component mount
onMounted(async () => {
  try {
    const permissions = await checkPermissions()
    
    if (permissions.camera !== 'granted' || permissions.photos !== 'granted') {
      await requestPermissions()
    }
  } catch (err) {
    console.error('Permission error:', err)
  }
})
</script>

<style scoped>
.camera-component {
  padding: 1rem;
}
</style>
