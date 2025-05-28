<template>
  <div>
    <div
      class="bg-white rounded-xl shadow-sm p-6 sm:p-8 border border-gray-100"
    >
      <transition name="fade" mode="out-in">
        <form @submit.prevent="handleSubmit" class="space-y-8">
          <!-- Form Header -->
          <div class="text-center space-y-2">
            <h2 class="text-2xl font-bold text-gray-800">
              Create Your Account
            </h2>
            <p class="text-gray-500">
              Join our community and enjoy all features
            </p>
            <div class="mt-2 flex justify-center">
              <div class="flex items-center justify-center gap-2">
                <div
                  v-for="(step, index) in steps"
                  :key="index"
                  class="flex items-center"
                >
                  <div
                    :class="[
                      'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
                      currentStep >= index + 1
                        ? 'bg-purple-600 text-white'
                        : 'bg-gray-200 text-gray-600',
                    ]"
                  >
                    {{ index + 1 }}
                  </div>
                  <div
                    v-if="index < steps.length - 1"
                    class="w-12 h-1 mx-1"
                    :class="
                      currentStep > index + 1 ? 'bg-purple-600' : 'bg-gray-200'
                    "
                  ></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Profile Image Upload -->
          <transition name="step" mode="out-in">
            <div v-if="currentStep === 1" class="text-center">
              <div class="flex flex-col items-center gap-4">
                <div class="relative group">
                  <div
                    class="w-32 h-32 rounded-full overflow-hidden bg-gray-100 border-4 border-white shadow-sm mx-auto"
                  >
                    <img
                      v-if="userProfile.image"
                      :src="userProfile.image"
                      alt="Profile"
                      class="w-full h-full object-cover"
                    />
                    <div
                      v-else
                      class="w-full h-full flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-user"
                        class="w-16 h-16 text-gray-400"
                      />
                    </div>
                  </div>
                  <div
                    class="absolute inset-0 flex items-center justify-center rounded-full bg-black bg-opacity-30 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <label
                      for="profile-upload"
                      class="cursor-pointer p-2 rounded-full bg-white text-purple-600 hover:bg-purple-50"
                    >
                      <UIcon name="i-heroicons-camera" class="w-6 h-6" />
                      <input
                        type="file"
                        id="profile-upload"
                        class="hidden"
                        @change="handleFileUpload($event)"
                        accept="image/*"
                      />
                    </label>
                  </div>
                  <button
                    v-if="userProfile.image"
                    type="button"
                    @click="deleteUpload()"
                    class="absolute -right-2 -top-2 bg-red-500 text-white rounded-full p-1 shadow-sm hover:bg-red-600 transition"
                  >
                    <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
                  </button>
                </div>
                <span class="text-sm text-gray-500"
                  >Upload a profile picture (optional)</span
                >
              </div>

              <div class="mt-6 flex justify-between">
                <UButton
                  type="button"
                  variant="ghost"
                  @click="skipStep()"
                  class="text-sm"
                >
                  Skip this step
                </UButton>                <UButton
                  type="button"
                  color="purple"
                  @click="nextStep()"
                  class="text-sm"
                >
                  Continue
                  <UIcon name="i-heroicons-arrow-right" class="w-4 h-4 ml-1" />
                </UButton>
              </div>
            </div>
          </transition>

          <div v-if="currentStep === 2" class="space-y-6">
            <!-- Personal Information Section -->
            <div class="space-y-4">
              <h3 class="text-md font-semibold text-gray-800 border-b pb-2">
                Personal Information
              </h3>

              <div class="grid grid-cols-2 gap-4">
                <div class="relative">
                  <UIcon
                    name="i-heroicons-user"
                    class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                  />
                  <input
                    type="text"
                    placeholder="First name"
                    v-model="form.first_name"
                    class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                  />
                  <p v-if="error.first_name" class="text-red-500 text-sm mt-1">
                    {{ error.first_name }}
                  </p>
                </div>
                <div class="relative">
                  <UIcon
                    name="i-heroicons-user"
                    class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                  />
                  <input
                    type="text"
                    placeholder="Last name"
                    v-model="form.last_name"
                    class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                  />
                  <p v-if="error.last_name" class="text-red-500 text-sm mt-1">
                    {{ error.last_name }}
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="relative">
                  <UIcon
                    name="i-heroicons-envelope"
                    class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                  />
                  <input
                    type="email"
                    placeholder="Email address"
                    v-model="form.email"
                    class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                  />
                  <p v-if="error.email" class="text-red-500 text-sm mt-1">
                    {{ error.email }}
                  </p>
                </div>
                <div class="relative">
                  <UIcon
                    name="i-heroicons-phone"
                    class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                  />
                  <input
                    type="text"
                    placeholder="Phone number"
                    v-model="form.phone"
                    class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                  />
                  <p v-if="error.phone" class="text-red-500 text-sm mt-1">
                    {{ error.phone }}
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <UFormGroup label="" class="space-y-1">
                  <div class="relative">
                    <UIcon
                      name="i-heroicons-calendar"
                      class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                    />
                    <input
                      type="text"
                      size="md"
                      placeholder="Age"
                      v-model="form.age"
                      class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                    />
                  </div>
                  <p v-if="error.age" class="text-red-500 text-sm mt-1">
                    {{ error.age }}
                  </p>
                </UFormGroup>
                <UFormGroup label="" class="space-y-1">
                  <div class="relative">
                    <USelectMenu
                      v-model="form.gender"
                      :options="['Male', 'Female', 'Others']"
                      placeholder="Select Gender"
                      size="xl"
                      :ui="{
                        base: 'w-full relative flex items-center rounded-lg border border-gray-200 focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all',
                        input:
                          'block w-full py-5 pl-10 focus:ring-2 focus:ring-purple-500',
                      }"
                    >
                      <template #leading>
                        <UIcon
                          name="i-heroicons-user-circle"
                          class="z-10 text-gray-400 w-5 h-5"
                        />
                      </template>
                    </USelectMenu>
                  </div>
                  <p v-if="error.gender" class="text-red-500 text-sm mt-1">
                    {{ error.gender }}
                  </p>
                </UFormGroup>
              </div>

              <div class="space-y-4">
                <div class="relative">
                  <UIcon
                    name="i-heroicons-lock-closed"
                    class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                  />
                  <input
                    :type="isPassword ? 'password' : 'text'"
                    placeholder="Password"
                    v-model="form.password"
                    class="w-full pl-10 pr-10 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                  />
                  <div
                    class="absolute inset-y-0 right-0 flex items-center pr-3 cursor-pointer"
                    @click="isPassword = !isPassword"
                  >
                    <UIcon
                      :name="
                        isPassword ? 'i-heroicons-eye' : 'i-heroicons-eye-slash'
                      "
                      class="w-5 h-5 text-gray-500 hover:text-gray-800"
                    />
                  </div>
                  <p v-if="error.password" class="text-red-500 text-sm mt-1">
                    {{ error.password }}
                  </p>
                </div>

                <div class="relative">
                  <UIcon
                    name="i-heroicons-lock-closed"
                    class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                  />
                  <input
                    :type="isPassword ? 'password' : 'text'"
                    placeholder="Confirm password"
                    v-model="form.confirmPassword"
                    class="w-full pl-10 pr-10 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                  />
                  <div
                    class="absolute inset-y-0 right-0 flex items-center pr-3 cursor-pointer"
                    @click="isPassword = !isPassword"
                  >
                    <UIcon
                      :name="
                        isPassword ? 'i-heroicons-eye' : 'i-heroicons-eye-slash'
                      "
                      class="w-5 h-5 text-gray-500 hover:text-gray-800"
                    />
                  </div>
                  <p
                    v-if="error.confirmPassword"
                    class="text-red-500 text-sm mt-1"
                  >
                    {{ error.confirmPassword }}
                  </p>
                </div>
              </div>
            </div>

            <div class="flex justify-between">
              <UButton
                type="button"
                variant="ghost"
                @click="prevStep()"
                class="text-sm"
              >
                <UIcon name="i-heroicons-arrow-left" class="w-4 h-4 mr-1" />
                Back
              </UButton>
              <UButton
                type="button"
                color="purple"
                @click="nextStep()"
                class="text-sm"
              >
                Continue
                <UIcon name="i-heroicons-arrow-right" class="w-4 h-4 ml-1" />
              </UButton>
            </div>
          </div>

          <div v-if="currentStep === 3" class="space-y-6">
            <!-- Address Information -->
            <div class="space-y-4">
              <h3 class="text-md font-semibold text-gray-800 border-b pb-2">
                Address Information
              </h3>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="col-span-1">
                  <UFormGroup label="" class="w-full">
                    <div class="relative">
                      <USelectMenu
                        v-model="form.state"
                        :options="regions"
                        placeholder="State/Region"
                        size="xl"
                        :ui="{
                          base: 'w-full relative flex rounded-md border border-gray-200 focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all',
                          input: 'block w-full py-2.5 pl-10',
                        }"
                        option-attribute="name_eng"
                        value-attribute="name_eng"
                      >
                        <template #leading>
                          <UIcon
                            name="i-heroicons-map"
                            class="z-10 text-gray-400 w-5 h-5"
                          />
                        </template>
                      </USelectMenu>
                    </div>
                  </UFormGroup>
                </div>
                <div class="col-span-1">
                  <UFormGroup label="" class="w-full">
                    <div class="relative">
                      <USelectMenu
                        v-model="form.city"
                        :options="cities"
                        placeholder="City"
                        size="xl"
                        :ui="{
                          base: 'w-full relative flex rounded-md border border-gray-200 focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all',
                          input: 'block w-full py-2.5 pl-10',
                        }"
                        option-attribute="name_eng"
                        value-attribute="name_eng"
                      >
                        <template #leading>
                          <UIcon
                            name="i-heroicons-building-office"
                            class="z-10 text-gray-400 w-5 h-5"
                          />
                        </template>
                      </USelectMenu>
                    </div>
                  </UFormGroup>
                </div>
                <div class="col-span-1">
                  <UFormGroup label="" class="w-full">
                    <div class="relative">
                      <USelectMenu
                        v-model="form.upazila"
                        :options="upazilas"
                        placeholder="Area/Upazila"
                        size="xl"
                        :ui="{
                          base: 'w-full relative flex rounded-md border border-gray-200 focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all',
                          input: 'block w-full py-2.5 pl-10',
                          shadow: '',
                        }"
                        option-attribute="name_eng"
                        value-attribute="name_eng"
                      >
                        <template #leading>
                          <UIcon
                            name="i-heroicons-map-pin"
                            class="z-10 text-gray-400 w-5 h-5"
                          />
                        </template>
                      </USelectMenu>
                    </div>
                  </UFormGroup>
                </div>
                <div class="col-span-1">
                  <UFormGroup label="" class="w-full">
                    <div class="relative">
                      <UIcon
                        name="i-heroicons-envelope"
                        class="absolute left-3 top-3 z-10 text-gray-400 w-5 h-5"
                      />
                      <input
                        type="text"
                        size="md"
                        placeholder="Zip/Postal Code"
                        v-model="form.zip"
                        class="w-full pl-10 pr-10 py-2.5 border border-gray-200 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                      />
                    </div>
                  </UFormGroup>
                </div>
                <div class="col-span-2">
                  <UFormGroup label="" class="w-full">
                    <div class="relative">
                      <UIcon
                        name="i-heroicons-home"
                        class="absolute left-3 top-3 z-10 text-gray-400 w-5 h-5"
                      />
                      <input
                        type="text"
                        size="md"
                        placeholder="Full Address"
                        v-model="form.address"
                        class="w-full pl-10 pr-10 py-2.5 border border-gray-200 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                      />
                    </div>
                  </UFormGroup>
                </div>
              </div>

              <div class="relative mt-4">
                <UIcon
                  name="i-heroicons-ticket"
                  class="absolute left-3 top-3 text-gray-400 w-5 h-5"
                />
                <input
                  type="text"
                  placeholder="Referral code (optional)"
                  v-model="form.refer"
                  class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                />
                <p v-if="error.refer" class="text-red-500 text-sm mt-1">
                  {{ error.refer }}
                </p>
              </div>
            </div>

            <p
              v-if="submitError"
              class="text-center p-3 bg-red-50 text-red-600 rounded-md border border-red-100 text-sm"
            >
              {{ submitError }}
            </p>

            <div class="flex justify-between">
              <UButton
                type="button"
                variant="ghost"
                @click="prevStep()"
                class="text-sm"
              >
                <UIcon name="i-heroicons-arrow-left" class="w-4 h-4 mr-1" />
                Back
              </UButton>
              <UButton
                :loading="isLoading"
                type="submit"
                color="purple"
                class="text-sm px-6 py-2.5 font-semibold"
                :class="{ 'opacity-75 cursor-not-allowed': isLoading }"
              >
                <UIcon name="i-heroicons-user-plus" class="w-5 h-5 mr-1" />
                Complete Registration
              </UButton>
            </div>
          </div>

          <div class="text-center mt-4">
            <NuxtLink
              to="/auth/login/"
              class="text-purple-600 hover:text-purple-500 text-sm font-medium flex items-center justify-center gap-1 hover:underline"
            >
              <UIcon name="i-heroicons-arrow-left-circle" class="w-4 h-4" />
              Already have an account? Sign in
            </NuxtLink>
          </div>
        </form>
      </transition>
    </div>
  </div>
