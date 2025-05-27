// API service for eLearning platform
import { $fetch } from "ofetch";

// Simple in-memory cache implementation
const cache = {
  data: {},
  timeout: {},

  // Set a cache item with expiration
  set(key, value, expirationMs = 60 * 60 * 1000) {
    // Default: 1 hour
    this.data[key] = value;

    // Clear any existing timeout
    if (this.timeout[key]) {
      clearTimeout(this.timeout[key]);
    }

    // Set expiration timeout
    this.timeout[key] = setTimeout(() => {
      this.delete(key);
    }, expirationMs);
  },

  // Get a cache item
  get(key) {
    return this.data[key];
  },

  // Check if a cache item exists
  has(key) {
    return key in this.data;
  },

  // Delete a cache item
  delete(key) {
    delete this.data[key];
    if (this.timeout[key]) {
      clearTimeout(this.timeout[key]);
      delete this.timeout[key];
    }
  },

  // Clear all cache items
  clear() {
    Object.keys(this.timeout).forEach((key) => {
      clearTimeout(this.timeout[key]);
    });

    this.data = {};
    this.timeout = {};
  },
};

export const fetchBatches = async (baseURL = null) => {
  const cacheKey = "batches";

  // Return cached data if available
  if (cache.has(cacheKey)) {
    return cache.get(cacheKey);
  }

  try {
    // Use the provided baseURL or fallback to relative path for dev
    const apiUrl = baseURL
      ? `${baseURL}/api/elearning/batches/`
      : "/api/elearning/batches/";
    const data = await $fetch(apiUrl);

    // Cache the results for 1 day (batches rarely change)
    cache.set(cacheKey, data, 24 * 60 * 60 * 1000);
    return data;
  } catch (error) {
    console.error("Error fetching batches:", error);
    return [];
  }
};

export const fetchDivisionsForBatch = async (batchId, baseURL = null) => {
  const cacheKey = `divisions_for_batch_${batchId}`;

  // Return cached data if available
  if (cache.has(cacheKey)) {
    return cache.get(cacheKey);
  }

  try {
    const apiUrl = baseURL
      ? `${baseURL}/api/elearning/batches/${batchId}/divisions/`
      : `/api/elearning/batches/${batchId}/divisions/`;
    const data = await $fetch(apiUrl);

    // Cache the results for 12 hours (divisions rarely change)
    cache.set(cacheKey, data, 12 * 60 * 60 * 1000);
    return data;
  } catch (error) {
    console.error(`Error fetching divisions for batch ${batchId}:`, error);
    return [];
  }
};

export const fetchSubjectsForDivision = async (divisionId, baseURL = null) => {
  const cacheKey = `subjects_for_division_${divisionId}`;

  // Return cached data if available
  if (cache.has(cacheKey)) {
    return cache.get(cacheKey);
  }

  try {
    const apiUrl = baseURL
      ? `${baseURL}/api/elearning/divisions/${divisionId}/subjects/`
      : `/api/elearning/divisions/${divisionId}/subjects/`;
    const data = await $fetch(apiUrl);

    // Cache the results for 6 hours
    cache.set(cacheKey, data, 6 * 60 * 60 * 1000);
    return data;
  } catch (error) {
    console.error(`Error fetching subjects for division ${divisionId}:`, error);
    return [];
  }
};

export const fetchVideoLessonsForSubject = async (
  subjectId,
  baseURL = null
) => {
  const cacheKey = `videos_for_subject_${subjectId}`;

  // Return cached data if available
  if (cache.has(cacheKey)) {
    console.log(`Using cached videos for subject ${subjectId}`);
    return cache.get(cacheKey);
  }
  try {
    const apiUrl = baseURL
      ? `${baseURL}/api/elearning/subjects/${subjectId}/videos/`
      : `/api/elearning/subjects/${subjectId}/videos/`;
    const data = await $fetch(apiUrl);

    // Process and cache video metadata
    if (Array.isArray(data)) {
      // Add preloading information for thumbnails if available
      data.forEach((video) => {
        if (video.thumbnail_url) {
          // Preload the thumbnail in the background
          const img = new Image();
          img.src = video.thumbnail_url;
        }
      });

      // Cache the results for 1 hour (videos may be updated more frequently)
      cache.set(cacheKey, data, 1 * 60 * 60 * 1000);
      console.log(`Cached ${data.length} videos for subject ${subjectId}`);
    }

    return data;
  } catch (error) {
    console.error(`Error fetching videos for subject ${subjectId}:`, error);
    return [];
  }
};

