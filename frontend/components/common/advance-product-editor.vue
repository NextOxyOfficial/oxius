<template>
  <div>
    <!-- Editor Toolbar - Visible when in edit mode -->
    <div
      v-if="editModeActive"
      class="sticky top-0 z-50 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 shadow-md mb-6 p-3"
    >
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <UBadge color="primary" variant="subtle">
            <UIcon name="i-heroicons-pencil-square" class="w-4 h-4 mr-1" />
            Edit Mode
          </UBadge>
        </div>

        <div class="flex items-center gap-2">
          <UButton color="gray" variant="soft" size="sm" @click="resetChanges">
            Reset Changes
          </UButton>
        </div>
      </div>
    </div>

    <!-- Key Benefits Section -->
    <section class="py-2 w-full relative">
      <!-- Edit indicator for section when in edit mode -->
      <div
        v-if="editModeActive"
        class="absolute top-2 right-2 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 text-xs px-2 py-1 rounded-md"
      >
        Click text to edit
      </div>

      <h2 class="text-2xl md:text-3xl font-bold text-center mb-12">
        <span v-if="!editModeActive">
          {{ editorData.benefits_title || `Why Choose?` }}
        </span>
        <span
          v-else
          @click="
            editField(
              'benefits_title',
              editorData.benefits_title || `Why Choose ?`
            )
          "
          class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
        >
          {{ editorData.benefits_title || `Why Choose ?` }}
        </span>
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <!-- Benefit 1 -->
        <div class="benefit-card relative">
          <div class="icon-container">
            <UIcon
              :name="benefits[0]?.icon || 'i-heroicons-sparkles'"
              class="w-8 h-8 text-primary-500"
            />
          </div>

          <h3 class="text-xl font-semibold mb-2">
            <span v-if="!editModeActive">{{
              benefits[0]?.title || "Premium Quality"
            }}</span>
            <span
              v-else
              @click="
                editBenefit(0, 'title', benefits[0]?.title || 'Premium Quality')
              "
              class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
            >
              {{ benefits[0]?.title || "Premium Quality" }}
            </span>
          </h3>

          <p>
            <span v-if="!editModeActive">{{
              benefits[0]?.description ||
              "Crafted with the highest quality materials for exceptional durability and performance."
            }}</span>
            <span
              v-else
              @click="
                editBenefit(
                  0,
                  'description',
                  benefits[0]?.description ||
                    'Crafted with the highest quality materials for exceptional durability and performance.'
                )
              "
              class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
            >
              {{
                benefits[0]?.description ||
                "Crafted with the highest quality materials for exceptional durability and performance."
              }}
            </span>
          </p>

          <div v-if="editModeActive" class="mt-3">
            <button
              type="button"
              @click="
                editBenefit(
                  0,
                  'icon',
                  benefits[0]?.icon || 'i-heroicons-sparkles'
                )
              "
              class="text-xs text-primary-600 dark:text-primary-400 flex items-center"
            >
              <UIcon name="i-heroicons-pencil-square" class="w-3 h-3 mr-1" />
              Edit icon
            </button>
          </div>
        </div>

        <!-- Benefit 2 -->
        <div class="benefit-card relative">
          <div class="icon-container">
            <UIcon
              :name="benefits[1]?.icon || 'i-heroicons-rocket-launch'"
              class="w-8 h-8 text-primary-500"
            />
          </div>

          <h3 class="text-xl font-semibold mb-2">
            <span v-if="!editModeActive">{{
              benefits[1]?.title || "Fast Results"
            }}</span>
            <span
              v-else
              @click="
                editBenefit(1, 'title', benefits[1]?.title || 'Fast Results')
              "
              class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
            >
              {{ benefits[1]?.title || "Fast Results" }}
            </span>
          </h3>

          <p>
            <span v-if="!editModeActive">{{
              benefits[1]?.description ||
              "Experience immediate benefits and see results faster than with competing products."
            }}</span>
            <span
              v-else
              @click="
                editBenefit(
                  1,
                  'description',
                  benefits[1]?.description ||
                    'Experience immediate benefits and see results faster than with competing products.'
                )
              "
              class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
            >
              {{
                benefits[1]?.description ||
                "Experience immediate benefits and see results faster than with competing products."
              }}
            </span>
          </p>

          <div v-if="editModeActive" class="mt-3">
            <button
              type="button"
              @click="
                editBenefit(
                  1,
                  'icon',
                  benefits[1]?.icon || 'i-heroicons-rocket-launch'
                )
              "
              class="text-xs text-primary-600 dark:text-primary-400 flex items-center"
            >
              <UIcon name="i-heroicons-pencil-square" class="w-3 h-3 mr-1" />
              Edit icon
            </button>
          </div>
        </div>

        <!-- Benefit 3 -->
        <div class="benefit-card relative">
          <div class="icon-container">
            <UIcon
              :name="benefits[2]?.icon || 'i-heroicons-check-badge'"
              class="w-8 h-8 text-primary-500"
            />
          </div>

          <h3 class="text-xl font-semibold mb-2">
            <span v-if="!editModeActive">{{
              benefits[2]?.title || "Satisfaction Guarantee"
            }}</span>
            <span
              v-else
              @click="
                editBenefit(
                  2,
                  'title',
                  benefits[2]?.title || 'Satisfaction Guarantee'
                )
              "
              class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
            >
              {{ benefits[2]?.title || "Satisfaction Guarantee" }}
            </span>
          </h3>

          <p>
            <span v-if="!editModeActive">{{
              benefits[2]?.description ||
              "Not completely satisfied? Return within 30 days for a full refund, no questions asked."
            }}</span>
            <span
              v-else
              @click="
                editBenefit(
                  2,
                  'description',
                  benefits[2]?.description ||
                    'Not completely satisfied? Return within 30 days for a full refund, no questions asked.'
                )
              "
              class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
            >
              {{
                benefits[2]?.description ||
                "Not completely satisfied? Return within 30 days for a full refund, no questions asked."
              }}
            </span>
          </p>

          <div v-if="editModeActive" class="mt-3">
            <button
              type="button"
              @click="
                editBenefit(
                  2,
                  'icon',
                  benefits[2]?.icon || 'i-heroicons-check-badge'
                )
              "
              class="text-xs text-primary-600 dark:text-primary-400 flex items-center"
            >
              <UIcon name="i-heroicons-pencil-square" class="w-3 h-3 mr-1" />
              Edit icon
            </button>
          </div>
        </div>
      </div>

      <div class="text-center mt-12">
        <button
          type="button"
          @click="addToCart(currentProduct, 1)"
          class="px-8 py-3 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white font-bold rounded-xl shadow-lg transition-all duration-300"
        >
          <span v-if="!editModeActive">{{
            editorData.benefits_cta || "Yes! I Want This Now"
          }}</span>
          <span
            v-else
            @click.stop="
              editField(
                'benefits_cta',
                editorData.benefits_cta || 'Yes! I Want This Now'
              )
            "
            class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
          >
            {{ editorData.benefits_cta || "Yes! I Want This Now" }}
          </span>
        </button>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-2 w-full relative">
      <!-- Edit indicator for section when in edit mode -->
      <div
        v-if="editModeActive"
        class="absolute top-2 right-2 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 text-xs px-2 py-1 rounded-md"
      >
        Click text to edit
      </div>

      <div class="w-full px-3 max-w-4xl mx-auto">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          <span v-if="!editModeActive">{{
            editorData.faqs_title || "Frequently Asked Questions"
          }}</span>
          <span
            v-else
            @click="
              editField(
                'faqs_title',
                editorData.faqs_title || 'Frequently Asked Questions'
              )
            "
            class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
          >
            {{ editorData.faqs_title || "Frequently Asked Questions" }}
          </span>
        </h2>

        <p class="text-center text-slate-600 dark:text-slate-300 mb-12">
          <span v-if="!editModeActive">{{
            editorData.faqs_subtitle ||
            "Everything you need to know about our product"
          }}</span>
          <span
            v-else
            @click="
              editField(
                'faqs_subtitle',
                editorData.faqs_subtitle ||
                  'Everything you need to know about our product'
              )
            "
            class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
          >
            {{
              editorData.faqs_subtitle ||
              "Everything you need to know about our product"
            }}
          </span>
        </p>

        <div>
          <!-- Display FAQs -->
          <UAccordion :items="editableFaqs" />

          <!-- FAQ Editor Tools -->
          <div
            v-if="editModeActive"
            class="mt-6 border-t border-slate-200 dark:border-slate-700 pt-4"
          >
            <h4 class="font-medium mb-3">Edit FAQs</h4>
            <div
              v-for="(faq, index) in editableFaqs"
              :key="index"
              class="mb-4 p-3 border border-slate-200 dark:border-slate-700 rounded-lg"
            >
              <div class="flex justify-between mb-2">
                <span class="font-medium">FAQ #{{ index + 1 }}</span>
                <UButton
                  type="button"
                  color="red"
                  variant="ghost"
                  icon="i-heroicons-trash"
                  size="xs"
                  @click="removeFaq(index)"
                />
              </div>

              <UFormGroup label="Question">
                <UInput
                  v-model="editableFaqs[index].label"
                  placeholder="Enter question"
                />
              </UFormGroup>

              <UFormGroup label="Answer" class="mt-2">
                <UTextarea
                  v-model="editableFaqs[index].content"
                  placeholder="Enter answer"
                  rows="3"
                />
              </UFormGroup>

              <UFormGroup label="Icon" class="mt-2">
                <UInput
                  v-model="editableFaqs[index].icon"
                  placeholder="i-heroicons-shield-check"
                />
              </UFormGroup>
            </div>

            <UButton
              type="button"
              color="primary"
              variant="soft"
              block
              @click="addFaq"
            >
              <UIcon name="i-heroicons-plus" class="w-4 h-4 mr-1.5" />
              Add FAQ
            </UButton>
          </div>
        </div>
      </div>
    </section>

    <!-- Final CTA Section -->
    <section
      class="py-2 bg-gradient-to-br from-primary-600 to-primary-800 text-white rounded-xl my-6 w-full relative"
    >
      <!-- Edit indicator for section when in edit mode -->
      <div
        v-if="editModeActive"
        class="absolute top-2 right-2 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 text-xs px-2 py-1 rounded-md"
      >
        Click text to edit
      </div>

      <div class="px-6 py-8 text-center w-full">
        <h2 class="text-3xl md:text-4xl font-bold mb-6">
          <span v-if="!editModeActive">{{
            editorData.cta_title || "Ready to Experience the Difference?"
          }}</span>
          <span
            v-else
            @click="
              editField(
                'cta_title',
                editorData.cta_title || 'Ready to Experience the Difference?'
              )
            "
            class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
          >
            {{ editorData.cta_title || "Ready to Experience the Difference?" }}
          </span>
        </h2>

        <p class="text-white/80 mb-8 text-lg max-w-3xl mx-auto">
          <span v-if="!editModeActive">{{
            editorData.cta_subtitle ||
            `Join thousands of satisfied customers who have already transformed their experience with ${currentProduct.name}.`
          }}</span>
          <span
            v-else
            @click="
              editField(
                'cta_subtitle',
                editorData.cta_subtitle ||
                  `Join thousands of satisfied customers who have already transformed their experience with ${currentProduct.name}.`
              )
            "
            class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
          >
            {{
              editorData.cta_subtitle ||
              `Join thousands of satisfied customers who have already transformed their experience with ${currentProduct.name}.`
            }}
          </span>
        </p>

        <!-- Price Box -->
        <div
          class="mb-8 inline-block bg-white/10 backdrop-blur-sm rounded-xl p-6 mx-auto"
        >
          <div class="flex items-center justify-center gap-4">
            <div class="text-center">
              <div class="text-white/60 line-through text-lg">
                Regular Price:
              </div>
              <div class="text-2xl font-bold">
                ৳{{
                  currentProduct.regular_price ||
                  (currentProduct.sale_price || 0) * 1.5
                }}
              </div>
            </div>
            <div class="text-4xl font-bold">→</div>
            <div class="text-center">
              <div class="text-white/90 text-lg">Special Offer:</div>
              <div class="text-4xl font-bold">
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </div>
            </div>
          </div>
        </div>

        <button
          type="button"
          @click="addToCart(currentProduct, 1)"
          class="px-10 py-4 bg-white hover:bg-slate-50 text-primary-700 text-xl font-bold rounded-xl shadow-2xl transition-all duration-300 animate-pulse hover:animate-none transform hover:scale-105"
        >
          <span v-if="!editModeActive">{{
            editorData.cta_button_text || "Order Now & Save"
          }}</span>
          <span
            v-else
            @click.stop="
              editField(
                'cta_button_text',
                editorData.cta_button_text || 'Order Now & Save'
              )
            "
            class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
          >
            {{ editorData.cta_button_text || "Order Now & Save" }}
          </span>
          <span class="block text-sm font-normal mt-1">
            <span v-if="!editModeActive">{{
              editorData.cta_button_subtext || "30-Day Money Back Guarantee"
            }}</span>
            <span
              v-else
              @click.stop="
                editField(
                  'cta_button_subtext',
                  editorData.cta_button_subtext || '30-Day Money Back Guarantee'
                )
              "
              class="cursor-pointer hover:bg-slate-800 dark:hover:bg-primary-900/20 px-2 rounded"
            >
              {{
                editorData.cta_button_subtext || "30-Day Money Back Guarantee"
              }}
            </span>
          </span>
        </button>

        <!-- Trust Badges -->
        <div class="flex flex-wrap justify-center gap-6 mt-8">
          <!-- Only show enabled badges in view mode -->

          <div
            v-for="badge in trust_badges.filter((b) => b.enabled)"
            :key="badge.id"
            class="flex items-center gap-1.5 px-4 py-2 rounded-full bg-white/10"
          >
            <UIcon :name="badge.icon" class="w-5 h-5" />
            <span class="text-sm">{{ badge.text }}</span>
          </div>

          <!-- Edit button in edit mode -->
          <div v-if="editModeActive" class="absolute bottom-2 right-2">
            <UButton
              type="button"
              color="primary"
              variant="solid"
              size="xs"
              @click="openTrustBadgeEditor"
              icon="i-heroicons-pencil-square"
            />
          </div>
        </div>

        <!-- Trust Badges Editor Modal -->
        <UModal v-model="isTrustBadgeModalOpen">
          <UCard
            :ui="{
              ring: '',
              divide: 'divide-y divide-gray-100 dark:divide-gray-800',
            }"
          >
            <template #header>
              <div class="flex justify-between items-center">
                <h3 class="text-base font-semibold">Trust Badges</h3>
                <UButton
                  type="button"
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  @click="isTrustBadgeModalOpen = false"
                />
              </div>
            </template>

            <div class="p-4">
              <p class="text-sm text-slate-600 dark:text-slate-300 mb-4">
                Select which trust badges to display on your product page:
              </p>
              <div class="space-y-3">
                <div
                  v-for="badge in trust_badges"
                  :key="badge.id"
                  class="flex items-center p-2 rounded hover:bg-slate-50 dark:hover:bg-slate-800/50"
                >
                  <UCheckbox
                    v-model="badge.enabled"
                    :ui="{ wrapper: 'mr-3' }"
                  />
                  <div class="flex items-center gap-2">
                    <div
                      class="bg-primary-100 dark:bg-primary-900/30 p-2 rounded"
                    >
                      <UIcon
                        :name="badge.icon"
                        class="w-5 h-5 text-primary-600 dark:text-primary-400"
                      />
                    </div>
                    <div>
                      <div class="font-medium">{{ badge.text }}</div>
                      <div class="text-xs text-slate-500 dark:text-slate-400">
                        {{ badge.description }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <template #footer>
              <div class="flex justify-end gap-2">
                <UButton
                  type="button"
                  color="gray"
                  @click="isTrustBadgeModalOpen = false"
                >
                  Cancel
                </UButton>
                <UButton type="button" color="primary" @click="saveTrustBadges">
                  Apply Changes
                </UButton>
              </div>
            </template>
          </UCard>
        </UModal>
      </div>
    </section>

    <!-- Edit Modal -->
    <UModal v-model="isEditModalOpen">
      <UCard
        :ui="{
          ring: '',
          divide: 'divide-y divide-gray-100 dark:divide-gray-800',
        }"
      >
        <template #header>
          <div class="flex justify-between items-center">
            <h3 class="text-base font-semibold">
              Editing {{ editingField.label }}
            </h3>
            <UButton
              type="button"
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark"
              @click="isEditModalOpen = false"
            />
          </div>
        </template>

        <div class="p-4">
          <UTextarea
            v-if="editingField.multiline"
            v-model="editingFieldValue"
            :placeholder="editingField.placeholder"
            rows="4"
            class="w-full"
          />
          <UInput
            v-else
            v-model="editingFieldValue"
            :placeholder="editingField.placeholder"
            class="w-full"
          />

          <div v-if="editingField.type === 'icon'" class="mt-4">
            <p class="text-sm text-slate-500 dark:text-slate-400 mb-2">
              Common icons:
            </p>
            <div class="flex flex-wrap gap-2">
              <button
                type="button"
                v-for="icon in commonIcons"
                :key="icon"
                @click="editingFieldValue = icon"
                class="p-2 border border-slate-200 dark:border-slate-700 rounded hover:bg-slate-100 dark:hover:bg-slate-700"
              >
                <UIcon :name="icon" class="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        <template #footer>
          <div class="flex justify-end gap-2">
            <UButton
              type="button"
              color="gray"
              @click="isEditModalOpen = false"
            >
              Cancel
            </UButton>
            <UButton type="button" color="primary" @click="saveEdit">
              Save
            </UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>

