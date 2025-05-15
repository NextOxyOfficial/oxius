<template>
  <div
    class="sm:min-h-[50vh] flex items-center justify-center bg-gray-50 px-2 sm:px-4 text-sm py-10"
  >
    <div class="max-w-md w-full">
      <div class="bg-white rounded-xl shadow-sm p-3 sm:p-8">
        <transition name="fade" mode="out-in">
          <div>
            <form
              @submit.prevent="handleReset"
              class="space-y-6"
              v-if="!showOtp && resetPasswordToken === ''"
            >
              <div class="space-y-2">
                <h2 class="text-2xl font-semibold text-gray-900">
                  Reset password
                </h2>
                <p class="text-gray-600">
                  Choose how you want to reset your password
                </p>
              </div>

              <div class="space-y-4">
                <div class="flex p-1 bg-gray-100 rounded-lg">
                  <button
                    type="button"
                    @click="form.method = 'email'"
                    :class="[
                      'flex-1 py-2 px-4 rounded-md text-sm font-medium transition-all duration-200 hidden',
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
                @click="sendOtpInstruction"
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
            <form
              v-else-if="showOtp && resetPasswordToken === ''"
              @submit.prevent="handleOTP"
              class="space-y-6"
            >
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
            <form
              v-if="showOtp && resetPasswordToken !== ''"
              @submit.prevent="handleChangePassword"
              class="space-y-6"
            >
              <div class="space-y-2">
                <h2 class="text-2xl font-semibold text-gray-900">
                  Enter New Password
                </h2>
              </div>

              <input
                type="text"
                placeholder="Enter New Password"
                v-model="new_password"
                class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                required
              />

              <button
                type="submit"
                class="w-full py-2 px-4 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors"
              >
                Change Password
              </button>
            </form>
          </div>
        </transition>
      </div>
    </div>
  </div>
</template>

<script setup>
const { post } = useApi();
const showOtp = ref(false);
const resetPasswordToken = ref("");
const new_password = ref("");
const toast = useToast();

const form = ref({
  method: "phone",
  value: "",
});

const sendOtpInstruction = async () => {
  console.log("Sending OTP instruction:", form.value.value);
  const res = await post("/send-otp/", { phone: form.value.value });
  console.log(res);
};

const otpForm = ref({
  otp: "",
});

function handleReset() {
  showOtp.value = true;
}

const handleOTP = async () => {
  console.log("OTP verification attempt:", otpForm.value);
  const { data } = await post("/verify-otp/", {
    phone: form.value.value,
    otp: otpForm.value.otp,
  });
  resetPasswordToken.value = data.token;
  console.log(data.token);
};
const handleChangePassword = async () => {
  console.log("Resetting password with token:", resetPasswordToken.value);
  const { data } = await post("/reset-password/", {
    token: resetPasswordToken.value,
    new_password: new_password.value,
  });
  console.log(data.message);
  if (data.message) {
    toast.add({ title: data.message });
    navigateTo("/auth/login/");
  }
};
</script>

<style scoped></style>
