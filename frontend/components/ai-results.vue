<template>
  <div>
    <!-- Confirmation Dialog -->
    <section v-if="!userChoice" class="py-6">
      <div class="flex flex-col items-center justify-center">
        <!-- Bot Icon with Animation -->
        <div class="bot-container mb-4">
          <div class="bot-icon">
            <UIcon name="i-carbon:bot" class="text-5xl text-primary" />
          </div>
          <div class="bot-pulse"></div>
        </div>

        <!-- Confirmation Message -->
        <div class="text-lg font-medium text-gray-700 flex items-center mb-4">
          <span>
            আমি
            <span class="text-lg font-bold text-green-950">
              AdsyAI Bot
              <UIcon class="text-2xl" name="i-carbon:bot" />
            </span>
            আমি কি আপনার জন্য বিভিন্ন ওয়েবসাইট থেকে তথ্য খুঁজে বের করবো?
          </span>
        </div>

        <!-- Choice Buttons -->
        <div class="flex gap-5 mt-6">
          <!-- Yes Button -->
          <UButton
            color="primary"
            variant="solid"
            @click="startSearch"
            class="min-w-24 py-3 px-5 confirmation-button yes-button group"
            :ui="{
              rounded: 'rounded-xl',
              padding: { sm: 'px-5 py-2.5', default: 'px-5 py-3' },
              font: { weight: 'font-bold' },
              size: { sm: 'text-sm', default: 'text-base' },
            }"
          >
            <span class="button-content">
              হা
              <UIcon
                name="i-heroicons-check-circle"
                class="ml-2 icon-animation"
              />
            </span>
            <span class="button-glow"></span>
          </UButton>

          <!-- No Button -->
          <UButton
            color="white"
            variant="soft"
            @click="declineSearch"
            class="min-w-24 py-3 px-5 confirmation-button no-button group"
            :ui="{
              rounded: 'rounded-xl',
              padding: { sm: 'px-5 py-2.5', default: 'px-5 py-3' },
              font: { weight: 'font-bold' },
              size: { sm: 'text-sm', default: 'text-base' },
            }"
          >
            <span class="button-content text-white">
              না
              <UIcon
                name="i-heroicons-x-circle"
                class="ml-2 icon-animation text-white"
              />
            </span>
          </UButton>
        </div>
      </div>
    </section>

    <!-- Loading Animation (shown after user confirms) -->
    <section v-else-if="isSearching" class="py-6">
      <div class="flex flex-col items-center justify-center">
        <!-- Animated Bot -->
        <div class="bot-container mb-4">
          <div class="bot-icon">
            <UIcon
              name="i-carbon:bot"
              class="text-5xl text-primary animate-pulse"
            />
          </div>
          <div class="search-beam"></div>
          <div class="search-pulse"></div>
        </div>

        <!-- Animated Text -->
        <div class="text-lg font-medium text-gray-700 flex items-center">
          <span>
            আমি
            <span class="text-lg font-bold text-green-950">
              AdsyAI Bot
              <UIcon class="text-2xl" name="i-carbon:bot" />
            </span>
            আপনার জন্য ইন্টারনেটে বিভিন্ন ওয়েবসাইট এ তথ্য খুঁজছি, একটু অপেক্ষা
            করুন
          </span>
          <span class="dots-animation ml-1"></span>
        </div>
        <p class="text-sm text-gray-500 mt-2">
          Finding information in {{ upazila }}, {{ city }}, {{ state }}
        </p>
      </div>
    </section>

    <!-- Search Declined Message -->
    <section v-else-if="searchDeclined" class="py-6">
      <div class="flex flex-col items-center justify-center">
        <div class="bot-container mb-4">
          <div class="bot-icon">
            <UIcon name="i-carbon:bot" class="text-5xl text-gray-400" />
          </div>
        </div>
        <div class="text-lg font-medium text-gray-700">
          <span>
            আমি
            <span class="text-lg font-bold text-green-950">
              AdsyAI Bot
              <UIcon class="text-2xl" name="i-carbon:bot" />
            </span>
            ঠিক আছে, আপনি যখন চাইবেন তখন আমি তথ্য খুঁজে দেখাবো।
          </span>
        </div>
        <UButton
          color="primary"
          @click="userChoice = false"
          class="mt-4"
          variant="soft"
        >
          Try Again
          <UIcon name="i-heroicons-arrow-path" class="ml-1" />
        </UButton>
      </div>
    </section>

    <!-- Search Results -->
    <section v-else-if="result">
      <div v-if="result.length === 0">
        আমি
        <span class="text-lg font-bold text-green-950">
          AdsyAI Bot
          <UIcon class="text-2xl" name="i-carbon:bot" />
        </span>
        দুঃখিত, আপনার জন্য ইন্টারনেট থেকে কোনো তথ্য খুঁজে পাইনি।
      </div>
      <div class="mb-3" v-else>
        আমি
        <span class="text-lg font-bold text-green-950">
          AdsyAI Bot
          <UIcon class="text-2xl" name="i-carbon:bot" />
        </span>
        আপনার জন্য ইন্টারনেট থেকে নিচের এই তথ্য গুলো খুঁজে বের করতে সক্ষম
        হয়েছি:
      </div>
      <UDivider label="" class="mb-2" />
      <div class="flex gap-4 py-2" v-for="(b, i) in result" :key="b.id">
        <div class="text-left">
          <h1 class="text-lg font-semibold">{{ i + 1 }}. {{ b.name }}</h1>
          <p v-if="b.description">{{ b.description }}</p>
          <p v-if="b.address">{{ b.address }}</p>

          <ul class="list-disc list-inside">
            <li v-if="b.phone">Mobile: {{ b.phone }}</li>
            <li v-if="b.email">Email: {{ b.email }}</li>
            <li v-if="b.website">Website: {{ b.website }}</li>
          </ul>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