<script setup>
// Define props to receive product data
const props = defineProps({
  currentProduct: {
    type: Object,
    default: () => ({}),
  },
  isEditable: {
    type: Boolean,
    default: false, // Keep this default for API compatibility
  },
});

// Make edit mode active by default regardless of the prop value
const editModeActive = ref(true); // Changed from props.isEditable to true

// Function to toggle edit mode

// Import necessary composables
const cart = useStoreCart();
const toast = useToast();
const { user } = useAuth();

// Emit events for editor interactions
const emit = defineEmits(["update:section", "update:content"]);

// Editor data to store all editable fields
const editorData = reactive({
  benefits_title: "",
  benefits_cta: "",
  faqs_title: "",
  faqs_subtitle: "",
  cta_title: "",
  cta_subtitle: "",
  cta_button_text: "",
  cta_button_subtext: "",
  cta_badge1: "",
  cta_badge2: "",
  cta_badge3: "",
});

// Store original data for reset functionality
const originalEditorData = ref({});
const originalBenefits = ref([]);
const originalFaqs = ref([]);
const originalTrustBadges = ref([]);

// For benefits section
const benefits = ref([
  {
    title: "Premium Quality",
    description:
      "Crafted with the highest quality materials for exceptional durability and performance.",
    icon: "i-heroicons-sparkles",
  },
  {
    title: "Fast Results",
    description:
      "Experience immediate benefits and see results faster than with competing products.",
    icon: "i-heroicons-rocket-launch",
  },
  {
    title: "Satisfaction Guarantee",
    description:
      "Not completely satisfied? Return within 30 days for a full refund, no questions asked.",
    icon: "i-heroicons-check-badge",
  },
]);

