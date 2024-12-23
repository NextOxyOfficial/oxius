<template>
  <PublicSection>
    <UContainer>
      <UCard class="max-w-lg mx-auto py-16">
        <div v-if="verifyPaymentDetails?.shurjopay_message" class="text-center">
          <UIcon
            name="i-material-symbols:check-circle-outline-rounded"
            class="text-3xl md:text-6xl text-green-500"
          />
          <p class="font-semibold">Payment Successful!</p>
        </div>
        <div class="text-center" v-else>
          <UIcon
            name="i-gridicons:cross"
            class="text-3xl md:text-6xl text-red-500"
          />
          <p class="font-semibold">Payment Unsuccessful!</p>
        </div>
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { get, post } = useApi();
const props = defineProps({ something: Number }); // const emit = defineEmits(['emitChange', 'anotherEmit']);
const router = useRoute();
console.log(router.query.order_id);
const toast = useToast();
const verifyPaymentDetails = ref({});

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
  console.log(res);
  if (res.data) {
    toast.add({ title: "Payment successfully!" });
  } else {
    toast.add({ title: res.error.data.error });
  }
}

async function VerifyPayment() {
  const response = await get(
    "/verify-pay/?sp_order_id=" + router.query.order_id
  );
  console.log(response);
  if (response.data) {
    verifyPaymentDetails.value = response.data;
  } else {
    toast.add({ title: response.error.data.error });
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
  }
});
</script>

<style scoped></style>
