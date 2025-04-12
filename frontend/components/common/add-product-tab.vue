<template>
  <div
    class="relative bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 py-6 sm:py-10 px-2"
  >
    <!-- Decorative background elements -->
    <div class="absolute top-0 left-0 w-full h-64 overflow-hidden">
      <div
        class="absolute -top-10 -left-10 w-72 h-72 bg-primary-500/10 dark:bg-primary-500/5 rounded-full blur-3xl"
      ></div>
      <div
        class="absolute top-20 right-10 w-96 h-96 bg-blue-500/10 dark:bg-blue-500/5 rounded-full blur-3xl"
      ></div>
    </div>

    <div class="relative max-w-4xl mx-auto">
      <!-- Form Title with Animation -->

      <form
        @submit.prevent="handleAddProduct"
        class="relative bg-white dark:bg-slate-800 overflow-hidden border border-slate-200/50 dark:border-slate-700/30 shadow-xl dark:shadow-slate-900/30 rounded-2xl"
      >
        <!-- Form Sections Container -->
        <div class="py-8">
          <!-- Product Basic Info Section -->
          <div
            class="form-section transition-all duration-500"
            :class="{ 'shadow-sm': currentStep === 0 }"
          >
            <div class="section-header">
              <div class="section-icon-wrapper">
                <UIcon
                  name="i-heroicons-information-circle"
                  class="section-icon"
                />
              </div>
              <h3 class="section-title">Basic Information</h3>
            </div>

            <div class="grid grid-cols-1 gap-6 mt-6">
              <!-- Product Name -->
              <div class="form-floating-group">
                <div class="relative">
                  <input
                    id="productName"
                    type="text"
                    v-model="form.name"
                    class="form-input py-2 px-4 block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500"
                    placeholder="Product Name"
                    :class="{ 'border-red-500': !form.name && checkSubmit }"
                  />
                  <label
                    for="productName"
                    class="absolute -top-2.5 left-3 px-1 bg-white dark:bg-slate-800 text-sm font-medium text-primary-600 dark:text-primary-400"
                  >
                    Product Name <span class="text-red-500">*</span>
                  </label>
                </div>
                <p v-if="!form.name && checkSubmit" class="form-error">
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="w-3.5 h-3.5 mr-1"
                  />
                  You must enter a product name
                </p>
              </div>

              <!-- Categories -->
              <div class="form-floating-group">
                <div class="relative">
                  <USelectMenu
                    v-model="form.category"
                    :options="categories"
                    option-attribute="name"
                    value-attribute="id"
                    placeholder="Select Category"
                    class="relative block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500 py-2"
                    :class="
                      !form.category && checkSubmit ? 'border-red-500' : ''
                    "
                  >
                    <template #leading>
                      <UIcon
                        name="i-heroicons-squares-2x2"
                        class="text-slate-400 dark:text-slate-500 w-5 h-5"
                      />
                    </template>
                  </USelectMenu>
                  <label
                    class="absolute -top-2.5 left-3 px-1 bg-white dark:bg-slate-800 text-sm font-medium text-primary-600 dark:text-primary-400"
                  >
                    Category <span class="text-red-500">*</span>
                  </label>
                </div>
                <p v-if="!form.category && checkSubmit" class="form-error">
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="w-3.5 h-3.5 mr-1"
                  />
                  Please select a category
                </p>
              </div>
            </div>
          </div>

          <!-- Product Details Section -->
          <div
            class="form-section sm:mt-12 transition-all duration-500"
            :class="{ 'shadow-lg': currentStep === 1 }"
          >
            <div class="section-header">
              <div class="section-icon-wrapper">
                <UIcon name="i-heroicons-document-text" class="section-icon" />
              </div>
              <h3 class="section-title">Product Details</h3>
            </div>

            <div class="mt-6 space-y-6">
              <!-- Rich Text Editor -->
              <div class="form-group">
                <label class="form-label mb-3 flex items-center">
                  <span>Description <span class="text-red-500">*</span></span>
                  <div
                    class="ml-2 text-sm px-2 py-0.5 bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 rounded-full"
                  >
                    Rich Text
                  </div>
                </label>
                <div class="relative premium-editor-container group">
                  <div
                    class="absolute inset-x-0 -top-0.5 h-0.5 bg-gradient-to-r from-primary-500 to-blue-500 transform scale-x-0 group-focus-within:scale-x-100 transition-transform duration-300"
                  ></div>
                  <div
                    class="absolute inset-x-0 -bottom-0.5 h-0.5 bg-gradient-to-r from-blue-500 to-primary-500 transform scale-x-0 group-focus-within:scale-x-100 transition-transform duration-300"
                  ></div>
                  <div
                    class="absolute inset-y-0 -left-0.5 w-0.5 bg-gradient-to-b from-primary-500 to-blue-500 transform scale-y-0 group-focus-within:scale-y-100 transition-transform duration-300"
                  ></div>
                  <div
                    class="absolute inset-y-0 -right-0.5 w-0.5 bg-gradient-to-b from-blue-500 to-primary-500 transform scale-y-0 group-focus-within:scale-y-100 transition-transform duration-300"
                  ></div>

                  <CommonEditor
                    v-if="router.query.id && form.description"
                    :content="form.description"
                    @updateContent="
                      (content) => {
                        form.description = content;
                      }
                    "
                    class="border border-slate-200 dark:border-slate-700 rounded-lg overflow-hidden transition-all duration-300 group-focus-within:border-primary-400 text-left p-2"
                  />
                  <CommonEditor
                    v-else
                    v-model="form.description"
                    @updateContent="updateContent"
                    class="border border-slate-200 dark:border-slate-700 rounded-lg overflow-hidden transition-all duration-300 group-focus-within:border-primary-400 text-left p-2"
                  />
                </div>
              </div>

              <!-- Short Description -->
              <div class="form-floating-group">
                <div class="relative">
                  <textarea
                    id="shortDescription"
                    v-model="form.short_description"
                    rows="3"
                    class="premium-textarea peer"
                    placeholder=" "
                  ></textarea>
                  <label for="shortDescription" class="floating-label-textarea">
                    Short Description
                  </label>
                </div>
                <p class="form-hint">
                  <UIcon
                    name="i-heroicons-light-bulb"
                    class="w-3.5 h-3.5 mr-1"
                  />
                  A brief overview that appears in product listings (150
                  characters max)
                </p>
              </div>
            </div>
          </div>

          <!-- Product Media Section -->
          <div
            class="form-section sm:mt-12 transition-all duration-500"
            :class="{ 'shadow-lg': currentStep === 2 }"
          >
            <div class="section-header">
              <div class="section-icon-wrapper">
                <UIcon name="i-heroicons-photo" class="section-icon" />
              </div>
              <h3 class="section-title">Media Gallery</h3>
            </div>

            <p class="text-sm text-slate-600 dark:text-slate-400 mt-4 mb-6">
              <UIcon
                name="i-heroicons-light-bulb"
                class="w-4 h-4 mr-1 text-amber-500"
                inline
              />
              High-quality images increase sales. Add up to 5 photos
              (recommended size: 1000×1000px)
            </p>

            <!-- Upload Container with Side-by-Side Layout -->
            <div
              class="premium-upload-container p-8 border-2 border-dashed border-slate-200 dark:border-slate-700 rounded-xl bg-slate-50/50 dark:bg-slate-800/20 relative group"
            >
              <div
                class="absolute inset-0 bg-primary-500/5 dark:bg-primary-500/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-xl"
              ></div>

              <!-- Animation lines -->
              <div
                class="absolute inset-0 overflow-hidden rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
              >
                <div
                  class="absolute top-0 left-0 w-full h-0.5 bg-gradient-to-r from-transparent via-primary-500 to-transparent animate-line-scroll"
                ></div>
                <div
                  class="absolute bottom-0 left-0 w-full h-0.5 bg-gradient-to-r from-transparent via-primary-500 to-transparent animate-line-scroll-reverse"
                ></div>
                <div
                  class="absolute left-0 top-0 h-full w-0.5 bg-gradient-to-b from-transparent via-primary-500 to-transparent animate-line-scroll"
                ></div>
                <div
                  class="absolute right-0 top-0 h-full w-0.5 bg-gradient-to-b from-transparent via-primary-500 to-transparent animate-line-scroll-reverse"
                ></div>
              </div>

              <!-- Image Gallery with Side-by-Side Layout -->
              <div
                class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4 relative"
              >
                <!-- Uploaded images with premium hover effects -->
                <template v-if="form.images && form.images.length > 0">
                  <div
                    v-for="(img, i) in form.images"
                    :key="i"
                    class="aspect-square rounded-lg overflow-hidden relative group/img flex items-center justify-center bg-slate-100 dark:bg-slate-800"
                  >
                    <div
                      class="absolute inset-0 bg-gradient-to-br from-blue-500/20 to-purple-500/20 opacity-0 group-hover/img:opacity-100 transition-opacity duration-300 z-10"
                    ></div>
                    <img
                      v-if="img.image"
                      :src="img.image"
                      :alt="`Uploaded file ${i + 1}`"
                      class="object-cover w-full h-full transition-all duration-500 group-hover/img:scale-110 group-hover/img:rotate-1"
                    />
                    <img
                      v-else
                      :src="img"
                      :alt="`Uploaded file ${i + 1}`"
                      class="object-cover w-full h-full transition-all duration-500 group-hover/img:scale-110 group-hover/img:rotate-1"
                    />

                    <!-- Premium overlay controls -->
                    <div
                      class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent opacity-0 group-hover/img:opacity-100 transition-opacity duration-300 flex flex-col justify-end p-2"
                    >
                      <div class="flex justify-between items-center">
                        <div class="text-sm text-white opacity-90">
                          Image {{ i + 1 }}
                        </div>
                        <button
                          type="button"
                          class="w-7 h-7 rounded-full bg-white/10 backdrop-blur-sm hover:bg-white/20 flex items-center justify-center text-white transition-all duration-300 group-hover:scale-110 z-10"
                          @click="deleteUpload(i)"
                        >
                          <UIcon name="i-heroicons-trash" class="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>
                  </div>
                </template>

                <!-- Upload button with clearer feedback and animations -->
                <div
                  v-if="!form.images || form.images.length < 5"
                  class="aspect-square rounded-lg relative border-2 border-dashed border-slate-300 dark:border-slate-600 bg-slate-100/50 dark:bg-slate-700/30 hover:border-primary-400 dark:hover:border-primary-500 hover:bg-primary-50/30 dark:hover:bg-primary-900/10 transition-colors flex items-center justify-center cursor-pointer group/upload"
                  :class="{ 'opacity-50 pointer-events-none': isUploading }"
                >
                  <input
                    type="file"
                    ref="fileInput"
                    class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                    @change="handleFileUpload"
                    accept="image/*"
                    :disabled="isUploading"
                  />

                  <!-- Pulse animation on hover -->
                  <div
                    class="absolute inset-0 rounded-lg pulse-animation opacity-0 group-hover/upload:opacity-100"
                  ></div>

                  <div
                    class="flex flex-col items-center gap-2 text-slate-500 dark:text-slate-400 text-sm text-center p-2 group-hover/upload:text-primary-600 dark:group-hover/upload:text-primary-400 transition-colors z-0"
                  >
                    <div
                      class="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-600 flex items-center justify-center group-hover/upload:bg-primary-100 dark:group-hover/upload:bg-primary-900/30 transition-colors"
                    >
                      <UIcon
                        v-if="!isUploading"
                        name="i-heroicons-plus"
                        class="w-5 h-5 group-hover/upload:scale-110 transition-transform"
                      />
                      <UIcon
                        v-else
                        name="i-heroicons-arrow-path"
                        class="w-5 h-5 animate-spin"
                      />
                    </div>
                    <span class="text-sm font-medium">
                      {{ isUploading ? "Uploading..." : "Add Photo" }}
                    </span>
                    <span
                      v-if="!isUploading"
                      class="text-xs text-slate-400 dark:text-slate-500"
                    >
                      {{ form.images ? `${form.images.length}/5` : "0/5" }}
                      images
                    </span>
                  </div>
                </div>
              </div>

              <!-- Upload status with premium styles -->
              <div class="mt-4">
                <p
                  v-if="uploadError"
                  class="text-sm flex items-center text-red-500"
                >
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="w-4 h-4 mr-1.5"
                  />
                  {{ uploadError }}
                </p>
                <div
                  v-if="isUploading"
                  class="text-sm flex items-center text-primary-600 dark:text-primary-400"
                >
                  <p
                    class="mr-2 w-4 h-4 border-2 border-primary-500 border-l-transparent rounded-full animate-spin"
                  ></p>
                  Uploading image...
                </div>
              </div>
            </div>
          </div>

          <!-- Product Pricing Section -->
          <div
            class="form-section sm:mt-12 transition-all duration-500"
            :class="{ 'shadow-lg': currentStep === 3 }"
          >
            <div class="section-header">
              <div class="section-icon-wrapper">
                <UIcon
                  name="i-heroicons-currency-bangladeshi"
                  class="section-icon"
                />
              </div>
              <h3 class="section-title">Pricing & Inventory</h3>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
              <!-- Regular Price with premium styling -->
              <div class="form-floating-group">
                <div class="relative">
                  <div
                    class="absolute left-3 top-3.5 text-slate-500 dark:text-slate-400"
                  >
                    ৳
                  </div>
                  <input
                    id="regularPrice"
                    v-model="form.regular_price"
                    type="number"
                    min="0"
                    step="0.01"
                    class="form-input py-3 pl-8 px-4 block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500"
                    placeholder="0.00"
                    :class="{
                      'border-red-500': !form.regular_price && checkSubmit,
                    }"
                  />
                  <label
                    for="regularPrice"
                    class="absolute -top-2.5 left-3 px-1 bg-white dark:bg-slate-800 text-sm font-medium text-primary-600 dark:text-primary-400"
                  >
                    Regular Price <span class="text-red-500">*</span>
                  </label>
                </div>
                <p v-if="!form.regular_price && checkSubmit" class="form-error">
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="w-3.5 h-3.5 mr-1"
                  />
                  Regular price is required
                </p>
              </div>

              <!-- Discounted Price -->
              <div class="form-floating-group">
                <div class="relative">
                  <div
                    class="absolute left-3 top-3.5 text-slate-500 dark:text-slate-400"
                  >
                    ৳
                  </div>
                  <input
                    id="salePrice"
                    v-model="form.sale_price"
                    type="number"
                    min="0"
                    step="0.01"
                    class="form-input py-3 pl-8 px-4 block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500"
                    placeholder="0.00"
                  />
                  <label
                    for="salePrice"
                    class="absolute -top-2.5 left-3 px-1 bg-white dark:bg-slate-800 text-sm font-medium text-primary-600 dark:text-primary-400"
                  >
                    Discounted Price
                  </label>
                </div>
                <p class="form-hint">
                  <UIcon name="i-heroicons-tag" class="w-3.5 h-3.5 mr-1" />
                  Leave empty if not on sale
                </p>
              </div>

              <!-- Stock Quantity -->
              <div class="form-floating-group">
                <div class="relative">
                  <input
                    id="stockQuantity"
                    v-model="form.quantity"
                    type="number"
                    min="0"
                    step="1"
                    class="form-input py-3 px-4 block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500"
                    placeholder="0"
                    :class="{ 'border-red-500': !form.quantity && checkSubmit }"
                  />
                  <label
                    for="stockQuantity"
                    class="absolute -top-2.5 left-3 px-1 bg-white dark:bg-slate-800 text-sm font-medium text-primary-600 dark:text-primary-400"
                  >
                    Stock Quantity <span class="text-red-500">*</span>
                  </label>
                </div>
                <p v-if="!form.quantity && checkSubmit" class="form-error">
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="w-3.5 h-3.5 mr-1"
                  />
                  Stock quantity is required
                </p>
              </div>
            </div>
          </div>

          <!-- Delivery Information Section -->
          <div
            class="form-section sm:mt-12 transition-all duration-500"
            :class="{ 'shadow-lg': currentStep === 4 }"
          >
            <div class="section-header">
              <div class="section-icon-wrapper">
                <UIcon name="i-heroicons-truck" class="section-icon" />
              </div>
              <h3 class="section-title">Delivery Information</h3>
            </div>

            <!-- Weight with premium styling -->
            <div class="mt-6">
              <div class="form-floating-group">
                <div class="relative">
                  <input
                    id="productWeight"
                    v-model="form.weight"
                    type="number"
                    min="0"
                    step="0.01"
                    class="form-input py-3 px-4 block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500"
                    placeholder="0.00"
                  />
                  <label
                    for="productWeight"
                    class="absolute -top-2.5 left-3 px-1 bg-white dark:bg-slate-800 text-sm font-medium text-primary-600 dark:text-primary-400"
                  >
                    Weight (kg)
                  </label>
                </div>
                <p class="form-hint">
                  <UIcon
                    name="i-heroicons-light-bulb"
                    class="w-3.5 h-3.5 mr-1 text-amber-500"
                  />
                  Required for accurate shipping calculation
                </p>
              </div>
            </div>

            <!-- Enhanced Delivery Methods Section -->
            <div
              class="mt-6 p-5 bg-slate-50 dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700"
            >
              <h4
                class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-4 flex items-center"
              >
                <UIcon
                  name="i-heroicons-truck"
                  class="w-4 h-4 mr-2 text-primary-500"
                />
                Delivery Method <span class="text-red-500 ml-0.5">*</span>
              </h4>

              <div class="space-y-4">
                <!-- Free Shipping Option with Radio button -->
                <div
                  class="relative bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden transition-all duration-300"
                  :class="{
                    'ring-2 ring-primary-500/30':
                      form.deliveryMethod === 'free',
                  }"
                >
                  <label class="p-4 flex items-start cursor-pointer">
                    <div class="flex items-center h-5 mt-0.5">
                      <input
                        type="radio"
                        v-model="form.deliveryMethod"
                        value="free"
                        class="form-radio border-slate-400 dark:border-slate-600"
                        name="deliveryMethod"
                      />
                    </div>
                    <div class="ml-3">
                      <span
                        class="text-sm font-medium text-slate-700 dark:text-slate-300 flex items-center"
                      >
                        Free Delivery All Over Bangladesh
                        <span
                          class="ml-2 inline-flex items-center px-1.5 py-0.5 rounded-full text-sm font-medium bg-gradient-to-r from-emerald-500 to-teal-500 text-white"
                        >
                          <UIcon
                            name="i-heroicons-sparkles"
                            class="w-3 h-3 mr-0.5 text-white"
                          />
                          FREE
                        </span>
                      </span>
                      <p
                        class="text-sm text-slate-500 dark:text-slate-400 mt-1"
                      >
                        Your customers won't pay any delivery charges
                      </p>
                    </div>
                  </label>
                </div>

                <!-- Standard Shipping Option with Radio button -->
                <div
                  class="relative bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden transition-all duration-300"
                  :class="{
                    'ring-2 ring-primary-500/30':
                      form.deliveryMethod === 'standard',
                  }"
                >
                  <label class="px-4 pt-4 pb-2 flex cursor-pointer">
                    <div class="flex items-center h-5 mt-0.5">
                      <input
                        type="radio"
                        v-model="form.deliveryMethod"
                        value="standard"
                        class="form-radio border-slate-400 dark:border-slate-600"
                        name="deliveryMethod"
                      />
                    </div>
                    <p class="ml-3 inline-flex flex-col items-start">
                      <span
                        class="text-sm font-medium text-slate-700 dark:text-slate-300"
                      >
                        Standard Shipping (Location Based)
                      </span>
                      <span
                        class="text-sm text-slate-500 dark:text-slate-400 mt-1"
                      >
                        Set different rates for inside and outside Dhaka
                      </span>
                    </p>
                  </label>

                  <!-- Rate inputs (only shown when standard is selected) -->
                  <div
                    v-if="form.deliveryMethod === 'standard'"
                    class="mt-2 pl-12 pr-4 pb-4 grid grid-cols-1 md:grid-cols-2 gap-4"
                  >
                    <!-- Inside Dhaka Rate -->
                    <div class="relative">
                      <label
                        class="block text-sm font-medium text-slate-600 dark:text-slate-400 mb-1.5"
                      >
                        Inside Dhaka Rate
                      </label>
                      <div class="relative">
                        <span
                          class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-500 dark:text-slate-400"
                          >৳</span
                        >
                        <input
                          v-model="form.delivery_fee_inside_dhaka"
                          type="number"
                          min="0"
                          class="form-input pl-7 py-2 block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500"
                          placeholder="100"
                        />
                      </div>
                    </div>

                    <!-- Outside Dhaka Rate -->
                    <div class="relative">
                      <label
                        class="block text-sm font-medium text-slate-600 dark:text-slate-400 mb-1.5"
                      >
                        Outside Dhaka Rate
                      </label>
                      <div class="relative">
                        <span
                          class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-500 dark:text-slate-400"
                          >৳</span
                        >
                        <input
                          v-model="form.delivery_fee_outside_dhaka"
                          type="number"
                          min="0"
                          class="form-input pl-7 py-2 block w-full border-slate-200 dark:border-slate-700 rounded-lg text-sm focus:border-primary-500 focus:ring-primary-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-primary-500"
                          placeholder="150"
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <p
                  v-if="!form.deliveryMethod && checkSubmit"
                  class="form-error mt-2"
                >
                  <UIcon
                    name="i-heroicons-exclamation-circle"
                    class="w-3.5 h-3.5 mr-1"
                  />
                  Please select a delivery method
                </p>
              </div>
            </div>
          </div>
          <UCard class="mx-6">
            <UCheckbox
              name="notifications"
              v-model="advanceEditMode"
              label="Advance Edit Mode"
              class="mb-2"
            />
            <CommonAdvanceProductEditor
              :currentProduct="form"
              v-if="advanceEditMode"
              @update:content="handleEditorUpdate"
            />
          </UCard>
          <!-- Form Actions -->
          <div
            class="flex flex-col sm:flex-row items-center justify-between gap-4 sm:mt-12 pt-6 border-t border-slate-200 dark:border-slate-700/60 px-6"
          >
            <!-- Left side buttons -->
            <div class="flex flex-wrap gap-4">
              <UButton
                color="gray"
                variant="ghost"
                class="rounded-lg"
                @click="resetForm"
              >
                <UIcon name="i-heroicons-arrow-path" class="w-4 h-4 mr-1.5" />
                Reset Form
              </UButton>
            </div>

            <!-- Right side submit button -->
            <UButton
              type="submit"
              color="primary"
              class="rounded-lg relative overflow-hidden group"
              :loading="isSubmitting"
            >
              <span class="flex items-center gap-1.5 relative z-10">
                <UIcon name="i-heroicons-check" class="w-4 h-4" />
                <span>Publish Product</span>
              </span>

              <!-- Fixed Shimmer Effect -->
              <div
                class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000"
              ></div>
            </UButton>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  product: Object,
});
const { get, post, put } = useApi();
const router = useRoute();
const toast = useToast();
const currentStep = ref(0); // Track current step for highlighting
const categories = ref([]);
// Simplified form with only essential fields
const form = ref(
  props.product || {
    name: "",
    category: "",
    description: "",
    short_description: "",
    images: [],
    discount_price: null,
    sale_price: null,
    quantity: null,
    weight: null,
    is_free_delivery: false,
    delivery_fee_free: 0,
    delivery_fee_inside_dhaka: 0,
    delivery_fee_outside_dhaka: 0,
  }
);

