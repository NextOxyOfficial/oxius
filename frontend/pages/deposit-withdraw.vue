<template>
  <PublicSection>
    <h1 class="text-center text-2xl md:text-4xl my-4">
      {{ $t("deposit_withdraw") }}
    </h1>
    <UContainer>
      <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
      <NuxtLink
        to="/mobile-recharge"
        class="mb-6 bg-gray-100 shadow-md border border-gray-500 block py-2 px-4 max-w-fit mx-auto rounded-2xl"
      >
        <div class="flex gap-2">
          <h2 class="text-base text-gray-900 sm:text-xl text-center">
            Mobile Recharge
          </h2>
          <div class="flex justify-center gap-2">
            <NuxtImg
              v-for="operator in operators"
              :key="operator.id"
              :src="operator.icon"
              :title="operator.title"
              class="size-6"
            />
          </div>
        </div>
      </NuxtLink>
      <UDivider label="" class="mb-4" />
      <div class="flex flex-col md:flex-row justify-between items-center">
        <p
          class="text-lg py-2 max-w-fit w-full text-green-800 dark:text-green-600 font-bold"
        >
          <span class="inline-flex items-center"
            >{{ $t("available_balance") }}:&nbsp;
            <UIcon name="i-mdi:currency-bdt" class="" />
            {{ user.user.balance }}
          </span>
        </p>
      </div>
      <div
        class="mb-5 flex justify-center shadow-md bg-gray-100 max-w-fit mx-auto"
      >
        <UButton
          :color="`${currentTab == 1 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-e-none',
          }"
          @click="currentTab = 1"
        >
          <UIcon name="i-ic:baseline-arrow-downward" />
          {{ $t("diposit") }}</UButton
        >

        <UButton
          :loading="isWithdrawLoading"
          :color="`${currentTab == 2 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-s-none rounded-e-none',
          }"
          @click="currentTab = 2"
          ><UIcon name="i-ic:baseline-arrow-upward" />{{
            $t("withdraw")
          }}</UButton
        >

        <UButton
          :color="`${currentTab == 3 ? 'green' : 'gray'}`"
          variant="outline"
          size="md"
          :ui="{
            rounded: 'rounded-s-none',
          }"
          @click="currentTab = 3"
        >
          <UIcon name="i-tabler:arrow-right" />
          {{ $t("transfer") }}</UButton
        >
      </div>

      <div class="flex items-center">
        <div v-if="currentTab === 1" class="max-sm:w-full">
          <div class="space-y-2">
            <!-- Modern Amount Input with Animation -->
            <div
              class="modern-input-container"
              :class="{ 'has-value': amount?.toString().length > 0 }"
            >
              <!-- <UIcon
                name="i-heroicons-banknotes"
                class="input-icon text-primary-400"
              /> -->
              <UInput
                icon="i-heroicons-banknotes"
                placeholder=""
                size="lg"
                :ui="{
                  base: 'relative w-full',
                }"
                class="text-green-800"
                v-model="amount"
                amount
              />
              <label class="floating-label">Enter Amount</label>
              <!-- <div class="input-backdrop"></div>
              <div class="input-currency">৳</div> -->
            </div>
          </div>
          <p v-if="depositErrors.amount" class="text-sm text-red-500">
            Please enter an amount
          </p>
          <div class="mt-4">
            <img
              src="/static/frontend/images/payment.png"
              class="w-60"
              alt="Payment Method"
            />
          </div>
          <div class="my-4">
            <!-- Modern Terms & Conditions Checkbox -->
            <UFormGroup
              class="flex flex-row-reverse justify-end gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
            >
              <template #label>
                I accept
                <ULink
                  to="/terms/"
                  active-class="text-primary"
                  inactive-class="text-green-500 dark:text-green-400"
                  >Terms & Conditions</ULink
                >,
                <ULink
                  to="/privacy/"
                  active-class="text-primary"
                  inactive-class="text-green-500 dark:text-green-400"
                  >Privacy Policy</ULink
                >.
              </template>
              <UCheckbox name="check" v-model="policy" />
            </UFormGroup>
          </div>

          <p v-if="depositErrors.policy" class="text-sm text-red-500">
            Please select this field
          </p>
          <div class="my-2 space-x-3">
            <UButton size="sm" @click="deposit" :loading="isDepositLoading">{{
              $t("diposit")
            }}</UButton>
            <!-- <UButton v-else size="sm" @click="isOpen = true">Deposit</UButton> -->
          </div>
        </div>
        <div v-if="currentTab === 2" class="max-sm:w-full">
          <div class="my-3">
            <!-- Modern Radio Group with Cards -->
            <div class="payment-method-container">
              <div class="method-options">
                <div
                  v-for="option in options"
                  :key="option.value"
                  class="method-option"
                  :class="{ selected: selected === option.value }"
                  @click="selected = option.value"
                >
                  <div class="method-radio">
                    <div class="radio-dot"></div>
                  </div>
                  <div class="method-card">
                    <img
                      :src="'/static/frontend/images/' + option.icon"
                      class="method-icon"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
          <p v-if="errors?.selected" class="text-sm text-red-500">
            Please enter a payment method
          </p>
          <div class="mb-3">
            <!-- Modern Phone Number Input -->
            <div
              class="modern-input-container"
              :class="{ 'has-value': payment_number?.toString().length > 0 }"
            >
              <!-- <UIcon
                name="i-heroicons-device-phone-mobile"
                class="input-icon text-primary-400"
              /> -->
              <UInput
                icon="i-heroicons-device-phone-mobile"
                :placeholder="selected === 'nagad' ? '' : ''"
                size="lg"
                :ui="{
                  base: 'relative w-full',
                  input:
                    'form-input pl-10 pr-4 py-3 rounded-xl border-0 bg-white bg-opacity-80 backdrop-blur-sm shadow-inner text-lg transition-all duration-300 focus:ring-2 focus:ring-primary-500/50 focus:shadow-glow',
                }"
                v-model="payment_number"
              />
              <label class="floating-label">{{
                selected === "nagad"
                  ? "Enter Nagad Number"
                  : "Enter Bkash Number"
              }}</label>
              <!-- <div class="input-backdrop"></div> -->
            </div>
            <p v-if="errors?.payment_number" class="text-sm text-red-500">
              Please enter a payment number
            </p>
          </div>
          <div class="space-y-2">
            <UInput
              icon="i-heroicons-banknotes"
              placeholder="Enter Amount"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="withdrawAmount"
              amount
            />
            <p v-if="errors?.withdrawAmount" class="text-sm text-red-500">
              Please enter an amount
            </p>
            <p class="text-sm">
              Total Deduction:
              {{ withdrawAmount * 1 + (withdrawAmount * 2.95) / 100 }}
            </p>
            <p class="text-sm pt-2">
              <span class="text-red-500">* </span>
              <span class="inline-flex items-center">
                Minimum withdrawal
                <UIcon name="i-mdi:currency-bdt" class="text-base" />200</span
              >
            </p>
            <p class="text-sm">
              <span class="text-red-500">*</span> 2.95% Charges applicable
            </p>

            <p v-if="errors?.insufficient" class="text-sm text-red-500">
              You do not have enough balance
            </p>
          </div>
          <div class="my-5">
            <!-- Modern Terms & Conditions Checkbox -->
            <UFormGroup
              class="flex flex-row-reverse justify-end gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
            >
              <template #label>
                I accept
                <ULink
                  to="/terms/"
                  active-class="text-primary"
                  inactive-class="text-green-500 dark:text-green-400"
                  >Terms & Conditions</ULink
                >,
                <ULink
                  to="/privacy/"
                  active-class="text-primary"
                  inactive-class="text-green-500 dark:text-green-400"
                  >Privacy Policy</ULink
                >.
              </template>
              <UCheckbox name="check" v-model="policy" />
            </UFormGroup>
            <p v-if="errors?.policy" class="text-sm text-red-500">
              Check this field
            </p>
          </div>
          <div class="my-2 space-x-3 mb-4">
            <!-- <UButton size="sm" @click="deposit">Deposit</UButton> -->
            <UButton
              @click="withdraw"
              variant="solid"
              v-if="
                user.user.name &&
                user.user.address &&
                user.user.phone &&
                user.user.city &&
                user.user.zip
              "
              >{{ $t("withdraw") }}</UButton
            >
            <UButton v-else size="sm" @click="isOpen = true">{{
              $t("withdraw")
            }}</UButton>
          </div>
        </div>
        <div v-if="currentTab === 3" class="max-sm:w-full">
          <div class="my-4">
            <UButton
              icon="i-ic:twotone-qr-code-scanner"
              size="md"
              color="primary"
              variant="outline"
              label="Show my QR Code"
              @click="showQr = !showQr"
              block
              class="max-w-40 mx-auto"
            />
            <UModal
              v-model="showQr"
              :ui="{
                width: 'w-full sm:max-w-md',
                background: 'bg-slate-100',
              }"
            >
              <div
                class="px-4 py-12 flex flex-col gap-4 items-center justify-center relative rounded-3xl overflow-hidden "
              >
                <UButton
                  icon="i-heroicons-x-mark"
                  size="md"
                  color="primary"
                  variant="solid"
                  @click="showQr = false"
                  class="absolute top-1 right-1 rounded-full"
                />

                <h3 class="text-2xl font-semibold text-green-700">AdsyPay</h3>
                <h3 class="text-xl font-semibold">Scan My QR Code</h3>
                <div class="border p-4 rounded-lg shadow-md bg-white">
                  <NuxtImg
                    class="max-w-[250px] max-sm:h-[200px]"
                    :src="`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${user.user.phone}`"
                  ></NuxtImg>
                </div>
              </div>
            </UModal>
          </div>
          <UFormGroup label="" class="mb-4">
            <div class="relative">
              <UButton
                icon="i-ic:twotone-qr-code-scanner"
                size="md"
                color="primary"
                variant="ghost"
                label=""
                class="absolute z-30 right-2 max-sm:size-10"
                @click="scanQr = !scanQr"
              />
              <UModal v-model="scanQr">
                <div
                  class="px-4 py-12 flex flex-col gap-2 items-center justify-center relative bg-slate-100"
                >
                  <UButton
                    icon="i-heroicons-x-mark"
                    size="md"
                    color="primary"
                    variant="solid"
                    @click="scanQr = false"
                    class="absolute top-1 right-1 rounded-full"
                  />

                  <h3 class="text-2xl font-semibold text-green-700">AdsyPay</h3>
                  <h3 class="text-base font-semibold capitalize">
                    Point camera on the payee's QR code
                  </h3>

                  <qrcode-stream
                    @scanned="
                      (res) => {
                        scanQr = false;
                        transfer.contact = res;
                      }
                    "
                  ></qrcode-stream>
                </div>
              </UModal>
            </div>
            <UInput
              icon="i-material-symbols-light-lists-rounded"
              type="text"
              size="md"
              color="white"
              placeholder="Enter Email/Phone Or Scan Code"
              v-model="transfer.contact"
            />
            <p class="text-sm text-red-500">{{ transferErrors.contact }}</p>
            <UInput
              icon="i-heroicons-banknotes"
              type="text"
              size="md"
              color="white"
              placeholder="Amount"
              class="my-3"
              v-model="transfer.payable_amount"
            />
            <p class="text-sm text-red-500 mb-2" v-if="transferErrors.transfer">
              {{ transferErrors.limit || transferErrors.transfer }}
            </p>
            <p class="text-sm text-red-500">
              {{ transferErrors.payable_amount }}
            </p>
            <UFormGroup
              class="flex flex-row-reverse justify-end gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-700 dark:text-slate-700',
                },
              }"
            >
              <template #label>
                I accept
                <ULink
                  to="/terms/"
                  active-class="text-primary"
                  inactive-class="text-green-500 dark:text-green-400"
                  >Terms & Conditions</ULink
                >,
                <ULink
                  to="/privacy/"
                  active-class="text-primary"
                  inactive-class="text-green-500 dark:text-green-400"
                  >Privacy Policy</ULink
                >.
              </template>
              <UCheckbox name="check" v-model="policy" />
            </UFormGroup>
            <p class="text-sm text-red-500" v-if="depositErrors.policy">
              *Please Accept Terms & Conditions, Privacy Policy
            </p>
            <div class="mt-4">
              <UButton
                :loading="isLoading"
                size="md"
                color="primary"
                variant="solid"
                @click="sendToUser"
                >{{ $t("transfer") }}</UButton
              >
            </div>
          </UFormGroup>
          <p class="text-sm text-red-500">{{ transferErrors.user }}</p>
        </div>
      </div>

      <h3
        class="text-center text-lg md:text-3xl font-semibold mt-8"
        v-if="statements?.length"
      >
        {{ $t("transaction_history") }}
      </h3>

      <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
        <div
          class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4"
        >
          <div class="flex max-sm:justify-between gap-2">
            <USelect
              v-model="filters.type"
              :options="[
                { name: 'All Types', value: '' },
                { name: 'Deposit', value: 'deposit' },
                { name: 'Withdraw', value: 'withdraw' },
                { name: 'Transfer', value: 'transfer' },
              ]"
              option-attribute="name"
              value-attribute="value"
            />
            <!-- <select
              v-model="filters.type"
              class="rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm sm:text-base px-4"
            >
              <option value="">All Types</option>
              <option value="Deposit">Deposit</option>
              <option value="Withdraw">Withdraw</option>
              <option value="Transfer">Transfer</option>
            </select> -->
            <USelect
              v-model="filters.status"
              :options="[
                { name: 'All Statuses', value: '' },
                { name: 'Completed', value: 'completed' },
                { name: 'Pending', value: 'pending' },
                { name: 'Rejected', value: 'rejected' },
              ]"
              option-attribute="name"
              value-attribute="value"
            />
            <!-- <select
              v-model="filters.status"
              class="rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm sm:text-base px-2"
            >
              <option value="">All Statuses</option>
              <option value="completed">Completed</option>
              <option value="pending">Pending</option>
              <option value="rejected">Rejected</option>
            </select> -->
          </div>
        </div>
      </div>
      <div class="overflow-hidden">
        <UTable :columns="columns" :rows="paginatedTransactions">
          <template #type-data="{ row }">
            <div class="flex items-center">
              <span
                v-if="row.transaction_type === 'Deposit'"
                class="flex-shrink-0 h-5 w-5 text-green-500"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M12 5v14" />
                  <path d="m19 12-7 7-7-7" />
                </svg>
              </span>
              <span
                v-else-if="row.transaction_type === 'Withdraw'"
                class="flex-shrink-0 h-5 w-5 text-red-500"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M12 19V5" />
                  <path d="m5 12 7-7 7 7" />
                </svg>
              </span>
              <span v-else class="flex-shrink-0 h-5 w-5 text-blue-500">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M8 3 4 7l4 4" />
                  <path d="M4 7h16" />
                  <path d="m16 21 4-4-4-4" />
                  <path d="M20 17H4" />
                </svg>
              </span>
              <span
                class="ml-2 text-sm text-gray-900 capitalize"
                v-if="row.transaction_type === 'order_payment'"
                >{{
                  row.transaction_type === "order_payment"
                    ? "Product Purchase"
                    : row.transaction_type
                }}</span
              >
              <span
                class="ml-2 text-sm text-gray-900 capitalize"
                v-if="row.transaction_type === 'order_received'"
                >{{
                  row.transaction_type === "order_received"
                    ? "Order Received"
                    : row.transaction_type
                }}</span
              >
              <span
                class="ml-2 text-sm text-gray-900 capitalize"
                v-if="row.transaction_type == 'transfer'"
                >{{ row.transaction_type }}</span
              >
            </div>
          </template>
          <template #recipient-data="{ row }">
            <div
              class="text-sm text-gray-500 capitalize"
              v-if="row?.to_user_details"
            >
              {{ row.to_user_details.first_name }}
              {{ row.to_user_details.last_name }}
            </div>
          </template>
          <template #sender-data="{ row }">
            <div
              class="text-sm text-gray-500 capitalize"
              v-if="row?.user_details"
            >
              {{ row.user_details.first_name }}
              {{ row.user_details.last_name }}
            </div>
          </template>
          <template #method-data="{ row }">
            <div class="text-sm text-gray-500 capitalize">
              {{ row?.payment_method }}
            </div>
          </template>
          <template #time-data="{ row }">
            <div class="text-sm text-gray-500">
              {{ formatDate(row.created_at) }}
            </div>
          </template>
          <template #amount-data="{ row }">
            <div
              v-if="row.amount !== '0.00'"
              class="text-sm font-medium"
              :class="{
                'text-green-600': row.transaction_type === 'Deposit',
                'text-red-600': row.transaction_type === 'Withdraw',
                'text-blue-600': row.transaction_type === 'Transfer',
              }"
            >
              {{ formatAmount(row.amount, row.transaction_type.toLowerCase()) }}
            </div>
            <div
              v-else
              class="text-sm font-medium"
              :class="{
                'text-green-600': row.transaction_type === 'Deposit',
                'text-red-600': row.transaction_type === 'Withdraw',
                'text-blue-600': row.transaction_type === 'Transfer',
              }"
            >
              {{
                formatAmount(
                  row.payable_amount,
                  row.transaction_type.toLowerCase()
                )
              }}
            </div>
          </template>
          <template #status-data="{ row }">
            <span
              class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
              :class="{
                'bg-green-100 text-green-800': row.bank_status === 'completed',
                'bg-yellow-100 text-yellow-800': row.bank_status === 'pending',
                'bg-red-100 text-red-800': row.bank_status === 'failed',
              }"
            >
              {{
                row.bank_status.charAt(0).toUpperCase() +
                row.bank_status.slice(1)
              }}
            </span>
          </template>
          <template #action-data="{ row }">
            <button
              @click="openTransactionDetails(row)"
              class="text-primary-600 hover:text-primary-900 focus:outline-none focus:underline"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="lucide lucide-eye h-5 w-5"
              >
                <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
                <circle cx="12" cy="12" r="3" />
              </svg>
              <span class="sr-only">View details</span>
            </button>
          </template>
        </UTable>
      </div>

      <!-- Pagination -->
      <div
        v-if="totalPages > 1"
        class="px-6 py-4 bg-gray-50 border-t border-gray-200 flex items-center justify-between"
      >
        <div
          class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between"
        >
          <div>
            <p class="text-sm text-gray-700">
              Showing
              <span class="font-medium">{{ startIndex + 1 }}</span> to
              <span class="font-medium">{{
                Math.min(startIndex + itemsPerPage, filteredTransactions.length)
              }}</span>
              of
              <span class="font-medium">{{ filteredTransactions.length }}</span>
              results
            </p>
          </div>
          <div>
            <nav
              class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
              aria-label="Pagination"
            >
              <button
                @click="goToPage(1)"
                :disabled="currentPage === 1"
                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span class="sr-only">First page</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="lucide lucide-chevrons-left h-5 w-5"
                >
                  <path d="m11 17-5-5 5-5" />
                  <path d="m18 17-5-5 5-5" />
                </svg>
              </button>

              <button
                @click="goToPage(currentPage - 1)"
                :disabled="currentPage === 1"
                class="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span class="sr-only">Previous</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="lucide lucide-chevron-left h-5 w-5"
                >
                  <path d="m15 18-6-6 6-6" />
                </svg>
              </button>

              <button
                v-for="(page, i) in displayedPages"
                :key="i"
                @click="goToPage(page)"
                :class="[
                  currentPage === page
                    ? 'z-10 bg-primary-50 border-primary-500 text-primary-600'
                    : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50',
                  'relative inline-flex items-center px-4 py-2 border text-sm font-medium',
                ]"
              >
                {{ page }}
              </button>

              <button
                @click="goToPage(currentPage + 1)"
                :disabled="currentPage === totalPages"
                class="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span class="sr-only">Next</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="lucide lucide-chevron-right h-5 w-5"
                >
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>

              <button
                @click="goToPage(totalPages)"
                :disabled="currentPage === totalPages"
                class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span class="sr-only">Last page</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="lucide lucide-chevrons-right h-5 w-5"
                >
                  <path d="m6 17 5-5-5-5" />
                  <path d="m13 17 5-5-5-5" />
                </svg>
              </button>
            </nav>
          </div>
        </div>

        <!-- Mobile pagination -->
        <div class="flex items-center justify-between w-full sm:hidden">
          <button
            @click="goToPage(currentPage - 1)"
            :disabled="currentPage === 1"
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          <p class="text-sm text-gray-700">
            Page <span class="font-medium">{{ currentPage }}</span> of
            <span class="font-medium">{{ totalPages }}</span>
          </p>
          <button
            @click="goToPage(currentPage + 1)"
            :disabled="currentPage === totalPages"
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      </div>
    </UContainer>
    <UModal v-model="isOpen">
      <div class="p-4 text-center space-y-3">
        <h3 class="text-lg font-semibold">Profile Incomplete!</h3>
        <p>Please complete your profile to make transactions.</p>

        <UButton
          size="md"
          color="primary"
          variant="solid"
          to="/my-account"
          label="Complete Profile"
        />
      </div>
    </UModal>
    <UModal
      v-model="isOpenTransfer"
      :ui="{
        inner: 'fixed inset-0 overflow-y-auto flex item-center justify-center',
        container:
          'flex min-h-full items-center justify-center text-center max-w-sm w-full',
      }"
    >
      <div class="flex items-center justify-center" v-if="!showSuccess">
        <div class="w-full max-w-sm">
          <!-- Glass Card Effect -->
          <div
            class="backdrop-blur-lg rounded-xl bg-slate-100 p-2 shadow-lg border border-white/20"
          >
            <div class="border p-4 bg-slate-50 rounded-xl">
              <!-- Title -->
              <h2 class="text-lg font-semibold text-gray-800 mb-4">
                Confirm Transfer
              </h2>

              <!-- Transfer Details -->
              <div class="space-y-4 mb-6">
                <div class="flex justify-between items-center">
                  <p class="text-gray-500 text-xs">Transfer amount</p>
                  <p class="text-gray-900 text-lg font-semibold">
                    <UIcon name="i-mdi:currency-bdt" class="" />
                    {{ transfer?.payable_amount }}
                  </p>
                </div>

                <div class="space-y-3">
                  <!-- Recipient Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Recipient:</label>
                    <p
                      class="text-sm text-gray-800 font-medium"
                      v-if="transfer?.to_user"
                    >
                      {{ transfer?.to_user }}
                    </p>
                  </div>

                  <!-- Email Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Email:</label>
                    <p class="text-sm text-gray-800 font-medium">
                      {{ transfer?.contact }}
                    </p>
                  </div>

                  <!-- Name Field -->
                  <!-- <div class="space-y-1">
                  <label class="text-xs text-gray-500">Name:</label>
                  <p class="text-sm text-gray-800 font-medium">John Smith</p>
                </div> -->

                  <!-- Time Field -->
                  <div class="flex items-center gap-2">
                    <label class="text-xs text-gray-500">Time:</label>
                    <span
                      class="px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium"
                    >
                      Instant
                    </span>
                  </div>
                </div>
              </div>

              <!-- Final Amount -->
              <div
                class="flex justify-between items-center mb-6 pt-4 border-t border-gray-200"
              >
                <p class="text-xs text-gray-500">Final amount</p>
                <p class="text-gray-900 font-semibold">
                  <UIcon name="i-mdi:currency-bdt" class="" />
                  {{ transfer?.payable_amount }}
                </p>
              </div>

              <!-- Confirm Button -->
              <UButton
                @click="handleTransfer"
                :class="[
                  'w-full py-2.5 rounded-lg text-sm font-medium transition-all duration-200',
                  'bg-black text-white hover:bg-gray-800 active:scale-98',
                  'focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2',
                  'disabled:opacity-50 disabled:cursor-not-allowed justify-center',
                ]"
                :loading="isLoading"
              >
                <div class="flex items-center justify-center gap-2">
                  {{ isLoading ? "Processing..." : "Confirm Transfer" }}
                </div>
              </UButton>
            </div>
          </div>

          <!-- Success Message -->
        </div>
      </div>

      <div class="flex items-center justify-center" v-else>
        <div class="w-full max-w-sm flex-1">
          <!-- Glass Card Effect -->
          <div
            class="backdrop-blur-lg bg-slate-100 rounded-xl p-2 shadow-lg border border-white/20 w-full"
          >
            <div class="border bg-slate-50 p-4 rounded-xl">
              <!-- Title and Success Icon -->
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-lg sm:text-2xl font-semibold text-green-700">
                  Transfer Successful
                </h2>
                <UIcon
                  name="i-rivet-icons-check-circle-breakout"
                  class="size-7 text-green-700"
                />
              </div>

              <!-- Transfer Details -->
              <div class="space-y-4 mb-6">
                <div class="flex justify-between items-center">
                  <p class="text-gray-500 text-xs">Transferred amount</p>
                  <p class="text-gray-900 text-lg font-semibold">
                    <UIcon name="i-mdi:currency-bdt" class="" />
                    {{ transfer?.payable_amount }}
                  </p>
                </div>

                <div class="space-y-3">
                  <!-- Recipient Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Recipient:</label>
                    <p class="text-sm sm:text-lg text-gray-800 font-medium">
                      {{ transfer?.to_user }}
                    </p>
                  </div>

                  <!-- Email Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-500">Email:</label>
                    <p class="text-sm text-gray-800 font-medium">
                      {{ transfer?.contact }}
                    </p>
                  </div>

                  <div class="flex items-center gap-2">
                    <label class="text-xs text-gray-500">Time:</label>
                    <span
                      class="px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium"
                    >
                      Completed
                    </span>
                  </div>
                </div>
              </div>

              <!-- Final Amount -->
              <div
                class="flex justify-between items-center mb-6 pt-4 border-t border-gray-200"
              >
                <p class="text-xs text-gray-500">Final amount</p>
                <p class="text-gray-900 font-semibold sm:text-lg">
                  <UIcon name="i-mdi:currency-bdt" class="" />
                  {{ transfer?.payable_amount }}
                </p>
              </div>

              <!-- Action Buttons -->
              <div class="flex gap-3">
                <button
                  @click="reset"
                  class="flex-1 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 bg-gray-100 text-gray-800 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-gray-300"
                >
                  View History
                </button>
                <button
                  @click="reset"
                  class="flex-1 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 bg-black text-white hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UModal>

    <!-- Transaction Details Modal -->
    <div
      v-if="showDetailsModal"
      class="fixed inset-0 top-16 overflow-y-auto z-50"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <!-- Background overlay -->
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
          @click="showDetailsModal = false"
        ></div>

        <!-- Modal panel -->
        <div
          class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="flex items-start">
              <div class="mt-3 sm:mt-0 sm:ml-4 text-left w-full">
                <h3
                  class="text-lg leading-6 font-medium text-gray-900"
                  id="modal-title"
                >
                  Transaction Details
                </h3>
                <div class="mt-4 border-t border-gray-200 pt-4">
                  <dl class="divide-y divide-gray-200">
                    <div class="py-3 grid grid-cols-3 gap-4">
                      <dt class="text-sm font-medium text-gray-500">
                        Transaction ID
                      </dt>
                      <dd
                        class="text-sm text-gray-900 mt-0 col-span-2 font-mono"
                      >
                        {{ selectedTransaction?.id }}
                      </dd>
                    </div>
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Type</dt>
                      <dd
                        class="text-sm text-gray-900 mt-0 col-span-2 flex items-center uppercase"
                      >
                        <span
                          v-if="selectedTransaction?.type === 'deposit'"
                          class="flex-shrink-0 h-5 w-5 text-green-500 mr-2"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-down"
                          >
                            <path d="M12 5v14" />
                            <path d="m19 12-7 7-7-7" />
                          </svg>
                        </span>
                        <span
                          v-else-if="selectedTransaction?.type === 'withdraw'"
                          class="flex-shrink-0 h-5 w-5 text-red-500 mr-2"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-up"
                          >
                            <path d="M12 19V5" />
                            <path d="m5 12 7-7 7 7" />
                          </svg>
                        </span>
                        <span
                          v-else
                          class="flex-shrink-0 h-5 w-5 text-blue-500 mr-2"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-left-right"
                          >
                            <path d="M8 3 4 7l4 4" />
                            <path d="M4 7h16" />
                            <path d="m16 21 4-4-4-4" />
                            <path d="M20 17H4" />
                          </svg>
                        </span>
                        {{
                          selectedTransaction?.transaction_type ===
                          "order_payment"
                            ? "Product Purchase"
                            : selectedTransaction?.transaction_type
                        }}
                      </dd>
                    </div>
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">
                        Recipient
                      </dt>
                      <dd
                        v-if="selectedTransaction?.to_user_details"
                        class="text-sm text-gray-900 mt-0 col-span-2 font-mono"
                      >
                        <p>
                          {{ selectedTransaction?.to_user_details?.phone }}
                        </p>
                        {{ selectedTransaction?.to_user_details?.email }}
                      </dd>
                    </div>
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Name</dt>
                      <dd
                        v-if="selectedTransaction?.to_user_details"
                        class="text-sm text-gray-900 mt-0 col-span-2"
                      >
                        {{ selectedTransaction?.to_user_details.name }}
                      </dd>
                    </div>
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">
                        Date & Time
                      </dt>
                      <dd class="text-sm text-gray-900 mt-0 col-span-2">
                        {{ formatDate(selectedTransaction?.created_at) }}
                      </dd>
                    </div>
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Amount</dt>
                      <dd
                        class="text-sm font-medium mt-0 col-span-2"
                        :class="{
                          'text-green-600':
                            selectedTransaction?.transaction_type === 'deposit',
                          'text-red-600':
                            selectedTransaction?.transaction_type ===
                            'withdraw',
                          'text-gray-900':
                            selectedTransaction?.transaction_type ===
                            'transfer',
                        }"
                      >
                        {{
                          selectedTransaction
                            ? formatAmount(
                                selectedTransaction?.payable_amount,
                                selectedTransaction?.transaction_type
                              )
                            : ""
                        }}
                      </dd>
                    </div>
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Status</dt>
                      <dd class="text-sm text-gray-900 mt-0 col-span-2">
                        <span
                          v-if="selectedTransaction"
                          class="px-2 inline-flex text-sm leading-5 font-medium rounded-full capitalize"
                          :class="{
                            'bg-green-100 text-green-800':
                              selectedTransaction?.status === 'completed',
                            'bg-yellow-100 text-yellow-800':
                              selectedTransaction?.status === 'pending',
                            'bg-red-100 text-red-800':
                              selectedTransaction?.status === 'failed',
                          }"
                        >
                          {{ selectedTransaction?.bank_status }}
                        </span>
                      </dd>
                    </div>
                  </dl>
                </div>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-primary-600 text-base font-medium text-white hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 sm:ml-3 sm:w-auto sm:text-sm"
              @click="showDetailsModal = false"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

