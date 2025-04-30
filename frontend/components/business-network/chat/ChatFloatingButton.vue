<template>
  <div>
    <!-- Floating messenger button (hidden on mobile when chat is open) -->
    <button
      v-if="!(isMobile && isChatOpen)"
      @click="toggleChat"
      class="fixed bottom-6 right-6 z-50 flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-green-500 to-green-600 shadow-lg transition-all duration-300 hover:scale-105 hover:shadow-green-200/50 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
      :class="{ 'rotate-90 transform': isChatOpen }"
      aria-label="Open chat"
    >
      <MessageCircleIcon v-if="!isChatOpen" class="h-5 w-5 text-white" />
      <XIcon v-else class="h-5 w-5 text-white" />
      
      <!-- Notification badge -->
      <div v-if="unreadCount > 0 && !isChatOpen" class="absolute -right-1 -top-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[9px] font-bold text-white">
        {{ unreadCount }}
      </div>
    </button>

    <!-- Chat window -->
    <div
      v-show="isChatOpen"
      class="fixed z-40 overflow-hidden rounded-xl bg-white shadow-2xl transition-all duration-300"
      :class="[
        isMobile 
          ? 'bottom-0 left-0 right-0 top-0' 
          : 'bottom-24 right-6 h-[600px] w-[360px]'
      ]"
    >
      <!-- User profile section -->
      <div class="relative flex items-center justify-between border-b bg-gradient-to-r from-green-500 to-green-600 p-3 text-white">
        <div class="absolute inset-0 bg-[url('https://i.pravatar.cc/150?img=11')] opacity-5 blur-xl"></div>
        <div class="relative flex items-center">
          <div class="relative h-9 w-9 overflow-hidden rounded-full ring-2 ring-white/30">
            <img 
              :src="userProfile.avatar" 
              alt="Your profile" 
              class="h-full w-full object-cover transition-all duration-300 hover:scale-110"
            />
            <div 
              class="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full border-2 border-green-600"
              :class="userProfile.isOnline ? 'bg-green-300' : 'bg-gray-400'"
            ></div>
          </div>
          <div class="ml-2">
            <h3 class="text-sm font-medium">{{ userProfile.name }}</h3>
            <div class="flex items-center text-[10px]">
              <span>{{ userProfile.isOnline ? 'Online' : 'Offline' }}</span>
            </div>
          </div>
        </div>
        <div class="flex items-center">
          <!-- Settings gear icon -->
          <button
            @click="openSettings"
            class="relative mr-2 rounded-full p-1.5 text-white/80 transition-colors hover:bg-white/10 hover:text-white"
            aria-label="Settings"
          >
            <SettingsIcon class="h-4.5 w-4.5" />
          </button>
          
          <button
            @click="toggleChat"
            class="relative rounded-full p-1.5 text-white/80 transition-colors hover:bg-white/10 hover:text-white"
            aria-label="Close chat"
          >
            <XIcon class="h-4.5 w-4.5" />
          </button>
        </div>
      </div>

      <!-- Settings page -->
      <div v-if="showSettings" class="flex h-[calc(100%-64px)] flex-col">
        <div class="flex items-center justify-between border-b bg-white p-2.5 shadow-sm">
          <div class="flex items-center">
            <button 
              @click="showSettings = false" 
              class="mr-2 rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100"
            >
              <ArrowLeftIcon class="h-4 w-4" />
            </button>
            <h4 class="text-sm font-medium text-gray-800">Settings</h4>
          </div>
        </div>
        
        <div class="flex-1 p-4">
          <p class="text-center text-sm text-gray-500">Settings page will be designed later</p>
        </div>
      </div>

      <!-- Main content area -->
      <div v-else-if="!activeChatId && !showStoryView && !showGroupMembers && !showAllStories" class="flex h-[calc(100%-64px)] flex-col">
        <!-- Search bar -->
        <div class="p-2">
          <div class="flex items-center rounded-md bg-gray-50 px-2 py-1.5 transition-all focus-within:ring-1 focus-within:ring-green-300">
            <SearchIcon class="h-3.5 w-3.5 text-gray-400" />
            <input 
              v-model="searchQuery"
              type="text" 
              placeholder="Search friends or groups..." 
              class="ml-2 w-full bg-transparent text-xs focus:outline-none"
            />
          </div>
        </div>

        <!-- Scrollable content area -->
        <div class="flex-1 overflow-y-auto scrollbar-hide">
          <!-- Stories section -->
          <div class="p-2">
            <div class="flex items-center justify-between pb-2">
              <h4 class="text-xs font-medium text-gray-600">Stories</h4>
              <button @click="openAllStories" class="text-[10px] text-green-600">View all</button>
            </div>
            <div class="flex space-x-3 overflow-x-auto pb-1 pt-1 scrollbar-hide">
              <!-- Add story button -->
              <div class="flex flex-col items-center">
                <div 
                  class="relative h-14 w-14 flex-shrink-0 cursor-pointer transition-transform hover:scale-105"
                  @click="showAddStoryModal = true"
                >
                  <div class="absolute inset-0 flex items-center justify-center rounded-full bg-gray-100">
                    <PlusIcon class="h-6 w-6 text-green-500" />
                  </div>
                  <div class="absolute bottom-0 right-0 flex h-5 w-5 items-center justify-center rounded-full bg-green-500 text-white">
                    <CameraIcon class="h-3 w-3" />
                  </div>
                </div>
                <span class="mt-1 text-[10px]">Add story</span>
              </div>
              
              <!-- User stories -->
              <div 
                v-for="(story, index) in stories" 
                :key="index"
                class="flex flex-col items-center"
              >
                <div 
                  class="relative h-14 w-14 flex-shrink-0 cursor-pointer transition-transform hover:scale-105"
                  @click="viewStory(story)"
                >
                  <div class="absolute inset-0 rounded-full bg-gradient-to-br from-green-400 to-green-600 p-0.5">
                    <div class="h-full w-full overflow-hidden rounded-full">
                      <img 
                        :src="story.avatar" 
                        :alt="story.name" 
                        class="h-full w-full object-cover"
                      />
                    </div>
                  </div>
                  <div v-if="story.isLive" class="absolute -right-1 top-0 rounded-full bg-red-500 px-1 py-0.5 text-[8px] text-white">
                    LIVE
                  </div>
                </div>
                <span class="mt-1 text-[10px] line-clamp-1">{{ story.name }}</span>
              </div>
            </div>
          </div>

          <!-- AdsyAI chat option -->
          <div class="p-2">
            <button
              @click="openChat('adsyai', 'ai')"
              class="flex w-full items-center rounded-lg bg-gradient-to-r from-purple-50 to-pink-50 p-2 text-left transition-all hover:shadow-sm"
            >
              <div class="relative flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-purple-500 to-pink-500 shadow-inner">
                <div class="absolute inset-0 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 opacity-50 blur-sm"></div>
                <ZapIcon class="relative h-4.5 w-4.5 text-white" />
                <div class="absolute -right-0.5 -top-0.5 flex h-3 w-3 items-center justify-center rounded-full bg-white">
                  <div class="h-2 w-2 rounded-full bg-gradient-to-br from-purple-500 to-pink-500"></div>
                </div>
              </div>
              <div class="ml-2 flex-1">
                <div class="flex items-center justify-between">
                  <h4 class="text-xs font-medium text-purple-800">AdsyAI Assistant</h4>
                  <span class="rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-1.5 py-0.5 text-[9px] text-white">
                    AI
                  </span>
                </div>
                <p class="text-[11px] text-purple-600">Ask me anything about AdsyConnect</p>
              </div>
            </button>
          </div>

          <!-- Tabs for Friends and Groups -->
          <div class="px-2">
            <div class="flex">
              <button 
                @click="activeTab = 'friends'" 
                class="flex-1 border-b-2 py-2 text-xs font-medium transition-colors"
                :class="activeTab === 'friends' ? 'border-green-500 text-green-600' : 'border-transparent text-gray-500'"
              >
                Friends
              </button>
              <button 
                @click="activeTab = 'groups'" 
                class="flex-1 border-b-2 py-2 text-xs font-medium transition-colors"
                :class="activeTab === 'groups' ? 'border-green-500 text-green-600' : 'border-transparent text-gray-500'"
              >
                Groups
              </button>
            </div>
          </div>

          <!-- Friends Tab Content -->
          <div v-if="activeTab === 'friends'" class="px-2 py-1">
            <div v-if="filteredFriends.length === 0" class="flex items-center justify-center py-4 text-[11px] text-gray-500">
              <p>No friends found</p>
            </div>
            <div v-else>
              <button
                v-for="friend in displayedFriends"
                :key="friend.id"
                @click="openChat(friend.id, 'friend')"
                class="mb-1 flex w-full items-center rounded-md p-2 text-left transition-all hover:bg-gray-50"
              >
                <div class="relative h-9 w-9 flex-shrink-0 overflow-hidden rounded-full">
                  <img 
                    :src="friend.avatar" 
                    :alt="friend.name" 
                    class="h-full w-full object-cover transition-all duration-300 hover:scale-110"
                  />
                  <div 
                    class="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full border-2 border-white"
                    :class="friend.isOnline ? 'bg-green-500' : 'bg-gray-400'"
                  ></div>
                  <div 
                    v-if="friend.isBlocked" 
                    class="absolute inset-0 flex items-center justify-center rounded-full bg-black/40"
                  >
                    <BanIcon class="h-5 w-5 text-white" />
                  </div>
                </div>
                <div class="ml-2 flex-1">
                  <div class="flex items-center justify-between">
                    <h4 class="flex items-center text-xs font-medium text-gray-700">
                      {{ friend.name }}
                      <span v-if="friend.isBlocked" class="ml-1 rounded-sm bg-red-100 px-1 py-0.5 text-[8px] text-red-600">
                        BLOCKED
                      </span>
                    </h4>
                    <span class="text-[10px] text-gray-500">{{ friend.lastTime }}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <p v-if="friend.isTyping" class="text-[10px] text-green-500">
                        <span class="mr-1">typing</span>
                        <span class="typing-animation">
                          <span class="dot"></span>
                          <span class="dot"></span>
                          <span class="dot"></span>
                        </span>
                      </p>
                      <p v-else class="text-[11px] text-gray-500 line-clamp-1">{{ friend.lastMessage }}</p>
                    </div>
                    <span v-if="friend.unreadCount" class="ml-1 flex h-5 w-5 items-center justify-center rounded-full bg-green-500 text-[9px] font-medium text-white">
                      {{ friend.unreadCount }}
                    </span>
                  </div>
                </div>
              </button>
              
              <!-- Loading indicator -->
              <div v-if="isLoadingMore" class="flex justify-center py-2">
                <div class="typing-animation">
                  <span class="dot bg-gray-400"></span>
                  <span class="dot bg-gray-400"></span>
                  <span class="dot bg-gray-400"></span>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Groups Tab Content -->
          <div v-if="activeTab === 'groups'" class="px-2 py-1">
            <div class="flex items-center justify-between mb-2">
              <h4 class="text-xs font-medium text-gray-600">Groups</h4>
              <button 
                class="flex h-5 w-5 items-center justify-center rounded-full bg-green-500 text-white transition-all hover:bg-green-600"
                aria-label="Create group"
              >
                <PlusIcon class="h-3 w-3" />
              </button>
            </div>
            
            <div v-if="filteredGroups.length === 0" class="flex items-center justify-center py-4 text-[11px] text-gray-500">
              <p>No groups found</p>
            </div>
            <div v-else>
              <button
                v-for="group in filteredGroups"
                :key="group.id"
                @click="openChat(group.id, 'group')"
                class="mb-1 flex w-full items-center rounded-md p-2 text-left transition-all hover:bg-gray-50"
              >
                <div class="relative h-9 w-9 flex-shrink-0 overflow-hidden rounded-full">
                  <img 
                    :src="group.avatar" 
                    :alt="group.name" 
                    class="h-full w-full object-cover transition-all duration-300 hover:scale-110"
                  />
                  <div class="absolute bottom-0 right-0 flex h-3.5 w-3.5 items-center justify-center rounded-full bg-gray-200 text-[8px] font-bold">
                    {{ group.memberCount }}
                  </div>
                </div>
                <div class="ml-2 flex-1">
                  <div class="flex items-center justify-between">
                    <h4 class="text-xs font-medium text-gray-700">{{ group.name }}</h4>
                    <span class="text-[10px] text-gray-500">{{ group.lastTime }}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <p v-if="group.isTyping" class="text-[10px] text-green-500">
                        <span class="mr-1">{{ group.typingUser }} is typing</span>
                        <span class="typing-animation">
                          <span class="dot"></span>
                          <span class="dot"></span>
                          <span class="dot"></span>
                        </span>
                      </p>
                      <p v-else class="text-[11px] text-gray-500 line-clamp-1">
                        <span class="font-medium">{{ group.lastMessageSender }}:</span> {{ group.lastMessage }}
                      </p>
                    </div>
                    <span v-if="group.unreadCount" class="ml-1 flex h-5 w-5 items-center justify-center rounded-full bg-green-500 text-[9px] font-medium text-white">
                      {{ group.unreadCount }}
                    </span>
                  </div>
                </div>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- All Stories View -->
      <div v-else-if="showAllStories" class="flex h-[calc(100%-64px)] flex-col">
        <div class="flex items-center justify-between border-b bg-white p-2.5 shadow-sm">
          <div class="flex items-center">
            <button 
              @click="showAllStories = false" 
              class="mr-2 rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100"
            >
              <ArrowLeftIcon class="h-4 w-4" />
            </button>
            <h4 class="text-sm font-medium text-gray-800">All Stories</h4>
          </div>
          <button 
            @click="showAddStoryModal = true"
            class="rounded-full bg-green-500 p-1 text-white transition-colors hover:bg-green-600"
          >
            <PlusIcon class="h-4 w-4" />
          </button>
        </div>
        
        <div class="flex-1 p-4">
          <p class="text-center text-sm text-gray-500">All stories page will be designed later</p>
        </div>
      </div>

      <!-- Story view -->
      <div v-else-if="showStoryView" class="relative flex h-[calc(100%-64px)] flex-col bg-black">
        <!-- Story header -->
        <div class="flex items-center justify-between bg-black/80 p-3 text-white">
          <div class="flex items-center">
            <button 
              @click="closeStoryView" 
              class="mr-2 rounded-full p-1 text-white/80 transition-colors hover:bg-white/10"
            >
              <ArrowLeftIcon class="h-4 w-4" />
            </button>
            <div class="relative h-8 w-8 overflow-hidden rounded-full">
              <img 
                :src="activeStory.avatar" 
                :alt="activeStory.name" 
                class="h-full w-full object-cover"
              />
            </div>
            <div class="ml-2">
              <h4 class="text-xs font-medium">{{ activeStory.name }}</h4>
              <p class="text-[9px] text-white/70">{{ activeStory.time }}</p>
            </div>
          </div>
          <div class="flex">
            <button class="rounded-full p-1 text-white/80 transition-colors hover:bg-white/10">
              <MoreVerticalIcon class="h-4 w-4" />
            </button>
          </div>
        </div>
        
        <!-- Story content -->
        <div class="relative flex-1">
          <img 
            :src="activeStory.content" 
            alt="Story" 
            class="h-full w-full object-cover"
          />
          
          <!-- Story progress bar -->
          <div class="absolute left-0 right-0 top-0 flex gap-1 p-2">
            <div 
              v-for="(_, index) in activeStory.totalParts" 
              :key="index" 
              class="h-0.5 flex-1 overflow-hidden rounded-full bg-white/30"
            >
              <div 
                class="h-full bg-white" 
                :style="{ width: index < activeStory.currentPart ? '100%' : (index === activeStory.currentPart ? `${storyProgress}%` : '0%') }"
              ></div>
            </div>
          </div>
          
          <!-- Story reactions -->
          <div class="absolute bottom-0 left-0 right-0 flex items-center justify-between bg-gradient-to-t from-black/70 to-transparent p-4">
            <div class="flex items-center">
              <button 
                @click="reactToStory"
                class="flex items-center rounded-full bg-white/10 px-3 py-1.5 text-white transition-all hover:bg-white/20"
              >
                <HeartIcon class="mr-1 h-4 w-4" :class="activeStory.hasLiked ? 'text-red-500' : 'text-white'" />
                <span class="text-xs">{{ activeStory.likes }}</span>
              </button>
            </div>
            
            <button 
              @click="showStoryViewers = !showStoryViewers"
              class="flex items-center rounded-full bg-white/10 px-3 py-1.5 text-white transition-all hover:bg-white/20"
            >
              <EyeIcon class="mr-1 h-4 w-4" />
              <span class="text-xs">{{ activeStory.viewers.length }}</span>
            </button>
          </div>
          
          <!-- Story viewers list -->
          <div 
            v-if="showStoryViewers" 
            class="absolute bottom-16 right-4 w-48 rounded-lg bg-white py-1 shadow-lg"
          >
            <div class="px-3 py-2">
              <p class="mb-1 text-xs font-medium text-gray-500">Viewers</p>
              <div v-for="(viewer, index) in activeStory.viewers" :key="index" class="flex items-center py-1">
                <img :src="viewer.avatar" :alt="viewer.name" class="h-6 w-6 rounded-full object-cover" />
                <span class="ml-2 text-xs text-gray-700">{{ viewer.name }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Group members view -->
      <div v-else-if="showGroupMembers" class="flex h-[calc(100%-64px)] flex-col">
        <!-- Group header -->
        <div class="flex items-center justify-between border-b bg-white p-2.5 shadow-sm">
          <div class="flex items-center">
            <button 
              @click="closeGroupMembers" 
              class="mr-2 rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100"
            >
              <ArrowLeftIcon class="h-4 w-4" />
            </button>
            <div class="relative h-8 w-8 overflow-hidden rounded-full">
              <img 
                :src="activeChat.avatar" 
                :alt="activeChat.name" 
                class="h-full w-full object-cover"
              />
            </div>
            <div class="ml-2">
              <h4 class="text-sm font-medium text-gray-800">{{ activeChat.name }} Members</h4>
              <p class="text-[10px] text-gray-500">{{ activeChat.memberCount }} members</p>
            </div>
          </div>
          <button 
            @click="showAddMemberModal = true"
            class="rounded-full bg-green-500 p-1 text-white transition-colors hover:bg-green-600"
          >
            <UserPlusIcon class="h-4 w-4" />
          </button>
        </div>

        <!-- Members list -->
        <div class="flex-1 overflow-y-auto p-2">
          <div v-for="(member, index) in groupMembers" :key="index" class="mb-1 flex items-center justify-between rounded-md p-2 hover:bg-gray-50">
            <div class="flex items-center">
              <div class="relative h-8 w-8 overflow-hidden rounded-full">
                <img 
                  :src="member.avatar" 
                  :alt="member.name" 
                  class="h-full w-full object-cover"
                />
                <div 
                  class="absolute bottom-0 right-0 h-2 w-2 rounded-full border-2 border-white"
                  :class="member.isOnline ? 'bg-green-500' : 'bg-gray-400'"
                ></div>
              </div>
              <div class="ml-2">
                <h4 class="flex items-center text-xs font-medium text-gray-700">
                  {{ member.name }}
                  <span v-if="member.isAdmin" class="ml-1 rounded-sm bg-gray-200 px-1 py-0.5 text-[8px] text-gray-600">
                    ADMIN
                  </span>
                </h4>
                <p class="text-[10px] text-gray-500">{{ member.isOnline ? 'Online' : 'Offline' }}</p>
              </div>
            </div>
            <div class="flex">
              <button @click="openChatWithMember(member)" class="rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100">
                <MessageSquareIcon class="h-3.5 w-3.5" />
              </button>
              <button 
                v-if="userProfile.id !== member.id" 
                @click="toggleMemberOptions(member.id)"
                class="ml-1 rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100"
              >
                <MoreVerticalIcon class="h-3.5 w-3.5" />
              </button>
              
              <!-- Member options dropdown -->
              <div 
                v-if="activeMemberOptionsId === member.id" 
                class="absolute right-2 mt-6 w-36 rounded-lg bg-white py-1 shadow-lg ring-1 ring-black/5 z-10"
              >
                <button @click="viewMemberProfile(member)" class="flex w-full items-center px-3 py-2 text-xs text-gray-700 transition-colors hover:bg-gray-100">
                  <UserIcon class="mr-2 h-3.5 w-3.5" />
                  View profile
                </button>
                <button 
                  v-if="userProfile.isAdmin" 
                  @click="removeMemberFromGroup(member)" 
                  class="flex w-full items-center px-3 py-2 text-xs text-red-600 transition-colors hover:bg-gray-100"
                >
                  <UserMinusIcon class="mr-2 h-3.5 w-3.5" />
                  Remove
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Active chat area -->
      <div v-else-if="activeChatId" class="flex h-[calc(100%-64px)] flex-col">
        <!-- Chat header -->
        <div class="flex items-center justify-between border-b bg-white p-2.5 shadow-sm">
          <div class="flex items-center">
            <button 
              @click="closeActiveChat" 
              class="mr-2 rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100"
            >
              <ArrowLeftIcon class="h-4 w-4" />
            </button>
            <div class="relative h-8 w-8 overflow-hidden rounded-full">
              <img 
                :src="activeChat.avatar" 
                :alt="activeChat.name" 
                class="h-full w-full object-cover transition-all duration-300 hover:scale-110"
              />
              <div 
                v-if="activeChatType === 'friend'"
                class="absolute bottom-0 right-0 h-2 w-2 rounded-full border-2 border-white"
                :class="activeChat.isOnline ? 'bg-green-500' : 'bg-gray-400'"
              ></div>
              <div 
                v-if="activeChatType === 'ai'"
                class="absolute bottom-0 right-0 h-2 w-2 rounded-full border-2 border-white bg-gradient-to-br from-purple-500 to-pink-500"
              ></div>
            </div>
            <div class="ml-2">
              <h4 class="text-sm font-medium text-gray-800">{{ activeChat.name }}</h4>
              <p v-if="activeChatType === 'friend'" class="text-[10px] text-gray-500">
                {{ activeChat.isOnline ? 'Online' : 'Offline' }}
              </p>
              <p v-else-if="activeChatType === 'group'" class="text-[10px] text-gray-500">
                {{ activeChat.memberCount }} members
              </p>
              <p v-else class="text-[10px] text-purple-500">
                AI Assistant
              </p>
            </div>
          </div>
          <div class="flex">
            <button v-if="activeChatType === 'friend'" class="rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100">
              <PhoneIcon class="h-4 w-4" />
            </button>
            <button v-if="activeChatType === 'friend'" class="ml-1 rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100">
              <VideoIcon class="h-4 w-4" />
            </button>
            <button v-if="activeChatType === 'group'" @click="viewGroupMembers" class="rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100">
              <UsersIcon class="h-4 w-4" />
            </button>
            <button @click="toggleChatOptions" class="ml-1 rounded-full p-1 text-gray-500 transition-colors hover:bg-gray-100">
              <MoreVerticalIcon class="h-4 w-4" />
            </button>
          </div>
          
          <!-- Chat options dropdown -->
          <div 
            v-if="showChatOptions" 
            class="absolute right-2 top-14 z-50 w-48 rounded-lg bg-white py-1 shadow-lg ring-1 ring-black/5"
          >
            <!-- Friend options -->
            <button v-if="activeChatType === 'friend'" @click="toggleBlockUser" class="flex w-full items-center px-3 py-2 text-xs text-gray-700 transition-colors hover:bg-gray-100">
              <BanIcon class="mr-2 h-3.5 w-3.5" />
              {{ activeChat.isBlocked ? 'Unblock user' : 'Block user' }}
            </button>
            
            <!-- Group options -->
            <button v-if="activeChatType === 'group'" @click="showRenameGroupModal = true" class="flex w-full items-center px-3 py-2 text-xs text-gray-700 transition-colors hover:bg-gray-100">
              <EditIcon class="mr-2 h-3.5 w-3.5" />
              Rename group
            </button>
            <button v-if="activeChatType === 'group'" @click="leaveGroup" class="flex w-full items-center px-3 py-2 text-xs text-gray-700 transition-colors hover:bg-gray-100">
              <LogOutIcon class="mr-2 h-3.5 w-3.5" />
              Leave group
            </button>
            
            <!-- Common options -->
            <button @click="deleteChat" class="flex w-full items-center px-3 py-2 text-xs text-red-600 transition-colors hover:bg-gray-100">
              <TrashIcon class="mr-2 h-3.5 w-3.5" />
              Delete chat
            </button>
          </div>
        </div>

        <!-- Chat messages -->
        <div 
          ref="messagesContainer"
          class="flex-1 overflow-y-auto bg-gradient-to-b from-gray-50 to-white p-3"
        >
          <div v-if="activeChat.messages.length === 0" class="flex h-full flex-col items-center justify-center text-center text-gray-500">
            <div class="flex h-16 w-16 items-center justify-center rounded-full bg-green-50">
              <MessageSquareIcon class="h-8 w-8 text-green-300" />
            </div>
            <p class="mb-1 mt-3 text-xs font-medium text-gray-600">No messages yet</p>
            <p class="text-[10px] text-gray-500">Start a conversation with {{ activeChat.name }}</p>
          </div>
          
          <div v-else>
            <div 
              v-for="(message, index) in activeChat.messages" 
              :key="index"
              class="mb-3 animate-fadeIn"
            >
              <div class="mb-1 flex items-center" :class="{ 'justify-end': message.isUser }">
                <img 
                  v-if="!message.isUser" 
                  :src="activeChat.avatar" 
                  :alt="activeChat.name" 
                  class="mr-1.5 h-5 w-5 rounded-full object-cover"
                />
                <span v-if="!message.isUser && activeChatType === 'group'" class="mr-1 text-[10px] font-medium text-gray-500">
                  {{ message.sender || activeChat.name }}:
                </span>
                <img
                  v-if="message.isUser" 
                  :src="userProfile.avatar" 
                  :alt="userProfile.name" 
                  class="ml-1.5 h-5 w-5 rounded-full object-cover"
                />
              </div>
              
              <div 
                class="max-w-[80%] rounded-lg px-3 py-2 shadow-sm transition-all hover:shadow-md"
                :class="[
                  message.isUser 
                    ? 'ml-auto bg-gradient-to-r from-green-500 to-green-600 text-white' 
                    : activeChatType === 'ai'
                      ? 'bg-gradient-to-r from-purple-50 to-pink-50 text-gray-800'
                      : 'bg-white text-gray-800'
                ]"
              >
                <p class="text-xs" v-html="formatMessageWithMentions(message.text)"></p>
                
                <!-- Media preview if message has media -->
                <div v-if="message.media" class="mt-2">
                  <img 
                    v-if="message.media.type === 'image'" 
                    :src="message.media.url" 
                    alt="Image" 
                    class="max-h-40 w-full rounded-md object-cover"
                    @click="viewFullMedia(message.media)"
                  />
                  <video 
                    v-else-if="message.media.type === 'video'" 
                    :src="message.media.url" 
                    class="max-h-40 w-full rounded-md object-cover" 
                    controls
                  ></video>
                  <div v-else-if="message.media.type === 'file'" class="flex items-center">
                    <FileIcon class="h-4 w-4" :class="message.isUser ? 'text-white' : 'text-gray-500'" />
                    <span class="ml-2 text-[10px]">{{ message.media.name }}</span>
                  </div>
                  <div v-else-if="message.media.type === 'voice'" class="flex items-center">
                    <MicIcon class="h-4 w-4" :class="message.isUser ? 'text-white' : 'text-gray-500'" />
                    <div class="ml-2 flex-1">
                      <div class="h-1 w-full rounded-full" :class="message.isUser ? 'bg-white/30' : 'bg-gray-300'">
                        <div class="h-full" 
                          :style="{ width: message.media.isPlaying ? `${message.media.progress}%` : '0%' }" 
                          :class="message.isUser ? 'bg-white' : 'bg-green-500'"
                        ></div>
                      </div>
                      <div class="mt-1 flex items-center justify-between">
                        <span class="text-[8px]" :class="message.isUser ? 'text-white/70' : 'text-gray-500'">
                          {{ formatVoiceDuration(message.media.currentTime || 0) }}
                        </span>
                        <span class="text-[8px]" :class="message.isUser ? 'text-white/70' : 'text-gray-500'">
                          {{ formatVoiceDuration(message.media.duration || 0) }}
                        </span>
                      </div>
                    </div>
                    <button 
                      @click="playVoiceMessage(message)" 
                      class="ml-2 rounded-full p-1" 
                      :class="message.isUser ? 'bg-white/20 text-white' : 'bg-gray-200 text-gray-700'"
                    >
                      <PlayIcon v-if="!message.media.isPlaying" class="h-3 w-3" />
                      <PauseIcon v-else class="h-3 w-3" />
                    </button>
                  </div>
                </div>
              </div>
              <div 
                class="mt-0.5 flex items-center text-[9px] text-gray-400"
                :class="{ 'justify-end': message.isUser }"
              >
                <span>{{ message.time }}</span>
                <span v-if="message.isUser && message.read" class="ml-1 text-green-500">
                  <CheckCheckIcon class="h-3 w-3" />
                </span>
                <span v-else-if="message.isUser" class="ml-1 text-gray-400">
                  <CheckIcon class="h-3 w-3" />
                </span>
              </div>
            </div>
            
            <!-- Typing indicator -->
            <div v-if="isOtherUserTyping" class="mb-3 flex items-center animate-fadeIn">
              <img 
                :src="activeChat.avatar" 
                :alt="activeChat.name" 
                class="mr-1.5 h-5 w-5 rounded-full object-cover"
              />
              <div class="rounded-lg bg-gray-100 px-3 py-2">
                <div class="typing-animation">
                  <span class="dot"></span>
                  <span class="dot"></span>
                  <span class="dot"></span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Chat input options -->
        <div class="border-t bg-white p-2">
          <!-- Media and attachment options -->
          <div class="mb-1.5 flex items-center justify-between px-1">
            <div class="flex space-x-3">
              <button @click="showMediaPicker = !showMediaPicker" class="flex items-center text-[10px] text-gray-500 transition-colors hover:text-green-500">
                <ImageIcon class="mr-1 h-3.5 w-3.5" />
                <span>Media</span>
              </button>
              <button 
                @touchstart="startVoiceRecording" 
                @touchend="stopVoiceRecording"
                @mousedown="startVoiceRecording"
                @mouseup="stopVoiceRecording"
                @mouseleave="stopVoiceRecording"
                class="flex items-center text-[10px] text-gray-500 transition-colors hover:text-green-500"
              >
                <MicIcon class="mr-1 h-3.5 w-3.5" :class="isRecording ? 'text-red-500 animate-pulse' : ''" />
                <span>{{ isRecording ? 'Recording...' : 'Voice' }}</span>
              </button>
              <label class="flex items-center text-[10px] text-gray-500 transition-colors hover:text-green-500 cursor-pointer">
                <PaperclipIcon class="mr-1 h-3.5 w-3.5" />
                <span>Files</span>
                <input type="file" class="hidden" @change="handleFileSelect" />
              </label>
            </div>
            <div class="flex items-center">
              <button v-if="activeChatType === 'group'" @click="toggleMentionList" class="mr-2 text-[10px] text-gray-500 transition-colors hover:text-green-500">
                <AtSignIcon class="h-3.5 w-3.5" />
              </button>
              <button @click="toggleEmojiPicker" class="text-[10px] text-gray-500 transition-colors hover:text-green-500">
                <SmileIcon class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
          
          <!-- Media picker -->
          <div v-if="showMediaPicker" class="mb-2 rounded-md border bg-gray-50 p-3 shadow-sm">
            <div class="flex flex-col items-center justify-center">
              <p class="mb-2 text-xs text-gray-600">Upload media from your device</p>
              <div class="flex space-x-3">
                <label class="flex flex-col items-center justify-center rounded-md bg-gray-100 px-4 py-2 text-gray-500 cursor-pointer hover:bg-gray-200">
                  <ImageIcon class="h-5 w-5 mb-1" />
                  <span class="text-[10px]">Images</span>
                  <input type="file" accept="image/*" multiple class="hidden" @change="handleMediaUpload" />
                </label>
                <label class="flex flex-col items-center justify-center rounded-md bg-gray-100 px-4 py-2 text-gray-500 cursor-pointer hover:bg-gray-200">
                  <VideoIcon class="h-5 w-5 mb-1" />
                  <span class="text-[10px]">Videos</span>
                  <input type="file" accept="video/*" multiple class="hidden" @change="handleMediaUpload" />
                </label>
              </div>
            </div>
            <div v-if="uploadedMedia.length > 0" class="mt-3">
              <p class="mb-1 text-xs text-gray-600">Selected media ({{ uploadedMedia.length }})</p>
              <div class="flex flex-wrap gap-2">
                <div v-for="(media, index) in uploadedMedia" :key="index" class="relative h-16 w-16 overflow-hidden rounded-md">
                  <img v-if="media.type.includes('image')" :src="media.url" class="h-full w-full object-cover" />
                  <video v-else-if="media.type.includes('video')" :src="media.url" class="h-full w-full object-cover"></video>
                  <button @click="removeUploadedMedia(index)" class="absolute right-0.5 top-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-black/50 text-white">
                    <XIcon class="h-3 w-3" />
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Emoji picker -->
          <div v-if="showEmojiPicker" class="mb-2 grid grid-cols-8 gap-1 rounded-md border bg-white p-2 shadow-sm">
            <button 
              v-for="emoji in emojis" 
              :key="emoji"
              @click="addEmoji(emoji)"
              class="flex h-8 w-8 items-center justify-center rounded-md text-lg hover:bg-gray-100"
            >
              {{ emoji }}
            </button>
          </div>
          
          <!-- Mention list -->
          <div 
            v-if="showMentionList && activeChatType === 'group'" 
            class="mb-2 max-h-32 overflow-y-auto rounded-md border bg-white p-1 shadow-sm scrollbar-hide"
          >
            <button 
              v-for="member in filteredGroupMembers" 
              :key="member.id"
              @click="mentionUser(member)"
              class="flex w-full items-center rounded-md p-1 text-left hover:bg-gray-50"
            >
              <img :src="member.avatar" :alt="member.name" class="h-5 w-5 rounded-full object-cover" />
              <span class="ml-2 text-xs">{{ member.name }}</span>
            </button>
          </div>
          
          <!-- Text input -->
          <div class="flex items-center rounded-full border bg-gray-50 px-3 py-2 transition-all focus-within:border-green-300 focus-within:ring-1 focus-within:ring-green-200">
            <input
              v-model="newMessage"
              @keyup.enter="sendMessage"
              @input="handleInput"
              @keydown="handleKeyDown"
              type="text"
              :placeholder="`Message ${activeChat.name}...`"
              class="flex-1 bg-transparent text-xs focus:outline-none"
            />
            <button
              @click="sendMessage"
              class="ml-2 flex h-6 w-6 items-center justify-center rounded-full bg-gradient-to-r from-green-500 to-green-600 text-white transition-all hover:shadow-sm disabled:opacity-50"
              :disabled="!newMessage.trim() && !selectedMedia && !recordedVoice && !selectedFile && uploadedMedia.length === 0"
              aria-label="Send message"
            >
              <SendIcon class="h-3 w-3" />
            </button>
          </div>
          
          <!-- Voice recording preview -->
          <div v-if="recordedVoice" class="mt-2 flex items-center rounded-md bg-gray-100 p-2">
            <MicIcon class="h-5 w-5 text-gray-500" />
            <div class="ml-2 flex-1">
              <div class="h-1 w-full rounded-full bg-gray-300">
                <div class="h-full w-full rounded-full bg-green-500"></div>
              </div>
              <div class="mt-1 flex items-center justify-between">
                <span class="text-[8px] text-gray-500">0:{{ recordingDuration.toString().padStart(2, '0') }}</span>
              </div>
            </div>
            <button @click="clearRecordedVoice" class="rounded-full p-1 text-gray-500 hover:bg-gray-200">
              <XIcon class="h-3.5 w-3.5" />
            </button>
          </div>
          
          <!-- Selected file preview -->
          <div v-if="selectedFile" class="mt-2 flex items-center rounded-md bg-gray-100 p-2">
            <FileIcon class="h-5 w-5 text-gray-500" />
            <div class="ml-2 flex-1">
              <p class="text-[10px] font-medium text-gray-700">{{ selectedFileName }}</p>
              <p class="text-[9px] text-gray-500">Ready to send</p>
            </div>
            <button @click="clearSelectedFile" class="rounded-full p-1 text-gray-500 hover:bg-gray-200">
              <XIcon class="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      </div>
      
      <!-- Add story modal -->
      <div v-if="showAddStoryModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-[90%] max-w-md rounded-lg bg-white p-4 shadow-xl">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-sm font-medium">Create Story</h3>
            <button @click="showAddStoryModal = false" class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
              <XIcon class="h-4 w-4" />
            </button>
          </div>
          
          <div class="mb-4 flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 p-6">
            <ImageIcon class="mb-2 h-10 w-10 text-gray-400" />
            <p class="mb-1 text-xs text-gray-600">Upload a photo or video</p>
            <p class="text-[10px] text-gray-500">Your story will be visible for 24 hours</p>
            <label class="mt-3 rounded-full bg-green-500 px-4 py-1.5 text-xs text-white transition-colors hover:bg-green-600 cursor-pointer">
              Select from gallery
              <input type="file" accept="image/*,video/*" class="hidden" />
            </label>
          </div>
          
          <div class="flex justify-end">
            <button @click="showAddStoryModal = false" class="mr-2 rounded-md px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-100">
              Cancel
            </button>
            <button class="rounded-md bg-green-500 px-3 py-1.5 text-xs text-white transition-colors hover:bg-green-600">
              Create Story
            </button>
          </div>
        </div>
      </div>
      
      <!-- Add member modal -->
      <div v-if="showAddMemberModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-[90%] max-w-md rounded-lg bg-white p-4 shadow-xl">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-sm font-medium">Add Members</h3>
            <button @click="showAddMemberModal = false" class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
              <XIcon class="h-4 w-4" />
            </button>
          </div>
          
          <div class="mb-3">
            <div class="flex items-center rounded-md bg-gray-50 px-2 py-1.5">
              <SearchIcon class="h-3.5 w-3.5 text-gray-400" />
              <input 
                type="text" 
                placeholder="Search friends..." 
                class="ml-2 w-full bg-transparent text-xs focus:outline-none"
              />
            </div>
          </div>
          
          <div class="mb-4 max-h-60 overflow-y-auto scrollbar-hide">
            <!-- Selected members -->
            <div v-if="selectedMembers.length > 0" class="mb-2 border-b pb-2">
              <p class="mb-1 text-xs font-medium text-gray-500">Selected ({{ selectedMembers.length }})</p>
              <div class="flex flex-wrap gap-1">
                <div 
                  v-for="memberId in selectedMembers" 
                  :key="memberId"
                  class="flex items-center rounded-full bg-green-100 px-2 py-0.5"
                >
                  <img 
                    :src="getFriendById(memberId).avatar" 
                    :alt="getFriendById(memberId).name" 
                    class="mr-1 h-4 w-4 rounded-full object-cover" 
                  />
                  <span class="text-[10px] text-green-800">{{ getFriendById(memberId).name }}</span>
                  <button @click="deselectMember(memberId)" class="ml-1 text-green-600">
                    <XIcon class="h-3 w-3" />
                  </button>
                </div>
              </div>
            </div>
            
            <!-- Available friends to add -->
            <div v-for="friend in availableFriendsToAdd" :key="friend.id" class="flex items-center justify-between p-2 hover:bg-gray-50">
              <div class="flex items-center">
                <img :src="friend.avatar" :alt="friend.name" class="h-8 w-8 rounded-full object-cover" />
                <span class="ml-2 text-xs">{{ friend.name }}</span>
              </div>
              <button 
                @click="toggleSelectMember(friend.id)"
                class="rounded-full p-1 transition-colors"
                :class="isSelectedMember(friend.id) ? 'bg-green-500 text-white' : 'bg-gray-200 text-gray-600 hover:bg-green-500 hover:text-white'"
              >
                <CheckIcon v-if="isSelectedMember(friend.id)" class="h-3 w-3" />
                <PlusIcon v-else class="h-3 w-3" />
              </button>
            </div>
          </div>
          
          <div class="flex justify-end">
            <button @click="showAddMemberModal = false" class="mr-2 rounded-md px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-100">
              Cancel
            </button>
            <button @click="addMembersToGroup" class="rounded-md bg-green-500 px-3 py-1.5 text-xs text-white transition-colors hover:bg-green-600">
              Add Selected
            </button>
          </div>
        </div>
      </div>
      
      <!-- Delete chat confirmation modal -->
      <div v-if="showDeleteConfirmation" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-[90%] max-w-md rounded-lg bg-white p-4 shadow-xl">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-sm font-medium">Delete Chat</h3>
            <button @click="showDeleteConfirmation = false" class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
              <XIcon class="h-4 w-4" />
            </button>
          </div>
          
          <p class="mb-4 text-xs text-gray-600">Are you sure you want to delete this chat? This action cannot be undone.</p>
          
          <div class="flex justify-end">
            <button @click="showDeleteConfirmation = false" class="mr-2 rounded-md px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-100">
              Cancel
            </button>
            <button @click="confirmDeleteChat" class="rounded-md bg-red-500 px-3 py-1.5 text-xs text-white transition-colors hover:bg-red-600">
              Delete
            </button>
          </div>
        </div>
      </div>

      <!-- Rename group modal -->
      <div v-if="showRenameGroupModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-[90%] max-w-md rounded-lg bg-white p-4 shadow-xl">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-sm font-medium">Rename Group</h3>
            <button @click="showRenameGroupModal = false" class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
              <XIcon class="h-4 w-4" />
            </button>
          </div>
          
          <div class="mb-4">
            <label class="mb-1 block text-xs font-medium text-gray-700">Group Name</label>
            <input 
              v-model="newGroupName" 
              type="text" 
              class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-green-500 focus:outline-none focus:ring-1 focus:ring-green-500" 
              placeholder="Enter new group name"
            />
          </div>
          
          <div class="flex justify-end">
            <button @click="showRenameGroupModal = false" class="mr-2 rounded-md px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-100">
              Cancel
            </button>
            <button 
              @click="renameGroup" 
              class="rounded-md bg-green-500 px-3 py-1.5 text-xs text-white transition-colors hover:bg-green-600"
              :disabled="!newGroupName.trim()"
            >
              Rename
            </button>
          </div>
        </div>
      </div>

      <!-- Member profile modal -->
      <div v-if="showMemberProfile" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-[90%] max-w-md rounded-lg bg-white p-4 shadow-xl">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-sm font-medium">Member Profile</h3>
            <button @click="showMemberProfile = false" class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
              <XIcon class="h-4 w-4" />
            </button>
          </div>
          
          <div v-if="activeMember" class="flex flex-col items-center">
            <div class="relative h-20 w-20 overflow-hidden rounded-full">
              <img :src="activeMember.avatar" :alt="activeMember.name" class="h-full w-full object-cover" />
              <div 
                class="absolute bottom-0 right-0 h-4 w-4 rounded-full border-2 border-white"
                :class="activeMember.isOnline ? 'bg-green-500' : 'bg-gray-400'"
              ></div>
            </div>
            <h4 class="mt-2 text-sm font-medium">{{ activeMember.name }}</h4>
            <p class="text-xs text-gray-500">{{ activeMember.isOnline ? 'Online' : 'Offline' }}</p>
            
            <div class="mt-4 flex w-full justify-center space-x-3">
              <button @click="openChatWithMember(activeMember); showMemberProfile = false" class="flex items-center rounded-md bg-green-500 px-3 py-1.5 text-xs text-white">
                <MessageSquareIcon class="mr-1 h-3.5 w-3.5" />
                Message
              </button>
              <button v-if="userProfile.isAdmin && userProfile.id !== activeMember.id" @click="removeMemberFromGroup(activeMember); showMemberProfile = false" class="flex items-center rounded-md bg-red-500 px-3 py-1.5 text-xs text-white">
                <UserMinusIcon class="mr-1 h-3.5 w-3.5" />
                Remove
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Full media view modal -->
      <div v-if="showFullMedia" class="fixed inset-0 z-50 flex items-center justify-center bg-black/90">
        <button @click="showFullMedia = false" class="absolute right-4 top-4 rounded-full bg-black/50 p-2 text-white">
          <XIcon class="h-6 w-6" />
        </button>
        <img v-if="fullMediaItem && fullMediaItem.type === 'image'" :src="fullMediaItem.url" class="max-h-[90vh] max-w-[90vw] object-contain" />
        <video v-else-if="fullMediaItem && fullMediaItem.type === 'video'" :src="fullMediaItem.url" controls class="max-h-[90vh] max-w-[90vw]"></video>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue';
