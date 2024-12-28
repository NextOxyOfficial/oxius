<template>
  <div>
    <form
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
    </form>
  </div>
</template>

<script setup>
const Api = useApi();
const { login } = useAuth();

const email = ref("");
const phone = ref("");
const password = ref("");
const confirmPassword = ref("");
const refer = ref("");
const passwordMismatch = ref(false);
const inValidRefer = ref(false);
const error = ref("");

const route = useRoute();
if (route.query.ref) {
  refer.value = route.query.ref;
}

const toast = useToast();

// Handle form submission
async function handleSubmit() {
  // Check if password and confirm password match
  if (password.value !== confirmPassword.value) {
    passwordMismatch.value = true;
    return;
  } else {
    passwordMismatch.value = false;
  }

  // Check if email and password are filled
  if (!email.value || !password.value) {
    toast.add("Please fill out all required fields");
    return;
  }

  const formData = {
    email: email.value,
    password: password.value,
    username: email.value,
    phone: phone.value,
    refer: refer.value,
  };

  try {
    const res = await Api.post("/auth/register/", formData);
    if (res?.data?.message) {
      error.value = "";
      const res2 = await login(email.value, password.value);
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
}
</script>