export const incrementVideoViews = async (videoId, baseURL = null) => {
  try {
    const apiUrl = baseURL
      ? `${baseURL}/api/elearning/videos/${videoId}/increment_views/`
      : `/api/elearning/videos/${videoId}/increment_views/`;
    const result = await $fetch(apiUrl, {
      method: "POST",
    });

    // If the view was successfully updated, invalidate the cache for this video's subject
    if (result && result.success) {
      // Find the video in cache to determine which subject cache to invalidate
      Object.keys(cache.data).forEach((key) => {
        if (key.startsWith("videos_for_subject_") && cache.data[key]) {
          const videos = cache.data[key];

          // If we find the video in this subject's cache, invalidate the cache
          const videoExists = videos.some((video) => video.id === videoId);
          if (videoExists) {
            console.log(`Invalidating cache for ${key} after view increment`);
            cache.delete(key);
          }
        }
      });
    }

    return result;
  } catch (error) {
    console.error(`Error incrementing views for video ${videoId}:`, error);
    return null;
  }
};

/**
 * Fetch a single video by its ID
 * This will first check for the video in all cached subject videos
 * @param {string} videoId - The ID of the video to fetch
 * @returns {Promise<Object|null>} The video object or null if not found
 */
export const fetchVideoById = async (videoId, baseURL = null) => {
  // First check if the video exists in any of our cached subject videos
  let cachedVideo = null;

  Object.keys(cache.data).forEach((key) => {
    if (key.startsWith("videos_for_subject_") && !cachedVideo) {
      const videos = cache.data[key];
      cachedVideo = videos.find((video) => video.id === videoId);
    }
  });

  if (cachedVideo) {
    console.log(`Found video ${videoId} in cache`);
    return cachedVideo;
  }

  // If not in cache, fetch from API directly
  try {
    const apiUrl = baseURL
      ? `${baseURL}/api/elearning/videos/${videoId}/`
      : `/api/elearning/videos/${videoId}/`;
    const video = await $fetch(apiUrl);
    return video;
  } catch (error) {
    console.error(`Error fetching video ${videoId}:`, error);
    return null;
  }
};

/**
 * Clears all cached data or specific cache entries
 * @param {string} type - Optional. The type of cache to clear: 'batches', 'divisions', 'subjects', 'videos', or 'all'
 * @param {string} id - Optional. The specific ID to clear cache for (e.g., subject ID for videos)
 */
export const clearCache = (type = "all", id = null) => {
  if (type === "all") {
    cache.clear();
    console.log("All cache cleared");
    return;
  }

  switch (type) {
    case "batches":
      cache.delete("batches");
      console.log("Batches cache cleared");
      break;
    case "divisions":
      if (id) {
        cache.delete(`divisions_for_batch_${id}`);
        console.log(`Divisions cache cleared for batch ${id}`);
      } else {
        // Clear all division caches
        Object.keys(cache.data).forEach((key) => {
          if (key.startsWith("divisions_for_batch_")) {
            cache.delete(key);
          }
        });
        console.log("All divisions cache cleared");
      }
      break;
    case "subjects":
      if (id) {
        cache.delete(`subjects_for_division_${id}`);
        console.log(`Subjects cache cleared for division ${id}`);
      } else {
        // Clear all subject caches
        Object.keys(cache.data).forEach((key) => {
          if (key.startsWith("subjects_for_division_")) {
            cache.delete(key);
          }
        });
        console.log("All subjects cache cleared");
      }
      break;
    case "videos":
      if (id) {
        cache.delete(`videos_for_subject_${id}`);
        console.log(`Videos cache cleared for subject ${id}`);
      } else {
        // Clear all video caches
        Object.keys(cache.data).forEach((key) => {
          if (key.startsWith("videos_for_subject_")) {
            cache.delete(key);
          }
        });
        console.log("All videos cache cleared");
      }
      break;
    default:
      console.warn(`Unknown cache type: ${type}`);
  }
};
