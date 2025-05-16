<template>
    <div class="workspace-container">
      <h1 class="text-xl font-semibold mb-4">Workspace: {{ workspaceName }}</h1>
  
      <!-- Tabs -->
      <div class="tabs mb-6">
        <button
          v-for="tab in tabs"
          :key="tab"
          @click="activeTab = tab"
          :class="['tab', { active: activeTab === tab }]"
        >
          {{ tab }}
        </button>
      </div>
  
      <!-- Tab Content -->
      <div v-if="activeTab === 'ToDo'">
        <h2 class="text-xl font-semibold mb-2">ToDo List</h2>
        <ul>
          <li v-for="(todo, index) in mockData.todos" :key="index">{{ todo }}</li>
        </ul>
      </div>
  
      <div v-else-if="activeTab === 'Members'">
        <h2 class="text-xl font-semibold mb-2">Members</h2>
        <ul>
          <li v-for="(member, index) in mockData.members" :key="index">{{ member }}</li>
        </ul>
      </div>
  
      <div v-else-if="activeTab === 'Location Tracking'">
        <h2 class="text-xl font-semibold mb-2">Location Tracking</h2>
        <p>Mock location data will be displayed here.</p>
      </div>
  
      <div v-else-if="activeTab === 'Posts'">
        <h2 class="text-xl font-semibold mb-2">Posts</h2>
        <ul>
          <li v-for="(post, index) in mockData.posts" :key="index">{{ post }}</li>
        </ul>
      </div>
  
      <div v-else-if="activeTab === 'Member Management'">
        <h2 class="text-xl font-semibold mb-2">Member Management</h2>
        <p>Add or remove members from the workspace.</p>
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref } from 'vue';
  
  const workspaceName = 'Example Workspace';
  const tabs = ['ToDo', 'Members', 'Location Tracking', 'Posts', 'Member Management'];
  const activeTab = ref(tabs[0]);
  
  const mockData = {
    todos: ['Task 1', 'Task 2', 'Task 3'],
    members: ['Alice', 'Bob', 'Charlie'],
    posts: ['Post 1', 'Post 2', 'Post 3'],
  };
  </script>
  
  <style scoped>
  .workspace-container {
    padding: 1rem;
  }
  
  .tabs {
    display: flex;
    gap: 1rem;
  }
  
  .tab {
    padding: 0.5rem 1rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    cursor: pointer;
    background-color: #f9f9f9;
  }
  
  .tab.active {
    background-color: #007bff;
    color: white;
    border-color: #007bff;
  }
  </style>