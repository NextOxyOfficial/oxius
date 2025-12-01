/**
 * Gig Order Fee Calculator Composable
 * 
 * Calculates fees for both buyers (order fee) and sellers (completion fee)
 * Fetches fee configuration from Django Admin via API
 */

interface FeeConfig {
  // Buyer fees (charged when placing order)
  buyerServiceFeePercent: number;      // Percentage fee on order amount
  buyerServiceFeeMin: number;          // Minimum service fee
  buyerServiceFeeMax: number;          // Maximum service fee cap
  buyerProcessingFee: number;          // Fixed processing fee
  
  // Seller fees (deducted from earnings on completion)
  sellerCommissionPercent: number;     // Platform commission percentage
  sellerCommissionMin: number;         // Minimum commission
  sellerCommissionMax: number;         // Maximum commission cap
  sellerWithdrawalFee: number;         // Fee for withdrawing earnings
  
  // Promotional settings
  buyerFeeWaived: boolean;             // Waive buyer service fee (promotional)
  sellerFeeDiscountPercent: number;    // Discount on seller commission (promotional)
}

interface BuyerFeeBreakdown {
  orderAmount: number;
  serviceFee: number;
  processingFee: number;
  totalFee: number;
  totalToPay: number;
  isFeeWaived: boolean;
}

interface SellerFeeBreakdown {
  orderAmount: number;
  platformCommission: number;
  commissionPercent: number;
  netEarnings: number;
  discountApplied: number;
}

interface OrderSummary {
  buyer: BuyerFeeBreakdown;
  seller: SellerFeeBreakdown;
}

// Cache for fee settings to avoid repeated API calls
let cachedConfig: FeeConfig | null = null;
let cacheTimestamp: number = 0;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes cache

