<template>
  <div class="post-sale-container">
    <!-- Success Modal -->
    <div v-if="showSuccessModal" class="fixed inset-0 flex items-center justify-center z-50 bg-black bg-opacity-50">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6 transform transition-all">
        <div class="text-center">
          <div class="mb-4 flex justify-center">
            <div class="rounded-full bg-green-100 p-3">
              <Icon name="heroicons:check-circle" class="h-10 w-10 text-green-500" />
            </div>
          </div>
          <h3 class="text-lg font-medium text-gray-900 mb-2">Post Submitted Successfully!</h3>
          <p class="text-sm text-gray-500 mb-4">
            Your listing has been submitted and is now under review. We'll notify you once it's approved.
          </p>
          <div class="flex justify-center">
            <button 
              @click="closeSuccessModal" 
              class="bg-primary text-white px-6 py-2.5 rounded-md hover:bg-primary/90 transition"
            >
              Got it
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg">
      <!-- Progress Steps Indicator -->
      <div class="px-2 sm:px-4 pt-6">
        <div class="flex justify-between mb-6">
          <div 
            v-for="(step, index) in formSteps" 
            :key="index" 
            class="flex flex-col items-center relative w-full"
          >
            <div 
              :class="[ 
                'w-8 h-8 rounded-full flex items-center justify-center z-10 relative mb-1',
                currentStep > index ? 'bg-green-500 text-white' : 
                currentStep === index ? 'bg-primary text-white' : 'bg-gray-200 text-gray-500'
              ]"
            >
              <span v-if="currentStep > index">
                <Icon name="heroicons:check" class="w-4 h-4" />
              </span>
              <span v-else>{{ index + 1 }}</span>
            </div>
            <span class="text-xs text-gray-500 text-center">{{ step }}</span>
            <!-- Connector line -->
            <div 
              v-if="index < formSteps.length - 1"
              :class="[ 
                'absolute top-4 left-1/2 h-0.5 w-full',
                currentStep > index ? 'bg-green-500' : 'bg-gray-200'
              ]"
            ></div>
          </div>
        </div>
      </div>

      <form @submit.prevent="validateStep">
        <!-- Step 1: Basic Details -->
        <div v-if="currentStep === 0" class="fade-transition px-2 pb-6">
          <h3 class="text-xl font-medium text-gray-800 mb-4">Basic Details</h3>
          
          <!-- Category Selection -->
          <div class="mb-5">
            <label for="category" class="block text-sm font-medium text-gray-700 mb-1">Category <span class="text-red-500">*</span></label>
            <div class="relative">
              <select 
                id="category" 
                v-model="formData.category" 
                class="w-full border border-gray-300 rounded-md pl-3 pr-10 py-2.5 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-700"
                required
                @change="handleCategoryChange"
              >
                <option value="" disabled>Select a category</option>
                <option v-for="category in categories" :key="category.id" :value="category.id">
                  {{ category.name }}
                </option>
              </select>
              <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                <Icon name="heroicons:chevron-down" class="h-5 w-5 text-gray-400" />
              </div>
            </div>
            <p v-if="errors.category" class="mt-1 text-red-500 text-sm">{{ errors.category }}</p>
          </div>

          <!-- Title -->
          <div class="mb-5">
            <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Title <span class="text-red-500">*</span></label>
            <div class="relative">
              <input 
                type="text" 
                id="title" 
                v-model="formData.title" 
                class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-2.5 focus:ring-primary focus:border-primary"
                placeholder="Enter a descriptive title"
                required
                maxlength="100"
              />
              <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                <Icon name="heroicons:document-text" class="h-5 w-5 text-gray-400" />
              </div>
              <div class="absolute right-3 bottom-1 text-xs text-gray-400">
                {{ formData.title.length }}/100
              </div>
            </div>
            <p v-if="errors.title" class="mt-1 text-red-500 text-sm">{{ errors.title }}</p>
          </div>

          <!-- Description -->
          <div class="mb-5">
            <label for="description" class="block text-sm font-medium text-gray-700 mb-1">Description <span class="text-red-500">*</span></label>
            <div class="relative">
              <textarea 
                id="description" 
                v-model="formData.description" 
                class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                rows="5"
                placeholder="Describe what you're selling in detail"
                required
              ></textarea>
              <div class="absolute right-3 bottom-1 text-xs text-gray-400">
                {{ formData.description.length }}/1000
              </div>
            </div>
            <p v-if="errors.description" class="mt-1 text-red-500 text-sm">{{ errors.description }}</p>
          </div>

          <!-- Condition -->
          <div class="mb-5">
            <label class="block text-sm font-medium text-gray-700 mb-1">Condition <span class="text-red-500">*</span></label>
            <div class="flex flex-wrap gap-3">
              <label 
                v-for="condition in conditions" 
                :key="condition.value" 
                :class="[ 
                  'flex items-center px-4 py-2.5 border rounded-md cursor-pointer transition-colors',
                  formData.condition === condition.value 
                    ? 'border-primary bg-primary/10 text-primary' 
                    : 'border-gray-300 hover:bg-gray-50'
                ]"
              >
                <input 
                  type="radio" 
                  :value="condition.value" 
                  v-model="formData.condition" 
                  class="hidden"
                />
                <span>{{ condition.label }}</span>
              </label>
            </div>
            <p v-if="errors.condition" class="mt-1 text-red-500 text-sm">{{ errors.condition }}</p>
          </div>
        </div>

        <!-- Step 2: Category-specific fields -->
        <div v-if="currentStep === 1" class="fade-transition px-2 sm:px-6 pb-6">
          <h3 class="text-xl font-medium text-gray-800 mb-4">
            {{ getCategoryName(formData.category) }} Details
          </h3>

          <!-- Property Fields -->
          <div v-if="formData.category === 1" class="space-y-5">
            <!-- Property Type -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Property Type <span class="text-red-500">*</span></label>
              <div class="relative">
                <select 
                  v-model="formData.propertyType" 
                  class="w-full border border-gray-300 rounded-md pl-3 pr-10 py-2.5 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-700"
                  required
                >
                  <option value="" disabled>Select property type</option>
                  <option value="apartment">Apartment</option>
                  <option value="house">House</option>
                  <option value="land">Land</option>
                  <option value="commercial">Commercial Space</option>
                  <option value="office">Office Space</option>
                </select>
                <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                  <Icon name="heroicons:chevron-down" class="h-5 w-5 text-gray-400" />
                </div>
              </div>
              <p v-if="errors.propertyType" class="mt-1 text-red-500 text-sm">{{ errors.propertyType }}</p>
            </div>

            <!-- Size and Unit -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Size <span class="text-red-500">*</span></label>
                <input 
                  type="number" 
                  v-model="formData.size" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="Size"
                  required
                  min="1"
                />
                <p v-if="errors.size" class="mt-1 text-red-500 text-sm">{{ errors.size }}</p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Unit</label>
                <select 
                  v-model="formData.unit" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  required
                >
                  <option value="sqft">Square Feet</option>
                  <option value="sqm">Square Meter</option>
                  <option value="katha">Katha</option>
                  <option value="bigha">Bigha</option>
                  <option value="acre">Acre</option>
                </select>
              </div>
            </div>

            <!-- Bedrooms & Bathrooms for apartments/houses -->
            <div v-if="['apartment', 'house'].includes(formData.propertyType)" class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Bedrooms</label>
                <select 
                  v-model="formData.bedrooms" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                >
                  <option value="">Select</option>
                  <option v-for="n in 10" :key="n" :value="n">{{ n }}</option>
                  <option value="10+">10+</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Bathrooms</label>
                <select 
                  v-model="formData.bathrooms" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                >
                  <option value="">Select</option>
                  <option v-for="n in 10" :key="n" :value="n">{{ n }}</option>
                  <option value="10+">10+</option>
                </select>
              </div>
            </div>

            <!-- Amenities -->
            <div v-if="['apartment', 'house', 'commercial', 'office'].includes(formData.propertyType)">
              <label class="block text-sm font-medium text-gray-700 mb-1">Amenities</label>
              <div class="grid grid-cols-2 gap-3">
                <label class="flex items-center gap-2">
                  <input type="checkbox" v-model="formData.amenities.parking" class="rounded text-primary focus:ring-primary h-4 w-4">
                  <span class="text-sm text-gray-700">Parking</span>
                </label>
                <label class="flex items-center gap-2">
                  <input type="checkbox" v-model="formData.amenities.elevator" class="rounded text-primary focus:ring-primary h-4 w-4">
                  <span class="text-sm text-gray-700">Elevator</span>
                </label>
                <label class="flex items-center gap-2">
                  <input type="checkbox" v-model="formData.amenities.generator" class="rounded text-primary focus:ring-primary h-4 w-4">
                  <span class="text-sm text-gray-700">Generator</span>
                </label>
                <label class="flex items-center gap-2">
                  <input type="checkbox" v-model="formData.amenities.security" class="rounded text-primary focus:ring-primary h-4 w-4">
                  <span class="text-sm text-gray-700">Security</span>
                </label>
              </div>
            </div>
          </div>

          <!-- Vehicle Fields -->
          <div v-if="formData.category === 2" class="space-y-5">
            <!-- Vehicle Type -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Vehicle Type <span class="text-red-500">*</span></label>
              <div class="relative">
                <select 
                  v-model="formData.vehicleType" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  required
                >
                  <option value="" disabled>Select vehicle type</option>
                  <option value="car">Car</option>
                  <option value="motorcycle">Motorcycle</option>
                  <option value="bicycle">Bicycle</option>
                  <option value="truck">Truck</option>
                  <option value="bus">Bus</option>
                  <option value="other">Other Vehicle</option>
                </select>
                <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                  <Icon name="heroicons:chevron-down" class="h-5 w-5 text-gray-400" />
                </div>
              </div>
              <p v-if="errors.vehicleType" class="mt-1 text-red-500 text-sm">{{ errors.vehicleType }}</p>
            </div>

            <!-- Make, Model, Year -->
            <div class="grid grid-cols-3 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Make <span class="text-red-500">*</span></label>
                <input 
                  type="text" 
                  v-model="formData.make" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="E.g. Toyota"
                  required
                />
                <p v-if="errors.make" class="mt-1 text-red-500 text-sm">{{ errors.make }}</p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Model <span class="text-red-500">*</span></label>
                <input 
                  type="text" 
                  v-model="formData.model" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="E.g. Corolla"
                  required
                />
                <p v-if="errors.model" class="mt-1 text-red-500 text-sm">{{ errors.model }}</p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Year <span class="text-red-500">*</span></label>
                <input 
                  type="number" 
                  v-model="formData.year" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="E.g. 2022"
                  min="1900" 
                  :max="new Date().getFullYear()"
                  required
                />
                <p v-if="errors.year" class="mt-1 text-red-500 text-sm">{{ errors.year }}</p>
              </div>
            </div>

            <!-- Mileage & Fuel Type -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Mileage (km)</label>
                <input 
                  type="number" 
                  v-model="formData.mileage" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="E.g. 15000"
                  min="0"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Fuel Type</label>
                <select 
                  v-model="formData.fuelType" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                >
                  <option value="">Select fuel type</option>
                  <option value="petrol">Petrol</option>
                  <option value="diesel">Diesel</option>
                  <option value="cng">CNG</option>
                  <option value="electric">Electric</option>
                  <option value="hybrid">Hybrid</option>
                  <option value="lpg">LPG</option>
                </select>
              </div>
            </div>

            <!-- Transmission & Registration -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Transmission</label>
                <select 
                  v-model="formData.transmission" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                >
                  <option value="">Select transmission</option>
                  <option value="manual">Manual</option>
                  <option value="automatic">Automatic</option>
                  <option value="semi-auto">Semi-Automatic</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Registration Year</label>
                <input 
                  type="number" 
                  v-model="formData.registrationYear" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="E.g. 2022"
                  min="1900" 
                  :max="new Date().getFullYear()"
                />
              </div>
            </div>
          </div>

          <!-- Electronics Fields -->
          <div v-if="formData.category === 3" class="space-y-5">
            <!-- Electronics Type -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Electronics Type <span class="text-red-500">*</span></label>
              <select 
                v-model="formData.electronicsType" 
                class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                required
              >
                <option value="" disabled>Select type</option>
                <option value="smartphone">Smartphone</option>
                <option value="laptop">Laptop</option>
                <option value="tablet">Tablet</option>
                <option value="desktop">Desktop Computer</option>
                <option value="camera">Camera</option>
                <option value="tv">Television</option>
                <option value="audio">Audio Equipment</option>
                <option value="gaming">Gaming Console</option>
                <option value="appliance">Home Appliance</option>
                <option value="other">Other Electronics</option>
              </select>
              <p v-if="errors.electronicsType" class="mt-1 text-red-500 text-sm">{{ errors.electronicsType }}</p>
            </div>

            <!-- Brand & Model -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Brand <span class="text-red-500">*</span></label>
                <input 
                  type="text" 
                  v-model="formData.brand" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="E.g. Samsung"
                  required
                />
                <p v-if="errors.brand" class="mt-1 text-red-500 text-sm">{{ errors.brand }}</p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Model <span class="text-red-500">*</span></label>
                <input 
                  type="text" 
                  v-model="formData.model" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="E.g. Galaxy S23"
                  required
                />
                <p v-if="errors.model" class="mt-1 text-red-500 text-sm">{{ errors.model }}</p>
              </div>
            </div>

            <!-- Age & Warranty -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Age</label>
                <div class="flex">
                  <input 
                    type="number" 
                    v-model="formData.ageValue" 
                    class="w-2/3 border border-gray-300 rounded-l-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                    placeholder="Age"
                    min="0"
                  />
                  <select 
                    v-model="formData.ageUnit" 
                    class="w-1/3 border-l-0 border border-gray-300 rounded-r-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  >
                    <option value="days">Days</option>
                    <option value="months">Months</option>
                    <option value="years">Years</option>
                  </select>
                </div>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Warranty Status</label>
                <select 
                  v-model="formData.warranty" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                >
                  <option value="">Select status</option>
                  <option value="under-warranty">Under Warranty</option>
                  <option value="expired">Warranty Expired</option>
                  <option value="no-warranty">No Warranty</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Sports & B2B & Others -->
          <div v-if="[4, 5, 6].includes(formData.category)" class="space-y-5">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Type/Brand <span class="text-red-500">*</span></label>
              <input 
                type="text" 
                v-model="formData.itemType" 
                class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                placeholder="Enter type or brand"
                required
              />
              <p v-if="errors.itemType" class="mt-1 text-red-500 text-sm">{{ errors.itemType }}</p>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Age/Quality</label>
              <input 
                type="text" 
                v-model="formData.itemQuality" 
                class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                placeholder="Describe age or quality"
              />
            </div>
          </div>
        </div>

        <!-- Step 3: Price and Location -->
        <div v-if="currentStep === 2" class="fade-transition px-2 sm:px-6 pb-6">
          <h3 class="text-xl font-medium text-gray-800 mb-4">Pricing & Location</h3>
          
          <!-- Price -->
          <div class="mb-5">
            <label class="block text-sm font-medium text-gray-700 mb-1">Price <span class="text-red-500">*</span></label>
            <div class="flex items-center">
              <div class="relative flex-grow">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <Icon name="mdi:currency-bdt" class="h-5 w-5 text-gray-400" />
                </div>
                <input 
                  type="number" 
                  v-model="formData.price" 
                  class="w-full border border-gray-300 rounded-l-md pl-10 pr-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="Enter your price"
                  min="0"
                  :disabled="formData.negotiable"
                  required
                />
              </div>
              <label class="flex items-center border border-l-0 border-gray-300 rounded-r-md px-3 py-2.5 bg-gray-50 hover:bg-gray-100 cursor-pointer">
                <input type="checkbox" v-model="formData.negotiable" class="rounded text-primary focus:ring-primary h-4 w-4 mr-2">
                <span class="text-sm">Negotiable</span>
              </label>
            </div>
            <p v-if="errors.price" class="mt-1 text-red-500 text-sm">{{ errors.price }}</p>
          </div>
          
          <!-- Location Selection -->
          <div class="mb-5">
            <label class="block text-sm font-medium text-gray-700 mb-1">Location <span class="text-red-500">*</span></label>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <select 
                  v-model="formData.division" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  required
                >
                  <option value="" disabled>Select Division</option>
                  <option v-for="division in divisions" :key="division" :value="division">{{ division }}</option>
                </select>
                <p v-if="errors.division" class="mt-1 text-red-500 text-sm">{{ errors.division }}</p>
              </div>
              
              <div>
                <select 
                  v-model="formData.district" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  required
                  :disabled="!formData.division"
                >
                  <option value="" disabled>Select District</option>
                  <option v-for="district in districtsForSelectedDivision" :key="district" :value="district">{{ district }}</option>
                </select>
                <p v-if="errors.district" class="mt-1 text-red-500 text-sm">{{ errors.district }}</p>
              </div>
              
              <div>
                <select 
                  v-model="formData.area" 
                  class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
                  required
                  :disabled="!formData.district"
                >
                  <option value="" disabled>Select Area</option>
                  <option v-for="area in areasForSelectedDistrict" :key="area" :value="area">{{ area }}</option>
                </select>
                <p v-if="errors.area" class="mt-1 text-red-500 text-sm">{{ errors.area }}</p>
              </div>
            </div>
          </div>
          
          <!-- Detailed Address -->
          <div class="mb-5">
            <label for="detailedAddress" class="block text-sm font-medium text-gray-700 mb-1">Detailed Address <span class="text-red-500">*</span></label>
            <textarea 
              id="detailedAddress" 
              v-model="formData.detailedAddress" 
              class="w-full border border-gray-300 rounded-md px-3 py-2.5 focus:ring-primary focus:border-primary"
              rows="2"
              placeholder="Provide specific location details"
              required
            ></textarea>
            <p v-if="errors.detailedAddress" class="mt-1 text-red-500 text-sm">{{ errors.detailedAddress }}</p>
          </div>
          
          <!-- Contact Info -->
          <div class="mb-5">
            <label class="block text-sm font-medium text-gray-700 mb-2">Contact Information <span class="text-red-500">*</span></label>
            
            <div class="space-y-4">
              <div class="relative">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <Icon name="heroicons:phone" class="h-5 w-5 text-gray-400" />
                </div>
                <input 
                  type="tel" 
                  v-model="formData.phone" 
                  class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="Phone Number"
                  required
                  pattern="[0-9]{11}"
                />
                <p v-if="errors.phone" class="mt-1 text-red-500 text-sm">{{ errors.phone }}</p>
              </div>
              
              <div class="relative">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <Icon name="heroicons:envelope" class="h-5 w-5 text-gray-400" />
                </div>
                <input 
                  type="email" 
                  v-model="formData.email" 
                  class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-2.5 focus:ring-primary focus:border-primary"
                  placeholder="Email (optional)"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Step 4: Images Upload -->
        <div v-if="currentStep === 3" class="fade-transition px-2 sm:px-6 pb-6">
          <h3 class="text-xl font-medium text-gray-800 mb-4">Upload Photos</h3>
          
          <p class="text-sm text-gray-500 mb-4">
            Upload clear photos to get more responses. You can upload up to 8 images.
            <span class="font-medium text-primary">First image will be the main image.</span>
          </p>
          
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div 
              v-for="n in 8" 
              :key="n" 
              class="aspect-square relative border-2 border-dashed rounded-lg group hover:border-primary transition-all"
              :class="formData.images[n - 1] ? 'border-primary bg-primary/5' : 'border-gray-300 bg-gray-50'"
              @click="openFileUpload(n - 1)"
            >
              <input 
                type="file" 
                :ref="el => { if(el) fileInputRefs[`fileInput${n-1}`] = el }"
                class="hidden" 
                accept="image/*" 
                @change="handleFileUpload($event, n - 1)"
              />
              
              <div 
                v-if="!formData.images[n - 1]" 
                class="absolute inset-0 flex flex-col items-center justify-center p-2 text-center"
              >
                <Icon name="heroicons:photo" class="text-gray-400 text-2xl mb-1 group-hover:text-primary transition-colors" />
                <div class="text-xs text-gray-500 group-hover:text-primary transition-colors">
                  {{ n === 1 ? 'Add main photo' : 'Add photo' }}
                </div>
              </div>
              
              <img 
                v-else 
                :src="imagePreviewUrls[n - 1]" 
                class="absolute inset-0 w-full h-full object-cover rounded-lg" 
                alt="Preview"
              />
              
              <button 
                v-if="formData.images[n - 1]" 
                type="button" 
                class="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-lg"
                @click.stop="removeImage(n - 1)"
              >
                <Icon name="heroicons:x-mark" size="16px" />
              </button>
              
              <div 
                v-if="n === 1" 
                class="absolute top-1 left-1 bg-primary text-white text-xs px-1.5 py-0.5 rounded">
                Main
              </div>
            </div>
          </div>
          
          <p v-if="errors.images" class="mt-3 text-red-500 text-sm">{{ errors.images }}</p>
          
          <div class="flex items-center gap-2 mt-4">
            <Icon name="heroicons:information-circle" class="text-blue-500" />
            <p class="text-xs text-gray-500">Recommended: Upload at least 3 images from different angles</p>
          </div>

          <!-- Terms and Conditions Acceptance -->
          <div class="mt-6 border-t pt-5">
            <label class="flex items-start gap-2 cursor-pointer group">
              <input 
                type="checkbox" 
                v-model="formData.termsAccepted" 
                class="rounded border-gray-300 text-primary focus:ring-primary mt-1"
                required
              />
              <div>
                <span class="text-sm text-gray-700">I agree to the</span>
                <a href="#" class="text-sm text-primary hover:underline ml-1">Terms and Conditions</a>
                <span class="text-sm text-gray-700">, </span>
                <a href="#" class="text-sm text-primary hover:underline">Privacy Policy</a>
                <span class="text-red-500 ml-0.5">*</span>
                <p class="mt-1 text-xs text-gray-500 group-hover:text-gray-700 transition-colors">
                  By posting, you confirm that this ad complies with our policies and you own or have rights to the content you're posting.
                </p>
              </div>
            </label>
            <p v-if="errors.termsAccepted" class="mt-1 text-red-500 text-sm">{{ errors.termsAccepted }}</p>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="px-6 py-4 bg-gray-50 border-t flex justify-between">
          <button 
            v-if="currentStep > 0"
            type="button" 
            class="border border-gray-300 rounded-md px-4 py-2 text-gray-700 hover:bg-gray-50"
            @click="goToPreviousStep"
          >
            Previous
          </button>
          <div v-else></div>
          
          <button 
            type="submit" 
            class="bg-primary text-white px-6 py-2 rounded-md hover:bg-primary/90"
            :disabled="isSubmitting"
          >
            <span v-if="isSubmitting">
              <Icon name="heroicons:arrow-path" class="animate-spin inline-block mr-1" />
              Processing...
            </span>
            <span v-else-if="currentStep < formSteps.length - 1">
              Next
            </span>
            <span v-else>
              Post Sale
            </span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue';