// Loading state
const isSubmitting = ref(false);
const isSuccessModalOpen = ref(false);
const successMessage = ref("");
const uploadError = ref("");
const isUploading = ref(false);
const checkSubmit = ref(false);
const advanceEditMode = ref(false);
const productEditorData = ref(null);

// Function to log advanced editor updates
function handleEditorUpdate(editorData) {
  console.group("Advanced Editor Data Update");
  console.log("Received editor data in parent component:", editorData);

  // Log individual sections for better visibility
  console.log("Header texts:", {
    benefitsTitle: editorData.benefitsTitle,
    benefitsCta: editorData.benefitsCta,
    faqsTitle: editorData.faqsTitle,
    faqsSubtitle: editorData.faqsSubtitle,
    ctaTitle: editorData.ctaTitle,
    ctaSubtitle: editorData.ctaSubtitle,
    ctaButtonText: editorData.ctaButtonText,
    ctaButtonSubtext: editorData.ctaButtonSubtext,
  });

  console.log("Benefits:", editorData.benefits);
  console.log("FAQs:", editorData.faqs);
  console.log("Trust badges:", editorData.trustBadges);

  // Store the editor data in the form
  if (editorData) {
    const previousData = form.value.editorData;
    form.value.editorData = editorData;

    // Compare with previous data if available
    if (previousData) {
      console.log("Changes from previous data:", {
        headersChanged:
          JSON.stringify(previousData.benefitsTitle) !==
            JSON.stringify(editorData.benefitsTitle) ||
          JSON.stringify(previousData.faqsTitle) !==
            JSON.stringify(editorData.faqsTitle) ||
          JSON.stringify(previousData.ctaTitle) !==
            JSON.stringify(editorData.ctaTitle),
        benefitsChanged:
          JSON.stringify(previousData.benefits) !==
          JSON.stringify(editorData.benefits),
        faqsChanged:
          JSON.stringify(previousData.faqs) !== JSON.stringify(editorData.faqs),
        trustBadgesChanged:
          JSON.stringify(previousData.trustBadges) !==
          JSON.stringify(editorData.trustBadges),
      });
    }

    // Add timestamp to track when changes occurred
    const now = new Date();
    console.log("Update timestamp:", now.toISOString());

    // Log the full updated form
    console.log("Updated form with editor data:", form.value);

    // Update the reference for display in the template
    productEditorData.value = editorData;

    // Show confirmation toast
    toast.add({
      title: "Editor Content Updated",
      description: `Advanced editor changes saved at ${now.toLocaleTimeString()}`,
      color: "green",
      timeout: 3000,
    });
  }
  console.groupEnd();
}

