<template>
  <PublicSection>
    <UContainer class="py-8">
      <!-- Header with 3D layered effect -->
      <!-- Header with premium glass effect design -->
      <!-- Header with clean, modern design -->
      <div class="inbox-header relative overflow-hidden rounded-xl mb-8">
        <!-- Simple gradient background -->
        <div
          class="absolute inset-0 bg-gradient-to-br from-gray-50 to-primary-50"
        ></div>

        <!-- Subtle animated dots pattern -->
        <div class="absolute inset-0 dot-pattern opacity-10"></div>

        <!-- Minimal glass effect -->
        <div class="absolute inset-0 backdrop-blur-[1px] opacity-40"></div>

        <!-- Content -->
        <div class="relative z-10 p-6 sm:p-8">
          <div
            class="flex flex-col sm:flex-row sm:items-center justify-between gap-3"
          >
            <div class="flex items-center">
              <!-- Clean icon with subtle animation -->
              <div class="inbox-icon mr-4">
                <div
                  class="flex items-center justify-center h-12 w-12 rounded-xl bg-white bg-opacity-80 shadow-sm"
                >
                  <UIcon
                    name="i-heroicons-inbox"
                    class="text-primary-600 text-2xl inbox-icon-anim"
                  />
                </div>
              </div>

              <!-- Clean typography -->
              <div>
                <h1 class="text-2xl sm:text-3xl font-bold text-gray-800">
                  Message Center
                </h1>
                <p class="text-gray-500 text-sm mt-1">
                  All your notifications in one place
                </p>
              </div>
            </div>

            <!-- Simple message counter -->
            <div v-if="messages.length" class="counter-badge">
              <span>{{ messages.length }}</span>
              <span class="text-sm ml-1">{{
                messages.length === 1 ? "message" : "messages"
              }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Account balance card -->
      <div class="mb-8">
        <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
      </div>

      <!-- Message filtering options -->
      <div class="flex flex-wrap gap-3 mb-6">
        <UButton
          variant="soft"
          color="primary"
          label="All Messages"
          icon="i-heroicons-inbox"
          class="filter-btn active"
        />
        <UButton
          variant="soft"
          color="gray"
          icon="i-heroicons-envelope"
          label="Unread"
          class="filter-btn"
        />
        <!-- <UButton
          variant="soft"
          color="gray"
          icon="i-heroicons-bell"
          label="Notifications"
          class="filter-btn"
        /> -->
        <div class="ml-auto">
          <UInput
            placeholder="Search messages..."
            icon="i-heroicons-magnifying-glass"
            size="md"
            class="max-w-xs search-input"
          />
        </div>
      </div>

      <!-- Messages List -->
      <div v-if="messages && messages.length" class="space-y-4">
        <TransitionGroup name="message-list" tag="div" class="space-y-5">
          <div
            v-for="message in messages"
            :key="message.id"
            class="message-card"
            :class="{ unread: !readMessages[message.id] }"
          >
            <!-- Message header -->
            <div
              class="message-header"
              :class="expandedMessages[message.id] ? 'expanded' : ''"
              @click="toggleMessage(message.id)"
            >
              <!-- Status indicator -->
              <div
                class="status-indicator"
                :class="{ active: !readMessages[message.id] }"
              ></div>

              <!-- Left side: message info -->
              <div class="flex items-center gap-3 flex-1 min-w-0">
                <div class="flex-shrink-0">
                  <div class="message-icon-circle">
                    <UIcon
                      :name="
                        readMessages[message.id]
                          ? 'i-heroicons-envelope-open'
                          : 'i-heroicons-envelope'
                      "
                      class="message-type-icon"
                      :class="readMessages[message.id] ? 'read' : 'unread'"
                    />
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <div
                    class="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2"
                  >
                    <span class="message-id"
                      >#{{ message.id.toString().padStart(4, "0") }}</span
                    >
                    <h3
                      class="message-title line-clamp-1"
                      :class="{ 'font-semibold': !readMessages[message.id] }"
                    >
                      {{ message.title }}
                    </h3>
                    <UBadge
                      v-if="!readMessages[message.id]"
                      color="primary"
                      class="new-badge"
                      >New</UBadge
                    >
                  </div>
                  <div class="message-meta">
                    <span>{{ formatDate(message.created_at) }}</span>
                    <span class="message-meta-dot">•</span>
                    <span>System</span>
                  </div>
                </div>
              </div>

              <!-- Right side: actions -->
              <div class="message-actions">
                <UButton
                  color="gray"
                  variant="ghost"
                  :icon="
                    expandedMessages[message.id]
                      ? 'i-heroicons-chevron-up'
                      : 'i-heroicons-chevron-down'
                  "
                  size="sm"
                  class="toggle-btn"
                />
              </div>
            </div>

            <!-- Message content -->
            <transition
              name="slide-fade"
              @enter="startTransition"
              @after-enter="endTransition"
              @before-leave="startTransition"
              @after-leave="endTransition"
            >
              <div v-if="expandedMessages[message.id]" class="message-content">
                <div class="message-body">
                  <div class="message-text">
                    <p>{{ message.message }}</p>
                  </div>

                  <div class="message-footer">
                    <span class="message-sender">Sent by System</span>
                    <UButton
                      size="xs"
                      color="primary"
                      variant="soft"
                      label="Mark as read"
                      icon="i-heroicons-check"
                      @click.stop="markAsRead(message.id)"
                      v-if="!readMessages[message.id]"
                    />
                  </div>
                </div>
              </div>
            </transition>
          </div>
        </TransitionGroup>
      </div>

      <!-- Empty state -->
      <transition name="scale-fade">
        <div v-if="!messages.length && !isLoading" class="empty-inbox">
          <div class="empty-animation">
            <div class="empty-paper"></div>
            <div class="empty-paper"></div>
            <div class="empty-inbox-icon">
              <UIcon name="i-heroicons-inbox" class="text-5xl text-white" />
            </div>
          </div>
          <h3 class="empty-title">Your inbox is empty</h3>
          <p class="empty-description">
            You don't have any messages yet. System notifications and important
            updates will appear here.
          </p>
        </div>
      </transition>

      <!-- Loading state -->
      <div v-if="isLoading" class="loading-state">
        <div class="loading-icon">
          <svg viewBox="0 0 24 24" class="loading-circle">
            <circle cx="12" cy="12" r="10" class="loading-track"></circle>
            <circle cx="12" cy="12" r="10" class="loading-path"></circle>
          </svg>
          <UIcon name="i-heroicons-envelope" class="loading-envelope" />
        </div>
        <p class="loading-text">Loading your messages...</p>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
// Script remains largely the same as your current implementation
const { user } = useAuth();
const messages = ref([]);
const { get } = useApi();
const { formatDate } = useUtils();
const expandedMessages = ref({});
const readMessages = ref({});
const isLoading = ref(true);

function toggleMessage(id) {
  expandedMessages.value = {
    ...expandedMessages.value,
    [id]: !expandedMessages.value[id],
  };

  if (!readMessages.value[id] && expandedMessages.value[id]) {
    markAsRead(id);
  }
}

function markAsRead(id) {
  readMessages.value = {
    ...readMessages.value,
    [id]: true,
  };
}

function startTransition(el) {
  el.style.height = "auto";
  const height = el.scrollHeight;
  el.style.height = "0px";
  el.offsetHeight;
  el.style.height = height + "px";
}

function endTransition(el) {
  el.style.height = "";
}

async function getAdminMessages() {
  isLoading.value = true;
  try {
    const res = await get("/admin-notice/");
    messages.value = res.data;

    messages.value.forEach((msg) => {
      expandedMessages.value[msg.id] = false;
      readMessages.value[msg.id] = false;
    });
  } catch (error) {
    console.error("Error fetching messages:", error);
  } finally {
    setTimeout(() => {
      isLoading.value = false;
    }, 800); // Add slight delay for loading animation
  }
}

onMounted(() => {
  getAdminMessages();
});
</script>

<style scoped>
/* Background pattern */
.bg-pattern {
  background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.15'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}

/* Inbox Header Animation */
.inbox-header {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

.message-icon-container {
  position: relative;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.message-icon-container::before {
  content: "";
  position: absolute;
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    transform: scale(0.95);
    opacity: 0.7;
  }
  50% {
    transform: scale(1.05);
    opacity: 0.4;
  }
  100% {
    transform: scale(0.95);
    opacity: 0.7;
  }
}

/* Message Card Styling */
.message-card {
  background-color: white;
  border-radius: 0.75rem;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  border: 1px solid rgba(229, 231, 235, 1);
  transition: all 0.3s ease;
}

.message-card:hover {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1),
    0 2px 4px -1px rgba(0, 0, 0, 0.06);
  transform: translateY(-2px);
}

.message-card.unread {
  border-color: rgba(79, 70, 229, 0.3);
}

.status-indicator {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background-color: transparent;
  transition: all 0.3s ease;
}

.status-indicator.active {
  background-color: #4f46e5;
}

.message-header {
  position: relative;
  display: flex;
  align-items: center;
  padding: 1rem 1.25rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.message-header:hover {
  background-color: rgba(249, 250, 251, 0.8);
}

.message-header.expanded {
  background-color: rgba(243, 244, 246, 0.8);
}

.message-icon-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  background-color: #f3f4f6;
}

.message-type-icon {
  font-size: 1.25rem;
  transition: all 0.3s ease;
}

.message-type-icon.unread {
  color: #4f46e5;
}

.message-type-icon.read {
  color: #9ca3af;
}

.message-id {
  font-family: monospace;
  font-size: 0.75rem;
  color: #6b7280;
  white-space: nowrap;
}

.message-title {
  font-size: 0.95rem;
  color: #1f2937;
  transition: all 0.2s ease;
}

.message-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #6b7280;
  font-size: 0.75rem;
  margin-top: 0.25rem;
}

.message-meta-dot {
  opacity: 0.5;
}

.new-badge {
  font-size: 0.65rem;
  padding: 0.125rem 0.375rem;
}

.message-actions {
  display: flex;
  align-items: center;
}

.toggle-btn {
  padding: 0;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  transition: all 0.3s ease;
}

.toggle-btn:hover {
  background-color: rgba(243, 244, 246, 0.8);
}

/* Message Content */
.message-content {
  overflow: hidden;
  transition: height 0.3s ease;
}

.message-body {
  padding: 1.25rem;
  background-color: #f9fafb;
  border-top: 1px solid rgba(229, 231, 235, 0.5);
}

.message-text {
  font-size: 0.9375rem;
  line-height: 1.6;
  color: #374151;
  white-space: pre-wrap;
}

.message-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  margin-top: 1rem;
  border-top: 1px solid rgba(229, 231, 235, 0.5);
}

