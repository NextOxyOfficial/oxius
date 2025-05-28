<template>
  <div class="mb-3">
    <div
      class="bg-gradient-to-r from-primary-50 to-primary-100 py-2 shadow-sm dark:from-primary-900/20 dark:to-primary-800/20"
    >
      <div class="flex flex-wrap items-center justify-between gap-2">
        <div class="flex items-center gap-2">
          <UIcon name="i-heroicons-heart" class="text-red-500 text-lg" />
          <p class="text-sm text-slate-700 dark:text-slate-200">
            {{ $t("support_our_mission") }} - {{ $t("donate_today") }}
          </p>
        </div>
        <div class="flex items-center gap-2">
          <UButton
            size="xs"
            color="gray"
            variant="ghost"
            :label="$t('view_donors')"
            icon="i-heroicons-user-group"
            @click="showDonorsList = true"
          />
          <UButton
            size="xs"
            color="primary"
            variant="solid"
            :label="$t('donate_now')"
            @click="showDonateModal = true"
            class="animate-pulse"
          />
        </div>
      </div>
    </div>
    <UModal v-model="showDonateModal">
      <div class="p-6">
        <div class="mb-6 text-center">
          <UIcon
            name="i-heroicons-heart"
            class="text-red-500 text-2xl mb-3 mx-auto"
          />
          <h3 class="text-xl font-semibold mb-2">
            {{ $t("donate_to_support") }}
          </h3>
          <p class="text-gray-500">{{ $t("donation_help_text") }}</p>
        </div>

        <div class="space-y-4">
          <div v-for="amount in donationAmounts" :key="amount" class="w-full">
            <UButton
              :label="amount + ' Tk'"
              color="primary"
              variant="outline"
              block
              @click="handleDonate(amount)"
              class="justify-center"
              :class="{ 'bg-primary-50': selectedAmount === amount }"
            />
          </div>

          <UFormGroup label="Custom Amount">
            <UInput
              v-model="customAmount"
              type="number"
              placeholder="Enter amount"
            />
          </UFormGroup>

          <UButton
            label="Proceed to Payment"
            color="primary"
            block
            :disabled="!selectedAmount && !customAmount"
            @click="proceedToDonation"
          />
        </div>
      </div>
    </UModal>
    <UModal v-model="showDonorsList" :ui="{ width: 'sm:max-w-xl' }">
      <div class="p-6">
        <div class="mb-6 text-center">
          <UIcon
            name="i-heroicons-heart"
            class="text-red-500 text-2xl mb-3 mx-auto"
          />
          <h3 class="text-xl font-semibold mb-2">
            {{ $t("our_generous_donors") }}
          </h3>
          <p class="text-gray-500 mb-4">
            {{ $t("donor_thank_you_message") }}
          </p>
        </div>

        <!-- Donor Tabs -->
        <UTabs :items="donorTabs" class="mb-4">
          <template #item="{ item }">
            <div>
              <div class="space-y-4">
                <!-- Recent Donors list for "recent" tab -->
                <div v-if="item.key === 'recent'" class="space-y-3">
                  <div
                    v-for="(donor, index) in recentDonors"
                    :key="index"
                    class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div class="flex items-center gap-3">
                      <UAvatar
                        :src="donor.avatar"
                        :alt="donor.name"
                        size="sm"
                      />
                      <div>
                        <p class="font-medium text-gray-800">
                          {{ donor.name }}
                        </p>
                        <p class="text-xs text-gray-500">{{ donor.date }}</p>
                      </div>
                    </div>
                    <div class="flex items-center gap-1">
                      <span class="font-semibold">{{ donor.amount }} Tk</span>
                      <UBadge v-if="index < 3" color="amber" size="xs"
                        >New</UBadge
                      >
                    </div>
                  </div>
                </div>

                <!-- Top Donors list for "top" tab -->
                <div v-if="item.key === 'top'" class="space-y-3">
                  <div
                    v-for="(donor, index) in topDonors"
                    :key="index"
                    class="flex items-center justify-between p-3 rounded-lg"
                    :class="index < 3 ? 'bg-amber-50' : 'bg-gray-50'"
                  >
                    <div class="flex items-center gap-3">
                      <div
                        class="w-6 h-6 flex items-center justify-center rounded-full bg-primary-100 text-primary-700 text-xs font-semibold"
                      >
                        {{ index + 1 }}
                      </div>
                      <UAvatar
                        :src="donor.avatar"
                        :alt="donor.name"
                        size="sm"
                      />
                      <p class="font-medium text-gray-800">
                        {{ donor.name }}
                      </p>
                    </div>
                    <span class="font-semibold">{{ donor.amount }} Tk</span>
                  </div>
                </div>

                <!-- Monthly Donors list for "monthly" tab -->
                <div v-if="item.key === 'monthly'" class="space-y-3">
                  <div
                    v-for="(donor, index) in monthlyDonors"
                    :key="index"
                    class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div class="flex items-center gap-3">
                      <UAvatar
                        :src="donor.avatar"
                        :alt="donor.name"
                        size="sm"
                      />
                      <div>
                        <p class="font-medium text-gray-800">
                          {{ donor.name }}
                        </p>
                        <p class="text-xs text-gray-500">
                          {{ $t("monthly_donor") }}
                        </p>
                      </div>
                    </div>
                    <UBadge color="green"
                      >{{ donor.amount }} Tk/{{ $t("month") }}</UBadge
                    >
                  </div>
                </div>
              </div>
            </div>
          </template>
        </UTabs>

        <!-- Join these donors button -->
        <div class="mt-6 text-center">
          <UButton
            color="primary"
            label="Become a Donor"
            @click="becomeDonor"
            block
          />
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
const showDonateModal = ref(false);
const showDonorsList = ref(false);
const selectedAmount = ref(null);
const customAmount = ref("");
const donationAmounts = [50, 100, 500, 1000];

