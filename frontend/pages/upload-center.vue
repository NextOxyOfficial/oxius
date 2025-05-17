<template>
  <div
    class="min-h-screen bg-gradient-to-b from-gray-50 to-white dark:from-gray-900 dark:to-gray-800 py-12"
  >
    <UContainer class="max-w-4xl">
      <!-- Animated Header -->
      <div class="text-center mb-12">
        <h1
          class="animate-fade-in-up text-xl md:text-2xl font-semibold bg-clip-text text-transparent bg-gradient-to-r from-primary-600 to-primary-400 mb-4"
        >
          {{ $t("upload_center") }}
        </h1>
        <div
          class="w-24 h-1 bg-gradient-to-r from-primary-500 to-primary-300 mx-auto rounded-full animate-width"
        ></div>
      </div>
      <div v-if="form && !form.pending" class="animate-fade-in-up">
        <div
          class="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm mb-8 flex items-center justify-between"
        >
          <div class="flex items-center">
            <div
              class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center mr-3"
            >
              <UIcon
                name="i-heroicons-user"
                class="text-gray-500 dark:text-gray-400"
              />
            </div>
            <div>
              <span
                v-if="user.user.kyc"
                class="flex items-center font-medium text-gray-800 dark:text-gray-200"
              >
                {{ user.user.name }}
                <UIcon
                  name="mdi:check-decagram"
                  class="ml-2 text-blue-500 animate-bounce-subtle"
                />
              </span>
              <span v-else class="text-red-500 font-medium flex items-center">
                <UIcon
                  name="i-heroicons-exclamation-circle"
                  class="mr-1 animate-pulse"
                />
                KYC Unverified
              </span>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                {{
                  user.user.kyc
                    ? "Your identity has been verified"
                    : "Please complete verification"
                }}
              </p>
            </div>
          </div>

          <div>
            <div
              v-if="user.user.kyc"
              class="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-xs rounded-full"
            >
              Verified
            </div>
            <div
              v-else
              class="px-3 py-1 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 text-xs rounded-full"
            >
              Unverified
            </div>
          </div>
        </div>
      </div>
      <!-- Instruction Card -->
      <div
        class="bg-white dark:bg-gray-800 rounded-xl shadow-sm mb-10 overflow-hidden animate-fade-in transform hover:scale-[1.01] transition-all duration-300"
      >
        <div class="p-6">
          <div class="flex items-center mb-4">
            <div
              class="w-10 h-10 rounded-full bg-primary-50 dark:bg-primary-900 flex items-center justify-center mr-4"
            >
              <UIcon
                name="i-heroicons-information-circle"
                class="text-xl text-primary-500"
              />
            </div>
            <h2 class="text-xl font-semibold text-gray-800 dark:text-gray-100">
              Verification Instructions
            </h2>
          </div>

          <ul
            class="space-y-3 text-sm md:text-base text-gray-600 dark:text-gray-300 pl-4"
          >
            <li class="flex items-start">
              <UIcon
                name="i-heroicons-check-circle"
                class="text-green-500 text-lg mr-2 mt-0.5"
              />
              <span
                >This is the upload center where you can upload documents for
                verification purposes.</span
              >
            </li>
            <li class="flex items-start">
              <UIcon
                name="i-heroicons-check-circle"
                class="text-green-500 text-lg mr-2 mt-0.5"
              />
              <span>You can upload NID front, back, and selfie.</span>
            </li>
            <li class="flex items-start">
              <UIcon
                name="i-heroicons-check-circle"
                class="text-green-500 text-lg mr-2 mt-0.5"
              />
              <span
                >We accept NID, Passport, Driving License, Birth
                Certificate.</span
              >
            </li>
            <li class="flex items-start">
              <UIcon
                name="i-heroicons-check-circle"
                class="text-green-500 text-lg mr-2 mt-0.5"
              />
              <span
                >After uploading, you will be able to review and approve the
                documents.</span
              >
            </li>
          </ul>
        </div>
      </div>

      <!-- Pending Verification Alert -->
      <div v-if="form && form.pending" class="animate-fade-in">
        <div
          class="bg-amber-50 dark:bg-amber-900/30 rounded-xl overflow-hidden shadow-sm p-6"
        >
          <div class="flex flex-col items-center text-center">
            <div
              class="w-16 h-16 rounded-full bg-amber-100 dark:bg-amber-800/50 flex items-center justify-center mb-4 animate-pulse"
            >
              <UIcon name="i-heroicons-clock" class="text-2xl text-amber-500" />
            </div>
            <h3
              class="text-xl font-semibold text-amber-800 dark:text-amber-300 mb-2"
            >
              Verification in Progress
            </h3>
            <p class="text-amber-700 dark:text-amber-400">
              Your ID verification is currently under review by our team.
            </p>

            <div class="mt-6 w-full max-w-md">
              <div
                class="h-2 bg-amber-200 dark:bg-amber-700/40 rounded-full overflow-hidden"
              >
                <div
                  class="h-full bg-amber-500 dark:bg-amber-500 rounded-full animate-progress"
                ></div>
              </div>
            </div>

            <p class="text-sm text-amber-600 dark:text-amber-500 mt-4">
              We'll notify you when your verification is complete.
            </p>
          </div>
        </div>
      </div>

      <!-- Main Upload Section -->
      <div v-else-if="form && !form.pending" class="animate-fade-in">
        <!-- User Status Banner -->

        <!-- Upload Section -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <!-- ID Upload Section -->
          <div v-if="!id_verification">
            <div
              class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden hover:shadow-sm transition-all duration-300"
            >
              <div class="bg-gradient-to-r from-primary-600 to-primary-400 p-4">
                <h3 class="text-white font-semibold flex items-center">
                  <UIcon name="i-heroicons-identification" class="mr-2" />
                  ID Verification
                </h3>
              </div>

              <div class="p-6 space-y-8">
                <!-- ID Front -->
                <div class="upload-item">
                  <div class="upload-item-header">
                    <h4 class="font-medium text-gray-700 dark:text-gray-200">
                      ID Front
                    </h4>
                    <div
                      class="upload-status"
                      :class="
                        form.front
                          ? 'bg-green-500'
                          : 'bg-gray-300 dark:bg-gray-700'
                      "
                    ></div>
                  </div>

                  <div class="upload-container">
                    <div
                      v-if="form.front"
                      class="relative aspect-[3/2] w-full bg-gray-100 dark:bg-gray-700 rounded-xl overflow-hidden group animate-fade-in"
                    >
                      <img
                        :src="form.front"
                        alt="ID Front"
                        class="w-full h-full object-contain"
                      />
                      <div
                        class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
                      >
                        <button
                          @click="deleteUpload('front')"
                          class="bg-white/20 backdrop-blur-sm p-2 rounded-full text-white hover:bg-white/30 transition-all"
                        >
                          <UIcon name="i-heroicons-trash" class="text-xl" />
                        </button>
                      </div>
                    </div>

                    <div v-else class="upload-dropzone">
                      <input
                        type="file"
                        class="absolute inset-0 opacity-0 cursor-pointer z-10"
                        @change="handleFileUpload($event, 'front')"
                      />
                      <div class="flex flex-col items-center">
                        <div
                          class="w-12 h-12 rounded-full bg-primary-50 dark:bg-primary-900/50 flex items-center justify-center mb-2"
                        >
                          <UIcon
                            name="i-heroicons-arrow-up-tray"
                            class="text-xl text-primary-500"
                          />
                        </div>
                        <span
                          class="text-sm font-medium text-gray-700 dark:text-gray-300"
                          >Upload Front</span
                        >
                        <span
                          class="text-xs text-gray-500 dark:text-gray-400 mt-1"
                          >Click or drag file</span
                        >
                      </div>
                    </div>
                  </div>

                  <p
                    v-if="errors.front"
                    class="text-sm text-red-500 flex items-center mt-1 animate-fade-in"
                  >
                    <UIcon name="i-heroicons-exclamation-circle" class="mr-1" />
                    ID front is required
                  </p>
                </div>

                <!-- ID Back -->
                <div class="upload-item">
                  <div class="upload-item-header">
                    <h4 class="font-medium text-gray-700 dark:text-gray-200">
                      ID Back
                    </h4>
                    <div
                      class="upload-status"
                      :class="
                        form.back
                          ? 'bg-green-500'
                          : 'bg-gray-300 dark:bg-gray-700'
                      "
                    ></div>
                  </div>

                  <div class="upload-container">
                    <div
                      v-if="form.back"
                      class="relative aspect-[3/2] w-full bg-gray-100 dark:bg-gray-700 rounded-xl overflow-hidden group animate-fade-in"
                    >
                      <img
                        :src="form.back"
                        alt="ID Back"
                        class="w-full h-full object-contain"
                      />
                      <div
                        class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
                      >
                        <button
                          @click="deleteUpload('back')"
                          class="bg-white/20 backdrop-blur-sm p-2 rounded-full text-white hover:bg-white/30 transition-all"
                        >
                          <UIcon name="i-heroicons-trash" class="text-xl" />
                        </button>
                      </div>
                    </div>

                    <div v-else class="upload-dropzone">
                      <input
                        type="file"
                        class="absolute inset-0 opacity-0 cursor-pointer z-10"
                        @change="handleFileUpload($event, 'back')"
                      />
                      <div class="flex flex-col items-center">
                        <div
                          class="w-12 h-12 rounded-full bg-primary-50 dark:bg-primary-900/50 flex items-center justify-center mb-2"
                        >
                          <UIcon
                            name="i-heroicons-arrow-up-tray"
                            class="text-xl text-primary-500"
                          />
                        </div>
                        <span
                          class="text-sm font-medium text-gray-700 dark:text-gray-300"
                          >Upload Back</span
                        >
                        <span
                          class="text-xs text-gray-500 dark:text-gray-400 mt-1"
                          >Click or drag file</span
                        >
                      </div>
                    </div>
                  </div>

                  <p
                    v-if="errors.back"
                    class="text-sm text-red-500 flex items-center mt-1 animate-fade-in"
                  >
                    <UIcon name="i-heroicons-exclamation-circle" class="mr-1" />
                    ID back is required
                  </p>
                </div>

                <!-- Selfie with ID -->
                <div class="upload-item">
                  <div class="upload-item-header">
                    <h4 class="font-medium text-gray-700 dark:text-gray-200">
                      Selfie with ID
                    </h4>
                    <div
                      class="upload-status"
                      :class="
                        form.selfie
                          ? 'bg-green-500'
                          : 'bg-gray-300 dark:bg-gray-700'
                      "
                    ></div>
                  </div>

                  <div class="upload-container">
                    <div
                      v-if="form.selfie"
                      class="relative aspect-[3/2] w-full bg-gray-100 dark:bg-gray-700 rounded-xl overflow-hidden group animate-fade-in"
                    >
                      <img
                        :src="form.selfie"
                        alt="Selfie with ID"
                        class="w-full h-full object-contain"
                      />
                      <div
                        class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
                      >
                        <button
                          @click="deleteUpload('selfie')"
                          class="bg-white/20 backdrop-blur-sm p-2 rounded-full text-white hover:bg-white/30 transition-all"
                        >
                          <UIcon name="i-heroicons-trash" class="text-xl" />
                        </button>
                      </div>
                    </div>

                    <div v-else class="upload-dropzone">
                      <input
                        type="file"
                        class="absolute inset-0 opacity-0 cursor-pointer z-10"
                        @change="handleFileUpload($event, 'selfie')"
                      />
                      <div class="flex flex-col items-center">
                        <div
                          class="w-12 h-12 rounded-full bg-primary-50 dark:bg-primary-900/50 flex items-center justify-center mb-2"
                        >
                          <UIcon
                            name="i-heroicons-arrow-up-tray"
                            class="text-xl text-primary-500"
                          />
                        </div>
                        <span
                          class="text-sm font-medium text-gray-700 dark:text-gray-300"
                          >Upload Selfie</span
                        >
                        <span
                          class="text-xs text-gray-500 dark:text-gray-400 mt-1"
                          >Click or drag file</span
                        >
                      </div>
                    </div>
                  </div>

                  <p
                    v-if="errors.selfie"
                    class="text-sm text-red-500 flex items-center mt-1 animate-fade-in"
                  >
                    <UIcon name="i-heroicons-exclamation-circle" class="mr-1" />
                    Selfie with ID is required
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Other Documents -->
          <div v-if="user.user.kyc" class="hidden">
            <div
              class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden hover:shadow-sm transition-all duration-300 h-full"
            >
              <div class="bg-gradient-to-r from-green-600 to-green-400 p-4">
                <h3 class="text-white font-semibold flex items-center">
                  <UIcon name="i-heroicons-document" class="mr-2" />
                  Additional Documents
                </h3>
              </div>

              <div class="p-6 flex flex-col">
                <p class="text-gray-600 dark:text-gray-300 text-sm mb-6">
                  Upload any additional documents that may help verify your
                  identity or support your account.
                </p>

                <div class="upload-item flex-grow">
                  <div class="upload-item-header">
                    <h4 class="font-medium text-gray-700 dark:text-gray-200">
                      Other Document
                    </h4>
                    <div
                      class="upload-status"
                      :class="
                        form.other_document
                          ? 'bg-green-500'
                          : 'bg-gray-300 dark:bg-gray-700'
                      "
                    ></div>
                  </div>

                  <!-- Upload container with proper styling -->
                  <div class="upload-container">
                    <div
                      v-if="form.other_document"
                      class="relative aspect-[3/2] w-full bg-gray-100 dark:bg-gray-700 rounded-xl overflow-hidden group animate-fade-in"
                    >
                      <img
                        :src="form.other_document"
                        alt="Other Document"
                        class="w-full h-full object-contain"
                      />
                      <div
                        class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
                      >
                        <button
                          @click="deleteUpload('other_document')"
                          class="bg-white/20 backdrop-blur-sm p-2 rounded-full text-white hover:bg-white/30 transition-all"
                        >
                          <UIcon name="i-heroicons-trash" class="text-xl" />
                        </button>
                      </div>
                    </div>

                    <div v-else class="upload-dropzone">
                      <input
                        type="file"
                        class="absolute inset-0 opacity-0 cursor-pointer z-10"
                        @change="handleFileUpload($event, 'other_document')"
                      />
                      <div class="flex flex-col items-center">
                        <div
                          class="w-12 h-12 rounded-full bg-green-50 dark:bg-green-900/50 flex items-center justify-center mb-2"
                        >
                          <UIcon
                            name="i-heroicons-plus"
                            class="text-xl text-green-500"
                          />
                        </div>
                        <span
                          class="text-sm font-medium text-gray-700 dark:text-gray-300"
                          >Optional Document</span
                        >
                        <span
                          class="text-xs text-gray-500 dark:text-gray-400 mt-1"
                          >Any supporting document</span
                        >
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Additional document submit button -->
                <div v-if="form.other_document" class="mt-6 flex justify-end">
                  <UButton
                    :loading="isAdditionalDocLoading"
                    color="green"
                    variant="solid"
                    class="submit-button"
                    @click="submitAdditionalDocument"
                  >
                    <UIcon
                      name="i-heroicons-cloud-arrow-up"
                      class="mr-2 icon-float"
                    />
                    Submit Additional Document
                  </UButton>
                </div>
              </div>
            </div>
          </div>

          <!-- Upload Progress -->
          <div v-if="!id_verification" class="md:col-span-2">
            <div class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
              <h3
                class="text-lg font-medium text-gray-800 dark:text-gray-200 mb-4"
              >
                Verification Progress
              </h3>
              <div
                class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5 mb-6"
              >
                <div
                  class="bg-primary-500 h-2.5 rounded-full transition-all duration-1000"
                  :style="`width: ${calculateProgress()}%`"
                ></div>
              </div>

              <div class="flex flex-wrap gap-4 items-center justify-between">
                <div class="flex items-center space-x-2">
                  <div class="flex items-center">
                    <span
                      class="w-3 h-3 rounded-full"
                      :class="
                        form.front
                          ? 'bg-green-500'
                          : 'bg-gray-300 dark:bg-gray-600'
                      "
                    ></span>
                    <span class="ml-2 text-sm text-gray-600 dark:text-gray-300"
                      >ID Front</span
                    >
                  </div>
                  <div class="flex items-center">
                    <span
                      class="w-3 h-3 rounded-full"
                      :class="
                        form.back
                          ? 'bg-green-500'
                          : 'bg-gray-300 dark:bg-gray-600'
                      "
                    ></span>
                    <span class="ml-2 text-sm text-gray-600 dark:text-gray-300"
                      >ID Back</span
                    >
                  </div>
                  <div class="flex items-center">
                    <span
                      class="w-3 h-3 rounded-full"
                      :class="
                        form.selfie
                          ? 'bg-green-500'
                          : 'bg-gray-300 dark:bg-gray-600'
                      "
                    ></span>
                    <span class="ml-2 text-sm text-gray-600 dark:text-gray-300"
                      >Selfie</span
                    >
                  </div>
                </div>

                <UButton
                  :loading="isLoading"
                  color="primary"
                  variant="solid"
                  class="submit-button"
                  @click="handleUploadSubmit"
                >
                  <UIcon
                    name="i-heroicons-paper-airplane"
                    class="mr-2 icon-float"
                  />
                  Submit Documents
                </UButton>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const toast = useToast();
