/**
 * Gig Order Fee Calculator Composable
 * 
 * Simple fee structure:
 * - Buyer Fee: Added to order total when placing order
 * - Seller Fee: Deducted from seller earnings when order completes
 * 
 * Example with 2.5% each on ৳1000 order:
 * - Buyer pays: ৳1000 + ৳25 (2.5% fee) = ৳1025
 * - Seller receives: ৳1000 - ৳25 (2.5% fee) = ৳975
 * - Platform earns: ৳25 + ৳25 = ৳50 total
 */

interface FeeConfig {
  // Simple percentage fees
  buyerFeePercent: number;             // Buyer fee percentage
  sellerFeePercent: number;            // Seller fee percentage
  feesEnabled: boolean;                // Master toggle for fees
  
  // Legacy fields (for backward compatibility)
  buyerServiceFeePercent: number;
  buyerServiceFeeMin: number;
  buyerServiceFeeMax: number;
  buyerProcessingFee: number;
  sellerCommissionPercent: number;
  sellerCommissionMin: number;
  sellerCommissionMax: number;
  sellerWithdrawalFee: number;
  buyerFeeWaived: boolean;
  sellerFeeDiscountPercent: number;
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
    // Simple percentage fees (new)
    buyerFeePercent: 2.5,              // 2.5% buyer fee
    sellerFeePercent: 2.5,             // 2.5% seller fee
    feesEnabled: true,                 // Fees are enabled by default
    
    // Legacy fields (for backward compatibility)
    buyerServiceFeePercent: 2.5,
    buyerServiceFeeMin: 0,
    buyerServiceFeeMax: 500,
    buyerProcessingFee: 0,
    sellerCommissionPercent: 2.5,
    sellerCommissionMin: 0,
    sellerCommissionMax: 5000,
    sellerWithdrawalFee: 0,
    buyerFeeWaived: false,
    sellerFeeDiscountPercent: 0,
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
          // New simplified fields
          buyerFeePercent: data.buyer_fee_percent ?? 2.5,
          sellerFeePercent: data.seller_fee_percent ?? 2.5,
          feesEnabled: data.fees_enabled ?? true,
          
          // Legacy fields
          buyerServiceFeePercent: data.buyer_service_fee_percent || 0,
          buyerServiceFeeMin: data.buyer_service_fee_min || 0,
          buyerServiceFeeMax: data.buyer_service_fee_max || 500,
          buyerProcessingFee: data.buyer_processing_fee || 0,
          buyerFeeWaived: data.buyer_fee_waived ?? false,
          sellerCommissionPercent: data.seller_commission_percent || 10,
          sellerCommissionMin: data.seller_commission_min || 0,
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
   * Simple: order_amount * buyer_fee_percent / 100
   * @param orderAmount - The gig price
   * @returns BuyerFeeBreakdown
   */
  const calculateBuyerFees = (orderAmount: number): BuyerFeeBreakdown => {
    const config = feeConfig.value;
    
    // Check if fees are disabled
    if (!config.feesEnabled) {
      return {
        orderAmount,
        serviceFee: 0,
        processingFee: 0,
        totalFee: 0,
        totalToPay: orderAmount,
        isFeeWaived: true,
      };
    }

    // Simple percentage calculation
    const serviceFee = Math.round((orderAmount * config.buyerFeePercent) * 100) / 10000;
    const totalToPay = orderAmount + serviceFee;

    return {
      orderAmount,
      serviceFee,
      processingFee: 0,
      totalFee: serviceFee,
      totalToPay,
      isFeeWaived: false,
    };
  };

  /**
   * Calculate seller fees/earnings on order completion
   * Simple: order_amount - (order_amount * seller_fee_percent / 100)
   * @param orderAmount - The gig price
   * @returns SellerFeeBreakdown
   */
  const calculateSellerFees = (orderAmount: number): SellerFeeBreakdown => {
    const config = feeConfig.value;
    
    // Check if fees are disabled
    if (!config.feesEnabled) {
      return {
        orderAmount,
        platformCommission: 0,
        commissionPercent: 0,
        netEarnings: orderAmount,
        discountApplied: 0,
      };
    }

    // Simple percentage calculation
    const commission = Math.round((orderAmount * config.sellerFeePercent) * 100) / 10000;
    const netEarnings = orderAmount - commission;

    return {
      orderAmount,
      platformCommission: commission,
      commissionPercent: config.sellerFeePercent,
      netEarnings,
      discountApplied: 0,
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
   * Check if fees are currently enabled
   */
  const feesEnabled = computed(() => feeConfig.value.feesEnabled);

  /**
   * Get current buyer fee percentage
   */
  const buyerFeeRate = computed(() => feeConfig.value.buyerFeePercent);

  /**
   * Get current seller fee percentage
   */
  const sellerFeeRate = computed(() => feeConfig.value.sellerFeePercent);

  /**
   * Get total platform fee percentage (buyer + seller)
   */
  const totalPlatformFeeRate = computed(() => 
    feeConfig.value.buyerFeePercent + feeConfig.value.sellerFeePercent
  );

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
    feesEnabled,
    buyerFeeRate,
    sellerFeeRate,
    totalPlatformFeeRate,
  };
}
