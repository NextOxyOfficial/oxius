<template>
  <div>{{ submittedTasks }}</div>
</template>

<script setup>
const { get, staticURL, del, put } = useApi();
const submittedTasks = ref([]);
const route = useRoute();
async function getUserGigs() {
  try {
    const res = await get(`/task-by-micro-gig-post/${route.params.id}/tasks/`);
    console.log(res);
    submittedTasks.value = res.data;
  } catch (error) {
    console.log(error);
  }
}
getUserGigs();
</script>

<style scoped></style>
