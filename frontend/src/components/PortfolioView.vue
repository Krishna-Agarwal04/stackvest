<script setup>
import { ref, onMounted, computed } from 'vue'
import { useFinanceStore } from '../store/finance'

const store = useFinanceStore()
const successMessage = ref('')
const payoutLoading = ref(false)

onMounted(async () => {
  await store.fetchStacks(false)
})

const formatCurrency = (val) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
  }).format(val)
}

// Portfolio statistics
const totalPortfolioValuation = computed(() => {
  return store.ownedStacks.reduce((sum, s) => sum + s.valuation, 0)
})

const averagePortfolioYield = computed(() => {
  const count = store.ownedStacks.length
  if (count === 0) return 0
  const sum = store.ownedStacks.reduce((acc, s) => acc + s.monthly_roi, 0)
  return (sum / count).toFixed(1)
})

const cumulativePortfolioEarnings = computed(() => {
  return store.ownedStacks.reduce((sum, s) => sum + s.earnings, 0)
})

const claimYields = async () => {
  payoutLoading.value = true
  successMessage.value = ''
  try {
    const data = await store.payoutYields()
    successMessage.value = data.message
    setTimeout(() => { successMessage.value = '' }, 5000)
  } catch (err) {
    alert(err.message)
  } finally {
    payoutLoading.value = false
  }
}

