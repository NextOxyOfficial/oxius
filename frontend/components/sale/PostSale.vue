<template>
  <div class="post-sale-container max-w-4xl mx-auto">
    <!-- Success Modal -->
    <div
      v-if="showSuccessModal"
      class="fixed inset-0 flex items-center justify-center z-50 bg-black/60"
    >
      <div
        class="bg-white rounded-lg shadow-xl max-w-md w-full p-8 transform transition-all"
      >
        <div class="text-center">
          <div class="mb-5 flex justify-center">
            <div class="rounded-full bg-yellow-100 p-4">
              <Icon name="heroicons:clock" class="h-12 w-12 text-yellow-500" />
            </div>
          </div>
          <h3 class="text-xl font-semibold text-gray-900 mb-3">
            Post Submitted Successfully!
          </h3>
          <p class="text-gray-600 mb-5">
            Your listing has been submitted and is now
            <span
              class="font-medium text-yellow-600 bg-yellow-50 px-2 py-0.5 rounded"
              >under review</span
            >. We'll notify you once it's approved.
          </p>
          <div class="flex justify-center">
            <button
              @click="closeSuccessModal"
              class="bg-primary text-white px-8 py-3 rounded-md hover:bg-primary/90 transition font-medium"
            >
              Got it
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-100">
      <!-- Progress Steps Indicator -->
      <div class="px-6 sm:px-8 pt-8">
        <div class="flex justify-between mb-8">
          <div
            v-for="(step, index) in formSteps"
            :key="index"
            class="flex flex-col items-center relative w-full"
          >
            <div
              :class="[
                'w-10 h-10 rounded-full flex items-center justify-center z-10 relative mb-2 shadow-sm',
                currentStep > index
                  ? 'bg-green-500 text-white'
                  : currentStep === index
                  ? 'bg-primary text-white'
                  : 'bg-gray-100 text-gray-500',
              ]"
            >
              <span v-if="currentStep > index">
                <Icon name="heroicons:check" class="w-5 h-5" />
              </span>
              <span v-else class="font-medium">{{ index + 1 }}</span>
            </div>
            <span
              class="text-sm font-medium text-center"
              :class="currentStep >= index ? 'text-gray-700' : 'text-gray-400'"
              >{{ step }}</span
            >
            <!-- Connector line -->
            <div
              v-if="index < formSteps.length - 1"
              :class="[
                'absolute top-5 left-1/2 h-0.5 w-full',
                currentStep > index ? 'bg-green-500' : 'bg-gray-200',
              ]"
            ></div>
          </div>
        </div>
      </div>

      <form @submit.prevent="validateStep">
        <!-- Step 1: Basic Details -->
        <div v-if="currentStep === 0" class="fade-transition px-6 sm:px-8 pb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-6">
            Basic Details
          </h3>

          <!-- Category Selection -->
          <div class="mb-6">
            <label
              for="category"
              class="block text-sm font-medium text-gray-700 mb-2"
              >Category <span class="text-red-500">*</span></label
            >
            <div class="relative">
              <select
                id="category"
                v-model="formData.category"
                class="w-full border border-gray-300 rounded-md pl-4 pr-10 py-3 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-700 shadow-sm"
                required
                @change="handleCategoryChange"
              >
                <option value="" disabled>Select a category</option>
                <option
                  v-for="category in categories"
                  :key="category.id"
                  :value="category.id"
                >
                  {{ category.name }}
                </option>
              </select>
              <div
                class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none"
              >
                <Icon
                  name="heroicons:chevron-down"
                  class="h-5 w-5 text-gray-400"
                />
              </div>
            </div>
            <p v-if="errors.category" class="mt-2 text-red-500 text-sm">
              {{ errors.category }}
            </p>
          </div>

          <!-- Title -->
          <div class="mb-6">
            <label
              for="title"
              class="block text-sm font-medium text-gray-700 mb-2"
              >Title <span class="text-red-500">*</span></label
            >
            <div class="relative">
              <input
                type="text"
                id="title"
                v-model="formData.title"
                class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-3 focus:ring-primary focus:border-primary shadow-sm"
                placeholder="Enter a descriptive title"
                required
                maxlength="100"
              />
              <div
                class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
              >
                <Icon
                  name="heroicons:document-text"
                  class="h-5 w-5 text-gray-400"
                />
              </div>
              <div class="absolute right-3 bottom-3 text-xs text-gray-400">
                {{ formData.title.length }}/100
              </div>
            </div>
            <p v-if="errors.title" class="mt-2 text-red-500 text-sm">
              {{ errors.title }}
            </p>
          </div>

          <!-- Description -->
          <div class="mb-6">
            <label
              for="description"
              class="block text-sm font-medium text-gray-700 mb-2"
              >Description <span class="text-red-500">*</span></label
            >
            <div class="relative">
              <textarea
                id="description"
                v-model="formData.description"
                class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                rows="5"
                placeholder="Describe what you're selling in detail"
                required
              ></textarea>
              <div class="absolute right-3 bottom-3 text-xs text-gray-400">
                {{ formData.description.length }}/1000
              </div>
            </div>
            <p v-if="errors.description" class="mt-2 text-red-500 text-sm">
              {{ errors.description }}
            </p>
          </div>

          <!-- Condition -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-2"
              >Condition <span class="text-red-500">*</span></label
            >
            <div class="flex flex-wrap gap-3">
              <label
                v-for="condition in conditions"
                :key="condition.value"
                :class="[
                  'flex items-center px-5 py-3 border rounded-md cursor-pointer transition-colors',
                  formData.condition === condition.value
                    ? 'border-primary bg-primary/10 text-primary font-medium shadow-sm'
                    : 'border-gray-300 hover:bg-gray-50',
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
            <p v-if="errors.condition" class="mt-2 text-red-500 text-sm">
              {{ errors.condition }}
            </p>
          </div>
        </div>

        <!-- Step 2: Category-specific fields -->
        <div v-if="currentStep === 1" class="fade-transition px-6 sm:px-8 pb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-6">
            {{ getCategoryName(formData.category) }} Details
          </h3>

          <!-- Property Fields -->
          <div
            v-if="
              getCategoryName(formData.category)?.toLowerCase() === 'properties'
            "
            class="space-y-6"
          >
            <!-- Property Type -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2"
                >Property Type <span class="text-red-500">*</span></label
              >
              <div class="relative">
                <select
                  v-model="formData.propertyType"
                  class="w-full border border-gray-300 rounded-md pl-4 pr-10 py-3 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-700 shadow-sm"
                  required
                >
                  <option value="" disabled>Select property type</option>
                  <option value="apartment">Apartment</option>
                  <option value="house">House</option>
                  <option value="land">Land</option>
                  <option value="commercial">Commercial Space</option>
                  <option value="office">Office Space</option>
                </select>
                <div
                  class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none"
                >
                  <Icon
                    name="heroicons:chevron-down"
                    class="h-5 w-5 text-gray-400"
                  />
                </div>
              </div>
              <p v-if="errors.propertyType" class="mt-2 text-red-500 text-sm">
                {{ errors.propertyType }}
              </p>
            </div>

            <!-- Size and Unit -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Size <span class="text-red-500">*</span></label
                >
                <input
                  type="number"
                  v-model="formData.size"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="Size"
                  required
                  min="1"
                />
                <p v-if="errors.size" class="mt-2 text-red-500 text-sm">
                  {{ errors.size }}
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Unit</label
                >
                <select
                  v-model="formData.unit"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
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
            <div
              v-if="['apartment', 'house'].includes(formData.propertyType)"
              class="grid grid-cols-2 gap-4"
            >
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Bedrooms</label
                >
                <select
                  v-model="formData.bedrooms"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                >
                  <option value="">Select</option>
                  <option v-for="n in 10" :key="n" :value="n">{{ n }}</option>
                  <option value="10+">10+</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Bathrooms</label
                >
                <select
                  v-model="formData.bathrooms"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                >
                  <option value="">Select</option>
                  <option v-for="n in 10" :key="n" :value="n">{{ n }}</option>
                  <option value="10+">10+</option>
                </select>
              </div>
            </div>

            <!-- Amenities -->
            <div
              v-if="
                ['apartment', 'house', 'commercial', 'office'].includes(
                  formData.propertyType
                )
              "
            >
              <label class="block text-sm font-medium text-gray-700 mb-3"
                >Amenities</label
              >
              <div class="grid grid-cols-2 gap-4">
                <label
                  class="flex items-center gap-2 p-3 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
                >
                  <input
                    type="checkbox"
                    v-model="formData.amenities.parking"
                    class="rounded text-primary focus:ring-primary h-4 w-4"
                  />
                  <span class="text-sm text-gray-700">Parking</span>
                </label>
                <label
                  class="flex items-center gap-2 p-3 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
                >
                  <input
                    type="checkbox"
                    v-model="formData.amenities.elevator"
                    class="rounded text-primary focus:ring-primary h-4 w-4"
                  />
                  <span class="text-sm text-gray-700">Elevator</span>
                </label>
                <label
                  class="flex items-center gap-2 p-3 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
                >
                  <input
                    type="checkbox"
                    v-model="formData.amenities.generator"
                    class="rounded text-primary focus:ring-primary h-4 w-4"
                  />
                  <span class="text-sm text-gray-700">Generator</span>
                </label>
                <label
                  class="flex items-center gap-2 p-3 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
                >
                  <input
                    type="checkbox"
                    v-model="formData.amenities.security"
                    class="rounded text-primary focus:ring-primary h-4 w-4"
                  />
                  <span class="text-sm text-gray-700">Security</span>
                </label>
              </div>
            </div>
          </div>

          <!-- Vehicle Fields -->
          <div
            v-if="
              getCategoryName(formData.category)?.toLowerCase() === 'vehicles'
            "
            class="space-y-6"
          >
            <!-- Vehicle Type -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2"
                >Vehicle Type <span class="text-red-500">*</span></label
              >
              <div class="relative">
                <select
                  v-model="formData.vehicleType"
                  class="w-full border border-gray-300 rounded-md pl-4 pr-10 py-3 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-700 shadow-sm"
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
                <div
                  class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none"
                >
                  <Icon
                    name="heroicons:chevron-down"
                    class="h-5 w-5 text-gray-400"
                  />
                </div>
              </div>
              <p v-if="errors.vehicleType" class="mt-2 text-red-500 text-sm">
                {{ errors.vehicleType }}
              </p>
            </div>

            <!-- Make, Model, Year -->
            <div class="grid grid-cols-3 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Make <span class="text-red-500">*</span></label
                >
                <input
                  type="text"
                  v-model="formData.make"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="E.g. Toyota"
                  required
                />
                <p v-if="errors.make" class="mt-2 text-red-500 text-sm">
                  {{ errors.make }}
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Model <span class="text-red-500">*</span></label
                >
                <input
                  type="text"
                  v-model="formData.model"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="E.g. Corolla"
                  required
                />
                <p v-if="errors.model" class="mt-2 text-red-500 text-sm">
                  {{ errors.model }}
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Year <span class="text-red-500">*</span></label
                >
                <input
                  type="number"
                  v-model="formData.year"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="E.g. 2022"
                  min="1900"
                  :max="new Date().getFullYear()"
                  required
                />
                <p v-if="errors.year" class="mt-2 text-red-500 text-sm">
                  {{ errors.year }}
                </p>
              </div>
            </div>

            <!-- Mileage & Fuel Type -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Mileage (km)</label
                >
                <input
                  type="number"
                  v-model="formData.mileage"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="E.g. 15000"
                  min="0"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Fuel Type</label
                >
                <select
                  v-model="formData.fuelType"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
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
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Transmission</label
                >
                <select
                  v-model="formData.transmission"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                >
                  <option value="">Select transmission</option>
                  <option value="manual">Manual</option>
                  <option value="automatic">Automatic</option>
                  <option value="semi-auto">Semi-Automatic</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Registration Year</label
                >
                <input
                  type="number"
                  v-model="formData.registrationYear"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="E.g. 2022"
                  min="1900"
                  :max="new Date().getFullYear()"
                />
              </div>
            </div>
          </div>

          <!-- Electronics Fields -->
          <div
            v-if="
              getCategoryName(formData.category)?.toLowerCase() ===
              'electronics'
            "
            class="space-y-6"
          >
            <!-- Electronics Type -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2"
                >Electronics Type <span class="text-red-500">*</span></label
              >
              <div class="relative">
                <select
                  v-model="formData.electronicsType"
                  class="w-full border border-gray-300 rounded-md pl-4 pr-10 py-3 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-700 shadow-sm"
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
                <div
                  class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none"
                >
                  <Icon
                    name="heroicons:chevron-down"
                    class="h-5 w-5 text-gray-400"
                  />
                </div>
              </div>
              <p
                v-if="errors.electronicsType"
                class="mt-2 text-red-500 text-sm"
              >
                {{ errors.electronicsType }}
              </p>
            </div>

            <!-- Brand & Model -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Brand <span class="text-red-500">*</span></label
                >
                <input
                  type="text"
                  v-model="formData.brand"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="E.g. Samsung"
                  required
                />
                <p v-if="errors.brand" class="mt-2 text-red-500 text-sm">
                  {{ errors.brand }}
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Model <span class="text-red-500">*</span></label
                >
                <input
                  type="text"
                  v-model="formData.model"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="E.g. Galaxy S23"
                  required
                />
                <p v-if="errors.model" class="mt-2 text-red-500 text-sm">
                  {{ errors.model }}
                </p>
              </div>
            </div>

            <!-- Age & Warranty -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Age</label
                >
                <div class="flex shadow-sm">
                  <input
                    type="number"
                    v-model="formData.ageValue"
                    class="w-2/3 border border-gray-300 rounded-l-md px-4 py-3 focus:ring-primary focus:border-primary"
                    placeholder="Age"
                    min="0"
                  />
                  <select
                    v-model="formData.ageUnit"
                    class="w-1/3 border-l-0 border border-gray-300 rounded-r-md px-2 py-3 focus:ring-primary focus:border-primary"
                  >
                    <option value="days">Days</option>
                    <option value="months">Months</option>
                    <option value="years">Years</option>
                  </select>
                </div>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2"
                  >Warranty Status</label
                >
                <select
                  v-model="formData.warranty"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
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
          <div
            v-if="
              ['sports', 'b2b', 'others'].includes(
                getCategoryName(formData.category)?.toLowerCase()
              )
            "
            class="space-y-6"
          >
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2"
                >Type/Brand <span class="text-red-500">*</span></label
              >
              <input
                type="text"
                v-model="formData.itemType"
                class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                placeholder="Enter type or brand"
                required
              />
              <p v-if="errors.itemType" class="mt-2 text-red-500 text-sm">
                {{ errors.itemType }}
              </p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2"
                >Age/Quality</label
              >
              <input
                type="text"
                v-model="formData.itemQuality"
                class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                placeholder="Describe age or quality"
              />
            </div>
          </div>
        </div>

        <!-- Step 3: Price and Location -->
        <div v-if="currentStep === 2" class="fade-transition px-6 sm:px-8 pb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-6">
            Pricing & Location
          </h3>

          <!-- Price -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-2"
              >Price <span class="text-red-500">*</span></label
            >
            <div class="flex items-center">
              <div class="relative flex-grow">
                <div
                  class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
                >
                  <Icon name="mdi:currency-bdt" class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="number"
                  v-model="formData.price"
                  class="w-full border border-gray-300 rounded-l-md pl-10 pr-3 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="Enter your price"
                  min="0"
                  :disabled="formData.negotiable"
                  required
                />
              </div>
              <label
                class="flex items-center border border-l-0 border-gray-300 rounded-r-md px-4 py-3 bg-gray-50 hover:bg-gray-100 cursor-pointer"
              >
                <input
                  type="checkbox"
                  v-model="formData.negotiable"
                  class="rounded text-primary focus:ring-primary h-4 w-4 mr-2"
                />
                <span class="text-sm font-medium">Negotiable</span>
              </label>
            </div>
            <p v-if="errors.price" class="mt-2 text-red-500 text-sm">
              {{ errors.price }}
            </p>
          </div>

          <!-- Location Selection -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-2"
              >Location <span class="text-red-500">*</span></label
            >
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <select
                  v-model="formData.division"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  required
                >
                  <option value="" disabled>Select Division</option>
                  <option
                    v-for="division in regions"
                    :key="division.id"
                    :value="division.name_eng"
                  >
                    {{ division.name_eng }}
                  </option>
                </select>
                <p v-if="errors.division" class="mt-2 text-red-500 text-sm">
                  {{ errors.division }}
                </p>
              </div>

              <div>
                <select
                  v-model="formData.district"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  required
                  :disabled="!formData.division"
                >
                  <option value="" disabled>Select District</option>
                  <option
                    v-for="district in cities"
                    :key="district.id"
                    :value="district.name_eng"
                  >
                    {{ district.name_eng }}
                  </option>
                </select>
                <p v-if="errors.district" class="mt-2 text-red-500 text-sm">
                  {{ errors.district }}
                </p>
              </div>

              <div>
                <select
                  v-model="formData.area"
                  class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  required
                  :disabled="!formData.district"
                >
                  <option value="" disabled>Select Area</option>
                  <option
                    v-for="area in upazilas"
                    :key="area.id"
                    :value="area.name_eng"
                  >
                    {{ area.name_eng }}
                  </option>
                </select>
                <p v-if="errors.area" class="mt-2 text-red-500 text-sm">
                  {{ errors.area }}
                </p>
              </div>
            </div>
          </div>

          <!-- Detailed Address -->
          <div class="mb-6">
            <label
              for="detailedAddress"
              class="block text-sm font-medium text-gray-700 mb-2"
              >Detailed Address <span class="text-red-500">*</span></label
            >
            <textarea
              id="detailedAddress"
              v-model="formData.detailedAddress"
              class="w-full border border-gray-300 rounded-md px-4 py-3 focus:ring-primary focus:border-primary shadow-sm"
              rows="3"
              placeholder="Provide specific location details"
              required
            ></textarea>
            <p v-if="errors.detailedAddress" class="mt-2 text-red-500 text-sm">
              {{ errors.detailedAddress }}
            </p>
          </div>

          <!-- Contact Info -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-3"
              >Contact Information <span class="text-red-500">*</span></label
            >

            <div class="space-y-4">
              <div class="relative">
                <div
                  class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
                >
                  <Icon name="heroicons:phone" class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="tel"
                  v-model="formData.phone"
                  class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="Phone Number"
                  required
                  pattern="[0-9]{11}"
                />
                <p v-if="errors.phone" class="mt-2 text-red-500 text-sm">
                  {{ errors.phone }}
                </p>
              </div>

              <div class="relative">
                <div
                  class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
                >
                  <Icon
                    name="heroicons:envelope"
                    class="h-5 w-5 text-gray-400"
                  />
                </div>
                <input
                  type="email"
                  v-model="formData.email"
                  class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-3 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="Email (optional)"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Step 4: Images Upload -->
        <div v-if="currentStep === 3" class="fade-transition px-6 sm:px-8 pb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-6">
            Upload Photos
          </h3>

          <p class="text-sm text-gray-600 mb-6">
            Upload clear photos to get more responses. You can upload up to 8
            images.
            <span class="font-medium text-primary"
              >First image will be the main image.</span
            >
          </p>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-5 mb-6">
            <div
              v-for="n in 8"
              :key="n"
              class="aspect-square relative border-2 border-dashed rounded-lg group transition-all shadow-sm hover:shadow"
              :class="
                formData.images[n - 1]
                  ? 'border-primary bg-primary/5'
                  : 'border-gray-300 bg-gray-50'
              "
              @click="openFileUpload(n - 1)"
            >
              <input
                type="file"
                :ref="
                  (el) => {
                    if (el) fileInputRefs[`fileInput${n - 1}`] = el;
                  }
                "
                class="hidden"
                accept="image/*"
                @change="handleFileUpload($event, n - 1)"
              />

              <div
                v-if="!formData.images[n - 1]"
                class="absolute inset-0 flex flex-col items-center justify-center p-3 text-center"
              >
                <Icon
                  name="heroicons:photo"
                  class="text-gray-400 text-3xl mb-2 group-hover:text-primary transition-colors"
                />
                <div
                  class="text-sm text-gray-500 group-hover:text-primary transition-colors"
                >
                  {{ n === 1 ? "Add main photo" : "Add photo" }}
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
                class="absolute top-2 right-2 bg-red-500 text-white rounded-full w-7 h-7 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-lg"
                @click.stop="removeImage(n - 1)"
              >
                <Icon name="heroicons:x-mark" size="18px" />
              </button>

              <div
                v-if="n === 1"
                class="absolute top-2 left-2 bg-primary text-white text-xs px-2.5 py-1 rounded font-medium shadow-sm"
              >
                Main
              </div>
            </div>
          </div>

          <p v-if="errors.images" class="mt-2 text-red-500 text-sm">
            {{ errors.images }}
          </p>

          <div
            class="flex items-center gap-2 mt-4 bg-blue-50 p-3 rounded-lg border border-blue-100"
          >
            <Icon
              name="heroicons:information-circle"
              class="text-blue-500 h-5 w-5 flex-shrink-0"
            />
            <p class="text-sm text-blue-700">
              Recommended: Upload at least 3 high-quality images from different
              angles for better responses
            </p>
          </div>

          <!-- Terms and Conditions Acceptance -->
          <div class="mt-8 border-t border-gray-200 pt-6">
            <label class="flex items-start gap-3 cursor-pointer group">
              <input
                type="checkbox"
                v-model="formData.termsAccepted"
                class="rounded border-gray-300 text-primary focus:ring-primary mt-1 h-5 w-5"
                required
              />
              <div>
                <span class="text-sm text-gray-700">I agree to the</span>
                <a
                  href="#"
                  class="text-sm text-primary hover:underline ml-1 font-medium"
                  >Terms and Conditions</a
                >
                <span class="text-sm text-gray-700">,</span>
                <a
                  href="#"
                  class="text-sm text-primary hover:underline ml-1 font-medium"
                  >Privacy Policy</a
                >
                <span class="text-red-500 ml-0.5">*</span>
                <p
                  class="mt-1.5 text-sm text-gray-500 group-hover:text-gray-700 transition-colors"
                >
                  By posting, you confirm that this ad complies with our
                  policies and you own or have rights to the content you're
                  posting.
                </p>
              </div>
            </label>
            <p v-if="errors.termsAccepted" class="mt-2 text-red-500 text-sm">
              {{ errors.termsAccepted }}
            </p>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="px-8 py-5 bg-gray-50 border-t flex justify-between">
          <button
            v-if="currentStep > 0"
            type="button"
            class="px-6 py-2.5 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-100 transition font-medium"
            @click="goToPreviousStep"
          >
            <Icon
              name="heroicons:arrow-left"
              class="w-5 h-5 mr-1.5 inline-block"
            />
            Previous
          </button>
          <div v-else></div>

          <button
            type="submit"
            class="bg-primary text-white px-8 py-2.5 rounded-md hover:bg-primary/90 transition font-medium shadow-sm"
            :disabled="isSubmitting"
          >
            <span v-if="isSubmitting" class="flex items-center">
              <Icon
                name="heroicons:arrow-path"
                class="animate-spin w-5 h-5 mr-1.5"
              />
              Processing...
            </span>
            <span
              v-else-if="currentStep < formSteps.length - 1"
              class="flex items-center"
            >
              Next
              <Icon name="heroicons:arrow-right" class="w-5 h-5 ml-1.5" />
            </span>
            <span v-else class="flex items-center">
              Post Sale
              <Icon name="heroicons:paper-airplane" class="w-5 h-5 ml-1.5" />
            </span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from "vue";