const { get, put, post } = useApi();
const isLoading = ref(false);
const { user } = useAuth();
const id_verification = ref(false);
const form = ref({
  front: null,
  back: null,
  selfie: null,
  other_document: null,
});
const errors = ref({
  front: false,
  back: false,
  selfie: false,
});
const isAdditionalDocLoading = ref(false);

function calculateProgress() {
  let completed = 0;
  if (form.value.front) completed++;
  if (form.value.back) completed++;
  if (form.value.selfie) completed++;
  return Math.floor((completed / 3) * 100);
}

function handleFileUpload(event, field) {
  const file = event.target.files[0];
  if (!file) return;

  // Check file size (limit to 5MB)
  const maxSize = 5 * 1024 * 1024; // 5MB in bytes
  if (file.size > maxSize) {
    toast.add({
      title: "File size too large. Maximum size is 5MB.",
      type: "error",
    });
    return;
  }

  // Check file type
  const allowedTypes = [
    "image/jpeg",
    "image/png",
    "image/jpg",
    "image/heic",
    "image/heif",
  ];
  if (!allowedTypes.includes(file.type.toLowerCase())) {
    toast.add({
      title: "Please upload a valid image file (JPEG, PNG, HEIC).",
      type: "error",
    });
    return;
  }

  const reader = new FileReader();

  reader.onload = () => {
    // Create an image element to check dimensions
    const img = new Image();
    img.onload = () => {
      // Compress image if needed
      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");

      // Set maximum dimensions
      const maxWidth = 1200;
      const maxHeight = 1200;

      let width = img.width;
      let height = img.height;

      // Calculate new dimensions while maintaining aspect ratio
      if (width > maxWidth || height > maxHeight) {
        if (width > height) {
          height = Math.round((height * maxWidth) / width);
          width = maxWidth;
        } else {
          width = Math.round((width * maxHeight) / height);
          height = maxHeight;
        }
      }

      // Set canvas dimensions
      canvas.width = width;
      canvas.height = height;

      // Draw and compress image
      ctx.drawImage(img, 0, 0, width, height);

      // Convert to base64 with reduced quality
      const compressedBase64 = canvas.toDataURL("image/jpeg", 0.7);

      // Update form value
      form.value[field] = compressedBase64;
    };

    img.src = reader.result;
  };

  reader.onerror = (error) => {
    console.error("Error reading file:", error);
    toast.add({
      title: "Error reading file. Please try again.",
      type: "error",
    });
  };

  reader.readAsDataURL(file);
}