</template>

<script setup>
const { get, post } = useApi();
const { login } = useAuth();
const isPassword = ref(true);
const isLoading = ref(false);

// Multi-step form implementation
const steps = ref(["Profile Photo", "Personal Info", "Address Info"]);
const currentStep = ref(1);

function nextStep() {
  if (currentStep.value < steps.value.length && validateCurrentStep()) {
    currentStep.value++;
  }
}

function prevStep() {
  if (currentStep.value > 1) {
    currentStep.value--;
  }
}

function skipStep() {
  // Skip validation and force move to next step
  if (currentStep.value < steps.value.length) {
    currentStep.value++;
  }
}

// Validate current step when moving to next
function validateCurrentStep() {
  if (currentStep.value === 1) {
    // Photo is optional, so we can always proceed
    return true;
  } else if (currentStep.value === 2) {
    // Validate personal info
    let isValid = true;

    error.value.first_name = !form.value.first_name
      ? "First name is required"
      : "";
    error.value.last_name = !form.value.last_name
      ? "Last name is required"
      : "";
    error.value.email = !form.value.email ? "Email is required" : "";

    const phoneNumberValid = /^(?:\+?88)?01[3-9]\d{8}$/;
    error.value.phone = !form.value.phone
      ? "Phone number is required"
      : !phoneNumberValid.test(form.value.phone)
      ? "Invalid phone number"
      : "";

    error.value.password = !form.value.password ? "Password is required" : "";
    error.value.confirmPassword = !form.value.confirmPassword
      ? "Confirm password is required"
      : form.value.password !== form.value.confirmPassword
      ? "Passwords do not match"
      : "";

    const ageValid = /^\d+$/;
    error.value.age = !form.value.age
      ? "Age is required"
      : !ageValid.test(+form.value.age)
      ? "Invalid age"
      : "";

    error.value.gender = !form.value.gender ? "Gender is required" : "";

    // Check if any validation errors
    isValid = !Object.values(error.value).some((err) => err);
    return isValid;
  }
  return true;
}