// For FAQs section
const editableFaqs = ref([
  {
    label: "How long is the warranty period?",
    content:
      "Our product comes with a full 1-year warranty that covers all manufacturing defects and normal wear and tear. We stand behind the quality of our products.",
    icon: "i-heroicons-shield-check",
  },
  {
    label: "What payment methods do you accept?",
    content:
      "We accept all major credit cards, mobile banking, bKash, Nagad, and bank transfers. All payments are processed securely.",
    icon: "i-heroicons-credit-card",
  },
  {
    label: "How long does delivery take?",
    content:
      "Delivery within Dhaka typically takes 2-3 business days. For locations outside Dhaka, please allow 3-5 business days for your order to arrive.",
    icon: "i-heroicons-truck",
  },
  {
    label: "Is this product suitable for commercial use?",
    content:
      "Yes, our product is designed for both personal and commercial use. The durable construction ensures it can withstand heavy usage in commercial settings.",
    icon: "i-heroicons-building-storefront",
  },
]);

// Common icons for the editor
const commonIcons = [
  "i-heroicons-sparkles",
  "i-heroicons-rocket-launch",
  "i-heroicons-check-badge",
  "i-heroicons-shield-check",
  "i-heroicons-light-bulb",
  "i-heroicons-star",
  "i-heroicons-heart",
  "i-heroicons-truck",
  "i-heroicons-credit-card",
  "i-heroicons-currency-dollar",
];