const liquidateStack = async (id, name, valuation) => {
  const confirmation = confirm(`Are you sure you want to liquidate '${name}'? You will receive a cash credit of ${formatCurrency(valuation)} and the asset will be listed back in the active auction arena.`)
  if (!confirmation) return
  
  try {
    const data = await store.sellStack(id)
    alert(data.message)
  } catch (err) {
    alert(err.message)
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header with statistics -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h2 class="text-xl font-bold text-slate-100 flex items-center">
          <svg class="w-6 h-6 mr-2 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
          </svg>
          My Portfolio Stacks
        </h2>
        <p class="text-xs text-slate-400 mt-1">Manage owned tech stack assets, monitor weekly compounding yield dividends, and liquidate holdings.</p>
      </div>

      <!-- Action: claim yields -->
      <button 
        @click="claimYields"
        :disabled="payoutLoading || store.ownedStacks.length === 0"
        class="bg-gradient-to-r from-emerald-400 to-teal-500 text-slate-950 font-extrabold px-5 py-2.5 rounded-xl text-xs flex items-center transition transform active:scale-95 disabled:opacity-50 shadow-lg glow-emerald cursor-pointer"
      >
        <svg class="w-4 h-4 mr-1.5 animate-spin" v-if="payoutLoading" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.283 16h-1"></path>
        </svg>
        <svg class="w-4 h-4 mr-1.5" v-else fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        Claim Portfolio Yields
      </button>
    </div>

    <!-- Notifications banner -->
    <div v-if="successMessage" class="glass-panel border-emerald-500/30 text-emerald-400 p-4 rounded-xl flex items-center shadow shadow-emerald-500/10 animate-bounce">
      <svg class="w-5 h-5 mr-2 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
      <span class="text-xs font-semibold">{{ successMessage }}</span>
    </div>

    <!-- Portfolio Metrics Grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="glass-panel p-4 rounded-xl flex justify-between items-center">
        <div>
          <span class="text-[10px] text-slate-400 font-semibold uppercase block">Total Portfolio Asset Value</span>
          <span class="text-xl font-bold text-slate-100 mt-1 block">{{ formatCurrency(totalPortfolioValuation) }}</span>
        </div>
        <div class="w-10 h-10 rounded-lg bg-indigo-500/10 flex items-center justify-center text-indigo-400">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 002 2h2a2 2 0 002-2z"></path>
          </svg>
        </div>
      </div>
      
      <div class="glass-panel p-4 rounded-xl flex justify-between items-center">
        <div>
          <span class="text-[10px] text-slate-400 font-semibold uppercase block">Average Monthly Yield Rate</span>
          <span class="text-xl font-bold text-emerald-400 mt-1 block">{{ averagePortfolioYield }}% / month</span>
        </div>
        <div class="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center text-emerald-400">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
          </svg>
        </div>
      </div>

      <div class="glass-panel p-4 rounded-xl flex justify-between items-center">
        <div>
          <span class="text-[10px] text-slate-400 font-semibold uppercase block">Total Generated Dividends</span>
          <span class="text-xl font-bold text-yellow-400 mt-1 block">{{ formatCurrency(cumulativePortfolioEarnings) }}</span>
        </div>
        <div class="w-10 h-10 rounded-lg bg-yellow-500/10 flex items-center justify-center text-yellow-400">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
        </div>
      </div>
    </div>

    <!-- List of Owned Tech Stacks -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div v-for="stack in store.ownedStacks" :key="stack.id" class="glass-panel p-5 rounded-2xl flex flex-col justify-between space-y-4">
        <!-- Asset Cover -->
        <div class="flex items-start justify-between">
          <div class="flex items-center space-x-3.5">
            <div class="w-14 h-14 bg-slate-800 rounded-xl overflow-hidden flex-shrink-0 relative">
              <img :src="stack.image_url" class="w-full h-full object-cover" alt="Portfolio Image" />
              <div class="absolute inset-0 bg-gradient-to-t from-slate-950/80 to-transparent"></div>
            </div>
            <div>
              <h3 class="text-sm font-bold text-slate-100">{{ stack.name }}</h3>
              <div class="flex flex-wrap gap-1 mt-1">
                <span v-for="tech in stack.technologies_list" :key="tech" class="px-2 py-0.5 rounded-full bg-slate-900 border border-slate-800 text-[8px] font-semibold text-slate-400">
                  {{ tech }}
                </span>
              </div>
            </div>
          </div>
          
          <span class="px-2 py-0.5 rounded bg-slate-900 border border-slate-800 text-[9px] font-bold uppercase tracking-wider" :class="{
            'text-emerald-400 border-emerald-500/20': stack.risk_level === 'Low',
            'text-indigo-400 border-indigo-500/20': stack.risk_level === 'Medium',
            'text-amber-400 border-amber-500/20': stack.risk_level === 'High',
          }">
            {{ stack.risk_level }}
          </span>
        </div>

        <p class="text-xs text-slate-400 leading-relaxed">{{ stack.description }}</p>

        <!-- Ledger Financial Data -->
        <div class="grid grid-cols-3 gap-2 p-3 bg-slate-900/60 border border-slate-800/40 rounded-xl text-center text-xs">
          <div>
            <span class="text-slate-500 text-[10px] font-semibold uppercase block">Equity Value</span>
            <span class="text-slate-200 font-bold font-mono mt-0.5 block">{{ formatCurrency(stack.valuation) }}</span>
          </div>
          <div>
            <span class="text-slate-500 text-[10px] font-semibold uppercase block">ROI Rate</span>
            <span class="text-emerald-400 font-bold mt-0.5 block">+{{ stack.monthly_roi }}% / mo</span>
          </div>
          <div>
            <span class="text-slate-500 text-[10px] font-semibold uppercase block">Earnings</span>
            <span class="text-yellow-400 font-bold font-mono mt-0.5 block">{{ formatCurrency(stack.earnings) }}</span>
          </div>
        </div>

        <!-- Liquidation action -->
        <div class="pt-2 border-t border-slate-800/40 flex justify-end">
          <button 
            @click="liquidateStack(stack.id, stack.name, stack.valuation)"
            class="bg-rose-500/10 border border-rose-500/25 hover:bg-rose-500/20 text-rose-400 font-bold px-3 py-1.5 rounded-xl text-[10px] transition cursor-pointer active:scale-95"
          >
            Liquidate Holdings
          </button>
        </div>
      </div>

      <div v-if="store.ownedStacks.length === 0" class="col-span-2 glass-panel p-12 rounded-2xl text-center text-slate-500 text-xs">
        <svg class="w-12 h-12 text-slate-700 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path>
        </svg>
        <span class="text-xs font-semibold">Your Portfolio is Empty</span>
        <p class="text-[10px] text-slate-400 mt-1">You don't own any technology stacks yet. Head over to the Stacks Auction Arena to place a bid or buy outright!</p>
      </div>
    </div>
  </div>
</template>
