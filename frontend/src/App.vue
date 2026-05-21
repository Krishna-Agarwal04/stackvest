<script setup>
import { ref, onMounted } from 'vue'
import { useFinanceStore } from './store/finance'
import Navbar from './components/Navbar.vue'
import DashboardView from './components/DashboardView.vue'
import AuctionView from './components/AuctionView.vue'
import PortfolioView from './components/PortfolioView.vue'
import TransactionsView from './components/TransactionsView.vue'

const store = useFinanceStore()
const activeTab = ref('dashboard')

onMounted(async () => {
  // Initialize wallet and load basic stocks
  await store.fetchWallet()
  await store.fetchDashboard()
})

const handleSwitchTab = (tab) => {
  activeTab.value = tab
  // Re-fetch transactions or dashboard on switch to ensure live updates
  if (tab === 'dashboard') {
    store.fetchDashboard()
  } else if (tab === 'transactions') {
    store.fetchTransactions()
  } else if (tab === 'portfolio' || tab === 'auctions') {
    store.fetchStacks(false)
  }
}
</script>

<template>
  <div class="min-h-screen relative p-4 md:p-6 overflow-hidden">
    <!-- Backdrop Glows -->
    <div class="absolute -top-32 -left-32 w-96 h-96 bg-indigo-900/10 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute -bottom-32 -right-32 w-[400px] h-[400px] bg-yellow-900/5 rounded-full blur-3xl pointer-events-none"></div>

    <div class="max-w-6xl mx-auto space-y-6 relative z-10">
      <!-- Navbar Component -->
      <Navbar :activeTab="activeTab" @switch-tab="handleSwitchTab" />

      <!-- Loading Splash -->
      <div v-if="store.loading && !store.wallet.balance" class="h-96 flex flex-col items-center justify-center space-y-4">
        <div class="w-12 h-12 border-4 border-indigo-500/20 border-t-yellow-500 rounded-full animate-spin"></div>
        <span class="text-xs text-slate-400 font-bold tracking-wider">SECURE CONNECTION TO LEDGER...</span>
      </div>

      <!-- Views Router -->
      <main v-else class="transition-all duration-300">
        <DashboardView 
          v-if="activeTab === 'dashboard'" 
          @switch-tab="handleSwitchTab" 
        />
        
        <AuctionView 
          v-else-if="activeTab === 'auctions'" 
        />
        
        <PortfolioView 
          v-else-if="activeTab === 'portfolio'" 
        />
        
        <TransactionsView 
          v-else-if="activeTab === 'transactions'" 
        />
      </main>
    </div>
  </div>
</template>