// Trust badges for the final CTA section
const trust_badges = ref([
  {
    id: "payment",
    text: "Secure Payment",
    icon: "i-heroicons-credit-card",
    enabled: true,
    description: "Emphasize the security of your payment process",
    editorField: "cta_badge1", 
  },
  {
    id: "guarantee",
    text: "Money-Back Guarantee",
    icon: "i-heroicons-shield-check",
    enabled: true,
    description: "Build customer confidence with a guarantee",
    editorField: "cta_badge2", 
  },
  {
    id: "delivery",
    text: "Fast Delivery",
    icon: "i-heroicons-truck",
    enabled: true,
    description: "Highlight your quick shipping options",
    editorField: "cta_badge3", 
  },
]);

// Edit modal state
const isEditModalOpen = ref(false);
const editingField = ref({
  key: "",
  label: "",
  value: "",
  placeholder: "",
  multiline: false,
  type: "text",
});
const editingFieldValue = ref("");
const editingBenefitIndex = ref(-1);

// Trust Badges Editor Modal state
const isTrustBadgeModalOpen = ref(false);

// Saving state
const isSaving = ref(false);

// Add to cart functionality
function addToCart(product, quantity) {
  if (editModeActive.value) {
    toast.add({
      title: "Editor Mode",
      description: "This button would normally add items to cart",
      color: "blue",
      timeout: 3000,
    });
    return;
  }

  cart.addProduct(product, quantity);
  toast.add({
    title: "Added to Cart",
    description: `${product.name} has been added to your cart`,
    color: "green",
    timeout: 3000,
  });
}