import { 
  MessageCircleIcon, 
  XIcon, 
  MessageSquareIcon, 
  SendIcon, 
  ArrowLeftIcon,
  PhoneIcon,
  VideoIcon,
  MoreVerticalIcon,
  PaperclipIcon,
  SearchIcon,
  PlusIcon,
  ImageIcon,
  MicIcon,
  SmileIcon,
  ZapIcon,
  CheckIcon,
  CheckCheckIcon,
  SettingsIcon,
  BellIcon,
  ShieldIcon,
  HelpCircleIcon,
  CameraIcon,
  HeartIcon,
  EyeIcon,
  UsersIcon,
  UserPlusIcon,
  AtSignIcon,
  FileIcon,
  PlayIcon,
  PauseIcon,
  BanIcon,
  TrashIcon,
  EditIcon,
  LogOutIcon,
  UserIcon,
  UserMinusIcon
} from 'lucide-vue-next';

// User profile
const userProfile = ref({
  id: 'user1',
  name: 'Alex Johnson',
  avatar: 'https://i.pravatar.cc/150?img=11',
  isOnline: true,
  isAdmin: true
});

// Toggle user online status
const toggleStatus = () => {
  userProfile.value.isOnline = !userProfile.value.isOnline;
};

// Set status explicitly
const setStatus = (status) => {
  userProfile.value.isOnline = status;
};

