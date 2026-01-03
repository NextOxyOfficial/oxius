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
        <div class="text-lg font-medium text-gray-800 flex items-center mb-4">
          <span>
            আমি
            <span class="text-lg font-semibold text-green-950">
              AdsyAI Bot
              <UIcon class="text-xl" name="i-carbon:bot" />
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
              font: { weight: 'font-semibold' },
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
              font: { weight: 'font-semibold' },
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
              name="i-carbon-bot"
              class="text-5xl text-primary animate-pulse"
            />
          </div>
          <div class="search-beam"></div>
          <div class="search-pulse"></div>
        </div>

        <!-- Animated Text -->
        <div class="text-lg font-medium text-gray-800 flex items-center">
          <span>
            আমি
            <span class="text-lg font-semibold text-green-950">
              AdsyAI Bot
              <UIcon class="text-xl" name="i-carbon-bot" />
            </span>
            আপনার জন্য ইন্টারনেটে বিভিন্ন ওয়েবসাইট এ তথ্য খুঁজছি, একটু অপেক্ষা
            করুন
          </span>
        </div>
        <span class="dots-animation ml-1"></span>
        <p class="text-sm text-gray-600 mt-2">
          Finding information in {{ upazila }}, {{ city }}, {{ state }}
        </p>
      </div>
    </section>

    <!-- Search Declined Message -->
    <section v-else-if="searchDeclined" class="py-6">
      <div class="flex flex-col items-center justify-center">
        <div class="bot-container mb-4">
          <div class="bot-icon">
            <UIcon name="i-carbon:bot" class="text-5xl text-gray-600" />
          </div>
        </div>
        <div class="text-lg font-medium text-gray-800">
          <span>
            আমি
            <span class="text-lg font-semibold text-green-950">
              AdsyAI Bot
              <UIcon class="text-xl" name="i-carbon:bot" />
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
        <span class="text-lg font-semibold text-green-950">
          AdsyAI Bot
          <UIcon class="text-xl" name="i-carbon:bot" />
        </span>
        দুঃখিত, আপনার জন্য ইন্টারনেট থেকে কোনো তথ্য খুঁজে পাইনি।
      </div>
      <div class="mb-3" v-else>
        আমি
        <span class="text-lg font-semibold text-green-950">
          AdsyAI Bot
          <UIcon class="text-xl" name="i-carbon:bot" />
        </span>
        আপনার জন্য ইন্টারনেট থেকে নিচের এই তথ্য গুলো খুঁজে বের করতে সক্ষম
        হয়েছি:
      </div>
      <UDivider label="" class="mb-2" />
      <div class="flex gap-4 py-2" v-for="(b, i) in result" :key="b.id || i">
        <div class="text-left flex-1">
          <div class="flex items-start justify-between">
            <h1 class="text-lg font-semibold break-words flex-1">
              {{ i + 1 }}. {{ b.name }}
            </h1>
            <button 
              @click="copyAllInfo(b)" 
              class="ml-2 p-1 text-gray-500 hover:text-gray-700 rounded"
              title="Copy all info"
            >
              <UIcon name="i-heroicons-clipboard-document" class="w-5 h-5" />
            </button>
          </div>
          <p v-if="b.description" class="break-words text-gray-600">{{ b.description }}</p>
          
          <div v-if="b.address" class="flex items-start gap-2 mt-1">
            <UIcon name="i-heroicons-map-pin" class="w-4 h-4 text-gray-500 mt-0.5 flex-shrink-0" />
            <span class="break-words flex-1 text-gray-600">{{ b.address }}</span>
            <button @click="copyText(b.address)" class="p-1 text-gray-400 hover:text-gray-600" title="Copy">
              <UIcon name="i-heroicons-clipboard" class="w-4 h-4" />
            </button>
          </div>
          
          <div v-if="b.phone" class="flex items-start gap-2 mt-1">
            <UIcon name="i-heroicons-phone" class="w-4 h-4 text-gray-500 mt-0.5 flex-shrink-0" />
            <a :href="'tel:' + b.phone" class="break-words flex-1 text-gray-600 hover:text-primary">{{ b.phone }}</a>
            <button @click="copyText(b.phone)" class="p-1 text-gray-400 hover:text-gray-600" title="Copy">
              <UIcon name="i-heroicons-clipboard" class="w-4 h-4" />
            </button>
          </div>
          
          <div v-if="b.email" class="flex items-start gap-2 mt-1">
            <UIcon name="i-heroicons-envelope" class="w-4 h-4 text-gray-500 mt-0.5 flex-shrink-0" />
            <a :href="'mailto:' + b.email" class="break-words flex-1 text-gray-600 hover:text-primary">{{ b.email }}</a>
            <button @click="copyText(b.email)" class="p-1 text-gray-400 hover:text-gray-600" title="Copy">
              <UIcon name="i-heroicons-clipboard" class="w-4 h-4" />
            </button>
          </div>
          
          <div v-if="b.website" class="flex items-start gap-2 mt-1">
            <UIcon name="i-heroicons-globe-alt" class="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
            <a :href="normalizeUrl(b.website)" target="_blank" rel="noopener" class="break-words flex-1 text-primary hover:underline">{{ b.website }}</a>
            <button @click="copyText(b.website)" class="p-1 text-gray-400 hover:text-gray-600" title="Copy">
              <UIcon name="i-heroicons-clipboard" class="w-4 h-4" />
            </button>
          </div>
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
const { get, post } = useApi();