const form = ref({
  first_name: "",
  last_name: "",
  email: "",
  phone: "",
  password: "",
  confirmPassword: "",
  age: "",
  gender: "",
  refer: "",
  country: "Bangladesh",
  state: "",
  city: "",
  upazila: "",
  zip: "",
  address: "",
});

const userProfile = ref({
  image: null, // Explicitly set to null to ensure it's handled properly
});

const error = ref({
  first_name: "",
  last_name: "",
  email: "",
  phone: "",
  password: "",
  confirmPassword: "",
  age: "",
  gender: "",
  refer: "",
});

const submitError = ref("");

const route = useRoute();
if (route.query.ref) {
  form.value.refer = route.query.ref;
}

const toast = useToast();

// geo filter
const regions = ref([]);
const cities = ref();
const upazilas = ref();

const regions_response = await get(
  `/geo/regions/?country_name_eng=${form.value.country}`
);
regions.value = regions_response.data;

if (form.value.state) {
  const cities_response = await get(
    `/geo/cities/?region_name_eng=${form.value.state}`
  );
  cities.value = cities_response.data;
}

if (form.value.city) {
  const thana_response = await get(
    `/geo/upazila/?city_name_eng=${form.value.city}`
  );
  upazilas.value = thana_response.data;
}

watch(
  () => form.value.state,
  async (newState) => {
    if (newState) {
      const cities_response = await get(
        `/geo/cities/?region_name_eng=${newState}`
      );
      cities.value = cities_response.data;
    }
  }
);

