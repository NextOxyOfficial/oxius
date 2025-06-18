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
            >+8801896144067</a
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

      <!-- Additional Support Section -->
      <!-- <div class="mt-16 mb-20">
        <div class="bg-slate-50 rounded-xl p-8 md:p-12">
          <div class="text-center max-w-3xl mx-auto">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">
              Need Additional Support?
            </h2>
            <p class="text-gray-600 mb-8">
              Our dedicated team is ready to assist you with any questions or
              concerns you may have
            </p>
            <div class="flex flex-col sm:flex-row gap-4 justify-center">
              <button
                class="inline-flex items-center justify-center px-6 py-3 border border-slate-900 text-gray-800 hover:bg-slate-900 hover:text-white rounded-lg font-medium transition-colors duration-300"
              >
                <PhoneIcon class="w-5 h-5 mr-2" />
                Schedule a Call
              </button>
              <button
                class="inline-flex items-center justify-center px-6 py-3 bg-slate-900 text-white hover:bg-slate-800 rounded-lg font-medium transition-colors duration-300"
              >
                <MessageSquareIcon class="w-5 h-5 mr-2" />
                Live Chat
              </button>
            </div>
          </div>
        </div>
      </div> -->
    </div>
  </div>
</template>
<style scoped>
.shadow-sm {
  box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.05),
    0 8px 10px -6px rgb(0 0 0 / 0.05);
}
</style>