// Categories from parent component or from API
const props = defineProps({
  categories: {
    type: Array,
    default: () => [
      { id: 1, name: 'Properties' },
      { id: 2, name: 'Vehicles' },
      { id: 3, name: 'Electronics' },
      { id: 4, name: 'Sports' },
      { id: 5, name: 'B2B' },
      { id: 6, name: 'Others' }
    ]
  }
});

// Success modal state
const showSuccessModal = ref(false);

// Multi-step form
const formSteps = ['Basic Info', 'Details', 'Price & Location', 'Photos'];
const currentStep = ref(0);

const goToNextStep = () => {
  if (currentStep.value < formSteps.length - 1) {
    currentStep.value++;
  }
};

const goToPreviousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--;
  }
};

// Conditions for items
const conditions = [
  { label: 'Brand New', value: 'brand-new' },
  { label: 'Like New', value: 'like-new' },
  { label: 'Good', value: 'good' },
  { label: 'Fair', value: 'fair' },
  { label: 'For Parts', value: 'for-parts' },
];

// Location data
const divisions = [
  'Dhaka',
  'Chittagong',
  'Khulna',
  'Rajshahi',
  'Barisal',
  'Sylhet',
  'Rangpur',
  'Mymensingh'
];

const districtsByDivision = {
  'Dhaka': ['Dhaka', 'Gazipur', 'Narayanganj', 'Tangail', 'Narsingdi'],
  'Chittagong': ['Chittagong', 'Cox\'s Bazar', 'Comilla', 'Chandpur'],
  'Khulna': ['Khulna', 'Jessore', 'Kushtia', 'Bagerhat'],
  'Rajshahi': ['Rajshahi', 'Bogra', 'Pabna', 'Sirajganj'],
  'Barisal': ['Barisal', 'Bhola', 'Patuakhali'],
  'Sylhet': ['Sylhet', 'Moulvibazar', 'Habiganj'],
  'Rangpur': ['Rangpur', 'Dinajpur', 'Kurigram'],
  'Mymensingh': ['Mymensingh', 'Jamalpur', 'Netrokona']
};