// Settings state
const showSettings = ref(false);

const openSettings = () => {
  showSettings.value = true;
};

// Stories data
const stories = ref([
  {
    id: 'story1',
    name: 'Sarah',
    avatar: 'https://i.pravatar.cc/150?img=5',
    isLive: true,
    content: 'https://i.pravatar.cc/800?img=5',
    time: '2 hours ago',
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours from now
    totalParts: 3,
    currentPart: 0,
    likes: 12,
    hasLiked: false,
    viewers: [
      { name: 'Michael Chen', avatar: 'https://i.pravatar.cc/150?img=3' },
      { name: 'Emma Rodriguez', avatar: 'https://i.pravatar.cc/150?img=9' },
      { name: 'David Kim', avatar: 'https://i.pravatar.cc/150?img=12' }
    ]
  },
  {
    id: 'story2',
    name: 'Michael',
    avatar: 'https://i.pravatar.cc/150?img=3',
    isLive: false,
    content: 'https://i.pravatar.cc/800?img=3',
    time: '45 minutes ago',
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    totalParts: 2,
    currentPart: 0,
    likes: 8,
    hasLiked: true,
    viewers: [
      { name: 'Sarah Williams', avatar: 'https://i.pravatar.cc/150?img=5' },
      { name: 'Alex Johnson', avatar: 'https://i.pravatar.cc/150?img=11' }
    ]
  },
  {
    id: 'story3',
    name: 'Emma',
    avatar: 'https://i.pravatar.cc/150?img=9',
    isLive: false,
    content: 'https://i.pravatar.cc/800?img=9',
    time: '3 hours ago',
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    totalParts: 4,
    currentPart: 0,
    likes: 15,
    hasLiked: false,
    viewers: [
      { name: 'Michael Chen', avatar: 'https://i.pravatar.cc/150?img=3' },
      { name: 'Alex Johnson', avatar: 'https://i.pravatar.cc/150?img=11' },
      { name: 'Jessica Lee', avatar: 'https://i.pravatar.cc/150?img=25' }
    ]
  },
  {
    id: 'story4',
    name: 'David',
    avatar: 'https://i.pravatar.cc/150?img=12',
    isLive: false,
    content: 'https://i.pravatar.cc/800?img=12',
    time: '1 hour ago',
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    totalParts: 1,
    currentPart: 0,
    likes: 5,
    hasLiked: false,
    viewers: [
      { name: 'Sarah Williams', avatar: 'https://i.pravatar.cc/150?img=5' }
    ]
  },
  {
    id: 'story5',
    name: 'Jessica',
    avatar: 'https://i.pravatar.cc/150?img=25',
    isLive: true,
    content: 'https://i.pravatar.cc/800?img=25',
    time: '20 minutes ago',
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    totalParts: 2,
    currentPart: 0,
    likes: 20,
    hasLiked: true,
    viewers: [
      { name: 'Michael Chen', avatar: 'https://i.pravatar.cc/150?img=3' },
      { name: 'Emma Rodriguez', avatar: 'https://i.pravatar.cc/150?img=9' },
      { name: 'Alex Johnson', avatar: 'https://i.pravatar.cc/150?img=11' },
      { name: 'David Kim', avatar: 'https://i.pravatar.cc/150?img=12' }
    ]
  }
]);

