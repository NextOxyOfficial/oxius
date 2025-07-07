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
            <!-- Success Message -->
            <div v-if="formSubmitted" class="text-center">
              <div class="mb-6">
                <div class="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
                  <UIcon
                    name="i-material-symbols-check-circle-outline-rounded"
                    class="w-8 h-8 text-green-600"
                  />
                </div>
                <h2 class="text-2xl font-semibold text-gray-800 mb-4">
                  Message Sent Successfully!
                </h2>
                <div class="bg-white rounded-lg p-6 border border-green-200">
                  <p class="text-gray-700 mb-4">
                    Thank you for contacting us! Your message has been received and a support ticket has been created.
                  </p>
                  <div class="bg-green-50 rounded-lg p-4 border border-green-200">
                    <div class="flex items-center justify-between">
                      <div>
                        <p class="text-sm text-gray-600 mb-1">Support Ticket ID:</p>
                        <p class="font-mono text-lg font-semibold text-green-700">{{ ticketId }}</p>
                      </div>
                      <UIcon
                        name="i-material-symbols-content-copy-outline-rounded"
                        class="w-5 h-5 text-green-600 cursor-pointer hover:text-green-700"
                        @click="copyTicketId"
                      />
                    </div>
                  </div>
                  <div class="mt-4 text-sm text-gray-600">
                    <p class="mb-2">
                      <strong>What happens next?</strong>
                    </p>
                    <ul class="list-disc list-inside space-y-1 text-left">
                      <li>Our support team will review your message within 24 hours</li>
                      <li>You'll receive an email confirmation with your ticket details</li>
                      <li>We'll respond to your inquiry as soon as possible</li>
                    </ul>
                  </div>
                </div>
                <button
                  @click="resetForm"
                  class="mt-6 inline-flex items-center justify-center px-6 py-3 bg-slate-900 text-white rounded-lg font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 transition-colors duration-200"
                >
                  <UIcon
                    name="i-material-symbols-add-circle-outline-rounded"
                    class="w-5 h-5 mr-2"
                  />
                  Send Another Message
                </button>
              </div>
            </div>

            <!-- Contact Form -->
            <div v-else>
              <div class="text-center mb-8">
                <h2 class="text-2xl font-semibold text-gray-800 mb-4">
                  Send us a Message
                </h2>
                <p class="text-gray-600">
                  Have a question or feedback? We'd love to hear from you. Send us
                  a message and we'll respond as soon as possible.
                </p>
              </div>

              <form class="space-y-6" @submit.prevent="submitMessage">
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

                <!-- Subject Field -->
                <div>
                  <label
                    for="subject"
                    class="block text-sm font-medium text-gray-700 mb-2"
                  >
                    Subject
                  </label>
                  <div class="relative">
                    <UIcon
                      name="i-material-symbols-subject-rounded"
                      class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400"
                    />
                    <input
                      type="text"
                      id="subject"
                      v-model="formData.subject"
                      placeholder="Brief description of your inquiry"
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
                    :disabled="isSubmitting"
                    class="inline-flex items-center justify-center px-8 py-3 bg-slate-900 text-white rounded-lg font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed transform hover:scale-105"
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
                    {{ isSubmitting ? "Processing..." : "Send Message" }}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";

// Use the API composable
const { post } = useApi();
const toast = useToast();

// Form data
const formData = ref({
  name: "",
  email: "",
  phone: "",
  subject: "",
  message: "",
});

// Form submission state
const isSubmitting = ref(false);
const formSubmitted = ref(false);
const ticketId = ref("");

// Toast function
const showToast = (title, description, color, timeout = 3000) => {
  toast.add({
    title,
    description,
    color,
    timeout,
  });
};

// Form validation
const validateForm = () => {
  if (!formData.value.name.trim()) {
    showToast("Validation Error", "Please enter your full name", "red");
    return false;
  }

  if (!formData.value.email.trim()) {
    showToast("Validation Error", "Please enter your email address", "red");
    return false;
  }

  // Basic email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(formData.value.email)) {
    showToast("Validation Error", "Please enter a valid email address", "red");
    return false;
  }

  if (!formData.value.phone.trim()) {
    showToast("Validation Error", "Please enter your phone number", "red");
    return false;
  }

  if (!formData.value.subject.trim()) {
    showToast("Validation Error", "Please enter a subject", "red");
    return false;
  }

  if (!formData.value.message.trim()) {
    showToast("Validation Error", "Please enter your message", "red");
    return false;
  }

  if (formData.value.message.length < 10) {
    showToast(
      "Validation Error",
      "Message must be at least 10 characters long",
      "red"
    );
    return false;
  }

  return true;
};

// Generate ticket ID
const generateTicketId = () => {
  const prefix = "TKT";
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substr(2, 4).toUpperCase();
  return `${prefix}-${timestamp}-${random}`;
};

// Copy ticket ID to clipboard
const copyTicketId = async () => {
  try {
    await navigator.clipboard.writeText(ticketId.value);
    showToast("Copied!", "Ticket ID copied to clipboard", "green", 2000);
  } catch (error) {
    console.error("Failed to copy ticket ID:", error);
    showToast("Error", "Failed to copy ticket ID", "red");
  }
};

// Reset form to initial state
const resetForm = () => {
  formSubmitted.value = false;
  ticketId.value = "";
  formData.value = {
    name: "",
    email: "",
    phone: "",
    subject: "",
    message: "",
  };
};

// Form submission handler
const submitMessage = async () => {
  // Validate form
  if (!validateForm()) {
    return;
  }

  isSubmitting.value = true;

  // Show spinner for 2 seconds before actual submission
  await new Promise(resolve => setTimeout(resolve, 2000));

  try {
    const { data, error } = await post("/public-contact/", formData.value);

    if (error) {
      console.error("Error submitting message:", error);
      showToast(
        "Error",
        error.data?.message || "Failed to send message. Please try again.",
        "red"
      );
      isSubmitting.value = false;
    } else {
      console.log("Message submitted successfully:", data);

      // Generate ticket ID
      ticketId.value = generateTicketId();

      // Hide form and show success message
      formSubmitted.value = true;

      // Show success toast
      showToast(
        "Success!",
        "Your message has been sent and a support ticket has been created.",
        "green",
        5000
      );

      isSubmitting.value = false;
    }
  } catch (error) {
    console.error("Error submitting message:", error);
    showToast(
      "Error",
      "An unexpected error occurred. Please try again.",
      "red"
    );
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