// Core state refs
const scanQr = ref(false);
const showQr = ref(false);
const showSuccess = ref(false);
const isOpenTransfer = ref(false);
const isOpen = ref(false);
const toast = useToast();
const { post, get } = useApi();
const { user, jwtLogin } = useAuth();
const { formatDate } = useUtils();
const policy = ref(false);
const amount = ref(null);
const withdrawAmount = ref(null);
const currentTab = ref(1);
const selected = ref("nagad");
const payment_number = ref(null);
const errors = ref({});
const depositErrors = ref({});
const isLoading = ref(false);
const isDepositLoading = ref(false);
const isWithdrawLoading = ref(false);
const selectedTransaction = ref(null);
const showDetailsModal = ref(false);

const { data } = await get("/received-transfers/");
console.log(data);

const columns = [
  {
    key: "type",
    label: "Type",
  },
  {
    key: "sender",
    label: "Sender",
  },
  {
    key: "recipient",
    label: "Recipient",
  },

  {
    key: "time",
    label: "Time",
  },
  {
    key: "amount",
    label: "Amount",
  },
  {
    key: "status",
    label: "Status",
  },
  {
    key: "action",
    label: "Action",
  },
];

// Transaction filtering and pagination
const filters = ref({
  type: "", // Deposit/Withdraw/Transfer
  status: "", // completed/pending/failed
  search: "", // search query
  dateRange: null,
});

