<template>
  <UContainer>
    <div
      class="max-w-4xl mx-auto bg-white rounded-2xl shadow-xl overflow-hidden border h-44 flex flex-col gap-3 items-center justify-center my-8"
      v-if="cart.products.length === 0"
    >
      <p>You have no products in the cart. Start adding some.</p>
      <UButton
        to="/"
        label="Back to Home"
        variant="link"
        icon="i-heroicons-arrow-long-left-20-solid"
        :trailing="false"
      />
    </div>

    <div
      class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 py-12 px-2 lg:px-8"
      v-else
    >
      <Transition
        appear
        enter-active-class="transition duration-500 ease-out"
        enter-from-class="opacity-0 translate-y-5"
        enter-to-class="opacity-100 translate-y-0"
      >
        <div
          class="max-w-4xl mx-auto bg-white rounded-2xl shadow-xl overflow-hidden"
        >
          <!-- Header -->
          <div class="relative overflow-hidden">
            <div
              class="absolute inset-0 bg-[url('/placeholder.svg?height=200&width=1000')] bg-cover bg-center opacity-20"
            ></div>
            <div
              class="bg-gradient-to-r from-violet-600 to-indigo-600 p-8 relative z-10"
            >
              <Transition
                appear
                enter-active-class="transition duration-400 delay-200 ease-out"
                enter-from-class="opacity-0 translate-y-3"
                enter-to-class="opacity-100 translate-y-0"
              >
                <div>
                  <h1 class="text-3xl font-bold text-white">Checkout</h1>
                  <p class="text-purple-100 mt-2">
                    Complete your purchase to experience premium quality
                  </p>
                </div>
              </Transition>

              <!-- Checkout Steps -->
              <div class="flex items-center mt-6 text-sm text-white">
                <div class="flex items-center">
                  <div
                    class="bg-white bg-opacity-30 rounded-full h-6 w-6 flex items-center justify-center"
                  >
                    <ShoppingBag class="h-3 w-3 text-white" />
                  </div>
                  <span class="ml-2">Cart</span>
                </div>
                <div class="w-8 h-[2px] bg-white bg-opacity-30 mx-2"></div>
                <div class="flex items-center">
                  <div
                    class="bg-white rounded-full h-6 w-6 flex items-center justify-center"
                  >
                    <Check class="h-3 w-3 text-indigo-600" />
                  </div>
                  <span class="ml-2 font-medium">Checkout</span>
                </div>
                <div class="w-8 h-[2px] bg-white bg-opacity-30 mx-2"></div>
                <div class="flex items-center opacity-60">
                  <div
                    class="border-2 border-white border-opacity-30 rounded-full h-6 w-6 flex items-center justify-center"
                  >
                    <span class="text-xs">3</span>
                  </div>
                  <span class="ml-2">Confirmation</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Main Form -->
          <form @submit.prevent="processCheckout" class="p-3 sm:p-8">
            <div class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-8">
              <!-- Left Column: Customer Information -->
              <div class="space-y-4">
                <!-- Product Details -->
                <Transition
                  appear
                  enter-active-class="transition duration-500 delay-300 ease-out"
                  enter-from-class="opacity-0"
                  enter-to-class="opacity-100"
                >
                  <div>
                    <h2
                      class="text-xl font-semibold text-gray-900 border-b border-gray-200 pb-3 mb-4 flex items-center"
                    >
                      <ShoppingBag class="mr-2 h-5 w-5 text-indigo-500" />
                      Your Products
                    </h2>

                    <div class="space-y-4">
                      <Transition-group
                        appear
                        enter-active-class="transition duration-500 ease-out"
                        enter-from-class="opacity-0 translate-y-5"
                        enter-to-class="opacity-100 translate-y-0"
                        move-class="transition duration-500"
                      >
                        <div
                          v-for="(product, index) in products"
                          :key="product.id"
                          class="flex items-center space-x-4 p-4 border border-gray-100 rounded-xl hover:border-indigo-100 hover:bg-indigo-50/30 transition-all duration-300 group"
                          :style="{ transitionDelay: `${index * 100 + 400}ms` }"
                        >
                          <div class="relative overflow-hidden rounded-xl">
                            <img
                              v-if="product.image_details"
                              :src="
                                product?.image_details[0]?.image ||
                                '/placeholder.svg'
                              "
                              :alt="product.name"
                              class="w-20 h-20 object-cover rounded-xl shadow-sm transition-transform duration-300 group-hover:scale-105"
                            />
                            <div
                              class="absolute inset-0 bg-gradient-to-tr from-indigo-500/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                            ></div>
                          </div>
                          <div class="flex-1">
                            <h3 class="font-medium text-gray-900">
                              {{ product.name }}
                            </h3>
                            <div
                              v-html="product.description"
                              class="text-gray-500 text-sm"
                            ></div>
                            <div class="flex items-center justify-between mt-2">
                              <div class="text-indigo-600 font-semibold">
                                ৳{{ product.sale_price }}
                              </div>
                              <div
                                class="flex items-center border border-gray-200 rounded-lg overflow-hidden shadow-sm"
                              >
                                <button
                                  type="button"
                                  @click="decreaseQuantity(index)"
                                  class="px-3 py-1 bg-gray-50 hover:bg-gray-100 text-gray-700 transition-colors duration-200 focus:outline-none"
                                  :disabled="product.count <= 1"
                                >
                                  <Minus class="h-3 w-3" />
                                </button>
                                <span
                                  class="px-3 py-1 bg-white text-gray-800 min-w-[40px] text-center"
                                  >{{ product.count }}</span
                                >
                                <button
                                  type="button"
                                  @click="increaseQuantity(index)"
                                  class="px-3 py-1 bg-gray-50 hover:bg-gray-100 text-gray-700 transition-colors duration-200 focus:outline-none"
                                >
                                  <Plus class="h-3 w-3" />
                                </button>
                              </div>
                            </div>
                          </div>
                        </div>
                      </Transition-group>
                    </div>
                  </div>
                </Transition>

                <!-- Customer Information -->
                <Transition
                  appear
                  enter-active-class="transition duration-500 delay-500 ease-out"
                  enter-from-class="opacity-0"
                  enter-to-class="opacity-100"
                >
                  <div>
                    <h2
                      class="text-xl font-semibold text-gray-900 border-b border-gray-200 pb-3 flex items-center"
                    >
                      <MapPin class="mr-2 h-5 w-5 text-indigo-500" />
                      Customer Information
                    </h2>
                    <div class="mt-3 space-y-3">
                      <div class="relative">
                        <label
                          for="name"
                          class="block text-sm font-medium text-gray-700 mb-1"
                        >
                          Full Name
                        </label>
                        <input
                          id="name"
                          v-model="form.name"
                          type="text"
                          required
                          :class="[
                            'block w-full px-4 py-1.5 border rounded-lg shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200',
                            errors.name
                              ? 'border-red-300 ring-1 ring-red-300'
                              : 'border-gray-300',
                          ]"
                          placeholder="Enter your full name"
                        />
                        <p v-if="errors.name" class="mt-1 text-sm text-red-600">
                          {{ errors.name }}
                        </p>
                      </div>

                      <div class="relative">
                        <label
                          for="email"
                          class="block text-sm font-medium text-gray-700 mb-1"
                        >
                          Email
                        </label>
                        <input
                          id="phone"
                          v-model="form.email"
                          type="tel"
                          required
                          :class="[
                            'block w-full px-4 py-1.5 border rounded-lg shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200',
                            errors.email
                              ? 'border-red-300 ring-1 ring-red-300'
                              : 'border-gray-300',
                          ]"
                          placeholder="Enter your email"
                        />
                        <p
                          v-if="errors.email"
                          class="mt-1 text-sm text-red-600"
                        >
                          {{ errors.email }}
                        </p>
                      </div>
                      <div class="relative">
                        <label
                          for="phone"
                          class="block text-sm font-medium text-gray-700 mb-1"
                        >
                          Phone Number
                        </label>
                        <input
                          id="phone"
                          v-model="form.phone"
                          type="tel"
                          required
                          :class="[
                            'block w-full px-4 py-1.5 border rounded-lg shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200',
                            errors.phone
                              ? 'border-red-300 ring-1 ring-red-300'
                              : 'border-gray-300',
                          ]"
                          placeholder="Enter your phone number"
                        />
                        <p
                          v-if="errors.phone"
                          class="mt-1 text-sm text-red-600"
                        >
                          {{ errors.phone }}
                        </p>
                      </div>

                      <div class="relative">
                        <label
                          for="address"
                          class="block text-sm font-medium text-gray-700 mb-1"
                        >
                          Full Address
                        </label>
                        <textarea
                          id="address"
                          v-model="form.address"
                          rows="3"
                          required
                          :class="[
                            'block w-full px-4 py-1.5 border rounded-lg shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200',
                            errors.address
                              ? 'border-red-300 ring-1 ring-red-300'
                              : 'border-gray-300',
                          ]"
                          placeholder="Enter your complete delivery address"
                        ></textarea>
                        <p
                          v-if="errors.address"
                          class="mt-1 text-sm text-red-600"
                        >
                          {{ errors.address }}
                        </p>
                      </div>
                    </div>
                  </div>
                </Transition>
              </div>

              <!-- Right Column: Payment and Summary -->
              <div class="space-y-4">
                <Transition
                  appear
                  enter-active-class="transition duration-500 delay-400 ease-out"
                  enter-from-class="opacity-0 translate-x-5"
                  enter-to-class="opacity-100 translate-x-0"
                >
                  <div
                    :class="[
                      'transition-all duration-300',
                      isScrolled ? 'lg:sticky lg:top-4' : '',
                    ]"
                  >
                    <!-- Delivery Options -->
                    <div
                      v-if="products?.length && !products[0].is_free_delivery"
                      class="mb-6 overflow-hidden rounded-xl border border-gray-200 shadow-sm"
                    >
                      <div
                        class="bg-gradient-to-r from-indigo-50 to-purple-50 px-4 py-3"
                      >
                        <h2
                          class="text-lg font-semibold text-gray-900 flex items-center"
                        >
                          <Truck class="mr-2 h-5 w-5 text-indigo-500" />
                          Delivery Options
                        </h2>
                      </div>
                      <div class="p-4">
                        <div class="mt-2 space-y-3">
                          <div
                            :class="[
                              'relative flex p-4 rounded-lg border border-gray-200 hover:border-indigo-200 transition-all duration-200',
                              form.deliveryOption === 'inside'
                                ? 'bg-indigo-50/50 border-indigo-300'
                                : '',
                            ]"
                          >
                            <div
                              class="flex items-center h-5 rounded-full overflow-hidden"
                            >
                              <input
                                id="inside-dhaka"
                                v-model="form.deliveryOption"
                                type="radio"
                                value="inside"
                                class="size-5 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                              />
                            </div>
                            <div class="ml-3 flex flex-col">
                              <label
                                for="inside-dhaka"
                                class="font-medium text-gray-800"
                                >Inside Dhaka</label
                              >
                              <span class="text-gray-500 text-sm"
                                >Delivery within 24 hours</span
                              >

                              <span class="text-indigo-600 font-medium mt-1"
                                >Delivery fee: ৳{{
                                  products[0].delivery_fee_inside_dhaka
                                }}</span
                              >
                            </div>
                          </div>

                          <div
                            :class="[
                              'relative flex p-4 rounded-lg border border-gray-200 hover:border-indigo-200 transition-all duration-200',
                              form.deliveryOption === 'outside'
                                ? 'bg-indigo-50/50 border-indigo-300'
                                : '',
                            ]"
                          >
                            <div
                              class="flex items-center h-5 rounded-full overflow-hidden"
                            >
                              <input
                                id="outside-dhaka"
                                v-model="form.deliveryOption"
                                type="radio"
                                value="outside"
                                class="size-5 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                              />
                            </div>
                            <div class="ml-3 flex flex-col">
                              <label
                                for="outside-dhaka"
                                class="font-medium text-gray-800"
                                >Outside Dhaka</label
                              >
                              <span class="text-gray-500 text-sm"
                                >Delivery within 3-5 days</span
                              >
                              <span class="text-indigo-600 font-medium mt-1"
                                >Delivery fee: ৳{{
                                  products[0].delivery_fee_outside_dhaka
                                }}</span
                              >
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Payment Methods -->
                    <div
                      class="mb-6 overflow-hidden rounded-xl border border-gray-200 shadow-sm"
                    >
                      <div
                        class="bg-gradient-to-r from-indigo-50 to-purple-50 px-4 py-3"
                      >
                        <h2
                          class="text-lg font-semibold text-gray-900 flex items-center"
                        >
                          <CreditCard class="mr-2 h-5 w-5 text-indigo-500" />
                          Payment Method
                        </h2>
                      </div>
                      <div class="p-4">
                        <div class="mt-2 space-y-3">
                          <div
                            v-if="user?.user"
                            :class="[
                              'relative flex p-4 rounded-lg border border-gray-200 hover:border-indigo-200 transition-all duration-200',
                              form.paymentMethod === 'account'
                                ? 'bg-indigo-50/50 border-indigo-300'
                                : '',
                            ]"
                          >
                            <div
                              class="flex items-center h-5 rounded-full overflow-hidden"
                            >
                              <input
                                id="account-funds"
                                v-model="form.paymentMethod"
                                type="radio"
                                value="account"
                                class="h-5 w-5 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                              />
                            </div>

                            <div class="ml-3 flex flex-col">
                              <label
                                for="account-funds"
                                class="font-medium text-gray-800"
                                >Account Funds</label
                              >
                              <div class="flex items-center mt-1">
                                <span class="text-gray-500 text-sm mr-2"
                                  >Available balance:</span
                                >

                                <span class="text-indigo-600 font-medium"
                                  >৳{{ user?.user.balance }}</span
                                >
                              </div>
                            </div>
                          </div>

                          <div
                            :class="[
                              'relative flex p-4 rounded-lg border border-gray-200 hover:border-indigo-200 transition-all duration-200',
                              form.paymentMethod === 'cod'
                                ? 'bg-indigo-50/50 border-indigo-300'
                                : '',
                            ]"
                          >
                            <div
                              class="flex items-center h-5 rounded-full overflow-hidden"
                            >
                              <input
                                id="cod"
                                v-model="form.paymentMethod"
                                type="radio"
                                value="cod"
                                class="h-5 w-5 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                              />
                            </div>
                            <div class="ml-3 flex flex-col">
                              <label for="cod" class="font-medium text-gray-800"
                                >Cash on Delivery</label
                              >
                              <span class="text-gray-500 text-sm"
                                >Pay when you receive your order</span
                              >
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Order Summary -->
                    <div class="overflow-hidden rounded-xl border-0 shadow-lg">
                      <div
                        class="bg-gradient-to-r from-violet-600 to-indigo-600 px-4 py-3"
                      >
                        <h2
                          class="text-lg font-semibold text-white flex items-center"
                        >
                          <Wallet class="mr-2 h-5 w-5 text-white" />
                          Order Summary
                        </h2>
                      </div>
                      <div class="p-6 bg-gradient-to-b from-white to-slate-50">
                        <div class="space-y-2 mb-4">
                          <div class="flex justify-between py-2 text-gray-600">
                            <span>Products ({{ totalItems }})</span>
                            <span class="font-medium">৳{{ subtotal }}</span>
                          </div>
                          <div class="flex justify-between py-2 text-gray-600">
                            <span>Delivery Fee</span>
                            <span class="font-medium">৳{{ deliveryFee }}</span>
                          </div>
                        </div>

                        <div
                          class="flex justify-between py-3 border-t border-gray-200 mt-2 pt-2"
                        >
                          <span class="text-gray-800 font-medium">Total</span>
                          <span class="text-xl font-bold text-indigo-600"
                            >৳{{ total }}</span
                          >
                        </div>

                        <!-- Submit Button -->
                        <button
                          type="submit"
                          class="mt-6 w-full py-3 text-base font-medium text-white bg-gradient-to-r from-violet-600 to-indigo-600 hover:from-violet-700 hover:to-indigo-700 transition-all duration-300 transform hover:-translate-y-1 shadow-md hover:shadow-xl rounded-lg"
                        >
                          Complete Purchase
                        </button>

                        <p class="text-xs text-center text-gray-500 mt-4">
                          By completing this purchase, you agree to our
                          <NuxtLink
                            href="/terms"
                            class="text-indigo-600 hover:underline"
                            >Terms of Service</NuxtLink
                          >
                          and
                          <NuxtLink
                            href="/privacy"
                            class="text-indigo-600 hover:underline"
                            >Privacy Policy</NuxtLink
                          >
                        </p>
                      </div>
                    </div>
                  </div>
                </Transition>
              </div>
            </div>
          </form>
        </div>
      </Transition>

      <!-- Insufficient Funds Warning Modal -->
      <Transition
        enter-active-class="transition ease-out duration-300"
        enter-from-class="opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="transition ease-in duration-200"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <div
          v-if="showInsufficientFundsModal"
          class="fixed inset-0 z-10 overflow-y-auto"
          aria-labelledby="modal-title"
          role="dialog"
          aria-modal="true"
        >
          <div
            class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
          >
            <div
              class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
              aria-hidden="true"
              @click="showInsufficientFundsModal = false"
            ></div>
            <span
              class="hidden sm:inline-block sm:align-middle sm:h-screen"
              aria-hidden="true"
              >&#8203;</span
            >
            <Transition
              enter-active-class="transition ease-out duration-300"
              enter-from-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              enter-to-class="opacity-100 translate-y-0 sm:scale-100"
              leave-active-class="transition ease-in duration-200"
              leave-from-class="opacity-100 translate-y-0 sm:scale-100"
              leave-to-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            >
              <div
                v-if="showInsufficientFundsModal"
                class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
              >
                <div
                  class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-400 to-red-600"
                ></div>
                <div class="bg-white px-6 pt-6 pb-4 sm:p-6 sm:pb-4">
                  <div class="sm:flex sm:items-start">
                    <div
                      class="mx-auto flex-shrink-0 flex items-center justify-center h-14 w-14 rounded-full bg-red-100 sm:mx-0 sm:h-12 sm:w-12"
                    >
                      <svg
                        class="h-7 w-7 text-red-600"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                        />
                      </svg>
                    </div>
                    <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                      <h3
                        class="text-xl leading-6 font-semibold text-gray-900"
                        id="modal-title"
                      >
                        Insufficient Funds
                      </h3>
                      <div class="mt-3">
                        <p class="text-base text-gray-500">
                          Your account balance (৳{{ user?.user.balance }}) is
                          not sufficient to complete this purchase (৳{{
                            total
                          }}).
                        </p>
                        <p class="mt-2 text-base text-gray-500">
                          Please choose another payment method or add funds to
                          your account.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  class="bg-gray-50 px-6 py-4 sm:px-6 sm:flex sm:flex-row-reverse"
                >
                  <button
                    type="button"
                    class="w-full inline-flex justify-center rounded-lg border border-transparent shadow-sm px-5 py-3 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm transition-colors duration-200"
                    @click="
                      (showInsufficientFundsModal = false)(
                        navigateTo('/deposit-withdraw')
                      )
                    "
                  >
                    Add Funds
                  </button>
                  <button
                    type="button"
                    class="mt-3 w-full inline-flex justify-center rounded-lg border border-gray-300 shadow-sm px-5 py-3 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm transition-colors duration-200"
                    @click="switchToCOD"
                  >
                    Switch to Cash On Delivery
                  </button>
                </div>
              </div>
            </Transition>
          </div>
        </div>
      </Transition>

      <!-- Success Modal -->
      <Transition
        enter-active-class="transition ease-out duration-300"
        enter-from-class="opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="transition ease-in duration-200"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <div
          v-if="showSuccessModal"
          class="fixed inset-0 z-10 overflow-y-auto"
          aria-labelledby="modal-title"
          role="dialog"
          aria-modal="true"
        >
          <div
            class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
          >
            <div
              class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
              aria-hidden="true"
            ></div>
            <span
              class="hidden sm:inline-block sm:align-middle sm:h-screen"
              aria-hidden="true"
              >&#8203;</span
            >
            <Transition
              enter-active-class="transition ease-out duration-300"
              enter-from-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              enter-to-class="opacity-100 translate-y-0 sm:scale-100"
              leave-active-class="transition ease-in duration-200"
              leave-from-class="opacity-100 translate-y-0 sm:scale-100"
              leave-to-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            >
              <div
                v-if="showSuccessModal"
                class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
              >
                <div
                  class="absolute top-0 left-0 right-0 h-2 bg-gradient-to-r from-green-400 to-green-600"
                ></div>
                <div class="bg-white px-6 pt-6 pb-4 sm:p-6 sm:pb-4">
                  <div class="sm:flex sm:items-start">
                    <div
                      class="mx-auto flex-shrink-0 flex items-center justify-center h-14 w-14 rounded-full bg-green-100 sm:mx-0 sm:h-12 sm:w-12"
                    >
                      <svg
                        class="h-7 w-7 text-green-600"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M5 13l4 4L19 7"
                        />
                      </svg>
                    </div>
                    <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                      <h3
                        class="text-xl leading-6 font-semibold text-gray-900"
                        id="modal-title"
                      >
                        Order Successful!
                      </h3>
                      <div class="mt-3">
                        <p class="text-base text-gray-500">
                          Thank you for your purchase! Your order #{{
                            orderNumber
                          }}
                          has been successfully placed.
                        </p>
                        <div
                          class="mt-4 p-3 bg-green-50 rounded-lg border border-green-100"
                        >
                          <div class="flex justify-between text-sm mb-1">
                            <span class="text-gray-600">Order Total:</span>
                            <span class="font-medium">৳{{ total }}</span>
                          </div>
                          <div class="flex justify-between text-sm">
                            <span class="text-gray-600"
                              >Estimated Delivery:</span
                            >
                            <span class="font-medium">{{
                              estimatedDelivery
                            }}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  class="bg-gray-50 px-6 py-4 sm:px-6 sm:flex sm:flex-row-reverse"
                >
                  <button
                    type="button"
                    to="/"
                    class="w-full inline-flex justify-center rounded-lg border border-transparent shadow-sm px-5 py-3 bg-gradient-to-r from-green-500 to-green-600 text-base font-medium text-white hover:from-green-600 hover:to-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 sm:ml-3 sm:w-auto transition-all duration-200"
                    @click="resetForm"
                  >
                    Continue Shopping
                  </button>
                </div>
              </div>
            </Transition>
          </div>
        </div>
      </Transition>
    </div>
  </UContainer>
