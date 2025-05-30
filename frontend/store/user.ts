import { defineStore } from "pinia";

export interface User {
  id: string;
  username: string;
  name?: string;
  email: string;
  phone?: string;
  image?: string;
  balance: number;
  pending_balance: number;
  is_pro: boolean;
  pro_validity?: string;
  kyc: boolean;
  kyc_pending: boolean;
  product_limit: number; // Added product limit property
}

export const useUserStore = defineStore("user", {
  state: () => ({
    user: null as User | null,
    isAuthenticated: false,
    token: null as string | null,
    loading: false,
    error: null as string | null,
  }),

  getters: {
    getUser: (state) => state.user,
    getBalance: (state) => state.user?.balance || 0,
    getPendingBalance: (state) => state.user?.pending_balance || 0,
    isLoggedIn: (state) => state.isAuthenticated && !!state.token,
    isKycVerified: (state) => state.user?.kyc || false,
    hasKycPending: (state) => state.user?.kyc_pending || false,
  },

  actions: {
    // Set user data
    setUser(user: User) {
      this.user = user;
      this.isAuthenticated = true;
    },    // Set authentication token
    setToken(token: string) {
      this.token = token;
      // Store in local storage - check if we're in browser environment
      if (typeof window !== 'undefined') {
        localStorage.setItem('token', token);
      }
    },

    // Log out user
    logout() {
      this.user = null;
      this.isAuthenticated = false;
      this.token = null;
      if (typeof window !== 'undefined') {
        localStorage.removeItem('token');
      }
    },

    // Fetch user data from API
    async fetchUserData() {
      if (!this.token && typeof window !== 'undefined') {
        // Try to get token from local storage
        const savedToken = localStorage.getItem('token');
        if (savedToken) {
          this.token = savedToken;
        } else {
          return;
        }
      }

      if (!this.token) return;

      this.loading = true;
      this.error = null;
      
      try {
        const userData = await $fetch<User>('/api/user/me', {
          headers: {
            Authorization: `Bearer ${this.token}`
          }
        });
        
        this.setUser(userData);
      } catch (error: any) {
        console.error('Error fetching user data:', error);
        this.error = 'Failed to load user data';
        if (error.response?.status === 401) {
          this.logout();
        }
      } finally {
        this.loading = false;
      }
    },

    // Update user balance (for immediate updates after transactions)
    updateBalance(newBalance: number) {
      if (this.user) {
        this.user.balance = newBalance;
      }
    },
    
    // Initialize user state from stored token
    async initializeFromStorage() {
      if (typeof window !== 'undefined') {
        const savedToken = localStorage.getItem('token');
        if (savedToken) {
          this.token = savedToken;
          this.isAuthenticated = true;
          await this.fetchUserData();
        }
      }
    }
  },
});