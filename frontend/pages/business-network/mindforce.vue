<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 pt-3 flex-1">
    <!-- Header Component -->
    <MindForceHeader :is-creating="isCreating" @create="openCreateModal" />

    <!-- Main Content -->
    <div
      class="bg-white rounded-xl shadow-md border border-gray-100 transition-all"
    >
      <!-- Tabs & Search Component -->
      <MindForceTabsSearch
        :tabs="tabs"
        :active-tab="activeTab"
        :is-searching="isSearching"
        :search-query="searchQuery"
        @update:active-tab="activeTab = $event"
        @update:search-query="searchQuery = $event"
        @search="handleSearch"
      />

      <div class="px-2 py-3 mb-20">
        <!-- Active Problems Tab -->
        <div v-if="activeTab === 'active'" class="space-y-4">
          <!-- Skeleton loading state -->
          <div v-if="isLoading" class="space-y-4">
            <div
              v-for="i in 3"
              :key="i"
              class="bg-white border border-gray-100 rounded-lg px-2 py-3 animate-pulse"
            >
              <div class="flex justify-between items-start mb-3">
                <div class="flex items-center">
                  <div class="h-10 w-10 rounded-full bg-gray-200"></div>
                  <div class="ml-3">
                    <div class="h-4 w-32 bg-gray-200 rounded"></div>
                    <div class="h-3 w-24 bg-gray-200 rounded mt-2"></div>
                  </div>
                </div>
                <div class="h-6 w-24 bg-gray-200 rounded-full"></div>
              </div>
              <div class="h-4 w-16 bg-gray-200 rounded-full mb-3"></div>
              <div class="h-5 w-3/4 bg-gray-200 rounded mb-4"></div>
              <div class="flex justify-between items-center">
                <div class="flex space-x-3">
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                </div>
              </div>
            </div>
          </div>

          <div v-else-if="activeProblems?.length > 0" class="space-y-4">
            <MindForceProblemCard
              v-for="problem in activeProblems"
              :key="problem.id"
              :problem="problem"
              :current-user-id="user?.user?.id"
              @click="openProblemDetail(problem)"
              @photo-view="(index) => openPhotoViewer(problem, index)"
            />
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <p class="text-gray-500 mb-2">
                No active problems at the moment.
              </p>
              <button
                @click="openCreateModal"
                class="inline-flex items-center justify-center rounded-md text-sm sm:text-base font-medium text-blue-600 underline-offset-4 hover:text-blue-800 hover:underline transition-colors"
              >
                Post a problem
              </button>
            </div>
          </div>
        </div>

        <!-- Solved Problems Tab -->
        <div v-if="activeTab === 'solved'" class="space-y-4">
          <!-- Skeleton loading state -->
          <div v-if="isLoading" class="space-y-4">
            <div
              v-for="i in 3"
              :key="i"
              class="bg-white border border-gray-100 rounded-lg px-2 py-3 animate-pulse"
            >
              <div class="flex justify-between items-start mb-3">
                <div class="flex items-center">
                  <div class="h-10 w-10 rounded-full bg-gray-200"></div>
                  <div class="ml-3">
                    <div class="h-4 w-32 bg-gray-200 rounded"></div>
                    <div class="h-3 w-24 bg-gray-200 rounded mt-2"></div>
                  </div>
                </div>
                <div class="h-6 w-24 bg-gray-200 rounded-full"></div>
              </div>
              <div class="h-4 w-16 bg-gray-200 rounded-full mb-3"></div>
              <div class="h-5 w-3/4 bg-gray-200 rounded mb-4"></div>
              <div class="flex justify-between items-center">
                <div class="flex space-x-3">
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                  <div class="h-4 w-24 bg-gray-200 rounded"></div>
                </div>
                <div class="h-5 w-16 bg-gray-200 rounded-full"></div>
              </div>
            </div>
          </div>

          <div v-else-if="solvedProblems?.length > 0" class="space-y-4">
            <MindForceProblemCard
              v-for="problem in solvedProblems"
              :key="problem.id"
              :problem="problem"
              :current-user-id="user?.user?.id"
              @click="openProblemDetail(problem)"
              @photo-view="(index) => openPhotoViewer(problem, index)"
            />
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="mx-auto text-gray-400 mb-4"
              >
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
              </svg>
              <p class="text-gray-500">No solved problems yet.</p>
            </div>
          </div>
        </div>

        <!-- My Problems Tab -->
        <div v-if="activeTab === 'my-problems' && user" class="space-y-4">
          <div v-if="myProblems?.length > 0" class="space-y-4">
            <MindForceProblemCard
              v-for="problem in myProblems"
              :key="problem.id"
              :problem="problem"
              :current-user-id="user?.user?.id"
              @click="openProblemDetail(problem)"
              @photo-view="(index) => openPhotoViewer(problem, index)"
            />
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="mx-auto text-gray-400 mb-4"
              >
                <path
                  d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"
                ></path>
                <line x1="12" y1="9" x2="12" y2="13"></line>
                <line x1="12" y1="17" x2="12.01" y2="17"></line>
              </svg>
              <p class="text-gray-500 mb-2">
                You haven't posted any problems yet.
              </p>
              <button
                @click="openCreateModal"
                class="inline-flex items-center justify-center rounded-md text-md font-medium text-blue-600 underline-offset-4 hover:text-blue-800 hover:underline transition-colors"
              >
                Post your first problem
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modals and dialogs using components -->
    <MindForceCreateModal
      v-model="isCreateModalOpen"
      :categories="categories"
      :is-submitting="isSubmittingCreate"
      :initial-form-data="createForm"
      @submit="handleCreateProblem"
    />

    <MindForceDetailModal
      v-model="isDetailModalOpen"
      :problem="selectedProblem"
      :current-user-id="user?.user?.id"
      :is-submitting-comment="isSubmittingComment"
      :processing-comment-ids="processingCommentIds"
      @photo-view="(index) => openPhotoViewer(selectedProblem, index)"
      @mark-solution="markAsSolution"
      @add-comment="addComment"
      @delete="confirmDelete"
      @mark-as-solved="markProblemAsSolved"
    />

    <MindForceDeleteDialog
      v-model="isDeleteDialogOpen"
      @confirm="deleteProblem"
    />

    <MindForcePhotoViewer
      v-model="isPhotoViewerOpen"
      :photos="viewerPhotos"
      :current-photo-index="currentPhotoIndex"
      @update:current-index="currentPhotoIndex = $event"
    />
  </div>