const props = defineProps({
  country: String,
  city: String,
  state: String,
  business_type: String,
  upazila: String,
});

const result = ref();
const userChoice = ref(false); // Track if user has made a choice
const isSearching = ref(false); // Track if search is in progress
const searchDeclined = ref(false); // Track if user declined the search

const url =
  "https://jolly-snow-f5d0.shimul929.workers.dev/business-finder?key=pk00xaytupk7";
let extra_command =
  "search for fields: name,description,address,phone,email,website";
let hidden_fields = ["phone"];

// Function to start search when user clicks "Yes"
async function startSearch() {
  userChoice.value = true;
  isSearching.value = true;
  searchDeclined.value = false;

  try {
    const { data, pending, error } = await useFetch(
      `${url}&country=${props.country}&city=${props.city}&state=${props.state}&business_type=${props.business_type}&extra_command=${extra_command}`,
      {
        method: "get",
      }
    );

    console.log("Business data", data.value);
    if (Array.isArray(data.value.data)) {
      result.value = data.value.data;
    } else {
      result.value = data.value.data.businesses;
    }
  } catch (err) {
    console.error("Error fetching business data:", err);
    result.value = [];
  } finally {
    isSearching.value = false;
  }
}

// Function when user clicks "No"
function declineSearch() {
  userChoice.value = true;
  isSearching.value = false;
  searchDeclined.value = true;
  result.value = undefined;
}

// No automatic fetching on mount - wait for user choice
</script>

