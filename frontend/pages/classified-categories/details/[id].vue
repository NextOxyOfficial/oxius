<template>
  <div class="max-w-6xl mx-auto -mt-3 mb-8">
    <!-- Breadcrumb -->
    <nav
      class="flex items-center text-sm my-3 px-3 pt-4 overflow-x-auto overflow-y-hidden whitespace-nowrap scrollbar-hide"
    >
      <NuxtLink
        to="/"
        class="text-gray-500 hover:text-emerald-600 flex-shrink-0"
        >Home</NuxtLink
      >
      <span class="mx-2 text-gray-400 flex-shrink-0">
        <UIcon name="i-heroicons-chevron-right" class="h-3 w-3" />
      </span>
      <NuxtLink
        to="/classified-categories"
        class="text-gray-500 hover:text-emerald-600 flex-shrink-0"
        >Classified Categories</NuxtLink
      >
      <span class="mx-2 text-gray-400 flex-shrink-0">
        <UIcon name="i-heroicons-chevron-right" class="h-3 w-3" />
      </span>
      <NuxtLink
        v-if="service?.category_details"
        :to="`/classified-categories/${service?.category_details?.slug}`"
        class="text-gray-500 hover:text-emerald-600 flex-shrink-0 max-w-[150px] truncate"
      >
        {{ service?.category_details?.title }}
      </NuxtLink>
      <span
        v-if="service?.category_details"
        class="mx-2 text-gray-400 flex-shrink-0"
      >
        <UIcon name="i-heroicons-chevron-right" class="h-3 w-3" />
      </span>
      <span class="text-gray-700 flex-shrink-0 max-w-[200px] truncate">{{
        service?.title
      }}</span>
    </nav>

    <!-- Main Service Section -->
    <div class="grid grid-cols-1 lg:grid-cols-5 gap-2">
      <div class="lg:col-span-3 relative">
        <div
          ref="galleryRef"
          class="relative aspect-video bg-gray-100 rounded-lg overflow-hidden border border-gray-200"
          @touchstart="handleTouchStart"
          @touchmove="handleTouchMove"
          @touchend="handleTouchEnd"
        >
          <div
            v-if="!service?.medias?.length && !service?.category_details?.image"
            class="absolute inset-0 w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex flex-col items-center justify-center"
          >
            <div
              class="bg-white/80 backdrop-blur-sm rounded-full p-6 mb-4 shadow-sm"
            >
              <UIcon name="i-heroicons-photo" class="h-16 w-16 text-gray-400" />
            </div>
            <p class="text-gray-500 text-lg font-medium">No Photo Uploaded</p>
          </div>
          <img
            v-else
            :src="
              service?.medias?.length > 0
                ? service.medias[currentImageIndex]?.image
                : service?.category_details?.image
            "
            :alt="service.title"
            class="absolute inset-0 w-full h-full object-cover"
          />
          <button
            v-if="service?.medias?.length > 1"
            class="absolute left-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 transition-all duration-200"
            @click="prevImage"
          >
            <ChevronLeft class="h-4 w-4 text-gray-800" />
          </button>
          <button
            v-if="service?.medias?.length > 1"
            class="absolute right-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 transition-all duration-200"
            @click="nextImage"
          >
            <ChevronRight class="h-4 w-4 text-gray-800" />
          </button>
          <div class="absolute bottom-3 right-3 flex space-x-2">
            <button
              class="bg-white/90 hover:bg-white text-gray-800 text-sm h-7 px-3 rounded-md transition-all duration-200 flex items-center"
              @click="downloadImage"
            >
              <Download class="h-3 w-3 mr-1" />
              Download
            </button>
            <span
              v-if="service?.medias?.length > 1"
              class="bg-white/90 text-gray-800 text-sm px-3 py-1.5 rounded-md"
            >
              {{ currentImageIndex + 1 }}/{{ service?.medias?.length }}
            </span>
          </div>
        </div>
        <!-- Thumbnail Gallery -->
        <div
          v-if="service?.medias?.length > 1"
          class="flex mt-3 space-x-2 overflow-x-auto pb-2 px-2"
        >
          <div
            v-for="(media, index) in service?.medias"
            :key="index"
            :class="`relative w-16 h-16 flex-shrink-0 cursor-pointer rounded-md overflow-hidden border-2 transition-all duration-200 ${
              index === currentImageIndex
                ? 'border-emerald-600'
                : 'border-transparent'
            }`"
            @click="selectImage(index)"
          >
            <div
              v-if="!media.image"
              class="absolute inset-0 w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center"
            >
              <UIcon name="i-heroicons-photo" class="h-6 w-6 text-gray-400" />
            </div>
            <img
              v-else
              :src="media.image"
              :alt="`Thumbnail ${index + 1}`"
              class="absolute inset-0 w-full h-full object-cover"
            />
          </div>
        </div>
      </div>

      <!-- Service Info - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg p-3 border border-gray-200">
          <div class="flex justify-between items-start">
            <h1 class="text-xl font-bold text-gray-800">
              {{ capitalizeTitle(service?.title) }}
            </h1>
            <div class="flex space-x-2">
              <button
                class="text-gray-400 hover:text-emerald-600 p-1 transition-colors duration-200"
                @click="handleShare"
              >
                <Share2 class="h-5 w-5" />
              </button>
            </div>
          </div>
          <div class="mt-2 flex items-center text-sm text-gray-600">
            <span v-if="numericServiceId" class="font-medium text-gray-600 mr-2"
              >Service ID: {{ numericServiceId }}</span
            >
            <span v-if="service?.created_at" class="flex items-center">
              <Calendar class="h-3 w-3 mr-1" />
              {{ formatDate(service?.created_at) }}
            </span>
          </div>

          <div class="mt-4">
            <span
              v-if="!service.negotiable"
              class="text-2xl font-bold text-emerald-600 inline-flex items-center"
            >
              <UIcon name="i-mdi:currency-bdt" class="text-2xl" />{{
                service?.price
                  ? service.price.toLocaleString()
                  : "Contact for Price"
              }}
            </span>
            <span v-else class="text-2xl font-bold text-emerald-600"
              >Negotiable</span
            >
          </div>
          <div class="mt-4 space-y-3">
            <!-- First row: Location (full width) -->
            <div class="flex items-center mb-4">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <MapPin class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-sm font-medium text-gray-600">Location</div>
                <div class="text-sm text-gray-800">
                  {{ service?.location || "Location not specified" }}
                </div>
              </div>
            </div>

            <!-- Second row: Category and Posted (2 columns) -->
            <div class="grid grid-cols-2 gap-2">
              <div v-if="service.category_details?.title" class="flex items-center">
                <div
                  class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
                >
                  <Tag class="h-4 w-4 text-emerald-600" />
                </div>
                <div>
                  <div class="text-sm font-medium text-gray-600">Category</div>
                  <div class="text-sm text-gray-800">
                    {{ service.category_details?.title }}
                  </div>
                </div>
              </div>

              <div v-if="service?.created_at" class="flex items-center">
                <div
                  class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
                >
                  <Clock class="h-4 w-4 text-emerald-600" />
                </div>
                <div>
                  <div class="text-sm font-medium text-gray-600">Posted</div>
                  <div class="text-sm text-gray-800">
                    {{ formatRelativeTime(service?.created_at) }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-4 flex justify-between">
            <button
              class="flex-1 mr-2 text-sm py-2 rounded-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-600"
              @click="openReportDialog"
            >
              <Flag class="h-3 w-3 mr-1" />
              Report Service
            </button>
            <button
              class="flex-1 text-sm py-2 rounded-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-600"
              @click="handleShare"
            >
              <Share2 class="h-3 w-3 mr-1" />
              Share
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Details Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mt-4">
      <!-- Service Details - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200">
          <div class="p-3">
            <h2 class="text-lg font-bold mb-4 text-gray-800 flex items-center">
              <ClipboardList class="h-5 w-5 mr-2 text-emerald-600" />
              Service Details
            </h2>
            <div
              v-if="service?.instructions"
              class="text-gray-600 sm:px-6 whitespace-pre-line text-sm leading-relaxed"
              v-html="service?.instructions"
            ></div>
            <div v-else class="text-gray-500 sm:px-6 text-sm italic">
              No service details provided
            </div>

            <!-- Service Location - Only show if location exists -->
            <template v-if="service?.location">
              <div class="my-6 border-t border-gray-100"></div>
              <div>
                <h3
                  class="text-base font-semibold mb-3 text-gray-800 flex items-center"
                >
                  <MapPin class="h-4 w-4 mr-2 text-emerald-600" />
                  Service Location
                </h3>
                <div class="text-sm sm:px-6 text-gray-800">
                  {{ service?.location }}
                </div>
              </div>
            </template>
          </div>
        </div>

        <!-- Safety Tips -->
        <div
          class="bg-white rounded-lg overflow-hidden mt-6 border border-gray-200"
        >
          <div class="p-6">
            <div class="flex items-center mb-4">
              <ShieldCheck class="h-5 w-5 text-emerald-600 mr-2" />
              <h2 class="text-lg font-bold text-gray-800">Safety Tips</h2>
            </div>
            <ul class="space-y-3 text-gray-600 text-sm">
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <Check class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Verify service provider credentials</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <Check class="h-3 w-3 text-emerald-600" />
                </div>
                <span
                  >Meet in a safe, public place for initial consultation</span
                >
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <Check class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Get written quotes and agreements</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <Check class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Don't pay full amount in advance</span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Service Provider Info - 1 column on large screens -->
      <div class="lg:col-span-1">
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200">
          <div class="p-6">
            <h2 class="text-lg font-bold mb-4 text-gray-800 flex items-center">
              <User class="h-5 w-5 mr-2 text-emerald-600" />
              Service Provider
            </h2>
            <div class="flex items-center">
              <div
                class="size-16 rounded-full bg-gray-200 overflow-hidden mr-4 border border-gray-200"
              >
                <img
                  :src="
                    service.user?.image ||
                    '/static/frontend/images/placeholder.jpg'
                  "
                  :alt="service.user?.first_name || 'Provider'"
                  class="h-full w-full object-cover"
                />
              </div>
              <div>
                <div class="flex items-center justify-between">
                  <h3 class="font-semibold text-gray-800">
                    {{ providerDisplayName }}
                  </h3>
                  <div class="flex items-center space-x-1 ml-2">
                    <UIcon
                      v-if="service.user?.kyc"
                      name="mdi:check-decagram"
                      class="w-4 h-4 text-blue-600"
                      title="Verified"
                    />
                    <div class="inline-flex" v-if="service.user?.is_pro">
                      <span
                        class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-xs font-medium shadow-sm"
                        title="Pro Member"
                      >
                        <div class="flex items-center gap-1">
                          <UIcon
                            name="i-heroicons-shield-check"
                            class="size-3"
                          />
                          <span class="text-2xs">Pro</span>
                        </div>
                      </span>
                    </div>
                  </div>
                </div>
                <p class="text-sm text-gray-600">Service Provider</p>
              </div>
            </div>

            <div
              v-if="service.user?.about"
              class="mt-4 text-sm text-gray-600"
              v-html="service.user?.about"
            ></div>

            <div class="mt-4 space-y-3 bg-gray-50 p-4 rounded-md">
              <div v-if="service.user?.phone" class="flex justify-between items-center text-sm">
                <span class="text-gray-600">Phone</span>
                <div class="flex items-center">
                  <span v-if="!showPhone" class="text-gray-800">{{
                    maskPhoneNumber(service.user?.phone)
                  }}</span>
                  <span v-else class="text-gray-800">{{
                    service.user?.phone
                  }}</span>
                  <button
                    @click="toggleShowPhone"
                    class="ml-2 text-emerald-600 hover:text-emerald-700"
                  >
                    <Eye v-if="!showPhone" class="h-4 w-4" />
                    <EyeOff v-else class="h-4 w-4" />
                  </button>
                </div>
              </div>

              <div
                v-if="service.user?.email"
                class="flex justify-between text-sm"
              >
                <span class="text-gray-600">Email</span>
                <a
                  :href="'mailto:' + service.user?.email"
                  class="font-medium text-emerald-600 hover:text-emerald-700"
                >
                  {{ service.user?.email }}
                </a>
              </div>
              
              <!-- Show message if no contact info -->
              <div v-if="!service.user?.phone && !service.user?.email" class="text-sm text-gray-500 text-center py-2">
                No contact information available
              </div>
            </div>

            <!-- Social Links -->
            <div v-if="hasSocialLinks" class="mt-4 space-y-2">
              <h4 class="text-sm font-medium text-gray-800">Connect</h4>
              <div class="flex flex-wrap gap-2">
                <a
                  v-if="service.user?.face_link"
                  :href="service.user?.face_link"
                  target="_blank"
                  class="flex items-center px-3 py-1 bg-blue-50 text-blue-600 rounded-md text-sm hover:bg-blue-100"
                >
                  <UIcon name="logos:facebook" class="w-4 h-4 mr-1" />
                  Facebook
                </a>
                <a
                  v-if="service.user?.instagram_link"
                  :href="service.user?.instagram_link"
                  target="_blank"
                  class="flex items-center px-3 py-1 bg-pink-50 text-pink-600 rounded-md text-sm hover:bg-pink-100"
                >
                  <UIcon name="skill-icons:instagram" class="w-4 h-4 mr-1" />
                  Instagram
                </a>
                <a
                  v-if="service.user?.whatsapp_link"
                  :href="service.user?.whatsapp_link"
                  target="_blank"
                  class="flex items-center px-3 py-1 bg-green-50 text-green-600 rounded-md text-sm hover:bg-green-100"
                >
                  <UIcon name="logos:whatsapp-icon" class="w-4 h-4 mr-1" />
                  WhatsApp
                </a>
              </div>
            </div>
            
            <!-- Chat with Service Provider Link -->
            <div
              v-if="isAuthenticated && user?.user?.id !== service.user?.id"
              class="mt-4 pt-4 border-t border-gray-100"
            >
              <button
                class="w-full flex items-center justify-center text-blue-600 hover:text-blue-700 transition-all duration-200 text-base font-semibold cursor-pointer group py-2 px-4 hover:bg-blue-50 rounded-lg"
                @click="
                  handleButtonClick('chat_provider');
                  startChatWithProvider();
                "
              >
                <div
                  v-if="loadingButtons.has('chat_provider')"
                  class="dotted-spinner blue mr-3"
                ></div>
                <template v-else>
                  <img 
                    src="https://adsyclub.com/static/frontend/images/chat_icon.png" 
                    alt="Chat"
                    class="w-5 h-5 mr-3 opacity-90 group-hover:opacity-100 transition-opacity"
                  />
                  Chat with Service Provider
                </template>
              </button>
            </div>
            
            <button
              class="w-full mt-4 text-sm border border-gray-200 rounded-md py-2 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-800"
              @click="contactProvider"
            >
              <Phone class="h-4 w-4 mr-2 text-emerald-600" />
              Contact Provider
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Share Dialog -->
    <div
      v-if="shareDialogOpen"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeShareDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Share this service</h3>
          <button
            @click="closeShareDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5" style="word-break: break-word">
          <div
            class="flex items-center space-x-2 overflow-hidden"
            style="word-break: break-word"
          >
            <div class="flex-1 overflow-hidden" style="word-break: break-word">
              <div
                class="flex items-center justify-between rounded-md border border-gray-200 px-3 py-2 overflow-hidden"
                style="word-break: break-word"
              >
                <span class="text-sm text-gray-600">{{ shareUrl }}</span>
              </div>
            </div>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="copyToClipboard"
            >
              <span class="flex items-center">
                <UIcon name="i-heroicons-clipboard" class="w-4 h-4 mr-1" />
                Copy
              </span>
            </button>
          </div>

          <div class="mt-5">
            <h4 class="text-sm font-medium mb-3 text-gray-800">Share via</h4>
            <div class="grid grid-cols-2 gap-3">
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('facebook')"
              >
                <span class="text-blue-600 font-bold mr-2">f</span>
                Facebook
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('twitter')"
              >
                <span class="text-blue-400 font-bold mr-2">𝕏</span>
                Twitter
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('whatsapp')"
              >
                <span class="text-green-600 font-bold mr-2">📱</span>
                WhatsApp
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('email')"
              >
                <span class="text-gray-600 font-bold mr-2">✉</span>
                Email
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Report Dialog -->
    <div
      v-if="showReportDialog"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeReportDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Report Service</h3>
          <button
            @click="closeReportDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5">
          <p class="text-sm text-gray-600 mb-4">
            Please select a reason for reporting this service:
          </p>

          <div class="space-y-2">
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="fake"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800"
                >Fake or misleading service</span
              >
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="prohibited"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Prohibited service</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="offensive"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Offensive content</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="scam"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Scam or fraud</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="other"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Other</span>
            </label>
          </div>

          <textarea
            v-if="reportReason === 'other'"
            v-model="reportDetails"
            placeholder="Please provide details about your report..."
            class="mt-4 w-full border border-gray-200 rounded-md p-2 text-sm text-gray-800 h-24 resize-none focus:outline-none focus:ring-1 focus:ring-emerald-500"
          ></textarea>

          <div class="mt-6 flex justify-end space-x-3">
            <button
              class="px-4 py-2 border border-gray-200 rounded-md text-sm text-gray-600 hover:bg-gray-50"
              @click="closeReportDialog"
            >
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="submitReport"
            >
              Submit Report
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from "vue";
import {
  Calendar,
  MapPin,
  Share2,
  Tag,
  Layers,
  AlertTriangle,
  ShieldCheck,
  User,
  ChevronRight,
  Flag,
  Heart,
  ChevronLeft,
  ExternalLink,
  Eye,
  EyeOff,
  X,
  Download,
  ClipboardList,
  LayoutGrid,
  Briefcase,
  Clock,
  Check,
  Phone,
} from "lucide-vue-next";

// Import toast functionality for notifications
const toast = useToast();

// Import authentication composable
const { user, isAuthenticated } = useAuth();
const { chatIconPath } = useStaticAssets();

const { baseURL } = useApi();
const service = ref({});
const router = useRoute();

// State variables
const currentImageIndex = ref(0);
const showPhone = ref(false);
const shareDialogOpen = ref(false);
const showReportDialog = ref(false);
const galleryRef = ref(null);
const touchStartX = ref(0);
const touchEndX = ref(0);
const shareUrl = ref("");
const reportReason = ref("");
const reportDetails = ref("");

// Loading state for buttons
const loadingButtons = ref(new Set());

// Handle button clicks with loading states
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
};

async function fetchServices() {
  const response = await $fetch(
    `${baseURL}/classified-categories/post/${router.params.id}/`
  );

  service.value = response;
  useHead({
    title: `AdsyClub | ${
      response?.title
        ? response.title.charAt(0).toUpperCase() + response.title.slice(1)
        : ""
    }`,
  });
}

setTimeout(() => {
  fetchServices();
}, 20);

// Computed property to check if user has social links
const hasSocialLinks = computed(() => {
  return (
    service.value.user?.face_link ||
    service.value.user?.instagram_link ||
    service.value.user?.whatsapp_link
  );
});

// Computed property for provider display name
const providerDisplayName = computed(() => {
  const user = service.value?.user;
  if (!user) return "Unknown Provider";
  
  const firstName = user.first_name?.trim() || "";
  const lastName = user.last_name?.trim() || "";
  
  if (firstName && lastName) {
    return `${firstName} ${lastName}`;
  } else if (firstName) {
    return firstName;
  } else if (lastName) {
    return lastName;
  } else if (user.username) {
    return user.username;
  }
  
  return "Service Provider";
});

// Generate numeric service ID
const numericServiceId = computed(() => {
  if (!service.value?.id) return "";

  // Convert string ID to a consistent numeric format
  let hash = 0;
  const str = service.value.id.toString();

  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convert to 32-bit integer
  }

  // Ensure positive number and limit to 10 digits
  const positiveHash = Math.abs(hash);
  const numericId = positiveHash.toString().padStart(6, "0").slice(0, 10);

  return numericId;
});

// Format date
const formatDate = (dateString) => {
  if (!dateString) return "N/A";
  try {
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return "N/A";
    return new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    }).format(date);
  } catch (e) {
    return "N/A";
  }
};

// Format relative time
const formatRelativeTime = (dateString) => {
  if (!dateString) return "Recently";
  try {
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return "Recently";
    const now = new Date();
    const diffInSeconds = Math.floor((now - date) / 1000);

    if (diffInSeconds < 60) return "Just now";
    if (diffInSeconds < 3600)
      return `${Math.floor(diffInSeconds / 60)} minutes ago`;
    if (diffInSeconds < 86400)
      return `${Math.floor(diffInSeconds / 3600)} hours ago`;
    return `${Math.floor(diffInSeconds / 86400)} days ago`;
  } catch (e) {
    return "Recently";
  }
};

// Mask phone number
const maskPhoneNumber = (phone) => {
  if (!phone) return "Not provided";
  return "XXXXXXX" + phone?.slice(-3);
};

// Image navigation
const nextImage = () => {
  if (!service.value?.medias?.length) return;
  currentImageIndex.value =
    currentImageIndex.value === service.value.medias.length - 1
      ? 0
      : currentImageIndex.value + 1;
};

const prevImage = () => {
  if (!service.value?.medias?.length) return;
  currentImageIndex.value =
    currentImageIndex.value === 0
      ? service.value.medias.length - 1
      : currentImageIndex.value - 1;
};

const selectImage = (index) => {
  currentImageIndex.value = index;
};

// Touch handlers for swipe
const handleTouchStart = (e) => {
  touchStartX.value = e.touches[0].clientX;
};

const handleTouchMove = (e) => {
  touchEndX.value = e.touches[0].clientX;
};

const handleTouchEnd = () => {
  const touchDiff = touchStartX.value - touchEndX.value;

  // If swipe distance is significant enough (more than 50px)
  if (Math.abs(touchDiff) > 50) {
    if (touchDiff > 0) {
      // Swipe left, go to next image
      nextImage();
    } else {
      // Swipe right, go to previous image
      prevImage();
    }
  }
};

// Download image
const downloadImage = () => {
  // Get the current image URL from the service medias array
  let imageUrl;

  if (service.value?.medias?.length > 0) {
    const currentMedia = service.value.medias[currentImageIndex.value];
    imageUrl = currentMedia?.image;
  } else {
    imageUrl = service.value?.category_details?.image;
  }

  if (!imageUrl) {
    console.error("No image URL found for download");
    return;
  }

  // Create a download link for the current image
  const link = document.createElement("a");
  link.href = imageUrl;
  link.download = `service-image-${currentImageIndex.value + 1}.jpg`;
  link.setAttribute("target", "_blank"); // Open in new tab if direct download fails
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

// Toggle phone visibility
const toggleShowPhone = () => {
  showPhone.value = !showPhone.value;
};

// Share functionality
const handleShare = () => {
  shareDialogOpen.value = true;
  // Use the current hostname; in production, this will be your domain
  const productionDomain = "https://adsyclub.com";
  // Use window.location.pathname to get just the path without hostname
  const pathname = window.location.pathname;
  // Create the full URL using the production domain
  shareUrl.value = productionDomain + pathname;
};

const closeShareDialog = () => {
  shareDialogOpen.value = false;
};

const copyToClipboard = () => {
  navigator.clipboard.writeText(shareUrl.value);
  // Show a toast message
  toast.add({
    title: "Link Copied!",
    description: "Share link has been copied to clipboard",
    color: "green",
    icon: "i-heroicons-check-circle",
  });
};

const shareViaMedia = (platform) => {
  let platformShareUrl = "";
  const currentUrl = encodeURIComponent(shareUrl.value);
  const title = encodeURIComponent(service.value?.title || "");

  switch (platform) {
    case "facebook":
      platformShareUrl = `https://www.facebook.com/sharer/sharer.php?u=${currentUrl}`;
      break;
    case "twitter":
      platformShareUrl = `https://twitter.com/intent/tweet?text=${title}&url=${currentUrl}`;
      break;
    case "whatsapp":
      platformShareUrl = `https://api.whatsapp.com/send?text=${title} ${currentUrl}`;
      break;
    case "email":
      platformShareUrl = `mailto:?subject=${title}&body=${currentUrl}`;
      break;
  }

  if (platformShareUrl) {
    window.open(platformShareUrl, "_blank");
  }

  closeShareDialog();
};