// Story view state
const showStoryView = ref(false);
const showAllStories = ref(false);
const activeStory = ref(null);
const storyProgress = ref(0);
const storyInterval = ref(null);
const showStoryViewers = ref(false);
const showAddStoryModal = ref(false);
const showStoryOptions = ref(false);

// Toggle story options
const toggleStoryOptions = () => {
  showStoryOptions.value = !showStoryOptions.value;
};

// Open all stories page
const openAllStories = () => {
  showAllStories.value = true;
  showStoryOptions.value = false;
};

// View story
const viewStory = (story) => {
  activeStory.value = { ...story };
  showStoryView.value = true;
  storyProgress.value = 0;

  // Start story progress
  if (storyInterval.value) clearInterval(storyInterval.value);
  storyInterval.value = setInterval(() => {
    storyProgress.value += 1;
    if (storyProgress.value >= 100) {
      // Move to next part or close
      if (activeStory.value.currentPart < activeStory.value.totalParts - 1) {
        activeStory.value.currentPart++;
        storyProgress.value = 0;
      } else {
        closeStoryView();
      }
    }
  }, 50); // Update every 50ms for smooth progress
};

// Close story view
const closeStoryView = () => {
  showStoryView.value = false;
  activeStory.value = null;
  showStoryViewers.value = false;
  if (storyInterval.value) {
    clearInterval(storyInterval.value);
    storyInterval.value = null;
  }
};