// Handle product submission with proper delivery fee processing
async function handleAddProduct() {
  // Start logging group
  console.group("Product Submission");
  console.log("Form data before submission:", form.value);

  if (form.value.editorData) {
    console.log(
      "Advanced editor data included in submission:",
      form.value.editorData
    );
  } else {
    console.log("No advanced editor data in submission");
  }

  checkSubmit.value = true;

  // Validate required fields
  if (
    !form.value.name ||
    !form.value.category ||
    !form.value.regular_price ||
    !form.value.quantity ||
    !form.value.deliveryMethod
  ) {
    toast.add({
      title: "Missing Required Fields",
      description: "Please fill in all required fields",
      color: "red",
    });
    console.log("Form validation failed - missing required fields");
    console.groupEnd();
    return;
  }

  isSubmitting.value = true;

  try {
    // Create API submission object from form data
    const productData = {
      ...form.value,
      ...form.value.editorData,
      is_advanced: advanceEditMode.value,
    };

    // Set is_free_delivery based on delivery method selection
    if (form.value.deliveryMethod === "free") {
      productData.is_free_delivery = true;
      productData.delivery_fee_inside_dhaka = 0;
      productData.delivery_fee_outside_dhaka = 0;
    } else {
      productData.is_free_delivery = false;
      // Keep the user-entered delivery fee values
    }

    // Clean up temporary form fields before submission
    delete productData.deliveryMethod;

    console.log("Sending product data to API:", productData);

    // Check if we are updating or creating a product
    let res;
    if (props.product?.id) {
      // Update existing product
      res = await put(`/products/${props.product.slug}/`, productData);
      successMessage.value = "Your product has been updated successfully!";
    } else {
      // Create new product
      res = await post("/products/", productData);
      successMessage.value = "Your product has been published successfully!";
    }

    if (res.data) {
      console.log("API response:", res.data);
      toast.add({
        title: "Success",
        description: successMessage.value,
        color: "green",
      });
      isSuccessModalOpen.value = true;

      // Reset form after successful submission (only for new products)
      if (!props.product?.id) {
        resetForm(false);
        checkSubmit.value = false;
        currentStep.value = 1;
      }
    }
  } catch (error) {
    console.error("Product submission error details:", error);
    toast.add({
      title: "Error",
      description:
        error?.message || "Failed to save product. Please try again.",
      color: "red",
    });
  } finally {
    isSubmitting.value = false;
    console.groupEnd();
  }
}