// Report functionality
const openReportDialog = () => {
  showReportDialog.value = true;
};

const closeReportDialog = () => {
  showReportDialog.value = false;
  reportReason.value = "";
  reportDetails.value = "";
};

const submitReport = () => {
  // Show success message
  toast.add({
    title: "Report Submitted",
    description: "Thank you for your report. We will review it shortly.",
    color: "green",
    icon: "i-heroicons-check-circle",
  });

  closeReportDialog();
};

// Function to capitalize first letter of title
const capitalizeTitle = (title) => {
  if (!title) return "";
  return title.charAt(0).toUpperCase() + title.slice(1);
};

// Contact provider functionality
const contactProvider = () => {
  if (service.value.user?.phone) {
    window.open(`tel:${service.value.user.phone}`, "_self");
  } else if (service.value.user?.email) {
    window.open(`mailto:${service.value.user.email}`, "_self");
  } else if (service.value.user?.whatsapp_link) {
    window.open(service.value.user.whatsapp_link, "_blank");
  } else {
    toast.add({
      title: "Contact Information Not Available",
      description: "No contact information is available for this provider.",
      color: "red",
      icon: "i-heroicons-exclamation-triangle",
    });
  }
};

// Legacy share functions for backward compatibility
const runtimeConfig = useRuntimeConfig();
const domain = runtimeConfig.public.domain || "https://adsyclub.com";
const pageLink = computed(
  () =>
    `${domain}/classified-categories/details/${
      service.value?.slug || router.params.id
    }`
);
const pageTitle = computed(() => String(document.title).replace(/\&/g, "%26"));

