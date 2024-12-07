<template>
  <div>
    <h1 class="font-bold text-center md:p-5 text-2xl">REGISTER</h1>
    <form
      @submit.prevent="handleSubmit"
      class="bg-white md:px-8 pt-6 md:pb-8 mb-4"
    >
      <div class="mb-4">
        <label class="block text-gray-700 text-md font-medium mb-2" for="email">
          EMAIL
        </label>
        <input
          v-model="email"
          class="w-full py-2 px-3 text-gray-700 bg-[#D9D9D9] rounded-md"
          id="email"
          type="email"
          placeholder="Email"
        />
      </div>
      <div class="mb-4">
        <label class="block text-gray-700 text-md font-medium mb-2" for="email">
          Phone
        </label>
        <div class="flex">
          <div>
            <UButton
              size="lg"
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
            class="w-full py-2 px-3 text-gray-700 bg-[#D9D9D9] rounded-md rounded-s-none"
            id="phone"
            type="phone"
            placeholder="017XXXXXXXX"
          />
        </div>
      </div>
      <div class="mb-4">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          PASSWORD
        </label>
        <input
          v-model="password"
          class="w-full py-2 px-3 text-gray-700 bg-[#D9D9D9] rounded-md"
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
          CONFIRM PASSWORD
        </label>
        <input
          v-model="confirmPassword"
          class="w-full py-2 px-3 text-gray-700 bg-[#D9D9D9] rounded-md mb-3"
          id="confirm-password"
          type="password"
          placeholder="********"
        />
        <p v-if="passwordMismatch" class="text-red-500 text-sm">
          Passwords do not match
        </p>
      </div>
      <div class="text-center">
        <button
          class="bg-orange-500 p-2 text-lg text-white px-10 uppercase rounded-md"
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
const password = ref("");
const confirmPassword = ref("");
const passwordMismatch = ref(false);

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
  };

  try {
    const res = await Api.post("/api/auth/register/", formData);
    console.log(res);
    if (res.data.message) {
      const res2 = await login(email.value, password.value);
      if (res2) {
        toast.add({ title: res.data.message });
        if (res2.loggedIn) {
          if (res2.user_type == "user") {
            if (res2.is_superuser) {
              navigateTo("/dashboard/admin");
            } else {
              navigateTo("/dashboard/user");
            }
          } else if (res2.user_type == "admin") {
            navigateTo("/dashboard/admin");
          } else if (res2.user_type == "vendor") {
            navigateTo("/dashboard/vendor");
          }
          toast.add({ title: "Login successful!" });
        }
      }
    }
  } catch (error) {
    console.error("Error submitting the form:", error);
  }
}
</script>