const itemsPerPage = 10;
const currentPage = ref(1);
const startIndex = computed(() => (currentPage.value - 1) * itemsPerPage);
const statements = ref([]);

// Filter transactions based on selected filters
const filteredTransactions = computed(() => {
  return statements.value.filter((transaction) => {
    // Type filter
    if (
      filters.value.type &&
      transaction.transaction_type !== filters.value.type
    ) {
      return false;
    }

    // Status filter
    if (
      filters.value.status &&
      transaction.bank_status !== filters.value.status
    ) {
      return false;
    }

    // Search (in payment method, amount, or transaction type)
    if (filters.value.search) {
      const searchTerm = filters.value.search.toLowerCase();
      const searchableFields = [
        transaction.payment_method?.toLowerCase() || "",
        transaction.payable_amount?.toString() || "",
        transaction.transaction_type?.toLowerCase() || "",
        transaction.bank_status?.toLowerCase() || "",
      ];

      if (!searchableFields.some((field) => field.includes(searchTerm))) {
        return false;
      }
    }

    return true;
  });
});

// Pagination
const totalPages = computed(() =>
  Math.ceil(filteredTransactions.value.length / itemsPerPage)
);

const paginatedTransactions = computed(() => {
  return filteredTransactions.value.slice(
    startIndex.value,
    startIndex.value + itemsPerPage
  );
});