const areasByDistrict = {
  'Dhaka': ['Uttara', 'Mirpur', 'Dhanmondi', 'Gulshan', 'Mohammadpur', 'Bashundhara', 'Banani', 'Motijheel', 'Khilgaon', 'Rampura'],
  'Gazipur': ['Gazipur Sadar', 'Tongi', 'Sreepur', 'Kaliganj', 'Kaliakair', 'Kapasia'],
  'Narayanganj': ['Narayanganj Sadar', 'Rupganj', 'Araihazar', 'Sonargaon', 'Bandar'],
  'Tangail': ['Tangail Sadar', 'Kalihati', 'Ghatail', 'Nagarpur', 'Mirzapur'],
  'Narsingdi': ['Narsingdi Sadar', 'Palash', 'Shibpur', 'Raipura', 'Belabo'],
  'Chittagong': ['Agrabad', 'Pahartali', 'Nasirabad', 'Halishahar', 'GEC', 'Chawkbazar', 'Patenga', 'Khulshi'],
  'Cox\'s Bazar': ['Cox\'s Bazar Sadar', 'Ukhiya', 'Teknaf', 'Moheshkhali', 'Chakaria'],
  'Comilla': ['Comilla Sadar', 'Chauddagram', 'Chandina', 'Daudkandi', 'Homna'],
  'Chandpur': ['Chandpur Sadar', 'Hajiganj', 'Shahrasti', 'Matlab', 'Faridganj'],
  'Khulna': ['Khulna Sadar', 'Sonadanga', 'Khalishpur', 'Daulatpur', 'Rupsha', 'Khan Jahan Ali'],
  'Jessore': ['Jessore Sadar', 'Manirampur', 'Jhikargacha', 'Abhaynagar', 'Keshabpur'],
  'Kushtia': ['Kushtia Sadar', 'Kumarkhali', 'Khoksa', 'Mirpur', 'Bheramara'],
  'Bagerhat': ['Bagerhat Sadar', 'Morrelganj', 'Mongla', 'Rampal', 'Fakirhat'],
  'Rajshahi': ['Rajshahi Sadar', 'Boalia', 'Motihar', 'Shah Makhdum', 'Paba'],
  'Bogra': ['Bogra Sadar', 'Shibganj', 'Shajahanpur', 'Kahaloo', 'Dupchanchia'],
  'Pabna': ['Pabna Sadar', 'Ishwardi', 'Bera', 'Atghoria', 'Chatmohar'],
  'Sirajganj': ['Sirajganj Sadar', 'Shahjadpur', 'Ullapara', 'Kamarkhand', 'Raiganj'],
  'Barisal': ['Barisal Sadar', 'Bakerganj', 'Babuganj', 'Wazirpur', 'Agailjhara'],
  'Bhola': ['Bhola Sadar', 'Charfesson', 'Daulatkhan', 'Borhanuddin', 'Lalmohan'],
  'Patuakhali': ['Patuakhali Sadar', 'Kalapara', 'Galachipa', 'Bauphal', 'Dumki'],
  'Sylhet': ['Sylhet Sadar', 'Zindabazar', 'Shahjalal Upashahar', 'Ambarkhana', 'Tilagor', 'Shibganj'],
  'Moulvibazar': ['Moulvibazar Sadar', 'Sreemangal', 'Kulaura', 'Kamalganj', 'Rajnagar'],
  'Habiganj': ['Habiganj Sadar', 'Nabiganj', 'Madhabpur', 'Chunarughat', 'Lakhai'],
  'Rangpur': ['Rangpur Sadar', 'Gangachara', 'Taraganj', 'Badarganj', 'Kaunia'],
  'Dinajpur': ['Dinajpur Sadar', 'Birampur', 'Bochaganj', 'Chirirbandar', 'Fulbari'],
  'Kurigram': ['Kurigram Sadar', 'Ulipur', 'Chilmari', 'Rowmari', 'Rajarhat'],
  'Mymensingh': ['Mymensingh Sadar', 'Bhaluka', 'Trishal', 'Muktagachha', 'Fulbaria'],
  'Jamalpur': ['Jamalpur Sadar', 'Dewanganj', 'Islampur', 'Madarganj', 'Melandaha'],
  'Netrokona': ['Netrokona Sadar', 'Atpara', 'Barhatta', 'Durgapur', 'Kendua']
};

