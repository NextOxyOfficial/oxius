<template>
  <PublicSection>
    <UContainer>
      <CommonProductDetailsCard2
        :currentProduct="currentProduct"
        v-if="currentProduct.is_advanced"
        :increaseProductViews="increaseProductViews"
      />
      <CommonProductDetailsCard
        :seeDetails="false"
        :currentProduct="currentProduct"
        :increaseProductViews="increaseProductViews"
        v-else
      />
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get, patch } = useApi();
const route = useRoute();

const currentProduct = ref({});

async function getProduct() {
  try {
    const { data } = await get(`/products/${route.params.id}/`);

    currentProduct.value = data;
  } catch (error) {
    console.error(error);
  }
}

await getProduct();

async function increaseProductViews() {
  try {
    const { data } = await patch(`/products/${currentProduct.value.slug}/`, {
      views: currentProduct.value.views + 1,
    });
  } catch (error) {
    console.error(error);
  }
}
</script>