</template>

<script setup>
import { Search, Plus, MessageSquare, Eye, CheckCircle } from "lucide-vue-next";
import { ref, computed, onMounted, onUnmounted } from "vue";
import MindForceHeader from "~/components/mindforce/MindForceHeader.vue";
import MindForceTabsSearch from "~/components/mindforce/MindForceTabsSearch.vue";
import MindForceProblemCard from "~/components/mindforce/MindForceProblemCard.vue";
import MindForceCreateModal from "~/components/mindforce/MindForceCreateModal.vue";
import MindForceDetailModal from "~/components/mindforce/MindForceDetailModal.vue";
import MindForceDeleteDialog from "~/components/mindforce/MindForceDeleteDialog.vue";
import MindForcePhotoViewer from "~/components/mindforce/MindForcePhotoViewer.vue";

definePageMeta({
  layout: "adsy-business-network",
  title: "MindForce - Business Network",
  meta: [
    {
      name: "description",
      content: "Connect with like-minded individuals and share your knowledge.",
    },
    {
      name: "keywords",
      content: "business, network, connect, share, knowledge",
    },
  ],
});

const { get, post, patch, del } = useApi();
const { user } = useAuth();

const toast = useToast();

// State
const isCreating = ref(false);
const isSearching = ref(false);
const searchQuery = ref("");
const activeTab = ref("active");
const isCreateModalOpen = ref(false);
const isDetailModalOpen = ref(false);
const selectedProblem = ref(null);
const isDeleteDialogOpen = ref(false);
const newComment = ref("");
const isSubmittingComment = ref(false);
const isSubmittingCreate = ref(false);
const isLoading = ref(true);
const isPhotoViewerOpen = ref(false);
const currentPhotoIndex = ref(0);
const viewerPhotos = ref([]);
const processingCommentIds = ref([]);