// Computed properties for location dropdowns
const districtsForSelectedDivision = computed(() => {
  return formData.division ? districtsByDivision[formData.division] || [] : [];
});

const areasForSelectedDistrict = computed(() => {
  return formData.district ? areasByDistrict[formData.district] || [] : [];
});

// Status variables
const isSubmitting = ref(false);
const errors = reactive({});

// Form data with all fields for different categories
const formData = reactive({
  category: '',
  title: '',
  description: '',
  condition: '',
  price: '',
  negotiable: false,
  division: '',
  district: '',
  area: '',
  detailedAddress: '',
  phone: '',
  email: '',
  images: [],
  termsAccepted: false,
  
  // Property specific fields
  propertyType: '',
  size: '',
  unit: 'sqft',
  bedrooms: '',
  bathrooms: '',
  amenities: {
    parking: false,
    elevator: false,
    generator: false,
    security: false
  },
  
  // Vehicle specific fields
  vehicleType: '',
  make: '',
  model: '',
  year: '',
  mileage: '',
  fuelType: '',
  transmission: '',
  registrationYear: '',
  
  // Electronics specific fields
  electronicsType: '',
  brand: '',
  ageValue: '',
  ageUnit: 'months',
  warranty: '',
  
  // Other categories fields
  itemType: '',
  itemQuality: ''
});

