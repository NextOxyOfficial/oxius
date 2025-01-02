<template>
  <UContainer class="mt-10 mb-16">
    <h1 class="text-center text-4xl my-8">{{ $t("customer_support") }}</h1>
    <UDivider label="" class="mb-8" />
    <p class="text-center text-base first-letter:capitalize lowercase">
      Get Help and Support for All Your Service Needs
    </p>
    <div
      class="flex flex-col md:flex-row gap-5 items-center justify-evenly my-5"
    >
      <div class="text-center border border-dashed p-4 rounded-md shadow">
        <p class="text-lg font-semibold">General Support</p>
        <p>support@adsyclub.com</p>
      </div>
      <div class="text-center border border-dashed p-4 rounded-md shadow">
        <p class="text-lg font-semibold">Partnership</p>
        <p>partnership@adsyclub.com</p>
      </div>
    </div>
  </UContainer>
</template>
