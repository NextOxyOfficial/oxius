<template>
  <PublicSection>
    <UContainer>
      <CommonProductDetailsCard2 :currentProduct="currentProduct" />
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get } = useApi();
const route = useRoute();

const currentProduct = ref({});

async function getProduct() {
  try {
    const { data } = await get(`/products/${route.params.id}/`);
    console.log({ data });
    currentProduct.value = data;
  } catch (error) {
    console.log(error);
  }
}

await getProduct();
</script>