// Edit a general field
function editField(key, value, multiline = false) {
  if (!editModeActive.value) return;

  const labels = {
    benefits_title: "Benefits Title",
    benefits_cta: "Benefits Button Text",
    faqs_title: "FAQs Title",
    faqs_subtitle: "FAQs Subtitle",
    cta_title: "CTA Title",
    cta_subtitle: "CTA Subtitle",
    cta_button_text: "Button Text",
    cta_button_subtext: "Button Subtext",
    cta_badge1: "Badge 1 Text",
    cta_badge2: "Badge 2 Text",
    cta_badge3: "Badge 3 Text",
  };

  editingField.value = {
    key,
    label: labels[key] || key,
    value: value,
    placeholder: value,
    multiline: multiline || key.includes("Subtitle") || key === "ctaSubtitle",
    type: "text",
  };

  editingFieldValue.value = value;
  isEditModalOpen.value = true;
}

// Edit a benefit field
function editBenefit(index, field, value) {
  if (!editModeActive.value) return;

  const labels = {
    title: "Benefit Title",
    description: "Benefit Description",
    icon: "Benefit Icon",
  };

  editingBenefitIndex.value = index;

  editingField.value = {
    key: field,
    label: labels[field] || field,
    value: value,
    placeholder: value,
    multiline: field === "description",
    type: field === "icon" ? "icon" : "text",
  };

  editingFieldValue.value = value;
  isEditModalOpen.value = true;
}

