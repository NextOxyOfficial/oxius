<template>
  <footer class="py-10 bg-slate-100">
    <UContainer>
      <div class="mb-8">
        <UHorizontalNavigation
          :links="links[1].items"
          :ui="{
            base: 'before:hidden text-base lg:text-xl font-normal hover:text-green-500',
            padding: 'px-1',
            inactive: 'hover:text-green-300 after:hidden',
            active: 'after:hidden',
            wrapper: 'justify-center',
          }"
          class="w-full !bg-transparent hidden md:flex"
        />
        <UVerticalNavigation
          :links="links[1].items"
          :ui="{
            base: 'before:hidden text-base justify-center lg:text-xl font-normal hover:text-green-500',
            padding: 'px-1',
            inactive: 'hover:text-green-300 after:hidden',
            active: 'after:hidden',
            wrapper: 'justify-center',
          }"
          class="w-full !bg-transparent md:hidden"
        />
      </div>

      <div
        class="flex flex-col sm:flex-row justify-between gap-5 lg:gap-12 sm:items-center px-[7px] max-w-5xl mx-auto"
      >
        <div class="flex flex-col gap-4">
          <h4 class="font-bold hidden md:block">Download Our App</h4>
          <ul class="flex gap-2 flex-1 max-md:justify-center">
            <li class="w-[90px] md:w-[117px]">
              <img
                src="/apple.png"
                class="mx-auto w-[90px] md:w-[117px]"
                quality="100"
                format="webp"
                alt="App"
              />
            </li>
            <li class="w-[90px] md:w-[119px]">
              <img
                src="/google.png"
                class="mx-auto w-[90px] md:w-[119px]"
                quality="100"
                format="webp"
                alt="App"
              />
            </li>
          </ul>
        </div>
        <div class="">
          <div class="flex flex-col gap-4">
            <h4 class="font-bold hidden md:block text-center">We Accept</h4>
            <NuxtImg
              src="/payment.png"
              quality="100"
              format="webp"
              alt="Payment"
              class="md:w-[370px]"
            />
          </div>
        </div>
      </div>

      <div>
        <UHorizontalNavigation
          :ui="{
            base: 'before:hidden  text-sm lg:text-base font-normal hover:text-green-500',
            padding: 'px-1',
            inactive: 'hover:text-green-300 after:hidden',
            active: 'after:hidden',
            wrapper: 'justify-center',
          }"
          :links="privacy"
        />
      </div>
      <UDivider label="" />
      <p class="text-center py-6">
        Developed With
        <UIcon name="i-solar:hearts-bold" class="text-red-500" />
        By Lyricz Softwares & Technology Limited ©
        {{ new Date().getFullYear() }}
      </p>
    </UContainer>
  </footer>
</template>

<script setup>
const toggleStatus = ref("");

function toggleLink(title) {
  if (toggleStatus.value === title) {
    toggleStatus.value = "";
  } else {
    toggleStatus.value = title;
  }
  console.log(this.nextElementSibling);
}

watch(toggleStatus, () => {
  console.log("State Changed");
});

const privacy = [
  {
    label: "Terms & Conditions",
    to: "/terms",
  },
  {
    label: "Privacy Policy",
    to: "/privacy",
  },
];

const links = [
  {
    title: "Contact Us",
  },
  {
    title: "Services",
    items: [
      {
        label: "Classified Services",
        to: "/",
      },
      {
        label: "Earn Money",
        to: "/",
      },
      {
        label: "Affiliates",
        to: "/",
      },

      {
        label: "About Us",
        to: "/about",
      },
      {
        label: "Contact Us",
        to: "/",
      },
    ],
  },
  {
    title: "Information",
    items: [
      {
        label: "About Us",
        to: "/about",
      },

      {
        label: "Privacy Policy",
        to: "/",
      },
      {
        label: "Terms & Conditions",
        to: "/terms",
      },
    ],
  },
  {
    title: "My Account",
    items: [
      {
        label: "Cart",
        to: "/",
      },
      {
        label: "Wishlist",
        to: "/",
      },
      {
        label: "Categories",
        to: "/",
      },
      {
        label: "All Products",
        to: "/",
      },
    ],
  },
];

const items = [
  {
    label: "Contact Us",
    "open-icon": "i-heroicons-plus",
    "close-icon": "i-heroicons-minus",
    slot: "contact",
  },
  {
    label: "Services",

    slot: "services",
  },
  {
    label: "Information",

    slot: "information",
  },
  {
    label: "My Account",

    slot: "my-account",
  },
];
</script>

<style></style>