export function useGigFees() {
  const { get } = useApi();
  
  // Default fee configuration (fallback if API fails)
  const defaultConfig: FeeConfig = {
    // Buyer fees
    buyerServiceFeePercent: 0,         // 0% service fee (currently free)
    buyerServiceFeeMin: 0,
    buyerServiceFeeMax: 500,           // Max ৳500 service fee
    buyerProcessingFee: 0,             // No processing fee
    
    // Seller fees
    sellerCommissionPercent: 10,       // 10% platform commission
    sellerCommissionMin: 5,            // Minimum ৳5 commission
    sellerCommissionMax: 5000,         // Max ৳5000 commission
    sellerWithdrawalFee: 0,            // No withdrawal fee
    
    // Promotional settings
    buyerFeeWaived: true,              // Currently waiving buyer fees
    sellerFeeDiscountPercent: 0,       // No discount on seller commission
  };

  const feeConfig = ref<FeeConfig>(defaultConfig);
  const isLoading = ref(false);
  const isLoaded = ref(false);

  /**
   * Fetch fee settings from API
   */
  const fetchFeeSettings = async (): Promise<void> => {
    // Check cache first
    const now = Date.now();
    if (cachedConfig && (now - cacheTimestamp) < CACHE_DURATION) {
      feeConfig.value = cachedConfig;
      isLoaded.value = true;
      return;
    }

    isLoading.value = true;
    try {
      const { data, error } = await get('/workspace/fee-settings/');
      
      if (data && !error) {
        const config: FeeConfig = {
          buyerServiceFeePercent: data.buyer_service_fee_percent || 0,
          buyerServiceFeeMin: data.buyer_service_fee_min || 0,
          buyerServiceFeeMax: data.buyer_service_fee_max || 500,
          buyerProcessingFee: data.buyer_processing_fee || 0,
          buyerFeeWaived: data.buyer_fee_waived ?? true,
          sellerCommissionPercent: data.seller_commission_percent || 10,
          sellerCommissionMin: data.seller_commission_min || 5,
          sellerCommissionMax: data.seller_commission_max || 5000,
          sellerWithdrawalFee: data.seller_withdrawal_fee || 0,
          sellerFeeDiscountPercent: data.seller_fee_discount_percent || 0,
        };
        
        feeConfig.value = config;
        cachedConfig = config;
        cacheTimestamp = now;
      }
    } catch (err) {
      // Use default config on error
      console.warn('Failed to fetch fee settings, using defaults');
    } finally {
      isLoading.value = false;
      isLoaded.value = true;
    }
  };

  // Auto-fetch on first use
  if (!isLoaded.value && !isLoading.value) {
    fetchFeeSettings();
  }

  /**
   * Calculate buyer fees for placing an order
   * @param orderAmount - The gig price
   * @returns BuyerFeeBreakdown
   */
  const calculateBuyerFees = (orderAmount: number): BuyerFeeBreakdown => {
    const config = feeConfig.value;
    
    // Check if fees are waived (promotional period)
    if (config.buyerFeeWaived) {
      return {
        orderAmount,
        serviceFee: 0,
        processingFee: 0,
        totalFee: 0,
        totalToPay: orderAmount,
        isFeeWaived: true,
      };
    }

    // Calculate service fee
    let serviceFee = (orderAmount * config.buyerServiceFeePercent) / 100;
    
    // Apply min/max caps
    serviceFee = Math.max(serviceFee, config.buyerServiceFeeMin);
    serviceFee = Math.min(serviceFee, config.buyerServiceFeeMax);
    
    // Round to 2 decimal places
    serviceFee = Math.round(serviceFee * 100) / 100;
    
    const processingFee = config.buyerProcessingFee;
    const totalFee = serviceFee + processingFee;
    const totalToPay = orderAmount + totalFee;

    return {
      orderAmount,
      serviceFee,
      processingFee,
      totalFee,
      totalToPay,
      isFeeWaived: false,
    };
  };

  /**
   * Calculate seller fees/earnings on order completion
   * @param orderAmount - The gig price
   * @returns SellerFeeBreakdown
   */
  const calculateSellerFees = (orderAmount: number): SellerFeeBreakdown => {
    const config = feeConfig.value;
    
    // Calculate platform commission
    let commission = (orderAmount * config.sellerCommissionPercent) / 100;
    
    // Apply min/max caps
    commission = Math.max(commission, config.sellerCommissionMin);
    commission = Math.min(commission, config.sellerCommissionMax);
    
    // Apply promotional discount if any
    let discountApplied = 0;
    if (config.sellerFeeDiscountPercent > 0) {
      discountApplied = (commission * config.sellerFeeDiscountPercent) / 100;
      commission = commission - discountApplied;
    }
    
    // Round to 2 decimal places
    commission = Math.round(commission * 100) / 100;
    discountApplied = Math.round(discountApplied * 100) / 100;
    
    const netEarnings = orderAmount - commission;

    return {
      orderAmount,
      platformCommission: commission,
      commissionPercent: config.sellerCommissionPercent,
      netEarnings,
      discountApplied,
    };
  };

  /**
   * Get complete order summary for both parties
   * @param orderAmount - The gig price
   * @returns OrderSummary
   */
  const getOrderSummary = (orderAmount: number): OrderSummary => {
    return {
      buyer: calculateBuyerFees(orderAmount),
      seller: calculateSellerFees(orderAmount),
    };
  };

  /**
   * Format currency for display
   * @param amount - Amount to format
   * @returns Formatted string
   */
  const formatCurrency = (amount: number): string => {
    return amount.toLocaleString('en-BD', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    });
  };

  /**
   * Get fee display text for buyer
   * @param orderAmount - The gig price
   * @returns Display text
   */
  const getBuyerFeeText = (orderAmount: number): string => {
    const fees = calculateBuyerFees(orderAmount);
    if (fees.isFeeWaived) {
      return 'Free';
    }
    return `৳${formatCurrency(fees.totalFee)}`;
  };

  /**
   * Get seller earnings text
   * @param orderAmount - The gig price
   * @returns Display text
   */
  const getSellerEarningsText = (orderAmount: number): string => {
    const fees = calculateSellerFees(orderAmount);
    return `৳${formatCurrency(fees.netEarnings)}`;
  };

  /**
   * Update fee configuration (e.g., from API)
   * @param newConfig - Partial config to update
   */
  const updateFeeConfig = (newConfig: Partial<FeeConfig>) => {
    feeConfig.value = { ...feeConfig.value, ...newConfig };
  };

  /**
   * Check if buyer fees are currently waived
   */
  const isBuyerFeeWaived = computed(() => feeConfig.value.buyerFeeWaived);

  /**
   * Get current seller commission percentage
   */
  const sellerCommissionRate = computed(() => feeConfig.value.sellerCommissionPercent);

  return {
    // Fee calculation functions
    calculateBuyerFees,
    calculateSellerFees,
    getOrderSummary,
    
    // Display helpers
    formatCurrency,
    getBuyerFeeText,
    getSellerEarningsText,
    
    // Configuration
    feeConfig,
    updateFeeConfig,
    fetchFeeSettings,
    
    // Loading state
    isLoading,
    isLoaded,
    
    // Computed properties
    isBuyerFeeWaived,
    sellerCommissionRate,
  };
}