// React to story
const reactToStory = () => {
  if (!activeStory.value) return;

  if (activeStory.value.hasLiked) {
    activeStory.value.likes--;
    activeStory.value.hasLiked = false;
  } else {
    activeStory.value.likes++;
    activeStory.value.hasLiked = true;
  }

  // Update the original story in the stories array
  const storyIndex = stories.value.findIndex(s => s.id === activeStory.value.id);
  if (storyIndex !== -1) {
    stories.value[storyIndex].likes = activeStory.value.likes;
    stories.value[storyIndex].hasLiked = activeStory.value.hasLiked;
  }
};

// AdsyAI data
const adsyAI = ref({
  id: 'adsyai',
  name: 'AdsyAI Assistant',
  avatar: 'https://i.pravatar.cc/150?img=68',
  messages: [
    {
      text: 'Hello! I\'m AdsyAI, your personal assistant. How can I help you today?',
      isUser: false,
      time: '10:30 AM',
      sender: 'AdsyAI'
    }
  ]
});

// Friends data
const friends = ref([
  {
    id: 'friend1',
    name: 'Sarah Williams',
    avatar: 'https://i.pravatar.cc/150?img=5',
    isOnline: true,
    isTyping: true,
    lastMessage: 'Are we still meeting tomorrow?',
    lastTime: '10:33 AM',
    unreadCount: 2,
    isBlocked: false,
    messages: [
      {
        text: 'Hey, how are you doing?',
        isUser: false,
        time: '10:30 AM',
        sender: 'Sarah Williams',
        read: true
      },
      {
        text: 'I\'m good, thanks! How about you?',
        isUser: true,
        time: '10:32 AM',
        read: true
      },
      {
        text: 'Great! Are we still meeting tomorrow?',
        isUser: false,
        time: '10:33 AM',
        sender: 'Sarah Williams',
        read: true
      }
    ]
  },
  {
    id: 'friend2',
    name: 'Michael Chen',
    avatar: 'https://i.pravatar.cc/150?img=3',
    isOnline: false,
    isTyping: false,
    lastMessage: 'Check out this new ad campaign',
    lastTime: 'Yesterday',
    unreadCount: 0,
    isBlocked: false,
    messages: [
      {
        text: 'Hey, I saw your latest post. Great work!',
        isUser: false,
        time: 'Yesterday',
        sender: 'Michael Chen',
        read: true
      },
      {
        text: 'Thanks! I spent a lot of time on it.',
        isUser: true,
        time: 'Yesterday',
        read: true
      },
      {
        text: 'Check out this new ad campaign I\'m working on.',
        isUser: false,
        time: 'Yesterday',
        sender: 'Michael Chen',
        read: true
      }
    ]
  },
  {
    id: 'friend3',
    name: 'Emma Rodriguez',
    avatar: 'https://i.pravatar.cc/150?img=9',
    isOnline: true,
    isTyping: false,
    lastMessage: 'The client loved our presentation!',
    lastTime: 'Monday',
    unreadCount: 0,
    isBlocked: false,
    messages: [
      {
        text: 'Just got out of the meeting with the client.',
        isUser: false,
        time: 'Monday',
        sender: 'Emma Rodriguez',
        read: true
      },
      {
        text: 'How did it go?',
        isUser: true,
        time: 'Monday',
        read: true
      },
      {
        text: 'The client loved our presentation!',
        isUser: false,
        time: 'Monday',
        sender: 'Emma Rodriguez',
        read: true
      }
    ]
  }
]);