</template>

<script setup>
import {
  ShoppingBag,
  Check,
  Truck,
  Wallet,
  MapPin,
  CreditCard,
  Plus,
  Minus,
} from "lucide-vue-next";
const { user } = useAuth();
const { post } = useApi();

// Get cart store
const cart = useStoreCart();
// Initialize products with the cart data
const products = ref(cart.products || []);

// Mock account balance
const accountBalance = ref(500);
const orderNumber = ref(Math.floor(100000 + Math.random() * 900000));

// Form state
const form = reactive({
  name: "",
  phone: "",
  email: "",
  address: "",
  deliveryOption: "inside",
  paymentMethod: "account",
});

// Error state
const errors = reactive({
  name: "",
  phone: "",
  email: "",
  address: "",
});

// Modal states
const showInsufficientFundsModal = ref(false);
const showSuccessModal = ref(false);
const isScrolled = ref(false);

// Fix subtotal calculation to properly handle string values
const subtotal = computed(() => {
  return products.value.reduce((total, product) => {
    // Convert sale_price to number in case it's a string
    const price =
      typeof product.sale_price === "string"
        ? parseFloat(product.sale_price)
        : product.sale_price;

    return total + price * product.count;
  }, 0);
});

const totalItems = computed(() => {
  return products.value.reduce((total, product) => total + product.count, 0);
});