<style scoped>
.bot-container {
  position: relative;
  width: 80px;
  height: 80px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.bot-icon {
  position: relative;
  z-index: 2;
  animation: float 3s ease-in-out infinite;
}

.search-beam {
  position: absolute;
  bottom: -10px;
  width: 120px;
  height: 60px;
  background: radial-gradient(
    ellipse at top,
    rgba(72, 187, 120, 0.4) 0%,
    rgba(72, 187, 120, 0) 70%
  );
  border-radius: 50%;
  filter: blur(5px);
  animation: scan 2s ease-in-out infinite;
  transform-origin: center top;
  z-index: 1;
}

.search-pulse {
  position: absolute;
  width: 100%;
  height: 100%;
  border: 2px solid transparent;
  border-radius: 50%;
  box-shadow: 0 0 0 0 rgba(72, 187, 120, 0.7);
  animation: pulse 2s infinite;
}

.bot-pulse {
  position: absolute;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: rgba(72, 187, 120, 0.1);
  animation: botPulse 2s ease-out infinite;
}

.confirmation-button {
  transition: all 0.2s ease;
  transform: translateY(0);
}

.confirmation-button:hover {
  transform: translateY(-3px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.dots-animation::after {
  content: "";
  animation: dots 1.5s infinite;
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

@keyframes scan {
  0%,
  100% {
    transform: scaleX(0.8) rotateX(65deg);
    opacity: 0.6;
  }
  50% {
    transform: scaleX(1.2) rotateX(65deg);
    opacity: 0.8;
  }
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(72, 187, 120, 0.7);
  }
  70% {
    box-shadow: 0 0 0 15px rgba(72, 187, 120, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(72, 187, 120, 0);
  }
}

@keyframes botPulse {
  0% {
    transform: scale(0.95);
    opacity: 1;
  }
  70% {
    transform: scale(1.2);
    opacity: 0;
  }
  100% {
    transform: scale(0.95);
    opacity: 0;
  }
}

@keyframes dots {
  0%,
  20% {
    content: ".";
  }
  40% {
    content: "..";
  }
  60%,
  100% {
    content: "...";
  }
}

/* Enhanced button styles */
.confirmation-button {
  position: relative;
  overflow: hidden;
  transition: all 0.4s cubic-bezier(0.2, 1, 0.2, 1);
  transform: translateY(0);
  letter-spacing: 0.5px;
  border: none;
}

.confirmation-button:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.15);
}

.confirmation-button:active {
  transform: translateY(-2px);
}

/* Yes button styling */
.yes-button {
  background: linear-gradient(135deg, #34d399 0%, #059669 100%);
  box-shadow: 0 4px 15px rgba(5, 150, 105, 0.3);
}

.yes-button:hover {
  background: linear-gradient(135deg, #10b981 0%, #047857 100%);
  box-shadow: 0 10px 25px rgba(5, 150, 105, 0.4);
}

.yes-button .button-glow {
  position: absolute;
  top: -30%;
  left: -20%;
  width: 80px;
  height: 80px;
  background: radial-gradient(
    circle,
    rgb(255, 255, 255) 0%,
    rgb(253, 253, 253) 70%
  );
  border-radius: 50%;
  opacity: 0;
  transition: opacity 0.5s ease;
  mix-blend-mode: overlay;
  pointer-events: none;
}

.yes-button:hover .button-glow {
  opacity: 0.5;
  animation: rotate-glow 3s infinite linear;
}

/* No button styling */
.no-button {
  background: linear-gradient(135deg, #eb4c37 0%, #d80da5 100%);
}

.no-button:hover {
  background: linear-gradient(135deg, #e67fcf 0%, #eb94e6 100%);
}

/* Button content */
.button-content {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  width: 100%;
}

/* Icon animations */
.icon-animation {
  transition: all 0.3s ease;
}

.yes-button:hover .icon-animation {
  transform: rotate(15deg) scale(1.2);
  filter: drop-shadow(0 0 3px rgb(255, 255, 255));
}

.no-button:hover .icon-animation {
  transform: rotate(-15deg) scale(1.2);
}

/* Button ripple effect */
.confirmation-button::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: 5px;
  height: 5px;
  background: rgb(255, 255, 255);
  opacity: 0;
  border-radius: 100%;
  transform: scale(1) translate(-50%, -50%);
  transform-origin: 50% 50%;
}

.confirmation-button:focus:not(:active)::after {
  animation: ripple 0.8s ease-out;
}

/* New animation keyframes */
@keyframes ripple {
  0% {
    transform: scale(0) translate(-50%, -50%);
    opacity: 0.6;
  }
  100% {
    transform: scale(20) translate(-50%, -50%);
    opacity: 0;
  }
}

@keyframes rotate-glow {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
