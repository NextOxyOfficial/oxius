<!-- filepath: c:\Users\NextOxy\Desktop\office\oxy-us\frontend\components\common\ProductDetailEditor.vue -->
<template>
  <div
    class="product-detail-editor bg-slate-100 dark:bg-slate-900 rounded-xl overflow-hidden"
  >
    <!-- Toolbar -->
    <div
      class="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 p-3 flex items-center justify-between sticky top-0 z-10"
    >
      <div class="flex items-center gap-2">
        <UButton
          size="sm"
          color="gray"
          variant="soft"
          icon="i-heroicons-eye"
          @click="isPreview = !isPreview"
          :class="{ 'bg-primary-100 dark:bg-primary-900': isPreview }"
        >
          {{ isPreview ? "Exit Preview" : "Preview" }}
        </UButton>

        <div
          class="h-6 border-r border-slate-200 dark:border-slate-700 mx-1"
        ></div>

        <div class="flex gap-1">
          <UButton
            size="xs"
            color="gray"
            variant="ghost"
            icon="i-heroicons-document-duplicate"
            @click="duplicateSection"
            v-tooltip="'Duplicate section'"
          />
        </div>
      </div>

      <div class="flex items-center gap-2">
        <UBadge color="amber" variant="soft" size="sm">
          <UIcon name="i-heroicons-light-bulb" class="w-3.5 h-3.5 mr-1" />
          Click any text to edit
        </UBadge>
        <UButton size="sm" color="gray" variant="soft" @click="resetChanges">
          Reset Changes
        </UButton>
      </div>
    </div>

    <!-- Editor or Preview -->
    <div class="min-h-[700px] max-h-[700px] overflow-auto">
      <!-- Preview mode -->
      <div
        v-if="isPreview"
        class="bg-white dark:bg-slate-900 p-4 w-full h-full"
      >
        <ProductDetailsCard2 :current-product="previewProduct" />
      </div>

      <!-- Editor mode -->
      <div v-else class="p-6 bg-slate-100 dark:bg-slate-900">
        <div
          class="bg-white dark:bg-slate-800 rounded-xl shadow-sm overflow-hidden"
        >
          <!-- Hero Section -->
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <h3 class="text-sm font-medium mb-2">Hero Section</h3>
            <div class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3">
              <!-- Hero Title Editable -->
              <EditorField
                v-model="sections.hero.title"
                label="Product Title"
                type="text"
                :placeholder="productData.name"
              />

              <!-- Short Description Editable -->
              <EditorField
                v-model="sections.hero.shortDescription"
                label="Short Description"
                type="textarea"
                :placeholder="
                  productData.short_description ||
                  'A brief product description that highlights key benefits'
                "
              />

              <!-- Hero CTA Button Text -->
              <EditorField
                v-model="sections.hero.buttonText"
                label="Button Text"
                type="text"
                placeholder="Buy Now"
              />

              <!-- Hero Background Classes -->
              <EditorField
                v-model="sections.hero.bgClasses"
                label="Background Style"
                type="text"
                placeholder="bg-gradient-to-br from-slate-900 to-slate-800"
              />
            </div>
          </div>

          <!-- Countdown Section -->
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">Limited Time Offer</h3>
              <USwitch v-model="sections.countdown.enabled" size="sm" />
            </div>

            <div
              v-if="sections.countdown.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.countdown.title"
                label="Countdown Title"
                type="text"
                placeholder="Limited Time Offer"
              />

              <div class="grid grid-cols-3 gap-2 mt-3">
                <EditorField
                  v-model="sections.countdown.hours"
                  label="Hours"
                  type="number"
                  min="0"
                  placeholder="12"
                />

                <EditorField
                  v-model="sections.countdown.minutes"
                  label="Minutes"
                  type="number"
                  min="0"
                  max="59"
                  placeholder="45"
                />

                <EditorField
                  v-model="sections.countdown.seconds"
                  label="Seconds"
                  type="number"
                  min="0"
                  max="59"
                  placeholder="22"
                />
              </div>

              <!-- Background Style -->
              <EditorField
                v-model="sections.countdown.bgClasses"
                label="Background Style"
                type="text"
                placeholder="bg-amber-50 dark:bg-amber-900/20"
              />
            </div>
          </div>

          <!-- Description Section -->
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">Product Description</h3>
              <USwitch v-model="sections.description.enabled" size="sm" />
            </div>

            <div
              v-if="sections.description.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.description.title"
                label="Section Title"
                type="text"
                placeholder="Description"
              />

              <div class="mt-3">
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
                >
                  Content
                </label>
                <CommonEditor
                  :content="sections.description.content"
                  @updateContent="
                    (content) => (sections.description.content = content)
                  "
                  class="border border-slate-200 dark:border-slate-700 rounded-lg overflow-hidden text-left p-2 min-h-[150px]"
                />
              </div>

              <!-- Background Style -->
              <EditorField
                v-model="sections.description.bgClasses"
                label="Background Style"
                type="text"
                placeholder="bg-slate-50 dark:bg-slate-800/20"
              />
            </div>
          </div>

          <!-- Benefits Section -->
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">Key Benefits</h3>
              <USwitch v-model="sections.benefits.enabled" size="sm" />
            </div>

            <div
              v-if="sections.benefits.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.benefits.title"
                label="Section Title"
                type="text"
                placeholder="Why Choose Our Product?"
              />

              <div class="mt-4 space-y-3">
                <div
                  v-for="(benefit, index) in sections.benefits.items"
                  :key="index"
                  class="border border-slate-200 dark:border-slate-700 rounded-md p-3 bg-white dark:bg-slate-800"
                >
                  <div class="flex justify-between items-center mb-2">
                    <h4 class="text-sm font-medium">Benefit {{ index + 1 }}</h4>
                    <UButton
                      v-if="sections.benefits.items.length > 1"
                      color="red"
                      variant="ghost"
                      icon="i-heroicons-trash"
                      size="xs"
                      class="h-6 w-6"
                      @click="removeBenefit(index)"
                    />
                  </div>

                  <div class="space-y-3">
                    <EditorField
                      v-model="benefit.title"
                      label="Title"
                      type="text"
                      placeholder="Benefit Title"
                    />

                    <EditorField
                      v-model="benefit.description"
                      label="Description"
                      type="textarea"
                      placeholder="Describe this benefit"
                    />

                    <EditorField
                      v-model="benefit.icon"
                      label="Icon"
                      type="text"
                      placeholder="i-heroicons-sparkles"
                    />
                  </div>
                </div>

                <UButton
                  block
                  color="gray"
                  variant="soft"
                  @click="addBenefit"
                  size="sm"
                >
                  <UIcon name="i-heroicons-plus" class="w-3.5 h-3.5 mr-1" />
                  Add Benefit
                </UButton>
              </div>
            </div>
          </div>

          <!-- Shipping Section -->
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">Shipping Information</h3>
              <USwitch v-model="sections.shipping.enabled" size="sm" />
            </div>

            <div
              v-if="sections.shipping.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.shipping.title"
                label="Section Title"
                type="text"
                placeholder="Shipping Information"
              />

              <EditorField
                v-model="sections.shipping.subtitle"
                label="Section Subtitle"
                type="text"
                placeholder="Fast and reliable delivery options"
              />

              <EditorField
                v-model="sections.shipping.freeShippingMessage"
                label="Free Shipping Message"
                type="textarea"
                placeholder="Orders over ৳5,000 qualify for free delivery nationwide."
              />

              <!-- Background Style -->
              <EditorField
                v-model="sections.shipping.bgClasses"
                label="Background Style"
                type="text"
                placeholder="bg-slate-50 dark:bg-slate-800/30"
              />
            </div>
          </div>

          <!-- Reviews Section -->
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">Reviews Section</h3>
              <USwitch v-model="sections.reviews.enabled" size="sm" />
            </div>

            <div
              v-if="sections.reviews.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.reviews.title"
                label="Section Title"
                type="text"
                placeholder="Customer Reviews"
              />

              <EditorField
                v-model="sections.reviews.subtitle"
                label="Section Subtitle"
                type="text"
                placeholder="Join thousands of satisfied customers who have experienced the difference"
              />

              <EditorField
                v-model="sections.reviews.reviewsPerPage"
                label="Reviews Per Page"
                type="number"
                min="1"
                max="12"
                placeholder="3"
              />
            </div>
          </div>

          <!-- FAQ Section -->
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">FAQs</h3>
              <USwitch v-model="sections.faqs.enabled" size="sm" />
            </div>

            <div
              v-if="sections.faqs.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.faqs.title"
                label="Section Title"
                type="text"
                placeholder="Frequently Asked Questions"
              />

              <EditorField
                v-model="sections.faqs.subtitle"
                label="Section Subtitle"
                type="text"
                placeholder="Everything you need to know about our product"
              />

              <!-- Show sample FAQs from the product data -->
              <div class="mt-4">
                <div class="text-sm font-medium mb-2">Your Added FAQs:</div>
                <div class="space-y-2">
                  <div
                    v-for="(faq, i) in productData.faqs"
                    :key="i"
                    class="bg-white dark:bg-slate-800 p-2 rounded border border-slate-200 dark:border-slate-700"
                  >
                    <div class="text-sm font-medium">{{ faq.label }}</div>
                    <div
                      class="text-xs text-slate-500 dark:text-slate-400 mt-1"
                    >
                      {{ faq.content }}
                    </div>
                  </div>
                </div>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-2">
                  FAQs are managed in the basic information step
                </p>
              </div>
            </div>
          </div>

          <!-- CTA Section -->
          <div class="p-4">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">Call to Action</h3>
              <USwitch v-model="sections.cta.enabled" size="sm" />
            </div>

            <div
              v-if="sections.cta.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.cta.title"
                label="CTA Title"
                type="text"
                placeholder="Ready to Experience the Difference?"
              />

              <EditorField
                v-model="sections.cta.subtitle"
                label="CTA Subtitle"
                type="text"
                placeholder="Join thousands of satisfied customers who have already transformed their experience."
              />

              <EditorField
                v-model="sections.cta.buttonText"
                label="Button Text"
                type="text"
                placeholder="Order Now & Save"
              />

              <EditorField
                v-model="sections.cta.bgClasses"
                label="Background Style"
                type="text"
                placeholder="bg-gradient-to-br from-primary-600 to-primary-800"
              />
            </div>
          </div>

          <!-- Sticky Button Section -->
          <div class="p-4 border-t border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium">Sticky Buy Button</h3>
              <USwitch v-model="sections.stickyButton.enabled" size="sm" />
            </div>

            <div
              v-if="sections.stickyButton.enabled"
              class="bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3"
            >
              <EditorField
                v-model="sections.stickyButton.buttonText"
                label="Button Text"
                type="text"
                placeholder="Buy Now"
              />

              <EditorField
                v-model="sections.stickyButton.bgClasses"
                label="Button Style"
                type="text"
                placeholder="bg-gradient-to-r from-primary-500 to-primary-600"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from "vue";