const deliveryFee = computed(() => {
  // Safety check in case products array is empty
  if (!products.value.length || !products.value[0]) return 0;

  // If the product has free delivery, return 0 regardless of delivery option
  if (products.value[0].is_free_delivery) return 0;

  const fee =
    form.deliveryOption === "inside"
      ? products.value[0].delivery_fee_inside_dhaka || 100
      : products.value[0].delivery_fee_outside_dhaka || 150;

  // Ensure fee is a number
  return typeof fee === "string" ? parseFloat(fee) : fee;
});

// Proper total calculation with explicit number conversion
const total = computed(() => {
  const subTotal = Number(subtotal.value);
  const delivery = Number(deliveryFee.value);
  return subTotal + delivery;
});

const estimatedDelivery = computed(() => {
  const today = new Date();
  const deliveryDays = form.deliveryOption === "inside" ? 1 : 5;
  const deliveryDate = new Date(today);
  deliveryDate.setDate(today.getDate() + deliveryDays);

  return deliveryDate.toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
});

// Modified function to prevent increasing quantity beyond available stock
const increaseQuantity = (index) => {
  const product = products.value[index];
  // Only allow increasing if stock is available
  if (product.count < product.quantity) {
    product.count++;
  } else {
    // Optional: Show toast notification when trying to exceed stock
    toast.add({
      title: "Maximum Available",
      description: `Only ${product.quantity} units available in stock`,
      color: "amber",
      timeout: 3000,
    });
  }
};