watch(
  () => form.value.city,
  async (newCity) => {
    if (newCity) {
      const thana_response = await get(
        `/geo/upazila/?city_name_eng=${newCity}`
      );
      upazilas.value = thana_response.data;
    }
  }
);

// Handle form submission
async function handleSubmit() {
  isLoading.value = true;

  // Validate all fields before submission
  error.value = {
    first_name: "",
    last_name: "",
    email: "",
    phone: "",
    password: "",
    confirmPassword: "",
    age: "",
    gender: "",
    refer: "",
  };

  const phoneNumberValid = /^(?:\+?88)?01[3-9]\d{8}$/;
  const ageValid = /^\d+$/;

  // Validate fields
  if (!form.value.first_name) error.value.first_name = "First name is required";
  if (!form.value.last_name) error.value.last_name = "Last name is required";
  if (!form.value.email) error.value.email = "Email is required";
  if (!form.value.phone) error.value.phone = "Phone number is required";
  if (!phoneNumberValid.test(form.value.phone))
    error.value.phone = "Invalid phone number";
  if (!form.value.password) error.value.password = "Password is required";
  if (!form.value.confirmPassword)
    error.value.confirmPassword = "Confirm password is required";
  if (form.value.password !== form.value.confirmPassword) {
    error.value.confirmPassword = "Passwords do not match";
  }
  if (!form.value.age) error.value.age = "Age is required";
  if (!ageValid.test(+form.value.age)) error.value.age = "Invalid age";
  if (!form.value.gender) error.value.gender = "Gender is required";

  // If any error exists, stop submission
  if (Object.values(error.value).some((err) => err)) {
    isLoading.value = false;
    // Move to the step that has errors
    if (
      error.value.first_name ||
      error.value.last_name ||
      error.value.email ||
      error.value.phone ||
      error.value.password ||
      error.value.confirmPassword ||
      error.value.age ||
      error.value.gender
    ) {
      currentStep.value = 2;
    }
    return;
  }  // Create formData without the image first
  const formData = {
    first_name: form.value.first_name,
    last_name: form.value.last_name,
    name: form.value.first_name + " " + form.value.last_name,
    email: form.value.email,
    password: form.value.password,
    username: form.value.email,
    phone: form.value.phone,
    refer: form.value.refer,
    age: +form.value.age,
    gender: form.value.gender,
    // Don't include image field if it's not provided
    country: form.value.country,
    city: form.value.city,
    state: form.value.state,
    upazila: form.value.upazila,
    zip: form.value.zip,
    address: form.value.address,
  };
  
  // Only add image if it actually exists
  if (userProfile.value.image) {
    formData.image = userProfile.value.image;
  }  try {
    // Try to register the user
    let res;
    try {
      res = await post("/auth/register/", formData);
    } catch (registrationError) {
      console.error("Registration error:", registrationError);
      // Check if the error is related to the profile image
      if (registrationError.response?.data?.error?.includes('image') || 
          registrationError.message?.includes('startswith') ||
          (registrationError.message && registrationError.message.toLowerCase().includes('nonetype'))) {
        // If there's an image-related error and we have an image field, remove it
        if ('image' in formData) {
          delete formData.image;
        }
        // Try again without the image
        res = await post("/auth/register/", formData);
      } else {
        // Re-throw the error if it's about something else
        throw registrationError;
      }
    }

    if (res?.data?.message) {
      error.value = {
        first_name: "",
        last_name: "",
        email: "",
        phone: "",
        password: "",
        confirmPassword: "",
        age: "",
        gender: "",
        refer: "",
      };

      const res2 = await login(form.value.email, form.value.password);
      if (res2) {
        const res = await post(`/send-sms/?phone=${form.value.phone}`);
        toast.add({
          title: "Registration successful!",
          description: "Welcome to ADSY Club",
          color: "green",
        });
        navigateTo("/");
      }
    } else {
      submitError.value =
        res.error?.data?.error || "An error occurred during registration";
    }
  } catch (err) {
    if (err.response?.status === 444) {
      error.value.refer = "Invalid referral code";
      currentStep.value = 3; // Go to referral step
    } else {
      submitError.value =
        err.response?.data?.message || "An error occurred. Please try again.";
      console.error("Error submitting the form:", err);
    }
  }
  isLoading.value = false;
}

