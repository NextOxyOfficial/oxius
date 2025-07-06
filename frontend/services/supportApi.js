// API service for support and public contact
import { $fetch } from "ofetch";

// Get the base URL from environment variables
const getBaseUrl = () => {
  const config = useRuntimeConfig();
  return config.public.baseURL || "http://localhost:8000";
};

// Create a public contact submission
export const createPublicContact = async (contactData) => {
  try {
    const response = await $fetch("/api/support/public-contact/", {
      method: "POST",
      baseURL: getBaseUrl(),
      body: contactData,
      headers: {
        "Content-Type": "application/json",
      },
    });
    return response;
  } catch (error) {
    console.error("Error creating public contact:", error);
    throw error;
  }
};

// Get all public contacts (admin only)
export const getPublicContacts = async (status = null) => {
  try {
    const query = status ? `?status=${status}` : "";
    const response = await $fetch(`/api/support/public-contacts/${query}`, {
      method: "GET",
      baseURL: getBaseUrl(),
      headers: {
        Authorization: `Bearer ${getAuthToken()}`,
      },
    });
    return response;
  } catch (error) {
    console.error("Error fetching public contacts:", error);
    throw error;
  }
};

// Get a specific public contact (admin only)
export const getPublicContact = async (contactId) => {
  try {
    const response = await $fetch(
      `/api/support/public-contacts/${contactId}/`,
      {
        method: "GET",
        baseURL: getBaseUrl(),
        headers: {
          Authorization: `Bearer ${getAuthToken()}`,
        },
      }
    );
    return response;
  } catch (error) {
    console.error("Error fetching public contact:", error);
    throw error;
  }
};

// Update a public contact (admin only)
export const updatePublicContact = async (contactId, updateData) => {
  try {
    const response = await $fetch(
      `/api/support/public-contacts/${contactId}/`,
      {
        method: "PATCH",
        baseURL: getBaseUrl(),
        body: updateData,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getAuthToken()}`,
        },
      }
    );
    return response;
  } catch (error) {
    console.error("Error updating public contact:", error);
    throw error;
  }
};

// Helper function to get auth token (implement based on your auth system)
const getAuthToken = () => {
  // This should be implemented based on your authentication system
  // For example, from localStorage, cookies, or Pinia store
  if (process.client) {
    return localStorage.getItem("authToken") || "";
  }
  return "";
};