function deleteUpload(field) {
  form.value[field] = null;
}

async function handleUploadSubmit() {
  // Reset validation errors
  errors.value.front = !form.value.front;
  errors.value.back = !form.value.back;
  errors.value.selfie = !form.value.selfie;

  // Check if validation failed
  if (errors.value.front || errors.value.back || errors.value.selfie) {
    toast.add({
      title: "Please fill in all required fields.",
      type: "error",
    });
    return;
  }
  isLoading.value = true;
  try {
    const res = await post(`/add-user-nid/`, form.value);

    if (res.data?.message) {
      toast.add({ title: res.data.message, type: "success" });
      form.value = res.data.data;
    }
  } catch (error) {
    console.error("Error during submission:", error);
    toast.add({
      title: "An error occurred. Please try again later.",
      type: "error",
    });
  }
  isLoading.value = false;
}

async function submitAdditionalDocument() {
  if (!form.value.other_document) {
    toast.add({
      title: "Please upload a document first.",
      type: "error",
    });
    return;
  }

  isAdditionalDocLoading.value = true;
  try {
    // Create payload with only the additional document
    const payload = {
      other_document: form.value.other_document,
    };

    const res = await post(`/add-additional-document/`, payload);

    if (res.data?.message) {
      toast.add({
        title: res.data.message || "Additional document submitted successfully",
        type: "success",
      });
    }
  } catch (error) {
    console.error("Error submitting additional document:", error);
    toast.add({
      title: "An error occurred. Please try again later.",
      type: "error",
    });
  }
  isAdditionalDocLoading.value = false;
}

