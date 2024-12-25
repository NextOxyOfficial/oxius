<template>
  <div>
    <h1 class="font-bold text-center md:p-5 text-2xl">LOGIN</h1>
    <form
      class="bg-white md:px-8 pt-6 md:pb-8 mb-4"
      @submit.prevent="handleLogin"
    >
      <div class="mb-6">
        <label class="block text-gray-700 text-md font-medium mb-2" for="email">
          Email
        </label>
        <input
          class="w-full py-2 px-3 text-gray-700 bg-[#D9D9D9] rounded-md"
          id="email"
          type="text"
          placeholder="abc@example.com"
          v-model="username"
        />
      </div>

      <div class="mb-2">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          Password
        </label>
        <input
          class="w-full py-2 px-3 text-gray-700 bg-[#D9D9D9] rounded-md"
          id="password"
          type="password"
          placeholder="********"
          v-model="password"
        />
        <a
          class="inline-block align-baseline font-medium tracking-wide text-md text-black"
          href="#"
        >
          Forgot Password?
        </a>
      </div>
      <p class="text-red-500 text-sm md:text-base">{{ error }}</p>
      <div class="text-center mt-6">
        <button
          class="bg-orange-500 p-2 text-lg text-white px-10 uppercase rounded-md"
          :disabled="btnDisabled"
        >
          Sign In
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
const { login } = useAuth();
const toast = useToast();
const username = ref("");
const password = ref("");
const btnDisabled = ref(false);
const error = ref("");

async function handleLogin() {
  btnDisabled.value = true;
  try {
    const res = await login(username.value, password.value);
    if (res.loggedIn) {
      navigateTo("/");
      toast.add({ title: "Login successful!" });
      error.value = "";
    } else {
      toast.add({ title: res._value.data.error, status: "error" });
      error.value = res._value.data.error;
    }
  } catch (error) {
    console.log("error:", error);
  }
  btnDisabled.value = false;
}
</script>

<style scoped></style>
