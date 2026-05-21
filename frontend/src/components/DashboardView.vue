<script setup>
import { ref, onMounted, computed } from 'vue'
import { useFinanceStore } from '../store/finance'

const store = useFinanceStore()
const depositAmount = ref(10000)
const successMessage = ref('')
const isDepositing = ref(false)

onMounted(async () => {
  await store.fetchDashboard()
})

const formatCurrency = (val) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
  }).format(val)
}

const handleDeposit = async () => {
  if (depositAmount.value <= 0) return
  isDepositing.value = true
  try {
    const data = await store.depositFunds(depositAmount.value)
    successMessage.value = `Successfully injected ${formatCurrency(depositAmount.value)} of capital!`
    setTimeout(() => { successMessage.value = '' }, 4000)
  } catch (err) {
    console.error(err)
  } finally {
    isDepositing.value = false
  }
}

// Custom High-Fidelity SVG Line Chart Helper
const svgPath = computed(() => {
  const data = store.dashboard.chart_data || []
  if (data.length < 2) return ''
  
  const width = 500
  const height = 180
  const padding = 30
  
  const values = data.map(d => d.value)
  const min = Math.min(...values) * 0.95
  const max = Math.max(...values) * 1.05
  const range = max - min || 1
  
  const points = data.map((d, index) => {
    const x = padding + (index * (width - 2 * padding) / (data.length - 1))
    const y = height - padding - ((d.value - min) * (height - 2 * padding) / range)
    return { x, y }
  })
  
  // Create smooth bezier curve path
  let path = `M ${points[0].x} ${points[0].y}`
  for (let i = 0; i < points.length - 1; i++) {
    const cpX1 = points[i].x + (points[i+1].x - points[i].x) / 3
    const cpY1 = points[i].y
    const cpX2 = points[i].x + 2 * (points[i+1].x - points[i].x) / 3
    const cpY2 = points[i+1].y
    path += ` C ${cpX1} ${cpY1}, ${cpX2} ${cpY2}, ${points[i+1].x} ${points[i+1].y}`
  }
  
  // Closed path for gradient fill
  const fillPath = `${path} L ${points[points.length-1].x} ${height - padding} L ${points[0].x} ${height - padding} Z`
  
  return { stroke: path, fill: fillPath, points }
})

// Custom SVG Donut Chart Helper
const donutSegments = computed(() => {
  const data = store.dashboard.risk_distribution || []
  const total = data.reduce((sum, d) => sum + d.value, 0)
  
  if (total === 0) {
    return [{ label: "Empty Portfolio", value: 0, percent: 100, strokeDash: "100, 100", strokeDashOffset: 0, color: "#475569" }]
  }
  
  const colors = {
    "Low Risk": "#10b981",    // Emerald
    "Medium Risk": "#6366f1", // Indigo
    "High Risk": "#f59e0b"    // Amber
  }
  
  let currentOffset = 0
  return data.map(d => {
    const percent = (d.value / total) * 100
    const strokeDash = `${percent}, 100`
    const strokeDashOffset = -currentOffset
    currentOffset += percent
    
    return {
      label: d.label,
      value: d.value,
      percent: percent.toFixed(0),
      strokeDash,
      strokeDashOffset,
      color: colors[d.label] || "#3b82f6"
    }
  })
})
</script>