async function getCategories() {
  const { data } = await get("/product-categories/");
  categories.value = data;
}

await getCategories();

// Add these improved functions to your script setup section

// Enhanced file upload handling with better error handling and file input reset
function handleFileUpload(event) {
  isUploading.value = true;
  uploadError.value = "";

  try {
    const files = Array.from(event.target.files);

    if (!files || files.length === 0) {
      uploadError.value = "No file selected";
      isUploading.value = false;
      return;
    }

    const file = files[0];

    if (!file.type.startsWith("image/")) {
      uploadError.value = "Please select a valid image file";
      isUploading.value = false;
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      uploadError.value = "Image size must be less than 5MB";
      isUploading.value = false;
      return;
    }

    if (!form.value.images) {
      form.value.images = [];
    }

    if (form.value.images.length >= 5) {
      uploadError.value = "Maximum 5 images allowed";
      isUploading.value = false;
      return;
    }

    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement("canvas");
        let width = img.width;
        let height = img.height;

        // Resize while maintaining aspect ratio
        const maxSize = 1000;
        if (width > maxSize || height > maxSize) {
          if (width > height) {
            height = height * (maxSize / width);
            width = maxSize;
          } else {
            width = width * (maxSize / height);
            height = maxSize;
          }
        }

        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, width, height);

        const compressedDataUrl = canvas.toDataURL("image/jpeg", 0.8); // 80% quality

        form.value.images.push(compressedDataUrl);
        isUploading.value = false;

        if (event.target) {
          event.target.value = null;
        }
      };

      img.onerror = () => {
        uploadError.value = "Invalid image. Please try again.";
        isUploading.value = false;
      };

      img.src = e.target.result;
    };

    reader.onerror = (error) => {
      console.error("FileReader error:", error);
      uploadError.value = "Error uploading image. Please try again.";
      isUploading.value = false;
    };

    reader.readAsDataURL(file);
  } catch (error) {
    console.error("File upload error:", error);
    uploadError.value = "Unexpected error occurred during upload";
    isUploading.value = false;
  }
}

