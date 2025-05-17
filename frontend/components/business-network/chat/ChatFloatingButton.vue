<template>
  <div class="bottom-50">
    <!-- Floating messenger button (hidden on mobile when chat is open) -->
    <button
      v-if="!(isMobile && isChatOpen)"
      @click="toggleChat"
      class="fixed bottom-20 right-6 z-50 flex size-14 items-center justify-center rounded-full bg-gradient-to-br from-green-500 to-green-600 shadow-sm transition-all duration-300 hover:scale-105 hover:shadow-green-200/50 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
      :class="{ 'rotate-90 transform': isChatOpen }"
      aria-label="Open chat"
    >
      <MessageCircleIcon v-if="!isChatOpen" class="h-5 w-5 text-white" />
      <XIcon v-else class="h-5 w-5 text-white" />
      
      <!-- Notification badge -->
      <div v-if="unreadCount > 0 && !isChatOpen" class="absolute -right-1 -top-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[9px] font-semibold text-white">
        {{ unreadCount }}
      </div>
    </button>
  
    <!-- Chat window - ensure it doesn't capture clicks when closed -->
    <div
      v-show="isChatOpen"
      class="fixed z-50 overflow-hidden rounded-sm sm:rounded-xl bg-white shadow-sm transition-all duration-300 pointer-events-auto"
      :class="[
        isMobile 
          ? 'bottom-0 left-0 right-0 top-0' 
          : 'bottom-24 right-6 h-[650px] w-[380px]'
      ]"
    >
      <!-- User profile section -->
      <div class="relative flex items-center justify-between border-b bg-gradient-to-r from-green-500 to-green-600 p-3 text-white">
        <div class="absolute inset-0 opacity-5 blur-xl" :style="activeChatId ? `background-image: url('${activeChat.avatar}')` : `background-image: url('${userProfile.avatar}')`"></div>
        <div class="relative flex items-center">
          <div class="relative h-9 w-9 overflow-hidden rounded-full ring-2 ring-white/30">
            <img 
              :src="activeChatId ? activeChat.avatar : userProfile.avatar" 
              :alt="activeChatId ? activeChat.name : 'Your profile'" 
              class="h-full w-full object-cover transition-all duration-300 hover:scale-110"
            />
            <div 
              class="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full border-2 border-green-600"
              :class="activeChatId ? (activeChat.isOnline ? 'bg-green-300' : 'bg-gray-400') : (userProfile.isOnline ? 'bg-green-300' : 'bg-gray-400')"
            ></div>
            <div 
              v-if="activeChatId && activeChatType === 'ai'"
              class="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full border-2 border-white bg-gradient-to-br from-purple-500 to-pink-500"
            ></div>
          </div>
          <div class="ml-2">
            <h3 class="text-md font-medium">{{ activeChatId ? activeChat.name : userProfile.name }}</h3>
            <div class="flex items-center text-sm">
              <span v-if="!activeChatId">{{ userProfile.isOnline ? 'Online' : 'Offline' }}</span>
              <span v-else-if="activeChatType === 'friend'">{{ activeChat.isOnline ? 'Online' : 'Offline' }}</span>
              <span v-else>AI Assistant</span>
            </div>
          </div>
        </div>
        <div class="flex items-center">
          <!-- Settings gear icon -->
          <button
            v-if="!activeChatId"
            @click="openSettings"
            class="relative mr-2 rounded-full p-1.5 text-white/80 transition-colors hover:bg-white/10 hover:text-white"
            aria-label="Settings"
          >
            <SettingsIcon class="h-4.5 w-4.5" />
          </button>
          
          <!-- Three dots menu for friend chats -->
          <div v-if="activeChatId && activeChatType === 'friend'" class="relative chat-options">
            <button
              @click="toggleChatOptions"
              class="relative mr-2 rounded-full p-1.5 text-white/80 transition-colors hover:bg-white/10 hover:text-white"
              aria-label="Chat options"
            >
              <MoreVerticalIcon class="h-4.5 w-4.5" />
            </button>
            
            <!-- Dropdown menu -->
            <div 
              v-if="showChatOptions" 
              class="absolute right-0 top-full mt-1 w-40 rounded-md bg-white py-1 shadow-sm"
            >
              <button 
                @click="toggleBlockUser" 
                class="flex w-full items-center px-3 py-2 text-left text-sm text-gray-700 hover:bg-gray-100"
              >
                <BanIcon class="mr-2 h-3.5 w-3.5" :class="activeChat.isBlocked ? 'text-green-500' : 'text-red-500'" />
                {{ activeChat.isBlocked ? 'Unblock user' : 'Block user' }}
              </button>
              <button 
                @click="deleteChat" 
                class="flex w-full items-center px-3 py-2 text-left text-sm text-gray-700 hover:bg-gray-100"
              >
                <TrashIcon class="mr-2 h-3.5 w-3.5 text-red-500" />
                Delete chat
              </button>
              <button 
                @click="reportSpam" 
                class="flex w-full items-center px-3 py-2 text-left text-sm text-gray-700 hover:bg-gray-100"
              >
                <ShieldIcon class="mr-2 h-3.5 w-3.5 text-orange-500" />
                Report as spam
              </button>
            </div>
          </div>
          
          <!-- Back button when in chat -->
          <button
            v-if="activeChatId"
            @click="closeActiveChat"
            class="relative mr-2 rounded-full p-1.5 text-white/80 transition-colors hover:bg-white/10 hover:text-white"
            aria-label="Back"
          >
            <ArrowLeftIcon class="h-4.5 w-4.5" />
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
            <h4 class="text-md font-medium text-gray-800">Settings</h4>
          </div>
        </div>
        
        <div class="flex-1 p-4">
          <p class="text-center text-md text-gray-500">Settings page will be designed later</p>
        </div>
      </div>
  
      <!-- Main content area -->
      <div v-else-if="!activeChatId && !showStoryView && !showAllStories" class="flex h-[calc(100%-64px)] flex-col">
        <!-- Search bar -->
        <div class="p-2">
          <div class="flex items-center rounded-md bg-gray-50 px-2 py-1.5 transition-all focus-within:ring-1 focus-within:ring-green-300">
            <SearchIcon class="h-3.5 w-3.5 text-gray-500" />
            <input 
              v-model="searchQuery"
              type="text" 
              placeholder="Search friends..." 
              class="ml-2 w-full bg-transparent text-sm focus:outline-none"
            />
          </div>
        </div>
  
        <!-- Scrollable content area -->
        <div 
          ref="chatListContainer" 
          class="flex-1 overflow-y-auto scrollbar-hide"
          @scroll="handleScroll"
        >
          <!-- Stories section -->
        <div class="p-2">
          <div class="flex items-center justify-between pb-2">
            <h4 class="text-sm font-medium text-gray-600">Stories</h4>
            <button @click="openAllStories" class="text-sm text-green-600">View all</button>
          </div>
          <div 
            class="flex space-x-4 overflow-x-auto  pb-1 pt-1 scrollbar-hide"
            @scroll="handleStoriesScroll"
          >
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
              <span class="mt-1 text-sm min-w-max">Add story</span>
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
                
              </div>
              <span class="mt-1 text-md line-clamp-1">{{ story.name }}</span>
            </div>
            
            <!-- Loading indicator for stories -->
            <div v-if="isLoadingMoreStories" class="flex flex-col items-center justify-center">
              <div class="relative h-14 w-14 flex-shrink-0 rounded-full bg-gray-100">
                <div class="absolute inset-0 flex items-center justify-center">
                  <div class="typing-animation">
                    <span class="dot bg-green-500"></span>
                    <span class="dot bg-green-500"></span>
                    <span class="dot bg-green-500"></span>
                  </div>
                </div>
              </div>
              <span class="mt-1 text-sm">Loading...</span>
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
                  <h4 class="text-sm font-medium text-purple-800">AdsyAI Assistant</h4>
                  <span class="rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-1.5 py-0.5 text-[9px] text-white">
                    AI
                  </span>
                </div>
                <p class="text-sm text-purple-600">Ask me anything about AdsyConnect</p>
              </div>
            </button>
          </div>
  
          <!-- Friends List -->
          <div class="px-2 py-1">
            <h4 class="mb-2 text-sm font-medium text-gray-600">Friends</h4>
            
            <div v-if="filteredFriends.length === 0" class="flex items-center justify-center py-4 text-sm text-gray-500">
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
                    <h4 class="flex items-center text-md font-medium text-gray-700">
                      {{ friend.name }}
                      <span v-if="friend.isBlocked" class="ml-1 rounded-sm bg-red-100 px-1 py-0.5 text-[8px] text-red-600">
                        BLOCKED
                      </span>
                    </h4>
                    <span class="text-sm text-gray-500">{{ friend.lastTime }}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <p v-if="friend.isTyping" class="text-sm text-green-500">
                        <span class="typing-animation">
                          <span class="dot"></span>
                          <span class="dot"></span>
                          <span class="dot"></span>
                        </span>
                      </p>
                      <p v-else class="text-sm text-gray-500 line-clamp-1">{{ friend.lastMessage }}</p>
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
            <h4 class="text-md font-medium text-gray-800">All Stories</h4>
          </div>
          <button 
            @click="showAddStoryModal = true"
            class="rounded-full bg-green-500 p-1 text-white transition-colors hover:bg-green-600"
          >
            <PlusIcon class="h-4 w-4" />
          </button>
        </div>
        
        <div class="flex-1 overflow-y-auto p-4" @scroll="handleAllStoriesScroll">
          <div class="grid grid-cols-3 gap-3">
            <!-- Add story button -->
            <div class="flex flex-col items-center">
              <div 
                class="relative h-24 w-full flex-shrink-0 cursor-pointer rounded-lg bg-gray-100 transition-transform hover:scale-105"
                @click="showAddStoryModal = true"
              >
                <div class="absolute inset-0 flex items-center justify-center">
                  <PlusIcon class="h-8 w-8 text-green-500" />
                </div>
                <div class="absolute bottom-2 right-2 flex h-6 w-6 items-center justify-center rounded-full bg-green-500 text-white">
                  <CameraIcon class="h-3.5 w-3.5" />
                </div>
              </div>
              <span class="mt-1 text-sm">Add story</span>
            </div>
            
            <!-- User stories -->
            <div 
              v-for="(story, index) in stories" 
              :key="index"
              class="flex flex-col items-center"
            >
              <div 
                class="relative h-24 w-full flex-shrink-0 cursor-pointer overflow-hidden rounded-lg transition-transform hover:scale-105"
                @click="viewStory(story)"
              >
                <img 
                  :src="story.content" 
                  :alt="story.name" 
                  class="h-full w-full object-cover"
                />
                <div class="absolute inset-0 bg-gradient-to-b from-black/30 to-transparent"></div>
                <div class="absolute left-2 top-2 flex items-center">
                  <div class="relative h-6 w-6 overflow-hidden rounded-full ring-2 ring-white">
                    <img 
                      :src="story.avatar" 
                      :alt="story.name" 
                      class="h-full w-full object-cover"
                    />
                  </div>
                  <span class="ml-1 text-sm font-medium text-white">{{ story.name }}</span>
                </div>
                
              </div>
              <span class="mt-1 text-sm">{{ story.time }}</span>
            </div>
          </div>
          
          <!-- Loading indicator for all stories -->
          <div v-if="isLoadingMoreStories" class="flex justify-center py-4">
            <div class="typing-animation">
              <span class="dot bg-green-500"></span>
              <span class="dot bg-green-500"></span>
              <span class="dot bg-green-500"></span>
            </div>
          </div>
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
              <h4 class="text-sm font-medium">{{ activeStory.name }}</h4>
              <p class="text-sm text-white/70">{{ activeStory.time }}</p>
            </div>
          </div>
          <div class="flex">
            <button class="rounded-full p-1 text-white/80 transition-colors hover:bg-white/10">
              <MoreVerticalIcon class="h-4 w-4" />
            </button>
          </div>
        </div>
        
        <!-- Story content with touch navigation -->
        <div class="relative flex-1">
          <!-- Left navigation area (previous) -->
          <div 
            class="absolute bottom-0 left-0 top-0 z-10 w-1/4 cursor-pointer" 
            @click="prevStoryPart"
          ></div>
          
          <!-- Center area (pause/play) -->
          <div 
            class="absolute bottom-0 left-1/4 right-1/4 top-0 z-10 cursor-pointer" 
            @click="toggleStoryPause"
          ></div>
          
          <!-- Right navigation area (next) -->
          <div 
            class="absolute bottom-0 right-0 top-0 z-10 w-1/4 cursor-pointer" 
            @click="nextStoryPart"
          ></div>
          
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
                <span class="text-sm">{{ activeStory.likes }}</span>
              </button>
            </div>
            
            <button 
              @click="showStoryViewers = !showStoryViewers"
              class="flex items-center rounded-full bg-white/10 px-3 py-1.5 text-white transition-all hover:bg-white/20"
            >
              <EyeIcon class="mr-1 h-4 w-4" />
              <span class="text-sm">{{ activeStory.viewers.length }}</span>
            </button>
          </div>
          
          <!-- Story viewers list -->
          <div 
            v-if="showStoryViewers" 
            class="absolute bottom-16 right-4 w-48 rounded-lg bg-white py-1 shadow-sm"
          >
            <div class="px-3 py-2">
              <p class="mb-1 text-sm font-medium text-gray-500">Viewers</p>
              <div v-for="(viewer, index) in activeStory.viewers" :key="index" class="flex items-center py-1">
                <img :src="viewer.avatar" :alt="viewer.name" class="h-6 w-6 rounded-full object-cover" />
                <span class="ml-2 text-sm text-gray-700">{{ viewer.name }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
  
      <!-- Active chat area -->
      <div v-else-if="activeChatId" class="flex h-[calc(100%-64px)] flex-col">
        <!-- Chat messages -->
        <div 
          ref="messagesContainer"
          class="flex-1 overflow-y-auto bg-gradient-to-b from-gray-50 to-white p-3 scrollbar-hide"
        >
          <!-- Blocked user message -->
          <div v-if="activeChatType === 'friend' && activeChat.isBlocked" class="flex flex-col items-center justify-center p-4 text-center">
            <div class="mb-3 flex h-16 w-16 items-center justify-center rounded-full bg-red-50">
              <BanIcon class="h-8 w-8 text-red-400" />
            </div>
            <p class="mb-2 text-md font-medium text-gray-700">You've blocked this user</p>
            <p class="mb-4 text-sm text-gray-500">You won't receive messages from this user</p>
            <button 
              @click="toggleBlockUser" 
              class="rounded-full bg-green-500 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-green-600"
            >
              Unblock to continue chat
            </button>
          </div>
          
          <div v-else-if="activeChat.messages.length === 0" class="flex h-full flex-col items-center justify-center text-center text-gray-500">
            <div class="flex h-16 w-16 items-center justify-center rounded-full bg-green-50">
              <MessageSquareIcon class="h-8 w-8 text-green-300" />
            </div>
            <p class="mb-1 mt-3 text-sm font-medium text-gray-600">No messages yet</p>
            <p class="text-sm text-gray-500">Start a conversation with {{ activeChat.name }}</p>
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
                <img
                  v-if="message.isUser" 
                  :src="userProfile.avatar" 
                  :alt="userProfile.name" 
                  class="ml-1.5 h-5 w-5 rounded-full object-cover"
                />
              </div>
              
              <div 
                class="max-w-[80%] rounded-lg px-3 py-2 shadow-sm transition-all hover:shadow-sm"
                :class="[
                  message.isUser 
                    ? 'ml-auto bg-gradient-to-r from-green-500 to-green-600 text-white' 
                    : activeChatType === 'ai'
                      ? 'bg-gradient-to-r from-purple-50 to-pink-50 text-gray-800'
                      : 'bg-white text-gray-800'
                ]"
              >
                <p v-if="message.text" class="text-md">{{ message.text }}</p>
                
                <!-- Media preview if message has media -->
                <div v-if="message.media" class="mt-2">
                  <img 
                    v-if="message.media.type === 'image' || message.media.type.includes('image')" 
                    :src="message.media.url" 
                    alt="Image" 
                    class="max-h-40 w-full rounded-md object-cover"
                    @click="viewFullMedia(message.media)"
                  />
                  <video 
                    v-else-if="message.media.type === 'video' || message.media.type.includes('video')" 
                    :src="message.media.url" 
                    class="max-h-40 w-full rounded-md object-cover" 
                    controls
                  ></video>
                  <div v-else-if="message.media.type === 'file'" class="flex items-center">
                    <FileIcon class="h-4 w-4" :class="message.isUser ? 'text-white' : 'text-gray-500'" />
                    <span class="ml-2 text-sm">{{ message.media.name }}</span>
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
                class="mt-0.5 flex items-center text-[9px] text-gray-500"
                :class="{ 'justify-end': message.isUser }"
              >
                <span>{{ message.time }}</span>
                <span v-if="message.isUser && message.read" class="ml-1 text-green-500">
                  <CheckCheckIcon class="h-3 w-3" />
                </span>
                <span v-else-if="message.isUser" class="ml-1 text-gray-500">
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
        <div class="border-t bg-white p-2" :class="{ 'opacity-50': activeChatType === 'friend' && activeChat.isBlocked }">
          <!-- Media and attachment options -->
          <div class="mb-1.5 flex items-center justify-between px-1">
            <div class="flex space-x-3">
              <button 
                @click="showMediaPicker = !showMediaPicker" 
                class="flex items-center text-sm text-gray-500 transition-colors hover:text-green-500"
                :disabled="activeChatType === 'friend' && activeChat.isBlocked"
              >
                <ImageIcon class="mr-1 h-3.5 w-3.5" />
                <span>Media</span>
              </button>
              <button 
                @touchstart="startVoiceRecording" 
                @touchend="stopVoiceRecording"
                @mousedown="startVoiceRecording"
                @mouseup="stopVoiceRecording"
                @mouseleave="stopVoiceRecording"
                class="flex items-center text-sm text-gray-500 transition-colors hover:text-green-500"
                :disabled="activeChatType === 'friend' && activeChat.isBlocked"
              >
                <MicIcon class="mr-1 h-3.5 w-3.5" :class="isRecording ? 'text-red-500 animate-pulse' : ''" />
                <span>{{ isRecording ? 'Recording...' : 'Voice' }}</span>
              </button>
              <label class="flex items-center text-sm text-gray-500 transition-colors hover:text-green-500 cursor-pointer" :class="{ 'pointer-events-none': activeChatType === 'friend' && activeChat.isBlocked }">
                <PaperclipIcon class="mr-1 h-3.5 w-3.5" />
                <span>Files</span>
                <input type="file" class="hidden" @change="handleFileSelect" :disabled="activeChatType === 'friend' && activeChat.isBlocked" />
              </label>
            </div>
            <div class="flex items-center">
              <button 
                @click="toggleEmojiPicker" 
                class="text-sm text-gray-500 transition-colors hover:text-green-500"
                :disabled="activeChatType === 'friend' && activeChat.isBlocked"
              >
                <SmileIcon class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
          
          <!-- Media picker -->
          <div v-if="showMediaPicker" class="mb-2 rounded-md border bg-gray-50 p-3 shadow-sm">
            <div class="flex flex-col items-center justify-center">
              <p class="mb-2 text-sm text-gray-600">Upload media from your device</p>
              <div class="flex space-x-3">
                <label class="flex flex-col items-center justify-center rounded-md bg-gray-100 px-4 py-2 text-gray-500 cursor-pointer hover:bg-gray-200">
                  <ImageIcon class="h-5 w-5 mb-1" />
                  <span class="text-sm">Images</span>
                  <input type="file" accept="image/*" multiple class="hidden" @change="handleMediaUpload" />
                </label>
                <label class="flex flex-col items-center justify-center rounded-md bg-gray-100 px-4 py-2 text-gray-500 cursor-pointer hover:bg-gray-200">
                  <VideoIcon class="h-5 w-5 mb-1" />
                  <span class="text-sm">Videos</span>
                  <input type="file" accept="video/*" multiple class="hidden" @change="handleMediaUpload" />
                </label>
              </div>
            </div>
            <div v-if="uploadedMedia.length > 0" class="mt-3">
              <p class="mb-1 text-sm text-gray-600">Selected media ({{ uploadedMedia.length }})</p>
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
          
          <!-- Text input -->
          <div class="flex items-center rounded-full border bg-gray-50 px-3 mb-2 py-2 transition-all focus-within:border-green-300 focus-within:ring-1 focus-within:ring-green-200">
            <input
              v-model="newMessage"
              @keyup.enter="sendMessage"
              @input="handleTyping"
              type="text"
              :placeholder="activeChatType === 'friend' && activeChat.isBlocked ? 'Unblock to send messages' : `Message ${activeChat ? activeChat.name : ''}...`"
              class="flex-1 bg-transparent text-sm focus:outline-none"
              :disabled="activeChatType === 'friend' && activeChat.isBlocked"
            />
            <button
              @click="sendMessage"
              class="ml-2 flex h-6 w-6 items-center justify-center rounded-full bg-gradient-to-r from-green-500 to-green-600 text-white transition-all hover:shadow-sm disabled:opacity-50"
              :disabled="(activeChatType === 'friend' && activeChat.isBlocked) || (!newMessage.trim() && !selectedMedia && !recordedVoice && !selectedFile && uploadedMedia.length === 0)"
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
              <p class="text-sm font-medium text-gray-700">{{ selectedFileName }}</p>
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
        <div class="w-[90%] max-w-md rounded-lg bg-white p-4 shadow-sm">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-md font-medium">Create Story</h3>
            <button @click="showAddStoryModal = false" class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
              <XIcon class="h-4 w-4" />
            </button>
          </div>
          
          <div class="mb-4 flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 p-6">
            <ImageIcon class="mb-2 h-10 w-10 text-gray-500" />
            <p class="mb-1 text-sm text-gray-600">Upload a photo or video</p>
            <p class="text-sm text-gray-500">Your story will be visible for 24 hours</p>
            <label class="mt-3 rounded-full bg-green-500 px-4 py-1.5 text-sm text-white transition-colors hover:bg-green-600 cursor-pointer">
              Select from gallery
              <input type="file" accept="image/*,video/*" class="hidden" />
            </label>
          </div>
          
          <div class="flex justify-end">
            <button @click="showAddStoryModal = false" class="mr-2 rounded-md px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-100">
              Cancel
            </button>
            <button class="rounded-md bg-green-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-green-600">
              Create Story
            </button>
          </div>
        </div>
      </div>
      
      <!-- Delete chat confirmation modal -->
      <div v-if="showDeleteConfirmation" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="w-[90%] max-w-md rounded-lg bg-white p-4 shadow-sm">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-md font-medium">Delete Chat</h3>
            <button @click="showDeleteConfirmation = false" class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
              <XIcon class="h-4 w-4" />
            </button>
          </div>
          
          <p class="mb-4 text-sm text-gray-600">Are you sure you want to delete this chat? This action cannot be undone.</p>
          
          <div class="flex justify-end">
            <button @click="showDeleteConfirmation = false" class="mr-2 rounded-md px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-100">
              Cancel
            </button>
            <button @click="confirmDeleteChat" class="rounded-md bg-red-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-red-600">
              Delete
            </button>
          </div>
        </div>
      </div>
  
      <!-- Full media view modal -->
      <div v-if="showFullMedia" class="fixed inset-0 z-50 flex items-center justify-center bg-black/90">
        <button @click="showFullMedia = false" class="absolute right-4 top-4 rounded-full bg-black/50 p-2 text-white">
          <XIcon class="h-6 w-6" />
        </button>
        <img v-if="fullMediaItem && fullMediaItem.type === 'image'" :src="fullMediaItem.url" class="max-h-[80vh] max-w-[90vw] object-contain" />
        <video v-else-if="fullMediaItem && fullMediaItem.type === 'video'" :src="fullMediaItem.url" controls class="max-h-[80vh] max-w-[90vw]"></video>
      </div>
    </div>
  </div>
  </template>
  
  <script setup>
  import { ref, computed, onMounted, onUnmounted, nextTick, watch } from "vue"
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
  } from "lucide-vue-next"
  
  // User profile
  const userProfile = ref({
    id: "user1",
    name: "Alex Johnson",
    avatar: "https://i.pravatar.cc/150?img=11",
    isOnline: true,
  })
  
  // Toggle user online status
  const toggleStatus = () => {
    userProfile.value.isOnline = !userProfile.value.isOnline
  }
  
  // Set status explicitly
  const setStatus = (status) => {
    userProfile.value.isOnline = status
  }
  
  // Settings state
  const showSettings = ref(false)
  
  const openSettings = () => {
    showSettings.value = true
  }
  
  // Stories data
  const stories = ref([
    {
      id: "story1",
      name: "Sarah",
      avatar: "https://i.pravatar.cc/150?img=5",
      content: "https://i.pravatar.cc/800?img=5",
      time: "2 hours ago",
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours from now
      totalParts: 3,
      currentPart: 0,
      likes: 12,
      hasLiked: false,
      viewers: [
        { name: "Michael Chen", avatar: "https://i.pravatar.cc/150?img=3" },
        { name: "Emma Rodriguez", avatar: "https://i.pravatar.cc/150?img=9" },
        { name: "David Kim", avatar: "https://i.pravatar.cc/150?img=12" },
      ],
    },
    {
      id: "story2",
      name: "Michael",
      avatar: "https://i.pravatar.cc/150?img=3",
      content: "https://i.pravatar.cc/800?img=3",
      time: "45 minutes ago",
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      totalParts: 2,
      currentPart: 0,
      likes: 8,
      hasLiked: true,
      viewers: [
        { name: "Sarah Williams", avatar: "https://i.pravatar.cc/150?img=5" },
        { name: "Alex Johnson", avatar: "https://i.pravatar.cc/150?img=11" },
      ],
    },
    {
      id: "story3",
      name: "Emma",
      avatar: "https://i.pravatar.cc/150?img=9",
      content: "https://i.pravatar.cc/800?img=9",
      time: "3 hours ago",
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      totalParts: 4,
      currentPart: 0,
      likes: 15,
      hasLiked: false,
      viewers: [
        { name: "Michael Chen", avatar: "https://i.pravatar.cc/150?img=3" },
        { name: "Alex Johnson", avatar: "https://i.pravatar.cc/150?img=11" },
        { name: "Jessica Lee", avatar: "https://i.pravatar.cc/150?img=25" },
      ],
    },
    {
      id: "story4",
      name: "David",
      avatar: "https://i.pravatar.cc/150?img=12",
      content: "https://i.pravatar.cc/800?img=12",
      time: "1 hour ago",
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      totalParts: 1,
      currentPart: 0,
      likes: 5,
      hasLiked: false,
      viewers: [{ name: "Sarah Williams", avatar: "https://i.pravatar.cc/150?img=5" }],
    },
    {
      id: "story5",
      name: "Jessica",
      avatar: "https://i.pravatar.cc/150?img=25",
      content: "https://i.pravatar.cc/800?img=25",
      time: "20 minutes ago",
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      totalParts: 2,
      currentPart: 0,
      likes: 20,
      hasLiked: true,
      viewers: [
        { name: "Michael Chen", avatar: "https://i.pravatar.cc/150?img=3" },
        { name: "Emma Rodriguez", avatar: "https://i.pravatar.cc/150?img=9" },
        { name: "Alex Johnson", avatar: "https://i.pravatar.cc/150?img=11" },
        { name: "David Kim", avatar: "https://i.pravatar.cc/150?img=12" },
      ],
    },
  ])
  
  // Story view state
  const showStoryView = ref(false)
  const showAllStories = ref(false)
  const activeStory = ref(null)
  const storyProgress = ref(0)
  const storyInterval = ref(null)
  const showStoryViewers = ref(false)
  const showAddStoryModal = ref(false)
  const showStoryOptions = ref(false)
  const isLoadingMoreStories = ref(false)
  const hasMoreStories = ref(true)
  const isPaused = ref(false)
  
  // Toggle story options
  const toggleStoryOptions = () => {
    showStoryOptions.value = !showStoryOptions.value
  }
  
  // Open all stories page
  const openAllStories = () => {
    showAllStories.value = true
    showStoryOptions.value = false
  }
  
  // View story
  const viewStory = (story) => {
    activeStory.value = { ...story }
    showStoryView.value = true
    storyProgress.value = 0
    isPaused.value = false
  
    // Start story progress
    if (storyInterval.value) clearInterval(storyInterval.value)
    storyInterval.value = setInterval(() => {
      if (!isPaused.value) {
        storyProgress.value += 1
        if (storyProgress.value >= 100) {
          // Move to next part or close
          if (activeStory.value.currentPart < activeStory.value.totalParts - 1) {
            activeStory.value.currentPart++
            storyProgress.value = 0
          } else {
            closeStoryView()
          }
        }
      }
    }, 50) // Update every 50ms for smooth progress
  }
  
  // Close story view
  const closeStoryView = () => {
    showStoryView.value = false
    activeStory.value = null
    showStoryViewers.value = false
    if (storyInterval.value) {
      clearInterval(storyInterval.value)
      storyInterval.value = null
    }
  }
  
  // React to story
  const reactToStory = () => {
    if (!activeStory.value) return
  
    if (activeStory.value.hasLiked) {
      activeStory.value.likes--
      activeStory.value.hasLiked = false
    } else {
      activeStory.value.likes++
      activeStory.value.hasLiked = true
    }
  
    // Update the original story in the stories array
    const storyIndex = stories.value.findIndex((s) => s.id === activeStory.value.id)
    if (storyIndex !== -1) {
      stories.value[storyIndex].likes = activeStory.value.likes
      stories.value[storyIndex].hasLiked = activeStory.value.hasLiked
    }
  }
  
  // Navigate to next story part
  const nextStoryPart = () => {
    if (!activeStory.value) return
  
    if (activeStory.value.currentPart < activeStory.value.totalParts - 1) {
      activeStory.value.currentPart++
      storyProgress.value = 0
    } else {
      // Move to next story or close if this is the last one
      const currentIndex = stories.value.findIndex((s) => s.id === activeStory.value.id)
      if (currentIndex < stories.value.length - 1) {
        viewStory(stories.value[currentIndex + 1])
      } else {
        closeStoryView()
      }
    }
  }
  
  // Navigate to previous story part
  const prevStoryPart = () => {
    if (!activeStory.value) return
  
    if (activeStory.value.currentPart > 0) {
      activeStory.value.currentPart--
      storyProgress.value = 0
    } else {
      // Move to previous story or stay if this is the first one
      const currentIndex = stories.value.findIndex(s => s.id === activeStory.value.id)
      if (currentIndex > 0) {
        const prevStory = stories.value[currentIndex - 1]
        viewStory(prevStory)
        // Set to last part of previous story
        activeStory.value.currentPart = activeStory.value.totalParts - 1
      }
    }
  }
  
  // Toggle story pause/play
  const toggleStoryPause = () => {
    isPaused.value = !isPaused.value
  }
  
  // Handle stories scroll for infinite loading
  const handleStoriesScroll = (event) => {
    const container = event.target
  
    // Check if scrolled to the end (with a small threshold)
    if (container.scrollLeft + container.clientWidth >= container.scrollWidth - 50) {
      loadMoreStories()
    }
  }
  
  // Handle all stories scroll for infinite loading
  const handleAllStoriesScroll = (event) => {
    const container = event.target
  
    // Check if scrolled to the bottom (with a small threshold)
    if (container.scrollTop + container.clientHeight >= container.scrollHeight - 50) {
      loadMoreStories()
    }
  }
  
  // AdsyAI data
  const adsyAI = ref({
    id: "adsyai",
    name: "AdsyAI Assistant",
    avatar: "https://i.pravatar.cc/150?img=68",
    messages: [
      {
        text: "Hello! I'm AdsyAI, your personal assistant. How can I help you today?",
        isUser: false,
        time: "10:30 AM",
        sender: "AdsyAI",
      },
    ],
  })
  
  // Friends data
  const friends = ref([
    {
      id: "friend1",
      name: "Sarah Williams",
      avatar: "https://i.pravatar.cc/150?img=5",
      isOnline: true,
      isTyping: true,
      lastMessage: "Are we still meeting tomorrow?",
      lastTime: "10:33 AM",
      unreadCount: 2,
      isBlocked: false,
      messages: [
        {
          text: "Hey, how are you doing?",
          isUser: false,
          time: "10:30 AM",
          sender: "Sarah Williams",
          read: true,
        },
        {
          text: "I'm good, thanks! How about you?",
          isUser: true,
          time: "10:32 AM",
          read: true,
        },
        {
          text: "Great! Are we still meeting tomorrow?",
          isUser: false,
          time: "10:33 AM",
          sender: "Sarah Williams",
          read: true,
        },
      ],
    },
    {
      id: "friend2",
      name: "Michael Chen",
      avatar: "https://i.pravatar.cc/150?img=3",
      isOnline: false,
      isTyping: false,
      lastMessage: "Check out this new ad campaign",
      lastTime: "Yesterday",
      unreadCount: 0,
      isBlocked: false,
      messages: [
        {
          text: "Hey, I saw your latest post. Great work!",
          isUser: false,
          time: "Yesterday",
          sender: "Michael Chen",
          read: true,
        },
        {
          text: "Thanks! I spent a lot of time on it.",
          isUser: true,
          time: "Yesterday",
          read: true,
        },
        {
          text: "Check out this new ad campaign I'm working on.",
          isUser: false,
          time: "Yesterday",
          sender: "Michael Chen",
          read: true,
        },
      ],
    },
    {
      id: "friend3",
      name: "Emma Rodriguez",
      avatar: "https://i.pravatar.cc/150?img=9",
      isOnline: true,
      isTyping: false,
      lastMessage: "The client loved our presentation!",
      lastTime: "Monday",
      unreadCount: 0,
      isBlocked: false,
      messages: [
        {
          text: "Just got out of the meeting with the client.",
          isUser: false,
          time: "Monday",
          sender: "Emma Rodriguez",
          read: true,
        },
        {
          text: "How did it go?",
          isUser: true,
          time: "Monday",
          read: true,
        },
        {
          text: "The client loved our presentation!",
          isUser: false,
          time: "Monday",
          sender: "Emma Rodriguez",
          read: true,
        },
      ],
    },
  ])
  
  // Generate more friends for pagination demo
  for (let i = 4; i <= 20; i++) {
    friends.value.push({
      id: `friend${i}`,
      name: `Friend ${i}`,
      avatar: `https://i.pravatar.cc/150?img=${20 + i}`,
      isOnline: Math.random() > 0.5,
      isTyping: false,
      lastMessage: `This is message ${i}`,
      lastTime: "Last week",
      unreadCount: 0,
      isBlocked: i % 7 === 0, // Block some friends for demo
      messages: [],
    })
  }
  
  // UI state
  const isChatOpen = ref(false)
  const isMobile = ref(false)
  const activeChatId = ref(null)
  const activeChatType = ref(null)
  const newMessage = ref("")
  const messagesContainer = ref(null)
  const chatListContainer = ref(null)
  const isUserTyping = ref(false)
  const isOtherUserTyping = ref(false)
  const typingTimeout = ref(null)
  const searchQuery = ref("")
  const currentPage = ref(1)
  const itemsPerPage = ref(15)
  const isLoadingMore = ref(false)
  const showMediaPicker = ref(false)
  const showEmojiPicker = ref(false)
  const selectedMedia = ref(null)
  const selectedMediaType = ref(null)
  const isRecording = ref(false)
  const recordedVoice = ref(false)
  const recordingDuration = ref(0)
  const recordingInterval = ref(null)
  const selectedFile = ref(null)
  const selectedFileName = ref("")
  const showChatOptions = ref(false)
  const showDeleteConfirmation = ref(false)
  const showFullMedia = ref(false)
  const fullMediaItem = ref(null)
  const uploadedMedia = ref([])
  
  // Emojis for picker
  const emojis = ref(["😊", "😂", "❤️", "👍", "🎉", "🔥", "😎", "🙏", "😢", "😍", "🤔", "👏", "💪", "🌟", "💯", "🤣"])
  
  // Computed properties
  const activeChat = computed(() => {
    if (!activeChatId.value) return null
  
    if (activeChatType.value === "friend") {
      return friends.value.find((f) => f.id === activeChatId.value)
    } else if (activeChatType.value === "ai") {
      return adsyAI.value
    }
  
    return null
  })
  
  const unreadCount = computed(() => {
    return friends.value.reduce((total, friend) => total + (friend.unreadCount || 0), 0)
  })
  
  // Filtered friends based on search
  const filteredFriends = computed(() => {
    if (!searchQuery.value) return friends.value
    return friends.value.filter((friend) => friend.name.toLowerCase().includes(searchQuery.value.toLowerCase()))
  })
  
  // Displayed friends (paginated)
  const displayedFriends = computed(() => {
    const endIndex = currentPage.value * itemsPerPage.value
    return filteredFriends.value.slice(0, endIndex)
  })
  
  // Check if there are more friends to load
  const hasMoreFriends = computed(() => {
    return displayedFriends.value.length < filteredFriends.value.length
  })
  
  // Methods
  const checkMobile = () => {
    isMobile.value = window.innerWidth < 768
  }
  
  const toggleChat = () => {
    isChatOpen.value = !isChatOpen.value
  
    if (!isChatOpen.value) {
      // Close all modals and views
      showSettings.value = false
      closeStoryView()
      showAddStoryModal.value = false
      showAllStories.value = false
      showStoryOptions.value = false
      showChatOptions.value = false
      showDeleteConfirmation.value = false
      showFullMedia.value = false
    }
  }
  
  const openChat = (id, type) => {
    activeChatId.value = id
    activeChatType.value = type
  
    // Reset unread count
    if (type === "friend") {
      const friend = friends.value.find((f) => f.id === id)
      if (friend) friend.unreadCount = 0
    }
  
    // Simulate other user typing for demo purposes
    if (type === "friend") {
      setTimeout(() => {
        isOtherUserTyping.value = true
        setTimeout(() => {
          isOtherUserTyping.value = false
        }, 3000)
      }, 2000)
    }
  
    nextTick(() => {
      scrollToBottom()
    })
  }
  
  const closeActiveChat = () => {
    activeChatId.value = null
    activeChatType.value = null
    showChatOptions.value = false
  }
  
  const handleTyping = () => {
    isUserTyping.value = true
  
    // Clear existing timeout
    if (typingTimeout.value) {
      clearTimeout(typingTimeout.value)
    }
  
    // Set new timeout to stop typing indicator after 2 seconds of inactivity
    typingTimeout.value = setTimeout(() => {
      isUserTyping.value = false
    }, 2000)
  }
  
  // Toggle emoji picker
  const toggleEmojiPicker = () => {
    showEmojiPicker.value = !showEmojiPicker.value
    showMediaPicker.value = false
  }
  
  // Toggle chat options
  const toggleChatOptions = () => {
    showChatOptions.value = !showChatOptions.value
  }
  
  // Add emoji to message
  const addEmoji = (emoji) => {
    newMessage.value += emoji
    showEmojiPicker.value = false
  }
  
  // Select media
  const selectMedia = (url, type) => {
    selectedMedia.value = url
    selectedMediaType.value = type
    showMediaPicker.value = false
  }
  
  // Clear selected media
  const clearSelectedMedia = () => {
    selectedMedia.value = null
    selectedMediaType.value = null
  }
  
  // Handle image selection from device
  const handleImageSelect = (event) => {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        selectMedia(e.target.result, "image")
      }
      reader.readAsDataURL(file)
    }
    showMediaPicker.value = false
  }
  
  // Handle media upload
  const handleMediaUpload = (event) => {
    const files = Array.from(event.target.files)
  
    files.forEach((file) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        uploadedMedia.value.push({
          url: e.target.result,
          type: file.type,
        })
      }
      reader.readAsDataURL(file)
    })
  }
  
  // Remove uploaded media
  const removeUploadedMedia = (index) => {
    uploadedMedia.value.splice(index, 1)
  }
  
  // Handle file selection
  const handleFileSelect = (event) => {
    const file = event.target.files[0]
    if (file) {
      selectedFile.value = file
      selectedFileName.value = file.name
    }
  }
  
  // Clear selected file
  const clearSelectedFile = () => {
    selectedFile.value = null
    selectedFileName.value = ""
  }
  
  // Start voice recording
  const startVoiceRecording = () => {
    isRecording.value = true
    recordingDuration.value = 0
  
    // Start recording timer
    recordingInterval.value = setInterval(() => {
      recordingDuration.value++
    }, 1000)
  
    // In a real app, this would start actual voice recording
  }
  
  // Stop voice recording
  const stopVoiceRecording = () => {
    if (isRecording.value) {
      isRecording.value = false
      clearInterval(recordingInterval.value)
  
      // Only save if recording lasted more than 1 second
      if (recordingDuration.value > 0) {
        recordedVoice.value = true
      }
  
      // In a real app, this would stop and save the recording
    }
  }
  
  // Clear recorded voice
  const clearRecordedVoice = () => {
    recordedVoice.value = false
    recordingDuration.value = 0
  }
  
  // Block/unblock user
  const toggleBlockUser = () => {
    if (activeChatType.value === "friend" && activeChat.value) {
      const friendIndex = friends.value.findIndex((f) => f.id === activeChatId.value)
      if (friendIndex !== -1) {
        friends.value[friendIndex].isBlocked = !friends.value[friendIndex].isBlocked
        showChatOptions.value = false
      }
    }
  }
  
  // Delete chat
  const deleteChat = () => {
    showDeleteConfirmation.value = true
    showChatOptions.value = false
  }
  
  // Confirm delete chat
  const confirmDeleteChat = () => {
    if (activeChatType.value === "friend") {
      const friendIndex = friends.value.findIndex((f) => f.id === activeChatId.value)
      if (friendIndex !== -1) {
        friends.value[friendIndex].messages = []
        friends.value[friendIndex].lastMessage = ""
        friends.value[friendIndex].lastTime = "No messages"
      }
    }
  
    showDeleteConfirmation.value = false
    closeActiveChat()
  }
  
  // Report user as spam
  const reportSpam = () => {
    if (activeChatType.value === "friend" && activeChat.value) {
      // In a real app, this would send a report to the server
      alert(`${activeChat.value.name} has been reported as spam`)
      showChatOptions.value = false
    }
  }
  
  const sendMessage = () => {
    if (
      (!newMessage.value.trim() &&
        !selectedMedia.value &&
        !recordedVoice.value &&
        !selectedFile.value &&
        uploadedMedia.value.length === 0) ||
      !activeChat.value
    )
      return
  
    const now = new Date()
    const timeString = now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
  
    // Create message object
    const messageObj = {
      text: newMessage.value,
      isUser: true,
      time: timeString,
      read: false,
      media: null, // Initialize media to null
    }
  
    // Add media if selected
    if (selectedMedia.value) {
      messageObj.media = {
        type: selectedMediaType.value,
        url: selectedMedia.value,
      }
    }
  
    // Add voice recording if available
    if (recordedVoice.value) {
      messageObj.media = {
        type: "voice",
        duration: recordingDuration.value,
        currentTime: 0,
        isPlaying: false,
        progress: 0,
      }
    }
  
    // Add file if selected
    if (selectedFile.value) {
      messageObj.media = {
        type: "file",
        name: selectedFileName.value,
      }
    }
  
    // Add message to chat if it has text or non-uploaded media
    if (newMessage.value.trim() || (messageObj.media && uploadedMedia.value.length === 0)) {
      activeChat.value.messages.push(messageObj)
    }
  
    // Add uploaded media as separate messages
    uploadedMedia.value.forEach((media) => {
      const mediaMessage = {
        text: "",
        isUser: true,
        time: timeString,
        read: false,
        media: {
          type: media.type.includes("image") ? "image" : "video",
          url: media.url,
        },
      }
      activeChat.value.messages.push(mediaMessage)
    })
  
    // Update last message
    if (activeChatType.value === "friend") {
      const friendIndex = friends.value.findIndex((f) => f.id === activeChatId.value)
      if (friendIndex !== -1) {
        friends.value[friendIndex].lastMessage =
          newMessage.value ||
          (uploadedMedia.value.length > 0
            ? `Sent ${uploadedMedia.value.length} media`
            : messageObj.media
              ? messageObj.media.type === "image"
                ? "Sent an image"
                : messageObj.media.type === "voice"
                  ? "Sent a voice message"
                  : "Sent a file"
              : "")
        friends.value[friendIndex].lastTime = timeString
      }
    }
  
    // Clear inputs
    newMessage.value = ""
    clearSelectedMedia()
    clearRecordedVoice()
    clearSelectedFile()
    uploadedMedia.value = []
  
    // Scroll to bottom
    nextTick(() => {
      scrollToBottom()
    })
  
    // Simulate typing indicator
    setTimeout(() => {
      isOtherUserTyping.value = true
  
      // Simulate response after typing
      setTimeout(() => {
        isOtherUserTyping.value = false
  
        let response
        if (activeChatType.value === "ai") {
          const aiResponses = [
            "I can help you with that! What specific information do you need about AdsyConnect?",
            "That's a great question about AdsyConnect. Let me provide some details.",
            "I'm here to assist with all your AdsyConnect needs. Could you provide more details?",
            "As your AdsyAI assistant, I'd be happy to help with that request.",
            "I'm processing your request about AdsyConnect. Is there anything specific you'd like to know?",
          ]
          response = aiResponses[Math.floor(Math.random() * aiResponses.length)]
        } else {
          const responses = [
            "Thanks for your message!",
            "I'll get back to you on this soon.",
            "Let me check and get back to you.",
            "Sounds good!",
            "Great idea!",
            "I'll share this with the team.",
          ]
          response = responses[Math.floor(Math.random() * responses.length)]
        }
  
        // Add response message
        activeChat.value.messages.push({
          text: response,
          isUser: false,
          time: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
          sender: activeChat.value.name,
          read: true,
        })
  
        // Update last message for the chat
        if (activeChatType.value === "friend") {
          const friendIndex = friends.value.findIndex((f) => f.id === activeChatId.value)
          if (friendIndex !== -1) {
            friends.value[friendIndex].lastMessage = response
            friends.value[friendIndex].lastTime = new Date().toLocaleTimeString([], {
              hour: "2-digit",
              minute: "2-digit",
            })
            friends.value[friendIndex].isTyping = false
          }
        }
  
        // Mark user message as read
        const lastUserMessageIndex = activeChat.value.messages.findIndex((m) => m.isUser && !m.read)
        if (lastUserMessageIndex !== -1) {
          activeChat.value.messages[lastUserMessageIndex].read = true
        }
  
        nextTick(() => {
          scrollToBottom()
        })
      }, 2000)
    }, 1000)
  }
  
  const scrollToBottom = () => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
  }
  
  // Handle scroll for infinite loading
  const handleScroll = () => {
    if (!chatListContainer.value || !hasMoreFriends.value) return
  
    const { scrollTop, scrollHeight, clientHeight } = chatListContainer.value
  
    // If scrolled to bottom (with a small threshold)
    if (scrollHeight - scrollTop - clientHeight < 50) {
      loadMoreFriends()
    }
  }
  
  // Load more friends
  const loadMoreFriends = () => {
    if (isLoadingMore.value || !hasMoreFriends.value) return
  
    isLoadingMore.value = true
  
    // Simulate loading delay
    setTimeout(() => {
      currentPage.value++
      isLoadingMore.value = false
    }, 800)
  }
  
  // Clean up expired stories
  const cleanupExpiredStories = () => {
    const now = new Date()
    stories.value = stories.value.filter((story) => story.expiresAt > now)
  }
  
  // Load more stories
  const loadMoreStories = () => {
    if (isLoadingMoreStories.value || !hasMoreStories.value) return
  
    isLoadingMoreStories.value = true
  
    // Simulate loading delay
    setTimeout(() => {
      // Generate new stories
      const newStories = []
      const startIndex = stories.value.length
  
      for (let i = 0; i < 5; i++) {
        const storyId = `story${startIndex + i + 1}`
        const randomImg = Math.floor(Math.random() * 70) + 1
  
        newStories.push({
          id: storyId,
          name: `User ${startIndex + i + 1}`,
          avatar: `https://i.pravatar.cc/150?img=${randomImg}`,
          content: `https://i.pravatar.cc/800?img=${randomImg}`,
          time: "Just now",
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
          totalParts: Math.floor(Math.random() * 4) + 1,
          currentPart: 0,
          likes: Math.floor(Math.random() * 30),
          hasLiked: false,
          viewers: [
            { name: "Alex Johnson", avatar: "https://i.pravatar.cc/150?img=11" },
            { name: "Sarah Williams", avatar: "https://i.pravatar.cc/150?img=5" },
          ],
        })
      }
  
      // Add new stories to the list
      stories.value = [...stories.value, ...newStories]
  
      // Simulate reaching the end after loading many stories
      if (stories.value.length > 30) {
        hasMoreStories.value = false
      }
  
      isLoadingMoreStories.value = false
    }, 1000)
  }
  
  // Format voice duration
  const formatVoiceDuration = (duration) => {
    const minutes = Math.floor(duration / 60)
    const seconds = Math.floor(duration % 60)
    return `${minutes}:${seconds.toString().padStart(2, "0")}`
  }
  
  // Play voice message
  const playVoiceMessage = (message) => {
    if (!message.media) return
  
    // Stop any other playing messages
    activeChat.value.messages.forEach((msg) => {
      if (msg.media && msg.media.type === "voice" && msg.media.isPlaying && msg !== message) {
        msg.media.isPlaying = false
      }
    })
  
    // Toggle play/pause
    message.media.isPlaying = !message.media.isPlaying
  
    // Simulate progress update
    if (message.media.isPlaying) {
      let progress = 0
      const interval = setInterval(
        () => {
          progress += 1
          message.media.progress = progress
          message.media.currentTime = (message.media.duration * progress) / 100
  
          if (progress >= 100 || !message.media.isPlaying) {
            clearInterval(interval)
            message.media.isPlaying = false
            message.media.progress = 0
            message.media.currentTime = 0
          }
        },
        (message.media.duration / 100) * 10,
      ) // Simulate real-time progress
    }
  }
  
  // View full media
  const viewFullMedia = (media) => {
    fullMediaItem.value = media
    showFullMedia.value = true
  }
  
  // Watch for changes in active chat
  watch(activeChatId, () => {
    nextTick(() => {
      scrollToBottom()
    })
  })
  
  // Watch for search query changes
  watch(searchQuery, () => {
    currentPage.value = 1 // Reset pagination when search changes
  })
  
  // Lifecycle hooks
  onMounted(() => {
    checkMobile()
    window.addEventListener("resize", checkMobile)
  
    // Set up interval to check for expired stories
    const storyInterval = setInterval(cleanupExpiredStories, 60000) // Check every minute
  
    // Click outside to close dropdowns
    const handleClickOutside = (event) => {
      if (showStoryOptions.value && !event.target.closest(".story-options")) {
        showStoryOptions.value = false
      }
      if (showChatOptions.value && !event.target.closest(".chat-options")) {
        showChatOptions.value = false
      }
    }
  
    document.addEventListener("click", handleClickOutside)
  
    // Cleanup
    onUnmounted(() => {
      window.removeEventListener("resize", checkMobile)
      document.removeEventListener("click", handleClickOutside)
      clearInterval(storyInterval)
  
      if (typingTimeout.value) {
        clearTimeout(typingTimeout.value)
      }
  
      if (recordingInterval.value) {
        clearInterval(recordingInterval.value)
      }
  
      // Close story interval if active
      if (storyInterval.value) {
        clearInterval(storyInterval.value)
      }
    })
  })
  </script>
  
  <style scoped>
  /* Typing animation */
  .typing-animation {
    display: flex;
  }
  
  .dot {
    width: 6px;
    height: 6px;
    margin: 0 2px;
    background-color: #9ca3af;
    border-radius: 50%;
    animation: typing 1s infinite;
  }
  
  .dot:nth-child(2) {
    animation-delay: 0.2s;
  }
  
  .dot:nth-child(3) {
    animation-delay: 0.4s;
  }
  
  @keyframes typing {
    0% {
      opacity: 0.4;
      transform: translateY(0);
    }
    50% {
      opacity: 1;
      transform: translateY(-3px);
    }
    100% {
      opacity: 0.4;
      transform: translateY(0);
    }
  }
  
  /* Fade-in animation */
  .animate-fadeIn {
    animation: fadeIn 0.3s ease-in-out;
  }
  
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(5px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  /* Hide scrollbars but maintain scrolling functionality */
  .scrollbar-hide {
    -ms-overflow-style: none;  /* IE and Edge */
    scrollbar-width: none;  /* Firefox */
  }
  
  .scrollbar-hide::-webkit-scrollbar {
    display: none;  /* Chrome, Safari and Opera */
  }
  </style>