import { useSalePost } from "~/composables/useSalePost";
import { useNotifications } from "~/composables/useNotifications";
const { get } = useApi();

// Initialize composables
const {
  createSalePost,
  updateSalePost,
  loading: apiLoading,
  error: apiError,
} = useSalePost();

// Props definition
const props = defineProps({
  categories: {
    type: Array,
  },
  editPost: {
    type: Object,
    default: null,
  },
});
// Form data with all fields for different categories
const formData = reactive({
  category: "",
  title: "",
  description: "",
  condition: "",
  price: "",
  negotiable: false,
  division: "",
  district: "",
  area: "",
  detailedAddress: "",
  phone: "",
  email: "",
  images: [],
  termsAccepted: false,

  // Property specific fields
  propertyType: "",
  size: "",
  unit: "sqft",
  bedrooms: "",
  bathrooms: "",
  amenities: {
    parking: false,
    elevator: false,
    generator: false,
    security: false,
  },

  // Vehicle specific fields
  vehicleType: "",
  make: "",
  model: "",
  year: "",
  mileage: "",
  fuelType: "",
  transmission: "",
  registrationYear: "",

  // Electronics specific fields
  electronicsType: "",
  brand: "",
  ageValue: "",
  ageUnit: "months",
  warranty: "",

  // Other categories fields
  itemType: "",
  itemQuality: "",
});

