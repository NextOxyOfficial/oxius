<template>
  <div>
    <section v-if="!result" class="py-6">
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
          <span
            >আমি
            <span class="text-lg font-bold text-green-950">
              AdsyAI Bot
              <UIcon class="text-2xl" name="i-carbon:bot" />
            </span>
            আপনার জন্য ইন্টারনেটে বিভিন্ন ওয়েবসাইট এ তথ্য খুঁজছি, একটু অপেক্ষা
            করুন</span
          >
          <span class="dots-animation ml-1"></span>
        </div>
        <p class="text-sm text-gray-500 mt-2">
          Finding information in {{ upazila }}, {{ city }}, {{ state }}
        </p>
      </div>
    </section>

    <section v-else>
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
        আপনার জন্য ইন্টারনেট থেকে নিচের এই তথ্য গুলো খুঁজে বের করতে সক্ষম হয়েছি
        :
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
const url =
  "https://jolly-snow-f5d0.shimul929.workers.dev/business-finder?key=pk00xaytupk7";
let extra_command =
  "search for fields: name,description,address,phone,email,website";
let hidden_fields = ["phone"];
onMounted(async () => {
  const { data, pending, error, refresh } = await useFetch(
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
});
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
</style>
