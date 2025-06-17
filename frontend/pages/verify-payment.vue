<template>
  <PublicSection>
    <UContainer>
      <UCard class="max-w-lg mx-auto py-16">
        <div v-if="!loader">
          <div v-if="!showError" class="text-center">
            <UIcon
              name="i-material-symbols:check-circle-outline-rounded"
              class="text-2xl md:text-6xl text-green-500"
            />
            <p class="font-semibold">Payment Successful!</p>
          </div>
          <div class="text-center" v-else>
            <UIcon
              name="i-gridicons:cross"
              class="text-2xl md:text-6xl text-red-500"
            />
            <p class="font-semibold">Payment Unsuccessful!</p>
          </div>
        </div>
        <CommonPreloader v-else />
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { jwtLogin } = useAuth();
const { get, post } = useApi();
const props = defineProps({ something: Number }); // const emit = defineEmits(['emitChange', 'anotherEmit']);
const router = useRoute();
const toast = useToast();
const verifyPaymentDetails = ref({});
const showError = ref(false);
const loader = ref(true);

async function addBalance() {
  const {
    bank_status,
    payment_method,
    amount,
    payable_amount,
    received_amount,
    merchant_invoice_no,
    shurjopay_order_id,
    payment_confirmed_at,
  } = verifyPaymentDetails.value;
  const res = await post("/add-user-balance/", {
    bank_status: bank_status.toLowerCase(),
    transaction_type: "Deposit",
    payment_method,
    amount,
    payable_amount,
    received_amount,
    merchant_invoice_no,
    shurjopay_order_id,
    payment_confirmed_at,
  });

  if (res.data) {
    toast.add({ title: "Payment successfully!" });
    await jwtLogin();
  } else {
    toast.add({ title: res.error.data.error });
    showError.value = true;
  }
  loader.value = false;
}

async function VerifyPayment() {
  const response = await get(
    "/verify-pay/?sp_order_id=" + router.query.order_id
  );

  if (response.data) {
    verifyPaymentDetails.value = response.data;
  } else {
    toast.add({ title: response.error.data.error });
    showError.value = true;
    loader.value = false;
  }
}
onMounted(() => {
  VerifyPayment();
});

watch(verifyPaymentDetails, () => {
  if (verifyPaymentDetails.value?.shurjopay_message === "Success") {
    addBalance();
  } else {
    toast.add({ title: "Payment Verification Failed!" });
    loader.value = false;
  }
});
</script>

<style scoped></style>
