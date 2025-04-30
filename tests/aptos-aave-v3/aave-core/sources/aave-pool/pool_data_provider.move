module aave_pool::pool_data_provider {
    use std::string::String;
    use std::vector;

    use aave_config::reserve_config;
    use aave_config::user_config;

    use aave_pool::a_token_factory;
    use aave_pool::fungible_asset_manager;
    use aave_pool::pool;
    use aave_pool::variable_debt_token_factory;

    struct TokenData has drop {
        symbol: String,
        token_address: address
    }

    #[test_only]
    public fun get_reserve_token_symbol(token_data: &TokenData): String {
        token_data.symbol
    }

    #[test_only]
    public fun get_reserve_token_address(token_data: &TokenData): address {
        token_data.token_address
    }

    #[view]
    /// @notice Returns the list of the existing reserves in the pool.
    /// @return The list of reserves, pairs of symbols and addresses
    public fun get_all_reserves_tokens(): vector<TokenData> {
        let reserves = pool::get_reserves_list();
        let reserves_tokens = vector::empty<TokenData>();

        for (i in 0..vector::length(&reserves)) {
            let reserve_address = *vector::borrow(&reserves, i);

            vector::push_back<TokenData>(
                &mut reserves_tokens,
                TokenData {
                    symbol: fungible_asset_manager::symbol(reserve_address),
                    token_address: reserve_address
                }
            );
        };

        reserves_tokens
    }

    #[view]
    /// @notice Returns the list of the existing ATokens in the pool.
    /// @return The list of ATokens, pairs of symbols and addresses
    public fun get_all_a_tokens(): vector<TokenData> {
        let reserves = pool::get_reserves_list();
        let a_tokens = vector::empty<TokenData>();

        for (i in 0..vector::length(&reserves)) {
            let reserve_address = *vector::borrow(&reserves, i);
            let reserve_data = pool::get_reserve_data(reserve_address);
            let a_token_address = pool::get_reserve_a_token_address(&reserve_data);

            vector::push_back<TokenData>(
                &mut a_tokens,
                TokenData {
                    symbol: a_token_factory::symbol(a_token_address),
                    token_address: a_token_address
                }
            );
        };

        a_tokens
    }

    #[view]
    /// @notice Returns the list of the existing variable debt Tokens in the pool.
    /// @return The list of variableDebtTokens, pairs of symbols and addresses
    public fun get_all_var_tokens(): vector<TokenData> {
        let reserves = pool::get_reserves_list();
        let var_tokens = vector::empty<TokenData>();

        for (i in 0..vector::length(&reserves)) {
            let reserve_address = *vector::borrow(&reserves, i);
            let reserve_data = pool::get_reserve_data(reserve_address);
            let var_token_address =
                pool::get_reserve_variable_debt_token_address(&reserve_data);

            vector::push_back<TokenData>(
                &mut var_tokens,
                TokenData {
                    symbol: variable_debt_token_factory::symbol(var_token_address),
                    token_address: var_token_address
                }
            );
        };

        var_tokens
    }

    #[view]
    /// @notice Returns the configuration data of the reserve
    /// @dev Not returning borrow and supply caps for compatibility, nor pause flag
    /// @param asset The address of the underlying asset of the reserve
    /// @return decimals The number of decimals of the reserve
    /// @return ltv The ltv of the reserve
    /// @return liquidation_threshold The liquidationThreshold of the reserve
    /// @return liquidation_bonus The liquidationBonus of the reserve
    /// @return reserve_factor The reserveFactor of the reserve
    /// @return usage_as_collateral_enabled True if the usage as collateral is enabled, false otherwise
    /// @return borrowing_enabled True if borrowing is enabled, false otherwise
    /// @return is_active True if it is active, false otherwise
    /// @return is_frozen True if it is frozen, false otherwise
    public fun get_reserve_configuration_data(
        asset: address
    ): (u256, u256, u256, u256, u256, bool, bool, bool, bool) {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        let (ltv, liquidation_threshold, liquidation_bonus, decimals, reserve_factor, _) =
            reserve_config::get_params(&reserve_configuration);

        let (is_active, is_frozen, borrowing_enabled, _) =
            reserve_config::get_flags(&reserve_configuration);

        let usage_as_collateral_enabled = liquidation_threshold != 0;

        (
            decimals,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            reserve_factor,
            usage_as_collateral_enabled,
            borrowing_enabled,
            is_active,
            is_frozen
        )
    }

    #[view]
    /// @notice Returns the efficiency mode category of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The eMode id of the reserve
    public fun get_reserve_emode_category(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        reserve_config::get_emode_category(&reserve_configuration)
    }

    #[view]
    /// @notice Returns the caps parameters of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return borrow_cap The borrow cap of the reserve
    /// @return supply_cap The supply cap of the reserve
    public fun get_reserve_caps(asset: address): (u256, u256) {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_caps(&reserve_configuration)
    }

    #[view]
    /// @notice Returns if the pool is paused
    /// @param asset The address of the underlying asset of the reserve
    /// @return isPaused True if the pool is paused, false otherwise
    public fun get_paused(asset: address): bool {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        reserve_config::get_paused(&reserve_configuration)
    }

    #[view]
    /// @notice Returns the siloed borrowing flag
    /// @param asset The address of the underlying asset of the reserve
    /// @return True if the asset is siloed for borrowing
    public fun get_siloed_borrowing(asset: address): bool {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        reserve_config::get_siloed_borrowing(&reserve_configuration)
    }

    #[view]
    /// @notice Returns the protocol fee on the liquidation bonus
    /// @param asset The address of the underlying asset of the reserve
    /// @return The protocol fee on liquidation
    public fun get_liquidation_protocol_fee(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        reserve_config::get_liquidation_protocol_fee(&reserve_configuration)
    }

    #[view]
    /// @notice Returns the unbacked mint cap of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The unbacked mint cap of the reserve
    public fun get_unbacked_mint_cap(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        reserve_config::get_unbacked_mint_cap(&reserve_configuration)
    }

    #[view]
    /// @notice Returns the debt ceiling of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The debt ceiling of the reserve
    public fun get_debt_ceiling(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        reserve_config::get_debt_ceiling(&reserve_configuration)
    }

    #[view]
    /// @notice Returns the debt ceiling decimals
    /// @return The debt ceiling decimals
    public fun get_debt_ceiling_decimals(): u256 {
        reserve_config::get_debt_ceiling_decimals()
    }

    #[view]
    /// @notice Returns the reserve data
    /// @param asset The address of the underlying asset of the reserve
    /// @return unbacked The amount of unbacked tokens
    /// @return accrued_to_treasury_scaled The scaled amount of tokens accrued to treasury that is to be minted
    /// @return total_a_token The total supply of the aToken
    /// @return total_variable_debt The total variable debt of the reserve
    /// @return liquidity_rate The liquidity rate of the reserve
    /// @return variable_borrow_rate The variable borrow rate of the reserve
    /// @return liquidity_index The liquidity index of the reserve
    /// @return variable_borrow_index The variable borrow index of the reserve
    /// @return last_update_timestamp The timestamp of the last update of the reserve
    public fun get_reserve_data(asset: address):
        (
        u256, u256, u256, u256, u256, u256, u256, u256, u64
    ) {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        let variable_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);

        (
            (pool::get_reserve_unbacked(&reserve_data) as u256),
            pool::get_reserve_accrued_to_treasury(&reserve_data),
            pool::a_token_total_supply(a_token_address),
            pool::variable_debt_token_total_supply(variable_token_address),
            (pool::get_reserve_current_liquidity_rate(&reserve_data) as u256),
            (pool::get_reserve_current_variable_borrow_rate(&reserve_data) as u256),
            (pool::get_reserve_liquidity_index(&reserve_data) as u256),
            (pool::get_reserve_variable_borrow_index(&reserve_data) as u256),
            pool::get_reserve_last_update_timestamp(&reserve_data)
        )
    }

    #[view]
    /// @notice Returns the total supply of aTokens for a given asset
    /// @param asset The address of the underlying asset of the reserve
    /// @return The total supply of the aToken
    public fun get_a_token_total_supply(asset: address): u256 {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);

        pool::a_token_total_supply(a_token_address)
    }

    #[view]
    /// @notice Returns the total debt for a given asset
    /// @param asset The address of the underlying asset of the reserve
    /// @return The total debt for asset
    public fun get_total_debt(asset: address): u256 {
        let reserve_data = pool::get_reserve_data(asset);
        let variable_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);

        pool::variable_debt_token_total_supply(variable_token_address)
    }

    #[view]
    /// @notice Returns the user data in a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param user The address of the user
    /// @return current_a_token_balance The current AToken balance of the user
    /// @return current_variable_debt The current variable debt of the user
    /// @return scaled_variable_debt The scaled variable debt of the user
    /// @return liquidity_rate The liquidity rate of the reserve
    /// @return usage_as_collateral_enabled True if the user is using the asset as collateral, false otherwise
    public fun get_user_reserve_data(asset: address, user: address):
        (u256, u256, u256, u256, bool) {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        let variable_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);

        let current_a_token_balance = pool::a_token_balance_of(user, a_token_address);
        let current_variable_debt =
            pool::variable_debt_token_balance_of(user, variable_token_address);
        let scaled_variable_debt =
            variable_debt_token_factory::scaled_balance_of(user, variable_token_address);
        let liquidity_rate =
            (pool::get_reserve_current_liquidity_rate(&reserve_data) as u256);

        let user_configuration = pool::get_user_configuration(user);
        let usage_as_collateral_enabled =
            user_config::is_using_as_collateral(
                &user_configuration,
                (pool::get_reserve_id(&reserve_data) as u256)
            );

        (
            current_a_token_balance,
            current_variable_debt,
            scaled_variable_debt,
            liquidity_rate,
            usage_as_collateral_enabled
        )
    }

    #[view]
    /// @notice Returns the token addresses of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return a_token_address The AToken address of the reserve
    /// @return variable_debt_token_address The VariableDebtToken address of the reserve
    public fun get_reserve_tokens_addresses(asset: address): (address, address) {
        let reserve_data = pool::get_reserve_data(asset);

        (
            pool::get_reserve_a_token_address(&reserve_data),
            pool::get_reserve_variable_debt_token_address(&reserve_data)
        )
    }

    #[view]
    /// @notice Returns whether the reserve has FlashLoans enabled or disabled
    /// @param asset The address of the underlying asset of the reserve
    /// @return True if FlashLoans are enabled, false otherwise
    public fun get_flash_loan_enabled(asset: address): bool {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        reserve_config::get_flash_loan_enabled(&reserve_configuration)
    }
}