// Generate more friends for pagination demo
for (let i = 4; i <= 20; i++) {
  friends.value.push({
    id: `friend${i}`,
    name: `Friend ${i}`,
    avatar: `https://i.pravatar.cc/150?img=${20 + i}`,
    isOnline: Math.random() > 0.5,
    isTyping: false,
    lastMessage: `This is message ${i}`,
    lastTime: 'Last week',
    unreadCount: 0,
    isBlocked: i % 7 === 0, // Block some friends for demo
    messages: []
  });
}

// Groups data
const groups = ref([
  {
    id: 'group1',
    name: 'Marketing Team',
    avatar: 'https://i.pravatar.cc/150?img=68',
    memberCount: 8,
    isTyping: true,
    typingUser: 'Emma',
    lastMessage: 'Let\'s finalize the Q3 campaign',
    lastMessageSender: 'Emma',
    lastTime: '9:05 AM',
    unreadCount: 5,
    messages: [
      {
        text: 'Good morning team!',
        isUser: false,
        time: '9:00 AM',
        sender: 'Sarah',
        read: true
      },
      {
        text: 'Morning everyone!',
        isUser: true,
        time: '9:02 AM',
        read: true
      },
      {
        text: 'Let\'s finalize the Q3 campaign today',
        isUser: false,
        time: '9:05 AM',
        sender: 'Emma',
        read: true
      }
    ]
  },
  {
    id: 'group2',
    name: 'AdsyConnect Devs',
    avatar: 'https://i.pravatar.cc/150?img=67',
    memberCount: 12,
    isTyping: false,
    typingUser: '',
    lastMessage: 'New feature deployment scheduled',
    lastMessageSender: 'Michael',
    lastTime: 'Yesterday',
    unreadCount: 0,
    messages: [
      {
        text: 'The new analytics dashboard is ready for testing',
        isUser: false,
        time: 'Yesterday',
        sender: 'David',
        read: true
      },
      {
        text: 'I\'ll take a look at it this afternoon',
        isUser: true,
        time: 'Yesterday',
        read: true
      },
      {
        text: 'New feature deployment scheduled for Friday',
        isUser: false,
        time: 'Yesterday',
        sender: 'Michael',
        read: true
      }
    ]
  },
  {
    id: 'group3',
    name: 'Client Projects',
    avatar: 'https://i.pravatar.cc/150?img=66',
    memberCount: 5,
    isTyping: false,
    typingUser: '',
    lastMessage: 'Nordica wants to increase their budget',
    lastMessageSender: 'Jessica',
    lastTime: 'Monday',
    unreadCount: 0,
    messages: [
      {
        text: 'Update on the Nordica account',
        isUser: false,
        time: 'Monday',
        sender: 'Jessica',
        read: true
      },
      {
        text: 'What\'s the latest?',
        isUser: true,
        time: 'Monday',
        read: true
      },
      {
        text: 'Nordica wants to increase their budget for Q4',
        isUser: false,
        time: 'Monday',
        sender: 'Jessica',
        read: true
      }
    ]
  }
]);

// Group members data
const groupMembers = ref([
  {
    id: 'user1',
    name: 'Alex Johnson',
    avatar: 'https://i.pravatar.cc/150?img=11',
    isOnline: true,
    isAdmin: true
  },
  {
    id: 'friend1',
    name: 'Sarah Williams',
    avatar: 'https://i.pravatar.cc/150?img=5',
    isOnline: true,
    isAdmin: true
  },
  {
    id: 'friend2',
    name: 'Michael Chen',
    avatar: 'https://i.pravatar.cc/150?img=3',
    isOnline: false,
    isAdmin: false
  },
  {
    id: 'friend3',
    name: 'Emma Rodriguez',
    avatar: 'https://i.pravatar.cc/150?img=9',
    isOnline: true,
    isAdmin: false
  },
  {
    id: 'friend4',
    name: 'David Kim',
    avatar: 'https://i.pravatar.cc/150?img=12',
    isOnline: false,
    isAdmin: false
  },
  {
    id: 'friend5',
    name: 'Jessica Lee',
    avatar: 'https://i.pravatar.cc/150?img=25',
    isOnline: true,
    isAdmin: false
  }
]);

// UI state
const isChatOpen = ref(false);
const isMobile = ref(false);
const activeChatId = ref(null);
const activeChatType = ref(null);
const newMessage = ref('');
const messagesContainer = ref(null);
const chatListContainer = ref(null);
const isUserTyping = ref(false);
const isOtherUserTyping = ref(false);
const typingTimeout = ref(null);
const showGroupMembers = ref(false);
const showAddMemberModal = ref(false);
const showMentionList = ref(false);
const activeTab = ref('friends');
const searchQuery = ref('');
const currentPage = ref(1);
const itemsPerPage = ref(15);
const isLoadingMore = ref(false);
const showMediaPicker = ref(false);
const showEmojiPicker = ref(false);
const selectedMedia = ref(null);
const selectedMediaType = ref(null);
const isRecording = ref(false);
const recordedVoice = ref(false);
const recordingDuration = ref(0);
const recordingInterval = ref(null);
const selectedFile = ref(null);
const selectedFileName = ref('');
const showChatOptions = ref(false);
const showDeleteConfirmation = ref(false);
const showRenameGroupModal = ref(false);
const newGroupName = ref('');
const showMemberProfile = ref(false);
const activeMember = ref(null);
const activeMemberOptionsId = ref(null);
const showFullMedia = ref(false);
const fullMediaItem = ref(null);
const mentionSearch = ref('');
const uploadedMedia = ref([]);
const mentionQuery = ref('');
const mentionStartIndex = ref(-1);

// Emojis for picker
const emojis = ref(['😊', '😂', '❤️', '👍', '🎉', '🔥', '😎', '🙏', '😢', '😍', '🤔', '👏', '💪', '🌟', '💯', '🤣']);

// Computed properties
const activeChat = computed(() => {
  if (!activeChatId.value) return null;

  if (activeChatType.value === 'friend') {
    return friends.value.find(f => f.id === activeChatId.value);
  } else if (activeChatType.value === 'group') {
    return groups.value.find(g => g.id === activeChatId.value);
  } else if (activeChatType.value === 'ai') {
    return adsyAI.value;
  }

  return null;
});

const unreadCount = computed(() => {
  const friendUnread = friends.value.reduce((total, friend) => total + (friend.unreadCount || 0), 0);
  const groupUnread = groups.value.reduce((total, group) => total + (group.unreadCount || 0), 0);
  return friendUnread + groupUnread;
});