// Calculate displayed page numbers for pagination
const displayedPages = computed(() => {
  const maxPages = 5;
  if (totalPages.value <= maxPages) {
    return Array.from({ length: totalPages.value }, (_, i) => i + 1);
  }

  const middle = Math.floor(maxPages / 2);
  let start = currentPage.value - middle;
  let end = currentPage.value + middle;

  if (start < 1) {
    start = 1;
    end = Math.min(maxPages, totalPages.value);
  }

  if (end > totalPages.value) {
    end = totalPages.value;
    start = Math.max(1, totalPages.value - maxPages + 1);
  }

  return Array.from({ length: end - start + 1 }, (_, i) => start + i);
});

function goToPage(page) {
  currentPage.value = page;
}

// Format amount with sign and symbol based on transaction type
function formatAmount(amount, type) {
  if (type === "deposit") {
    return `+৳${amount}`;
  } else if (type === "withdraw" || type === "transfer") {
    return `-৳${amount}`;
  }
  return `৳${amount}`;
}

// Open transaction details modal
function openTransactionDetails(transaction) {
  selectedTransaction.value = transaction;
  showDetailsModal.value = true;
}

// Get transaction status badge class
function getStatusBadgeClass(status) {
  switch (status) {
    case "completed":
      return "bg-green-100 text-green-800";
    case "pending":
      return "bg-yellow-100 text-yellow-800";
    case "failed":
    case "rejected":
      return "bg-red-100 text-red-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
}

// Get transaction type icon color
function getTransactionTypeColor(type) {
  switch (type) {
    case "Deposit":
      return "text-green-500";
    case "Withdraw":
      return "text-red-500";
    case "Transfer":
      return "text-blue-500";
    default:
      return "text-gray-500";
  }
}

const options = [
  { value: "bkash", label: "BKash", icon: "bkash.png" },
  { value: "nagad", label: "Nagad", icon: "nagad.png" },
];

const transfer = ref({
  contact: "",
  payable_amount: "",
  transaction_type: "Transfer",
  payment_method: "p2p",
  bank_status: "completed",
});

const transferErrors = ref({});

// Fetch transaction history
const getTransactionHistory = async () => {
  try {
    isLoading.value = true;
    const res = await get(`/user-balance/${user.value.user.email}/`);
    statements.value = res.data || [];
    currentPage.value = 1;
  } catch (error) {
    toast.add({
      title: "Failed to load transaction history",
      description: error.message,
      color: "red",
    });
    console.error("Error fetching transactions:", error);
  } finally {
    isLoading.value = false;
  }
};

// Clear all filters
function clearFilters() {
  filters.value = {
    type: "",
    status: "",
    search: "",
    dateRange: null,
  };
  currentPage.value = 1;
}

// Deposit function
const deposit = async () => {
  depositErrors.value = {};

  if (!amount.value) {
    depositErrors.value.amount = true;
  }

  if (!policy.value) {
    depositErrors.value.policy = true;
  }

  if (!amount.value || !policy.value) {
    toast.add({
      title: "Please fill in all required fields",
      color: "orange",
    });
    return;
  }

  try {
    isDepositLoading.value = true;

    const payment = await get(
      `/pay/?amount=${amount.value}&order_id=123&currency=BDT&customer_name=${user.value.user.first_name}+${user.value.user.last_name}&customer_address=${user.value.user.address}&customer_phone=${user.value.user.phone}&customer_city=${user.value.user.city}&customer_post_code=${user.value.user.zip}`
    );

    if (payment.data?.checkout_url) {
      window.open(payment.data.checkout_url, "_blank");
    } else {
      throw new Error("Failed to get payment URL");
    }

    // Reset form and update data
    amount.value = "";
    policy.value = false;
    await getTransactionHistory();
  } catch (error) {
    toast.add({
      title: "Payment initiation failed",
      description: error.message,
      color: "red",
    });
    console.error("Deposit error:", error);
  } finally {
    isDepositLoading.value = false;
  }
};

// Withdraw function
const withdraw = async () => {
  errors.value = {};

  if (!withdrawAmount.value) {
    errors.value.withdrawAmount = true;
  }

  if (!selected.value) {
    errors.value.selected = true;
  }

  if (Number(withdrawAmount.value) > Number(user.value.user.balance)) {
    errors.value.insufficient = true;
  }

  if (!payment_number.value) {
    errors.value.payment_number = true;
  }

  if (!policy.value) {
    errors.value.policy = true;
  }

  if (Object.keys(errors.value).length > 0) {
    return;
  }

  try {
    isWithdrawLoading.value = true;

    const totalAmount =
      withdrawAmount.value * 1 + (withdrawAmount.value * 2.95) / 100;

    const res = await post(`/add-user-balance/`, {
      payment_method: selected.value,
      card_number: payment_number.value,
      payable_amount: totalAmount,
      transaction_type: "Withdraw",
    });

    if (res.error) {
      throw new Error(res.error);
    }

    toast.add({
      title: "Withdrawal request submitted",
      color: "green",
    });

    // Reset form and update data
    withdrawAmount.value = "";
    payment_number.value = "";
    policy.value = false;
    await getTransactionHistory();
    await jwtLogin();
    isWithdrawLoading.value = false;
  } catch (error) {
    toast.add({
      title: "Withdrawal failed",
      description: error.message,
      color: "red",
    });
    console.error("Withdraw error:", error);
  } finally {
    isWithdrawLoading.value = false;
  }
};

// Transfer functions
async function sendToUser() {
  transferErrors.value = {};

  if (!transfer.value.contact) {
    transferErrors.value.contact = "Contact is required";
  }

  if (!transfer.value.payable_amount) {
    transferErrors.value.payable_amount = "Amount is required";
  }

  if (Number(transfer.value.payable_amount) > 25000) {
    transferErrors.value.limit = "Maximum single transfer limit is 25,000/=";
  }

  const transferAmount = Number(transfer.value.payable_amount);
  const userBalance = Number(user.value?.user.balance);

  if (transferAmount > userBalance) {
    transferErrors.value.transfer = "* Insufficient Balance";
  }

  if (!policy.value) {
    depositErrors.value.policy = true;
  }

  if (Object.keys(transferErrors.value).length > 0 || !policy.value) {
    return;
  }

  try {
    isLoading.value = true;

    const { data, error } = await get(`/user/${transfer.value.contact}/`);

    if (error || !data) {
      transferErrors.value.user = "User not found";
      return;
    }

    transfer.value.to_user = data.name;
    isOpenTransfer.value = true;

    isLoading.value = false;
  } catch (error) {
    toast.add({
      title: "Error finding user",
      description: error.message,
      color: "red",
    });
    console.error("User search error:", error);
  } finally {
    isLoading.value = false;
  }
}

async function handleTransfer() {
  try {
    isLoading.value = true;

    const { to_user, ...rest } = transfer.value;

    const { data, error } = await post(`/add-user-balance/`, rest);

    if (error) {
      throw new Error(error);
    }

    showSuccess.value = true;
    await getTransactionHistory();
    await jwtLogin();
  } catch (error) {
    toast.add({
      title: "Transfer failed",
      description: error.message,
      color: "red",
    });
    console.error("Transfer error:", error);
    isOpenTransfer.value = false;
  } finally {
    isLoading.value = false;
  }
}
const operators = ref([]);
const operatorsRes = await get("/mobile-recharge/operators/");

operators.value = operatorsRes.data;

function reset() {
  isOpenTransfer.value = false;
  showSuccess.value = false;
  transfer.value = {
    contact: "",
    payable_amount: "",
    transaction_type: "Transfer",
    payment_method: "p2p",
    bank_status: "completed",
    to_user: null,
  };
}

// Initialize the component
onMounted(() => {
  getTransactionHistory();
});
</script>

<style scoped>
/* Modern Input Fields */
.modern-input-container {
  position: relative;
  margin-bottom: 1.5rem;
  transition: all 0.3s ease;
}

.input-backdrop {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to right,
    rgba(255, 255, 255, 0.9),
    rgba(249, 250, 251, 0.9)
  );
  border-radius: 0.75rem;
  z-index: -1;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05),
    0 2px 4px -1px rgba(0, 0, 0, 0.03), inset 0 2px 4px rgba(255, 255, 255, 0.7);
  transform: translateY(0);
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.modern-input-container:focus-within .input-backdrop {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px -5px rgba(59, 130, 246, 0.15),
    0 5px 10px -5px rgba(59, 130, 246, 0.1),
    inset 0 2px 4px rgba(255, 255, 255, 0.7);
}

