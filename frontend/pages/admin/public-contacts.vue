<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <div class="bg-white shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center py-6">
          <div>
            <h1 class="text-3xl font-bold text-gray-900">Public Contacts</h1>
            <p class="text-gray-600">Manage contact form submissions</p>
          </div>
          <div class="flex items-center space-x-4">
            <select
              v-model="statusFilter"
              @change="fetchContacts"
              class="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-slate-500 focus:border-slate-500"
            >
              <option value="">All Status</option>
              <option value="new">New</option>
              <option value="read">Read</option>
              <option value="responded">Responded</option>
              <option value="closed">Closed</option>
            </select>
            <button
              @click="fetchContacts"
              class="px-4 py-2 bg-slate-600 text-white rounded-lg hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-slate-500"
            >
              Refresh
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Loading State -->
      <div v-if="loading" class="flex justify-center items-center py-12">
        <div
          class="animate-spin rounded-full h-8 w-8 border-b-2 border-slate-600"
        ></div>
      </div>

      <!-- Error State -->
      <div
        v-else-if="error"
        class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-6"
      >
        <div class="flex items-center">
          <UIcon name="i-heroicons-x-circle" class="w-5 h-5 mr-2" />
          <span>{{ error }}</span>
        </div>
      </div>

      <!-- Contacts List -->
      <div v-else-if="contacts.length > 0" class="space-y-4">
        <div
          v-for="contact in contacts"
          :key="contact.id"
          class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
        >
          <div class="flex justify-between items-start mb-4">
            <div class="flex-1">
              <div class="flex items-center space-x-3 mb-2">
                <h3 class="text-lg font-semibold text-gray-900">
                  {{ contact.name }}
                </h3>
                <span
                  :class="getStatusClass(contact.status)"
                  class="px-2 py-1 text-xs font-medium rounded-full"
                >
                  {{
                    contact.status.charAt(0).toUpperCase() +
                    contact.status.slice(1)
                  }}
                </span>
              </div>
              <div
                class="flex items-center space-x-4 text-sm text-gray-600 mb-3"
              >
                <div class="flex items-center">
                  <UIcon name="i-heroicons-envelope" class="w-4 h-4 mr-1" />
                  <a
                    :href="`mailto:${contact.email}`"
                    class="hover:text-slate-600"
                    >{{ contact.email }}</a
                  >
                </div>
                <div class="flex items-center">
                  <UIcon name="i-heroicons-phone" class="w-4 h-4 mr-1" />
                  <a
                    :href="`tel:${contact.phone}`"
                    class="hover:text-slate-600"
                    >{{ contact.phone }}</a
                  >
                </div>
                <div class="flex items-center">
                  <UIcon name="i-heroicons-calendar" class="w-4 h-4 mr-1" />
                  <span>{{ formatDate(contact.created_at) }}</span>
                </div>
              </div>
            </div>
            <div class="flex items-center space-x-2">
              <button
                @click="updateContactStatus(contact.id, 'read')"
                v-if="contact.status === 'new'"
                class="px-3 py-1 text-sm bg-blue-100 text-blue-800 rounded-lg hover:bg-blue-200"
              >
                Mark as Read
              </button>
              <button
                @click="updateContactStatus(contact.id, 'responded')"
                v-if="contact.status === 'read'"
                class="px-3 py-1 text-sm bg-green-100 text-green-800 rounded-lg hover:bg-green-200"
              >
                Mark as Responded
              </button>
              <button
                @click="updateContactStatus(contact.id, 'closed')"
                v-if="contact.status === 'responded'"
                class="px-3 py-1 text-sm bg-gray-100 text-gray-800 rounded-lg hover:bg-gray-200"
              >
                Close
              </button>
            </div>
          </div>

          <div class="bg-gray-50 rounded-lg p-4">
            <p class="text-gray-800 whitespace-pre-wrap">
              {{ contact.message }}
            </p>
          </div>

          <div
            v-if="contact.admin_notes"
            class="mt-4 bg-yellow-50 border border-yellow-200 rounded-lg p-3"
          >
            <p class="text-sm text-yellow-800">
              <strong>Admin Notes:</strong> {{ contact.admin_notes }}
            </p>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center py-12">
        <UIcon
          name="i-heroicons-inbox"
          class="w-12 h-12 text-gray-400 mx-auto mb-4"
        />
        <h3 class="text-lg font-medium text-gray-900 mb-2">
          No contacts found
        </h3>
        <p class="text-gray-600">
          {{
            statusFilter
              ? "No contacts match the selected status filter."
              : "No contact submissions yet."
          }}
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { getPublicContacts, updatePublicContact } from "~/services/supportApi";

// Define page meta
definePageMeta({
  layout: "admin",
  middleware: "auth", // Add your auth middleware here
});

// Reactive data
const contacts = ref([]);
const loading = ref(true);
const error = ref("");
const statusFilter = ref("");

// Fetch contacts from API
const fetchContacts = async () => {
  try {
    loading.value = true;
    error.value = "";
    const response = await getPublicContacts(statusFilter.value);
    contacts.value = response.results || response; // Handle paginated or non-paginated response
  } catch (err) {
    console.error("Error fetching contacts:", err);
    error.value = "Failed to load contacts. Please try again.";
  } finally {
    loading.value = false;
  }
};

// Update contact status
const updateContactStatus = async (contactId, newStatus) => {
  try {
    await updatePublicContact(contactId, { status: newStatus });

    // Update local state
    const contactIndex = contacts.value.findIndex((c) => c.id === contactId);
    if (contactIndex !== -1) {
      contacts.value[contactIndex].status = newStatus;
    }
  } catch (err) {
    console.error("Error updating contact status:", err);
    error.value = "Failed to update contact status.";
  }
};

// Get status class for styling
const getStatusClass = (status) => {
  switch (status) {
    case "new":
      return "bg-red-100 text-red-800";
    case "read":
      return "bg-blue-100 text-blue-800";
    case "responded":
      return "bg-green-100 text-green-800";
    case "closed":
      return "bg-gray-100 text-gray-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

// Format date
const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

// Load contacts on component mount
onMounted(() => {
  fetchContacts();
});
</script>

<style scoped>
/* Add any additional styles here */
</style>
