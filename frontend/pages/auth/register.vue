<template>
  <UContainer>
    <div class="flex flex-col-reverse md:flex-row gap-8 py-5 md:py-0">
      <div class="md:w-3/4">
        <div
          class="w-full h-full bg-[url('/images/loginSofa.png')] bg-no-repeat transform -scale-x-100 bg-bottom bg-contain"
        ></div>
      </div>
      <CommonRegisterForm />
    </div>
  </UContainer>
</template>

<script setup>
// const { user } = useAuth();

// if (user) {
//   navigateTo("/");
// }
</script>