// Open Trust Badge Editor Modal
function openTrustBadgeEditor() {
  // Sync editor data to trust badges before opening modal
  trust_badges.value.forEach((badge) => {
    if (badge.editorField && editorData[badge.editorField]) {
      badge.text = editorData[badge.editorField];
    }
  });

  isTrustBadgeModalOpen.value = true;
}

// Save Trust Badges changes
function saveTrustBadges() {
  // Update editorData fields with badge text values
  trust_badges.value.forEach((badge) => {
    if (badge.editorField) {
      editorData[badge.editorField] = badge.enabled ? badge.text : "";
    }
  });

  isTrustBadgeModalOpen.value = false;

  // Emit content update after saving
  emitContentUpdate();

  toast.add({
    title: "Trust Badges Updated",
    description: "Your trust badge settings have been updated.",
    color: "green",
    timeout: 3000,
  });
}

// Save the current edit
const originalSaveEdit = saveEdit;
function saveEdit() {
  console.log("Before saving edit:", {
    editingField: editingField.value,
    editingFieldValue: editingFieldValue.value,
    editingBenefitIndex: editingBenefitIndex.value,
  });

  if (editingBenefitIndex.value !== -1) {
    // Editing a benefit
    const index = editingBenefitIndex.value;
    const field = editingField.value.key;

    if (!benefits.value[index]) {
      benefits.value[index] = {
        title: "",
        description: "",
        icon: "i-heroicons-sparkles",
      };
    }

    benefits.value[index][field] = editingFieldValue.value;
    editingBenefitIndex.value = -1;
  } else {
    // Editing a general field
    const key = editingField.value.key;
    editorData[key] = editingFieldValue.value;
  }

  emitContentUpdate();

  // Close the modal
  isEditModalOpen.value = false;

  // Save current state as original data
  saveOriginalState();

  toast.add({
    title: "Content Updated",
    description: "Your changes have been applied",
    color: "green",
    timeout: 3000,
  });

  console.log("After saving edit:", {
    editorData,
    benefits: benefits.value,
    faqs: editableFaqs.value,
    trust_badges: trust_badges.value,
  });
}

