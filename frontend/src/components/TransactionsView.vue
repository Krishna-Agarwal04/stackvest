<script setup>
import { ref, onMounted, computed } from 'vue'
import { useFinanceStore } from '../store/finance'

const store = useFinanceStore()
const filterType = ref('ALL')

onMounted(async () => {
  await store.fetchTransactions()
})

const formatCurrency = (val) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 2
  }).format(val)
}

const filteredTransactions = computed(() => {
  if (filterType.value === 'ALL') return store.transactions
  return store.transactions.filter(tx => tx.transaction_type.toUpperCase() === filterType.value)
})
</script>

<template>
  <div class="glass-panel p-5 rounded-2xl">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h2 class="text-base font-bold text-slate-100 flex items-center">
          <svg class="w-5 h-5 mr-2 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path>
          </svg>
          Audit Ledger History
        </h2>
        <p class="text-xs text-slate-400 mt-1">A transparent audit log of all financial interactions, deposits, investments, and payouts.</p>
      </div>

      <!-- Filters -->
      <div class="flex items-center space-x-2 text-xs">
        <span class="text-slate-400 font-semibold mr-1.5 hidden sm:inline">Filter By:</span>
        <select v-model="filterType" class="bg-slate-900 border border-slate-700/60 rounded-xl px-2.5 py-1.5 text-slate-200 focus:outline-none focus:border-indigo-500">
          <option value="ALL">All Operations</option>
          <option value="DEPOSIT">Deposits</option>
          <option value="PURCHASE">Purchases</option>
          <option value="DIVIDEND">Dividends</option>
          <option value="LIQUIDATION">Liquidations</option>
        </select>
      </div>
    </div>

    <!-- Ledger Table -->
    <div class="mt-5 overflow-x-auto">
      <table class="w-full text-left text-xs border-collapse">
        <thead>
          <tr class="border-b border-slate-800 text-slate-400">
            <th class="py-3 font-semibold pl-2">Audit Hash</th>
            <th class="py-3 font-semibold">Description</th>
            <th class="py-3 font-semibold">Ledger Action</th>
            <th class="py-3 font-semibold">Timestamp</th>
            <th class="py-3 font-semibold text-right pr-2">Balance Shift</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="tx in filteredTransactions" :key="tx.id" class="border-b border-slate-800/40 hover:bg-slate-800/10">
            <td class="py-3.5 pl-2 font-mono text-slate-500">#SHA-{{ tx.id + 1024 }}</td>
            <td class="py-3.5 font-medium text-slate-200">{{ tx.description }}</td>
            <td class="py-3.5">
              <span class="px-2 py-0.5 rounded text-[10px] font-bold" :class="{
                'bg-emerald-500/10 text-emerald-400 border border-emerald-500/10': tx.transaction_type === 'deposit' || tx.transaction_type === 'dividend' || tx.transaction_type === 'liquidation',
                'bg-rose-500/10 text-rose-400 border border-rose-500/10': tx.transaction_type === 'purchase'
              }">
                {{ tx.transaction_type.toUpperCase() }}
              </span>
            </td>
            <td class="py-3.5 text-slate-400 font-medium">
              {{ new Date(tx.timestamp).toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }) }}
            </td>
            <td class="py-3.5 text-right pr-2 font-bold font-mono" :class="tx.amount >= 0 ? 'text-emerald-400' : 'text-rose-400'">
              {{ tx.amount >= 0 ? '+' : '' }}{{ formatCurrency(tx.amount) }}
            </td>
          </tr>
          <tr v-if="filteredTransactions.length === 0">
            <td colspan="5" class="py-8 text-center text-slate-500">No records found for this filter type. Place bids or inject capital!</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
