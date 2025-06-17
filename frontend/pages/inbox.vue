<template>
  <PublicSection>
    <UContainer class="py-0 sm:py-8">
      
      <div
        class="inbox-header relative overflow-hidden rounded-xl mb-3 sm:mb-8"
      >
        <!-- Simple gradient background -->
        <div
          class="absolute inset-0 bg-gradient-to-br from-gray-50 to-primary-50"
        ></div>

        <!-- Subtle animated dots pattern -->
        <div class="absolute inset-0 dot-pattern opacity-10"></div>

        <!-- Minimal glass effect -->
        <div class="absolute inset-0 backdrop-blur-[1px] opacity-40 bg-green-300"></div>

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
                    class="text-primary-600 text-xl inbox-icon-anim"
                  />
                </div>
              </div>

              <!-- Clean typography -->
              <div>
                <h1 class="text-xl sm:text-2xl font-semibold text-gray-800">
                  {{ $t("message_center") }}
                </h1>
                <p class="text-gray-600 text-sm mt-1">
                  {{ $t("message_center_text") }}
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

      <!-- Notification banner for new messages -->
      <transition name="scale-fade">
        <div
          v-if="newMessageCount > 0"
          class="notification-banner mb-6 p-4 rounded-lg flex items-center justify-between"
          :class="{ 'bg-primary-50 border border-primary-200': true }"
        >
          <div class="flex items-center gap-3">
            <div
              class="notification-icon flex items-center justify-center h-10 w-10 rounded-full bg-primary-100"
            >
              <UIcon name="i-heroicons-bell" class="text-primary-600" />
            </div>
            <div>
              <h3 class="font-medium text-gray-800">
                {{ newMessageCount }} New
                {{ newMessageCount === 1 ? "Message" : "Messages" }}
              </h3>
              <p class="text-sm text-gray-600">
                {{
                  newTicketCount > 0
                    ? `Including ${newTicketCount} support ${
                        newTicketCount === 1 ? "ticket" : "tickets"
                      }`
                    : "Check your inbox for details"
                }}
              </p>
            </div>
          </div>
          <UButton
            color="primary"
            variant="soft"
            size="sm"
            label="Dismiss"
            @click="clearNotifications"
          />
        </div>
      </transition>      <!-- Open Ticket and Mark All Read buttons -->
      <div class="flex flex-row justify-between items-center gap-3 mb-4 px-4">
        <UButton
          color="primary"
          label="Open Ticket"
          icon="i-heroicons-plus"
          @click="openNewTicketModal"
          class="flex-shrink-0"
        />
        <UButton
          color="gray"
          variant="soft"
          icon="i-heroicons-check-circle"
          :disabled="!hasUnreadMessages"
          @click="markAllAsRead"
          :title="`Mark all unread ${activeTab === 'support' ? 'tickets' : 'updates'} in this tab as read`"
          class="mark-all-read-btn flex-shrink-0"
          size="sm"
        >
          <span class="hidden sm:inline">Mark All Read</span>
          <span class="sm:hidden">Mark All Read</span>
        </UButton>
      </div>

      <!-- Tabbed Navigation -->
      <div class="mb-2 border-b border-gray-200">
        <nav class="flex space-x-8 px-4">
          <button
            @click="setActiveTab('updates')"
            :class="[
              'py-2 px-1 border-b-2 font-medium text-sm transition-colors',
              activeTab === 'updates'
                ? 'border-primary-500 text-primary-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
          >
            <UIcon name="i-heroicons-bell" class="mr-2" />
            Updates            <span
              v-if="updatesCount > 0"
              class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-200 text-red-800"
            >
              {{ updatesCount }}
            </span>
          </button>
          <button
            @click="setActiveTab('support')"
            :class="[
              'py-2 px-1 border-b-2 font-medium text-sm transition-colors',
              activeTab === 'support'
                ? 'border-primary-500 text-primary-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
          >
            <UIcon name="i-heroicons-chat-bubble-left-right" class="mr-2" />
            Support Tickets            <span
              v-if="supportTicketsCount > 0"
              class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-200 text-red-800"
            >
              {{ supportTicketsCount }}
            </span>
          </button>
        </nav>
      </div>      
      <!-- Unified Content Area with Filtering -->
      <div class="sm:px-4">
        <!-- Unified Filtering Bar -->
        <div class="flex flex-wrap gap-2 mb-2 p-2 bg-gray-50 rounded-lg border border-gray-200">
          <!-- Tab specific filters -->
          <div v-if="activeTab === 'support'" class="flex flex-wrap gap-2 flex-1">
            <UButton
              variant="soft"
              :class="{ active: ticketStatusFilter === 'all' }"
              @click="setTicketStatusFilter('all')"
              label="All Tickets"
            />
            <UButton
              variant="soft"
              color="amber"
              :class="{ active: ticketStatusFilter === 'open' }"
              @click="setTicketStatusFilter('open')"
              label="Open"
            />
            <UButton
              variant="soft"
              color="blue"
              :class="{ active: ticketStatusFilter === 'in_progress' }"
              @click="setTicketStatusFilter('in_progress')"
              label="In Progress"
            />
            <UButton
              variant="soft"
              color="green"
              :class="{ active: ticketStatusFilter === 'resolved' }"
              @click="setTicketStatusFilter('resolved')"
              label="Resolved"
            />
            <UButton
              variant="soft"
              color="gray"
              :class="{ active: ticketStatusFilter === 'closed' }"
              @click="setTicketStatusFilter('closed')"
              label="Closed"
            />
          </div>          <div v-if="activeTab === 'updates'" class="flex flex-wrap gap-2 flex-1">
            <UButton
              variant="soft"
              :class="{ active: updatesFilter === 'all' }"
              @click="setUpdatesFilter('all')"
              label="All Updates"
            />
            <UButton
              variant="soft"
              color="green"
              :class="{ active: updatesFilter === 'order_received' }"
              @click="setUpdatesFilter('order_received')"
              label="Orders"
            />
            <UButton
              variant="soft"
              color="blue"
              :class="{ active: updatesFilter === 'withdraw_successful' }"
              @click="setUpdatesFilter('withdraw_successful')"
              label="Withdrawals"
            />
            <UButton
              variant="soft"
              color="orange"
              :class="{ active: updatesFilter === 'mobile_recharge_successful' }"
              @click="setUpdatesFilter('mobile_recharge_successful')"
              label="Recharges"
            />
            <UButton
              variant="soft"
              color="purple"
              :class="{ active: updatesFilter === 'pro_subscribed' }"
              @click="setUpdatesFilter('pro_subscribed')"
              label="Pro"
            />
            <UButton
              variant="soft"
              color="amber"
              :class="{ active: updatesFilter === 'pro_expiring' }"
              @click="setUpdatesFilter('pro_expiring')"
              label="Expiring"
            />            
            <UButton
              variant="soft"
              color="gray"
              :class="{ active: updatesFilter === 'gig_posted' }"
              @click="setUpdatesFilter('gig_posted')"
              label="Gigs"
            />
            <UButton
              variant="soft"
              color="cyan"
              :class="{ active: updatesFilter === 'transfer_sent' }"
              @click="setUpdatesFilter('transfer_sent')"
              label="Transfers Sent"
            />
            <UButton
              variant="soft"
              color="emerald"
              :class="{ active: updatesFilter === 'transfer_received' }"
              @click="setUpdatesFilter('transfer_received')"
              label="Transfers Received"
            />
            <UButton
              variant="soft"
              color="teal"
              :class="{ active: updatesFilter === 'deposit_successful' }"
              @click="setUpdatesFilter('deposit_successful')"
              label="Deposits"
            />
          </div>            <!-- Refresh button (always visible) -->
          <UButton
            color="gray"
            variant="soft"
            icon="i-heroicons-arrow-path"
            :loading="isLoading"
            @click="refreshMessages"
            :title="`Refresh ${activeTab === 'support' ? 'tickets' : 'updates'}`"
          />
        </div>

        <!-- Unified Content List with Stripe Design -->
        <div class="bg-white border border-gray-200 rounded-lg overflow-hidden">          <!-- Support Tickets Content -->
          <div v-if="activeTab === 'support'">
            <div v-if="supportTickets && supportTickets.length">
              <TransitionGroup name="message-list" tag="div">
                <div
                  v-for="(ticket, index) in filteredSupportTickets"
                  :key="ticket.id"
                  class="unified-message-item border-b border-gray-100 hover:bg-gray-50 transition-colors duration-200"
                  :class="{ 
                    'unread': !readMessages[ticket.id],
                    'border-b-0': index === filteredSupportTickets.length - 1
                  }"
                >
                  <div
                    class="flex items-center gap-2 p-2 cursor-pointer"
                    @click="openTicketDetail(ticket)"
                  >
                    <!-- Left Status Stripe -->
                    <div 
                      class="w-1 h-12 rounded-full"
                      :class="{
                        'bg-red-500': !readMessages[ticket.id],
                        'bg-gray-300': readMessages[ticket.id]
                      }"
                    ></div>

                    <!-- Icon -->
                    <div class="flex-shrink-0">
                      <div
                        class="w-10 h-10 rounded-full flex items-center justify-center border-2"
                        :class="{
                          'bg-amber-50 border-amber-200': ticket.status === 'open',
                          'bg-blue-50 border-blue-200': ticket.status === 'in_progress',
                          'bg-green-50 border-green-200': ['resolved', 'closed'].includes(ticket.status),
                          'bg-gray-50 border-gray-200': !ticket.status
                        }"
                      >
                        <UIcon
                          name="i-heroicons-chat-bubble-left-right"
                          class="w-5 h-5"
                          :class="{
                            'text-amber-600': ticket.status === 'open',
                            'text-blue-600': ticket.status === 'in_progress',
                            'text-green-600': ['resolved', 'closed'].includes(ticket.status),
                            'text-gray-600': !ticket.status
                          }"
                        />
                      </div>
                    </div>

                    <!-- Content -->
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center justify-between mb-1">
                        <div class="flex items-center gap-2">
                          <span class="text-sm font-mono text-gray-500">
                            #{{ ticket.id.toString().padStart(10, "0") }}
                          </span>
                          <UBadge
                            :color="readMessages[ticket.id] ? 'gray' : 'primary'"
                            size="xs"
                            class="cursor-pointer"
                            @click="toggleReadStatus(ticket.id, $event)"
                          >
                            {{ readMessageLabel(ticket.id) }}
                          </UBadge>
                          <UBadge
                            :color="getTicketStatusColor(ticket.status)"
                            size="xs"
                          >
                            {{ formatTicketStatus(ticket.status) }}
                          </UBadge>
                        </div>
                        <span class="text-xs text-gray-500">
                          {{ formatDate(ticket.created_at) }}
                        </span>
                      </div>
                      <h3 
                        class="text-sm font-medium text-gray-900 line-clamp-1 mb-1"
                        :class="{ 'font-semibold': !readMessages[ticket.id] }"
                      >
                        {{ ticket.title }}
                      </h3>
                      <p class="text-xs text-gray-600 line-clamp-1">
                        Support Ticket
                      </p>
                    </div>
                  </div>
                </div>
              </TransitionGroup>
              
              <!-- Load More Button for Support Tickets -->
              <div v-if="hasMoreItems" class="p-4 text-center border-t border-gray-100">
                <UButton
                  color="primary"
                  variant="outline"
                  :loading="isLoadingMore"
                  @click="loadMoreItems"
                  size="sm"
                  icon="i-heroicons-arrow-down-circle"
                >
                  <template v-if="isLoadingMore">
                    Loading more...
                  </template>
                  <template v-else>
                    Load More Tickets
                  </template>
                </UButton>
                <p class="text-xs text-gray-500 mt-2">
                  Showing {{ Math.min(currentPage * itemsPerPage, allSupportTickets.length) }} of {{ allSupportTickets.length }} tickets
                </p>
              </div>
            </div>

            <!-- Empty state for support tickets -->
            <div v-else-if="!isLoading" class="p-8 text-center">
              <div class="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
                <UIcon name="i-heroicons-chat-bubble-left-right" class="w-8 h-8 text-gray-400" />
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No Support Tickets</h3>
              <p class="text-gray-600 mb-4">
                You haven't created any support tickets yet.
              </p>
              <UButton color="primary" @click="openNewTicketModal">
                Open Your First Ticket
              </UButton>
            </div>
          </div><!-- Updates Content -->
          <div v-if="activeTab === 'updates'">
            <div v-if="updates && updates.length">
              <TransitionGroup name="message-list" tag="div">
                <div
                  v-for="(update, index) in filteredUpdates"
                  :key="update.id"
                  class="unified-message-item border-b border-gray-100 hover:bg-gray-50 transition-colors duration-200"
                  :class="{ 
                    'unread': !update.is_read,
                    'border-b-0': index === filteredUpdates.length - 1
                  }"
                >
                  <div
                    class="flex items-center gap-4 p-4 cursor-pointer"
                    @click="markUpdateAsRead(update)"
                  >
                    <!-- Left Status Stripe -->
                    <div 
                      class="w-1 h-12 rounded-full"
                      :class="{
                        'bg-primary-500': !update.is_read,
                        'bg-gray-300': update.is_read
                      }"
                    ></div>

                    <!-- Icon -->
                    <div class="flex-shrink-0">
                      <div
                        class="w-10 h-10 rounded-full flex items-center justify-center border-2"
                        :class="getUpdateIconClass(update.notification_type)"
                      >
                        <UIcon
                          :name="getUpdateIcon(update.notification_type)"
                          class="w-5 h-5"
                        />
                      </div>
                    </div>

                    <!-- Content -->
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center justify-between mb-1">
                        <div class="flex items-center gap-2">
                          <UBadge
                            :color="update.is_read ? 'gray' : 'primary'"
                            size="xs"
                          >
                            {{ update.is_read ? 'Read' : 'New' }}
                          </UBadge>
                          <UBadge
                            :color="getUpdateTypeColor(update.notification_type)"
                            size="xs"
                          >
                            {{ formatUpdateType(update.notification_type) }}
                          </UBadge>
                          <span
                            v-if="update.amount"
                            class="text-xs font-medium text-green-600"
                          >
                            ৳{{ update.amount }}
                          </span>
                        </div>
                        <span class="text-xs text-gray-500">
                          {{ formatDate(update.created_at) }}
                        </span>
                      </div>
                      <h3 
                        class="text-sm font-medium text-gray-900 line-clamp-1 mb-1"
                        :class="{ 'font-semibold': !update.is_read }"
                      >
                        {{ update.title }}
                      </h3>
                      <p class="text-xs text-gray-600 line-clamp-1">
                        {{ update.message }}
                      </p>
                    </div>
                  </div>
                </div>
              </TransitionGroup>
              
              <!-- Load More Button -->
              <div v-if="hasMoreItems" class="p-4 text-center border-t border-gray-100">
                <UButton
                  color="primary"
                  variant="outline"
                  :loading="isLoadingMore"
                  @click="loadMoreItems"
                  size="sm"
                  icon="i-heroicons-arrow-down-circle"
                >
                  <template v-if="isLoadingMore">
                    Loading more...
                  </template>
                  <template v-else>
                    Load More Notifications
                  </template>
                </UButton>
                <p class="text-xs text-gray-500 mt-2">
                  Showing {{ Math.min(currentPage * itemsPerPage, allUpdates.length) }} of {{ allUpdates.length }} notifications
                </p>
              </div>
            </div>

            <!-- Empty state for updates -->
            <div v-else-if="!isLoading" class="p-8 text-center">
              <div class="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
                <UIcon name="i-heroicons-bell" class="w-8 h-8 text-gray-400" />
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No Updates</h3>
              <p class="text-gray-600">
                You'll see notifications about orders, withdrawals, recharges, and more here.
              </p>
            </div>
          </div>
        </div>
      </div>

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
      <!-- New Support Ticket Modal -->
      <Teleport to="body">
        <div
          v-if="isNewTicketModalOpen"
          class="fixed inset-0 -top-14 sm:top-14 z-50 overflow-y-auto"
          :class="{ 'animate-fade-in': isNewTicketModalOpen }"
          @click="() => (isNewTicketModalOpen = false)"
        >
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
            aria-hidden="true"
            @click="isNewTicketModalOpen = false"
          ></div>
          <div
            class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
          >
            <div
              class="relative max-w-xl w-full mx-auto my-8 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-xl shadow-sm border border-white/20 dark:border-slate-700/40 overflow-hidden"
              :class="{ 'animate-modal-slide-up': isNewTicketModalOpen }"
              @click.stop
            >
              <div
                class="w-full overflow-hidden overflow-y-auto custom-scrollbar"
              >
                <UCard class="shadow-2xl border-0">
                  <template #header>
                    <div
                      class="flex justify-between items-center bg-gradient-to-r from-primary-50 to-white p-1 rounded-t-lg"
                    >
                      <div class="flex items-center gap-3">
                        <div class="bg-primary-100 p-2 rounded-full">
                          <UIcon
                            name="i-heroicons-ticket"
                            class="text-primary-600 text-xl"
                          />
                        </div>
                        <h3 class="text-lg font-medium text-gray-800">
                          Open New Ticket
                        </h3>
                      </div>
                      <UButton
                        color="gray"
                        variant="ghost"
                        icon="i-heroicons-x-mark"
                        class="rounded-full h-8 w-8 hover:bg-red-50 hover:text-red-500 transition-colors"
                        @click="isNewTicketModalOpen = false"
                      />
                    </div>
                  </template>

                  <div class="space-y-5 p-1">
                    <div
                      class="bg-blue-50 rounded-lg p-3 mb-4 border-l-4 border-blue-400"
                    >
                      <div class="flex gap-2">
                        <UIcon
                          name="i-heroicons-information-circle"
                          class="text-blue-500 flex-shrink-0 mt-1"
                        />
                        <p class="text-sm text-blue-700 text-left">
                          Please provide details about your issue. Our support
                          team will respond as soon as possible.
                        </p>
                      </div>
                    </div>

                    <UFormGroup label="Subject" required class="form-group">
                      <UInput
                        v-model="newTicket.title"
                        placeholder="Brief description of your issue"
                        icon="i-heroicons-document-text"
                        class="focus-ring"
                      />
                    </UFormGroup>

                    <UFormGroup label="Message" required class="form-group">
                      <UTextarea
                        v-model="newTicket.message"
                        placeholder="Please describe your issue in detail"
                        rows="6"
                        class="focus-ring"
                      />
                    </UFormGroup>
                  </div>

                  <template #footer>
                    <div
                      class="flex justify-end gap-3 pt-2 border-t border-gray-100"
                    >
                      <UButton
                        color="gray"
                        variant="soft"
                        icon="i-heroicons-x-mark"
                        @click="isNewTicketModalOpen = false"
                        class="transition-transform hover:-translate-y-0.5"
                      >
                        Cancel
                      </UButton>
                      <UButton
                        color="primary"
                        :loading="isSubmittingTicket"
                        icon="i-heroicons-paper-airplane"
                        @click="submitNewTicket"
                        class="transition-transform hover:-translate-y-0.5"
                      >
                        Submit Ticket
                      </UButton>
                    </div>
                  </template>
                </UCard>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
      <!-- Reply to Ticket Modal -->
      <Teleport to="body">
        <div
          v-if="isReplyModalOpen"
          class="fixed inset-0 top-14 z-50 overflow-y-auto"
          :class="{ 'animate-fade-in': isReplyModalOpen }"
          @click="() => (isReplyModalOpen = false)"
        >
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
            aria-hidden="true"
            @click="isReplyModalOpen = false"
          ></div>
          <div
            class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
          >
            <div
              class="relative max-w-xl w-full mx-auto my-8 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-xl shadow-sm border border-white/20 dark:border-slate-700/40 overflow-hidden"
              :class="{ 'animate-modal-slide-up': isReplyModalOpen }"
              @click.stop
            >
              <div
                class="w-full overflow-hidden overflow-y-auto custom-scrollbar"
              >
                <UCard class="shadow-2xl border-0">
                  <template #header>
                    <div
                      class="flex justify-between items-center bg-gradient-to-r from-blue-50 to-white p-1 rounded-t-lg"
                    >
                      <div class="flex items-center gap-3">
                        <div class="bg-blue-100 p-2 rounded-full">
                          <UIcon
                            name="i-heroicons-chat-bubble-left-right"
                            class="text-blue-600 text-xl"
                          />
                        </div>
                        <h3 class="text-lg font-medium text-gray-800">
                          Reply to Ticket
                        </h3>
                      </div>
                      <UButton
                        color="gray"
                        variant="ghost"
                        icon="i-heroicons-x-mark"
                        class="rounded-full h-8 w-8 hover:bg-red-50 hover:text-red-500 transition-colors"
                        @click="isReplyModalOpen = false"
                      />
                    </div>
                  </template>

                  <div class="space-y-5 p-1">
                    <div
                      v-if="activeTicket"
                      class="bg-gray-50 p-4 rounded-lg border border-gray-200 shadow-sm"
                    >
                      <div class="flex items-center gap-2 mb-2">
                        <UIcon
                          name="i-heroicons-ticket"
                          class="text-gray-600"
                        />
                        <h4 class="text-sm font-semibold text-gray-800">
                          {{ activeTicket.title }}
                        </h4>
                      </div>
                      <div class="flex items-center gap-2">
                        <span
                          class="px-2 py-1 bg-gray-100 rounded-md text-xs font-mono text-gray-600"
                        >
                          #{{ activeTicket.id.toString().padStart(10, "0") }}
                        </span>
                        <UBadge
                          :color="getTicketStatusColor(activeTicket.status)"
                          size="xs"
                          class="capitalize"
                        >
                          {{ formatTicketStatus(activeTicket.status) }}
                        </UBadge>
                      </div>
                    </div>

                    <UFormGroup label="Your Reply" required class="form-group">
                      <UTextarea
                        v-model="ticketReply"
                        placeholder="Type your response..."
                        autofocus
                        rows="5"
                        class="focus-ring"
                      />
                    </UFormGroup>

                    <div class="text-xs text-gray-600 italic">
                      <UIcon name="i-heroicons-clock" class="inline mr-1" />
                      Typical response time: 24-48 hours
                    </div>
                  </div>

                  <template #footer>
                    <div
                      class="flex justify-end gap-3 pt-2 border-t border-gray-100"
                    >
                      <UButton
                        color="gray"
                        variant="soft"
                        icon="i-heroicons-arrow-left"
                        @click="isReplyModalOpen = false"
                        class="transition-transform hover:-translate-y-0.5"
                      >
                        Cancel
                      </UButton>
                      <UButton
                        color="primary"
                        :loading="isSubmittingReply"
                        icon="i-heroicons-paper-airplane"
                        @click="submitReply"
                        class="transition-transform hover:-translate-y-0.5"
                      >
                        Send Reply
                      </UButton>
                    </div>
                  </template>
                </UCard>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
      <!-- Ticket Detail Modal -->
      <Teleport to="body">
        <div
          v-if="isTicketDetailModalOpen"
          class="fixed inset-0 top-14 z-50 overflow-y-auto"
          :class="{ 'animate-fade-in': isTicketDetailModalOpen }"
          @click="() => (isTicketDetailModalOpen = false)"
        >
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
            aria-hidden="true"
            @click="isTicketDetailModalOpen = false"
          ></div>
          <div
            class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
          >
            <div
              class="relative max-w-xl w-full mx-auto my-8 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-xl shadow-sm border border-white/20 dark:border-slate-700/40 overflow-hidden"
              :class="{ 'animate-modal-slide-up': isTicketDetailModalOpen }"
              @click.stop
            >
              <div
                class="w-full overflow-hidden overflow-y-auto custom-scrollbar"
              >
                <UCard
                  v-if="activeTicket"
                  class="shadow-2xl border-0 flex flex-col"
                >
                  <template #header>
                    <div
                      class="bg-gradient-to-r"
                      :class="{
                        'from-amber-50 to-white':
                          activeTicket.status === 'open',
                        'from-blue-50 to-white':
                          activeTicket.status === 'in_progress',
                        'from-green-50 to-white':
                          activeTicket.status === 'resolved',
                        'from-gray-50 to-white':
                          activeTicket.status === 'closed',
                      }"
                    >
                      <div class="flex justify-between items-center p-2">
                        <div class="flex items-center gap-3">
                          <div
                            class="p-2 rounded-full"
                            :class="{
                              'bg-amber-100': activeTicket.status === 'open',
                              'bg-blue-100':
                                activeTicket.status === 'in_progress',
                              'bg-green-100':
                                activeTicket.status === 'resolved',
                              'bg-gray-100': activeTicket.status === 'closed',
                            }"
                          >
                            <UIcon
                              name="i-heroicons-ticket"
                              class="text-xl"
                              :class="{
                                'text-amber-600':
                                  activeTicket.status === 'open',
                                'text-blue-600':
                                  activeTicket.status === 'in_progress',
                                'text-green-600':
                                  activeTicket.status === 'resolved',
                                'text-gray-600':
                                  activeTicket.status === 'closed',
                              }"
                            />
                          </div>
                          <div>
                            <div class="flex items-center gap-2 mb-1">
                              <h3 class="text-lg font-medium text-gray-800">
                                Ticket #{{
                                  activeTicket.id.toString().padStart(10, "0")
                                }}
                              </h3>
                              <UBadge
                                :color="
                                  getTicketStatusColor(activeTicket.status)
                                "
                                size="sm"
                                class="uppercase tracking-wider font-semibold text-xs"
                              >
                                {{ formatTicketStatus(activeTicket.status) }}
                              </UBadge>
                            </div>
                            <div
                              class="flex items-center gap-2 text-sm text-gray-600"
                            >
                              <UIcon
                                name="i-heroicons-calendar"
                                class="text-xs"
                              />
                              <span>{{
                                formatDate(activeTicket.created_at)
                              }}</span>
                            </div>
                          </div>
                        </div>
                        <UButton
                          color="gray"
                          variant="ghost"
                          icon="i-heroicons-x-mark"
                          class="rounded-full h-8 w-8 hover:bg-red-50 hover:text-red-500 transition-colors"
                          @click="isTicketDetailModalOpen = false"
                        />
                      </div>
                    </div>
                  </template>
                  <div class="flex-1 overflow-hidden flex flex-col text-left">
                    <!-- Fixed content at top -->
                    <div
                      class="flex-shrink-0 px-6 py-4 border-b border-gray-200"
                    >
                      <!-- Ticket subject and message -->
                      <h4 class="font-semibold text-lg mb-3 flex items-center">
                        <UIcon
                          name="i-heroicons-document-text"
                          class="mr-2 text-gray-600"
                        />
                        {{ activeTicket.title }}
                      </h4>                      <div
                        class="p-4 bg-gray-50 rounded-lg border border-gray-200 text-gray-800 whitespace-pre-wrap shadow-sm"
                        v-html="activeTicket.message"
                      >
                      </div>
                    </div>

                    <!-- Scrollable replies area -->
                    <div class="flex-1 overflow-y-auto custom-scrollbar">
                      <div class="px-6 py-4">
                        <!-- Ticket replies section -->
                        <div
                          v-if="(activeTicket.replies || []).length > 0"
                          class="mb-6"
                        >
                          <div class="flex items-center justify-between mb-4">
                            <h4
                              class="flex items-center text-md font-medium text-gray-800"
                            >
                              <UIcon
                                name="i-heroicons-chat-bubble-bottom-center-text"
                                class="mr-2"
                              />
                              Conversation History ({{
                                activeTicket.replies.length
                              }}
                              {{
                                activeTicket.replies.length === 1
                                  ? "reply"
                                  : "replies"
                              }})
                            </h4>

                            <!-- Load more button -->
                            <UButton
                              v-if="hasMoreReplies"
                              size="sm"
                              color="gray"
                              variant="ghost"
                              :loading="isLoadingMoreReplies"
                              @click="loadMoreReplies"
                              class="text-xs"
                            >
                              <template v-if="isLoadingMoreReplies">
                                Loading...
                              </template>
                              <template v-else>
                                Load
                                {{
                                  Math.min(
                                    10,
                                    activeTicket.replies.length -
                                      displayedRepliesCount
                                  )
                                }}
                                more
                              </template>
                            </UButton>
                          </div>

                          <div class="space-y-4">
                            <div
                              v-for="(reply, index) in displayedReplies"
                              :key="reply.id"
                              class="p-4 rounded-lg shadow-sm transition-all duration-200 hover:shadow-md"
                              :class="{
                                'bg-primary-50 border-l-4 border-primary-300':
                                  reply.is_from_admin,
                                'bg-gray-50 border-l-4 border-gray-300':
                                  !reply.is_from_admin,
                              }"
                            >
                              <div class="flex items-start gap-3">
                                <div
                                  :class="[
                                    'reply-avatar flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center shadow-sm',
                                    reply.is_from_admin
                                      ? 'bg-primary-100'
                                      : 'bg-gray-100',
                                  ]"
                                >
                                  <UIcon
                                    :name="
                                      reply.is_from_admin
                                        ? 'i-heroicons-user-circle'
                                        : 'i-heroicons-user'
                                    "
                                    class="text-xl"
                                    :class="
                                      reply.is_from_admin
                                        ? 'text-primary-600'
                                        : 'text-gray-600'
                                    "
                                  />
                                </div>
                                <div class="reply-content flex-1">
                                  <div
                                    class="flex justify-between items-center mb-2"
                                  >
                                    <span
                                      class="text-sm font-semibold"
                                      :class="
                                        reply.is_from_admin
                                          ? 'text-primary-700'
                                          : 'text-gray-800'
                                      "
                                    >
                                      {{
                                        reply.is_from_admin
                                          ? "Support Team"
                                          : "You"
                                      }}
                                    </span>
                                    <div class="flex items-center gap-2">
                                      <UBadge
                                        v-if="index === 0"
                                        color="gray"
                                        size="xs"
                                        class="font-mono mr-1"
                                        >Latest</UBadge
                                      >
                                      <span
                                        class="text-xs text-gray-600 flex items-center"
                                      >
                                        <UIcon
                                          name="i-heroicons-clock"
                                          class="mr-1"
                                        />
                                        {{ formatDate(reply.created_at) }}
                                      </span>
                                    </div>
                                  </div>                                  <div
                                    class="text-sm text-gray-800 whitespace-pre-wrap"
                                    v-html="reply.message"
                                  >
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Fixed reply form and actions at bottom -->
                    <div
                      class="flex-shrink-0 border-t border-gray-200 bg-gray-50"
                    >
                      <!-- Reply form -->
                      <div
                        v-if="activeTicket.status !== 'closed'"
                        class="px-6 py-4"
                      >
                        <h4
                          class="flex items-center text-md font-medium text-gray-800 mb-3"
                        >
                          <UIcon
                            name="i-heroicons-pencil-square"
                            class="mr-2"
                          />
                          Add Reply
                        </h4>
                        <UTextarea
                          v-model="ticketReply"
                          placeholder="Type your response..."
                          rows="3"
                          class="mb-3 focus-ring"
                        />
                        <div class="flex justify-between items-center">
                          <p class="text-xs text-gray-600 flex items-center">
                            <UIcon
                              name="i-heroicons-information-circle"
                              class="mr-1"
                            />
                            Your reply will be sent to our support team
                          </p>
                          <UButton
                            color="primary"
                            :loading="isSubmittingReply"
                            icon="i-heroicons-paper-airplane"
                            @click="submitReplyFromDetail"
                            class="transition-transform hover:-translate-y-0.5"
                          >
                            Send Reply
                          </UButton>
                        </div>
                      </div>

                      <!-- Admin only: status update options -->
                      <div
                        v-if="
                          user?.user?.is_staff &&
                          activeTicket.status !== 'closed'
                        "
                        class="border-t border-gray-200 px-6 py-4"
                      >
                        <h4
                          class="flex items-center text-sm font-medium text-gray-800 mb-3"
                        >
                          <UIcon
                            name="i-heroicons-adjustments-horizontal"
                            class="mr-1"
                          />
                          Update Ticket Status:
                        </h4>
                        <div class="flex flex-wrap gap-2">
                          <UButton
                            v-for="status in [
                              'open',
                              'in_progress',
                              'resolved',
                              'closed',
                            ]"
                            :key="status"
                            size="sm"
                            :color="getTicketStatusColor(status)"
                            :disabled="activeTicket.status === status"
                            :icon="getStatusIcon(status)"
                            :label="formatTicketStatus(status)"
                            class="transition-all duration-200 hover:-translate-y-0.5"
                            @click="
                              updateTicketStatusFromDetail(
                                activeTicket.id,
                                status
                              )
                            "
                          />
                        </div>
                      </div>

                      <!-- User only: close resolved ticket -->
                      <div
                        v-if="
                          !user?.user?.is_staff &&
                          activeTicket.status === 'resolved'
                        "
                        class="border-t border-gray-200 px-6 py-4"
                      >
                        <div class="flex items-center justify-between">
                          <p class="text-sm text-gray-600">
                            <UIcon
                              name="i-heroicons-information-circle"
                              class="inline mr-1"
                            />
                            Is your issue resolved? You can close this ticket
                            now.
                          </p>
                          <UButton
                            color="gray"
                            label="Close Ticket"
                            icon="i-heroicons-check-circle"
                            class="transition-transform hover:-translate-y-0.5"
                            @click="
                              updateTicketStatusFromDetail(
                                activeTicket.id,
                                'closed'
                              )
                            "
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </UCard>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { t } = useI18n();
const { user } = useAuth();
const { get, post, put } = useApi();
const { formatDate } = useUtils();
const { 
  markTicketAsRead: markTicketAsReadGlobal, 
  markUpdateAsRead: markUpdateAsReadGlobal, 
  fetchUnreadCount 
} = useTickets();
const toast = useToast();