const result = ref();
const userChoice = ref(false);
const isSearching = ref(false);
const searchDeclined = ref(false);
const aiConfig = ref(null);
const errorMessage = ref("");

function sanitizeAiValue(value) {
  if (value === null || value === undefined) return null;
  const text = String(value).trim();
  if (!text) return null;
  const lower = text.toLowerCase();
  if (['null', 'n/a', 'na', 'none', 'unknown'].includes(lower)) return null;
  return text;
}

function isValidBangladeshPhone(value) {
  const compact = value.replace(/[\s\-()]/g, '');
  if (!compact) return false;
  if (compact.toLowerCase().includes('x')) return false;
  if (compact.includes('1234567') || compact.includes('12345678')) return false;
  const mobileIntl = /^\+8801\d{9}$/.test(compact);
  const mobileLocal = /^01\d{9}$/.test(compact);
  const landlineIntl = /^\+880\d{1,2}\d{6,8}$/.test(compact);
  return mobileIntl || mobileLocal || landlineIntl;
}

function isValidEmail(value) {
  const email = value.trim();
  if (!email) return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isLikelyValidWebsite(value) {
  const text = value.trim();
  if (!text) return false;
  if (text.includes(' ')) return false;
  const lower = text.toLowerCase();
  if (lower.includes('example.com') || lower.includes('test.com')) return false;
  if (lower.startsWith('http://') || lower.startsWith('https://')) return text.includes('.');
  return /^[a-z0-9\-_.]+\.[a-z]{2,}/.test(lower);
}

function extractEmailDomain(email) {
  const trimmed = email.trim().toLowerCase();
  const at = trimmed.indexOf('@');
  if (at <= 0 || at >= trimmed.length - 1) return null;
  return trimmed.substring(at + 1);
}

function extractHostFromWebsite(website) {
  let w = website.trim();
  if (!w.toLowerCase().startsWith('http://') && !w.toLowerCase().startsWith('https://')) {
    w = 'https://' + w;
  }
  try {
    const url = new URL(w);
    let host = url.hostname.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    return host || null;
  } catch {
    return null;
  }
}

function isWebsiteConsistentWithEmail(email, website) {
  if (!email || !website) return true;
  const emailDomain = extractEmailDomain(email);
  const websiteHost = extractHostFromWebsite(website);
  if (!emailDomain || !websiteHost) return false;
  const cleanEmailDomain = emailDomain.startsWith('www.') ? emailDomain.substring(4) : emailDomain;
  return websiteHost === cleanEmailDomain || 
         websiteHost.endsWith('.' + cleanEmailDomain) || 
         cleanEmailDomain.endsWith('.' + websiteHost);
}

function sanitizeAiBusiness(business) {
  const sanitized = { ...business };

  const name = sanitizeAiValue(sanitized.name);
  if (!name) return null;
  sanitized.name = name;

  const description = sanitizeAiValue(sanitized.description);
  if (!description) delete sanitized.description;
  else sanitized.description = description;

  const address = sanitizeAiValue(sanitized.address);
  if (!address) delete sanitized.address;
  else sanitized.address = address;

  const phone = sanitizeAiValue(sanitized.phone);
  if (!phone || !isValidBangladeshPhone(phone)) delete sanitized.phone;
  else sanitized.phone = phone;

  const email = sanitizeAiValue(sanitized.email);
  if (!email || !isValidEmail(email)) delete sanitized.email;
  else sanitized.email = email;

  const website = sanitizeAiValue(sanitized.website);
  if (!website || !isLikelyValidWebsite(website)) delete sanitized.website;
  else sanitized.website = website;

  if (!isWebsiteConsistentWithEmail(sanitized.email, sanitized.website)) {
    delete sanitized.website;
  }

  return sanitized;
}

function dropRepeatedFieldsAcrossResults(items) {
  const phoneCount = {};
  const websiteCount = {};

  for (const item of items) {
    if (item.phone) {
      const p = item.phone.trim();
      phoneCount[p] = (phoneCount[p] || 0) + 1;
    }
    if (item.website) {
      const w = item.website.trim();
      websiteCount[w] = (websiteCount[w] || 0) + 1;
    }
  }

  for (const item of items) {
    if (item.phone && phoneCount[item.phone.trim()] > 1) {
      delete item.phone;
    }
    if (item.website && websiteCount[item.website.trim()] > 1) {
      delete item.website;
    }
  }

  return items;
}

function sanitizeBusinesses(businesses) {
  if (!Array.isArray(businesses)) return [];
  const cleaned = businesses
    .map(sanitizeAiBusiness)
    .filter(b => b !== null);
  return dropRepeatedFieldsAcrossResults(cleaned);
}

async function fetchAIConfig() {
  try {
    const { data, error } = await get("/ai-link/");
    if (data) {
      aiConfig.value = data;
    } else {
      throw error;
    }
  } catch (err) {
    console.error("Error fetching AI config:", err);
  }
}

await fetchAIConfig();

// Function to start search when user clicks "Yes"
async function startSearch() {
  userChoice.value = true;
  isSearching.value = true;
  searchDeclined.value = false;
  errorMessage.value = "";

  try {
    // Use the new backend endpoint that handles OpenAI/Cloudflare internally
    const { data, error } = await post("/ai-business-finder/", {
      country: props.country,
      state: props.state,
      city: props.city,
      upazila: props.upazila,
      business_type: props.business_type,
    });

    if (error) {
      console.error("Error from AI business finder:", error);
      errorMessage.value = error.message || "Failed to fetch business data";
      result.value = [];
    } else if (data) {
      let businesses = [];
      if (Array.isArray(data.businesses)) {
        businesses = data.businesses;
      } else if (Array.isArray(data)) {
        businesses = data;
      }
      result.value = sanitizeBusinesses(businesses);
    } else {
      result.value = [];
    }
  } catch (err) {
    console.error("Error fetching business data:", err);
    errorMessage.value = err.message || "An error occurred while searching";
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
  errorMessage.value = "";
}

function normalizeUrl(url) {
  const trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
  return 'https://' + trimmed;
}

function copyText(text) {
  navigator.clipboard.writeText(text);
}

function copyAllInfo(business) {
  const parts = [business.name];
  if (business.description) parts.push(business.description);
  if (business.address) parts.push(business.address);
  if (business.phone) parts.push(business.phone);
  if (business.email) parts.push(business.email);
  if (business.website) parts.push(business.website);
  navigator.clipboard.writeText(parts.join('\n'));
}
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