// Emit content update with detailed logging
function emitContentUpdate() {
  // Create compiled data object from all editor components
  const compiledData = {
    ...editorData,
    benefits: benefits.value,
    faqs: editableFaqs.value,
    trust_badges: trust_badges.value,
  };

  console.log("Emitting update:content event with data:", compiledData);

  // Emit update event for parent components
  emit("update:content", compiledData);
}

// Reset changes to original state
function resetChanges() {
  if (confirm("Are you sure you want to reset all changes?")) {
    // Reset editor data
    Object.keys(editorData).forEach((key) => {
      editorData[key] = originalEditorData.value[key] || "";
    });

    // Reset benefits
    benefits.value = JSON.parse(JSON.stringify(originalBenefits.value));

    // Reset FAQs
    editableFaqs.value = JSON.parse(JSON.stringify(originalFaqs.value));

    // Reset trust badges
    trust_badges.value = JSON.parse(JSON.stringify(originalTrustBadges.value));

    toast.add({
      title: "Changes Reset",
      description: "All changes have been reset to the last saved state.",
      color: "blue",
      timeout: 3000,
    });
  }
}

// Save current state as original
function saveOriginalState() {
  originalEditorData.value = { ...editorData };
  originalBenefits.value = JSON.parse(JSON.stringify(benefits.value));
  originalFaqs.value = JSON.parse(JSON.stringify(editableFaqs.value));
  originalTrustBadges.value = JSON.parse(JSON.stringify(trust_badges.value));
}

// Initialize when component is mounted
onMounted(() => {
  // If the product has existing editor data, populate the form
  if (props.currentProduct.editorData) {
    // Populate editor data fields
    Object.keys(editorData).forEach((key) => {
      if (props.currentProduct.editorData[key]) {
        editorData[key] = props.currentProduct.editorData[key];
      }
    });

    // Populate benefits
    if (props.currentProduct.editorData.benefits?.length) {
      benefits.value = [...props.currentProduct.editorData.benefits];
    }

    // Populate FAQs
    if (props.currentProduct.editorData.faqs?.length) {
      editableFaqs.value = [...props.currentProduct.editorData.faqs];
    }

    // Populate trust badges
    if (props.currentProduct.editorData.trust_badges?.length) {
      trust_badges.value = [...props.currentProduct.editorData.trust_badges];
    } else {
      // If no trust badges in editorData but badge text exists, update trust badges
      trust_badges.value.forEach((badge) => {
        if (badge.editorField && editorData[badge.editorField]) {
          badge.text = editorData[badge.editorField];
          badge.enabled = Boolean(editorData[badge.editorField]);
        }
      });
    }
  }

  // Save original state for reset functionality
  saveOriginalState();
});