// State variables
const messages = ref([]);
const expandedMessages = ref({});
const readMessages = ref({});
const isLoading = ref(true);
const ticketStatusFilter = ref("all");
const newMessageCount = ref(0);
const newTicketCount = ref(0);
const isTicketDetailModalOpen = ref(false);

// Tab state
const activeTab = ref('updates');
const updatesFilter = ref('all');

// Pagination state
const currentPage = ref(1);
const itemsPerPage = 10;
const isLoadingMore = ref(false);
const hasMoreItems = ref(true);

// Separate data for updates and support tickets
const updates = ref([]);
const supportTickets = ref([]);
const allUpdates = ref([]); // Store all updates for pagination
const allSupportTickets = ref([]); // Store all support tickets for pagination
const filteredMessages = computed(() => {
  let filtered = messages.value.filter((msg) => msg.is_ticket);

  // Apply ticket status filter
  if (ticketStatusFilter.value !== "all") {
    filtered = filtered.filter(
      (ticket) => ticket.status === ticketStatusFilter.value
    );
  }

  return filtered;
});

// Computed properties for tabbed interface
const updatesCount = computed(() => {
  return allUpdates.value.filter(update => !update.is_read).length;
});

const supportTicketsCount = computed(() => {
  return allSupportTickets.value.filter(ticket => !readMessages.value[ticket.id]).length;
});