// Emit events
const emit = defineEmits(["post-saved"]);

// Success modal state
const showSuccessModal = ref(false);

// Multi-step form
const formSteps = ["Basic Info", "Details", "Price & Location", "Photos"];
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
  { label: "Brand New", value: "brand-new" },
  { label: "Like New", value: "like-new" },
  { label: "Good", value: "good" },
  { label: "Fair", value: "fair" },
  { label: "For Parts", value: "for-parts" },
];

// Location data
// geo filter

const regions = ref([]);
const cities = ref();
const upazilas = ref();

const regions_response = await get(`/geo/regions/?country_name_eng=Bangladesh`);
regions.value = regions_response.data;

if (formData.division) {
  const cities_response = await get(
    `/geo/cities/?region_name_eng=${formData.division}`
  );
  cities.value = cities_response.data;
  console.log(cities_response.data);
}
if (formData.district) {
  const thana_response = await get(
    `/geo/upazila/?city_name_eng=${formData.district}`
  );
  upazilas.value = thana_response.data;
  console.log(thana_response.data);
}

watch(
  () => formData.division,
  async (newState) => {
    console.log(newState);
    if (newState) {
      const cities_response = await get(
        `/geo/cities/?region_name_eng=${newState}`
      );
      cities.value = cities_response.data;
      console.log(cities_response.data);
    }
  }
);

