<template>
  <div class="min-h-full bg-white pb-10">
    <!-- Hero Section -->
    <div class="bg-slate-900 py-20">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center">
          <h1 class="text-2xl md:text-5xl font-semibold text-white mb-4">
            {{ $t("customer_support") }}
          </h1>
          <a
            href="tel:+8801896144067"
            class="text-slate-300 text-xl max-w-2xl mx-auto block"
            >+8801896144066</a
          >
          <p class="text-slate-300 text-lg max-w-2xl mx-auto">
            {{ $t("support_text") }}
          </p>
        </div>
      </div>
    </div>

    <!-- Support Options Section -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 -mt-16">
      <div class="grid md:grid-cols-2 gap-8">
        <!-- General Support Card -->
        <div
          class="bg-white rounded-lg shadow-sm py-6 sm:py-8 px-2 border border-slate-100 hover:border-slate-200 transition-all duration-300"
        >
          <div class="flex items-start space-x-5">
            <div class="flex-shrink-0">
              <div class="p-3 bg-slate-50 rounded-lg">
                <UIcon
                  name="i-material-symbols-headphones-rounded"
                  class="w-8 h-8 text-slate-700"
                />
                <!-- <HeadphonesIcon class="w-8 h-8 text-slate-700" /> -->
              </div>
            </div>
            <div class="flex-1">
              <h2 class="text-xl font-semibold text-gray-800 mb-3">
                {{ $t("general_support") }}
              </h2>
              <p class="text-gray-600 mb-4">
                Technical assistance and general inquiries for all our services
              </p>
              <div class="space-y-3">
                <a
                  href="mailto:support@adsyclub.com"
                  class="flex items-center text-slate-700 hover:text-gray-800 group"
                >
                  <UIcon
                    name="i-material-symbols-mail-outline-rounded"
                    class="w-5 h-5 mr-2 text-slate-400 group-hover:text-gray-600"
                  />
                  <!-- <MailIcon
                    class="w-5 h-5 mr-2 text-slate-400 group-hover:text-gray-600"
                  /> -->
                  <span class="font-medium">support@adsyclub.com</span>
                </a>
                <div class="flex items-center text-gray-600">
                  <UIcon
                    name="i-iconoir-clock"
                    class="w-5 h-5 mr-2 text-slate-400"
                  />
                  <!-- <ClockIcon class="w-5 h-5 mr-2 text-slate-400" /> -->
                  <span>24/7 Support Available</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Partnership Card -->
        <div
          class="bg-white rounded-lg shadow-sm py-6 sm:py-8 px-2 border border-slate-100 hover:border-slate-200 transition-all duration-300"
        >
          <div class="flex items-start space-x-5">
            <div class="flex-shrink-0">
              <div class="p-3 bg-slate-50 rounded-lg">
                <UIcon
                  name="i-tabler-building"
                  class="w-8 h-8 text-slate-700"
                />
                <!-- <BuildingIcon class="w-8 h-8 text-slate-700" /> -->
              </div>
            </div>
            <div class="flex-1">
              <h2 class="text-xl font-semibold text-gray-800 mb-3">
                {{ $t("partnership") }}
              </h2>
              <p class="text-gray-600 mb-4">
                Business development and partnership opportunities
              </p>
              <div class="space-y-3">
                <a
                  href="mailto:partnership@adsyclub.com"
                  class="flex items-center text-slate-700 hover:text-gray-800 group"
                >
                  <!-- <MailIcon
                    class="w-5 h-5 mr-2 text-slate-400 group-hover:text-gray-600"
                  /> -->
                  <UIcon
                    name="i-material-symbols-mail-outline-rounded"
                    class="w-5 h-5 mr-2 text-slate-400 group-hover:text-gray-600"
                  />
                  <span class="font-medium">partnership@adsyclub.com</span>
                </a>
                <div class="flex items-center text-gray-600">
                  <UIcon
                    name="i-iconoir-clock"
                    class="w-5 h-5 mr-2 text-slate-400"
                  />
                  <!-- <ClockIcon class="w-5 h-5 mr-2 text-slate-400" /> -->
                  <span>Business Hours: 9AM - 6PM </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Message Submission Form -->
      <div class="mt-16 mb-20">
        <div class="bg-slate-50 rounded-xl p-8 md:p-12">
          <div class="max-w-2xl mx-auto">
            <div class="text-center mb-8">
              <h2 class="text-2xl font-semibold text-gray-800 mb-4">
                Send us a Message
              </h2>
              <p class="text-gray-600">
                Have a question or feedback? We'd love to hear from you. Send us
                a message and we'll respond as soon as possible.
              </p>
            </div>

            <form class="space-y-6">
              <!-- Success Message -->
              <div
                v-if="submitStatus === 'success'"
                class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg"
              >
                <div class="flex items-center">
                  <UIcon name="i-heroicons-check-circle" class="w-5 h-5 mr-2" />
                  <span
                    >Thank you for your message! We'll get back to you
                    soon.</span
                  >
                </div>
              </div>

              <!-- Error Message -->
              <div
                v-if="submitStatus === 'error'"
                class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg"
              >
                <div class="flex items-center">
                  <UIcon name="i-heroicons-x-circle" class="w-5 h-5 mr-2" />
                  <span>{{
                    errorMessage ||
                    "There was an error sending your message. Please try again."
                  }}</span>
                </div>
              </div>

              <!-- Name Field -->
              <div>
                <label
                  for="name"
                  class="block text-sm font-medium text-gray-700 mb-2"
                >
                  Full Name
                </label>
                <div class="relative">
                  <UIcon
                    name="i-material-symbols-person-outline-rounded"
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400"
                  />
                  <input
                    type="text"
                    id="name"
                    v-model="formData.name"
                    placeholder="Enter your full name"
                    class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-slate-500 focus:border-slate-500 transition-colors duration-200 bg-white"
                    required
                  />
                </div>
              </div>

              <!-- Email Field -->
              <div>
                <label
                  for="email"
                  class="block text-sm font-medium text-gray-700 mb-2"
                >
                  Email Address
                </label>
                <div class="relative">
                  <UIcon
                    name="i-material-symbols-mail-outline-rounded"
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400"
                  />
                  <input
                    type="email"
                    id="email"
                    v-model="formData.email"
                    placeholder="your.email@example.com"
                    class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-slate-500 focus:border-slate-500 transition-colors duration-200 bg-white"
                    required
                  />
                </div>
              </div>

              <!-- Phone Number Field -->
              <div>
                <label
                  for="phone"
                  class="block text-sm font-medium text-gray-700 mb-2"
                >
                  Phone Number
                </label>
                <div class="relative">
                  <UIcon
                    name="i-tabler-phone"
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400"
                  />
                  <input
                    type="tel"
                    id="phone"
                    v-model="formData.phone"
                    placeholder="+880 1234 567890"
                    class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-slate-500 focus:border-slate-500 transition-colors duration-200 bg-white"
                    required
                  />
                </div>
              </div>

              <!-- Message Field -->
              <div>
                <label
                  for="message"
                  class="block text-sm font-medium text-gray-700 mb-2"
                >
                  Message
                </label>
                <div class="relative">
                  <textarea
                    id="message"
                    v-model="formData.message"
                    rows="6"
                    maxlength="1000"
                    placeholder="Please describe your question or concern in detail..."
                    class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-slate-500 focus:border-slate-500 transition-colors duration-200 bg-white resize-none"
                    required
                  ></textarea>
                  <div class="absolute bottom-3 right-3 text-xs text-gray-400">
                    {{ formData.message.length }}/1000
                  </div>
                </div>
              </div>

              <!-- Submit Button -->
              <div class="flex justify-center pt-4">
                <button
                  type="submit"
                  @click.prevent="submitMessage"
                  :disabled="isSubmitting"
                  class="inline-flex items-center justify-center px-8 py-3 bg-slate-900 text-white rounded-lg font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <UIcon
                    v-if="isSubmitting"
                    name="i-material-symbols-progress-activity"
                    class="w-5 h-5 mr-2 animate-spin"
                  />
                  <UIcon
                    v-else
                    name="i-material-symbols-send-rounded"
                    class="w-5 h-5 mr-2"
                  />
                  {{ isSubmitting ? "Sending..." : "Send Message" }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { createPublicContact } from "~/services/supportApi";

// Form data
const formData = ref({
  name: "",
  email: "",
  phone: "",
  message: "",
});

// Form submission state
const isSubmitting = ref(false);
const submitStatus = ref(null); // 'success', 'error', or null
const errorMessage = ref("");

// Form validation
const validateForm = () => {
  if (!formData.value.name.trim()) {
    errorMessage.value = "Please enter your full name";
    return false;
  }

  if (!formData.value.email.trim()) {
    errorMessage.value = "Please enter your email address";
    return false;
  }

  // Basic email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(formData.value.email)) {
    errorMessage.value = "Please enter a valid email address";
    return false;
  }

  if (!formData.value.phone.trim()) {
    errorMessage.value = "Please enter your phone number";
    return false;
  }

  if (!formData.value.message.trim()) {
    errorMessage.value = "Please enter your message";
    return false;
  }

  if (formData.value.message.length < 10) {
    errorMessage.value = "Message must be at least 10 characters long";
    return false;
  }

  return true;
};

// Form submission handler
const submitMessage = async () => {
  // Reset status
  submitStatus.value = null;
  errorMessage.value = "";

  // Validate form
  if (!validateForm()) {
    submitStatus.value = "error";
    return;
  }

  isSubmitting.value = true;

  try {
    const response = await createPublicContact(formData.value);

    console.log("Message submitted successfully:", response);

    // Show success message
    submitStatus.value = "success";

    // Reset form after successful submission
    formData.value.name = "";
    formData.value.email = "";
    formData.value.phone = "";
    formData.value.message = "";
  } catch (error) {
    console.error("Error submitting message:", error);
    submitStatus.value = "error";

    // Handle specific error messages
    if (error.data && error.data.message) {
      errorMessage.value = error.data.message;
    } else if (error.message) {
      errorMessage.value = error.message;
    } else {
      errorMessage.value =
        "There was an error sending your message. Please try again.";
    }
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<style scoped>
.shadow-sm {
  box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.05),
    0 8px 10px -6px rgb(0 0 0 / 0.05);
}
</style>