const decreaseQuantity = (index) => {
  if (products.value[index].count > 1) {
    products.value[index].count--;
  }
};

// Modified validateForm to include stock validation
const validateForm = () => {
  let isValid = true;

  // Reset errors
  errors.name = "";
  errors.phone = "";
  errors.email = "";
  errors.address = "";

  // Validate name
  if (!form.name.trim()) {
    errors.name = "Name is required";
    isValid = false;
  }

  // Validate phone
  if (!form.phone.trim()) {
    errors.phone = "Phone number is required";
    isValid = false;
  } else if (!/^\d{10,11}$/.test(form.phone.replace(/\D/g, ""))) {
    errors.phone = "Please enter a valid phone number";
    isValid = false;
  }

  // Validate email
  if (!form.email.trim()) {
    errors.email = "Email is required";
    isValid = false;
  } else if (!/\S+@\S+\.\S+/.test(form.email)) {
    errors.email = "Please enter a valid email address";
    isValid = false;
  }

  // Validate address
  if (!form.address.trim()) {
    errors.address = "Address is required";
    isValid = false;
  }

  // Validate product quantities against available stock
  const stockError = products.value.find(
    (product) => product.count > product.quantity
  );
  if (stockError) {
    toast.add({
      title: "Insufficient Stock",
      description: `Only ${stockError.quantity} units of ${stockError.name} are available`,
      color: "red",
      timeout: 5000,
    });
    isValid = false;
  }

  return isValid;
};