// Image preview URLs for display
const imagePreviewUrls = ref([]);

// File input references - fixed implementation
const fileInputRefs = reactive({});

// Open file upload dialog
const openFileUpload = (index) => {
  if (fileInputRefs[`fileInput${index}`]) {
    fileInputRefs[`fileInput${index}`].click();
  }
};

// Handle file upload
const handleFileUpload = (event, index) => {
  const file = event.target.files[0];
  if (file) {
    // Validate file type
    if (!file.type.match('image.*')) {
      errors.images = 'Please upload only image files';
      return;
    }
    
    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      errors.images = 'Image size should be less than 5MB';
      return;
    }
    
    // Create URL for preview
    const imageUrl = URL.createObjectURL(file);
    
    // Create a new array if needed to maintain reactivity
    const newImagePreviewUrls = [...imagePreviewUrls.value];
    newImagePreviewUrls[index] = imageUrl;
    imagePreviewUrls.value = newImagePreviewUrls;
    
    // Update images array while preserving reactivity
    const newImages = [...formData.images];
    newImages[index] = file;
    formData.images = newImages;
    
    // Clear error if any
    if (errors.images) {
      errors.images = '';
    }
  }
};

// Remove image
const removeImage = (index) => {
  if (formData.images[index]) {
    // Revoke URL to prevent memory leaks
    URL.revokeObjectURL(imagePreviewUrls.value[index]);
    
    // Remove image from arrays while preserving reactivity
    const newImagePreviewUrls = [...imagePreviewUrls.value];
    newImagePreviewUrls[index] = null;
    imagePreviewUrls.value = newImagePreviewUrls;
    
    const newImages = [...formData.images];
    newImages[index] = null;
    formData.images = newImages;
    
    // Reset file input
    if (fileInputRefs[`fileInput${index}`]) {
      fileInputRefs[`fileInput${index}`].value = '';
    }
  }
};

