import { defineStore } from 'pinia'

export const useFinanceStore = defineStore('finance', {
  state: () => ({
    wallet: { balance: 0.0 },
    stacks: [],
    transactions: [],
    dashboard: {
      metrics: {
        cash: 0.0,
        portfolio_value: 0.0,
        net_worth: 0.0,
        total_yield_earnings: 0.0,
        active_bids_count: 0,
        owned_stacks_count: 0
      },
      chart_data: [],
      risk_distribution: [],
      recent_transactions: []
    },
    activeStackDetails: null,
    activeStackBids: [],
    loading: false,
    error: null
  }),

  getters: {
    ownedStacks: (state) => state.stacks.filter(s => s.status === 'owned'),
    auctionStacks: (state) => state.stacks.filter(s => s.status === 'active_auction'),
  },

  actions: {
    async fetchWallet() {
      this.loading = true
      try {
        const response = await fetch('/api/wallet')
        if (!response.ok) throw new Error("Failed to fetch wallet info")
        this.wallet = await response.json()
      } catch (err) {
        this.error = err.message
        console.error(err)
      } finally {
        this.loading = false
      }
    },

    async depositFunds(amount) {
      this.loading = true
      this.error = null
      try {
        const response = await fetch('/api/wallet/deposit', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ amount })
        })
        const data = await response.json()
        if (!response.ok) throw new Error(data.error || "Deposit failed")
        
        this.wallet = data.wallet
        await this.fetchDashboard()
        return data
      } catch (err) {
        this.error = err.message
        throw err
      } finally {
        this.loading = false
      }
    },

    async fetchDashboard() {
      try {
        const response = await fetch('/api/dashboard')
        if (!response.ok) throw new Error("Failed to fetch dashboard metrics")
        this.dashboard = await response.json()
        // Keep wallet cash updated in sync
        this.wallet.balance = this.dashboard.metrics.cash
      } catch (err) {
        console.error(err)
      }
    },

    async fetchStacks(simulate = false) {
      this.loading = true
      try {
        const url = simulate ? '/api/stacks?simulate=true' : '/api/stacks'
        const response = await fetch(url)
        if (!response.ok) throw new Error("Failed to fetch stack assets")
        this.stacks = await response.json()
      } catch (err) {
        this.error = err.message
        console.error(err)
      } finally {
        this.loading = false
      }
    },

    async fetchStackDetails(id) {
      try {
        const response = await fetch(`/api/stacks/${id}`)
        if (!response.ok) throw new Error("Failed to fetch stack details")
        const data = await response.json()
        this.activeStackDetails = data.stack
        this.activeStackBids = data.bids
        return data
      } catch (err) {
        console.error(err)
      }
    },

    async placeBid(id, amount) {
      this.error = null
      try {
        const response = await fetch(`/api/stacks/${id}/bid`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ amount })
        })
        const data = await response.json()
        if (!response.ok) throw new Error(data.error || "Bidding failed")
        
        // Refresh items and wallet
        await this.fetchStacks(false)
        await this.fetchDashboard()
        // If we are looking at details, update details
        if (this.activeStackDetails && this.activeStackDetails.id === id) {
          await this.fetchStackDetails(id)
        }
        return data
      } catch (err) {
        this.error = err.message
        throw err
      }
    },

    async buyStack(id) {
      this.error = null
      try {
        const response = await fetch(`/api/stacks/${id}/buy`, {
          method: 'POST'
        })
        const data = await response.json()
        if (!response.ok) throw new Error(data.error || "Purchase failed")
        
        await this.fetchStacks(false)
        await this.fetchDashboard()
        return data
      } catch (err) {
        this.error = err.message
        throw err
      }
    },

    async sellStack(id) {
      this.error = null
      try {
        const response = await fetch(`/api/stacks/${id}/sell`, {
          method: 'POST'
        })
        const data = await response.json()
        if (!response.ok) throw new Error(data.error || "Sale liquidation failed")
        
        await this.fetchStacks(false)
        await this.fetchDashboard()
        return data
      } catch (err) {
        this.error = err.message
        throw err
      }
    },

    async payoutYields() {
      try {
        const response = await fetch('/api/stacks/payout_yields', {
          method: 'POST'
        })
        const data = await response.json()
        if (!response.ok) throw new Error(data.error || "Dividend payout failed")
        
        await this.fetchStacks(false)
        await this.fetchDashboard()
        return data
      } catch (err) {
        console.error(err)
        throw err
      }
    },

    async fetchTransactions() {
      try {
        const response = await fetch('/api/transactions')
        if (!response.ok) throw new Error("Failed to fetch transaction ledgers")
        this.transactions = await response.json()
      } catch (err) {
        console.error(err)
      }
    }
  }
})