.input-icon {
  position: absolute;
  left: 0.875rem;
  top: 50%;
  transform: translateY(-50%);
  font-size: 1.25rem;
  z-index: 10;
  transition: all 0.3s ease;
}

.modern-input-container:focus-within .input-icon {
  color: var(--color-primary-600) !important;
  transform: translateY(-50%) scale(1.1);
}

.input-currency {
  position: absolute;
  right: 1rem;
  top: 50%;
  transform: translateY(-50%);
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-primary-600);
  opacity: 0;
  transition: all 0.3s ease;
}

.modern-input-container:focus-within .input-currency,
.modern-input-container.has-value .input-currency {
  opacity: 1;
}

.floating-label {
  position: absolute;
  left: 2.75rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-gray-400);
  transition: all 0.3s ease;
  pointer-events: none;
  z-index: 5;
  font-size: 0.95rem;
}

.modern-input-container:focus-within .floating-label,
.modern-input-container.has-value .floating-label {
  top: 0;
  transform: translateY(-50%) scale(0.85);
  left: 0.75rem;
  color: var(--color-primary-600);
  background: linear-gradient(to right, white, rgba(255, 255, 255, 0.9));
  padding: 0 0.5rem;
  border-radius: 4px;
  font-weight: 500;
}

/* Focus shadow glow effect */
.focus\:shadow-glow:focus {
  box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.15),
    0 2px 8px rgba(99, 102, 241, 0.25) !important;
}