<template>
  <div class="space-y-6">
    <!-- Notifications banner -->
    <div v-if="successMessage" class="glass-panel border-emerald-500/30 text-emerald-400 p-4 rounded-xl flex items-center shadow-lg glow-emerald animate-pulse">
      <svg class="w-6 h-6 mr-3 text-emerald-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
      <span class="font-medium text-sm md:text-base">{{ successMessage }}</span>
    </div>

    <!-- Quick Stats Grid -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Net Worth -->
      <div class="glass-panel glass-panel-hover p-4 rounded-2xl relative overflow-hidden shimmer-effect">
        <div class="absolute -right-6 -bottom-6 text-slate-800/10 w-24 h-24 font-bold select-none text-7xl">$</div>
        <span class="text-xs font-semibold text-slate-400 uppercase tracking-wider block">Net Worth</span>
        <span class="text-2xl md:text-3xl font-bold bg-gradient-to-r from-amber-200 via-yellow-400 to-amber-300 bg-clip-text text-transparent block mt-2 glow-amber">
          {{ formatCurrency(store.dashboard.metrics.net_worth) }}
        </span>
        <div class="text-[10px] md:text-xs text-slate-400 mt-2 flex items-center">
          <span class="text-emerald-400 font-semibold mr-1">Liquid Cap + Assets</span>
        </div>
      </div>

      <!-- Cash Wallet -->
      <div class="glass-panel glass-panel-hover p-4 rounded-2xl relative overflow-hidden">
        <span class="text-xs font-semibold text-slate-400 uppercase tracking-wider block">Available Cash</span>
        <span class="text-2xl md:text-3xl font-bold text-slate-100 block mt-2">
          {{ formatCurrency(store.dashboard.metrics.cash) }}
        </span>
        <div class="text-[10px] md:text-xs text-slate-400 mt-2 flex items-center">
          <span class="w-1.5 h-1.5 rounded-full bg-cyan-400 mr-1.5"></span> Ready to Bid
        </div>
      </div>

      <!-- Asset Value -->
      <div class="glass-panel glass-panel-hover p-4 rounded-2xl relative overflow-hidden">
        <span class="text-xs font-semibold text-slate-400 uppercase tracking-wider block">Portfolio Valuation</span>
        <span class="text-2xl md:text-3xl font-bold text-indigo-400 block mt-2 glow-indigo">
          {{ formatCurrency(store.dashboard.metrics.portfolio_value) }}
        </span>
        <div class="text-[10px] md:text-xs text-slate-400 mt-2 flex items-center">
          <span class="w-1.5 h-1.5 rounded-full bg-indigo-400 mr-1.5"></span> {{ store.dashboard.metrics.owned_stacks_count }} Tech Stacks
        </div>
      </div>

      <!-- Total Yield Earnings -->
      <div class="glass-panel glass-panel-hover p-4 rounded-2xl relative overflow-hidden">
        <span class="text-xs font-semibold text-slate-400 uppercase tracking-wider block">Yield Cash Flow</span>
        <span class="text-2xl md:text-3xl font-bold text-emerald-400 block mt-2 glow-emerald">
          {{ formatCurrency(store.dashboard.metrics.total_yield_earnings) }}
        </span>
        <div class="text-[10px] md:text-xs text-slate-400 mt-2 flex items-center">
          <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 mr-1.5"></span> Compounding Weekly
        </div>
      </div>
    </div>

    <!-- Charts and Actions Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Net Worth Growth Line Chart -->
      <div class="glass-panel p-5 rounded-2xl lg:col-span-2 flex flex-col justify-between">
        <div>
          <h3 class="text-base font-bold text-slate-100 flex items-center">
            <svg class="w-5 h-5 mr-2 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 12l3-3 3 3 4-4M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
            </svg>
            Net Worth Growth Timeline
          </h3>
          <p class="text-xs text-slate-400 mt-1">Reconstructed financial growth ledger based on transactions and bidding returns.</p>
        </div>

        <div class="w-full h-48 mt-4 flex items-center justify-center relative">
          <!-- Render custom SVG line chart if data exists -->
          <svg v-if="svgPath" viewBox="0 0 500 180" class="w-full h-full">
            <defs>
              <linearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#fbbf24" stop-opacity="0.25" />
                <stop offset="100%" stop-color="#fbbf24" stop-opacity="0.0" />
              </linearGradient>
            </defs>

            <!-- Grid Lines -->
            <line x1="30" y1="30" x2="470" y2="30" stroke="#1e293b" stroke-width="1" stroke-dasharray="4" />
            <line x1="30" y1="90" x2="470" y2="90" stroke="#1e293b" stroke-width="1" stroke-dasharray="4" />
            <line x1="30" y1="150" x2="470" y2="150" stroke="#1e293b" stroke-width="1" />

            <!-- Gradient Area Fill -->
            <path :d="svgPath.fill" fill="url(#chartGradient)" />

            <!-- Stroke Path -->
            <path :d="svgPath.stroke" fill="none" stroke="#fbbf24" stroke-width="3" stroke-linecap="round" class="glow-amber" />

            <!-- Highlight Data Circles -->
            <g v-for="(pt, idx) in svgPath.points" :key="idx">
              <circle :cx="pt.x" :cy="pt.y" r="5" fill="#0b0f19" stroke="#fbbf24" stroke-width="2" />
              <!-- Text tooltips below each circle -->
              <text :x="pt.x" :y="pt.y - 12" fill="#e2e8f0" font-size="9" text-anchor="middle" font-weight="600">
                {{ formatCurrency(store.dashboard.chart_data[idx].value) }}
              </text>
            </g>

            <!-- Bottom Labels -->
            <text v-for="(pt, idx) in svgPath.points" :key="'label-' + idx" :x="pt.x" y="168" fill="#64748b" font-size="9" text-anchor="middle">
              {{ store.dashboard.chart_data[idx].date }}
            </text>
          </svg>
          <div v-else class="text-xs text-slate-500">Generating chart...</div>
        </div>
      </div>

      <!-- Asset Allocations and Fund injection -->
      <div class="space-y-6">
        <!-- Asset allocation Donut Chart -->
        <div class="glass-panel p-5 rounded-2xl flex flex-col justify-between h-[230px]">
          <h3 class="text-base font-bold text-slate-100 flex items-center">
            <svg class="w-5 h-5 mr-2 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 3.055A9.003 9.003 0 1020.945 13H11V3.055z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z"></path>
            </svg>
            Risk Allocation
          </h3>
          
          <div class="flex items-center justify-between mt-3">
            <div class="relative w-28 h-28 flex items-center justify-center">
              <svg viewBox="0 0 36 36" class="w-full h-full">
                <!-- Outer empty circle -->
                <circle cx="18" cy="18" r="15.915" fill="transparent" stroke="#0f172a" stroke-width="4.5"></circle>
                <!-- Render Segment Rings -->
                <circle 
                  v-for="(seg, idx) in donutSegments" 
                  :key="idx" 
                  cx="18" 
                  cy="18" 
                  r="15.915" 
                  fill="transparent" 
                  :stroke="seg.color" 
                  stroke-width="4.5" 
                  :stroke-dasharray="seg.strokeDash" 
                  :stroke-dashoffset="seg.strokeDashOffset" 
                  stroke-linecap="round"
                  transform="rotate(-90 18 18)"
                ></circle>
              </svg>
              <div class="absolute inset-0 flex flex-col items-center justify-center select-none">
                <span class="text-[9px] uppercase tracking-wider text-slate-400 font-semibold">Total Owned</span>
                <span class="text-sm font-bold text-slate-100 mt-0.5">
                  {{ store.dashboard.metrics.owned_stacks_count }}
                </span>
              </div>
            </div>
            
            <div class="flex-1 ml-4 space-y-1.5">
              <div v-for="(seg, idx) in donutSegments" :key="idx" class="flex items-center justify-between text-xs">
                <span class="flex items-center text-slate-300">
                  <span class="w-2.5 h-2.5 rounded-full mr-2" :style="{ backgroundColor: seg.color }"></span>
                  {{ seg.label }}
                </span>
                <span class="font-semibold text-slate-100">{{ seg.percent }}%</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Deposit Capital Box -->
        <div class="glass-panel p-5 rounded-2xl">
          <h3 class="text-sm font-bold text-slate-100 uppercase tracking-wider">Fund Capital Account</h3>
          <p class="text-xs text-slate-400 mt-1">Inject mock seed capital into your available cash pool to buy premium stacks.</p>
          
          <div class="mt-4 flex items-center space-x-2">
            <select v-model="depositAmount" class="flex-1 bg-slate-900 border border-slate-700/60 rounded-xl px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-yellow-500">
              <option :value="10000">$10,000 Cash</option>
              <option :value="50000">$50,000 Cash</option>
              <option :value="100000">$100,000 Capital</option>
              <option :value="250000">$250,000 VC Funding</option>
            </select>
            <button 
              @click="handleDeposit" 
              :disabled="isDepositing"
              class="bg-gradient-to-r from-amber-400 to-yellow-500 text-slate-950 font-bold px-4 py-2 rounded-xl text-xs hover:from-amber-300 hover:to-yellow-400 transition transform hover:scale-[1.02] cursor-pointer shadow-lg glow-amber active:scale-[0.98] disabled:opacity-60"
            >
              {{ isDepositing ? 'Depositing...' : 'Inject Funds' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Transactions Box -->
    <div class="glass-panel p-5 rounded-2xl">
      <div class="flex items-center justify-between">
        <h3 class="text-base font-bold text-slate-100 flex items-center">
          <svg class="w-5 h-5 mr-2 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path>
          </svg>
          Recent Transactions
        </h3>
        <span class="text-xs text-indigo-400 cursor-pointer hover:underline" @click="$emit('switch-tab', 'transactions')">
          View full ledger
        </span>
      </div>
      
      <div class="mt-4 overflow-x-auto">
        <table class="w-full text-left text-xs border-collapse">
          <thead>
            <tr class="border-b border-slate-800 text-slate-400">
              <th class="py-2.5 font-semibold">Ledger ID</th>
              <th class="py-2.5 font-semibold">Transaction</th>
              <th class="py-2.5 font-semibold">Type</th>
              <th class="py-2.5 font-semibold">Timestamp</th>
              <th class="py-2.5 font-semibold text-right">Amount</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="tx in store.dashboard.recent_transactions" :key="tx.id" class="border-b border-slate-800/40 hover:bg-slate-800/10">
              <td class="py-3 font-mono text-slate-500">#{{ tx.id }}</td>
              <td class="py-3 font-medium text-slate-200">{{ tx.description }}</td>
              <td class="py-3">
                <span class="px-2 py-0.5 rounded text-[10px] font-semibold" :class="{
                  'bg-emerald-500/10 text-emerald-400': tx.transaction_type === 'deposit' || tx.transaction_type === 'dividend' || tx.transaction_type === 'liquidation',
                  'bg-rose-500/10 text-rose-400': tx.transaction_type === 'purchase'
                }">
                  {{ tx.transaction_type.toUpperCase() }}
                </span>
              </td>
              <td class="py-3 text-slate-400">
                {{ new Date(tx.timestamp).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) }}
              </td>
              <td class="py-3 text-right font-semibold font-mono" :class="tx.amount >= 0 ? 'text-emerald-400' : 'text-rose-400'">
                {{ tx.amount >= 0 ? '+' : '' }}{{ formatCurrency(tx.amount) }}
              </td>
            </tr>
            <tr v-if="!store.dashboard.recent_transactions || store.dashboard.recent_transactions.length === 0">
              <td colspan="5" class="py-4 text-center text-slate-500">No transactions recorded yet. Go fund capital!</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
