<template>
  <div>
    <h3
      class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center"
    >
      <Link class="h-3.5 w-3.5 mr-1.5" />
      <span>Useful Links</span>
    </h3>
    <div class="grid grid-cols-2 gap-2 px-3">
      <NuxtLink
        v-for="item in links"
        :key="item.path"
        :to="item.path"
        class="flex flex-col items-center justify-center p-3 rounded-md bg-gray-50 border border-gray-100 hover:bg-blue-50 hover:border-blue-100 transition-all shadow-sm"
      >
        <component :is="item.icon" class="h-5 w-5 mb-2 text-blue-600" />
        <span class="text-xs font-medium text-gray-700">{{ item.label }}</span>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
import { Link, ShoppingBag, DollarSign, Store, Smartphone } from "lucide-vue-next";

// Define the useful links
const links = [
  {
    label: "eShop",
    path: "/eshop",
    icon: ShoppingBag,
  },
  {
    label: "Earn Money",
    path: "/#micro-gigs",
    icon: DollarSign,
  },
  {
    label: "Sell Products",
    path: "/shop-manager",
    icon: Store,
  },
  {
    label: "Mobile Recharge",
    path: "/mobile-recharge",
    icon: Smartphone,
  },
];
</script>