// Donor tabs
const donorTabs = [
  { key: "recent", label: "Recent Donors", icon: "i-heroicons-clock" },
  { key: "top", label: "Top Donors", icon: "i-heroicons-trophy" },
  { key: "monthly", label: "Monthly Donors", icon: "i-heroicons-calendar" },
];

// Sample donor data - replace with your actual donor data from an API
const recentDonors = [
  {
    name: "Ahmed K.",
    amount: 500,
    date: "1 hour ago",
    avatar: "https://avatars.githubusercontent.com/u/1",
  },
  {
    name: "Maryam S.",
    amount: 200,
    date: "3 hours ago",
    avatar: "https://avatars.githubusercontent.com/u/2",
  },
  {
    name: "Tareq R.",
    amount: 1000,
    date: "5 hours ago",
    avatar: "https://avatars.githubusercontent.com/u/3",
  },
  {
    name: "Samira H.",
    amount: 100,
    date: "Yesterday",
    avatar: "https://avatars.githubusercontent.com/u/4",
  },
  {
    name: "Kamal Z.",
    amount: 50,
    date: "2 days ago",
    avatar: "https://avatars.githubusercontent.com/u/5",
  },
];

const topDonors = [
  {
    name: "Tareq R.",
    amount: 5000,
    avatar: "https://avatars.githubusercontent.com/u/3",
  },
  {
    name: "Maryam S.",
    amount: 3500,
    avatar: "https://avatars.githubusercontent.com/u/2",
  },
  {
    name: "Ahmed K.",
    amount: 2500,
    avatar: "https://avatars.githubusercontent.com/u/1",
  },
  {
    name: "Fahmida R.",
    amount: 1500,
    avatar: "https://avatars.githubusercontent.com/u/6",
  },
  {
    name: "Nasir H.",
    amount: 1000,
    avatar: "https://avatars.githubusercontent.com/u/7",
  },
];

const monthlyDonors = [
  {
    name: "Ahmed K.",
    amount: 200,
    avatar: "https://avatars.githubusercontent.com/u/1",
  },
  {
    name: "Samira H.",
    amount: 100,
    avatar: "https://avatars.githubusercontent.com/u/4",
  },
  {
    name: "Nasir H.",
    amount: 500,
    avatar: "https://avatars.githubusercontent.com/u/7",
  },
];

function handleDonate(amount) {
  selectedAmount.value = amount;
  customAmount.value = "";
}

function proceedToDonation() {
  const finalAmount = customAmount.value || selectedAmount.value;
  // Handle donation payment process here

  showDonateModal.value = false;
  toast.add({
    title: "Thank you!",
    description: "Redirecting to payment...",
    color: "green",
  });
}

function becomeDonor() {
  showDonorsList.value = false;
  showDonateModal.value = true;
}
</script>

<style scoped></style>