// Get category name
const getCategoryName = (categoryId) => {
  const category = props.categories.find(c => c.id === categoryId);
  return category ? category.name : '';
};

// Reset category-specific fields when category changes
const handleCategoryChange = () => {
  // Reset property fields
  formData.propertyType = '';
  formData.size = '';
  formData.unit = 'sqft';
  formData.bedrooms = '';
  formData.bathrooms = '';
  formData.amenities = {
    parking: false,
    elevator: false,
    generator: false,
    security: false
  };
  
  // Reset vehicle fields
  formData.vehicleType = '';
  formData.make = '';
  formData.model = '';
  formData.year = '';
  formData.mileage = '';
  formData.fuelType = '';
  formData.transmission = '';
  formData.registrationYear = '';
  
  // Reset electronics fields
  formData.electronicsType = '';
  formData.brand = '';
  formData.ageValue = '';
  formData.ageUnit = 'months';
  formData.warranty = '';
  
  // Reset other categories fields
  formData.itemType = '';
  formData.itemQuality = '';
};

// Validate current step
const validateStep = () => {
  errors.category = !formData.category ? 'Please select a category' : '';
  
  if (currentStep.value === 0) {
    errors.title = !formData.title ? 'Please enter a title' : '';
    errors.description = !formData.description ? 'Please enter a description' : '';
    errors.condition = !formData.condition ? 'Please select a condition' : '';
    
    if (!errors.category && !errors.title && !errors.description && !errors.condition) {
      goToNextStep();
    }
  } 
  else if (currentStep.value === 1) {
    // Validate category-specific fields
    if (formData.category === 1) { // Properties
      errors.propertyType = !formData.propertyType ? 'Please select property type' : '';
      errors.size = !formData.size ? 'Please enter property size' : '';
      
      if (!errors.propertyType && !errors.size) {
        goToNextStep();
      }
    } 
    else if (formData.category === 2) { // Vehicles
      errors.vehicleType = !formData.vehicleType ? 'Please select vehicle type' : '';
      errors.make = !formData.make ? 'Please enter make' : '';
      errors.model = !formData.model ? 'Please enter model' : '';
      errors.year = !formData.year ? 'Please enter year' : '';
      
      if (!errors.vehicleType && !errors.make && !errors.model && !errors.year) {
        goToNextStep();
      }
    } 
    else if (formData.category === 3) { // Electronics
      errors.electronicsType = !formData.electronicsType ? 'Please select electronics type' : '';
      errors.brand = !formData.brand ? 'Please enter brand' : '';
      errors.model = !formData.model ? 'Please enter model' : '';
      
      if (!errors.electronicsType && !errors.brand && !errors.model) {
        goToNextStep();
      }
    } 
    else {
      errors.itemType = !formData.itemType ? 'Please enter type or brand' : '';
      
      if (!errors.itemType) {
        goToNextStep();
      }
    }
  } 
  else if (currentStep.value === 2) {
    if (!formData.negotiable) {
      errors.price = !formData.price ? 'Please enter a price or mark as negotiable' : '';
    }
    
    errors.division = !formData.division ? 'Please select division' : '';
    errors.district = !formData.district ? 'Please select district' : '';
    errors.area = !formData.area ? 'Please select area' : '';
    errors.detailedAddress = !formData.detailedAddress ? 'Please enter detailed address' : '';
    errors.phone = !formData.phone ? 'Please enter phone number' : '';
    
    if ((!errors.price || formData.negotiable) && !errors.division && !errors.district && 
        !errors.area && !errors.detailedAddress && !errors.phone) {
      goToNextStep();
    }
  } 
  else if (currentStep.value === 3) {
    // Check if at least one image is uploaded
    if (!formData.images.some(img => img)) {
      errors.images = 'Please upload at least one image';
      return;
    }
    
    // Validate terms acceptance
    errors.termsAccepted = !formData.termsAccepted ? 'You must accept the terms and conditions' : '';
    
    if (!errors.images && !errors.termsAccepted) {
      // Submit the form
      submitForm();
    }
  }
};