function handleFileUpload(event) {
  const files = Array.from(event.target.files);
  if (files.length === 0) return;

  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    try {
      // Make sure the result is a valid string
      if (typeof reader.result === 'string' && reader.result.startsWith('data:')) {
        userProfile.value.image = reader.result;
      } else {
        console.error("Invalid file format");
        toast.add({
          title: "Warning",
          description: "Invalid file format. Using default profile.",
          color: "orange",
        });
        // Don't set an invalid image
        userProfile.value.image = null;
      }
    } catch (error) {
      console.error("Error processing uploaded file:", error);
      userProfile.value.image = null;
    }
  };

  // Event listener for errors
  reader.onerror = (error) => {
    console.error("Error reading file:", error);
    toast.add({
      title: "Error",
      description: "Failed to upload image",
      color: "red",
    });
    userProfile.value.image = null;
  };

  try {
    // Read the file as a data URL (Base64 string)
    reader.readAsDataURL(files[0]);
  } catch (error) {
    console.error("Error reading file:", error);
    userProfile.value.image = null;
  }
}

function deleteUpload() {
  userProfile.value.image = null;
}
</script>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Form field focus animation */
input:focus,
.select:focus {
  transition: all 0.3s ease;
  box-shadow: 0 0 0 2px rgba(124, 58, 237, 0.2);
}

/* Button hover effects */
button {
  transition: all 0.3s ease;
}

/* Step transition */
@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes slideOut {
  from {
    opacity: 1;
    transform: translateX(0);
  }
  to {
    opacity: 0;
    transform: translateX(-20px);
  }
}

.step-enter-active {
  animation: slideIn 0.3s ease-out forwards;
}

.step-leave-active {
  animation: slideOut 0.3s ease-out forwards;
}
</style>
