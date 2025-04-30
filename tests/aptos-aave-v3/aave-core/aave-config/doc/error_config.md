
<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error"></a>

# Module `0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd::error`

@title Errors library
@author Aave
@notice Defines the error messages emitted by the different contracts of the Aave protocol


-  [Constants](#@Constants_0)
-  [Function `get_ecaller_not_pool_admin`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_admin)
-  [Function `get_ecaller_not_emergency_admin`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_emergency_admin)
-  [Function `get_ecaller_not_pool_or_emergency_admin`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_or_emergency_admin)
-  [Function `get_ecaller_not_risk_or_pool_admin`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_risk_or_pool_admin)
-  [Function `get_ecaller_not_asset_listing_or_pool_admin`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_asset_listing_or_pool_admin)
-  [Function `get_ecaller_not_bridge`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_bridge)
-  [Function `get_eaddresses_provider_not_registered`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaddresses_provider_not_registered)
-  [Function `get_einvalid_addresses_provider_id`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_addresses_provider_id)
-  [Function `get_enot_contract`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_enot_contract)
-  [Function `get_ecaller_not_pool_configurator`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_configurator)
-  [Function `get_ecaller_not_atoken`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_atoken)
-  [Function `get_einvalid_addresses_provider`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_addresses_provider)
-  [Function `get_einvalid_flashloan_executor_return`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_flashloan_executor_return)
-  [Function `get_ereserve_already_added`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_already_added)
-  [Function `get_ereserves_storage_count_mismatch`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserves_storage_count_mismatch)
-  [Function `get_eno_more_reserves_allowed`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_more_reserves_allowed)
-  [Function `get_eemode_category_reserved`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eemode_category_reserved)
-  [Function `get_einvalid_emode_category_assignment`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category_assignment)
-  [Function `get_ereserve_liquidity_not_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_liquidity_not_zero)
-  [Function `get_eflashloan_premium_invalid`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eflashloan_premium_invalid)
-  [Function `get_einvalid_reserve_params`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_params)
-  [Function `get_einvalid_emode_category_params`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category_params)
-  [Function `get_ebridge_protocol_fee_invalid`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ebridge_protocol_fee_invalid)
-  [Function `get_ecaller_must_be_pool`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_must_be_pool)
-  [Function `get_einvalid_mint_amount`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_mint_amount)
-  [Function `get_einvalid_burn_amount`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_burn_amount)
-  [Function `get_einvalid_amount`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_amount)
-  [Function `get_ereserve_inactive`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_inactive)
-  [Function `get_ereserve_frozen`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_frozen)
-  [Function `get_ereserve_paused`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_paused)
-  [Function `get_eborrowing_not_enabled`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eborrowing_not_enabled)
-  [Function `get_enot_enough_available_user_balance`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_enot_enough_available_user_balance)
-  [Function `get_einvalid_interest_rate_mode_selected`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_interest_rate_mode_selected)
-  [Function `get_ecollateral_balance_is_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_balance_is_zero)
-  [Function `get_ehealth_factor_lower_than_liquidation_threshold`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ehealth_factor_lower_than_liquidation_threshold)
-  [Function `get_ecollateral_cannot_cover_new_borrow`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_cannot_cover_new_borrow)
-  [Function `get_ecollateral_same_as_borrowing_currency`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_same_as_borrowing_currency)
-  [Function `get_eno_debt_of_selected_type`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_debt_of_selected_type)
-  [Function `get_eno_explicit_amount_to_repay_on_behalf`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_explicit_amount_to_repay_on_behalf)
-  [Function `get_eno_outstanding_variable_debt`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_outstanding_variable_debt)
-  [Function `get_eunderlying_balance_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_balance_zero)
-  [Function `get_einterest_rate_rebalance_conditions_not_met`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einterest_rate_rebalance_conditions_not_met)
-  [Function `get_ehealth_factor_not_below_threshold`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ehealth_factor_not_below_threshold)
-  [Function `get_ecollateral_cannot_be_liquidated`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_cannot_be_liquidated)
-  [Function `get_especified_currency_not_borrowed_by_user`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_especified_currency_not_borrowed_by_user)
-  [Function `get_einconsistent_flashloan_params`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_flashloan_params)
-  [Function `get_eborrow_cap_exceeded`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eborrow_cap_exceeded)
-  [Function `get_esupply_cap_exceeded`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esupply_cap_exceeded)
-  [Function `get_eunbacked_mint_cap_exceeded`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunbacked_mint_cap_exceeded)
-  [Function `get_edebt_ceiling_exceeded`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_edebt_ceiling_exceeded)
-  [Function `get_eunderlying_claimable_rights_not_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_claimable_rights_not_zero)
-  [Function `get_evariable_debt_supply_not_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_evariable_debt_supply_not_zero)
-  [Function `get_eltv_validation_failed`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eltv_validation_failed)
-  [Function `get_einconsistent_emode_category`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_emode_category)
-  [Function `get_eprice_oracle_sentinel_check_failed`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eprice_oracle_sentinel_check_failed)
-  [Function `get_easset_not_borrowable_in_isolation`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_easset_not_borrowable_in_isolation)
-  [Function `get_ereserve_already_initialized`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_already_initialized)
-  [Function `get_euser_in_isolation_mode_or_ltv_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_euser_in_isolation_mode_or_ltv_zero)
-  [Function `get_einvalid_ltv`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_ltv)
-  [Function `get_einvalid_liq_threshold`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liq_threshold)
-  [Function `get_einvalid_liq_bonus`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liq_bonus)
-  [Function `get_einvalid_decimals`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_decimals)
-  [Function `get_einvalid_reserve_factor`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_factor)
-  [Function `get_einvalid_borrow_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_borrow_cap)
-  [Function `get_einvalid_supply_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_supply_cap)
-  [Function `get_einvalid_liquidation_protocol_fee`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liquidation_protocol_fee)
-  [Function `get_einvalid_emode_category`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category)
-  [Function `get_einvalid_unbacked_mint_cap`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_unbacked_mint_cap)
-  [Function `get_einvalid_debt_ceiling`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_debt_ceiling)
-  [Function `get_einvalid_reserve_index`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_index)
-  [Function `get_eacl_admin_cannot_be_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eacl_admin_cannot_be_zero)
-  [Function `get_einconsistent_params_length`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_params_length)
-  [Function `get_ezero_address_not_valid`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ezero_address_not_valid)
-  [Function `get_einvalid_expiration`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_expiration)
-  [Function `get_einvalid_signature`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_signature)
-  [Function `get_eoperation_not_supported`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eoperation_not_supported)
-  [Function `get_edebt_ceiling_not_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_edebt_ceiling_not_zero)
-  [Function `get_easset_not_listed`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_easset_not_listed)
-  [Function `get_einvalid_optimal_usage_ratio`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_optimal_usage_ratio)
-  [Function `get_eunderlying_cannot_be_rescued`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_cannot_be_rescued)
-  [Function `get_eaddresses_provider_already_added`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaddresses_provider_already_added)
-  [Function `get_epool_addresses_do_not_match`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_epool_addresses_do_not_match)
-  [Function `get_esiloed_borrowing_violation`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esiloed_borrowing_violation)
-  [Function `get_ereserve_debt_not_zero`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_debt_not_zero)
-  [Function `get_eflashloan_disabled`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eflashloan_disabled)
-  [Function `get_euser_not_listed`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_euser_not_listed)
-  [Function `get_esigner_and_on_behalf_of_no_same`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esigner_and_on_behalf_of_no_same)
-  [Function `get_eaccount_does_not_exist`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaccount_does_not_exist)
-  [Function `get_flashloan_payer_not_receiver`](#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_flashloan_payer_not_receiver)


<pre><code></code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EACCOUNT_DOES_NOT_EXIST"></a>

Account does not exist


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>: u64 = 95;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EACL_ADMIN_CANNOT_BE_ZERO"></a>

ACL admin cannot be set to the zero address


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EACL_ADMIN_CANNOT_BE_ZERO">EACL_ADMIN_CANNOT_BE_ZERO</a>: u64 = 75;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EADDRESSES_PROVIDER_ALREADY_ADDED"></a>

Reserve has already been added to reserve list


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EADDRESSES_PROVIDER_ALREADY_ADDED">EADDRESSES_PROVIDER_ALREADY_ADDED</a>: u64 = 86;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EADDRESSES_PROVIDER_NOT_REGISTERED"></a>

Pool addresses provider is not registered


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EADDRESSES_PROVIDER_NOT_REGISTERED">EADDRESSES_PROVIDER_NOT_REGISTERED</a>: u64 = 7;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EASSET_NOT_BORROWABLE_IN_ISOLATION"></a>

Asset is not borrowable in isolation mode


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EASSET_NOT_BORROWABLE_IN_ISOLATION">EASSET_NOT_BORROWABLE_IN_ISOLATION</a>: u64 = 60;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EASSET_NOT_LISTED"></a>

Asset is not listed


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EASSET_NOT_LISTED">EASSET_NOT_LISTED</a>: u64 = 82;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EBORROWING_NOT_ENABLED"></a>

Borrowing is not enabled


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EBORROWING_NOT_ENABLED">EBORROWING_NOT_ENABLED</a>: u64 = 30;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EBORROW_CAP_EXCEEDED"></a>

Borrow cap is exceeded


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EBORROW_CAP_EXCEEDED">EBORROW_CAP_EXCEEDED</a>: u64 = 50;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EBRIDGE_PROTOCOL_FEE_INVALID"></a>

Invalid bridge protocol fee


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EBRIDGE_PROTOCOL_FEE_INVALID">EBRIDGE_PROTOCOL_FEE_INVALID</a>: u64 = 22;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_MUST_BE_POOL"></a>

The caller of this function must be a pool


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_MUST_BE_POOL">ECALLER_MUST_BE_POOL</a>: u64 = 23;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN"></a>

The caller of the function is not an asset listing or pool admin


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN">ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN</a>: u64 = 5;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_ATOKEN"></a>

The caller of the function is not an AToken


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_ATOKEN">ECALLER_NOT_ATOKEN</a>: u64 = 11;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_BRIDGE"></a>

The caller of the function is not a bridge


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_BRIDGE">ECALLER_NOT_BRIDGE</a>: u64 = 6;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_EMERGENCY_ADMIN"></a>

The caller of the function is not an emergency admin


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_EMERGENCY_ADMIN">ECALLER_NOT_EMERGENCY_ADMIN</a>: u64 = 2;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_POOL_ADMIN"></a>

The caller of the function is not a pool admin


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_POOL_ADMIN">ECALLER_NOT_POOL_ADMIN</a>: u64 = 1;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_POOL_CONFIGURATOR"></a>

The caller of the function is not the pool configurator


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_POOL_CONFIGURATOR">ECALLER_NOT_POOL_CONFIGURATOR</a>: u64 = 10;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN"></a>

The caller of the function is not a pool or emergency admin


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN">ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN</a>: u64 = 3;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_RISK_OR_POOL_ADMIN"></a>

The caller of the function is not a risk or pool admin


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECALLER_NOT_RISK_OR_POOL_ADMIN">ECALLER_NOT_RISK_OR_POOL_ADMIN</a>: u64 = 4;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_BALANCE_IS_ZERO"></a>

The collateral balance is 0


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_BALANCE_IS_ZERO">ECOLLATERAL_BALANCE_IS_ZERO</a>: u64 = 34;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_CANNOT_BE_LIQUIDATED"></a>

The collateral chosen cannot be liquidated


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_CANNOT_BE_LIQUIDATED">ECOLLATERAL_CANNOT_BE_LIQUIDATED</a>: u64 = 46;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_CANNOT_COVER_NEW_BORROW"></a>

There is not enough collateral to cover a new borrow


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_CANNOT_COVER_NEW_BORROW">ECOLLATERAL_CANNOT_COVER_NEW_BORROW</a>: u64 = 36;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_SAME_AS_BORROWING_CURRENCY"></a>

Collateral is (mostly) the same currency that is being borrowed


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ECOLLATERAL_SAME_AS_BORROWING_CURRENCY">ECOLLATERAL_SAME_AS_BORROWING_CURRENCY</a>: u64 = 37;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EDEBT_CEILING_EXCEEDED"></a>

Debt ceiling is exceeded


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EDEBT_CEILING_EXCEEDED">EDEBT_CEILING_EXCEEDED</a>: u64 = 53;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EDEBT_CEILING_NOT_ZERO"></a>

Debt ceiling is not zero


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EDEBT_CEILING_NOT_ZERO">EDEBT_CEILING_NOT_ZERO</a>: u64 = 81;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EEMODE_CATEGORY_RESERVED"></a>

Zero eMode category is reserved for volatile heterogeneous assets


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EEMODE_CATEGORY_RESERVED">EEMODE_CATEGORY_RESERVED</a>: u64 = 16;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EFLASHLOAN_DISABLED"></a>

FlashLoaning for this asset is disabled


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EFLASHLOAN_DISABLED">EFLASHLOAN_DISABLED</a>: u64 = 91;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EFLASHLOAN_PAYER_NOT_RECEIVER"></a>

Flashloan payer is different from the flashloan receiver


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EFLASHLOAN_PAYER_NOT_RECEIVER">EFLASHLOAN_PAYER_NOT_RECEIVER</a>: u64 = 95;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EFLASHLOAN_PREMIUM_INVALID"></a>

Invalid flashloan premium


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EFLASHLOAN_PREMIUM_INVALID">EFLASHLOAN_PREMIUM_INVALID</a>: u64 = 19;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD"></a>

Health factor is lesser than the liquidation threshold


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD">EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD</a>: u64 = 35;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EHEALTH_FACTOR_NOT_BELOW_THRESHOLD"></a>

Health factor is not below the threshold


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EHEALTH_FACTOR_NOT_BELOW_THRESHOLD">EHEALTH_FACTOR_NOT_BELOW_THRESHOLD</a>: u64 = 45;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINCONSISTENT_EMODE_CATEGORY"></a>

Inconsistent eMode category


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINCONSISTENT_EMODE_CATEGORY">EINCONSISTENT_EMODE_CATEGORY</a>: u64 = 58;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINCONSISTENT_FLASHLOAN_PARAMS"></a>

Inconsistent flashloan parameters


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINCONSISTENT_FLASHLOAN_PARAMS">EINCONSISTENT_FLASHLOAN_PARAMS</a>: u64 = 49;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINCONSISTENT_PARAMS_LENGTH"></a>

Array parameters that should be equal length are not


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINCONSISTENT_PARAMS_LENGTH">EINCONSISTENT_PARAMS_LENGTH</a>: u64 = 76;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET"></a>

Interest rate rebalance conditions were not met


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET">EINTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET</a>: u64 = 44;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_ADDRESSES_PROVIDER"></a>

The address of the pool addresses provider is invalid


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_ADDRESSES_PROVIDER">EINVALID_ADDRESSES_PROVIDER</a>: u64 = 12;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_ADDRESSES_PROVIDER_ID"></a>

Invalid id for the pool addresses provider


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_ADDRESSES_PROVIDER_ID">EINVALID_ADDRESSES_PROVIDER_ID</a>: u64 = 8;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_AMOUNT"></a>

Amount must be greater than 0


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_AMOUNT">EINVALID_AMOUNT</a>: u64 = 26;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_BORROW_CAP"></a>

Invalid borrow cap for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_BORROW_CAP">EINVALID_BORROW_CAP</a>: u64 = 68;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_BURN_AMOUNT"></a>

Invalid amount to burn


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_BURN_AMOUNT">EINVALID_BURN_AMOUNT</a>: u64 = 25;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_DEBT_CEILING"></a>

Invalid debt ceiling for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_DEBT_CEILING">EINVALID_DEBT_CEILING</a>: u64 = 73;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_DECIMALS"></a>

Invalid decimals parameter of the underlying asset of the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_DECIMALS">EINVALID_DECIMALS</a>: u64 = 66;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EMODE_CATEGORY"></a>

Invalid eMode category for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EMODE_CATEGORY">EINVALID_EMODE_CATEGORY</a>: u64 = 71;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EMODE_CATEGORY_ASSIGNMENT"></a>

Invalid eMode category assignment to asset


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EMODE_CATEGORY_ASSIGNMENT">EINVALID_EMODE_CATEGORY_ASSIGNMENT</a>: u64 = 17;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EMODE_CATEGORY_PARAMS"></a>

Invalid risk parameters for the eMode category


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EMODE_CATEGORY_PARAMS">EINVALID_EMODE_CATEGORY_PARAMS</a>: u64 = 21;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EXPIRATION"></a>

Invalid expiration


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_EXPIRATION">EINVALID_EXPIRATION</a>: u64 = 78;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_FLASHLOAN_EXECUTOR_RETURN"></a>

Invalid return value of the flashloan executor function


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_FLASHLOAN_EXECUTOR_RETURN">EINVALID_FLASHLOAN_EXECUTOR_RETURN</a>: u64 = 13;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_INTEREST_RATE_MODE_SELECTED"></a>

Invalid interest rate mode selected


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_INTEREST_RATE_MODE_SELECTED">EINVALID_INTEREST_RATE_MODE_SELECTED</a>: u64 = 33;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LIQUIDATION_PROTOCOL_FEE"></a>

Invalid liquidation protocol fee for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LIQUIDATION_PROTOCOL_FEE">EINVALID_LIQUIDATION_PROTOCOL_FEE</a>: u64 = 70;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LIQ_BONUS"></a>

Invalid liquidity bonus parameter for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LIQ_BONUS">EINVALID_LIQ_BONUS</a>: u64 = 65;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LIQ_THRESHOLD"></a>

Invalid liquidity threshold parameter for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LIQ_THRESHOLD">EINVALID_LIQ_THRESHOLD</a>: u64 = 64;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LTV"></a>

Invalid ltv parameter for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_LTV">EINVALID_LTV</a>: u64 = 63;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_MINT_AMOUNT"></a>

Invalid amount to mint


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_MINT_AMOUNT">EINVALID_MINT_AMOUNT</a>: u64 = 24;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_OPTIMAL_USAGE_RATIO"></a>

Invalid optimal usage ratio


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_OPTIMAL_USAGE_RATIO">EINVALID_OPTIMAL_USAGE_RATIO</a>: u64 = 83;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_RESERVE_FACTOR"></a>

Invalid reserve factor parameter for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_RESERVE_FACTOR">EINVALID_RESERVE_FACTOR</a>: u64 = 67;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_RESERVE_INDEX"></a>

Invalid reserve index


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_RESERVE_INDEX">EINVALID_RESERVE_INDEX</a>: u64 = 74;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_RESERVE_PARAMS"></a>

Invalid risk parameters for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_RESERVE_PARAMS">EINVALID_RESERVE_PARAMS</a>: u64 = 20;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_SIGNATURE"></a>

Invalid signature


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_SIGNATURE">EINVALID_SIGNATURE</a>: u64 = 79;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_SUPPLY_CAP"></a>

Invalid supply cap for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_SUPPLY_CAP">EINVALID_SUPPLY_CAP</a>: u64 = 69;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_UNBACKED_MINT_CAP"></a>

Invalid unbacked mint cap for the reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EINVALID_UNBACKED_MINT_CAP">EINVALID_UNBACKED_MINT_CAP</a>: u64 = 72;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ELTV_VALIDATION_FAILED"></a>

Ltv validation failed


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ELTV_VALIDATION_FAILED">ELTV_VALIDATION_FAILED</a>: u64 = 57;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENOT_CONTRACT"></a>

Address is not a contract


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENOT_CONTRACT">ENOT_CONTRACT</a>: u64 = 9;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENOT_ENOUGH_AVAILABLE_USER_BALANCE"></a>

User cannot withdraw more than the available balance


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENOT_ENOUGH_AVAILABLE_USER_BALANCE">ENOT_ENOUGH_AVAILABLE_USER_BALANCE</a>: u64 = 32;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_DEBT_OF_SELECTED_TYPE"></a>

For repayment of a specific type of debt, the user needs to have debt that type


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_DEBT_OF_SELECTED_TYPE">ENO_DEBT_OF_SELECTED_TYPE</a>: u64 = 39;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF"></a>

To repay on behalf of a user an explicit amount to repay is needed


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF">ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF</a>: u64 = 40;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_MORE_RESERVES_ALLOWED"></a>

Maximum amount of reserves in the pool reached


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_MORE_RESERVES_ALLOWED">ENO_MORE_RESERVES_ALLOWED</a>: u64 = 15;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_OUTSTANDING_VARIABLE_DEBT"></a>

User does not have outstanding variable rate debt on this reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ENO_OUTSTANDING_VARIABLE_DEBT">ENO_OUTSTANDING_VARIABLE_DEBT</a>: u64 = 42;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EOPERATION_NOT_SUPPORTED"></a>

Operation not supported


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EOPERATION_NOT_SUPPORTED">EOPERATION_NOT_SUPPORTED</a>: u64 = 80;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EPOOL_ADDRESSES_DO_NOT_MATCH"></a>

The token implementation pool address and the pool address provided by the initializing pool do not match


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EPOOL_ADDRESSES_DO_NOT_MATCH">EPOOL_ADDRESSES_DO_NOT_MATCH</a>: u64 = 87;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EPRICE_ORACLE_SENTINEL_CHECK_FAILED"></a>

Price oracle sentinel validation failed


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EPRICE_ORACLE_SENTINEL_CHECK_FAILED">EPRICE_ORACLE_SENTINEL_CHECK_FAILED</a>: u64 = 59;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVES_STORAGE_COUNT_MISMATCH"></a>

Mismatch of reserves count in storage


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVES_STORAGE_COUNT_MISMATCH">ERESERVES_STORAGE_COUNT_MISMATCH</a>: u64 = 93;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_ALREADY_ADDED"></a>

Reserve has already been added to reserve list


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_ALREADY_ADDED">ERESERVE_ALREADY_ADDED</a>: u64 = 14;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_ALREADY_INITIALIZED"></a>

Reserve has already been initialized


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_ALREADY_INITIALIZED">ERESERVE_ALREADY_INITIALIZED</a>: u64 = 61;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_DEBT_NOT_ZERO"></a>

the total debt of the reserve needs to be 0


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_DEBT_NOT_ZERO">ERESERVE_DEBT_NOT_ZERO</a>: u64 = 90;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_FROZEN"></a>

Action cannot be performed because the reserve is frozen


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_FROZEN">ERESERVE_FROZEN</a>: u64 = 28;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_INACTIVE"></a>

Action requires an active reserve


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_INACTIVE">ERESERVE_INACTIVE</a>: u64 = 27;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_LIQUIDITY_NOT_ZERO"></a>

The liquidity of the reserve needs to be 0


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_LIQUIDITY_NOT_ZERO">ERESERVE_LIQUIDITY_NOT_ZERO</a>: u64 = 18;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_PAUSED"></a>

Action cannot be performed because the reserve is paused


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ERESERVE_PAUSED">ERESERVE_PAUSED</a>: u64 = 29;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESIGNER_AND_ON_BEHALF_OF_NO_SAME"></a>

The person who signed must be consistent with on_behalf_of


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESIGNER_AND_ON_BEHALF_OF_NO_SAME">ESIGNER_AND_ON_BEHALF_OF_NO_SAME</a>: u64 = 94;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESILOED_BORROWING_VIOLATION"></a>

User is trying to borrow multiple assets including a siloed one


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESILOED_BORROWING_VIOLATION">ESILOED_BORROWING_VIOLATION</a>: u64 = 89;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER"></a>

User did not borrow the specified currency


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER">ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER</a>: u64 = 47;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESUPPLY_CAP_EXCEEDED"></a>

Supply cap is exceeded


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_ESUPPLY_CAP_EXCEEDED">ESUPPLY_CAP_EXCEEDED</a>: u64 = 51;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNBACKED_MINT_CAP_EXCEEDED"></a>

Unbacked mint cap is exceeded


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNBACKED_MINT_CAP_EXCEEDED">EUNBACKED_MINT_CAP_EXCEEDED</a>: u64 = 52;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNDERLYING_BALANCE_ZERO"></a>

The underlying balance needs to be greater than 0


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNDERLYING_BALANCE_ZERO">EUNDERLYING_BALANCE_ZERO</a>: u64 = 43;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNDERLYING_CANNOT_BE_RESCUED"></a>

The underlying asset cannot be rescued


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNDERLYING_CANNOT_BE_RESCUED">EUNDERLYING_CANNOT_BE_RESCUED</a>: u64 = 85;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO"></a>

Claimable rights over underlying not zero (aToken supply or accruedToTreasury)


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO">EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO</a>: u64 = 54;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO"></a>

User is in isolation mode or ltv is zero


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO">EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO</a>: u64 = 62;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUSER_NOT_LISTED"></a>

User is not listed


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EUSER_NOT_LISTED">EUSER_NOT_LISTED</a>: u64 = 92;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EVARIABLE_DEBT_SUPPLY_NOT_ZERO"></a>

Variable debt supply is not zero


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EVARIABLE_DEBT_SUPPLY_NOT_ZERO">EVARIABLE_DEBT_SUPPLY_NOT_ZERO</a>: u64 = 56;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EZERO_ADDRESS_NOT_VALID"></a>

Zero address not valid


<pre><code><b>const</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_EZERO_ADDRESS_NOT_VALID">EZERO_ADDRESS_NOT_VALID</a>: u64 = 77;
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_admin"></a>

## Function `get_ecaller_not_pool_admin`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_admin">get_ecaller_not_pool_admin</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_emergency_admin"></a>

## Function `get_ecaller_not_emergency_admin`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_emergency_admin">get_ecaller_not_emergency_admin</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_or_emergency_admin"></a>

## Function `get_ecaller_not_pool_or_emergency_admin`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_or_emergency_admin">get_ecaller_not_pool_or_emergency_admin</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_risk_or_pool_admin"></a>

## Function `get_ecaller_not_risk_or_pool_admin`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_risk_or_pool_admin">get_ecaller_not_risk_or_pool_admin</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_asset_listing_or_pool_admin"></a>

## Function `get_ecaller_not_asset_listing_or_pool_admin`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_asset_listing_or_pool_admin">get_ecaller_not_asset_listing_or_pool_admin</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_bridge"></a>

## Function `get_ecaller_not_bridge`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_bridge">get_ecaller_not_bridge</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaddresses_provider_not_registered"></a>

## Function `get_eaddresses_provider_not_registered`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaddresses_provider_not_registered">get_eaddresses_provider_not_registered</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_addresses_provider_id"></a>

## Function `get_einvalid_addresses_provider_id`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_addresses_provider_id">get_einvalid_addresses_provider_id</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_enot_contract"></a>

## Function `get_enot_contract`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_enot_contract">get_enot_contract</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_configurator"></a>

## Function `get_ecaller_not_pool_configurator`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_pool_configurator">get_ecaller_not_pool_configurator</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_atoken"></a>

## Function `get_ecaller_not_atoken`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_not_atoken">get_ecaller_not_atoken</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_addresses_provider"></a>

## Function `get_einvalid_addresses_provider`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_addresses_provider">get_einvalid_addresses_provider</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_flashloan_executor_return"></a>

## Function `get_einvalid_flashloan_executor_return`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_flashloan_executor_return">get_einvalid_flashloan_executor_return</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_already_added"></a>

## Function `get_ereserve_already_added`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_already_added">get_ereserve_already_added</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserves_storage_count_mismatch"></a>

## Function `get_ereserves_storage_count_mismatch`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserves_storage_count_mismatch">get_ereserves_storage_count_mismatch</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_more_reserves_allowed"></a>

## Function `get_eno_more_reserves_allowed`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_more_reserves_allowed">get_eno_more_reserves_allowed</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eemode_category_reserved"></a>

## Function `get_eemode_category_reserved`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eemode_category_reserved">get_eemode_category_reserved</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category_assignment"></a>

## Function `get_einvalid_emode_category_assignment`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category_assignment">get_einvalid_emode_category_assignment</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_liquidity_not_zero"></a>

## Function `get_ereserve_liquidity_not_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_liquidity_not_zero">get_ereserve_liquidity_not_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eflashloan_premium_invalid"></a>

## Function `get_eflashloan_premium_invalid`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eflashloan_premium_invalid">get_eflashloan_premium_invalid</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_params"></a>

## Function `get_einvalid_reserve_params`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_params">get_einvalid_reserve_params</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category_params"></a>

## Function `get_einvalid_emode_category_params`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category_params">get_einvalid_emode_category_params</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ebridge_protocol_fee_invalid"></a>

## Function `get_ebridge_protocol_fee_invalid`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ebridge_protocol_fee_invalid">get_ebridge_protocol_fee_invalid</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_must_be_pool"></a>

## Function `get_ecaller_must_be_pool`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecaller_must_be_pool">get_ecaller_must_be_pool</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_mint_amount"></a>

## Function `get_einvalid_mint_amount`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_mint_amount">get_einvalid_mint_amount</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_burn_amount"></a>

## Function `get_einvalid_burn_amount`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_burn_amount">get_einvalid_burn_amount</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_amount"></a>

## Function `get_einvalid_amount`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_amount">get_einvalid_amount</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_inactive"></a>

## Function `get_ereserve_inactive`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_inactive">get_ereserve_inactive</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_frozen"></a>

## Function `get_ereserve_frozen`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_frozen">get_ereserve_frozen</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_paused"></a>

## Function `get_ereserve_paused`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_paused">get_ereserve_paused</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eborrowing_not_enabled"></a>

## Function `get_eborrowing_not_enabled`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eborrowing_not_enabled">get_eborrowing_not_enabled</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_enot_enough_available_user_balance"></a>

## Function `get_enot_enough_available_user_balance`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_enot_enough_available_user_balance">get_enot_enough_available_user_balance</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_interest_rate_mode_selected"></a>

## Function `get_einvalid_interest_rate_mode_selected`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_interest_rate_mode_selected">get_einvalid_interest_rate_mode_selected</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_balance_is_zero"></a>

## Function `get_ecollateral_balance_is_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_balance_is_zero">get_ecollateral_balance_is_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ehealth_factor_lower_than_liquidation_threshold"></a>

## Function `get_ehealth_factor_lower_than_liquidation_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ehealth_factor_lower_than_liquidation_threshold">get_ehealth_factor_lower_than_liquidation_threshold</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_cannot_cover_new_borrow"></a>

## Function `get_ecollateral_cannot_cover_new_borrow`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_cannot_cover_new_borrow">get_ecollateral_cannot_cover_new_borrow</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_same_as_borrowing_currency"></a>

## Function `get_ecollateral_same_as_borrowing_currency`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_same_as_borrowing_currency">get_ecollateral_same_as_borrowing_currency</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_debt_of_selected_type"></a>

## Function `get_eno_debt_of_selected_type`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_debt_of_selected_type">get_eno_debt_of_selected_type</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_explicit_amount_to_repay_on_behalf"></a>

## Function `get_eno_explicit_amount_to_repay_on_behalf`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_explicit_amount_to_repay_on_behalf">get_eno_explicit_amount_to_repay_on_behalf</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_outstanding_variable_debt"></a>

## Function `get_eno_outstanding_variable_debt`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eno_outstanding_variable_debt">get_eno_outstanding_variable_debt</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_balance_zero"></a>

## Function `get_eunderlying_balance_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_balance_zero">get_eunderlying_balance_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einterest_rate_rebalance_conditions_not_met"></a>

## Function `get_einterest_rate_rebalance_conditions_not_met`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einterest_rate_rebalance_conditions_not_met">get_einterest_rate_rebalance_conditions_not_met</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ehealth_factor_not_below_threshold"></a>

## Function `get_ehealth_factor_not_below_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ehealth_factor_not_below_threshold">get_ehealth_factor_not_below_threshold</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_cannot_be_liquidated"></a>

## Function `get_ecollateral_cannot_be_liquidated`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ecollateral_cannot_be_liquidated">get_ecollateral_cannot_be_liquidated</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_especified_currency_not_borrowed_by_user"></a>

## Function `get_especified_currency_not_borrowed_by_user`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_especified_currency_not_borrowed_by_user">get_especified_currency_not_borrowed_by_user</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_flashloan_params"></a>

## Function `get_einconsistent_flashloan_params`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_flashloan_params">get_einconsistent_flashloan_params</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eborrow_cap_exceeded"></a>

## Function `get_eborrow_cap_exceeded`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eborrow_cap_exceeded">get_eborrow_cap_exceeded</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esupply_cap_exceeded"></a>

## Function `get_esupply_cap_exceeded`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esupply_cap_exceeded">get_esupply_cap_exceeded</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunbacked_mint_cap_exceeded"></a>

## Function `get_eunbacked_mint_cap_exceeded`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunbacked_mint_cap_exceeded">get_eunbacked_mint_cap_exceeded</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_edebt_ceiling_exceeded"></a>

## Function `get_edebt_ceiling_exceeded`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_edebt_ceiling_exceeded">get_edebt_ceiling_exceeded</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_claimable_rights_not_zero"></a>

## Function `get_eunderlying_claimable_rights_not_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_claimable_rights_not_zero">get_eunderlying_claimable_rights_not_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_evariable_debt_supply_not_zero"></a>

## Function `get_evariable_debt_supply_not_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_evariable_debt_supply_not_zero">get_evariable_debt_supply_not_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eltv_validation_failed"></a>

## Function `get_eltv_validation_failed`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eltv_validation_failed">get_eltv_validation_failed</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_emode_category"></a>

## Function `get_einconsistent_emode_category`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_emode_category">get_einconsistent_emode_category</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eprice_oracle_sentinel_check_failed"></a>

## Function `get_eprice_oracle_sentinel_check_failed`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eprice_oracle_sentinel_check_failed">get_eprice_oracle_sentinel_check_failed</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_easset_not_borrowable_in_isolation"></a>

## Function `get_easset_not_borrowable_in_isolation`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_easset_not_borrowable_in_isolation">get_easset_not_borrowable_in_isolation</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_already_initialized"></a>

## Function `get_ereserve_already_initialized`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_already_initialized">get_ereserve_already_initialized</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_euser_in_isolation_mode_or_ltv_zero"></a>

## Function `get_euser_in_isolation_mode_or_ltv_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_euser_in_isolation_mode_or_ltv_zero">get_euser_in_isolation_mode_or_ltv_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_ltv"></a>

## Function `get_einvalid_ltv`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_ltv">get_einvalid_ltv</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liq_threshold"></a>

## Function `get_einvalid_liq_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liq_threshold">get_einvalid_liq_threshold</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liq_bonus"></a>

## Function `get_einvalid_liq_bonus`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liq_bonus">get_einvalid_liq_bonus</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_decimals"></a>

## Function `get_einvalid_decimals`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_decimals">get_einvalid_decimals</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_factor"></a>

## Function `get_einvalid_reserve_factor`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_factor">get_einvalid_reserve_factor</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_borrow_cap"></a>

## Function `get_einvalid_borrow_cap`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_borrow_cap">get_einvalid_borrow_cap</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_supply_cap"></a>

## Function `get_einvalid_supply_cap`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_supply_cap">get_einvalid_supply_cap</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liquidation_protocol_fee"></a>

## Function `get_einvalid_liquidation_protocol_fee`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_liquidation_protocol_fee">get_einvalid_liquidation_protocol_fee</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category"></a>

## Function `get_einvalid_emode_category`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_emode_category">get_einvalid_emode_category</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_unbacked_mint_cap"></a>

## Function `get_einvalid_unbacked_mint_cap`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_unbacked_mint_cap">get_einvalid_unbacked_mint_cap</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_debt_ceiling"></a>

## Function `get_einvalid_debt_ceiling`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_debt_ceiling">get_einvalid_debt_ceiling</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_index"></a>

## Function `get_einvalid_reserve_index`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_reserve_index">get_einvalid_reserve_index</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eacl_admin_cannot_be_zero"></a>

## Function `get_eacl_admin_cannot_be_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eacl_admin_cannot_be_zero">get_eacl_admin_cannot_be_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_params_length"></a>

## Function `get_einconsistent_params_length`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einconsistent_params_length">get_einconsistent_params_length</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ezero_address_not_valid"></a>

## Function `get_ezero_address_not_valid`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ezero_address_not_valid">get_ezero_address_not_valid</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_expiration"></a>

## Function `get_einvalid_expiration`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_expiration">get_einvalid_expiration</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_signature"></a>

## Function `get_einvalid_signature`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_signature">get_einvalid_signature</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eoperation_not_supported"></a>

## Function `get_eoperation_not_supported`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eoperation_not_supported">get_eoperation_not_supported</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_edebt_ceiling_not_zero"></a>

## Function `get_edebt_ceiling_not_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_edebt_ceiling_not_zero">get_edebt_ceiling_not_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_easset_not_listed"></a>

## Function `get_easset_not_listed`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_easset_not_listed">get_easset_not_listed</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_optimal_usage_ratio"></a>

## Function `get_einvalid_optimal_usage_ratio`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_einvalid_optimal_usage_ratio">get_einvalid_optimal_usage_ratio</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_cannot_be_rescued"></a>

## Function `get_eunderlying_cannot_be_rescued`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eunderlying_cannot_be_rescued">get_eunderlying_cannot_be_rescued</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaddresses_provider_already_added"></a>

## Function `get_eaddresses_provider_already_added`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaddresses_provider_already_added">get_eaddresses_provider_already_added</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_epool_addresses_do_not_match"></a>

## Function `get_epool_addresses_do_not_match`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_epool_addresses_do_not_match">get_epool_addresses_do_not_match</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esiloed_borrowing_violation"></a>

## Function `get_esiloed_borrowing_violation`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esiloed_borrowing_violation">get_esiloed_borrowing_violation</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_debt_not_zero"></a>

## Function `get_ereserve_debt_not_zero`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_ereserve_debt_not_zero">get_ereserve_debt_not_zero</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eflashloan_disabled"></a>

## Function `get_eflashloan_disabled`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eflashloan_disabled">get_eflashloan_disabled</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_euser_not_listed"></a>

## Function `get_euser_not_listed`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_euser_not_listed">get_euser_not_listed</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esigner_and_on_behalf_of_no_same"></a>

## Function `get_esigner_and_on_behalf_of_no_same`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_esigner_and_on_behalf_of_no_same">get_esigner_and_on_behalf_of_no_same</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaccount_does_not_exist"></a>

## Function `get_eaccount_does_not_exist`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_eaccount_does_not_exist">get_eaccount_does_not_exist</a>(): u64
</code></pre>



<a id="0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_flashloan_payer_not_receiver"></a>

## Function `get_flashloan_payer_not_receiver`



<pre><code><b>public</b> <b>fun</b> <a href="error_config.md#0xe984b3b024d14e7aac51fb0aec8d0fbfbc23a230fe3bd8a87f575d243bc0cedd_error_get_flashloan_payer_not_receiver">get_flashloan_payer_not_receiver</a>(): u64
</code></pre>