watch(
  () => formData.district,
  async (newCity) => {
    console.log(newCity);
    if (newCity) {
      const thana_response = await get(
        `/geo/upazila/?city_name_eng=${newCity}`
      );
      upazilas.value = thana_response.data;
      console.log(thana_response.data);
    }
  }
);

// geo filter

// Status variables
const isSubmitting = computed(() => apiLoading.value);
const errors = reactive({});

// Watch for API errors and update local error state
watch(
  () => apiError.value,
  (newError) => {
    if (newError) {
      // Process validation errors from the API
      if (typeof newError === "object") {
        Object.keys(newError).forEach((key) => {
          errors[key] = Array.isArray(newError[key])
            ? newError[key][0]
            : newError[key];
        });
      } else {
        // Handle general error messages
        console.log("Sometthing went wrong");
      }
    }
  }
);

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
function handleFileUpload(event, index) {
  const file = event.target.files[0];
  if (!file) return;

  // Validate file type
  if (!file.type.match("image.*")) {
    errors.images = "Please upload only image files";
    return;
  }

  // Validate file size (max 5MB)
  if (file.size > 5 * 1024 * 1024) {
    errors.images = "Image size should be less than 5MB";
    return;
  }

  const reader = new FileReader();

  reader.onload = () => {
    // Update preview URL
    const newImagePreviewUrls = [...imagePreviewUrls.value];
    newImagePreviewUrls[index] = reader.result;
    imagePreviewUrls.value = newImagePreviewUrls;

    // Update formData.images (reactive object)
    formData.images[index] = file;

    // Clear errors if any
    errors.images = "";
  };

  reader.onerror = (error) => {
    errors.images = "Failed to read image file.";
    console.error("FileReader error:", error);
  };

  reader.readAsDataURL(file);
}

