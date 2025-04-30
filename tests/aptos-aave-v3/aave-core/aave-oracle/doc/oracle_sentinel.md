
<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel"></a>

# Module `0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e::oracle_sentinel`

@title PriceOracleSentinel
@author Aave
@notice It validates if operations are allowed depending on the PriceOracle health.
@dev Once the PriceOracle gets up after an outage/downtime, users can make their positions healthy during a grace
period. So the PriceOracle is considered completely up once its up and the grace period passed.


-  [Struct `GracePeriodUpdated`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_GracePeriodUpdated)
-  [Resource `OracleSentinel`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_OracleSentinel)
-  [Constants](#@Constants_0)
-  [Function `init_oracle_sentinel`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_init_oracle_sentinel)
-  [Function `set_answer`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_set_answer)
-  [Function `latest_round_data`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_latest_round_data)
-  [Function `is_borrow_allowed`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_borrow_allowed)
-  [Function `is_liquidation_allowed`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_liquidation_allowed)
-  [Function `is_up_and_grace_period_passed`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_up_and_grace_period_passed)
-  [Function `set_grace_period`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_set_grace_period)
-  [Function `get_grace_period`](#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_get_grace_period)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="../../aave-acl/doc/acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage">0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage</a>;
<b>use</b> <a href="../../aave-config/doc/error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error">0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error</a>;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_GracePeriodUpdated"></a>

## Struct `GracePeriodUpdated`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_GracePeriodUpdated">GracePeriodUpdated</a> <b>has</b> drop, store
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_OracleSentinel"></a>

## Resource `OracleSentinel`



<pre><code><b>struct</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_OracleSentinel">OracleSentinel</a> <b>has</b> store, key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_E_ORACLE_NOT_ADMIN"></a>



<pre><code><b>const</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_E_ORACLE_NOT_ADMIN">E_ORACLE_NOT_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_E_RESOURCE_NOT_FOUND"></a>



<pre><code><b>const</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_E_RESOURCE_NOT_FOUND">E_RESOURCE_NOT_FOUND</a>: u64 = 2;
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_init_oracle_sentinel"></a>

## Function `init_oracle_sentinel`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_init_oracle_sentinel">init_oracle_sentinel</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_set_answer"></a>

## Function `set_answer`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_set_answer">set_answer</a>(<a href="">account</a>: &<a href="">signer</a>, is_down: bool, <a href="">timestamp</a>: u256)
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_latest_round_data"></a>

## Function `latest_round_data`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_latest_round_data">latest_round_data</a>(): (u128, u256, u256, u256, u128)
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_borrow_allowed"></a>

## Function `is_borrow_allowed`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_borrow_allowed">is_borrow_allowed</a>(): bool
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_liquidation_allowed"></a>

## Function `is_liquidation_allowed`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_liquidation_allowed">is_liquidation_allowed</a>(): bool
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_up_and_grace_period_passed"></a>

## Function `is_up_and_grace_period_passed`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_is_up_and_grace_period_passed">is_up_and_grace_period_passed</a>(): bool
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_set_grace_period"></a>

## Function `set_grace_period`



<pre><code><b>public</b> entry <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_set_grace_period">set_grace_period</a>(<a href="">account</a>: &<a href="">signer</a>, new_grace_period: u256)
</code></pre>



<a id="0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_get_grace_period"></a>

## Function `get_grace_period`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="oracle_sentinel.md#0xe02c89369099ad99993cbe3d4c3c80b299df006885854178a8acdb6ab6afb6e_oracle_sentinel_get_grace_period">get_grace_period</a>(): u256
</code></pre>