const filteredUpdates = computed(() => {
  let filtered = allUpdates.value;
  
  if (updatesFilter.value !== 'all') {
    filtered = filtered.filter(update => update.notification_type === updatesFilter.value);
  }
  
  // Apply pagination - show only items for current page
  const startIndex = 0;
  const endIndex = currentPage.value * itemsPerPage;
  const paginatedFiltered = filtered.slice(startIndex, endIndex);
  
  // Update hasMoreItems based on whether there are more items to load
  hasMoreItems.value = filtered.length > endIndex;
  
  return paginatedFiltered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
});

const filteredSupportTickets = computed(() => {
  let filtered = allSupportTickets.value;
  
  if (ticketStatusFilter.value !== 'all') {
    filtered = filtered.filter(ticket => ticket.status === ticketStatusFilter.value);
  }
  
  // Apply pagination - show only items for current page
  const startIndex = 0;
  const endIndex = currentPage.value * itemsPerPage;
  const paginatedFiltered = filtered.slice(startIndex, endIndex);
  
  // Update hasMoreItems based on whether there are more items to load
  hasMoreItems.value = filtered.length > endIndex;
  
  return paginatedFiltered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
});

// Computed property to check if there are unread messages in the current tab
const hasUnreadMessages = computed(() => {
  if (activeTab.value === 'updates') {
    return allUpdates.value.some(update => !update.is_read);
  } else if (activeTab.value === 'support') {
    return allSupportTickets.value.some(ticket => !readMessages.value[ticket.id]);
  }
  return false;
});