// Update the saveChanges function to log data and emit events properly
async function saveChanges() {
  isSaving.value = true;

  try {
    // Create compiled data object with all editable content
    const compiledData = {
      ...editorData,
      benefits: [...benefits.value],
      faqs: [...editableFaqs.value],
      trust_badges: [...trust_badges.value],
    };

    // Log the data being saved (this will show in browser console)
    console.log("Saving Advanced Editor data:", compiledData);

    // Emit update event to parent component
    emitContentUpdate();

    // Show success message
    toast.add({
      title: "Changes Saved",
      description: "Your product editor changes have been saved successfully",
      color: "green",
      timeout: 3000,
    });

    // Save current state as original data for reset functionality
    saveOriginalState();
  } catch (error) {
    console.error("Error saving product editor data:", error);
    toast.add({
      title: "Error",
      description: "Failed to save changes. Please try again.",
      color: "red",
      timeout: 5000,
    });
  } finally {
    isSaving.value = false;
  }
}

// Watch for changes to editor data
watch(
  editorData,
  (newValue, oldValue) => {
    console.log("Editor data changed:", {
      newValue,
      oldValue,
      changedFields: getChangedFields(newValue, oldValue),
    });
  },
  { deep: true }
);

// Watch for changes to benefits
watch(
  benefits,
  (newValue, oldValue) => {
    console.log("Benefits changed:", {
      newValue,
      oldValue,
      diff: getDiffBetweenArrays(newValue, oldValue),
    });
  },
  { deep: true }
);

// Watch for changes to FAQs
watch(
  editableFaqs,
  (newValue, oldValue) => {
    console.log("FAQs changed:", {
      newValue,
      oldValue,
      diff: getDiffBetweenArrays(newValue, oldValue),
    });
  },
  { deep: true }
);

// Watch for changes to trust badges
watch(
  trust_badges,
  (newValue, oldValue) => {
    console.log("Trust badges changed:", {
      newValue,
      oldValue,
      diff: getDiffBetweenArrays(newValue, oldValue),
    });
  },
  { deep: true }
);

// Helper function to identify changed fields between objects
function getChangedFields(newObj, oldObj) {
  if (!oldObj) return { allFieldsNew: true };

  const changes = {};
  Object.keys(newObj).forEach((key) => {
    if (JSON.stringify(newObj[key]) !== JSON.stringify(oldObj[key])) {
      changes[key] = {
        from: oldObj[key],
        to: newObj[key],
      };
    }
  });

  return changes;
}

// Helper function to identify differences between arrays
function getDiffBetweenArrays(newArr, oldArr) {
  if (!oldArr || oldArr.length === 0)
    return { allItemsNew: true, items: newArr };
  if (newArr.length !== oldArr.length)
    return {
      lengthChanged: true,
      newLength: newArr.length,
      oldLength: oldArr.length,
    };

  const changes = newArr
    .map((item, index) => {
      if (index >= oldArr.length) return { newItem: item };

      const oldItem = oldArr[index];
      const changedFields = {};
      let hasChanges = false;

      Object.keys(item).forEach((key) => {
        if (JSON.stringify(item[key]) !== JSON.stringify(oldItem[key])) {
          changedFields[key] = {
            from: oldItem[key],
            to: item[key],
          };
          hasChanges = true;
        }
      });

      return hasChanges ? { index, changedFields } : null;
    })
    .filter(Boolean);

  return changes.length > 0 ? changes : { noChanges: true };
}

// Function to add a new FAQ
function addFaq() {
  editableFaqs.value.push({
    label: "New Question",
    content: "Answer to the question",
    icon: "i-heroicons-question-mark-circle",
  });
}

// Function to remove a FAQ at the specified index
function removeFaq(index) {
  if (index >= 0 && index < editableFaqs.value.length) {
    editableFaqs.value.splice(index, 1);

    // Update editor data after removing
    emitContentUpdate();
  }
}

// Keep your existing code like countdown timer, sticky button, etc.
</script>

<style scoped>
.benefit-card {
  @apply bg-white dark:bg-slate-800 p-6 rounded-xl shadow-md text-center;
}

.icon-container {
  @apply w-16 h-16 mx-auto bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mb-4;
}

.feature-item {
  @apply flex items-center gap-2 bg-white dark:bg-slate-800 p-3 rounded-lg shadow-sm;
}

/* Animation for pulse effect */
@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.8;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Animation for sticky button */
.translate-y-0 {
  transform: translateY(0);
}

.translate-y-full {
  transform: translateY(100%);
}
</style>
