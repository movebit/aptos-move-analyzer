/// @title gho_interest_rate_strategy module
/// @author Aave
/// @notice Implements the calculation of GHO interest rates, which defines a fixed variable borrow rate.
/// @dev The variable borrow interest rate is fixed at deployment time. The rest of parameters are zeroed.
module aave_rate::gho_interest_rate_strategy {
    use std::signer;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::event;

    use aave_acl::acl_manage;
    use aave_config::error_config;

    /// the usage ratio at which the pool aims to obtain most competitive borrow rates.
    const OPTIMAL_USAGE_RATIO: u256 = 0;

    /// the excess usage ratio above the optimal.
    const MAX_EXCESS_USAGE_RATIO: u256 = 0;

    #[event]
    struct ReserveInterestRateStrategy has store, drop {
        asset: address,
        optimal_usage_ratio: u256,
        max_excess_usage_ratio: u256,
        // Base variable borrow rate when usage rate = 0. Expressed in ray
        base_variable_borrow_rate: u256,
        // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
        variable_rate_slope1: u256,
        // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
        variable_rate_slope2: u256
    }

    struct GHOReserveInterestRateStrategy has key, store, copy, drop {
        // Base variable borrow rate when usage rate = 0. Expressed in ray
        base_variable_borrow_rate: u256
    }

    // List of reserves as a map (underlying_asset => GHOReserveInterestRateStrategy)
    struct ReserveInterestRateStrategyMap has key {
        value: SmartTable<address, GHOReserveInterestRateStrategy>
    }

    /// @notice Initializes the interest rate strategy
    /// @dev Only callable by the interest_rate_strategy module
    /// @param account The account signer of the caller
    public fun init_interest_rate_strategy(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_rate,
            error_config::get_enot_rate_owner()
        );

        move_to(
            account,
            ReserveInterestRateStrategyMap {
                value: smart_table::new<address, GHOReserveInterestRateStrategy>()
            }
        );
    }

    /// @notice Sets the interest rate strategy of a reserve
    /// @param account The account signer of the caller
    /// @param asset The address of the reserve
    /// @param base_variable_borrow_rate The base variable borrow rate
    public entry fun set_reserve_interest_rate_strategy(
        account: &signer, asset: address, base_variable_borrow_rate: u256
    ) acquires ReserveInterestRateStrategyMap {
        let account_address = signer::address_of(account);
        assert!(
            only_risk_or_pool_admins(account_address),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        let reserve_interest_rate_strategy = GHOReserveInterestRateStrategy {
            base_variable_borrow_rate
        };

        let rate_strategy = borrow_global_mut<ReserveInterestRateStrategyMap>(@aave_rate);
        smart_table::upsert(
            &mut rate_strategy.value, asset, reserve_interest_rate_strategy
        );

        event::emit(
            ReserveInterestRateStrategy {
                asset,
                optimal_usage_ratio: OPTIMAL_USAGE_RATIO,
                max_excess_usage_ratio: MAX_EXCESS_USAGE_RATIO,
                base_variable_borrow_rate,
                variable_rate_slope1: 0,
                variable_rate_slope2: 0
            }
        )
    }

    public fun asset_interest_rate_exists(asset: address) acquires ReserveInterestRateStrategyMap {
        let rate_strategy = borrow_global<ReserveInterestRateStrategyMap>(@aave_rate);
        assert!(
            smart_table::contains(&rate_strategy.value, asset),
            error_config::get_easset_not_listed()
        );
    }

    #[view]
    public fun get_reserve_interest_rate_strategy(
        asset: address
    ): GHOReserveInterestRateStrategy acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_rate);
        if (!smart_table::contains(&rate_strategy_map.value, asset)) {
            // If rate do not exist, return zero as default values, to be 1:1 with Solidity
            return GHOReserveInterestRateStrategy { base_variable_borrow_rate: 0 }
        };
        *smart_table::borrow(&rate_strategy_map.value, asset)
    }

    #[view]
    public fun get_optimal_usage_ratio(_asset: address): u256 {
        OPTIMAL_USAGE_RATIO
    }

    #[view]
    public fun get_max_excess_usage_ratio(_asset: address): u256 {
        MAX_EXCESS_USAGE_RATIO
    }

    #[view]
    public fun get_variable_rate_slope1(_asset: address): u256 {
        0
    }

    #[view]
    public fun get_variable_rate_slope2(_asset: address): u256 {
        0
    }

    #[view]
    public fun get_base_variable_borrow_rate(
        asset: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(asset).base_variable_borrow_rate
    }

    #[view]
    public fun get_max_variable_borrow_rate(
        asset: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_base_variable_borrow_rate(asset)
    }

    #[view]
    /// @notice Calculates the interest rates depending on the reserve's state and configurations
    /// @param _unbacked The amount of unbacked liquidity
    /// @param _liquidity_added The amount of liquidity added
    /// @param _liquidity_taken The amount of liquidity taken
    /// @param _total_variable_debt The total variable debt of the reserve
    /// @param _reserve_factor The reserve factor
    /// @param reserve The address of the reserve
    /// @param _a_token_underlying_balance The underlying token balance corresponding to the aToken
    /// @return current_liquidity_rate The liquidity rate expressed in rays
    /// @return current_variable_borrow_rate The variable borrow rate expressed in rays
    public fun calculate_interest_rates(
        _unbacked: u256,
        _liquidity_added: u256,
        _liquidity_taken: u256,
        _total_variable_debt: u256,
        _reserve_factor: u256,
        reserve: address,
        _a_token_underlying_balance: u256
    ): (u256, u256) acquires ReserveInterestRateStrategyMap {
        (0, get_base_variable_borrow_rate(reserve))
    }

    fun only_risk_or_pool_admins(account: address): bool {
        acl_manage::is_risk_admin(account) || acl_manage::is_pool_admin(account)
    }
}