// Modified processCheckout function to add better error handling
const processCheckout = async () => {
  if (!validateForm()) return;

  // Check if account funds are sufficient when that payment method is selected
  if (
    form.paymentMethod === "account" &&
    user.value?.user?.balance < total.value
  ) {
    showInsufficientFundsModal.value = true;
    return;
  }

  try {
    // Format data according to API requirements
    const orderPayload = {
      order: {
        user: user.value?.user?.id || null,
        name: form.name,
        email: form.email,
        address: form.address,
        phone: form.phone,
        total: total.value,
        order_status: "pending",
        delivery_fee: deliveryFee.value,
        delivery_location:
          form.deliveryOption === "inside" ? "inside_dhaka" : "outside_dhaka",
        payment_method:
          form.paymentMethod === "account" ? "balance" : "cash_on_delivery",
      },
      items: products.value.map((product) => ({
        product: product.id,
        quantity: product.count,
        price: parseFloat(product.sale_price),
      })),
    };

    // Send data to API
    const response = await post("/orders/create-with-items/", orderPayload);

    if (response.data) {
      // Show success modal
      orderNumber.value =
        response.data.id || Math.floor(100000 + Math.random() * 900000);
      showSuccessModal.value = true;
    }
  } catch (error) {
    console.error("Error creating order:", error);

    // Show specific error message based on response
    const errorMessage =
      error.response?.data?.detail ||
      "There was an error processing your order. Please try again.";

    toast.add({
      title: "Order Failed",
      description: errorMessage,
      color: "red",
      timeout: 5000,
    });
  }
};