function fbs_click() {
  shareViaMedia("facebook");
}

function tbs_click() {
  shareViaMedia("twitter");
}

function lbs_click() {
  window.open(
    `https://www.linkedin.com/sharing/share-offsite/?url=${pageLink.value}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}

function rbs_click() {
  window.open(
    `https://www.reddit.com/submit?url=${pageLink.value}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}

function pbs_click() {
  window.open(
    `https://www.pinterest.com/pin/create/button/?&text=${pageTitle.value}&url=${pageLink.value}&description=${pageTitle.value}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}

// Chat with service provider functionality
const startChatWithProvider = async () => {
  try {
    if (!isAuthenticated.value) {
      toast.add({
        title: 'Authentication Required',
        description: 'Please log in to start a chat with the service provider.',
        color: 'red',
        timeout: 3000,
      });
      return;
    }

    if (!service.value?.user?.id) {
      toast.add({
        title: 'Error',
        description: 'Service provider information not available.',
        color: 'red',
        timeout: 3000,
      });
      return;
    }

    // Navigate to inbox with provider chat
    await navigateTo(`/inbox?chat_with=${service.value.user.id}`);
    
    toast.add({
      title: 'Chat Started',
      description: `Opening chat with ${providerDisplayName.value}`,
      color: 'green',
      timeout: 2000,
    });
  } catch (error) {
    console.error('Error starting chat:', error);
    toast.add({
      title: 'Error',
      description: 'Failed to start chat. Please try again.',
      color: 'red',
      timeout: 3000,
    });
  } finally {
    loadingButtons.value.delete('chat_provider');
  }
};
</script>

<style scoped>
/* Hide scrollbar while keeping scroll functionality */
.scrollbar-hide {
  -ms-overflow-style: none; /* Internet Explorer 10+ */
  scrollbar-width: none; /* Firefox */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Safari and Chrome */
}
</style>