// Create form state with photos array
const createForm = ref({
  title: "",
  description: "",
  category: "",
  payment_option: "free",
  payment_amount: "",
  images: [],
});

// Tabs
const tabs = [
  { label: "Active Problems", value: "active" },
  { label: "Solved Problems", value: "solved" },
  { label: "My Problems", value: "my-problems" },
];

// Categories
const categories = ref([]);

async function fetchCategories() {
  try {
    const { data } = await get("/bn/mindforce/categories/");
    categories.value = data;
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}

// Sample data
const problems = ref([]);

async function fetchProblems() {
  try {
    isLoading.value = true;
    const { data } = await get("/bn/mindforce/");
    problems.value = data;
  } catch (error) {
    console.error("Error fetching problems:", error);
  } finally {
    isLoading.value = false;
  }
}

// Computed properties
const activeProblems = computed(() =>
  problems.value.filter((problem) => problem.status === "active")
);

const solvedProblems = computed(() =>
  problems.value.filter((problem) => problem.status === "solved")
);

const myProblems = computed(() =>
  problems.value.filter(
    (problem) => problem.user_details.id === user.value?.user?.id
  )
);

// Methods
const openCreateModal = () => {
  isCreating.value = true;
  setTimeout(() => {
    isCreating.value = false;
    isCreateModalOpen.value = true;
  }, 500);
};

const openProblemDetail = async (problem) => {
  if (!problem) return;

  selectedProblem.value = problem;
  isDetailModalOpen.value = true;

  try {
    // Fetch comments for the selected problem
    const commentsRes = await get(`/bn/mindforce/${problem.id}/comments/`);
    if (commentsRes.data) {
      // Update the comments in the selected problem - use mindforce_comments key
      selectedProblem.value.mindforce_comments = commentsRes.data;

      // Also update comments in the problems array
      const index = problems.value.findIndex((p) => p.id === problem.id);
      if (index !== -1) {
        problems.value[index].mindforce_comments = commentsRes.data;
      }
    }

    setTimeout(async () => {
      // Increment view count through API
      const res = await patch(`/bn/mindforce/${problem.id}/`, {
        views: problem.views + 1,
      });

      if (res.data) {
        // Update the view count locally
        problem.views += 1;
      }
    }, 7000);
  } catch (error) {
    console.error("Error updating problem details:", error);
  }
};

const handleSearch = () => {
  isSearching.value = true;
  setTimeout(() => {
    isSearching.value = false;
  }, 500);
};

const openPhotoViewer = (problem, index) => {
  if (problem?.media?.length) {
    viewerPhotos.value = problem.media;
    currentPhotoIndex.value = index;
    isPhotoViewerOpen.value = true;
  }
};

async function getProblemComments() {
  const commentsRes = await get(
    `/bn/mindforce/${selectedProblem.value.id}/comments/`
  );

  if (commentsRes.data) {
    // Update both the selected problem and the problems array
    selectedProblem.value.comments = commentsRes.data;

    // Find and update the problem in the problems list
    const index = problems.value.findIndex(
      (p) => p.id === selectedProblem.value.id
    );
    if (index !== -1) {
      problems.value[index].comments = commentsRes.data;
    }
  }
}

// Modified create problem function
const handleCreateProblem = async (formData) => {
  isSubmittingCreate.value = true;

  try {
    const res = await post("/bn/mindforce/", formData);
    if (res.data) {
      isCreateModalOpen.value = false;
      await fetchProblems();
      // Reset form
      createForm.value = {
        title: "",
        description: "",
        category: "",
        payment_option: "free",
        payment_amount: "",
        images: [],
      };
    }
  } finally {
    isSubmittingCreate.value = false;
  }
};

const confirmDelete = () => {
  isDetailModalOpen.value = false;
  isDeleteDialogOpen.value = true;
};

const deleteProblem = async () => {
  try {
    const res = await del(`/bn/mindforce/${selectedProblem.value.id}/`);
    if (res.data === undefined) {
      isDeleteDialogOpen.value = false;
      toast.add({
        title: "Success",
        description: "Problem deleted successfully",
      });
      await fetchProblems();
    }
  } catch (error) {
    toast.add({ title: "Error", description: "Failed to delete problem" });
  }
  isDeleteDialogOpen.value = false;
};

const markAsSolution = async (commentId) => {
  // Keep track of which comment is being processed
  processingCommentIds.value.push(commentId);

  try {
    // Make the API call to mark the comment as a solution
    const res = await patch(`/bn/mindforce/comments/${commentId}/`, {
      is_solved: true,
    });

    if (res.data.is_solved) {
      // Update the selected problem's comments
      if (selectedProblem.value && selectedProblem.value.mindforce_comments) {
        // Find and update the specific comment
        const commentIndex = selectedProblem.value.mindforce_comments.findIndex(
          (c) => c.id === commentId
        );
        if (commentIndex !== -1) {
          selectedProblem.value.mindforce_comments[
            commentIndex
          ].is_solved = true;
        }
      }

      // Also update in the main problems array
      const problemIndex = problems.value.findIndex(
        (p) => p.id === selectedProblem.value.id
      );
      if (
        problemIndex !== -1 &&
        problems.value[problemIndex].mindforce_comments
      ) {
        const commentIndex = problems.value[
          problemIndex
        ].mindforce_comments.findIndex((c) => c.id === commentId);
        if (commentIndex !== -1) {
          problems.value[problemIndex].mindforce_comments[
            commentIndex
          ].is_solved = true;
        }
      }
    }
  } catch (error) {
    console.error("Error marking solution:", error);
    alert("Failed to mark as solution. Please try again.");
  } finally {
    processingCommentIds.value = processingCommentIds.value.filter(
      (id) => id !== commentId
    );
  }
};

const addComment = async (commentText) => {
  if (!commentText.trim()) return;

  // Check if the problem is already solved
  if (selectedProblem.value.status === "solved") {
    alert("Comments cannot be added to solved problems.");
    return;
  }

  isSubmittingComment.value = true;

  try {
    // Initialize mindforce_comments array if needed
    if (!selectedProblem.value.mindforce_comments) {
      selectedProblem.value.mindforce_comments = [];
    }

    const res = await post(
      `/bn/mindforce/${selectedProblem.value.id}/comments/`,
      {
        comment: commentText,
      }
    );

    if (res.data) {
      // The modal component will handle displaying the comment via its local state
      // We don't need to update the comments array here
      // This prevents duplicate comments
    }
  } catch (error) {
    console.error("Error adding comment:", error);
    if (
      error.response &&
      error.response.data &&
      error.response.data.detail === "Cannot comment on solved problems"
    ) {
      alert("This problem has been marked as solved. Comments are disabled.");
    } else {
      alert("Failed to add comment. Please try again later.");
    }
  } finally {
    isSubmittingComment.value = false;
  }
};

const markProblemAsSolved = async () => {
  if (!selectedProblem.value) return;

  try {
    // Make sure we're updating the correct problem
    const problemId = selectedProblem.value.id;

    // Call the API to update the problem status
    const res = await patch(`/bn/mindforce/${problemId}/`, {
      status: "solved",
    });

    if (res.data && res.data.status === "solved") {
      // Update the problem in the local state
      const index = problems.value.findIndex((p) => p.id === problemId);
      if (index !== -1) {
        problems.value[index].status = "solved";
      }

      // Close the modal and refresh problems to ensure everything is up-to-date
      isDetailModalOpen.value = false;
      await fetchProblems();
    } else {
      console.error(
        "Error marking problem as solved: Unexpected response",
        res.data
      );
      alert("Could not mark the problem as solved. Please try again.");
    }
  } catch (error) {
    console.error("Error marking problem as solved:", error);
    alert(
      "An error occurred while marking the problem as solved. Please try again."
    );
  }
};

// Initialize data
onMounted(async () => {
  await Promise.all([fetchCategories(), fetchProblems()]);
});
</script>

<style scoped>
/* Add smooth transition for all elements */
* {
  transition-property: background-color, border-color, color, fill, stroke,
    opacity, box-shadow, transform;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}

/* Force proper viewport behavior */
@media (max-width: 640px) {
  html,
  body {
    max-width: 100%;
    overflow-x: hidden;
  }
}
</style>