// More robust image deletion with confirmation and error handling
function deleteUpload(index) {
  try {
    if (index < 0 || !form.value.images || index >= form.value.images.length) {
      console.warn("Invalid image index for deletion:", index);
      return;
    }

    // Optional: Add confirmation dialog
    if (confirm("Are you sure you want to remove this image?")) {
      // Create a new array without the deleted item
      const newImages = [...form.value.images];
      newImages.splice(index, 1);
      form.value.images = newImages;

      // Success notification
      toast.add({
        title: "Image Removed",
        description: "The image has been removed successfully",
        color: "blue",
        timeout: 2000,
      });
    }
  } catch (error) {
    console.error("Error removing image:", error);
    toast.add({
      title: "Error",
      description: "Failed to remove the image. Please try again.",
      color: "red",
    });
  }
}

// Updated function to log changes in the editor content
function updateContent(p) {
  console.log(
    "Content updated:",
    p.substring(0, 100) + (p.length > 100 ? "..." : "")
  );
  form.value.description = p;
}

function resetForm(showConfirm = true) {
  const doReset = showConfirm
    ? confirm(
        "Are you sure you want to reset the form? All changes will be lost."
      )
    : true;

  if (doReset) {
    console.log("Resetting form");
    form.value = {
      name: "",
      category: "",
      description: "",
      short_description: "",
      images: [],
      discount_price: null,
      sale_price: null,
      quantity: null,
      weight: null,
      delivery_fee_free: 0,
      delivery_fee_inside_dhaka: 0,
      delivery_fee_outside_dhaka: 0,
    };
    // Also reset editor data
    productEditorData.value = null;
  }
}
</script>

