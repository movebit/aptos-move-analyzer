/// @title interest_rate_strategy module
/// @author Aave
/// This module provides unified methods for managing asset interest rate strategies
/// offering two main functions:
/// 1. asset_interest_rate_exists to check if an interest rate strategy exists for a given asset
/// 2. calculate_interest_rates to compute the interest rates.
module aave_rate::interest_rate_strategy {
    use std::signer;
    use std::string::{String, utf8};

    use aave_config::error_config;

    use aave_rate::default_reserve_interest_rate_strategy;
    use aave_rate::gho_interest_rate_strategy;

    fun init_module(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_rate,
            error_config::get_enot_rate_owner()
        );
        default_reserve_interest_rate_strategy::init_interest_rate_strategy(account);
        gho_interest_rate_strategy::init_interest_rate_strategy(account);
    }

    #[test_only]
    public fun test_init_module(account: &signer) {
        init_module(account)
    }

    /// @notice Checks if an interest rate strategy exists for a given asset
    /// @param asset The address of the underlying asset
    /// @param reserve_symbol The symbol of the reserve
    /// @return true if the interest rate strategy exists, false otherwise
    public fun asset_interest_rate_exists(
        asset: address, reserve_symbol: String
    ) {
        if (reserve_symbol == utf8(b"GHO")) {
            gho_interest_rate_strategy::asset_interest_rate_exists(asset)
        } else {
            default_reserve_interest_rate_strategy::asset_interest_rate_exists(asset)
        }
    }

    /// @notice Calculates the interest rates depending on the reserve's state and configurations
    /// @param unbacked The amount of unbacked liquidity
    /// @param liquidity_added The amount of liquidity added
    /// @param liquidity_taken The amount of liquidity taken
    /// @param total_variable_debt The total variable debt of the reserve
    /// @param reserve_factor The reserve factor
    /// @param reserve The address of the reserve
    /// @param reserve_symbol The symbol of the reserve
    /// @param a_token_underlying_balance The underlying token balance corresponding to the aToken
    /// @return current_liquidity_rate The liquidity rate expressed in rays
    /// @return current_variable_borrow_rate The variable borrow rate expressed in rays
    public fun calculate_interest_rates(
        unbacked: u256,
        liquidity_added: u256,
        liquidity_taken: u256,
        total_variable_debt: u256,
        reserve_factor: u256,
        reserve: address,
        reserve_symbol: String,
        a_token_underlying_balance: u256
    ): (u256, u256) {
        let next_liquidity_rate: u256;
        let next_variable_rate: u256;

        if (reserve_symbol == utf8(b"GHO")) {
            (next_liquidity_rate, next_variable_rate) = gho_interest_rate_strategy::calculate_interest_rates(
                unbacked,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_factor,
                reserve,
                a_token_underlying_balance
            )
        } else {
            (next_liquidity_rate, next_variable_rate) = default_reserve_interest_rate_strategy::calculate_interest_rates(
                unbacked,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_factor,
                reserve,
                a_token_underlying_balance
            )
        };

        (next_liquidity_rate, next_variable_rate)
    }
}