// Ticket handling
const isNewTicketModalOpen = ref(false);
const isReplyModalOpen = ref(false);
const activeTicket = ref(null);
const newTicket = ref({ title: "", message: "" });
const ticketReply = ref("");
const isSubmittingTicket = ref(false);
const isSubmittingReply = ref(false);

// Reply pagination
const displayedRepliesCount = ref(10);
const isLoadingMoreReplies = ref(false);

// Computed property for paginated replies
const displayedReplies = computed(() => {
  if (!activeTicket.value?.replies) return [];
  const replies = [...activeTicket.value.replies].reverse(); // Show newest first
  return replies.slice(0, displayedRepliesCount.value);
});

const hasMoreReplies = computed(() => {
  if (!activeTicket.value?.replies) return false;
  return activeTicket.value.replies.length > displayedRepliesCount.value;
});

async function loadMoreReplies() {
  isLoadingMoreReplies.value = true;
  // Simulate API delay (in real scenario, you might fetch from server)
  setTimeout(() => {
    displayedRepliesCount.value += 10;
    isLoadingMoreReplies.value = false;
  }, 500);
}

async function toggleMessage(id) {
  // We no longer expand messages, we just mark them as read
  await markAsRead(id);
}

function readMessageLabel(id) {
  // Return appropriate label based on read status
  const isRead = readMessages.value[id] === true;
  return isRead ? "Read" : "Unread";
}

