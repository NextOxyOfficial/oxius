<template>
  <div
    class="sm:min-h-[50vh] flex items-center justify-center bg-gray-50 px-2 sm:px-4 text-sm py-10"
  >
    <div class="max-w-md w-full">
      <div class="bg-white rounded-2xl shadow-sm p-3 sm:p-8">
        <transition name="fade" mode="out-in">
          <form @submit.prevent="handleReset" class="space-y-6" v-if="!showOtp">
            <div class="space-y-2">
              <h2 class="text-2xl font-semibold text-gray-900">
                Reset password
              </h2>
              <p class="text-gray-600">
                Choose how you want to reset your password
              </p>
            </div>

            <div class="space-y-4">
              <div class="flex space-x-4 p-1 bg-gray-100 rounded-lg">
                <button
                  type="button"
                  @click="form.method = 'email'"
                  :class="[
                    'flex-1 py-2 px-4 rounded-md text-sm font-medium transition-all duration-200',
                    form.method === 'email'
                      ? 'bg-white shadow-sm text-gray-900'
                      : 'text-gray-500 hover:text-gray-900',
                  ]"
                >
                  Email
                </button>
                <button
                  type="button"
                  @click="form.method = 'phone'"
                  :class="[
                    'flex-1 py-2 px-4 rounded-md text-sm font-medium transition-all duration-200',
                    form.method === 'phone'
                      ? 'bg-white shadow-sm text-gray-900'
                      : 'text-gray-500 hover:text-gray-900',
                  ]"
                >
                  Phone
                </button>
              </div>

              <transition name="fade" mode="out-in">
                <div v-if="form.method === 'email'" key="email">
                  <input
                    type="email"
                    placeholder="Enter your email"
                    v-model="form.value"
                    class="w-full px-3 text-base md:text-sm py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                    required
                  />
                </div>
                <div v-else key="phone">
                  <input
                    type="tel"
                    placeholder="Enter your phone number"
                    v-model="form.value"
                    class="w-full px-3 text-base md:text-sm py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                    required
                  />
                </div>
              </transition>
            </div>

            <button
              type="submit"
              class="w-full py-3 text-sm font-semibold px-4 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors"
            >
              Send reset instructions
            </button>

            <div class="text-center">
              <NuxtLink
                to="/auth/login/"
                class="text-purple-600 hover:text-purple-500 text-sm font-semibold"
              >
                Back to sign in
              </NuxtLink>
            </div>
          </form>
          <form v-else @submit.prevent="handleOTP" class="space-y-6">
            <div class="space-y-2">
              <h2 class="text-2xl font-semibold text-gray-900">
                Enter verification code
              </h2>
              <p class="text-gray-600">
                We sent a code to your {{ form.method }}
              </p>
            </div>

            <input
              type="text"
              placeholder="Enter verification code"
              v-model="otpForm.otp"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
              required
            />

            <button
              type="submit"
              class="w-full py-2 px-4 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors"
            >
              Verify code
            </button>

            <div class="text-center">
              <a
                href="#"
                @click.prevent="handleReset"
                class="text-purple-600 hover:text-purple-500 text-sm"
              >
                Didn't receive a code? Send again
              </a>
            </div>
          </form>
        </transition>
      </div>
    </div>
  </div>
</template>

<script setup>
const showOtp = ref(false);
const form = ref({
  method: "email",
  value: "",
});

const otpForm = ref({
  otp: "",
});

function handleReset() {
  showOtp.value = true;
}

const handleOTP = () => {
  console.log("OTP verification attempt:", otpForm.value);
  otpForm.value = "login";
};
</script>

<style scoped></style>