<style scoped>
/* Premium Glassmorphism Card */
.glassmorphism-card {
  @apply bg-white/90 dark:bg-slate-800/90 backdrop-blur-md;
}

/* Section Styling */
.form-section {
  @apply px-2 sm:px-6 py-5 rounded-xl relative transition-all duration-300;
}

.section-header {
  @apply flex items-center gap-3 mb-4;
}

.section-icon-wrapper {
  @apply w-10 h-10 rounded-full bg-primary-50 dark:bg-primary-900/30 flex items-center justify-center border border-primary-200 dark:border-primary-800/50;
}

.section-icon {
  @apply w-5 h-5 text-primary-600 dark:text-primary-400;
}

.section-title {
  @apply text-lg font-medium text-slate-800 dark:text-white;
}

/* Premium Floating Form Controls */
.form-floating-group {
  @apply relative;
}

.floating-input-wrapper {
  @apply relative;
}

.floating-input {
  @apply w-full px-4 py-2.5 pt-5 pl-10 rounded-lg border border-slate-200 dark:border-slate-700 
         bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 focus:outline-none focus:border-primary-500 
         dark:focus:border-primary-400 focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20 transition-all duration-200;
}

.floating-label {
  @apply absolute left-10 top-3.5 text-sm text-slate-500 dark:text-slate-400 transition-all duration-200 pointer-events-none
         peer-focus:text-sm peer-focus:top-1.5 peer-focus:text-primary-600 dark:peer-focus:text-primary-400
         peer-[:not(:placeholder-shown)]:text-sm peer-[:not(:placeholder-shown)]:top-1.5;
}

