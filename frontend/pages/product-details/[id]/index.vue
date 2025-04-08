<template>
  <PublicSection>
    <UContainer>
      <CommonProductDetailsCard2
        :currentProduct="currentProduct"
        v-if="currentProduct.is_advanced"
      />
      <CommonProductDetailsCard :currentProduct="currentProduct" v-else />
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
