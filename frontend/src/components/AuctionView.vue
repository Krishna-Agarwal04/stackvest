<script setup>
import { ref, onMounted, computed } from 'vue'
import { useFinanceStore } from '../store/finance'

const store = useFinanceStore()
const selectedStackId = ref(null)
const customBidAmount = ref(0)
const actionMessage = ref('')
const errorMessage = ref('')
const bidLoading = ref(false)
const isSimulating = ref(false)

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

const selectStack = async (id) => {
  selectedStackId.value = id
  errorMessage.value = ''
  actionMessage.value = ''
  const data = await store.fetchStackDetails(id)
  if (data && data.stack) {
    // Set default bid amount slightly higher than current high bid
    const minBid = data.stack.current_bid > 0 ? data.stack.current_bid : data.stack.valuation
    customBidAmount.value = Math.ceil((minBid * 1.05) / 100) * 100 // add ~5% and round to nearest 100
  }
}

const activeStack = computed(() => store.activeStackDetails)
const activeBids = computed(() => store.activeStackBids)

const submitBid = async () => {
  if (!activeStack.value) return
  bidLoading.value = true
  errorMessage.value = ''
  actionMessage.value = ''
  try {
    const data = await store.placeBid(activeStack.value.id, customBidAmount.value)
    actionMessage.value = data.message
    
    // Automatically recalculate minimum next bid
    const nextMin = activeStack.value.current_bid > 0 ? activeStack.value.current_bid : activeStack.value.valuation
    customBidAmount.value = Math.ceil((nextMin * 1.05) / 100) * 100

    setTimeout(() => { actionMessage.value = '' }, 4000)
  } catch (err) {
    errorMessage.value = err.message
  } finally {
    bidLoading.value = false
  }
}

const buyOutright = async (id) => {
  if (!confirm("Are you sure you want to buy this technology stack outright and claim immediate ownership?")) return
  errorMessage.value = ''
  actionMessage.value = ''
  try {
    const data = await store.buyStack(id)
    alert(data.message)
    selectedStackId.value = null
  } catch (err) {
    errorMessage.value = err.message
  }
}