// Filtered friends based on search
const filteredFriends = computed(() => {
  if (!searchQuery.value) return friends.value;
  return friends.value.filter(friend => 
    friend.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

// Displayed friends (paginated)
const displayedFriends = computed(() => {
  const endIndex = currentPage.value * itemsPerPage.value;
  return filteredFriends.value.slice(0, endIndex);
});

// Filtered groups based on search
const filteredGroups = computed(() => {
  if (!searchQuery.value) return groups.value;
  return groups.value.filter(group => 
    group.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

// Check if there are more friends to load
const hasMoreFriends = computed(() => {
  return displayedFriends.value.length < filteredFriends.value.length;
});

// Available friends to add to group
const availableFriendsToAdd = computed(() => {
  return friends.value.filter(friend => !groupMembers.value.some(member => member.id === friend.id));
});

// Filtered group members based on @ mention search
const filteredGroupMembers = computed(() => {
  if (!mentionQuery.value) return groupMembers.value;
  return groupMembers.value.filter(member => 
    member.name.toLowerCase().includes(mentionQuery.value.toLowerCase())
  );
});

// Methods
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768;
};

const toggleChat = () => {
  isChatOpen.value = !isChatOpen.value;

  if (!isChatOpen.value) {
    // Close all modals and views
    showSettings.value = false;
    closeStoryView();
    showGroupMembers.value = false;
    showAddMemberModal.value = false;
    showAddStoryModal.value = false;
    showAllStories.value = false;
    showStoryOptions.value = false;
    showChatOptions.value = false;
    showDeleteConfirmation.value = false;
    showRenameGroupModal.value = false;
    showMemberProfile.value = false;
    showFullMedia.value = false;
  }
};

const openChat = (id, type) => {
  activeChatId.value = id;
  activeChatType.value = type;

  // Reset unread count
  if (type === 'friend') {
    const friend = friends.value.find(f => f.id === id);
    if (friend) friend.unreadCount = 0;
  } else if (type === 'group') {
    const group = groups.value.find(g => g.id === id);
    if (group) group.unreadCount = 0;
  }

  // Simulate other user typing for demo purposes
  if (type === 'friend' || type === 'group') {
    setTimeout(() => {
      isOtherUserTyping.value = true;
      setTimeout(() => {
        isOtherUserTyping.value = false;
      }, 3000);
    }, 2000);
  }

  nextTick(() => {
    scrollToBottom();
  });
};

const closeActiveChat = () => {
  activeChatId.value = null;
  activeChatType.value = null;
  showChatOptions.value = false;
};

const handleTyping = () => {
  isUserTyping.value = true;

  // Clear existing timeout
  if (typingTimeout.value) {
    clearTimeout(typingTimeout.value);
  }

  // Set new timeout to stop typing indicator after 2 seconds of inactivity
  typingTimeout.value = setTimeout(() => {
    isUserTyping.value = false;
  }, 2000);
};

// View group members
const viewGroupMembers = () => {
  if (activeChatType.value !== 'group') return;
  showGroupMembers.value = true;
  showChatOptions.value = false;
};

// Close group members view
const closeGroupMembers = () => {
  showGroupMembers.value = false;
};

// Add members to group
const addMembersToGroup = () => {
  showAddMemberModal.value = false;
  // In a real app, this would add the selected members to the group
  // and update the groupMembers array accordingly.
  // For this demo, we'll just close the modal.

  // Add selected members to the groupMembers array
  selectedMembers.value.forEach(memberId => {
    const friendToAdd = friends.value.find(friend => friend.id === memberId);
    if (friendToAdd) {
      groupMembers.value.push({
        ...friendToAdd,
        isAdmin: false // New members are not admins by default
      });
    }
  });

  // Clear selected members
  selectedMembers.value = [];
};

// Toggle select member
const toggleSelectMember = (memberId) => {
  if (selectedMembers.value.includes(memberId)) {
    deselectMember(memberId);
  } else {
    selectMember(memberId);
  }
};

// Select member
const selectMember = (memberId) => {
  if (!selectedMembers.value.includes(memberId)) {
    selectedMembers.value.push(memberId);
  }
};

// Deselect member
const deselectMember = (memberId) => {
  selectedMembers.value = selectedMembers.value.filter(id => id !== memberId);
};

// Is selected member
const isSelectedMember = (memberId) => {
  return selectedMembers.value.includes(memberId);
};

// Get friend by id
const getFriendById = (memberId) => {
  return friends.value.find(friend => friend.id === memberId);
};

// Rename group
const renameGroup = () => {
  if (activeChatType.value === 'group' && activeChat.value && newGroupName.value.trim()) {
    activeChat.value.name = newGroupName.value.trim();
    const groupIndex = groups.value.findIndex(g => g.id === activeChatId.value);
    if (groupIndex !== -1) {
      groups.value[groupIndex].name = newGroupName.value.trim();
    }
    showRenameGroupModal.value = false;
    newGroupName.value = '';
  }
};

// Leave group
const leaveGroup = () => {
  if (activeChatType.value === 'group' && activeChat.value) {
    // Remove user from groupMembers array
    groupMembers.value = groupMembers.value.filter(member => member.id !== userProfile.value.id);

    // Close active chat
    closeActiveChat();
    showChatOptions.value = false;
  }
};

// View member profile
const viewMemberProfile = (member) => {
  activeMember.value = member;
  showMemberProfile.value = true;
  activeMemberOptionsId.value = null;
};

// Remove member from group
const removeMemberFromGroup = (member) => {
  // Remove member from groupMembers array
  groupMembers.value = groupMembers.value.filter(m => m.id !== member.id);

  // If the removed member was the active member being viewed, close the profile
  if (activeMember.value && activeMember.value.id === member.id) {
    showMemberProfile.value = false;
    activeMember.value = null;
  }

  // Close the member options dropdown
  activeMemberOptionsId.value = null;
};

// Open chat with member
const openChatWithMember = (member) => {
  openChat(member.id, 'friend');
};

// Toggle member options
const toggleMemberOptions = (memberId) => {
  activeMemberOptionsId.value = activeMemberOptionsId.value === memberId ? null : memberId;
};

// Toggle mention list
const toggleMentionList = () => {
  showMentionList.value = !showMentionList.value;
  showEmojiPicker.value = false;
  showMediaPicker.value = false;
  mentionSearch.value = ''; // Reset search when opening mention list
};

// Toggle emoji picker
const toggleEmojiPicker = () => {
  showEmojiPicker.value = !showEmojiPicker.value;
  showMentionList.value = false;
  showMediaPicker.value = false;
};

// Toggle chat options
const toggleChatOptions = () => {
  showChatOptions.value = !showChatOptions.value;
};

// Add emoji to message
const addEmoji = (emoji) => {
  newMessage.value += emoji;
  showEmojiPicker.value = false;
};

// Mention a user
const mentionUser = (user) => {
  newMessage.value += `@${user.name} `;
  showMentionList.value = false;
  mentionSearch.value = ''; // Clear search after mentioning
};

// Format message with mentions
const formatMessageWithMentions = (text) => {
  if (!text) return '';

  // Replace @mentions with styled spans
  return text.replace(/@([a-zA-Z\s]+)/g, '<span class="font-medium text-green-600">@$1</span>');
};

// Select media
const selectMedia = (url, type) => {
  selectedMedia.value = url;
  selectedMediaType.value = type;
  showMediaPicker.value = false;
};

// Clear selected media
const clearSelectedMedia = () => {
  selectedMedia.value = null;
  selectedMediaType.value = null;
};

// Handle image selection from device
const handleImageSelect = (event) => {
  const file = event.target.files[0];
  if (file) {
    const reader = new FileReader();
    reader.onload = (e) => {
      selectMedia(e.target.result, 'image');
    };
    reader.readAsDataURL(file);
  }
  showMediaPicker.value = false;
};

// Handle media upload
const handleMediaUpload = (event) => {
  const files = Array.from(event.target.files);

  files.forEach(file => {
    const reader = new FileReader();
    reader.onload = (e) => {
      uploadedMedia.value.push({
        url: e.target.result,
        type: file.type
      });
    };
    reader.readAsDataURL(file);
  });

  showMediaPicker.value = false;
};

// Remove uploaded media
const removeUploadedMedia = (index) => {
  uploadedMedia.value.splice(index, 1);
};

// Handle file selection
const handleFileSelect = (event) => {
  const file = event.target.files[0];
  if (file) {
    selectedFile.value = file;
    selectedFileName.value = file.name;
  }
};

// Clear selected file
const clearSelectedFile = () => {
  selectedFile.value = null;
  selectedFileName.value = '';
};

// Start voice recording
const startVoiceRecording = () => {
  isRecording.value = true;
  recordingDuration.value = 0;
  
  // Start recording timer
  recordingInterval.value = setInterval(() => {
    recordingDuration.value++;
  }, 1000);
  
  // In a real app, this would start actual voice recording
};

// Stop voice recording
const stopVoiceRecording = () => {
  if (isRecording.value) {
    isRecording.value = false;
    clearInterval(recordingInterval.value);
    
    // Only save if recording lasted more than 1 second
    if (recordingDuration.value > 0) {
      recordedVoice.value = true;
    }
    
    // In a real app, this would stop and save the recording
  }
};

// Clear recorded voice
const clearRecordedVoice = () => {
  recordedVoice.value = false;
  recordingDuration.value = 0;
};

// Block/unblock user
const toggleBlockUser = () => {
  if (activeChatType.value === 'friend' && activeChat.value) {
    const friendIndex = friends.value.findIndex(f => f.id === activeChatId.value);
    if (friendIndex !== -1) {
      friends.value[friendIndex].isBlocked = !friends.value[friendIndex].isBlocked;
      showChatOptions.value = false;
    }
  }
};

// Delete chat
const deleteChat = () => {
  showDeleteConfirmation.value = true;
  showChatOptions.value = false;
};

// Confirm delete chat
const confirmDeleteChat = () => {
  if (activeChatType.value === 'friend') {
    const friendIndex = friends.value.findIndex(f => f.id === activeChatId.value);
    if (friendIndex !== -1) {
      friends.value[friendIndex].messages = [];
      friends.value[friendIndex].lastMessage = '';
      friends.value[friendIndex].lastTime = 'No messages';
    }
  } else if (activeChatType.value === 'group') {
    const groupIndex = groups.value.findIndex(g => g.id === activeChatId.value);
    if (groupIndex !== -1) {
      groups.value[groupIndex].messages = [];
      groups.value[groupIndex].lastMessage = '';
      groups.value[groupIndex].lastTime = 'No messages';
    }
  }
  
  showDeleteConfirmation.value = false;
  closeActiveChat();
};

const sendMessage = () => {
  if ((!newMessage.value.trim() && !selectedMedia.value && !recordedVoice.value && !selectedFile.value && uploadedMedia.length === 0) || !activeChat.value) return;

  const now = new Date();
  const timeString = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  // Create message object
  const messageObj = {
    text: newMessage.value,
    isUser: true,
    time: timeString,
    read: false,
    media: null // Initialize media to null
  };

  // Add media if selected
  if (selectedMedia.value) {
    messageObj.media = {
      type: selectedMediaType.value,
      url: selectedMedia.value
    };
  }

  // Add voice recording if available
  if (recordedVoice.value) {
    messageObj.media = {
      type: 'voice',
      duration: recordingDuration.value,
      currentTime: 0,
      isPlaying: false,
      progress: 0
    };
  }

  // Add file if selected
  if (selectedFile.value) {
    messageObj.media = {
      type: 'file',
      name: selectedFileName.value
    };
  }

  // Add uploaded media
  uploadedMedia.value.forEach(media => {
    const mediaMessage = {
      text: '',
      isUser: true,
      time: timeString,
      read: false,
      media: {
        type: media.type,
        url: media.url
      }
    };
    activeChat.value.messages.push(mediaMessage);
  });

  // Add message to chat
  if (newMessage.value.trim() || messageObj.media) {
    activeChat.value.messages.push(messageObj);
  }

  // Update last message
  if (activeChatType.value === 'friend') {
    const friendIndex = friends.value.findIndex(f => f.id === activeChatId.value);
    if (friendIndex !== -1) {
      friends.value[friendIndex].lastMessage = newMessage.value || (messageObj.media ? 
        messageObj.media.type === 'image' ? 'Sent an image' : 
        messageObj.media.type === 'voice' ? 'Sent a voice message' : 
        'Sent a file' : '');
      friends.value[friendIndex].lastTime = timeString;
    }
  } else if (activeChatType.value === 'group') {
    const groupIndex = groups.value.findIndex(g => g.id === activeChatId.value);
    if (groupIndex !== -1) {
      groups.value[groupIndex].lastMessage = newMessage.value || (messageObj.media ? 
        messageObj.media.type === 'image' ? 'Sent an image' : 
        messageObj.media.type === 'voice' ? 'Sent a voice message' : 
        'Sent a file' : '');
      groups.value[groupIndex].lastMessageSender = userProfile.value.name.split(' ')[0];
      groups.value[groupIndex].lastTime = timeString;
    }
  }

  // Clear inputs
  newMessage.value = '';
  clearSelectedMedia();
  clearRecordedVoice();
  clearSelectedFile();
  uploadedMedia.value = [];

  // Scroll to bottom
  nextTick(() => {
    scrollToBottom();
  });

  // Simulate typing indicator
  setTimeout(() => {
    isOtherUserTyping.value = true;
    
    // Simulate response after typing
    setTimeout(() => {
      isOtherUserTyping.value = false;
      
      let response;
      if (activeChatType.value === 'ai') {
        const aiResponses = [
          "I can help you with that! What specific information do you need about AdsyConnect?",
          "That's a great question about AdsyConnect. Let me provide some details.",
          "I'm here to assist with all your AdsyConnect needs. Could you provide more details?",
          "As your AdsyAI assistant, I'd be happy to help with that request.",
          "I'm processing your request about AdsyConnect. Is there anything specific you'd like to know?"
        ];
        response = aiResponses[Math.floor(Math.random() * aiResponses.length)];
      } else {
        const responses = [
          "Thanks for your message!",
          "I'll get back to you on this soon.",
          "Let me check and get back to you.",
          "Sounds good!",
          "Great idea!",
          "I'll share this with the team."
        ];
        response = responses[Math.floor(Math.random() * responses.length)];
      }
      
      // Add response message
      activeChat.value.messages.push({
        text: response,
        isUser: false,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        sender: activeChatType.value === 'group' 
          ? friends.value[Math.floor(Math.random() * friends.value.length)].name.split(' ')[0]
          : activeChat.value.name,
        read: true
      });
      
      // Update last message for the chat
      if (activeChatType.value === 'friend') {
        const friendIndex = friends.value.findIndex(f => f.id === activeChatId.value);
        if (friendIndex !== -1) {
          friends.value[friendIndex].lastMessage = response;
          friends.value[friendIndex].lastTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          friends.value[friendIndex].isTyping = false;
        }
      } else if (activeChatType.value === 'group') {
        const groupIndex = groups.value.findIndex(g => g.id === activeChatId.value);
        if (groupIndex !== -1) {
          groups.value[groupIndex].lastMessage = response;
          groups.value[groupIndex].lastMessageSender = activeChat.value.messages[activeChat.value.messages.length - 1].sender;
          groups.value[groupIndex].lastTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          groups.value[groupIndex].isTyping = false;
          groups.value[groupIndex].typingUser = '';
        }
      }
      
      // Mark user message as read
      const lastUserMessageIndex = activeChat.value.messages.findIndex(m => m.isUser && !m.read);
      if (lastUserMessageIndex !== -1) {
        activeChat.value.messages[lastUserMessageIndex].read = true;
      }
      
      nextTick(() => {
        scrollToBottom();
      });
    }, 2000);
  }, 1000);
};

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
};

// Handle scroll for infinite loading
const handleScroll = () => {
  if (!chatListContainer.value || !hasMoreFriends.value) return;
  
  const { scrollTop, scrollHeight, clientHeight } = chatListContainer.value;
  
  // If scrolled to bottom (with a small threshold)
  if (scrollHeight - scrollTop - clientHeight < 50) {
    loadMoreFriends();
  }
};

// Load more friends
const loadMoreFriends = () => {
  if (isLoadingMore.value || !hasMoreFriends.value) return;
  
  isLoadingMore.value = true;
  
  // Simulate loading delay
  setTimeout(() => {
    currentPage.value++;
    isLoadingMore.value = false;
  }, 800);
};

// Clean up expired stories
const cleanupExpiredStories = () => {
  const now = new Date();
  stories.value = stories.value.filter(story => story.expiresAt > now);
};

// Handle input for @ mentions
const handleInput = () => {
  handleTyping(); // Still trigger typing indicator

  const lastWord = newMessage.value.split(' ').pop();
  if (lastWord && lastWord.startsWith('@')) {
    showMentionList.value = true;
    mentionSearch.value = lastWord.substring(1).toLowerCase(); // Search term
  } else {
    showMentionList.value = false;
    mentionSearch.value = '';
  }
};

// Handle keydown to prevent space after @mention
const handleKeyDown = (event) => {
  if (event.key === ' ' && showMentionList.value) {
    event.preventDefault(); // Prevent adding space
  }
};

// Format voice duration
const formatVoiceDuration = (duration) => {
  const minutes = Math.floor(duration / 60);
  const seconds = Math.floor(duration % 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

// Play voice message
const playVoiceMessage = (message) => {
  if (!message.media) return;

  // Stop any other playing messages
  activeChat.value.messages.forEach(msg => {
    if (msg.media && msg.media.type === 'voice' && msg.media.isPlaying && msg !== message) {
      msg.media.isPlaying = false;
    }
  });

  // Toggle play/pause
  message.media.isPlaying = !message.media.isPlaying;

  // Simulate progress update
  if (message.media.isPlaying) {
    let progress = 0;
    const interval = setInterval(() => {
      progress += 1;
      message.media.progress = progress;
      message.media.currentTime = (message.media.duration * progress) / 100;

      if (progress >= 100 || !message.media.isPlaying) {
        clearInterval(interval);
        message.media.isPlaying = false;
        message.media.progress = 0;
        message.media.currentTime = 0;
      }
    }, message.media.duration / 100 * 10); // Simulate real-time progress
  }
};

// View full media
const viewFullMedia = (media) => {
  fullMediaItem.value = media;
  showFullMedia.value = true;
};

// Selected members
const selectedMembers = ref([]);

// Watch for changes in active chat
watch(activeChatId, () => {
  nextTick(() => {
    scrollToBottom();
  });
});

// Watch for search query changes
watch(searchQuery, () => {
  currentPage.value = 1; // Reset pagination when search changes
});

// Lifecycle hooks
onMounted(() => {
  checkMobile();
  window.addEventListener('resize', checkMobile);

  // Set up interval to check for expired stories
  const storyInterval = setInterval(cleanupExpiredStories, 60000); // Check every minute

  // Click outside to close dropdowns
  const handleClickOutside = (event) => {
    if (showStoryOptions.value && !event.target.closest('.story-options')) {
      showStoryOptions.value = false;
    }
    if (showChatOptions.value && !event.target.closest('.chat-options')) {
      showChatOptions.value = false;
    }
    if (activeMemberOptionsId.value && !event.target.closest('.member-options')) {
      activeMemberOptionsId.value = null;
    }
  };

  document.addEventListener('click', handleClickOutside);

  // Cleanup
  onUnmounted(() => {
    window.removeEventListener('resize', checkMobile);
    document.removeEventListener('click', handleClickOutside);
    clearInterval(storyInterval);
    
    if (typingTimeout.value) {
      clearTimeout(typingTimeout.value);
    }
    
    if (recordingInterval.value) {
      clearInterval(recordingInterval.value);
    }
    
    // Close story interval if active
    if (storyInterval.value) {
      clearInterval(storyInterval.value);
    }
  });
});
</script>

<style>
:root {
  --color-primary: #10b981;
  --color-primary-foreground: white;
}

.bg-primary {
  background-color: var(--color-primary);
}

.text-primary {
  color: var(--color-primary);
}

.border-primary {
  border-color: var(--color-primary);
}

.ring-primary {
  --tw-ring-color: var(--color-primary);
}

.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Hide scrollbar but keep functionality */
.scrollbar-hide {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;  /* Chrome, Safari and Opera */
}

/* Typing animation */
.typing-animation {
  display: inline-flex;
  align-items: center;
}

.typing-animation .dot {
  display: inline-block;
  width: 3px;
  height: 3px;
  border-radius: 50%;
  margin: 0 1px;
  background-color: currentColor;
  animation: typing 1.4s infinite ease-in-out both;
}

.typing-animation .dot:nth-child(1) {
  animation-delay: -0.32s;
}

.typing-animation .dot:nth-child(2) {
  animation-delay: -0.16s;
}

@keyframes typing {
  0%, 80%, 100% { 
    transform: scale(0.6);
    opacity: 0.6;
  }
  40% { 
    transform: scale(1);
    opacity: 1;
  }
}

/* Fade in animation */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(5px); }
  to { opacity: 1; transform: translateY(0); }
}

.animate-fadeIn {
  animation: fadeIn 0.3s ease-out;
}
</style>