.floating-icon {
  @apply absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 dark:text-slate-500;
}

/* Premium Currency Input */
.premium-currency-input {
  @apply relative;
}

.currency-symbol {
  @apply absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 dark:text-slate-400 font-medium;
}

.premium-input {
  @apply w-full px-4 py-2.5 pt-5 pl-10 rounded-lg border border-slate-200 dark:border-slate-700
         bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 focus:outline-none focus:border-primary-500
         dark:focus:border-primary-400 focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20 transition-all duration-200;
}

.premium-input-label {
  @apply absolute left-10 top-1.5 text-sm text-slate-500 dark:text-slate-400;
}

/* Premium Textarea */
.premium-textarea {
  @apply w-full px-4 py-2.5 pt-5 rounded-lg border border-slate-200 dark:border-slate-700
         bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 focus:outline-none focus:border-primary-500
         dark:focus:border-primary-400 focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20 transition-all duration-200 resize-none;
}

.floating-label-textarea {
  @apply absolute left-4 top-1.5 text-sm text-slate-500 dark:text-slate-400;
}

/* Premium Select */
.premium-select {
  @apply border-slate-200 dark:border-slate-700 pt-4 focus:border-primary-500 dark:focus:border-primary-400
         focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20;
}

/* Form Hints & Errors */
.form-hint {
  @apply mt-1.5 text-sm text-slate-500 dark:text-slate-400 flex items-center;
}