// Trigger Simulated counter-bidding by competitors
const triggerSimulation = async () => {
  isSimulating.value = true
  try {
    await store.fetchStacks(true) // calls index with simulate=true
    if (selectedStackId.value) {
      await store.fetchStackDetails(selectedStackId.value)
    }
    actionMessage.value = "Competitor bids recorded! Check updated prices."
    setTimeout(() => { actionMessage.value = '' }, 4000)
  } catch (err) {
    console.error(err)
  } finally {
    isSimulating.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Screen Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
      <div>
        <h2 class="text-xl font-bold text-slate-100 flex items-center">
          <span class="w-2.5 h-2.5 rounded-full bg-yellow-400 mr-2 animate-ping"></span>
          Stacks Auction Arena
        </h2>
        <p class="text-xs text-slate-400 mt-1">Bid on active technology stack assets. Compete against rival funds in real-time.</p>
      </div>
      <button 
        @click="triggerSimulation"
        :disabled="isSimulating"
        class="bg-slate-800 border border-slate-700/80 hover:bg-slate-700 text-slate-200 font-semibold px-4 py-2 rounded-xl text-xs flex items-center transition transform active:scale-95 disabled:opacity-60 cursor-pointer shadow"
      >
        <svg class="w-4 h-4 mr-1.5 text-yellow-400 animate-spin" v-if="isSimulating" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.283 16h-1"></path>
        </svg>
        <svg class="w-4 h-4 mr-1.5 text-yellow-400" v-else fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
        </svg>
        {{ isSimulating ? 'Simulating Rivals...' : 'Trigger Rival Bids' }}
      </button>
    </div>

    <!-- Alert / Banner Banners -->
    <div v-if="actionMessage" class="glass-panel border-emerald-500/30 text-emerald-400 p-4 rounded-xl flex items-center shadow shadow-emerald-500/10">
      <svg class="w-5 h-5 mr-2 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
      <span class="text-xs font-semibold">{{ actionMessage }}</span>
    </div>

    <div v-if="errorMessage" class="glass-panel border-rose-500/30 text-rose-400 p-4 rounded-xl flex items-center shadow shadow-rose-500/10">
      <svg class="w-5 h-5 mr-2 text-rose-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
      </svg>
      <span class="text-xs font-semibold">{{ errorMessage }}</span>
    </div>

    <!-- Main Workspace Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left side: List of Auction Items -->
      <div class="lg:col-span-2 space-y-4">
        <div v-for="stack in store.auctionStacks" :key="stack.id" 
          @click="selectStack(stack.id)"
          :class="['glass-panel p-4 rounded-2xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4 cursor-pointer transition border border-transparent shadow hover:border-indigo-500/30', selectedStackId === stack.id ? 'border-yellow-500/40 bg-slate-800/40 glow-amber' : '']"
        >
          <!-- Stack Image and Info -->
          <div class="flex items-start md:items-center space-x-4">
            <div class="w-16 h-16 rounded-xl bg-slate-800 overflow-hidden flex-shrink-0 relative">
              <img :src="stack.image_url" class="w-full h-full object-cover" alt="Stack Cover" />
              <div class="absolute inset-0 bg-gradient-to-t from-slate-950/80 to-transparent"></div>
            </div>
            
            <div class="space-y-1">
              <h3 class="text-sm font-bold text-slate-100">{{ stack.name }}</h3>
              <p class="text-[11px] text-slate-400 line-clamp-1 max-w-sm md:max-w-md">{{ stack.description }}</p>
              
              <!-- Technologies Tags -->
              <div class="flex flex-wrap gap-1 mt-1.5">
                <span v-for="tech in stack.technologies_list" :key="tech" class="px-2 py-0.5 rounded-full bg-slate-900 border border-slate-800 text-[9px] font-semibold text-slate-300">
                  {{ tech }}
                </span>
              </div>
            </div>
          </div>

          <!-- Bidding Info & Actions -->
          <div class="flex md:flex-col items-center md:items-end justify-between md:justify-center w-full md:w-auto border-t border-slate-800 md:border-t-0 pt-3 md:pt-0">
            <div class="text-left md:text-right space-y-0.5">
              <span class="text-[10px] text-slate-400 font-medium block">Current High Bid</span>
              <span class="text-sm font-extrabold text-yellow-400 font-mono">
                {{ formatCurrency(stack.current_bid > 0 ? stack.current_bid : stack.valuation) }}
              </span>
              <span class="text-[9px] text-slate-400 block mt-0.5">
                by <span class="font-bold text-indigo-400">{{ stack.highest_bidder || 'No bids yet' }}</span>
              </span>
            </div>
            
            <div class="flex items-center space-x-2 mt-2 md:mt-3">
              <button 
                @click.stop="buyOutright(stack.id)"
                class="bg-indigo-600 hover:bg-indigo-500 text-white font-bold px-3 py-1.5 rounded-lg text-[10px] transition cursor-pointer"
              >
                Buy Outright
              </button>
            </div>
          </div>
        </div>
        
        <div v-if="store.auctionStacks.length === 0" class="glass-panel p-8 rounded-2xl text-center text-slate-500 text-xs">
          No stacks are currently listed in the Auction Arena. Check back or place your own portfolio stacks on the block!
        </div>
      </div>

      <!-- Right side: Bidding details panel -->
      <div class="glass-panel p-5 rounded-2xl h-fit">
        <div v-if="activeStack" class="space-y-5">
          <!-- Item info Header -->
          <div class="space-y-2">
            <span class="px-2.5 py-0.5 rounded bg-slate-900 border border-slate-800 text-[10px] font-bold uppercase tracking-wider text-slate-400" :class="{
              'text-emerald-400 border-emerald-500/25': activeStack.risk_level === 'Low',
              'text-indigo-400 border-indigo-500/25': activeStack.risk_level === 'Medium',
              'text-amber-400 border-amber-500/25': activeStack.risk_level === 'High',
            }">
              {{ activeStack.risk_level }} Risk Stack
            </span>
            <h3 class="text-base font-extrabold text-slate-100">{{ activeStack.name }}</h3>
            <p class="text-xs text-slate-400 leading-relaxed">{{ activeStack.description }}</p>
          </div>

          <!-- Financial Profile -->
          <div class="grid grid-cols-2 gap-3 p-3 bg-slate-900/60 rounded-xl border border-slate-800/40 text-xs">
            <div>
              <span class="text-slate-400 block font-medium">Base Valuation</span>
              <span class="text-slate-100 font-bold font-mono">{{ formatCurrency(activeStack.valuation) }}</span>
            </div>
            <div>
              <span class="text-slate-400 block font-medium">Expected Yield</span>
              <span class="text-emerald-400 font-bold">{{ activeStack.monthly_roi }}% / mo</span>
            </div>
          </div>

          <!-- Bidding form -->
          <div class="space-y-3 pt-3 border-t border-slate-800">
            <h4 class="text-xs font-bold text-slate-300 uppercase tracking-wider">Place Custom Bid</h4>
            <div class="text-[10px] text-slate-400 flex justify-between">
              <span>Your Cash: {{ formatCurrency(store.wallet.balance) }}</span>
              <span>Min Next Bid: {{ formatCurrency(activeStack.current_bid > 0 ? activeStack.current_bid * 1.01 : activeStack.valuation) }}</span>
            </div>
            
            <div class="flex items-center space-x-2">
              <div class="relative flex-1">
                <span class="absolute left-3 top-2.5 text-slate-500 font-bold text-xs">$</span>
                <input 
                  type="number" 
                  v-model="customBidAmount" 
                  class="w-full bg-slate-900 border border-slate-700/60 rounded-xl pl-6 pr-3 py-2 text-xs font-bold text-slate-100 font-mono focus:outline-none focus:border-yellow-500" 
                  placeholder="Amount" 
                />
              </div>
              <button 
                @click="submitBid"
                :disabled="bidLoading"
                class="bg-gradient-to-r from-amber-400 to-yellow-500 text-slate-950 font-bold px-4 py-2.5 rounded-xl text-xs transition hover:from-amber-300 hover:to-yellow-400 cursor-pointer shadow glow-amber"
              >
                {{ bidLoading ? 'Bidding...' : 'Bid' }}
              </button>
            </div>
          </div>

          <!-- Bid History Timeline -->
          <div class="space-y-3 pt-4 border-t border-slate-800">
            <h4 class="text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center">
              <svg class="w-4 h-4 mr-1 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
              Live Bidding History
            </h4>
            
            <div class="space-y-2 max-h-36 overflow-y-auto pr-1">
              <div v-for="(bid, idx) in activeBids" :key="bid.id" class="flex items-center justify-between text-xs py-1.5 border-b border-slate-800/40 last:border-0">
                <div class="space-y-0.5">
                  <span class="font-bold block" :class="bid.bidder_name === 'You' ? 'text-yellow-400' : 'text-slate-200'">
                    {{ bid.bidder_name }}
                  </span>
                  <span class="text-[9px] text-slate-400 block">
                    {{ new Date(bid.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) }}
                  </span>
                </div>
                <span class="font-bold font-mono text-slate-200" :class="idx === 0 ? 'text-yellow-400 font-extrabold' : ''">
                  {{ formatCurrency(bid.amount) }}
                </span>
              </div>
              <div v-if="!activeBids || activeBids.length === 0" class="text-center text-slate-500 text-[10px] py-4">
                No bidding history recorded. Place the first bid!
              </div>
            </div>
          </div>
        </div>

        <div v-else class="h-64 flex flex-col items-center justify-center text-center p-5 text-slate-500">
          <svg class="w-12 h-12 text-slate-600 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.907c.961 0 1.36 1.25.59 1.81l-3.97 2.88a1 1 0 00-.364 1.118l1.52 4.674c.3.922-.755 1.688-1.538 1.118l-3.971-2.88a1 1 0 00-1.175 0l-3.97 2.88c-.783.57-1.838-.197-1.538-1.118l1.52-4.674a1 1 0 00-.364-1.118L2.98 8.72c-.78-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"></path>
          </svg>
          <span class="text-xs font-semibold">No Stack Selected</span>
          <span class="text-[10px] text-slate-400 mt-1">Select an active technology stack on the left to participate in live-ish bidding!</span>
        </div>
      </div>
    </div>
  </div>
</template>