// Remove image
function removeImage(index) {
  if (formData.images[index]) {
    // Clear preview and revoke object URL if applicable
    const previewUrl = imagePreviewUrls.value[index];
    if (previewUrl?.startsWith("blob:")) {
      URL.revokeObjectURL(previewUrl);
    }

    const newImagePreviewUrls = [...imagePreviewUrls.value];
    newImagePreviewUrls[index] = null;
    imagePreviewUrls.value = newImagePreviewUrls;

    // Remove image file from reactive formData
    formData.images[index] = null;

    // Clear the file input value
    if (fileInputRefs[`fileInput${index}`]) {
      fileInputRefs[`fileInput${index}`].value = "";
    }

    // Clear any error
    errors.images = "";
  }
}

// Get category name
const getCategoryName = (categoryId) => {
  const category = props.categories.find((c) => c.id === categoryId);
  return category ? category.name : "";
};

// Reset category-specific fields when category changes
const handleCategoryChange = () => {
  // Reset property fields
  formData.propertyType = "";
  formData.size = "";
  formData.unit = "sqft";
  formData.bedrooms = "";
  formData.bathrooms = "";
  formData.amenities = {
    parking: false,
    elevator: false,
    generator: false,
    security: false,
  };

  // Reset vehicle fields
  formData.vehicleType = "";
  formData.make = "";
  formData.model = "";
  formData.year = "";
  formData.mileage = "";
  formData.fuelType = "";
  formData.transmission = "";
  formData.registrationYear = "";

  // Reset electronics fields
  formData.electronicsType = "";
  formData.brand = "";
  formData.ageValue = "";
  formData.ageUnit = "months";
  formData.warranty = "";

  // Reset other categories fields
  formData.itemType = "";
  formData.itemQuality = "";
};

