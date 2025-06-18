<template>
  <div>
    <h3
      class="text-xs font-semibold text-gray-600 uppercase tracking-wider px-3 mb-3 flex items-center"
    >
      <Link class="h-3.5 w-3.5 mr-1.5" />
      <span>Useful Links</span>
    </h3>    <div class="grid grid-cols-2 gap-2 px-3">
      <NuxtLink
        v-for="item in links"
        :key="item.path"
        :to="item.path"
        class="flex flex-col items-center justify-center p-3 rounded-md bg-gray-50 border border-gray-100 hover:bg-blue-50 hover:border-blue-100 transition-all shadow-sm"
        @click="handleButtonClick(`useful_${item.label.toLowerCase().replace(' ', '_')}`)"
      >
        <div v-if="loadingButtons.has(`useful_${item.label.toLowerCase().replace(' ', '_')}`)" class="dotted-spinner blue mb-2"></div>
        <component v-else :is="item.icon" class="h-5 w-5 mb-2 text-blue-600" />
        <span class="text-xs font-medium text-gray-800">{{ item.label }}</span>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
import { Link, ShoppingBag, DollarSign, Store, Smartphone } from "lucide-vue-next";

// Loading state for buttons
const loadingButtons = ref(new Set());

// Handle button clicks with loading states
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
};

// Watch route changes to clear loading states
watch(() => useRoute().fullPath, () => {
  loadingButtons.value.clear();
});

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
    icon: Smartphone,  },
];
</script>

<style scoped>
/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1.25rem;
  height: 1.25rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.emerald {
  border-color: #059669;
}

.dotted-spinner.green {
  border-color: #16a34a;
}

.dotted-spinner.slate {
  border-color: #64748b;
}

.dotted-spinner.blue {
  border-color: #3b82f6;
}

.dotted-spinner.violet {
  border-color: #8b5cf6;
}

.dotted-spinner.white {
  border-color: #ffffff;
}

.dotted-spinner.primary {
  border-color: #059669;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>