const switchToCOD = () => {
  form.paymentMethod = "cod";
  showInsufficientFundsModal.value = false;
};

const resetForm = () => {
  // Reset form
  form.name = "";
  form.email = "";
  form.phone = "";
  form.address = "";
  form.deliveryOption = "inside";
  form.paymentMethod = "account";

  // Reset products
  products.value.forEach((product) => {
    product.count = 1;
  });

  // Generate new order number
  orderNumber.value = Math.floor(100000 + Math.random() * 900000);

  // Close modal
  showSuccessModal.value = false;

  // Clear cart
  cart.clearCart();

  // Navigate to home
  navigateTo("/");
};

// Handle scroll effect for sticky summary
const handleScroll = () => {
  isScrolled.value = window.scrollY > 100;
};

// Add an onMounted hook to initialize and validate initial quantities
onMounted(() => {
  window.addEventListener("scroll", handleScroll);

  // Update products if cart changes
  if (!products.value.length && cart.products.length) {
    products.value = [...cart.products];
  }

  // Validate and adjust initial quantities if they exceed available stock
  products.value.forEach((product) => {
    if (!product.count) {
      product.count = 1;
    }

    // If initial count exceeds available quantity, cap it
    if (product.count > product.quantity) {
      product.count = product.quantity;
      toast.add({
        title: "Quantity Adjusted",
        description: `Quantity for ${product.name} has been adjusted to match available stock`,
        color: "blue",
        timeout: 3000,
      });
    }
  });
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});
</script>

<style scoped>
/* Add custom animations */
@keyframes slide-up {
  0% {
    opacity: 0;
    transform: translate3d(0, 40px, 0) scale(0.95);
  }
  100% {
    opacity: 1;
    transform: translate3d(0, 0, 0) scale(1);
  }
}

/* Add some custom styling for inputs */
input,
textarea,
select {
  @apply border rounded-lg px-4 py-3;
}

input:focus,
textarea:focus,
select:focus {
  @apply outline-none ring-2 ring-indigo-500 border-indigo-500;
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

::-webkit-scrollbar-thumb {
  background: #c5c5c5;
  border-radius: 10px;
}

::-webkit-scrollbar-thumb:hover {
  background: #a0a0a0;
}

/* Improve focus styles for accessibility */
button:focus,
a:focus {
  @apply outline-none;
}

/* Premium card hover effects */
.card-hover-effect {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.card-hover-effect:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1),
    0 10px 10px -5px rgba(0, 0, 0, 0.04);
}
</style>