// Validate current step
const validateStep = () => {
  errors.category = !formData.category ? "Please select a category" : "";

  if (currentStep.value === 0) {
    errors.title = !formData.title ? "Please enter a title" : "";
    errors.description = !formData.description
      ? "Please enter a description"
      : "";
    errors.condition = !formData.condition ? "Please select a condition" : "";

    if (
      !errors.category &&
      !errors.title &&
      !errors.description &&
      !errors.condition
    ) {
      goToNextStep();
    }
  } else if (currentStep.value === 1) {
    // Validate category-specific fields
    if (getCategoryName(formData.category)?.toLowerCase() === "properties") {
      // Properties
      errors.propertyType = !formData.propertyType
        ? "Please select property type"
        : "";
      errors.size = !formData.size ? "Please enter property size" : "";

      if (!errors.propertyType && !errors.size) {
        goToNextStep();
      }
    } else if (
      getCategoryName(formData.category)?.toLowerCase() === "vehicles"
    ) {
      // Vehicles
      errors.vehicleType = !formData.vehicleType
        ? "Please select vehicle type"
        : "";
      errors.make = !formData.make ? "Please enter make" : "";
      errors.model = !formData.model ? "Please enter model" : "";
      errors.year = !formData.year ? "Please enter year" : "";

      if (
        !errors.vehicleType &&
        !errors.make &&
        !errors.model &&
        !errors.year
      ) {
        goToNextStep();
      }
    } else if (
      getCategoryName(formData.category)?.toLowerCase() === "electronics"
    ) {
      // Electronics
      errors.electronicsType = !formData.electronicsType
        ? "Please select electronics type"
        : "";
      errors.brand = !formData.brand ? "Please enter brand" : "";
      errors.model = !formData.model ? "Please enter model" : "";

      if (!errors.electronicsType && !errors.brand && !errors.model) {
        goToNextStep();
      }
    } else {
      errors.itemType = !formData.itemType ? "Please enter type or brand" : "";

      if (!errors.itemType) {
        goToNextStep();
      }
    }
  } else if (currentStep.value === 2) {
    if (!formData.negotiable) {
      errors.price = !formData.price
        ? "Please enter a price or mark as negotiable"
        : "";
    }

    errors.division = !formData.division ? "Please select division" : "";
    errors.district = !formData.district ? "Please select district" : "";
    errors.area = !formData.area ? "Please select area" : "";
    errors.detailedAddress = !formData.detailedAddress
      ? "Please enter detailed address"
      : "";
    errors.phone = !formData.phone ? "Please enter phone number" : "";

    if (
      (!errors.price || formData.negotiable) &&
      !errors.division &&
      !errors.district &&
      !errors.area &&
      !errors.detailedAddress &&
      !errors.phone
    ) {
      goToNextStep();
    }
  } else if (currentStep.value === 3) {
    // Check if at least one image is uploaded
    if (!formData.images.some((img) => img)) {
      errors.images = "Please upload at least one image";
      return;
    }

    // Validate terms acceptance
    errors.termsAccepted = !formData.termsAccepted
      ? "You must accept the terms and conditions"
      : "";

    if (!errors.images && !errors.termsAccepted) {
      // Submit the form
      submitForm();
    }
  }
};

