<script setup>
import { computed } from 'vue'
import { useFinanceStore } from '../store/finance'

const props = defineProps({
  activeTab: {
    type: String,
    required: true
  }
})

defineEmits(['switch-tab'])

const store = useFinanceStore()

const formatCurrency = (val) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
  }).format(val)
}
</script>

<template>
  <nav class="glass-panel px-6 py-4 rounded-3xl flex flex-col md:flex-row items-center justify-between gap-4 shadow-xl border border-slate-800 glow-indigo">
    <!-- Brand Logo -->
    <div class="flex items-center space-x-2 select-none cursor-pointer" @click="$emit('switch-tab', 'dashboard')">
      <div class="w-8 h-8 rounded-xl bg-gradient-to-tr from-amber-400 to-yellow-500 flex items-center justify-center text-slate-950 font-black shadow glow-amber">
        $
      </div>
      <div>
        <h1 class="text-base font-black tracking-wider text-slate-100 uppercase">Stack<span class="bg-gradient-to-r from-amber-300 to-yellow-500 bg-clip-text text-transparent">Vest</span></h1>
        <span class="text-[9px] text-slate-400 font-bold block leading-3 tracking-widest uppercase">Finance Portal</span>
      </div>
    </div>

    <!-- Navigation tabs -->
    <div class="flex items-center space-x-1 overflow-x-auto max-w-full pb-1 md:pb-0">
      <button 
        @click="$emit('switch-tab', 'dashboard')"
        :class="['px-4 py-2 rounded-xl text-xs font-bold transition duration-200 cursor-pointer active:scale-95 whitespace-nowrap', 
          activeTab === 'dashboard' ? 'bg-slate-800 text-yellow-400' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/30']"
      >
        Dashboard
      </button>
      
      <button 
        @click="$emit('switch-tab', 'auctions')"
        :class="['px-4 py-2 rounded-xl text-xs font-bold transition duration-200 cursor-pointer active:scale-95 whitespace-nowrap flex items-center', 
          activeTab === 'auctions' ? 'bg-slate-800 text-yellow-400 font-extrabold' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/30']"
      >
        <span class="w-1.5 h-1.5 rounded-full bg-yellow-400 mr-1.5 animate-pulse" v-if="activeTab === 'auctions'"></span>
        Auction Arena
      </button>

      <button 
        @click="$emit('switch-tab', 'portfolio')"
        :class="['px-4 py-2 rounded-xl text-xs font-bold transition duration-200 cursor-pointer active:scale-95 whitespace-nowrap', 
          activeTab === 'portfolio' ? 'bg-slate-800 text-yellow-400' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/30']"
      >
        My Portfolio
      </button>

      <button 
        @click="$emit('switch-tab', 'transactions')"
        :class="['px-4 py-2 rounded-xl text-xs font-bold transition duration-200 cursor-pointer active:scale-95 whitespace-nowrap', 
          activeTab === 'transactions' ? 'bg-slate-800 text-yellow-400' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/30']"
      >
        Ledger history
      </button>
    </div>

    <!-- Live Wallet Status Capsule -->
    <div class="flex items-center space-x-3">
      <div class="glass-panel bg-slate-950/80 px-3.5 py-1.5 rounded-2xl flex items-center space-x-2.5 border border-slate-800/60 shadow">
        <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
        <div class="text-left select-none">
          <span class="text-[8px] text-slate-500 font-bold uppercase block leading-3">Liquid Cash</span>
          <span class="text-xs font-bold text-slate-100 font-mono">{{ formatCurrency(store.wallet.balance) }}</span>
        </div>
      </div>
    </div>
  </nav>
</template>
