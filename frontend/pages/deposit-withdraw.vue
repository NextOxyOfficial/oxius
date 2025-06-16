<template>
  <PublicSection>
    <h1 class="text-center text-xl md:text-2xl my-4">
      {{ $t("deposit_withdraw") }}
    </h1>
    <UContainer>
      <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
      <NuxtLink
        to="/mobile-recharge"
        class="mb-6 bg-gray-100 shadow-sm border border-gray-500 block py-2 px-4 max-w-fit mx-auto rounded-xl"
      >
        <div class="flex gap-2">
          <h2 class="text-base text-gray-800 sm:text-xl text-center">Mobile Recharge</h2>
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
        <p class="text-lg py-2 max-w-fit w-full text-green-800 dark:text-green-600 font-semibold">
          <span class="inline-flex items-center"
            >{{ $t("available_balance") }}:&nbsp;
            <UIcon name="i-mdi:currency-bdt" class="" />
            {{ user.user.balance }}
          </span>
        </p>
      </div>
      <div class="mb-5 flex justify-center shadow-sm bg-gray-100 max-w-fit mx-auto">
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
          ><UIcon name="i-ic:baseline-arrow-upward" />{{ $t("withdraw") }}</UButton
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

      <div class="flex items-center px-4">
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
              /> -->              <UInput
                icon="i-heroicons-banknotes"
                placeholder=""
                size="lg"
                :ui="{
                  base: 'relative w-full',
                }"
                class="text-green-800"
                v-model="amount"
                type="number"
                min="0"
                step="0.01"
                @input="validateAmountInput('amount')"
              />
              <label class="floating-label">Enter Amount</label>
                </div>
          </div>
          <p v-if="depositErrors.amount" class="text-sm text-red-500">
            {{ typeof depositErrors.amount === 'string' ? depositErrors.amount : 'Please enter an amount' }}
          </p>
          <p v-if="depositErrors.min_deposit" class="text-sm text-red-500">
            Minimum deposit amount is ৳{{ min_deposit }}
          </p>
          <p class="text-sm py-2">
            <span class="text-green-600">* </span>
            <span class="inline-flex items-center">
              Minimum deposit
              <UIcon name="i-mdi:currency-bdt" class="text-base" />{{ min_deposit }}</span
            >
          </p>
          <div class="mt-4">
            <img src="/static/frontend/images/payment.png" class="w-60" alt="Payment Method" />
          </div>
          <div class="my-4">
            <!-- Modern Terms & Conditions Checkbox -->
            <UFormGroup
              class="flex flex-row-reverse justify-end gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
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

          <p v-if="depositErrors.policy" class="text-sm text-red-500">Please select this field</p>
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
                    <img :src="'/static/frontend/images/' + option.icon" class="method-icon" />
                  </div>
                </div>
              </div>
            </div>
          </div>
          <p v-if="errors?.selected" class="text-sm text-red-500">Please enter a payment method</p>
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
                selected === "nagad" ? "Enter Nagad Number" : "Enter Bkash Number"
              }}</label>
              <!-- <div class="input-backdrop"></div> -->
            </div>
            <p v-if="errors?.payment_number" class="text-sm text-red-500">
              Please enter a payment number
            </p>
          </div>
          <div class="space-y-2">            <UInput
              icon="i-heroicons-banknotes"
              placeholder="Enter Amount"
              size="md"
              :ui="{
                padding: { md: 'px-3 py-2' },
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
              v-model="withdrawAmount"
              type="number"
              min="0"
              step="0.01"
              @input="validateAmountInput('withdraw')"
            />            <p v-if="errors?.withdrawAmount" class="text-sm text-red-500">
              {{ typeof errors.withdrawAmount === 'string' ? errors.withdrawAmount : 'Please enter an amount' }}
            </p>
            <p class="text-sm">
              Total Deduction:
              {{ withdrawAmount * 1 + (withdrawAmount * 2.95) / 100 }}
            </p>
            <p class="text-sm py-2">
              <span class="text-red-500">* </span>
              <span class="inline-flex items-center">
                Minimum withdrawal
                <UIcon name="i-mdi:currency-bdt" class="text-base" />{{ min_withdrawal }}</span
              >
            </p>
            <p class="text-sm"><span class="text-red-500">*</span> 2.95% Charges applicable</p>
            <p v-if="errors?.insufficient" class="text-sm text-red-500">
              You do not have enough balance
            </p>
            <p v-if="errors?.min_withdrawal" class="text-sm text-red-500">
              Minimum withdrawal amount is ৳200
            </p>
          </div>
          <div class="my-5">
            <!-- Modern Terms & Conditions Checkbox -->
            <UFormGroup
              class="flex flex-row-reverse justify-end gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
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
            <p v-if="errors?.policy" class="text-sm text-red-500">Check this field</p>
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
            <UButton v-else size="sm" @click="isOpen = true">{{ $t("withdraw") }}</UButton>
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
            />            <CommonQrCodeModal
              v-model="showQr"
              title="Scan My QR Code"
              :qr-data="user.user.phone"
              size="250x250"
            />
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

                  <h3 class="text-xl font-semibold text-green-700">AdsyPay</h3>
                  <h3 class="text-base font-semibold capitalize">
                    Point camera on the payee's QR code
                  </h3>

                  <qrcode-stream
                    @scanned="
                      res => {
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
            <p class="text-sm text-red-500">{{ transferErrors.contact }}</p>            <UInput
              icon="i-heroicons-banknotes"
              type="number"
              size="md"
              color="white"
              placeholder="Amount"
              class="my-3"
              min="0"
              step="0.01"
              v-model="transfer.payable_amount"
              @input="validateAmountInput('transfer')"
            />            <p class="text-sm text-red-500 mb-2" v-if="transferErrors.transfer">
              {{ transferErrors.limit || transferErrors.transfer }}
            </p>
            <p class="text-sm text-red-500" v-if="transferErrors.min_transfer">
              {{ transferErrors.min_transfer }}
            </p>
            <p class="text-sm text-red-500">
              {{ transferErrors.payable_amount }}
            </p>
            <p class="text-sm py-2">
              <span class="text-blue-600">* </span>
              <span class="inline-flex items-center">
                Minimum transfer
                <UIcon name="i-mdi:currency-bdt" class="text-base" />{{ min_transfer }}</span
              >
            </p>
            <UFormGroup
              class="flex flex-row-reverse justify-end gap-2"
              :ui="{
                label: {
                  base: 'block font-medium text-gray-800 dark:text-slate-700',
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
        class="text-center text-lg md:text-2xl font-semibold mt-8"
        v-if="statements?.length || receivedTransactions?.length"
      >
        {{ $t("transaction_history") }}
      </h3>

      <!-- Transaction Tabs -->
      <div
        class="flex justify-center my-4"
        v-if="statements?.length || receivedTransactions?.length"
      >
        <div class="inline-flex rounded-md shadow-sm bg-gray-100" role="group">
          <button
            @click="transactionTab = 'sent'"
            type="button"
            class="px-4 py-2 text-sm font-medium border border-gray-200 rounded-l-lg"
            :class="{
              'bg-primary-600 text-white': transactionTab === 'sent',
              'bg-white text-gray-800 hover:bg-gray-50': transactionTab !== 'sent',
            }"
          >
            Sent Transactions
          </button>
          <button
            @click="transactionTab = 'received'"
            type="button"
            class="px-4 py-2 text-sm font-medium border border-gray-200 rounded-r-lg"
            :class="{
              'bg-primary-600 text-white': transactionTab === 'received',
              'bg-white text-gray-800 hover:bg-gray-50': transactionTab !== 'received',
            }"
          >
            Received Transactions
          </button>
        </div>
      </div>

      <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex max-sm:justify-between gap-2">            <USelect
              v-model="filters.type"
              :options="transactionTypeOptions.map(option => ({ name: option.label, value: option.value }))"
              option-attribute="name"
              value-attribute="value"
              placeholder="Filter by type"
            />
            
            <USelect
              v-model="filters.status"
              :options="transactionStatusOptions.map(option => ({ name: option.label, value: option.value }))"
              option-attribute="name" 
              value-attribute="value"
              placeholder="Filter by status"
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
        <UTable :columns="columns" :rows="paginatedTransactions">          <template #type-data="{ row }">
            <div class="flex items-center">
              <!-- Deposit icon -->
              <span
                v-if="row.transaction_type?.toLowerCase() === 'deposit'"
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
              
              <!-- Withdraw icon -->
              <span
                v-else-if="row.transaction_type?.toLowerCase() === 'withdraw'"
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
              
              <!-- Transfer icon -->
              <span 
                v-else-if="row.transaction_type?.toLowerCase() === 'transfer'" 
                class="flex-shrink-0 h-5 w-5 text-blue-500"
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
                  <path d="M8 3 4 7l4 4" />
                  <path d="M4 7h16" />
                  <path d="m16 21 4-4-4-4" />
                  <path d="M20 17H4" />
                </svg>
              </span>
              
              <!-- Diamond transactions icon -->
              <span
                v-else-if="row.transaction_type?.toLowerCase().startsWith('diamond_')"
                class="flex-shrink-0 h-5 w-5 text-purple-500"
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
                  <path d="M16 2H8l-4 6h16l-4-6z" />
                  <path d="M4 8l8 14 8-14-8 14z" />
                </svg>
              </span>
              
              <!-- Mobile recharge icon -->
              <span
                v-else-if="row.transaction_type?.toLowerCase() === 'mobile_recharge'"
                class="flex-shrink-0 h-5 w-5 text-blue-500"
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
                  <rect x="7" y="2" width="10" height="20" rx="2" />
                  <path d="m12 17 .01.01" />
                  <path d="M12 7V6.02" />
                </svg>
              </span>
              
              <!-- Purchase icon -->
              <span
                v-else-if="row.transaction_type?.toLowerCase() === 'order_payment'"
                class="flex-shrink-0 h-5 w-5 text-green-600"
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
                  <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                  <path d="M3 6h18" />
                  <path d="M16 10a4 4 0 0 1-8 0" />
                </svg>
              </span>
              
              <!-- Subscription icon -->
              <span
                v-else-if="row.transaction_type?.toLowerCase() === 'pro_subscription'"
                class="flex-shrink-0 h-5 w-5 text-amber-500"
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
                  <path d="M12 2L5 12l7 10 7-10z" />
                  <path d="M5 12h14" />
                </svg>
              </span>
              
              <!-- Commission icon -->
              <span
                v-else-if="row.transaction_type?.toLowerCase() === 'referral_commission'"
                class="flex-shrink-0 h-5 w-5 text-yellow-500"
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
                  <path d="M18 16a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
                  <path d="M6 10a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
                  <path d="M6 20a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
                  <path d="m15 13-3-2" />
                  <path d="m15 17-3 2" />
                  <path d="M9 7 6 5" />
                </svg>
              </span>
              
              <!-- Default icon for other types -->
              <span v-else class="flex-shrink-0 h-5 w-5 text-gray-600">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <circle cx="12" cy="12" r="10" />
                  <path d="M12 16v-4" />
                  <path d="M12 8h.01" />
                </svg>
              </span>
              
              <!-- Display transaction type name -->
              <span class="ml-2 text-sm text-gray-800">
                {{ getTransactionTypeName(row.transaction_type) }}
              </span>
            </div>          </template>          <template #recipient-data="{ row }">
            <!-- Show recipient details if available -->
            <div class="text-sm text-gray-600 capitalize" v-if="row?.to_user_details">
              {{ row.to_user_details.first_name }}
              {{ row.to_user_details.last_name }}
            </div>
              <!-- For self-transactions like deposits, purchases, etc. show "Myself" -->
            <div class="text-sm text-gray-600" v-else-if="['deposit', 'diamond_purchase', 'pro_subscription', 'mobile_recharge', 'order_payment', 'diamond_bonus', 'diamond_refund', 'diamond_admin'].includes(row.transaction_type?.toLowerCase())">
              Myself
            </div>
            
            <!-- For withdraw transactions, show payment method and number in recipients -->
            <div class="text-sm text-gray-600" v-else-if="row.transaction_type?.toLowerCase() === 'withdraw'">
              {{ row.payment_method ? (row.payment_method.charAt(0).toUpperCase() + row.payment_method.slice(1)) : 'N/A' }}
              <span v-if="row.card_number" class="block text-xs text-gray-500 font-mono">{{ row.card_number }}</span>
            </div>
            
            <!-- For diamond transactions without recipient -->
            <div class="text-sm text-gray-600" v-else-if="row.transaction_type?.toLowerCase()?.startsWith('diamond_') && !row.to_user_details">
              Personal Account
            </div>
          </template>          <template #sender-data="{ row }">
            <!-- Show sender details if available -->
            <div class="text-sm text-gray-600 capitalize" v-if="row?.user_details">
              {{ row.user_details.first_name }}
              {{ row.user_details.last_name }}
            </div>
            
            <!-- For system-generated transactions -->
            <div class="text-sm text-gray-600" v-else-if="row.transaction_type?.toLowerCase()?.includes('system') || row.transaction_type?.toLowerCase()?.includes('admin')">
              System
            </div>
              <!-- For payments to self -->
            <div class="text-sm text-gray-600" v-else-if="['deposit', 'diamond_purchase'].includes(row.transaction_type?.toLowerCase())">
              Payment Gateway
            </div>
            
            <!-- For system-generated diamond additions -->
            <div class="text-sm text-gray-600" v-else-if="['diamond_bonus', 'diamond_refund'].includes(row.transaction_type?.toLowerCase())">
              System
            </div>
          </template>          <template #method-data="{ row }">
            <div class="text-sm text-gray-600 capitalize">
              {{ row?.payment_method }}
              <span v-if="row?.transaction_type?.toLowerCase() === 'withdraw' && row?.card_number" class="block text-xs text-gray-500 font-mono">
                {{ row.card_number }}
              </span>
            </div>
          </template>
          <template #time-data="{ row }">
            <div class="text-sm text-gray-600">
              {{ formatDate(row.created_at) }}
            </div>
          </template>          <template #amount-data="{ row }">
            <div
              class="text-sm font-medium"
              :class="{
                'text-green-600': ['deposit', 'diamond_bonus', 'diamond_refund', 'referral_commission'].includes(row.transaction_type?.toLowerCase()),
                'text-red-600': ['withdraw', 'diamond_purchase', 'pro_subscription', 'order_payment', 'mobile_recharge'].includes(row.transaction_type?.toLowerCase()),
                'text-blue-600': row.transaction_type?.toLowerCase() === 'transfer',
                'text-purple-600': row.transaction_type?.toLowerCase()?.startsWith('diamond_') && !['diamond_bonus', 'diamond_refund', 'diamond_purchase'].includes(row.transaction_type?.toLowerCase()),
                'text-gray-800': !row.transaction_type
              }"
            >              {{ 
                formatAmount(
                  row.amount !== '0.00' ? 
                  row.amount : 
                  (row.payable_amount || row.cost || 0), 
                  row.transaction_type?.toLowerCase()
                ) 
              }}              <span v-if="row.transaction_type?.toLowerCase()?.startsWith('diamond_')" class="text-xs ml-1 whitespace-nowrap">
                ({{ row.diamonds || parseInt(row.quantity) || row.quantity || row.amount || 0 }} 💎)
              </span>
            </div>
          </template>          <template #status-data="{ row }">
            <span
              class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
              :class="{
                'bg-green-100 text-green-800': 
                  row.bank_status === 'completed' || row.status === 'completed' || row.completed,
                'bg-yellow-100 text-yellow-800': 
                  row.bank_status === 'pending' || row.status === 'pending' || (!row.completed && !row.rejected),
                'bg-red-100 text-red-800': 
                  row.bank_status === 'failed' || row.bank_status === 'rejected' ||
                  row.status === 'failed' || row.status === 'rejected' ||
                  row.rejected
              }"
            >
              {{ 
                (row.bank_status || row.status || 
                  (row.completed ? 'Completed' : (row.rejected ? 'Rejected' : 'Pending'))
                ).charAt(0).toUpperCase() + 
                (row.bank_status || row.status || 
                  (row.completed ? 'Completed' : (row.rejected ? 'Rejected' : 'Pending'))
                ).slice(1) 
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
        <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
          <div>
            <p class="text-sm text-gray-800">
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
                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
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
                class="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
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
                    : 'bg-white border-gray-300 text-gray-600 hover:bg-gray-50',
                  'relative inline-flex items-center px-4 py-2 border text-sm font-medium',
                ]"
              >
                {{ page }}
              </button>

              <button
                @click="goToPage(currentPage + 1)"
                :disabled="currentPage === totalPages"
                class="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
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
                class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
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
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-800 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          <p class="text-sm text-gray-800">
            Page <span class="font-medium">{{ currentPage }}</span> of
            <span class="font-medium">{{ totalPages }}</span>
          </p>
          <button
            @click="goToPage(currentPage + 1)"
            :disabled="currentPage === totalPages"
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-800 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
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
        container: 'flex min-h-full items-center justify-center text-center max-w-sm w-full',
      }"
    >
      <div class="flex items-center justify-center" v-if="!showSuccess">
        <div class="w-full max-w-sm">
          <!-- Glass Card Effect -->
          <div
            class="backdrop-blur-lg rounded-xl bg-slate-100 p-2 shadow-sm border border-white/20"
          >
            <div class="border p-4 bg-slate-50 rounded-xl">
              <!-- Title -->
              <h2 class="text-lg font-medium text-gray-800 mb-4">Confirm Transfer</h2>

              <!-- Transfer Details -->
              <div class="space-y-4 mb-6">
                <div class="flex justify-between items-center">
                  <p class="text-gray-600 text-xs">Transfer amount</p>
                  <p class="text-gray-800 text-lg font-semibold">
                    <UIcon name="i-mdi:currency-bdt" class="" />
                    {{ transfer?.payable_amount }}
                  </p>
                </div>

                <div class="space-y-3">
                  <!-- Recipient Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-600">Recipient:</label>
                    <p class="text-sm text-gray-800 font-medium" v-if="transfer?.to_user">
                      {{ transfer?.to_user }}
                    </p>
                  </div>

                  <!-- Email Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-600">Email:</label>
                    <p class="text-sm text-gray-800 font-medium">
                      {{ transfer?.contact }}
                    </p>
                  </div>

                  <!-- Name Field -->
                  <!-- <div class="space-y-1">
                  <label class="text-xs text-gray-600">Name:</label>
                  <p class="text-sm text-gray-800 font-medium">John Smith</p>
                </div> -->                  <!-- Time Field -->
                  <div class="flex items-center gap-2">
                    <label class="text-xs text-gray-600">Time:</label>
                    <span
                      class="px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium"
                    >
                      Instant
                    </span>
                  </div>
                </div>
              </div>              <!-- Password Confirmation -->
              <div class="mb-6">
                <div class="space-y-2">
                  <label class="text-xs text-gray-600 font-medium">Enter your password to confirm:</label>
                  <UInput
                    v-model="transfer.password"
                    type="password"
                    placeholder="Enter your password"
                    size="md"
                    :ui="{
                      base: 'w-full',
                      rounded: 'rounded-lg',
                      placeholder: 'placeholder-gray-400',
                      color: {
                        white: {
                          outline: 'shadow-sm bg-white dark:bg-gray-900 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-300 dark:ring-gray-700 focus:ring-2 focus:ring-primary-500 dark:focus:ring-primary-400'
                        }
                      }
                    }"
                    class="text-sm"
                    autocomplete="current-password"
                    @input="passwordError = ''"
                  />
                  <div v-if="passwordError" class="text-red-600 text-xs mt-1 font-medium">
                    {{ passwordError }}
                  </div>
                </div>
              </div>

              <!-- Final Amount -->
              <div class="flex justify-between items-center mb-6 pt-4 border-t border-gray-200">
                <p class="text-xs text-gray-600">Final amount</p>
                <p class="text-gray-800 font-semibold">
                  <UIcon name="i-mdi:currency-bdt" class="" />
                  {{ transfer?.payable_amount }}
                </p>
              </div>              <!-- Confirm Button -->
              <UButton
                @click="handleTransfer"
                :disabled="!transfer.password || isLoading"
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
            class="backdrop-blur-lg bg-slate-100 rounded-xl p-2 shadow-sm border border-white/20 w-full"
          >
            <div class="border bg-slate-50 p-4 rounded-xl">
              <!-- Title and Success Icon -->
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-lg sm:text-xl font-semibold text-green-700">
                  Transfer Successful
                </h2>
                <UIcon name="i-rivet-icons-check-circle-breakout" class="size-7 text-green-700" />
              </div>

              <!-- Transfer Details -->
              <div class="space-y-4 mb-6">
                <div class="flex justify-between items-center">
                  <p class="text-gray-600 text-xs">Transferred amount</p>
                  <p class="text-gray-800 text-lg font-semibold">
                    <UIcon name="i-mdi:currency-bdt" class="" />
                    {{ transfer?.payable_amount }}
                  </p>
                </div>

                <div class="space-y-3">
                  <!-- Recipient Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-600">Recipient:</label>
                    <p class="text-sm sm:text-lg text-gray-800 font-medium">
                      {{ transfer?.to_user }}
                    </p>
                  </div>

                  <!-- Email Field -->
                  <div class="space-y-1">
                    <label class="text-xs text-gray-600">Email:</label>
                    <p class="text-sm text-gray-800 font-medium">
                      {{ transfer?.contact }}
                    </p>
                  </div>

                  <div class="flex items-center gap-2">
                    <label class="text-xs text-gray-600">Time:</label>
                    <span
                      class="px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium"
                    >
                      Completed
                    </span>
                  </div>
                </div>
              </div>

              <!-- Final Amount -->
              <div class="flex justify-between items-center mb-6 pt-4 border-t border-gray-200">
                <p class="text-xs text-gray-600">Final amount</p>
                <p class="text-gray-800 font-semibold sm:text-lg">
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
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <!-- Background overlay -->
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
          @click="showDetailsModal = false"
        ></div>

        <!-- Modal panel -->
        <div
          class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="flex items-start">
              <div class="mt-3 sm:mt-0 sm:ml-4 text-left w-full">
                <h3 class="text-lg leading-6 font-medium text-gray-800 py-2" id="modal-title">
                  Transaction Details
                </h3>
                <div class="mt-4 border-t border-gray-200 pt-4">
                  <dl class="divide-y divide-gray-200">
                    <div class="py-3 grid grid-cols-3 gap-4">
                      <dt class="text-sm font-medium text-gray-600">Transaction ID</dt>
                      <dd class="text-sm text-gray-800 mt-0 col-span-2 font-mono">
                        {{ selectedTransaction?.id }}
                      </dd>
                    </div>                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Type</dt>
                      <dd
                        class="text-sm text-gray-800 mt-0 col-span-2 flex items-center"
                      >
                        <!-- Deposit icon -->
                        <span
                          v-if="selectedTransaction?.transaction_type === 'deposit'"
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
                          >
                            <path d="M12 5v14" />
                            <path d="m19 12-7 7-7-7" />
                          </svg>
                        </span>
                        
                        <!-- Withdraw icon -->
                        <span
                          v-else-if="selectedTransaction?.transaction_type === 'withdraw'"
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
                          >
                            <path d="M12 19V5" />
                            <path d="m5 12 7-7 7 7" />
                          </svg>
                        </span>
                        
                        <!-- Diamond icons -->
                        <span
                          v-else-if="selectedTransaction?.transaction_type?.startsWith('diamond_')"
                          class="flex-shrink-0 h-5 w-5 text-purple-500 mr-2"
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
                            <path d="M16 2H8l-4 6h16l-4-6z" />
                            <path d="M4 8l8 14 8-14-8 14z" />
                          </svg>
                        </span>
                        
                        <!-- Mobile recharge icon -->
                        <span
                          v-else-if="selectedTransaction?.transaction_type === 'mobile_recharge'"
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
                          >
                            <rect x="7" y="2" width="10" height="20" rx="2" />
                            <path d="m12 17 .01.01" />
                            <path d="M12 7V6.02" />
                            <path d="M16 9 8 9" />
                            <path d="M16 12 8 12" />
                          </svg>
                        </span>
                        
                        <!-- Subscription icon -->
                        <span
                          v-else-if="selectedTransaction?.transaction_type === 'pro_subscription'"
                          class="flex-shrink-0 h-5 w-5 text-amber-500 mr-2"
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
                            <path d="M12 2L5 12l7 10 7-10z" />
                            <path d="M5 12h14" />
                          </svg>
                        </span>
                        
                        <!-- Transfer icon -->
                        <span
                          v-else-if="selectedTransaction?.transaction_type === 'transfer'"
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
                          >
                            <path d="M8 3 4 7l4 4" />
                            <path d="M4 7h16" />
                            <path d="m16 21 4-4-4-4" />
                            <path d="M20 17H4" />
                          </svg>
                        </span>
                        
                        <!-- Purchase icon -->
                        <span
                          v-else-if="selectedTransaction?.transaction_type === 'order_payment'"
                          class="flex-shrink-0 h-5 w-5 text-green-600 mr-2"
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
                            <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                            <path d="M3 6h18" />
                            <path d="M16 10a4 4 0 0 1-8 0" />
                          </svg>
                        </span>
                        
                        <!-- Commission icon -->
                        <span
                          v-else-if="selectedTransaction?.transaction_type === 'referral_commission'"
                          class="flex-shrink-0 h-5 w-5 text-yellow-500 mr-2"
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
                            <path d="M18 16a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
                            <path d="M6 10a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
                            <path d="M6 20a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
                            <path d="m15 13-3-2" />
                            <path d="m15 17-3 2" />
                            <path d="M9 7 6 5" />
                          </svg>
                        </span>
                        
                        <!-- Default icon for other types -->
                        <span v-else class="flex-shrink-0 h-5 w-5 text-gray-600 mr-2">
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <circle cx="12" cy="12" r="10" />
                            <path d="M12 16v-4" />
                            <path d="M12 8h.01" />
                          </svg>
                        </span>
                        
                        <!-- Transaction type name -->
                        {{ getTransactionTypeName(selectedTransaction?.transaction_type) }}
                      </dd>
                    </div>                    <!-- Sender information -->
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Sender</dt>
                      
                      <!-- When sender details are available -->
                      <dd
                        v-if="selectedTransaction?.user_details"
                        class="text-sm text-gray-800 mt-0 col-span-2 font-mono"
                      >
                        <p>{{ selectedTransaction?.user_details?.name || '' }}</p>
                        <p>{{ selectedTransaction?.user_details?.phone || '' }}</p>
                        {{ selectedTransaction?.user_details?.email || '' }}
                      </dd>
                      
                      <!-- For payments through gateway -->
                      <dd v-else-if="['deposit', 'diamond_purchase'].includes(selectedTransaction?.transaction_type)" 
                          class="text-sm text-gray-800 mt-0 col-span-2">
                        Payment Gateway
                      </dd>
                      
                      <!-- For system-generated transactions -->
                      <dd v-else-if="['diamond_bonus', 'diamond_refund', 'diamond_admin'].includes(selectedTransaction?.transaction_type) || selectedTransaction?.transaction_type?.toLowerCase()?.includes('system')" 
                          class="text-sm text-gray-800 mt-0 col-span-2">
                        System
                      </dd>
                      
                      <!-- For other transactions -->
                      <dd v-else class="text-sm text-gray-800 mt-0 col-span-2">
                        Unknown
                      </dd>
                    </div>
                    
                    <!-- Recipient information -->
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Recipient</dt>
                      
                      <!-- When recipient details are available -->
                      <dd
                        v-if="selectedTransaction?.to_user_details"
                        class="text-sm text-gray-800 mt-0 col-span-2 font-mono"
                      >
                        <p>
                          {{ selectedTransaction?.to_user_details?.phone }}
                        </p>
                        {{ selectedTransaction?.to_user_details?.email }}
                      </dd>
                        <!-- For self-transactions like deposits, purchases -->
                      <dd v-else-if="['deposit', 'diamond_purchase', 'pro_subscription', 'mobile_recharge', 'order_payment', 'diamond_bonus', 'diamond_refund', 'diamond_admin'].includes(selectedTransaction?.transaction_type)" 
                          class="text-sm text-gray-800 mt-0 col-span-2">
                        Myself
                      </dd>
                      
                      <!-- For diamond transactions without recipient -->
                      <dd v-else-if="selectedTransaction?.transaction_type?.startsWith('diamond_') && !selectedTransaction?.to_user_details"
                          class="text-sm text-gray-800 mt-0 col-span-2">
                        Personal Account
                      </dd>                        <!-- For withdraw transactions, show payment method and number -->
                      <dd v-else-if="selectedTransaction?.transaction_type?.toLowerCase() === 'withdraw'" class="text-sm text-gray-800 mt-0 col-span-2">
                        {{ selectedTransaction?.payment_method ? (selectedTransaction?.payment_method.charAt(0).toUpperCase() + selectedTransaction?.payment_method.slice(1)) : 'N/A' }} 
                        <span v-if="selectedTransaction?.card_number" class="block mt-1 font-mono">
                          Account: {{ selectedTransaction?.card_number }}
                        </span>
                      </dd>
                      <!-- For other transactions, show payment method if available -->
                      <dd v-else class="text-sm text-gray-800 mt-0 col-span-2">
                        {{ selectedTransaction?.payment_method || 'N/A' }}
                      </dd>
                    </div>
                    
                    <!-- Name information -->
                    <div v-if="selectedTransaction?.to_user_details" class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Name</dt>
                      <dd class="text-sm text-gray-800 mt-0 col-span-2">
                        {{ selectedTransaction?.to_user_details.name }}
                      </dd>
                    </div>
                      <!-- Diamond transaction details -->                    <div v-if="selectedTransaction?.transaction_type?.startsWith('diamond_')" class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Diamond Count</dt>
                      <dd class="text-sm text-gray-800 mt-0 col-span-2">
                        {{ selectedTransaction?.diamonds || parseInt(selectedTransaction?.quantity) || selectedTransaction?.quantity || selectedTransaction?.amount || 0 }} 💎
                      </dd>
                    </div>
                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Date & Time</dt>
                      <dd class="text-sm text-gray-800 mt-0 col-span-2">
                        {{ formatDate(selectedTransaction?.created_at) }}
                      </dd>
                    </div>                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Amount</dt>
                      <dd
                        class="text-sm font-medium mt-0 col-span-2"
                        :class="{
                          'text-green-600': ['deposit', 'diamond_bonus', 'diamond_refund', 'referral_commission'].includes(selectedTransaction?.transaction_type),
                          'text-red-600': ['withdraw', 'diamond_purchase', 'pro_subscription', 'order_payment', 'mobile_recharge'].includes(selectedTransaction?.transaction_type),
                          'text-blue-600': selectedTransaction?.transaction_type === 'transfer',
                          'text-purple-600': selectedTransaction?.transaction_type?.startsWith('diamond_') && !['diamond_bonus', 'diamond_refund', 'diamond_purchase'].includes(selectedTransaction?.transaction_type),
                          'text-gray-800': !selectedTransaction?.transaction_type
                        }"
                      >                        {{
                          selectedTransaction
                            ? formatAmount(
                                selectedTransaction.amount !== '0.00' ? 
                                selectedTransaction.amount : 
                                (selectedTransaction.payable_amount || selectedTransaction.cost || 0),
                                selectedTransaction.transaction_type?.toLowerCase()
                              )
                            : ""
                        }}
                      </dd>
                    </div>                    <div class="py-3 grid grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-600">Status</dt>
                      <dd class="text-sm text-gray-800 mt-0 col-span-2">
                        <span
                          v-if="selectedTransaction"
                          class="px-2 inline-flex text-sm leading-5 font-medium rounded-full capitalize"
                          :class="{
                            'bg-green-100 text-green-800':
                              (selectedTransaction?.bank_status === 'completed' || selectedTransaction?.status === 'completed' || selectedTransaction?.completed),
                            'bg-yellow-100 text-yellow-800':
                              (selectedTransaction?.bank_status === 'pending' || selectedTransaction?.status === 'pending' || (!selectedTransaction?.completed && !selectedTransaction?.rejected)),
                            'bg-red-100 text-red-800': 
                              (selectedTransaction?.bank_status === 'failed' || selectedTransaction?.bank_status === 'rejected' || 
                              selectedTransaction?.status === 'failed' || selectedTransaction?.status === 'rejected' || 
                              selectedTransaction?.rejected)
                          }"
                        >
                          {{ 
                            selectedTransaction?.bank_status || 
                            selectedTransaction?.status || 
                            (selectedTransaction?.completed ? 'Completed' : 
                              (selectedTransaction?.rejected ? 'Rejected' : 'Pending'))
                          }}
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
const min_withdrawal = ref(200);
const min_deposit = ref(100);
const min_transfer = ref(50);
const currentTab = ref(1);
const transactionTab = ref("sent"); // 'sent' or 'received'
const selected = ref("nagad");
const payment_number = ref(null);
const errors = ref({});
const depositErrors = ref({});
const isLoading = ref(false);
const isDepositLoading = ref(false);
const isWithdrawLoading = ref(false);
const selectedTransaction = ref(null);
const showDetailsModal = ref(false);
const receivedTransactions = ref([]);
async function receivedTransactionsFetch() {
  try {
    const { data } = await get("/received-transfers/");
    console.log(data, "received");
    receivedTransactions.value = data;  } catch (error) {
    toast.add({
      title: "📊 Failed to Load Data",
      description: `Unable to load received transactions. Please try again.`,
      icon: "i-heroicons-exclamation-circle-20-solid",
      color: "red",
      timeout: 6000,
      actions: [{
        label: 'Retry',
        click: () => receivedTransactionsFetch()
      }]
    });
    console.error("Error fetching received transactions:", error);
  }
}