const submitForm = async () => {
  try {
    console.log("Starting form submission process...");

    const payload = {
      category: formData.category,
      title: formData.title,
      images: formData.images,
      description: formData.description,
      condition: formData.condition,
      division: formData.division,
      district: formData.district,
      area: formData.area,
      detailed_address: formData.detailedAddress,
      phone: formData.phone,
      email: formData.email || null,
      negotiable: formData.negotiable,
      price: formData.negotiable ? formData.price || 0 : formData.price || 0,
      amenities: formData.amenities || {},
    };

    // Add category-specific fields
    const categoryName = getCategoryName(formData.category)?.toLowerCase();

    if (categoryName === "properties") {
      Object.assign(payload, {
        property_type: formData.propertyType,
        size: formData.size,
        unit: formData.unit,
        bedrooms: formData.bedrooms,
        bathrooms: formData.bathrooms,
      });
    } else if (categoryName === "vehicles") {
      Object.assign(payload, {
        vehicle_type: formData.vehicleType,
        make: formData.make,
        model: formData.model,
        year: formData.year,
        mileage: formData.mileage,
        fuel_type: formData.fuelType,
        transmission: formData.transmission,
        registration_year: formData.registrationYear,
      });
    } else if (categoryName === "electronics") {
      Object.assign(payload, {
        electronics_type: formData.electronicsType,
        brand: formData.brand,
        model: formData.model,
        age_value: formData.ageValue,
        age_unit: formData.ageUnit,
        warranty: formData.warranty,
      });
    } else if (["sports", "b2b", "others"].includes(categoryName)) {
      Object.assign(payload, {
        item_type: formData.itemType,
        item_quality: formData.itemQuality,
      });
    }

    // Handle image uploads separately if needed
    // If images need to be uploaded, do it in a separate API call before or after this
    // Or convert images to base64 if the server accepts that (not recommended for large files)
    let result;
    if (props.editPost) {
      payload.id = props.editPost.id;
      result = await updateSalePost(props.editPost.id, payload);
    } else {
      console.log("Payload to submit", payload);
      result = await createSalePost(payload);
      showSuccessModal.value = true;
    }

    console.log("Server response:", result);
    emit("post-saved", result);
  } catch (error) {
    console.error("Error submitting form:", error);
    // Display error message
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
  Object.keys(formData).forEach((key) => {
    if (key === "termsAccepted") {
      formData[key] = false;
    } else if (typeof formData[key] === "object" && formData[key] !== null) {
      if (Array.isArray(formData[key])) {
        formData[key] = [];
      } else {
        Object.keys(formData[key]).forEach((subKey) => {
          formData[key][subKey] = false;
        });
      }
    } else {
      formData[key] = "";
    }
  });

  formData.category = "";
  formData.negotiable = false;
  formData.unit = "sqft";
  formData.ageUnit = "months";

  // Clean up image previews
  imagePreviewUrls.value.forEach((url, index) => {
    if (url) {
      URL.revokeObjectURL(url);
    }
  });
  imagePreviewUrls.value = [];

  // Reset file inputs
  Object.keys(fileInputRefs).forEach((key) => {
    if (fileInputRefs[key]) {
      fileInputRefs[key].value = "";
    }
  });

  // Reset errors
  Object.keys(errors).forEach((key) => {
    errors[key] = "";
  });

  // Go back to first step
  currentStep.value = 0;
};

// Load edit data if available
onMounted(() => {
  if (props.editPost) {
    populateFormWithEditData();
  }
});

// Watch for changes in edit post data
watch(
  () => props.editPost,
  (newEditPost) => {
    if (newEditPost) {
      populateFormWithEditData();
    }
  }
);

// Populate form with edit data
const populateFormWithEditData = () => {
  const post = props.editPost;
  if (!post) return;

  // Basic fields
  formData.category = post.category;
  formData.title = post.title;
  formData.description = post.description;
  formData.condition = post.condition;
  formData.price = post.price;
  formData.negotiable = post.negotiable || false;

  // Location fields
  formData.division = post.division;
  formData.district = post.district;
  formData.area = post.area;
  formData.detailedAddress = post.detailed_address;

  // Contact info
  formData.phone = post.phone;
  formData.email = post.email;

  // Category-specific fields
  if (post.category === 1) {
    // Properties
    formData.propertyType = post.property_type;
    formData.size = post.size;
    formData.unit = post.unit || "sqft";
    formData.bedrooms = post.bedrooms;
    formData.bathrooms = post.bathrooms;

    // Amenities
    if (post.amenities) {
      try {
        const amenities =
          typeof post.amenities === "string"
            ? JSON.parse(post.amenities)
            : post.amenities;

        formData.amenities = {
          parking: amenities.parking || false,
          elevator: amenities.elevator || false,
          generator: amenities.generator || false,
          security: amenities.security || false,
        };
      } catch (e) {
        console.error("Error parsing amenities:", e);
      }
    }
  } else if (post.category === 2) {
    // Vehicles
    formData.vehicleType = post.vehicle_type;
    formData.make = post.make;
    formData.model = post.model;
    formData.year = post.year;
    formData.mileage = post.mileage;
    formData.fuelType = post.fuel_type;
    formData.transmission = post.transmission;
    formData.registrationYear = post.registration_year;
  } else if (post.category === 3) {
    // Electronics
    formData.electronicsType = post.electronics_type;
    formData.brand = post.brand;
    formData.model = post.model;
    formData.ageValue = post.age_value;
    formData.ageUnit = post.age_unit || "months";
    formData.warranty = post.warranty;
  } else if ([4, 5, 6].includes(post.category)) {
    // Other categories
    formData.itemType = post.item_type;
    formData.itemQuality = post.item_quality;
  }

  // Set existing images if available
  if (post.images && Array.isArray(post.images)) {
    post.images.forEach((image, index) => {
      if (index < 8) {
        // Maximum 8 images
        imagePreviewUrls.value[index] = image.image || image;
      }
    });
  }

  // Accept terms by default when editing
  formData.termsAccepted = true;
};
</script>

<style scoped>
.fade-transition {
  transition: all 0.3s ease;
}

/* Fix for number input spinner buttons */
input[type="number"]::-webkit-inner-spin-button,
input[type="number"]::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
input[type="number"] {
  -moz-appearance: textfield;
}
</style>