.form-error {
  @apply mt-1.5 text-sm text-red-500 flex items-center;
}

/* Premium Buttons */
.premium-btn-primary {
  @apply rounded-lg py-2.5 px-5 bg-gradient-to-r from-primary-500 to-primary-600 border-0 shadow-md 
         hover:shadow-lg hover:from-primary-600 hover:to-primary-700 transition-all duration-300 transform hover:-translate-y-0.5;
}

.premium-btn-outline {
  @apply rounded-lg py-2.5 px-5 border border-slate-200 dark:border-slate-700 hover:border-primary-400 
         dark:hover:border-primary-500 hover:bg-primary-50 dark:hover:bg-primary-900/10 
         text-slate-700 dark:text-slate-300 hover:text-primary-600 dark:hover:text-primary-400
         transition-all duration-300 transform hover:-translate-y-0.5;
}

.premium-btn-secondary {
  @apply rounded-lg py-2.5 px-5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 
         dark:hover:bg-slate-700/50 hover:text-slate-800 dark:hover:text-white
         transition-all duration-300;
}

/* Premium Checkboxes */
.premium-checkbox-container {
  @apply cursor-pointer;
}

.premium-checkbox {
  @apply sr-only;
}

.premium-checkbox-bg {
  @apply absolute w-5 h-5 border-2 border-slate-300 dark:border-slate-600 rounded 
         transition-colors duration-200;
}

.premium-checkbox-container input:checked ~ .premium-checkbox-bg {
  @apply bg-primary-500 border-primary-500 dark:bg-primary-600 dark:border-primary-600;
}

.premium-checkbox-icon {
  @apply absolute w-3 h-3 text-white opacity-0 transform scale-90 
         transition-all duration-200 pointer-events-none;
}

.premium-checkbox-container input:checked ~ .premium-checkbox-icon {
  @apply opacity-100 scale-100;
}

/* Premium Radio Buttons */
.premium-radio-container {
  @apply cursor-pointer;
}

.premium-radio {
  @apply sr-only;
}

.premium-radio-bg {
  @apply absolute w-5 h-5 border-2 border-slate-300 dark:border-slate-600 rounded-full 
         transition-colors duration-200;
}

.premium-radio-dot {
  @apply absolute w-2.5 h-2.5 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full 
         bg-primary-500 scale-0 opacity-0 transition-all duration-200;
}

.premium-radio-container input:checked ~ .premium-radio-bg {
  @apply border-primary-500 dark:border-primary-500;
}

.premium-radio-container input:checked ~ .premium-radio-dot {
  @apply scale-100 opacity-100;
}

/* Upload Container Animations */
.premium-upload-container {
  @apply transition-all duration-300;
}

.premium-editor-container {
  @apply transition-all duration-300;
}

/* Pulse Animation */
.pulse-animation {
  @apply border-2 border-primary-400/50 dark:border-primary-500/50;
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 0.5;
  }
  50% {
    opacity: 0;
  }
}

/* Success Animation */
.success-pulse-animation {
  animation: success-pulse 1.5s ease-in-out infinite;
}

@keyframes success-pulse {
  0%,
  100% {
    transform: scale(1);
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 0 0 0 15px rgba(255, 255, 255, 0);
  }
}

/* Success Modal Particles */
.success-particle {
  @apply absolute w-2 h-2 rounded-full bg-white/40;
  animation: float-up 3s ease-in-out infinite;
  top: 100%;
  left: calc(random(100) * 1%);
  animation-delay: calc(random(3) * 1s);
}

@keyframes float-up {
  0% {
    transform: translateY(0) scale(0);
    opacity: 0;
  }
  50% {
    opacity: 1;
  }
  100% {
    transform: translateY(-300px) scale(1);
    opacity: 0;
  }
}

/* Animation Lines */
@keyframes line-scroll {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

@keyframes line-scroll-reverse {
  0% {
    transform: translateX(100%);
  }
  100% {
    transform: translateX(-100%);
  }
}

.animate-line-scroll {
  animation: line-scroll 3s infinite linear;
}

.animate-line-scroll-reverse {
  animation: line-scroll-reverse 3s infinite linear;
}

/* Shimmer animation */
@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

/* Additional Hover Effects */
.form-section:hover {
  @apply bg-slate-50/70 dark:bg-slate-800/60;
}

/* Premium Modal */
.premium-modal {
  @apply backdrop-blur-md;
}
</style>