await receivedTransactionsFetch();

const columns = computed(() => {
  // Always show type, time, amount, status, and action columns
  const baseColumns = [
    {
      key: "type",
      label: "Type",
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

  // Add payment method column for deposit/withdraw transactions
  if (filters.value.type === 'deposit' || filters.value.type === 'withdraw') {
    baseColumns.splice(3, 0, {
      key: "method",
      label: "Method",
    });
  }

  // Add sender/recipient columns based on active tab
  // But only if diamond transaction types are not being filtered
  if (!filters.value.type?.startsWith('diamond_')) {
    if (transactionTab.value === "sent") {
      baseColumns.splice(1, 0, {
        key: "recipient",
        label: "Recipient",
      });
    } else {
      baseColumns.splice(1, 0, {
        key: "sender",
        label: "Sender",
      });
    }
  }

  return baseColumns;
});

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

// Filter transactions based on selected filters and active tab
const filteredTransactions = computed(() => {
  const activeTransactions =
    transactionTab.value === "sent" ? statements.value : receivedTransactions.value;

  return activeTransactions.filter(transaction => {
    // Skip transactions without transaction_type
    if (!transaction.transaction_type) return false;
    
    // Group transaction types for filtering
    const transactionGroup = getTransactionGroup(transaction.transaction_type.toLowerCase());
    
    // Handle Type filter (by group)
    if (filters.value.type) {
      // For diamond transactions, check if it starts with diamond_
      if (filters.value.type === 'diamond' && !transaction.transaction_type.toLowerCase().startsWith('diamond_')) {
        return false;
      }
      // For specific diamond transaction types
      else if (filters.value.type.startsWith('diamond_') && transaction.transaction_type.toLowerCase() !== filters.value.type) {
        return false;
      }
      // For other transaction groups
      else if (!filters.value.type.startsWith('diamond_') && filters.value.type !== 'diamond' && transactionGroup !== filters.value.type) {
        return false;
      }
    }

    // Handle Status filter - check multiple status fields
    if (filters.value.status) {
      const transactionStatus = transaction.bank_status || 
                               transaction.status || 
                               (transaction.completed ? 'completed' : 
                                 (transaction.rejected ? 'rejected' : 'pending'));
                                 
      if (transactionStatus !== filters.value.status) {
        return false;
      }
    }

    // Search across all relevant fields
    if (filters.value.search) {
      const searchTerm = filters.value.search.toLowerCase();
      
      // Build array of all searchable fields from the transaction
      const searchableFields = [
        // Payment information
        transaction.payment_method?.toLowerCase() || "",
        
        // Amount fields
        transaction.payable_amount?.toString() || "",
        transaction.amount?.toString() || "",
        transaction.cost?.toString() || "",
        
        // Type and status
        transaction.transaction_type?.toLowerCase() || "",
        getTransactionTypeName(transaction.transaction_type)?.toLowerCase() || "",
        transaction.bank_status?.toLowerCase() || "",
        transaction.status?.toLowerCase() || "",
        
        // Description and notes
        transaction.description?.toLowerCase() || "",
        transaction.notes?.toLowerCase() || "",
        
        // Diamond count for diamond transactions
        (transaction.transaction_type?.toLowerCase().startsWith('diamond_') ? 
          transaction.diamonds?.toString() + " diamonds" : ""),
          
        // User details
        transaction.user_details?.name?.toLowerCase() || "",
        transaction.user_details?.email?.toLowerCase() || "",
        transaction.user_details?.phone?.toLowerCase() || "",
        transaction.to_user_details?.name?.toLowerCase() || "",
        transaction.to_user_details?.email?.toLowerCase() || "",
        transaction.to_user_details?.phone?.toLowerCase() || ""
      ];

      if (!searchableFields.some(field => field.includes(searchTerm))) {
        return false;
      }
    }

    return true;
  });
});

// Pagination
const totalPages = computed(() => Math.ceil(filteredTransactions.value.length / itemsPerPage));

const paginatedTransactions = computed(() => {
  return filteredTransactions.value.slice(startIndex.value, startIndex.value + itemsPerPage);
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
  // Ensure amount is properly formatted
  const formattedAmount = amount ? parseFloat(amount).toFixed(2) : "0.00";
  
  // Types that increase balance (positive)
  const positiveTypes = [
    "deposit", 
    "diamond_bonus", 
    "diamond_refund", 
    "referral_commission", 
    "diamond_gift_received"
  ];
  
  // Types that decrease balance (negative)
  const negativeTypes = [
    "withdraw", 
    "transfer", 
    "diamond_purchase", 
    "diamond_gift", 
    "pro_subscription", 
    "order_payment", 
    "mobile_recharge"
  ];
  
  if (positiveTypes.includes(type)) {
    return `+৳${formattedAmount}`;
  } else if (negativeTypes.includes(type)) {
    return `-৳${formattedAmount}`;
  }
  
  // Default formatting for unknown types
  return `৳${formattedAmount}`;
}

// Open transaction details modal with enhanced handling for all transaction types
function openTransactionDetails(transaction) {
  // Create a copy of the transaction to avoid modifying the original
  const enhancedTransaction = { ...transaction };
  
  // Ensure consistent transaction type case for comparison
  if (enhancedTransaction.transaction_type) {
    enhancedTransaction.transaction_type = enhancedTransaction.transaction_type.toLowerCase();
  }
  
  // Handle status field consistency
  const status = enhancedTransaction.bank_status || 
                enhancedTransaction.status || 
                (enhancedTransaction.completed ? 'completed' : 
                  (enhancedTransaction.rejected ? 'rejected' : 'pending'));
                    enhancedTransaction.bank_status = status;
      // For diamond transactions, make sure we have a consistent diamond count display
  if (enhancedTransaction.transaction_type?.startsWith('diamond_')) {
    // Get diamond count from any available field
    enhancedTransaction.diamonds = enhancedTransaction.diamonds || 
                                 parseInt(enhancedTransaction.quantity) || 
                                 enhancedTransaction.quantity || 
                                 enhancedTransaction.amount || 
                                 0;
    
    // If payment amount is missing, calculate it from diamonds
    if (!enhancedTransaction.amount && !enhancedTransaction.payable_amount && !enhancedTransaction.cost) {
      enhancedTransaction.amount = enhancedTransaction.diamonds * 10; // Assuming 10 BDT per diamond as default
    }
  }
    // For withdraw transactions, make sure we have proper amount display
  // The withdrawal amount is stored in payable_amount including fees
  if (enhancedTransaction.transaction_type === 'withdraw' && enhancedTransaction.payable_amount) {
    // The payable_amount includes the 2.95% fee, so we calculate the original withdrawal amount
    const payableAmount = parseFloat(enhancedTransaction.payable_amount);
    const originalAmount = payableAmount / 1.0295; // Reversing the fee calculation
    enhancedTransaction.amount = originalAmount.toFixed(2); // Set the amount to display
  }
  
  selectedTransaction.value = enhancedTransaction;
  showDetailsModal.value = true;
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
  password: "",
});

const transferErrors = ref({});
const passwordError = ref("");

// Fetch transaction history - gets all transaction types
const getTransactionHistory = async () => {
  try {
    isLoading.value = true;
    
    // 1. Get balance transactions (deposits, withdrawals, transfers)
    const balanceRes = await get(`/user-balance/${user.value.user.email}/`);
    const balanceData = balanceRes.data || [];
      // 2. Get diamond transactions
    const diamondRes = await get(`/diamonds-transactions/`);    const diamondData = (diamondRes.data?.results || diamondRes.data || []).map(item => ({
      ...item,
      transaction_type: `diamond_${item.transaction_type}`,
      payable_amount: item.cost,
      amount: item.cost,
      diamonds: item.diamonds || parseInt(item.quantity) || item.amount || 0, // Ensure diamonds count is captured from all possible fields
      bank_status: item.completed ? 'completed' : (item.rejected ? 'rejected' : 'pending')
    }));

    // 3. Combine all transactions
    statements.value = [...balanceData, ...diamondData].sort((a, b) => {
      const dateA = new Date(a.created_at || a.updated_at);
      const dateB = new Date(b.created_at || b.updated_at);
      return dateB - dateA; // Sort by date descending (newest first)
    });
    
    console.log("All transactions:", statements.value);
    currentPage.value = 1;  } catch (error) {
    toast.add({
      title: "📈 Transaction History Error",
      description: `Unable to load transaction history. Please refresh the page.`,
      icon: "i-heroicons-exclamation-triangle-20-solid",
      color: "red",
      timeout: 6000,
      actions: [{
        label: 'Retry',
        click: () => getTransactionHistory()
      }]
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

// Helper function to format error messages for user display
const formatErrorMessage = (error) => {
  // If error has a response with data
  if (error.response?.data) {
    const errorData = error.response.data;
    
    // Handle validation errors for specific fields
    if (typeof errorData === 'object' && errorData !== null) {
      // Check for amount validation errors
      if (errorData.amount) {
        const amountError = Array.isArray(errorData.amount) ? errorData.amount[0] : errorData.amount;
        
        // Convert common API error messages to user-friendly ones
        if (typeof amountError === 'string') {
          if (amountError.toLowerCase().includes('invalid') || amountError.toLowerCase().includes('not a valid number')) {
            return "Please enter a valid amount (numbers only)";
          }
          if (amountError.toLowerCase().includes('required') || amountError.toLowerCase().includes('field may not be blank')) {
            return "Amount is required";
          }
          if (amountError.toLowerCase().includes('minimum')) {
            return `Minimum amount is ৳${min_deposit.value}`;
          }
          if (amountError.toLowerCase().includes('maximum')) {
            return "Amount exceeds maximum limit";
          }
        }
        
        return amountError;
      }
      
      // Check for contact/user validation errors
      if (errorData.contact) {
        const contactError = Array.isArray(errorData.contact) ? errorData.contact[0] : errorData.contact;
        if (typeof contactError === 'string' && contactError.toLowerCase().includes('not found')) {
          return "User not found. Please check the email or phone number";
        }
        return contactError;
      }
      
      // Check for payment method errors
      if (errorData.payment_method) {
        const paymentError = Array.isArray(errorData.payment_method) ? errorData.payment_method[0] : errorData.payment_method;
        if (typeof paymentError === 'string' && paymentError.toLowerCase().includes('required')) {
          return "Please select a payment method";
        }
        return paymentError;
      }
      
      // Check for general validation errors
      if (errorData.error) {
        return errorData.error;
      }
      
      // Check for non_field_errors (common in Django REST framework)
      if (errorData.non_field_errors && Array.isArray(errorData.non_field_errors)) {
        const nonFieldError = errorData.non_field_errors[0];
        
        // Convert common non-field errors to user-friendly messages
        if (typeof nonFieldError === 'string') {
          if (nonFieldError.toLowerCase().includes('insufficient')) {
            return "Insufficient balance for this transaction";
          }
          if (nonFieldError.toLowerCase().includes('limit')) {
            return "Transaction limit exceeded";
          }
          if (nonFieldError.toLowerCase().includes('user not found')) {
            return "Recipient not found. Please check the contact information";
          }
        }
        
        return nonFieldError;
      }
      
      // Check for detail field
      if (errorData.detail) {
        const detailError = errorData.detail;
        
        // Convert common detail errors to user-friendly messages
        if (typeof detailError === 'string') {
          if (detailError.toLowerCase().includes('not found')) {
            return "The requested information was not found";
          }
          if (detailError.toLowerCase().includes('permission')) {
            return "You don't have permission to perform this action";
          }
          if (detailError.toLowerCase().includes('authentication')) {
            return "Please log in again to continue";
          }
        }
        
        return detailError;
      }
      
      // Handle field-specific validation errors
      const fieldErrors = [];
      const errorFields = {
        'payable_amount': 'Please enter a valid transfer amount',
        'card_number': 'Please enter a valid payment number',
        'phone': 'Please enter a valid phone number',
        'email': 'Please enter a valid email address'
      };
      
      Object.keys(errorData).forEach(field => {
        if (Array.isArray(errorData[field])) {
          errorData[field].forEach(msg => {
            // Convert field-specific errors to user-friendly messages
            if (errorFields[field] && typeof msg === 'string' && msg.toLowerCase().includes('invalid')) {
              fieldErrors.push(errorFields[field]);
            } else {
              fieldErrors.push(msg);
            }
          });
        } else if (typeof errorData[field] === 'string') {
          if (errorFields[field] && errorData[field].toLowerCase().includes('invalid')) {
            fieldErrors.push(errorFields[field]);
          } else {
            fieldErrors.push(errorData[field]);
          }
        }
      });
      
      if (fieldErrors.length > 0) {
        return fieldErrors[0]; // Return the first error message
      }
    }
    
    // If errorData is a string
    if (typeof errorData === 'string') {
      // Convert common string errors to user-friendly messages
      if (errorData.toLowerCase().includes('invalid characters')) {
        return "Please enter valid characters only";
      }
      if (errorData.toLowerCase().includes('network')) {
        return "Network error. Please check your connection and try again";
      }
      if (errorData.toLowerCase().includes('timeout')) {
        return "Request timeout. Please try again";
      }
      
      return errorData;
    }
  }
  
  // Handle specific error types
  if (error.message) {
    // Check for common validation patterns
    if (error.message.includes('amount') && error.message.includes('invalid')) {
      return "Please enter a valid amount (numbers only)";
    }
    if (error.message.includes('required')) {
      return "Please fill in all required fields";
    }
    if (error.message.includes('minimum')) {
      return `Minimum amount is ৳${min_deposit.value}`;
    }
    if (error.message.includes('balance')) {
      return "Insufficient balance for this transaction";
    }
    if (error.message.includes('not found') || error.message.includes('404')) {
      return "Information not found. Please check your input";
    }
    if (error.message.includes('network') || error.message.includes('fetch')) {
      return "Network error. Please check your connection and try again";
    }
    if (error.message.includes('timeout')) {
      return "Request timeout. Please try again";
    }
    if (error.message.includes('500') || error.message.includes('server')) {
      return "Server error. Please try again later";
    }
    if (error.message.includes('unauthorized') || error.message.includes('401')) {
      return "Session expired. Please log in again";
    }
    if (error.message.includes('forbidden') || error.message.includes('403')) {
      return "You don't have permission to perform this action";
    }
    
    // Return the error message if it's user-friendly (doesn't contain technical details)
    if (!error.message.includes('http://') && 
        !error.message.includes('https://') && 
        !error.message.includes('API') && 
        !error.message.toLowerCase().includes('fetch') &&
        !error.message.includes('XMLHttpRequest') &&
        !error.message.includes('TypeError') &&
        !error.message.includes('ReferenceError')) {
      return error.message;
    }
  }
  
  // Handle network errors
  if (error.code === 'NETWORK_ERROR' || error.name === 'NetworkError') {
    return "Network error. Please check your internet connection and try again";
  }
  
  // Handle timeout errors
  if (error.code === 'TIMEOUT' || error.name === 'TimeoutError') {
    return "Request timeout. Please try again";
  }
  
  // Default user-friendly message for unknown errors
  return "Something went wrong. Please check your input and try again.";
};

// Input validation function
const validateAmountInput = (type) => {
  let value;
  let errorField;
  
  switch(type) {
    case 'amount':
      value = amount.value;
      errorField = 'amount';
      break;
    case 'withdraw':
      value = withdrawAmount.value;
      errorField = 'withdrawAmount';
      break;
    case 'transfer':
      value = transfer.value.payable_amount;
      errorField = 'payable_amount';
      break;
  }
  
  // Clear previous errors for this field
  if (type === 'transfer') {
    if (transferErrors.value[errorField]) {
      delete transferErrors.value[errorField];
    }
  } else {
    if (errors.value[errorField]) {
      delete errors.value[errorField];
    }
    if (depositErrors.value[errorField]) {
      delete depositErrors.value[errorField];
    }
  }
  
  // Validate the input
  if (value !== null && value !== undefined && value !== '') {
    // Check if it's a valid number
    if (isNaN(value) || value < 0) {
      const errorMessage = "Please enter a valid amount (numbers only)";
      
      if (type === 'transfer') {
        transferErrors.value[errorField] = errorMessage;
      } else if (type === 'amount') {
        depositErrors.value[errorField] = errorMessage;
      } else {
        errors.value[errorField] = errorMessage;
      }
      
      // Show toast for immediate feedback
      toast.add({
        title: "❌ Invalid Input",
        description: errorMessage,
        icon: "i-heroicons-exclamation-triangle-20-solid",
        color: "amber",
        timeout: 3000,
      });
      return;
    }
    
    // Check for decimal places (max 2)
    const decimalPlaces = (value.toString().split('.')[1] || '').length;
    if (decimalPlaces > 2) {
      const errorMessage = "Amount can have maximum 2 decimal places";
      
      if (type === 'transfer') {
        transferErrors.value[errorField] = errorMessage;
      } else if (type === 'amount') {
        depositErrors.value[errorField] = errorMessage;
      } else {
        errors.value[errorField] = errorMessage;
      }
      
      toast.add({
        title: "❌ Invalid Format",
        description: errorMessage,
        icon: "i-heroicons-exclamation-triangle-20-solid",
        color: "amber",
        timeout: 3000,
      });
      return;
    }
    
    // Check for very large amounts (optional safeguard)
    if (parseFloat(value) > 1000000) {
      const errorMessage = "Amount cannot exceed 1,000,000";
      
      if (type === 'transfer') {
        transferErrors.value[errorField] = errorMessage;
      } else if (type === 'amount') {
        depositErrors.value[errorField] = errorMessage;
      } else {
        errors.value[errorField] = errorMessage;
      }
      
      toast.add({
        title: "❌ Amount Too Large",
        description: errorMessage,
        icon: "i-heroicons-exclamation-triangle-20-solid",
        color: "amber",
        timeout: 3000,
      });
    }
  }
};

// Deposit function
const deposit = async () => {
  depositErrors.value = {};

  if (!amount.value) {
    depositErrors.value.amount = true;
  }

  if (!policy.value) {
    depositErrors.value.policy = true;
  }
  
  // Validate amount format
  if (amount.value && (isNaN(amount.value) || amount.value <= 0)) {
    toast.add({
      title: "❌ Invalid Amount",
      description: "Please enter a valid amount (numbers only)",
      icon: "i-heroicons-exclamation-triangle-20-solid",
      color: "red",
      timeout: 5000,
    });
    return;
  }
  
  if (!amount.value || !policy.value) {
    toast.add({
      title: "⚠️ Missing Information",
      description: "Please fill in all required fields and accept the terms & conditions",
      icon: "i-heroicons-information-circle-20-solid",
      color: "amber",
      timeout: 5000,
    });
    return;
  }

  // Check minimum deposit amount
  if (Number(amount.value) < Number(min_deposit.value)) {
    depositErrors.value.min_deposit = true;
    return;
  }
  try {
    isDepositLoading.value = true;
    
    // Generate a unique order ID using timestamp
    const uniqueOrderId = `${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    
    // Validate required fields and provide defaults if missing
    const firstName = user.value.user.first_name || "User";
    const lastName = user.value.user.last_name || "";
    const address = user.value.user.address || "N/A";
    const phone = user.value.user.phone || "N/A";
    const city = user.value.user.city || "N/A";
    const zip = user.value.user.zip || "0000";
    
    // Create payment URL with proper encoding and validation
    const paymentUrl = `/pay/?amount=${encodeURIComponent(amount.value)}` +
      `&order_id=${encodeURIComponent(uniqueOrderId)}` +
      `&currency=BDT` +
      `&customer_name=${encodeURIComponent(firstName)}+${encodeURIComponent(lastName)}` +
      `&customer_address=${encodeURIComponent(address)}` +
      `&customer_phone=${encodeURIComponent(phone)}` +
      `&customer_city=${encodeURIComponent(city)}` +
      `&customer_post_code=${encodeURIComponent(zip)}`;
    
    console.log("Payment URL:", paymentUrl);
    
    const payment = await get(paymentUrl);
    
    if (payment.data?.checkout_url) {
      window.open(payment.data.checkout_url, "_blank");
    } else {
      console.error("Payment response:", payment);
      throw new Error("Failed to get payment URL. Please check your personal information in your profile.");
    }

    // Reset form and update data
    amount.value = "";
    policy.value = false;
    await getTransactionHistory();  } catch (error) {
    console.error("Deposit error:", error);
    
    // Use the formatted error message helper
    const userFriendlyMessage = formatErrorMessage(error);
      
    toast.add({
      title: "💳 Payment Gateway Error",
      description: userFriendlyMessage,
      icon: "i-heroicons-exclamation-triangle-20-solid",
      color: "red",
      timeout: 8000,
      actions: [{
        label: 'Try Again',
        click: () => deposit()
      }]
    });
    
    // If the error is related to missing user info, suggest profile completion
    if (
      userFriendlyMessage.includes("Missing mandatory parameters") || 
      !user.value.user.address || 
      !user.value.user.phone
    ) {
      setTimeout(() => {        toast.add({
          title: "📝 Profile Incomplete",
          description: "Please complete your profile with address, phone, and other required details.",
          icon: "i-heroicons-user-circle-20-solid",
          color: "orange",
          timeout: 8000,
          actions: [{
            label: 'Complete Profile',
            click: () => navigateTo('/my-account')
          }]
        });
      }, 1000);
    }
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

  // Validate withdrawal amount format
  if (withdrawAmount.value && (isNaN(withdrawAmount.value) || withdrawAmount.value <= 0)) {
    toast.add({
      title: "❌ Invalid Amount",
      description: "Please enter a valid withdrawal amount (numbers only)",
      icon: "i-heroicons-exclamation-triangle-20-solid",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  if (Object.keys(errors.value).length > 0) {
    return;
  }

  if (Number(withdrawAmount.value) < Number(min_withdrawal.value)) {
    errors.value.min_withdrawal = true;
    return;
  }

  try {
    isWithdrawLoading.value = true;

    const totalAmount = withdrawAmount.value * 1 + (withdrawAmount.value * 2.95) / 100;    const res = await post(`/add-user-balance/`, {
      payment_method: selected.value,
      card_number: payment_number.value,
      payable_amount: totalAmount,
      transaction_type: "Withdraw",
    });

    // Check for errors in the response
    if (res.error) {
      throw new Error(res.error);
    }

    // Check if response indicates success
    if (res.data || res.status === 201) {      toast.add({
        title: "✅ Withdrawal Submitted",
        description: "Your withdrawal request has been submitted successfully and is being processed.",
        icon: "i-heroicons-check-circle-20-solid",
        color: "green",
        timeout: 6000,
        actions: [{
          label: 'View History',
          click: () => {
            currentTab.value = 1;
            getTransactionHistory();
          }
        }]
      });

      // Reset form and update data
      withdrawAmount.value = "";
      payment_number.value = "";
      policy.value = false;
      await getTransactionHistory();
      await jwtLogin();    } else {
      throw new Error("Unexpected response format");
    }} catch (error) {
    console.log(error);
    
    // Use the formatted error message helper
    const userFriendlyMessage = formatErrorMessage(error);
      
    toast.add({
      title: "❌ Withdrawal Failed",
      description: userFriendlyMessage,
      icon: "i-heroicons-x-circle-20-solid",
      color: "red",
      timeout: 8000,
      actions: [{
        label: 'Try Again',
        click: () => withdraw()
      }, {
        label: 'Contact Support',
        click: () => navigateTo('/support')
      }]
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
  
  // Validate transfer amount format
  if (transfer.value.payable_amount && (isNaN(transfer.value.payable_amount) || transfer.value.payable_amount <= 0)) {
    transferErrors.value.payable_amount = "Please enter a valid amount (numbers only)";
    return;
  }
  
  if (Number(transfer.value.payable_amount) > 25000) {
    transferErrors.value.limit = "Maximum single transfer limit is 25,000/=";
  }

  // Check minimum transfer amount
  if (Number(transfer.value.payable_amount) < Number(min_transfer.value)) {
    transferErrors.value.min_transfer = "Minimum transfer amount is ৳50";
  }

  const transferAmount = Number(transfer.value.payable_amount);
  const userBalance = Number(user.value?.user.balance);

  if (transferAmount > userBalance) {
    transferErrors.value.transfer = "* Insufficient Balance";
  }

  // Check if user is trying to transfer to themselves
  const currentUserEmail = user.value?.user?.email;
  const currentUserPhone = user.value?.user?.phone;
  const transferContact = transfer.value.contact;

  if (transferContact && (transferContact === currentUserEmail || transferContact === currentUserPhone)) {
    transferErrors.value.contact = "You cannot transfer money to yourself";
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
    isOpenTransfer.value = true;    isLoading.value = false;  } catch (error) {
    // Use the formatted error message helper
    const userFriendlyMessage = formatErrorMessage(error);
    
    toast.add({
      title: "👤 User Search Failed",
      description: userFriendlyMessage,
      icon: "i-heroicons-user-minus-20-solid",
      color: "red",
      timeout: 6000,
      actions: [{
        label: 'Try Again',
        click: () => {
          transfer.value.contact = '';
          transferErrors.value = {};
        }
      }]
    });
    console.error("User search error:", error);
  } finally {
    isLoading.value = false;
  }
}

async function handleTransfer() {
  try {
    isLoading.value = true;
    passwordError.value = ""; // Clear any previous password errors

    // Validate password first
    if (!transfer.value.password) {
      passwordError.value = "Password is required to confirm the transfer";
      isLoading.value = false;
      return;
    }

    // Basic password length check (client-side validation)
    if (transfer.value.password.length < 6) {
      passwordError.value = "Password must be at least 6 characters long";
      isLoading.value = false;
      return;
    }

    // Verify password with backend using change-password endpoint
    // We'll attempt to change password to the same password to verify the current one
    try {
      const { data: passwordVerification, error: passwordVerifyError } = await post(`/change-password/`, {
        old_password: transfer.value.password,
        new_password: transfer.value.password
      });

      if (passwordVerifyError) {
        // Check if it's specifically about incorrect current password
        if (passwordVerifyError.data?.error?.includes('incorrect') || 
            passwordVerifyError.data?.error?.includes('Current password')) {
          passwordError.value = "Incorrect password. Please retry with the correct password.";
        } else {
          passwordError.value = "Password verification failed. Please try again.";
        }
        isLoading.value = false;
        return;
      }
    } catch (passwordVerifyError) {
      passwordError.value = "Incorrect password. Please retry with the correct password.";
      isLoading.value = false;
      return;
    }

    const { to_user, password, ...rest } = transfer.value;

    const { data, error } = await post(`/add-user-balance/`, rest);    if (error) {
      throw new Error(error);
    }

    // Show success toast for transfer
    toast.add({
      title: "💸 Transfer Successful!",
      description: `Successfully transferred ৳${transfer.value.payable_amount} to ${transfer.value.to_user}`,
      icon: "i-heroicons-check-circle-20-solid",
      color: "green",
      timeout: 6000,
      actions: [{
        label: 'View History',
        click: () => {
          reset();
          getTransactionHistory();
        }
      }]
    });    showSuccess.value = true;
    await getTransactionHistory();
    await jwtLogin();} catch (error) {
    // Use the formatted error message helper
    const userFriendlyMessage = formatErrorMessage(error);
    
    toast.add({
      title: "💸 Transfer Failed",
      description: userFriendlyMessage,
      icon: "i-heroicons-exclamation-triangle-20-solid",
      color: "red",
      timeout: 8000,
      actions: [{
        label: 'Retry Transfer',
        click: () => handleTransfer()
      }, {
        label: 'Contact Support',
        click: () => navigateTo('/support')
      }]
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
  passwordError.value = "";
  transfer.value = {
    contact: "",
    payable_amount: "",
    transaction_type: "Transfer",
    payment_method: "p2p",
    bank_status: "completed",
    to_user: null,
    password: "",
  };
}

// Initialize the component
onMounted(() => {
  getTransactionHistory();
});

// Reset pagination when changing transaction tabs
watch(transactionTab, () => {
  currentPage.value = 1;
});

// Transaction type filter options
const transactionTypeOptions = [
  { value: "", label: "All Types" },
  { value: "deposit", label: "Deposits" },
  { value: "withdraw", label: "Withdrawals" },
  { value: "transfer", label: "Transfers" },
  { value: "diamond", label: "Diamond Transactions" },
  { value: "mobile_recharge", label: "Mobile Recharges" },
  { value: "subscription", label: "Subscriptions" },
  { value: "purchase", label: "Purchases" },
  { value: "commission", label: "Commissions" },
  { value: "other", label: "Other" }
];

// Transaction status filter options
const transactionStatusOptions = [
  { value: "", label: "All Statuses" },
  { value: "completed", label: "Completed" },
  { value: "pending", label: "Pending" },
  { value: "rejected", label: "Rejected" }
];

// Function to get transaction group based on transaction type
function getTransactionGroup(transactionType) {
  // Standard transaction types
  if (["deposit"].includes(transactionType)) return "deposit";
  if (["withdraw"].includes(transactionType)) return "withdraw";
  if (["transfer"].includes(transactionType)) return "transfer";
  
  // Diamond-related transactions
  if (transactionType?.startsWith("diamond_")) return "diamond";
  
  // Other specific types
  if (["mobile_recharge"].includes(transactionType)) return "mobile_recharge";
  if (["pro_subscription"].includes(transactionType)) return "subscription";
  if (["order_payment"].includes(transactionType)) return "purchase";
  if (["referral_commission"].includes(transactionType)) return "commission";
  
  // Default case
  return "other";
}

// Function to get a user-friendly transaction type name
function getTransactionTypeName(transactionType) {
  const typeMap = {
    "deposit": "Deposit",
    "withdraw": "Withdrawal",
    "transfer": "Transfer",
    "diamond_purchase": "Diamond Purchase",
    "diamond_gift": "Diamond Gift Sent",
    "diamond_bonus": "Diamond Bonus",
    "diamond_refund": "Diamond Refund",
    "diamond_admin": "Diamond Adjustment",
    "mobile_recharge": "Mobile Recharge",
    "pro_subscription": "Pro Subscription",
    "order_payment": "Product Purchase",
    "referral_commission": "Referral Commission"
  };
  
  return typeMap[transactionType] || transactionType?.replace("_", " ")?.replace(/\b\w/g, l => l.toUpperCase()) || "Other";
}
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
  background: linear-gradient(to right, rgba(255, 255, 255, 0.9), rgba(249, 250, 251, 0.9));
  border-radius: 0.75rem;
  z-index: -1;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03),
    inset 0 2px 4px rgba(255, 255, 255, 0.7);
  transform: translateY(0);
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.modern-input-container:focus-within .input-backdrop {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px -5px rgba(59, 130, 246, 0.15), 0 5px 10px -5px rgba(59, 130, 246, 0.1),
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
  box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.15), 0 2px 8px rgba(99, 102, 241, 0.25) !important;
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
  background: radial-gradient(circle, var(--color-primary-100) 0%, transparent 70%);
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

/* Professional Toast Enhancements */
:deep(.u-toast) {
  border-radius: 0.75rem !important;
  backdrop-filter: blur(12px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 
              0 10px 10px -5px rgba(0, 0, 0, 0.04),
              0 0 0 1px rgba(255, 255, 255, 0.05) !important;
  border: 1px solid rgba(255, 255, 255, 0.1);
  overflow: hidden;
  position: relative;
}

:deep(.u-toast::before) {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: linear-gradient(90deg, 
    var(--toast-accent-color, #10b981) 0%, 
    color-mix(in srgb, var(--toast-accent-color, #10b981) 80%, white) 100%);
  z-index: 1;
}

/* Success Toast Styling */
:deep(.u-toast[data-color="green"]) {
  --toast-accent-color: #10b981;
  background: linear-gradient(135deg, 
    rgba(16, 185, 129, 0.05) 0%, 
    rgba(5, 150, 105, 0.02) 100%);
  border-color: rgba(16, 185, 129, 0.2);
}

/* Error Toast Styling */
:deep(.u-toast[data-color="red"]) {
  --toast-accent-color: #ef4444;
  background: linear-gradient(135deg, 
    rgba(239, 68, 68, 0.05) 0%, 
    rgba(220, 38, 38, 0.02) 100%);
  border-color: rgba(239, 68, 68, 0.2);
}

/* Warning Toast Styling */
:deep(.u-toast[data-color="amber"]) {
  --toast-accent-color: #f59e0b;
  background: linear-gradient(135deg, 
    rgba(245, 158, 11, 0.05) 0%, 
    rgba(217, 119, 6, 0.02) 100%);
  border-color: rgba(245, 158, 11, 0.2);
}

/* Orange Toast Styling */
:deep(.u-toast[data-color="orange"]) {
  --toast-accent-color: #f97316;
  background: linear-gradient(135deg, 
    rgba(249, 115, 22, 0.05) 0%, 
    rgba(234, 88, 12, 0.02) 100%);
  border-color: rgba(249, 115, 22, 0.2);
}

/* Toast Title Enhancement */
:deep(.u-toast .font-medium) {
  font-weight: 600 !important;
  font-size: 0.95rem !important;
  letter-spacing: -0.01em;
  margin-bottom: 0.25rem;
}

/* Toast Description Enhancement */
:deep(.u-toast .text-sm) {
  font-size: 0.875rem !important;
  line-height: 1.4;
  opacity: 0.9;
}

/* Toast Icon Enhancement */
:deep(.u-toast .shrink-0) {
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
}

/* Toast Actions Enhancement */
:deep(.u-toast .gap-1\.5 button) {
  font-size: 0.8rem !important;
  font-weight: 500 !important;
  padding: 0.375rem 0.75rem !important;
  border-radius: 0.5rem !important;
  background: rgba(255, 255, 255, 0.9) !important;
  color: var(--toast-accent-color, #374151) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  transition: all 0.2s ease !important;
  backdrop-filter: blur(8px);
}

:deep(.u-toast .gap-1\.5 button:hover) {
  background: var(--toast-accent-color, #374151) !important;
  color: white !important;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

/* Toast Animation Enhancement */
:deep(.u-toast) {
  animation: toast-slide-in 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes toast-slide-in {
  from {
    opacity: 0;
    transform: translateX(100%) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateX(0) scale(1);
  }
}

/* Mobile Toast Positioning - Use global layout-specific rules */
@media (max-width: 640px) {
  :deep(.u-toast) {
    margin-bottom: 0.75rem !important;
    max-width: calc(100vw - 2rem) !important;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  :deep(.u-toast) {
    background: linear-gradient(135deg, 
      rgba(17, 24, 39, 0.95) 0%, 
      rgba(31, 41, 55, 0.95) 100%) !important;
    border-color: rgba(75, 85, 99, 0.3) !important;
    color: #e5e7eb !important;
  }
}
</style>
