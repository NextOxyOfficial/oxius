<template>
  <div>
    <!-- <form
      @submit.prevent="handleSubmit"
      class="bg-white rounded-xl md:px-8 pt-6 pb-6 md:pb-8 mb-4 px-2 sm:px-8"
    >
      <h1 class="font-bold text-center mb-4 text-2xl">REGISTER</h1>
      <UDivider label="" />
      <div class="my-4">
        <label class="block text-gray-700 text-md font-medium mb-2" for="email">
          Email
        </label>
        <input
          v-model="email"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="email"
          type="email"
          placeholder="Email"
        />
        <p
          v-if="error.email"
          class="text-red-500 text-sm first-letter:uppercase"
        >
          {{ error.email[0] }}
        </p>
      </div>
      <div class="mb-4">
        <label class="block text-gray-700 text-md font-medium mb-2" for="phone">
          Phone
        </label>
        <div class="flex">
          <div>
            <UButton
              size="md"
              variant="solid"
              disabled
              label="+88"
              :ui="{
                rounded: 'rounded-s-md rounded-e-none',
                size: {
                  lg: 'text-base',
                },
              }"
            />
          </div>
          <input
            v-model="phone"
            class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md rounded-s-none"
            id="phone"
            type="phone"
            placeholder="017XXXXXXXX"
          />
        </div>
        <p
          v-if="error.phone"
          class="text-red-500 text-sm first-letter:uppercase"
        >
          {{ error.phone[0] }}
        </p>
      </div>
      <div class="mb-4">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          Password
        </label>
        <input
          v-model="password"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="password"
          type="password"
          placeholder="********"
        />
      </div>
      <div class="mb-4">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="confirm-password"
        >
          Confirm Password
        </label>
        <input
          v-model="confirmPassword"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md mb-3"
          id="confirm-password"
          type="password"
          placeholder="********"
        />
        <p v-if="passwordMismatch" class="text-red-500 text-sm">
          Passwords do not match
        </p>
      </div>
      <div class="mb-4">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          Referral Code
        </label>
        <input
          v-model="refer"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="password"
          type="text"
          placeholder="********"
          readonly
        />
        <p v-if="inValidRefer" class="text-red-500 text-sm">
          Refer Code Is Invalid
        </p>
      </div>
      <div class="text-center !mt-8">
        <button
          class="bg-orange-500 py-1 text-base text-white px-6 capitalize rounded-md"
        >
          Register
        </button>
      </div>
    </form> -->
    <div class="bg-white rounded-2xl shadow-sm p-4 sm:p-8">
      <transition name="fade" mode="out-in">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <div class="space-y-2">
            <h2 class="text-2xl font-semibold text-gray-900">Create account</h2>
            <p class="text-gray-600">Enter your details to register</p>
          </div>

          <div class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <input
                type="text"
                placeholder="First name"
                v-model="form.first_name"
                class="px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                required
              />
              <input
                type="text"
                placeholder="Last name"
                v-model="form.last_name"
                class="px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                required
              />
            </div>

            <input
              type="email"
              placeholder="Email address"
              v-model="form.email"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
              required
            />
            <input
              type="tel"
              placeholder="Phone number"
              v-model="form.phone"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
              required
            />
            <input
              type="password"
              placeholder="Password"
              v-model="form.password"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
              required
            />
            <input
              type="password"
              placeholder="Confirm password"
              v-model="form.confirmPassword"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
              required
            />
            <input
              type="text"
              placeholder="Referral code (optional)"
              v-model="form.refer"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
            />
          </div>

          <UButton
            :loading="isLoading"
            type="submit"
            class="w-full py-3 font-semibold text-sm px-4 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors justify-center"
          >
            Create account
          </UButton>

          <div class="text-center">
            <NuxtLink
              to="/auth/login/"
              class="text-purple-600 hover:text-purple-500 text-sm font-semibold"
            >
              Already have an account? Sign in
            </NuxtLink>
          </div>
        </form>
      </transition>
    </div>
  </div>
</template>

<script setup>
const Api = useApi();
const { login } = useAuth();
const passwordMismatch = ref(false);
const isLoading = ref(false);

const form = ref({
  first_name: "",
  last_name: "",
  email: "",
  phone: "",
  password: "",
  confirmPassword: "",
  refer: "",
});

const error = ref("");

const route = useRoute();
if (route.query.ref) {
  form.value.refer = route.query.ref;
}

const toast = useToast();

// Handle form submission
async function handleSubmit() {
  isLoading.value = true;
  // Check if password and confirm password match
  if (form.value.password !== form.value.confirmPassword) {
    passwordMismatch.value = true;
    return;
  } else {
    passwordMismatch.value = false;
  }

  // Check if email and password are filled
  if (!form.value.email || !form.value.password) {
    toast.add("Please fill out all required fields");
    return;
  }

  const formData = {
    first_name: form.value.first_name,
    last_name: form.value.last_name,
    name: form.value.first_name + " " + form.value.last_name,
    email: form.value.email,
    password: form.value.password,
    username: form.value.email,
    phone: form.value.phone,
    refer: form.value.refer,
  };

  try {
    const res = await Api.post("/auth/register/", formData);
    if (res?.data?.message) {
      error.value = "";
      const res2 = await login(form.value.email, form.value.password);
      if (res2) {
        toast.add({ title: "Login successful!" });
        navigateTo("/");
      }
    } else {
      toast.add({ title: res.error.data.errors.email[0] });
      error.value = res.error.data.errors;
      console.log(res.error.data);
    }
  } catch (error) {
    // set inValidRefer to true if error code from api is 444 (Invalid Refer Code)
    console.error("Error submitting the form:", error);
  }
  isLoading.value = false;
}
</script>