// Submit form
const submitForm = async () => {
  isSubmitting.value = true;
  
  try {
    // Prepare data for submission
    const formDataToSubmit = new FormData();
    
    // Add basic fields
    Object.keys(formData).forEach(key => {
      if (key !== 'images' && key !== 'amenities') {
        formDataToSubmit.append(key, formData[key]);
      }
    });
    
    // Add amenities as JSON
    formDataToSubmit.append('amenities', JSON.stringify(formData.amenities));
    
    // Add images
    formData.images.forEach((image, index) => {
      if (image) {
        formDataToSubmit.append(`image_${index}`, image);
      }
    });
    
    // In a real app, you would send this to your API endpoint
    console.log('Form data submitted:', formDataToSubmit);
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    // Show success modal instead of alert
    showSuccessModal.value = true;
  } catch (error) {
    console.error('Error submitting form:', error);
    alert('There was an error submitting your form. Please try again.');
  } finally {
    isSubmitting.value = false;
  }
};

// Close success modal and reset form
const closeSuccessModal = () => {
  showSuccessModal.value = false;
  resetForm();
};

// Reset form to initial state
const resetForm = () => {
  // Reset all form fields
  Object.keys(formData).forEach(key => {
    if (key === 'termsAccepted') {
      formData[key] = false;
    }
    else if (typeof formData[key] === 'object' && formData[key] !== null) {
      if (Array.isArray(formData[key])) {
        formData[key] = [];
      } else {
        Object.keys(formData[key]).forEach(subKey => {
          formData[key][subKey] = false;
        });
      }
    } else {
      formData[key] = '';
    }
  });
  
  formData.category = '';
  formData.negotiable = false;
  formData.unit = 'sqft';
  formData.ageUnit = 'months';
  
  // Clean up image previews
  imagePreviewUrls.value.forEach((url, index) => {
    if (url) {
      URL.revokeObjectURL(url);
    }
  });
  imagePreviewUrls.value = [];
  
  // Reset file inputs
  Object.keys(fileInputRefs).forEach(key => {
    if (fileInputRefs[key]) {
      fileInputRefs[key].value = '';
    }
  });
  
  // Reset errors
  Object.keys(errors).forEach(key => {
    errors[key] = '';
  });
  
  // Go back to first step
  currentStep.value = 0;
};
</script>

<style scoped>
.fade-transition {
  transition: all 0.3s ease;
}

/* Fix for number input spinner buttons */
input[type=number]::-webkit-inner-spin-button, 
input[type=number]::-webkit-outer-spin-button { 
  -webkit-appearance: none; 
  margin: 0; 
}
input[type=number] {
  -moz-appearance: textfield;
}
</style>