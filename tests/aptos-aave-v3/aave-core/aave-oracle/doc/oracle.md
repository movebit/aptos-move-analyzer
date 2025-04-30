
<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle"></a>

# Module `0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle`



-  [Struct `OracleEvent`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_OracleEvent)
-  [Resource `AssetPriceList`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_AssetPriceList)
-  [Resource `RewardOracle`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle)
-  [Constants](#@Constants_0)
-  [Function `create_reward_oracle`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_create_reward_oracle)
-  [Function `decimals`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_decimals)
-  [Function `latest_answer`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_answer)
-  [Function `latest_timestamp`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_timestamp)
-  [Function `latest_round`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_round)
-  [Function `get_answer`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_answer)
-  [Function `get_timestamp`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_timestamp)
-  [Function `base_currency_unit`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_base_currency_unit)
-  [Function `get_asset_price`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_asset_price)
-  [Function `get_base_currency_unit`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_base_currency_unit)
-  [Function `set_asset_price`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_set_asset_price)
-  [Function `batch_set_asset_price`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_batch_set_asset_price)
-  [Function `update_asset_price`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_update_asset_price)
-  [Function `remove_asset_price`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_remove_asset_price)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::simple_map</a>;
<b>use</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel">0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle_sentinel</a>;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_OracleEvent"></a>

## Struct `OracleEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_OracleEvent">OracleEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_AssetPriceList"></a>

## Resource `AssetPriceList`



<pre><code><b>struct</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_AssetPriceList">AssetPriceList</a> <b>has</b> key
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle"></a>

## Resource `RewardOracle`



<pre><code><b>struct</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">RewardOracle</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_E_ORACLE_NOT_ADMIN"></a>



<pre><code><b>const</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_E_ORACLE_NOT_ADMIN">E_ORACLE_NOT_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_E_ASSET_ALREADY_EXISTS"></a>



<pre><code><b>const</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_E_ASSET_ALREADY_EXISTS">E_ASSET_ALREADY_EXISTS</a>: u64 = 2;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_E_ASSET_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_E_ASSET_NOT_EXISTS">E_ASSET_NOT_EXISTS</a>: u64 = 3;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_create_reward_oracle"></a>

## Function `create_reward_oracle`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_create_reward_oracle">create_reward_oracle</a>(id: u256): <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_decimals"></a>

## Function `decimals`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_decimals">decimals</a>(_reward_oracle: <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>): u8
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_answer"></a>

## Function `latest_answer`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_answer">latest_answer</a>(_reward_oracle: <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>): u256
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_timestamp"></a>

## Function `latest_timestamp`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_timestamp">latest_timestamp</a>(_reward_oracle: <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>): u256
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_round"></a>

## Function `latest_round`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_latest_round">latest_round</a>(_reward_oracle: <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>): u256
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_answer"></a>

## Function `get_answer`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_answer">get_answer</a>(_reward_oracle: <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>, _round_id: u256): u256
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_timestamp"></a>

## Function `get_timestamp`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_timestamp">get_timestamp</a>(_reward_oracle: <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>, _round_id: u256): u256
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_base_currency_unit"></a>

## Function `base_currency_unit`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_base_currency_unit">base_currency_unit</a>(_reward_oracle: <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_RewardOracle">oracle::RewardOracle</a>, _round_id: u256): u64
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_asset_price"></a>

## Function `get_asset_price`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_asset_price">get_asset_price</a>(asset: <b>address</b>): u256
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_base_currency_unit"></a>

## Function `get_base_currency_unit`



<pre><code><b>public</b> <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_get_base_currency_unit">get_base_currency_unit</a>(): <a href="_Option">option::Option</a>&lt;u256&gt;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_set_asset_price"></a>

## Function `set_asset_price`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_set_asset_price">set_asset_price</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, price: u256)
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_batch_set_asset_price"></a>

## Function `batch_set_asset_price`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_batch_set_asset_price">batch_set_asset_price</a>(<a href="">account</a>: &<a href="">signer</a>, assets: <a href="">vector</a>&lt;<b>address</b>&gt;, prices: <a href="">vector</a>&lt;u256&gt;)
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_update_asset_price"></a>

## Function `update_asset_price`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_update_asset_price">update_asset_price</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>, price: u256)
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_remove_asset_price"></a>

## Function `remove_asset_price`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_remove_asset_price">remove_asset_price</a>(<a href="">account</a>: &<a href="">signer</a>, asset: <b>address</b>)
</code></pre>