const props = defineProps({
  productData: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["update:content"]);

const isPreview = ref(false);

// Initial sections data based on product-details-card2.vue structure
const sections = ref({
  hero: {
    title: props.productData.name || "",
    shortDescription: props.productData.short_description || "",
    buttonText: "Buy Now",
    bgClasses: "bg-gradient-to-br from-slate-900 to-slate-800",
  },
  countdown: {
    enabled: true,
    title: "Limited Time Offer",
    hours: "12",
    minutes: "45",
    seconds: "22",
    bgClasses: "bg-amber-50 dark:bg-amber-900/20",
  },
  description: {
    enabled: true,
    title: "Description",
    content: props.productData.description || "",
    bgClasses: "bg-slate-50 dark:bg-slate-800/20",
  },
  benefits: {
    enabled: true,
    title: "Why Choose Our Product?",
    items: [
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
    ],
  },
  shipping: {
    enabled: true,
    title: "Shipping Information",
    subtitle: "Fast and reliable delivery options",
    freeShippingMessage:
      "Orders over ৳5,000 qualify for free delivery nationwide.",
    bgClasses: "bg-slate-50 dark:bg-slate-800/30",
  },
  reviews: {
    enabled: true,
    title: "Customer Reviews",
    subtitle:
      "Join thousands of satisfied customers who have experienced the difference",
    reviewsPerPage: 3,
  },
  faqs: {
    enabled: true,
    title: "Frequently Asked Questions",
    subtitle: "Everything you need to know about our product",
  },
  cta: {
    enabled: true,
    title: "Ready to Experience the Difference?",
    subtitle:
      "Join thousands of satisfied customers who have already transformed their experience.",
    buttonText: "Order Now & Save",
    bgClasses: "bg-gradient-to-br from-primary-600 to-primary-800",
  },
  stickyButton: {
    enabled: true,
    buttonText: "Buy Now",
    bgClasses: "bg-gradient-to-r from-primary-500 to-primary-600",
  },
});

// Keep a copy of the original settings for reset functionality
const originalSections = JSON.parse(JSON.stringify(sections.value));

// Generate preview product data
const previewProduct = computed(() => {
  return {
    ...props.productData,
    name: sections.value.hero.title || props.productData.name,
    short_description:
      sections.value.hero.shortDescription ||
      props.productData.short_description,
    description:
      sections.value.description.content || props.productData.description,
    // Add other customized fields
    editorData: sections.value,
    faqs: props.productData.faqs || [],
  };
});

// Add a new benefit
function addBenefit() {
  sections.value.benefits.items.push({
    title: "",
    description: "",
    icon: "i-heroicons-sparkles",
  });
}

// Remove a benefit
function removeBenefit(index) {
  sections.value.benefits.items.splice(index, 1);
}

// Duplicate a section (placeholder for future functionality)
function duplicateSection() {
  alert("Duplication functionality will be available in a future update");
}

// Reset changes to original state
function resetChanges() {
  if (confirm("Are you sure you want to reset all changes?")) {
    sections.value = JSON.parse(JSON.stringify(originalSections));
  }
}

// Watch for changes and emit to parent
watch(
  sections,
  (newValue) => {
    emit("update:content", newValue);
  },
  { deep: true }
);

// Initialize with product data if available
onMounted(() => {
  if (props.productData.editorData) {
    sections.value = props.productData.editorData;
  }
});
</script>

<style scoped>
.product-detail-editor {
  width: 100%;
  border: 1px solid rgba(0, 0, 0, 0.1);
}
</style>
