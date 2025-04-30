
<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve"></a>

# Module `0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve`

@title ReserveConfiguration module
@author Aave
@notice Implements the bitmap logic to handle the reserve configuration


-  [Resource `ReserveConfigurationMap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap)
-  [Constants](#@Constants_0)
-  [Function `init`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_init)
-  [Function `set_ltv`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_ltv)
-  [Function `get_ltv`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_ltv)
-  [Function `set_liquidation_threshold`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_threshold)
-  [Function `get_liquidation_threshold`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_threshold)
-  [Function `set_liquidation_bonus`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_bonus)
-  [Function `get_liquidation_bonus`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_bonus)
-  [Function `set_decimals`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_decimals)
-  [Function `get_decimals`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_decimals)
-  [Function `set_active`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_active)
-  [Function `get_active`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_active)
-  [Function `set_frozen`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_frozen)
-  [Function `get_frozen`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_frozen)
-  [Function `set_paused`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_paused)
-  [Function `get_paused`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_paused)
-  [Function `set_borrowable_in_isolation`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrowable_in_isolation)
-  [Function `get_borrowable_in_isolation`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrowable_in_isolation)
-  [Function `set_siloed_borrowing`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_siloed_borrowing)
-  [Function `get_siloed_borrowing`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_siloed_borrowing)
-  [Function `set_borrowing_enabled`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrowing_enabled)
-  [Function `get_borrowing_enabled`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrowing_enabled)
-  [Function `set_reserve_factor`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_reserve_factor)
-  [Function `get_reserve_factor`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_reserve_factor)
-  [Function `set_borrow_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrow_cap)
-  [Function `get_borrow_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrow_cap)
-  [Function `set_supply_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_supply_cap)
-  [Function `get_supply_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_supply_cap)
-  [Function `set_debt_ceiling`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_debt_ceiling)
-  [Function `get_debt_ceiling`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_debt_ceiling)
-  [Function `set_liquidation_protocol_fee`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_protocol_fee)
-  [Function `get_liquidation_protocol_fee`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_protocol_fee)
-  [Function `set_unbacked_mint_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_unbacked_mint_cap)
-  [Function `get_unbacked_mint_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_unbacked_mint_cap)
-  [Function `set_emode_category`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_emode_category)
-  [Function `get_emode_category`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_emode_category)
-  [Function `set_flash_loan_enabled`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_flash_loan_enabled)
-  [Function `get_flash_loan_enabled`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_flash_loan_enabled)
-  [Function `get_flags`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_flags)
-  [Function `get_params`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_params)
-  [Function `get_caps`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_caps)
-  [Function `get_debt_ceiling_decimals`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_debt_ceiling_decimals)
-  [Function `get_max_reserves_count`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_max_reserves_count)


<pre><code><b>use</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="helper.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_helper">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::helper</a>;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap"></a>

## Resource `ReserveConfigurationMap`



<pre><code><b>struct</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">ReserveConfigurationMap</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ACTIVE_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ACTIVE_MASK">ACTIVE_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039457511950319091711999;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWABLE_IN_ISOLATION_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWABLE_IN_ISOLATION_MASK">BORROWABLE_IN_ISOLATION_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039455278164903915945983;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWABLE_IN_ISOLATION_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWABLE_IN_ISOLATION_START_BIT_POSITION">BORROWABLE_IN_ISOLATION_START_BIT_POSITION</a>: u256 = 61;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWING_ENABLED_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWING_ENABLED_START_BIT_POSITION">BORROWING_ENABLED_START_BIT_POSITION</a>: u256 = 58;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWING_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROWING_MASK">BORROWING_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039457295777536977928191;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROW_CAP_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROW_CAP_MASK">BORROW_CAP_MASK</a>: u256 = 115792089237316195423570985008687907853269901588890828691141347134601036824575;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROW_CAP_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_BORROW_CAP_START_BIT_POSITION">BORROW_CAP_START_BIT_POSITION</a>: u256 = 80;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DEBT_CEILING_DECIMALS"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DEBT_CEILING_DECIMALS">DEBT_CEILING_DECIMALS</a>: u256 = 2;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DEBT_CEILING_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DEBT_CEILING_MASK">DEBT_CEILING_MASK</a>: u256 = 108555083659990515227827083269813533489170840026057959730454019326871953473535;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DEBT_CEILING_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DEBT_CEILING_START_BIT_POSITION">DEBT_CEILING_START_BIT_POSITION</a>: u256 = 212;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DECIMALS_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_DECIMALS_MASK">DECIMALS_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039457512231794068422655;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_EMODE_CATEGORY_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_EMODE_CATEGORY_MASK">EMODE_CATEGORY_MASK</a>: u256 = 115792089237316195423570889601861022891927484329094684320502060868636724166655;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_EMODE_CATEGORY_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_EMODE_CATEGORY_START_BIT_POSITION">EMODE_CATEGORY_START_BIT_POSITION</a>: u256 = 168;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_FLASHLOAN_ENABLED_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_FLASHLOAN_ENABLED_MASK">FLASHLOAN_ENABLED_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039448360635876274864127;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_FLASHLOAN_ENABLED_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_FLASHLOAN_ENABLED_START_BIT_POSITION">FLASHLOAN_ENABLED_START_BIT_POSITION</a>: u256 = 63;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_FROZEN_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_FROZEN_MASK">FROZEN_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039457439892725053784063;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_IS_ACTIVE_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_IS_ACTIVE_START_BIT_POSITION">IS_ACTIVE_START_BIT_POSITION</a>: u256 = 56;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_IS_FROZEN_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_IS_FROZEN_START_BIT_POSITION">IS_FROZEN_START_BIT_POSITION</a>: u256 = 57;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_IS_PAUSED_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_IS_PAUSED_START_BIT_POSITION">IS_PAUSED_START_BIT_POSITION</a>: u256 = 60;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_BONUS_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_BONUS_MASK">LIQUIDATION_BONUS_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039457583726442447896575;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_BONUS_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_BONUS_START_BIT_POSITION">LIQUIDATION_BONUS_START_BIT_POSITION</a>: u256 = 32;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_PROTOCOL_FEE_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_PROTOCOL_FEE_MASK">LIQUIDATION_PROTOCOL_FEE_MASK</a>: u256 = 115792089237316195423570984634549197687329661445021480007966928956539929624575;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION">LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION</a>: u256 = 152;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_THRESHOLD_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_THRESHOLD_MASK">LIQUIDATION_THRESHOLD_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039457584007908834738175;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_THRESHOLD_START_BIT_POSITION"></a>

@dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed


<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LIQUIDATION_THRESHOLD_START_BIT_POSITION">LIQUIDATION_THRESHOLD_START_BIT_POSITION</a>: u256 = 16;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LTV_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_LTV_MASK">LTV_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129574400;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_RESERVES_COUNT"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_RESERVES_COUNT">MAX_RESERVES_COUNT</a>: u16 = 128;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_BORROW_CAP"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_BORROW_CAP">MAX_VALID_BORROW_CAP</a>: u256 = 68719476735;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_DEBT_CEILING"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_DEBT_CEILING">MAX_VALID_DEBT_CEILING</a>: u256 = 1099511627775;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_DECIMALS"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_DECIMALS">MAX_VALID_DECIMALS</a>: u256 = 255;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_EMODE_CATEGORY"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_EMODE_CATEGORY">MAX_VALID_EMODE_CATEGORY</a>: u256 = 255;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LIQUIDATION_BONUS"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LIQUIDATION_BONUS">MAX_VALID_LIQUIDATION_BONUS</a>: u256 = 65535;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LIQUIDATION_PROTOCOL_FEE"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LIQUIDATION_PROTOCOL_FEE">MAX_VALID_LIQUIDATION_PROTOCOL_FEE</a>: u256 = 65535;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LIQUIDATION_THRESHOLD"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LIQUIDATION_THRESHOLD">MAX_VALID_LIQUIDATION_THRESHOLD</a>: u256 = 65535;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LTV"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_LTV">MAX_VALID_LTV</a>: u256 = 65535;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_RESERVE_FACTOR"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_RESERVE_FACTOR">MAX_VALID_RESERVE_FACTOR</a>: u256 = 65535;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_SUPPLY_CAP"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_SUPPLY_CAP">MAX_VALID_SUPPLY_CAP</a>: u256 = 68719476735;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_UNBACKED_MINT_CAP"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_MAX_VALID_UNBACKED_MINT_CAP">MAX_VALID_UNBACKED_MINT_CAP</a>: u256 = 68719476735;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_PAUSED_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_PAUSED_MASK">PAUSED_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039456431086408522792959;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_RESERVE_DECIMALS_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_RESERVE_DECIMALS_START_BIT_POSITION">RESERVE_DECIMALS_START_BIT_POSITION</a>: u256 = 48;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_RESERVE_FACTOR_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_RESERVE_FACTOR_MASK">RESERVE_FACTOR_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640562830550211137357664485375;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_RESERVE_FACTOR_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_RESERVE_FACTOR_START_BIT_POSITION">RESERVE_FACTOR_START_BIT_POSITION</a>: u256 = 64;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SILOED_BORROWING_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SILOED_BORROWING_MASK">SILOED_BORROWING_MASK</a>: u256 = 115792089237316195423570985008687907853269984665640564039452972321894702252031;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SILOED_BORROWING_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SILOED_BORROWING_START_BIT_POSITION">SILOED_BORROWING_START_BIT_POSITION</a>: u256 = 62;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SUPPLY_CAP_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SUPPLY_CAP_MASK">SUPPLY_CAP_MASK</a>: u256 = 115792089237316195423570985008682198862499243902866067452821842515308866174975;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SUPPLY_CAP_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_SUPPLY_CAP_START_BIT_POSITION">SUPPLY_CAP_START_BIT_POSITION</a>: u256 = 116;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_UNBACKED_MINT_CAP_MASK"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_UNBACKED_MINT_CAP_MASK">UNBACKED_MINT_CAP_MASK</a>: u256 = 115792089237309613405341795965490592094593402660309829990319025859654871678975;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_UNBACKED_MINT_CAP_START_BIT_POSITION"></a>



<pre><code><b>const</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_UNBACKED_MINT_CAP_START_BIT_POSITION">UNBACKED_MINT_CAP_START_BIT_POSITION</a>: u256 = 176;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_init"></a>

## Function `init`

@notice init the reserve configuration


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_init">init</a>(): <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_ltv"></a>

## Function `set_ltv`

@notice Sets the Loan to Value of the reserve
@param self The reserve configuration
@param ltv The new ltv


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_ltv">set_ltv</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, ltv: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_ltv"></a>

## Function `get_ltv`

@notice Gets the Loan to Value of the reserve
@param self The reserve configuration
@return The loan to value


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_ltv">get_ltv</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_threshold"></a>

## Function `set_liquidation_threshold`

@notice Sets the liquidation threshold of the reserve
@param self The reserve configuration
@param liquidation_threshold The new liquidation threshold


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_threshold">set_liquidation_threshold</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, liquidation_threshold: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_threshold"></a>

## Function `get_liquidation_threshold`

@notice Gets the liquidation threshold of the reserve
@param self The reserve configuration
@return The liquidation threshold


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_threshold">get_liquidation_threshold</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_bonus"></a>

## Function `set_liquidation_bonus`

@notice Sets the liquidation bonus of the reserve
@param self The reserve configuration
@param liquidation_bonus The new liquidation bonus


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_bonus">set_liquidation_bonus</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, liquidation_bonus: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_bonus"></a>

## Function `get_liquidation_bonus`

@notice Gets the liquidation bonus of the reserve
@param self The reserve configuration
@return The liquidation bonus


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_bonus">get_liquidation_bonus</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_decimals"></a>

## Function `set_decimals`

@notice Sets the decimals of the underlying asset of the reserve
@param self The reserve configuration
@param decimals The decimals


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_decimals">set_decimals</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, decimals: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_decimals"></a>

## Function `get_decimals`

@notice Gets the decimals of the underlying asset of the reserve
@param self The reserve configuration
@return The decimals


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_decimals">get_decimals</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_active"></a>

## Function `set_active`

@notice Sets the active state of the reserve
@param self The reserve configuration
@param active The new active state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_active">set_active</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, active: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_active"></a>

## Function `get_active`

@notice Gets the active state of the reserve
@param self The reserve configuration
@return The active state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_active">get_active</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_frozen"></a>

## Function `set_frozen`

@notice Sets the frozen state of the reserve
@param self The reserve configuration
@param frozen The new frozen state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_frozen">set_frozen</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, frozen: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_frozen"></a>

## Function `get_frozen`

@notice Gets the frozen state of the reserve
@param self The reserve configuration
@return The frozen state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_frozen">get_frozen</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_paused"></a>

## Function `set_paused`

@notice Sets the paused state of the reserve
@param self The reserve configuration
@param paused The new paused state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_paused">set_paused</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, paused: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_paused"></a>

## Function `get_paused`

@notice Gets the paused state of the reserve
@param self The reserve configuration
@return The paused state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_paused">get_paused</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrowable_in_isolation"></a>

## Function `set_borrowable_in_isolation`

@notice Sets the borrowing in isolation state of the reserve
@dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
amount will be accumulated in the isolated collateral's total debt exposure.
@dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
consistency in the debt ceiling calculations.
@param self The reserve configuration
@param borrowable The new borrowing in isolation state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrowable_in_isolation">set_borrowable_in_isolation</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, borrowable: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrowable_in_isolation"></a>

## Function `get_borrowable_in_isolation`

@notice Gets the borrowable in isolation flag for the reserve.
@dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
isolated collateral is accounted for in the isolated collateral's total debt exposure.
@dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
consistency in the debt ceiling calculations.
@param self The reserve configuration
@return The borrowable in isolation flag


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrowable_in_isolation">get_borrowable_in_isolation</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_siloed_borrowing"></a>

## Function `set_siloed_borrowing`

@notice Sets the siloed borrowing flag for the reserve.
@dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
@param self The reserve configuration
@param siloed_borrowing True if the asset is siloed


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_siloed_borrowing">set_siloed_borrowing</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, siloed_borrowing: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_siloed_borrowing"></a>

## Function `get_siloed_borrowing`

@notice Gets the siloed borrowing flag for the reserve.
@dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
@param self The reserve configuration
@return The siloed borrowing flag


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_siloed_borrowing">get_siloed_borrowing</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrowing_enabled"></a>

## Function `set_borrowing_enabled`

@notice Enables or disables borrowing on the reserve
@param self The reserve configuration
@param borrowing_enabled True if the borrowing needs to be enabled, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrowing_enabled">set_borrowing_enabled</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, borrowing_enabled: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrowing_enabled"></a>

## Function `get_borrowing_enabled`

@notice Gets the borrowing state of the reserve
@param self The reserve configuration
@return The borrowing state


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrowing_enabled">get_borrowing_enabled</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_reserve_factor"></a>

## Function `set_reserve_factor`

@notice Sets the reserve factor of the reserve
@param self The reserve configuration
@param reserve_factor The reserve factor


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_reserve_factor">set_reserve_factor</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, reserve_factor: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_reserve_factor"></a>

## Function `get_reserve_factor`

@notice Gets the reserve factor of the reserve
@param self The reserve configuration
@return The reserve factor


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_reserve_factor">get_reserve_factor</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrow_cap"></a>

## Function `set_borrow_cap`

@notice Sets the borrow cap of the reserve
@param self The reserve configuration
@param borrow_cap The borrow cap


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_borrow_cap">set_borrow_cap</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, borrow_cap: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrow_cap"></a>

## Function `get_borrow_cap`

@notice Gets the borrow cap of the reserve
@param self The reserve configuration
@return The borrow cap


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_borrow_cap">get_borrow_cap</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_supply_cap"></a>

## Function `set_supply_cap`

@notice Sets the supply cap of the reserve
@param self The reserve configuration
@param supply_cap The supply cap


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_supply_cap">set_supply_cap</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, supply_cap: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_supply_cap"></a>

## Function `get_supply_cap`

@notice Gets the supply cap of the reserve
@param self The reserve configuration
@return The supply cap


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_supply_cap">get_supply_cap</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_debt_ceiling"></a>

## Function `set_debt_ceiling`

@notice Sets the debt ceiling in isolation mode for the asset
@param self The reserve configuration
@param debt_ceiling The maximum debt ceiling for the asset


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_debt_ceiling">set_debt_ceiling</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, debt_ceiling: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_debt_ceiling"></a>

## Function `get_debt_ceiling`

@notice Gets the debt ceiling for the asset if the asset is in isolation mode
@param self The reserve configuration
@return The debt ceiling (0 = isolation mode disabled)


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_debt_ceiling">get_debt_ceiling</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_protocol_fee"></a>

## Function `set_liquidation_protocol_fee`

@notice Sets the liquidation protocol fee of the reserve
@param self The reserve configuration
@param liquidation_protocol_fee The liquidation protocol fee


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_liquidation_protocol_fee">set_liquidation_protocol_fee</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, liquidation_protocol_fee: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_protocol_fee"></a>

## Function `get_liquidation_protocol_fee`

@dev Gets the liquidation protocol fee
@param self The reserve configuration
@return The liquidation protocol fee


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_liquidation_protocol_fee">get_liquidation_protocol_fee</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_unbacked_mint_cap"></a>

## Function `set_unbacked_mint_cap`

@notice Sets the unbacked mint cap of the reserve
@param self The reserve configuration
@param unbacked_mint_cap The unbacked mint cap


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_unbacked_mint_cap">set_unbacked_mint_cap</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, unbacked_mint_cap: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_unbacked_mint_cap"></a>

## Function `get_unbacked_mint_cap`

@dev Gets the unbacked mint cap of the reserve
@param self The reserve configuration
@return The unbacked mint cap


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_unbacked_mint_cap">get_unbacked_mint_cap</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_emode_category"></a>

## Function `set_emode_category`

@notice Sets the eMode asset category
@param self The reserve configuration
@param emode_category The asset category when the user selects the eMode


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_emode_category">set_emode_category</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, emode_category: u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_emode_category"></a>

## Function `get_emode_category`

@dev Gets the eMode asset category
@param self The reserve configuration
@return The eMode category for the asset


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_emode_category">get_emode_category</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_flash_loan_enabled"></a>

## Function `set_flash_loan_enabled`

@notice Sets the flashloanable flag for the reserve
@param self The reserve configuration
@param flash_loan_enabled True if the asset is flashloanable, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_set_flash_loan_enabled">set_flash_loan_enabled</a>(self: &<b>mut</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>, flash_loan_enabled: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_flash_loan_enabled"></a>

## Function `get_flash_loan_enabled`

@notice Gets the flashloanable flag for the reserve
@param self The reserve configuration
@return The flashloanable flag


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_flash_loan_enabled">get_flash_loan_enabled</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_flags"></a>

## Function `get_flags`

@notice Gets the configuration flags of the reserve
@param self The reserve configuration
@return The state flag representing active
@return The state flag representing frozen
@return The state flag representing borrowing enabled
@return The state flag representing paused


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_flags">get_flags</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): (bool, bool, bool, bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_params"></a>

## Function `get_params`

@notice Gets the configuration parameters of the reserve from storage
@param self The reserve configuration
@return The state param representing ltv
@return The state param representing liquidation threshold
@return The state param representing liquidation bonus
@return The state param representing reserve decimals
@return The state param representing reserve factor
@return The state param representing eMode category


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_params">get_params</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): (u256, u256, u256, u256, u256, u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_caps"></a>

## Function `get_caps`

@notice Gets the caps parameters of the reserve from storage
@param self The reserve configuration
@return The state param representing borrow cap
@return The state param representing supply cap.


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_caps">get_caps</a>(self: &<a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_ReserveConfigurationMap">reserve::ReserveConfigurationMap</a>): (u256, u256)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_debt_ceiling_decimals"></a>

## Function `get_debt_ceiling_decimals`

@notice Gets the debt ceiling decimals


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_debt_ceiling_decimals">get_debt_ceiling_decimals</a>(): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_max_reserves_count"></a>

## Function `get_max_reserves_count`

@notice Gets the maximum number of reserves


<pre><code><b>public</b> <b>fun</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve_get_max_reserves_count">get_max_reserves_count</a>(): u16
</code></pre>