/* Modern Payment Method Radio Group */
.payment-method-container {
  margin-bottom: 1.5rem;
}

.method-label {
  display: block;
  font-size: 0.875rem;
  color: var(--color-gray-500);
  margin-bottom: 0.75rem;
  font-weight: 500;
}

.method-options {
  display: flex;
  gap: 1rem;
}

.method-option {
  display: flex;
  align-items: center;
  cursor: pointer;
  position: relative;
  padding: 0.25rem;
  transition: all 0.3s ease;
  flex: 1;
  min-width: 120px;
}

.method-radio {
  width: 1.5rem;
  height: 1.5rem;
  border-radius: 50%;
  border: 2px solid var(--color-gray-300);
  margin-right: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  position: absolute;
  left: 0.5rem;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
}

.radio-dot {
  width: 1rem;
  height: 1rem;
  border-radius: 50%;
  background-color: green;
  transform: scale(0);
  transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.method-option.selected .radio-dot {
  transform: scale(1);
}

.method-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  width: 100%;
  background-color: white;
  border-radius: 0.75rem;
  border: 1px solid var(--color-gray-200);
  transition: all 0.3s ease;
  padding-left: 2.5rem;
}

.method-option:hover .method-card {
  transform: translateY(-2px);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.05);
  border-color: var(--color-gray-300);
}