async function get_nid() {
  try {
    const { data } = await get("/get-user-nid/");

    if (data) {
      form.value = data.data;
      console.log(data.data);

      id_verification.value = Boolean(data.data.approved);

      form.value = {
        front: staticURL + data.data.front,
        back: staticURL + data.data.back,
        selfie: staticURL + data.data.selfie,
        other_document: data.data.other_document
          ? staticURL + data.data.other_document
          : data.data.other_document,
      };
    }
  } catch (error) {
    console.log(error);
  }
}

get_nid();
</script>

<style>
/* Animation Keyframes */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes widthExpand {
  from {
    width: 0;
  }
  to {
    width: 6rem;
  }
}

@keyframes bounceSoft {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-3px);
  }
}

@keyframes progress {
  from {
    width: 0%;
  }
  to {
    width: 100%;
  }
}

/* Animation Classes */
.animate-fade-in-up {
  animation: fadeInUp 0.6s ease-out forwards;
}

.animate-fade-in {
  animation: fadeInUp 0.5s ease-out forwards;
}

.animate-width {
  animation: widthExpand 0.8s ease-out forwards;
  animation-delay: 0.3s;
}

.animate-bounce-subtle {
  animation: bounceSoft 2s infinite ease-in-out;
}

.animate-progress {
  animation: progress 3s infinite ease-in-out alternate;
}

.icon-float {
  animation: bounceSoft 2s infinite ease-in-out;
}

/* Component Styles */
.upload-item {
  @apply space-y-2;
}

.upload-item-header {
  @apply flex justify-between items-center;
}

.upload-status {
  @apply w-3 h-3 rounded-full transition-all duration-300;
}

.upload-container {
  @apply relative rounded-xl border-2 border-dashed border-gray-300 dark:border-gray-600 overflow-hidden transition-all duration-300;
}

.upload-dropzone {
  @apply relative w-full min-h-[160px] bg-gray-50 dark:bg-gray-900/40 flex items-center justify-center cursor-pointer transition-all hover:bg-gray-100 dark:hover:bg-gray-900/60;
}

.submit-button {
  @apply relative overflow-hidden transition-all duration-300 hover:shadow-sm hover:-translate-y-1;
}
</style>