.message-sender {
  font-size: 0.75rem;
  color: #6b7280;
}

/* Filter buttons */
.filter-btn {
  transition: all 0.3s ease;
}

.filter-btn:hover {
  transform: translateY(-1px);
}

.filter-btn.active {
  background-color: rgba(79, 70, 229, 0.1);
  color: #4f46e5;
  font-weight: 500;
}

.search-input {
  transition: all 0.3s ease;
}

.search-input:focus-within {
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

/* Empty state styling */
.empty-inbox {
  background: linear-gradient(
    180deg,
    rgba(249, 250, 251, 0.7) 0%,
    rgba(255, 255, 255, 1) 100%
  );
  border-radius: 1rem;
  padding: 4rem 2rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 1px 2px rgba(0, 0, 0, 0.1);
}

.empty-animation {
  position: relative;
  width: 100px;
  height: 100px;
  margin-bottom: 2rem;
}

.empty-inbox-icon {
  position: absolute;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background-color: #6366f1;
  display: flex;
  align-items: center;
  justify-content: center;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  animation: float 4s ease-in-out infinite;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

.empty-paper {
  position: absolute;
  width: 30px;
  height: 40px;
  background: white;
  border-radius: 3px;
}

.empty-paper:first-child {
  left: 20%;
  top: 30%;
  transform: rotate(-15deg);
  animation: paper1 5s ease-in-out infinite;
}

.empty-paper:nth-child(2) {
  right: 20%;
  top: 35%;
  transform: rotate(10deg);
  animation: paper2 4s ease-in-out infinite;
}

.empty-title {
  font-size: 1.5rem;
  color: #374151;
  font-weight: 600;
  margin-bottom: 0.75rem;
}

.empty-description {
  font-size: 0.9375rem;
  color: #6b7280;
  max-width: 24rem;
  margin: 0 auto;
}

/* Loading state */
.loading-state {
  padding: 4rem 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.loading-icon {
  position: relative;
  width: 60px;
  height: 60px;
  margin-bottom: 1rem;
}

.loading-circle {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.loading-track {
  fill: none;
  stroke: #e5e7eb;
  stroke-width: 2;
}

.loading-path {
  fill: none;
  stroke: #6366f1;
  stroke-width: 2;
  stroke-dasharray: 63;
  stroke-dashoffset: 63;
  animation: loadingCircle 1.5s infinite;
}

.loading-envelope {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 1.5rem;
  color: #6366f1;
}

.loading-text {
  font-size: 0.9375rem;
  color: #6b7280;
}

/* Animations */
@keyframes loadingCircle {
  0% {
    stroke-dashoffset: 63;
  }
  50% {
    stroke-dashoffset: 0;
  }
  100% {
    stroke-dashoffset: -63;
  }
}

@keyframes float {
  0%,
  100% {
    transform: translate(-50%, -50%);
  }
  50% {
    transform: translate(-50%, -60%);
  }
}

@keyframes paper1 {
  0%,
  100% {
    transform: rotate(-15deg) translateY(0);
    opacity: 0.8;
  }
  50% {
    transform: rotate(-20deg) translateY(-15px);
    opacity: 0.5;
  }
}

@keyframes paper2 {
  0%,
  100% {
    transform: rotate(10deg) translateY(0);
    opacity: 0.7;
  }
  50% {
    transform: rotate(15deg) translateY(-10px);
    opacity: 0.4;
  }
}

/* Transition animations */
.message-list-enter-active,
.message-list-leave-active {
  transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

.message-list-enter-from,
.message-list-leave-to {
  opacity: 0;
  transform: translateY(30px);
}

.message-list-move {
  transition: transform 0.8s ease;
}

.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
}

.slide-fade-enter-from,
.slide-fade-leave-to {
  transform-origin: top;
  opacity: 0;
}

.scale-fade-enter-active,
.scale-fade-leave-active {
  transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

.scale-fade-enter-from,
.scale-fade-leave-to {
  opacity: 0;
  transform: scale(0.95);
}

/* Responsive styles */
@media (max-width: 640px) {
  .message-meta {
    flex-wrap: wrap;
    gap: 0.25rem;
  }

  .message-meta-dot {
    display: none;
  }

  .message-header {
    padding: 0.75rem 1rem;
  }

  .message-icon-circle {
    width: 36px;
    height: 36px;
  }

  .message-body {
    padding: 1rem;
  }

  .toggle-btn {
    width: 28px;
    height: 28px;
  }

  .inbox-header {
    border-radius: 0.5rem;
  }
}
/* Clean, modern inbox header styling */
.inbox-header {
  box-shadow: 0 4px 15px -3px rgba(0, 0, 0, 0.05);
  border: 1px solid rgba(229, 231, 235, 0.6);
}

/* Subtle animated pattern */
.dot-pattern {
  background-image: radial-gradient(circle, currentColor 1px, transparent 1px);
  background-size: 30px 30px;
}

/* Simple icon animation */
.inbox-icon-anim {
  animation: gentle-bounce 3s ease-in-out infinite;
}

@keyframes gentle-bounce {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-3px);
  }
}

/* Clean counter badge */
.counter-badge {
  display: inline-flex;
  align-items: center;
  background-color: white;
  color: var(--color-primary-600);
  padding: 0.5rem 0.875rem;
  border-radius: 0.5rem;
  font-weight: 500;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  border: 1px solid rgba(229, 231, 235, 0.8);
  position: relative;
  overflow: hidden;
}

.counter-badge::before {
  content: "";
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.5),
    transparent
  );
  animation: shine 3s infinite;
}

@keyframes shine {
  0% {
    left: -100%;
  }
  20%,
  100% {
    left: 100%;
  }
}

/* Responsive adjustments */
@media (max-width: 640px) {
  .inbox-header {
    border-radius: 0.75rem;
  }

  .inbox-icon {
    margin-right: 0.75rem;
  }
}
</style>