.method-option.selected .method-card {
  border-color: rgba(0, 255, 0, 0);
  background-color: rgba(89, 230, 143, 0.301);
  transform: translateY(-3px);
}

.method-icon {
  height: 1.5rem;
  object-fit: contain;
  margin-bottom: 0.5rem;
}

.method-name {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-gray-700);
}

/* Modern Checkbox */
.modern-checkbox-container {
  margin: 1.5rem 0;
  position: relative;
}

.checkbox-wrapper {
  position: relative;
  margin-right: 0.75rem;
}

.checkbox-ripple {
  position: absolute;
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  background: radial-gradient(
    circle,
    var(--color-primary-100) 0%,
    transparent 70%
  );
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) scale(0);
  opacity: 0;
  transition: all 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
  pointer-events: none;
}

.custom-checkbox:focus-within + .checkbox-ripple,
.custom-checkbox:active + .checkbox-ripple {
  transform: translate(-50%, -50%) scale(1);
  opacity: 1;
}

.checkbox-label {
  font-size: 0.95rem;
  color: var(--color-gray-700);
  user-select: none;
}

.terms-link {
  font-weight: 500;
  position: relative;
  display: inline-block;
}

.terms-link::after {
  content: "";
  position: absolute;
  width: 100%;
  height: 2px;
  bottom: -2px;
  left: 0;
  background-color: var(--color-primary-400);
  transform: scaleX(0);
  transition: transform 0.3s ease;
  transform-origin: bottom right;
}

.terms-link:hover::after {
  transform: scaleX(1);
  transform-origin: bottom left;
}

/* For better mobile appearance */
@media (max-width: 640px) {
  .method-options {
    gap: 0.25rem;
  }

  .method-option {
    width: 100%;
  }
}
</style>

<style>
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fade-in 0.2s ease-out;
}

.active\:scale-98:active {
  transform: scale(0.98);
}

/* Glass morphism effect */
.backdrop-blur-lg {
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}
</style>