async function markAsRead(id) {
  // Check current status to see if there's a change
  const currentStatus = readMessages.value[id];

  // Update local state for immediate UI feedback
  readMessages.value = {
    ...readMessages.value,
    [id]: true,
  };

  // Find the message to update both locally and on server
  const messageToMark = messages.value.find((msg) => msg.id === id);
  if (messageToMark && messageToMark.is_ticket && !currentStatus) {
    try {
      // Update the local message to show as read immediately
      messageToMark.is_unread = false;
        // Use the composable function which will also update the global count
      const success = await markTicketAsReadGlobal(id);
      
      if (success) {
        // Update the local counts
        newMessageCount.value = messages.value.filter(
          (msg) => !readMessages.value[msg.id]
        ).length;
        newTicketCount.value = messages.value.filter(
          (msg) => msg.is_ticket && !readMessages.value[msg.id]
        ).length;
      }
    } catch (error) {
      console.error("Error marking ticket as read:", error);
      // Revert local changes if server update failed
      delete readMessages.value[id];
      if (messageToMark) {
        messageToMark.is_unread = true;
      }
    }
  }
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

function setFilter(filter) {
  currentFilter.value = filter;

  // Reset ticket status filter when changing main filter
  if (filter !== "support") {
    ticketStatusFilter.value = "all";
  }
}

function setTicketStatusFilter(status) {
  ticketStatusFilter.value = status;
  // Reset pagination when filter changes
  currentPage.value = 1;
}

// Tab switching functions
function setActiveTab(tab) {
  activeTab.value = tab;
  // Reset pagination when switching tabs
  currentPage.value = 1;
}

// Updates filter functions
function setUpdatesFilter(filter) {
  updatesFilter.value = filter;
  // Reset pagination when filter changes
  currentPage.value = 1;
}

// Load more function
async function loadMoreItems() {
  if (isLoadingMore.value || !hasMoreItems.value) return;
  
  isLoadingMore.value = true;
  
  try {
    // Simulate loading delay for better UX
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Increase the page count to show more items
    currentPage.value += 1;
  } catch (error) {
    console.error('Error loading more items:', error);
    toast.add({
      title: "Error",
      description: "Failed to load more items. Please try again.",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoadingMore.value = false;
  }
}

// Mark all messages as read
async function markAllAsRead() {
  try {
    let markedCount = 0;
    
    if (activeTab.value === 'updates') {
      // Mark all unread updates as read
      const unreadUpdates = allUpdates.value.filter(update => !update.is_read);
      
      for (const update of unreadUpdates) {
        try {
          const success = await markUpdateAsReadGlobal(update.id);
          if (success) {
            update.is_read = true;
            markedCount++;
          }
        } catch (error) {
          console.error(`Error marking update ${update.id} as read:`, error);
        }
      }
    } else if (activeTab.value === 'support') {
      // Mark all unread support tickets as read
      const unreadTickets = allSupportTickets.value.filter(ticket => !readMessages.value[ticket.id]);
      
      for (const ticket of unreadTickets) {
        try {
          const success = await markTicketAsReadGlobal(ticket.id);
          if (success) {
            readMessages.value[ticket.id] = true;
            markedCount++;
          }
        } catch (error) {
          console.error(`Error marking ticket ${ticket.id} as read:`, error);
        }
      }
    }
    
    // Update global counts
    await fetchUnreadCount();
    
    // Update local counts
    newMessageCount.value = messages.value.filter(
      (msg) => !readMessages.value[msg.id] && (msg.is_ticket ? !msg.is_read : !msg.is_read)
    ).length;
    newTicketCount.value = allSupportTickets.value.filter(
      (ticket) => !readMessages.value[ticket.id]
    ).length;
    
    if (markedCount > 0) {
      toast.add({
        title: "Success",
        description: `Marked ${markedCount} ${activeTab.value === 'support' ? 'ticket' : 'update'}${markedCount > 1 ? 's' : ''} as read`,
        color: "green",
        timeout: 3000,
      });
    } else {
      toast.add({
        title: "Info",
        description: `No unread ${activeTab.value === 'support' ? 'tickets' : 'updates'} to mark`,
        color: "blue",
        timeout: 2000,
      });
    }
  } catch (error) {
    console.error('Error marking all as read:', error);
    toast.add({
      title: "Error",
      description: "Failed to mark all as read. Please try again.",
      color: "red",
      timeout: 3000,
    });
  }
}

// Helper functions for updates
function getUpdateIcon(notificationType) {
  const iconMap = {
    system: 'i-heroicons-cog-6-tooth',
    order_received: 'i-heroicons-shopping-bag',
    withdraw_successful: 'i-heroicons-banknotes',
    mobile_recharge_successful: 'i-heroicons-device-phone-mobile',
    pro_subscribed: 'i-heroicons-star',
    pro_expiring: 'i-heroicons-exclamation-triangle',
    gig_posted: 'i-heroicons-briefcase',
    transfer_sent: 'i-heroicons-arrow-up-right',
    transfer_received: 'i-heroicons-arrow-down-left',
    deposit_successful: 'i-heroicons-credit-card',
    gig_approved: 'i-heroicons-check-circle',
    gig_rejected: 'i-heroicons-x-circle',
    general: 'i-heroicons-bell'
  };
  return iconMap[notificationType] || 'i-heroicons-bell';
}

function getUpdateIconClass(notificationType) {
  const classMap = {
    system: 'system-update',
    order_received: 'order-update',
    withdraw_successful: 'withdraw-update',
    mobile_recharge_successful: 'recharge-update',
    pro_subscribed: 'pro-update',
    pro_expiring: 'expiring-update',
    gig_posted: 'gig-update',
    transfer_sent: 'transfer-sent-update',
    transfer_received: 'transfer-received-update',
    deposit_successful: 'deposit-update',
    gig_approved: 'gig-approved-update',
    gig_rejected: 'gig-rejected-update',
    general: 'general-update'
  };
  return classMap[notificationType] || 'general-update';
}

function getUpdateTypeColor(notificationType) {
  const colorMap = {
    system: 'gray',
    order_received: 'green',
    withdraw_successful: 'blue',
    mobile_recharge_successful: 'orange',
    pro_subscribed: 'purple',
    pro_expiring: 'amber',
    gig_posted: 'gray',
    transfer_sent: 'cyan',
    transfer_received: 'emerald',
    deposit_successful: 'teal',
    gig_approved: 'green',
    gig_rejected: 'red',
    general: 'blue'
  };
  return colorMap[notificationType] || 'blue';
}

function formatUpdateType(notificationType) {
  const formatMap = {
    system: 'System',
    order_received: 'Order',
    withdraw_successful: 'Withdrawal',
    mobile_recharge_successful: 'Recharge',
    pro_subscribed: 'Pro',
    pro_expiring: 'Pro Ending',
    gig_posted: 'Gig Posted',
    transfer_sent: 'Transfer Sent',
    transfer_received: 'Transfer Received',
    deposit_successful: 'Deposit',
    gig_approved: 'Gig Approved',
    gig_rejected: 'Gig Rejected',
    general: 'General'
  };
  return formatMap[notificationType] || 'Notification';
}

async function markUpdateAsRead(update) {
  if (update.is_read) return;
  
  try {
    // Use the composable function which will also update the global count
    const success = await markUpdateAsReadGlobal(update.id);
    
    if (success) {
      update.is_read = true;
      
      // Update local counts
      newMessageCount.value = Math.max(0, newMessageCount.value - 1);
      
      toast.add({
        title: "Marked as Read",
        description: "Update has been marked as read",
        color: "green",
        timeout: 2000,
      });
    }
  } catch (error) {
    console.error("Error marking update as read:", error);
    toast.add({
      title: "Error",
      description: "Failed to mark update as read",
      color: "red",
      timeout: 3000,
    });
  }
}

function getTicketStatusColor(status) {
  switch (status) {
    case "open":
      return "amber";
    case "in_progress":
      return "blue";
    case "resolved":
      return "green";
    case "closed":
      return "gray";
    default:
      return "gray";
  }
}

function formatTicketStatus(status) {
  if (!status) return "";

  // Convert 'in_progress' to 'In Progress'
  return status
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

function getStatusIcon(status) {
  switch (status) {
    case "open":
      return "i-heroicons-ticket";
    case "in_progress":
      return "i-heroicons-clock";
    case "resolved":
      return "i-heroicons-check-badge";
    case "closed":
      return "i-heroicons-archive-box";
    default:
      return "i-heroicons-ticket";
  }
}

// Support ticket functions
function openNewTicketModal() {
  newTicket.value = { title: "", message: "" };
  isNewTicketModalOpen.value = true;
}

async function openTicketDetail(ticket) {
  // Mark the ticket as read first
  await markAsRead(ticket.id);

  // Update the ticket's unread status locally for immediate feedback
  ticket.is_unread = false;

  // Set as active ticket and open detail modal
  activeTicket.value = { ...ticket };
  ticketReply.value = "";

  // Reset pagination for replies
  displayedRepliesCount.value = 10;

  isTicketDetailModalOpen.value = true;
}

function openReplyModal(ticket) {
  activeTicket.value = ticket;
  ticketReply.value = "";
  isReplyModalOpen.value = true;
}

async function submitNewTicket() {
  if (!newTicket.value.title || !newTicket.value.message) {
    // Show validation error
    toast.add({
      title: "Validation Error",
      description: "Please fill in both the subject and message fields.",
      color: "red",
      timeout: 3000,
    });
    return;
  }

  // Check for minimum content length
  if (newTicket.value.title.trim().length < 3) {
    toast.add({
      title: "Validation Error",
      description: "Subject must be at least 3 characters long.",
      color: "red",
      timeout: 3000,
    });
    return;
  }

  if (newTicket.value.message.trim().length < 10) {
    toast.add({
      title: "Validation Error",
      description: "Message must be at least 10 characters long.",
      color: "red",
      timeout: 3000,
    });
    return;
  }

  isSubmittingTicket.value = true;

  try {
    const response = await post("/tickets/", {
      title: newTicket.value.title,
      message: newTicket.value.message,
    });

    // Add the new ticket to the messages list
    const newTicketData = {
      ...response.data,
      is_ticket: true,
      replies: [],
    };

    messages.value = [newTicketData, ...messages.value];
    // Reset the form and close the modal
    newTicket.value = { title: "", message: "" };
    isNewTicketModalOpen.value = false;

    // Auto-expand the new ticket
    expandedMessages.value[newTicketData.id] = true;
    await refreshMessages();

    // Show success notification
    toast.add({
      title: "Ticket Created",
      description: "Your support ticket has been created successfully.",
      color: "green",
      timeout: 3000,
    });
  } catch (error) {
    console.error("Error creating support ticket:", error);

    // Show error notification to user
    toast.add({
      title: "Error Creating Ticket",
      description:
        error.response?.data?.message ||
        "Failed to create support ticket. Please try again.",
      color: "red",
      timeout: 5000,
    });
  } finally {
    isSubmittingTicket.value = false;
    await refreshMessages();
  }
}

async function submitReply() {
  if (!ticketReply.value || !activeTicket.value) {
    return;
  }

  isSubmittingReply.value = true;

  try {
    const response = await post(`/tickets/${activeTicket.value.id}/replies/`, {
      message: ticketReply.value,
    });

    // Update the ticket with the new reply
    const updatedTicket = messages.value.find(
      (msg) => msg.id === activeTicket.value.id
    );
    if (updatedTicket) {
      if (!updatedTicket.replies) {
        updatedTicket.replies = [];
      }
      updatedTicket.replies.push(response.data);
    }

    // Reset and close
    ticketReply.value = "";
    isReplyModalOpen.value = false;
  } catch (error) {
    console.error("Error submitting reply:", error);
  } finally {
    isSubmittingReply.value = false;
  }
}

async function submitReplyFromDetail() {
  if (!ticketReply.value || !activeTicket.value) {
    return;
  }

  isSubmittingReply.value = true;

  try {
    const response = await post(`/tickets/${activeTicket.value.id}/replies/`, {
      message: ticketReply.value,
    });

    // Update the ticket with the new reply
    const updatedTicket = messages.value.find(
      (msg) => msg.id === activeTicket.value.id
    );
    if (updatedTicket) {
      if (!updatedTicket.replies) {
        updatedTicket.replies = [];
      }
      updatedTicket.replies.push(response.data);

      // Update the activeTicket to reflect changes
      activeTicket.value = { ...updatedTicket };
    }

    // Reset reply field
    ticketReply.value = "";

    // Show success notification
    toast.add({
      title: "Reply Sent",
      description: "Your reply has been sent successfully",
      color: "green",
    });
  } catch (error) {
    console.error("Error submitting reply:", error);
    toast.add({
      title: "Error",
      description: "Failed to send your reply. Please try again.",
      color: "red",
    });
  } finally {
    isSubmittingReply.value = false;
  }
}

async function updateTicketStatus(ticketId, newStatus) {
  try {
    const response = await post(`/tickets/${ticketId}/status/`, {
      status: newStatus,
    });

    // Update the ticket status in the UI
    const updatedTicket = messages.value.find((msg) => msg.id === ticketId);
    if (updatedTicket) {
      updatedTicket.status = newStatus;

      // Add a system message indicating status change
      if (!updatedTicket.statusChanges) {
        updatedTicket.statusChanges = [];
      }

      // Add notification to the user about the status update
      toast.add({
        title: "Ticket Status Updated",
        description: `Ticket has been marked as "${formatTicketStatus(
          newStatus
        )}"`,
        color: getTicketStatusColor(newStatus),
      });
    }
  } catch (error) {
    console.error("Error updating ticket status:", error);

    // Show error notification
    toast.add({
      title: "Update Failed",
      description: "Failed to update ticket status. Please try again.",
      color: "red",
    });
  }
}

async function updateTicketStatusFromDetail(ticketId, newStatus) {
  try {
    const response = await post(`/tickets/${ticketId}/status/`, {
      status: newStatus,
    });

    // Update the ticket status in the UI
    const updatedTicket = messages.value.find((msg) => msg.id === ticketId);
    if (updatedTicket) {
      updatedTicket.status = newStatus;

      // Update the activeTicket to reflect changes
      activeTicket.value = { ...updatedTicket };

      // Show success notification
      toast.add({
        title: "Ticket Status Updated",
        description: `Ticket has been marked as "${formatTicketStatus(
          newStatus
        )}"`,
        color: getTicketStatusColor(newStatus),
      });

      // Close the modal if the ticket is closed
      if (newStatus === "closed") {
        setTimeout(() => {
          isTicketDetailModalOpen.value = false;
        }, 1500);
      }
    }
  } catch (error) {
    console.error("Error updating ticket status:", error);

    // Show error notification
    toast.add({
      title: "Update Failed",
      description: "Failed to update ticket status. Please try again.",
      color: "red",
    });
  }
}

async function getMessages(preserveState = false) {
  isLoading.value = true;
  try {
    // Save current messages for comparison
    const oldMessages = [...messages.value];
    const oldUpdates = [...updates.value];
    const oldSupportTickets = [...supportTickets.value];

    // Get admin notices (updates) with user filtering
    const noticesRes = await get("/admin-notice/", {
      params: {
        user_specific: true
      }
    });
    const adminNotices = noticesRes.data.map((notice) => ({
      ...notice,
      is_ticket: false,
    }));

    // Get support tickets
    const ticketsRes = await get("/tickets/");
    const supportTicketsData = ticketsRes.data.map((ticket) => ({
      ...ticket,
      is_ticket: true,
    }));    // Update separate arrays and store all data for pagination
    allUpdates.value = adminNotices; // Store all updates
    allSupportTickets.value = supportTicketsData; // Store all support tickets
    
    // Keep the current arrays for backward compatibility
    updates.value = adminNotices;
    supportTickets.value = supportTicketsData;

    // Combine messages and sort by date (for backward compatibility)
    const newMessages = [...supportTicketsData, ...adminNotices].sort(
      (a, b) => new Date(b.created_at) - new Date(a.created_at)
    );

    // If preserving state, check for new messages and notify
    if (preserveState && oldMessages.length > 0) {
      checkForNewMessages(oldMessages, newMessages);
      checkForNewUpdates(oldUpdates, adminNotices);
      checkForNewTickets(oldSupportTickets, supportTicketsData);

      // Save current expanded and read states
      const currentExpandedState = { ...expandedMessages.value };
      const currentReadState = { ...readMessages.value };

      messages.value = newMessages;
      // Restore expanded and read states for existing messages
      messages.value.forEach((msg) => {
        // If message was expanded before, keep it expanded
        if (currentExpandedState[msg.id]) {
          expandedMessages.value[msg.id] = true;
        }

        // For read status, prioritize server data for tickets, but preserve user actions
        if (msg.is_ticket) {
          // If user had manually marked it as read, keep it read
          // Otherwise, use server data
          if (currentReadState[msg.id]) {
            readMessages.value[msg.id] = true;
          } else {
            readMessages.value[msg.id] = !msg.is_unread;
          }
        } else {
          // For admin notices, use server data (is_read field)
          readMessages.value[msg.id] = msg.is_read;
        }
      });
    } else {
      // Initialize new messages
      messages.value = newMessages;

      // Initialize expanded and read states based on server data
      messages.value.forEach((msg) => {
        expandedMessages.value[msg.id] = false;
        // For tickets, use server-side read status; for admin notices, use server is_read field
        if (msg.is_ticket) {
          readMessages.value[msg.id] = !msg.is_unread; // If is_unread is false, then it's read
        } else {
          readMessages.value[msg.id] = msg.is_read; // Admin notices have is_read field
        }
      });
    }    // Count new messages based on read status
    newMessageCount.value = messages.value.filter(
      (msg) => !readMessages.value[msg.id] && (msg.is_ticket ? !msg.is_read : !msg.is_read)
    ).length;
    newTicketCount.value = allSupportTickets.value.filter(
      (ticket) => !readMessages.value[ticket.id]
    ).length;
  } catch (error) {
    console.error("Error fetching messages:", error);
    toast.add({
      title: "Error",
      description: "Failed to load messages. Please try refreshing.",
      color: "red",
      timeout: 5000,
    });
  } finally {
    setTimeout(() => {
      isLoading.value = false;
    }, 800); // Add slight delay for loading animation
  }
}

async function refreshMessages() {
  await getMessages(true); // Preserve UI state when refreshing
  // Also refresh the global unread count to keep header/balance in sync
  await fetchUnreadCount();
}

// Clear notifications banner
function clearNotifications() {
  messages.value.forEach((msg) => {
    markAsRead(msg.id);
  });

  newMessageCount.value = 0;
  newTicketCount.value = 0;
}

async function toggleReadStatus(id, event) {
  // Stop event propagation to prevent opening the detail view
  if (event) {
    event.stopPropagation();
  }

  const isCurrentlyRead = readMessages.value[id] || false;

  // Toggle read status
  readMessages.value = {
    ...readMessages.value,
    [id]: !isCurrentlyRead,
  };

  const messageToUpdate = messages.value.find((msg) => msg.id === id);
  if (messageToUpdate && messageToUpdate.is_ticket) {
    try {
      // If marking as unread
      if (isCurrentlyRead) {
        // Send unread status to server
        post(`/tickets/${id}/mark-unread/`, {}).catch((error) => {
          console.error("Error marking ticket as unread:", error);
        });
      } else {
        // Send read status to server
        post(`/tickets/${id}/mark-read/`, {}).catch((error) => {
          console.error("Error marking ticket as read:", error);
        });
      }
    } catch (error) {
      console.error("Error toggling read status:", error);
    }
  }

  // Update counts
  newMessageCount.value = messages.value.filter(
    (msg) => !readMessages.value[msg.id]
  ).length;
  newTicketCount.value = messages.value.filter(
    (msg) => msg.is_ticket && !readMessages.value[msg.id]
  ).length;
}

// Check for new messages and show notifications
function checkForNewMessages(oldMessages, newMessages) {
  // Check if there are any new messages
  const oldIds = oldMessages.map((msg) => msg.id);
  const newItems = newMessages.filter((msg) => !oldIds.includes(msg.id));

  if (newItems.length > 0) {
    // Show notification about new messages
    toast.add({
      title: `${newItems.length} New ${
        newItems.length === 1 ? "Message" : "Messages"
      }`,
      description: newItems[0].is_ticket
        ? "You have new support ticket activity"
        : "You have new messages",
      color: "primary",
      timeout: 5000,
    });
  }

  // Check for new replies in existing tickets
  newMessages.forEach((newMsg) => {
    if (!newMsg.is_ticket || !newMsg.replies || newMsg.replies.length === 0)
      return;
    const oldMsg = oldMessages.find((m) => m.id === newMsg.id);
    if (!oldMsg || !oldMsg.replies) return;

    if (newMsg.replies.length > oldMsg.replies.length) {
      // There are new replies to this ticket
      const newReplyCount = newMsg.replies.length - oldMsg.replies.length;
      toast.add({
        title: `New ${newReplyCount === 1 ? "Reply" : "Replies"} to Ticket`,
        description: `Ticket #${newMsg.id.toString().padStart(10, "0")}: ${
          newMsg.title
        }`,
        color: "primary",
        timeout: 5000,
      });
    }
  });
}

// Check for new updates
function checkForNewUpdates(oldUpdates, newUpdates) {
  const oldIds = oldUpdates.map((update) => update.id);
  const newItems = newUpdates.filter((update) => !oldIds.includes(update.id));

  if (newItems.length > 0) {
    toast.add({
      title: `${newItems.length} New Update${newItems.length > 1 ? 's' : ''}`,
      description: `You have new ${formatUpdateType(newItems[0].notification_type).toLowerCase()} notifications`,
      color: "primary",
      timeout: 5000,
    });
  }
}

// Check for new tickets
function checkForNewTickets(oldTickets, newTickets) {
  const oldIds = oldTickets.map((ticket) => ticket.id);
  const newItems = newTickets.filter((ticket) => !oldIds.includes(ticket.id));

  if (newItems.length > 0) {
    toast.add({
      title: `${newItems.length} New Support Ticket${newItems.length > 1 ? 's' : ''}`,
      description: "You have new support ticket activity",
      color: "primary",
      timeout: 5000,
    });
  }
}

// Auto-refresh interval
let autoRefreshInterval;

onMounted(async () => {
  await getMessages();
  // Refresh the global unread count to keep header/balance in sync
  await fetchUnreadCount();

  // Auto-refresh disabled - users can manually refresh by pulling down
  // autoRefreshInterval = setInterval(async () => {
  //   await getMessages(true);
  // }, 30000);
});

onBeforeUnmount(() => {
  // Clear auto-refresh interval when leaving the page
  if (autoRefreshInterval) {
    clearInterval(autoRefreshInterval);
  }
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
  display: inline-flex;
  align-items: center;
}

.message-title {
  font-size: 0.95rem;
  color: #1f2937;
  transition: all 0.2s ease;
}

.message-title:hover {
  text-decoration: underline;
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
  vertical-align: middle;
}

.status-badge {
  font-size: 0.65rem;
  padding: 0.125rem 0.375rem;
  vertical-align: middle;
}

.status-badge[class*="amber"] {
  animation: pulse-light 2s infinite;
}

@keyframes pulse-light {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.8;
  }
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease, transform 0.5s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateX(-10px);
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
  background-color: rgba(0, 0, 0, 0.1);
  color: #22c55e;
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

/* Custom scrollbar styling */
.custom-scrollbar {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 5px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.4);
  border-radius: 20px;
}

.dark .custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(75, 85, 99, 0.5);
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

/* Support ticket styles */
.message-icon-circle.admin-notice {
  background-color: #f3f4f6;
  border-color: #e5e7eb;
}

/* Update type specific styles */
.message-icon-circle.system-update {
  background-color: #f3f4f6;
  border-color: #e5e7eb;
}

.message-icon-circle.order-update {
  background-color: #dcfce7;
  border-color: #bbf7d0;
}

.message-icon-circle.withdraw-update {
  background-color: #dbeafe;
  border-color: #bfdbfe;
}

.message-icon-circle.recharge-update {
  background-color: #fed7aa;
  border-color: #fdba74;
}

.message-icon-circle.pro-update {
  background-color: #e9d5ff;
  border-color: #d8b4fe;
}

.message-icon-circle.expiring-update {
  background-color: #fef3c7;
  border-color: #fde68a;
}

.message-icon-circle.gig-update {
  background-color: #f3f4f6;
  border-color: #e5e7eb;
}

.message-icon-circle.transfer-sent-update {
  background-color: #cffafe;
  border-color: #7dd3fc;
}

.message-icon-circle.transfer-received-update {
  background-color: #d1fae5;
  border-color: #6ee7b7;
}

.message-icon-circle.deposit-update {
  background-color: #ccfbf1;
  border-color: #5eead4;
}

.message-icon-circle.gig-approved-update {
  background-color: #dcfce7;
  border-color: #bbf7d0;
}

.message-icon-circle.gig-rejected-update {
  background-color: #fee2e2;
  border-color: #fecaca;
}

.message-icon-circle.general-update {
  background-color: #dbeafe;
  border-color: #bfdbfe;
}

.status-badge {
  font-size: 0.65rem;
  padding: 0.125rem 0.375rem;
  animation: pulse-light 2s infinite;
}

@keyframes pulse-light {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.8;
  }
}

.message-icon-circle.support-ticket {
  background-color: #ede9fe;
  border-color: #ddd6fe;
}

.message-icon-circle.support-ticket.resolved {
  background-color: #dcfce7;
  border-color: #bbf7d0;
}

.message-card:hover .message-icon-circle.admin-notice {
  background-color: #e5e7eb;
  border-color: #d1d5db;
}

.message-card:hover .message-icon-circle.support-ticket {
  background-color: #ddd6fe;
  border-color: #c4b5fd;
}

.message-card:hover .message-icon-circle.support-ticket.resolved {
  background-color: #bbf7d0;
  border-color: #86efac;
}

/* Reply section styling */
.message-replies {
  background-color: rgba(249, 250, 251, 0.6);
  border-radius: 0.5rem;
  padding: 1rem;
}

.message-reply {
  transition: all 0.2s ease;
}

.message-reply:hover {
  background-color: rgba(249, 250, 251, 1);
  border-radius: 0.5rem;
}

.reply-avatar {
  transition: all 0.3s ease;
}

.reply-content {
  transition: all 0.3s ease;
}

/* Ticket status filters */
.active {
  font-weight: 500;
}

/* Notification banner styles */
.notification-banner {
  background-color: #eff6ff;
  border: 1px solid #dbeafe;
  border-radius: 0.5rem;
  padding: 1rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  animation: gentle-fade-in 0.5s ease-out forwards;
}

.notification-banner:hover {
  background-color: #e0f2fe;
}

.notification-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 0.625rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #dbeafe;
  transition: all 0.3s ease;
}

@keyframes gentle-fade-in {
  0% {
    opacity: 0;
    transform: translateY(-10px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Modal enhancements */
.focus-ring:focus {
  box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.1),
    0 0 0 4px rgba(255, 255, 255, 1);
  outline: none;
  transition: all 0.2s ease;
}

.form-group label {
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.25rem;
  display: block;
}

/* Animation for modals */
@keyframes slide-down {
  from {
    transform: translateY(-10px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

/* Custom Scrollbar */
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background-color: rgba(0, 0, 0, 0.05);
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, 0.15);
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background-color: rgba(0, 0, 0, 0.25);
}

/* Dark mode scrollbar */
.dark .custom-scrollbar::-webkit-scrollbar-track {
  background-color: rgba(255, 255, 255, 0.05);
}

.dark .custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(255, 255, 255, 0.15);
}

.dark .custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background-color: rgba(255, 255, 255, 0.25);
}

/* Reply style enhancements */
.reply-avatar {
  position: relative;
}

.reply-avatar::after {
  content: "";
  position: absolute;
  height: 100%;
  width: 1px;
  background: linear-gradient(
    to bottom,
    rgba(209, 213, 219, 0),
    rgba(209, 213, 219, 1),
    rgba(209, 213, 219, 0)
  );
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
}

/* Mark All Read button styling */
.mark-all-read-btn {
  transition: all 0.3s ease;
}

.mark-all-read-btn:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.mark-all-read-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Mobile responsive styling for button container */
@media (max-width: 640px) {
  .mark-all-read-btn {
    font-size: 0.875rem; /* text-sm */
    padding-left: 0.5rem;
    padding-right: 0.5rem;
  }
  
  /* Ensure buttons fit well in mobile row layout */
  .mark-all-read-btn span {
    white-space: nowrap;
  }
}
</style>
