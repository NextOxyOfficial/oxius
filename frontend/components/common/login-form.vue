<template>
  <div>
    <h1 class="font-bold text-center md:p-5 text-2xl">LOGIN</h1>
    <form
      class="bg-white md:px-8 pt-6 md:pb-8 mb-4"
      @submit.prevent="handleLogin"
    >
      <div class="mb-6">
        <label class="block text-gray-700 text-md font-medium mb-2" for="email">
          EMAIL
        </label>
        <input
          class="w-full py-2 px-3 text-gray-700 bg-[#D9D9D9] rounded-md"
          id="email"
          type="text"
          placeholder="email"
          v-model="email"
        />
      </div>

      <div class="mb-6">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          PASSWORD
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
      <div class="text-center">
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
const email = ref("");
const password = ref("");
const btnDisabled = ref(false);

async function handleLogin() {
  btnDisabled.value = true;
  const res = await login(email.value, password.value);
  console.log(res);

  if (res.loggedIn) {
    if (res.user_type == "user") {
      if (res.is_superuser) {
        navigateTo("/dashboard/admin");
      } else {
        navigateTo("/dashboard/user");
      }
    } else if (res.user_type == "admin") {
      navigateTo("/dashboard/admin");
    } else if (res.user_type == "vendor") {
      navigateTo("/dashboard/vendor");
    }
    toast.add({ title: "Login successful!" });
  } else {
    toast.add({ title: "Invalid credentials", status: "error" });
  }
  btnDisabled.value = false;
}
</script>

<style scoped></style>
