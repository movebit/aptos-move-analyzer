
<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user"></a>

# Module `0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::user`

@title UserConfiguration library
@author Aave
@notice Implements the bitmap logic to handle the user configuration


-  [Resource `UserConfigurationMap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap)
-  [Constants](#@Constants_0)
-  [Function `init`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_init)
-  [Function `get_interest_rate_mode_none`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_interest_rate_mode_none)
-  [Function `get_interest_rate_mode_variable`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_interest_rate_mode_variable)
-  [Function `get_borrowing_mask`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_borrowing_mask)
-  [Function `get_collateral_mask`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_collateral_mask)
-  [Function `get_minimum_health_factor_liquidation_threshold`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_minimum_health_factor_liquidation_threshold)
-  [Function `get_health_factor_liquidation_threshold`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_health_factor_liquidation_threshold)
-  [Function `get_isolated_collateral_supplier_role`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_isolated_collateral_supplier_role)
-  [Function `set_borrowing`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_set_borrowing)
-  [Function `set_using_as_collateral`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_set_using_as_collateral)
-  [Function `is_using_as_collateral_or_borrowing`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_or_borrowing)
-  [Function `is_borrowing`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing)
-  [Function `is_using_as_collateral`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral)
-  [Function `is_using_as_collateral_one`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_one)
-  [Function `is_using_as_collateral_any`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_any)
-  [Function `is_borrowing_one`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing_one)
-  [Function `is_borrowing_any`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing_any)
-  [Function `is_empty`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_empty)
-  [Function `get_first_asset_id_by_mask`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_first_asset_id_by_mask)


<pre><code><b>use</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
<b>use</b> <a href="helper.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_helper">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::helper</a>;
<b>use</b> <a href="reserve_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_reserve">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::reserve</a>;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap"></a>

## Resource `UserConfigurationMap`



<pre><code><b>struct</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">UserConfigurationMap</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_BORROWING_MASK"></a>



<pre><code><b>const</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_BORROWING_MASK">BORROWING_MASK</a>: u256 = 38597363079105398474523661669562635951089994888546854679819194669304376546645;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_COLLATERAL_MASK"></a>



<pre><code><b>const</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_COLLATERAL_MASK">COLLATERAL_MASK</a>: u256 = 77194726158210796949047323339125271902179989777093709359638389338608753093290;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_HEALTH_FACTOR_LIQUIDATION_THRESHOLD"></a>

@dev Minimum health factor to consider a user position healthy
A value of 1e18 results in 1
1 * 10 ** 18


<pre><code><b>const</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_HEALTH_FACTOR_LIQUIDATION_THRESHOLD">HEALTH_FACTOR_LIQUIDATION_THRESHOLD</a>: u256 = 1000000000000000000;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_INTEREST_RATE_MODE_NONE"></a>



<pre><code><b>const</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_INTEREST_RATE_MODE_NONE">INTEREST_RATE_MODE_NONE</a>: u8 = 0;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_INTEREST_RATE_MODE_VARIABLE"></a>

1 = Stable Rate, 2 = Variable Rate, Since the Stable Rate service has been removed, only the Variable Rate service is retained.


<pre><code><b>const</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_INTEREST_RATE_MODE_VARIABLE">INTEREST_RATE_MODE_VARIABLE</a>: u8 = 2;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_ISOLATED_COLLATERAL_SUPPLIER_ROLE"></a>

@dev Role identifier for the role allowed to supply isolated reserves as collateral


<pre><code><b>const</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_ISOLATED_COLLATERAL_SUPPLIER_ROLE">ISOLATED_COLLATERAL_SUPPLIER_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [73, 83, 79, 76, 65, 84, 69, 68, 95, 67, 79, 76, 76, 65, 84, 69, 82, 65, 76, 95, 83, 85, 80, 80, 76, 73, 69, 82];
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD"></a>

Minimum health factor allowed under any circumstance
A value of 0.95e18 results in 0.95
0.95 * 10 ** 18


<pre><code><b>const</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD">MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD</a>: u256 = 950000000000000000;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_init"></a>

## Function `init`

@notice Initializes the user configuration map


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_init">init</a>(): <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_interest_rate_mode_none"></a>

## Function `get_interest_rate_mode_none`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_interest_rate_mode_none">get_interest_rate_mode_none</a>(): u8
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_interest_rate_mode_variable"></a>

## Function `get_interest_rate_mode_variable`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_interest_rate_mode_variable">get_interest_rate_mode_variable</a>(): u8
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_borrowing_mask"></a>

## Function `get_borrowing_mask`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_borrowing_mask">get_borrowing_mask</a>(): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_collateral_mask"></a>

## Function `get_collateral_mask`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_collateral_mask">get_collateral_mask</a>(): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_minimum_health_factor_liquidation_threshold"></a>

## Function `get_minimum_health_factor_liquidation_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_minimum_health_factor_liquidation_threshold">get_minimum_health_factor_liquidation_threshold</a>(): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_health_factor_liquidation_threshold"></a>

## Function `get_health_factor_liquidation_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_health_factor_liquidation_threshold">get_health_factor_liquidation_threshold</a>(): u256
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_isolated_collateral_supplier_role"></a>

## Function `get_isolated_collateral_supplier_role`



<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_isolated_collateral_supplier_role">get_isolated_collateral_supplier_role</a>(): <a href="">vector</a>&lt;u8&gt;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_set_borrowing"></a>

## Function `set_borrowing`

@notice Sets if the user is borrowing the reserve identified by reserve_index
@param self The configuration object
@param reserve_index The index of the reserve in the bitmap
@param borrowing True if the user is borrowing the reserve, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_set_borrowing">set_borrowing</a>(self: &<b>mut</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256, borrowing: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_set_using_as_collateral"></a>

## Function `set_using_as_collateral`

@notice Sets if the user is using as collateral the reserve identified by reserve_index
@param self The configuration object
@param reserve_index The index of the reserve in the bitmap
@param using_as_collateral True if the user is using the reserve as collateral, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_set_using_as_collateral">set_using_as_collateral</a>(self: &<b>mut</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256, using_as_collateral: bool)
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_or_borrowing"></a>

## Function `is_using_as_collateral_or_borrowing`

@notice Returns if a user has been using the reserve for borrowing or as collateral
@param self The configuration object
@param reserve_index The index of the reserve in the bitmap
@return True if the user has been using a reserve for borrowing or as collateral, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_or_borrowing">is_using_as_collateral_or_borrowing</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing"></a>

## Function `is_borrowing`

@notice Validate a user has been using the reserve for borrowing
@param self The configuration object
@param reserve_index The index of the reserve in the bitmap
@return True if the user has been using a reserve for borrowing, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing">is_borrowing</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral"></a>

## Function `is_using_as_collateral`

@notice Validate a user has been using the reserve as collateral
@param self The configuration object
@param reserve_index The index of the reserve in the bitmap
@return True if the user has been using a reserve as collateral, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral">is_using_as_collateral</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, reserve_index: u256): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_one"></a>

## Function `is_using_as_collateral_one`

@notice Checks if a user has been supplying only one reserve as collateral
@dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
@param self The configuration object
@return True if the user has been supplying as collateral one reserve, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_one">is_using_as_collateral_one</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_any"></a>

## Function `is_using_as_collateral_any`

@notice Checks if a user has been supplying any reserve as collateral
@param self The configuration object
@return True if the user has been supplying as collateral any reserve, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_using_as_collateral_any">is_using_as_collateral_any</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing_one"></a>

## Function `is_borrowing_one`

@notice Checks if a user has been borrowing only one asset
@dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
@param self The configuration object
@return True if the user has been supplying as collateral one reserve, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing_one">is_borrowing_one</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing_any"></a>

## Function `is_borrowing_any`

@notice Checks if a user has been borrowing from any reserve
@param self The configuration object
@return True if the user has been borrowing any reserve, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_borrowing_any">is_borrowing_any</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_empty"></a>

## Function `is_empty`

@notice Checks if a user has not been using any reserve for borrowing or supply
@param self The configuration object
@return True if the user has not been borrowing or supplying any reserve, false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_is_empty">is_empty</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>): bool
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_first_asset_id_by_mask"></a>

## Function `get_first_asset_id_by_mask`

@notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
@param self The configuration object
@return The index of the first asset flagged in the bitmap once the corresponding mask is applied


<pre><code><b>public</b> <b>fun</b> <a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_get_first_asset_id_by_mask">get_first_asset_id_by_mask</a>(self: &<a href="user_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_user_UserConfigurationMap">user::UserConfigurationMap</a>, mask: u256): u256
</code></pre>
