<template>
  <div>
    <CommonAddProductTab :product="currentProduct" />
  </div>
</template>

<script setup>
const { get } = useApi();
const route = useRoute();

const currentProduct = ref({});

async function getProduct() {
  try {
    const { data } = await get(`/products/${route.params.id}/`);

    currentProduct.value = data;
  } catch (error) {
    console.log(error);
  }
}

await getProduct();
</script>
