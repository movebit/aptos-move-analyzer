/// @title default_reserve_interest_rate_strategy module
/// @author Aave
/// @notice Implements the calculation of the interest rates depending on the reserve state
/// @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_USAGE_RATIO`
/// point of usage and another from that one to 100%.
module aave_rate::default_reserve_interest_rate_strategy {
    use std::signer;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::event;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math::{Self, wad_to_ray};
    friend aave_rate::interest_rate_strategy;

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

    struct DefaultReserveInterestRateStrategy has key, store, copy, drop {
        optimal_usage_ratio: u256,
        max_excess_usage_ratio: u256,
        // Base variable borrow rate when usage rate = 0. Expressed in ray
        base_variable_borrow_rate: u256,
        // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
        variable_rate_slope1: u256,
        // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
        variable_rate_slope2: u256
    }

    // List of reserves as a map (underlying_asset => DefaultReserveInterestRateStrategy)
    struct ReserveInterestRateStrategyMap has key {
        value: SmartTable<address, DefaultReserveInterestRateStrategy>
    }

    struct CalcInterestRatesLocalVars has drop {
        available_liquidity: u256,
        total_debt: u256,
        current_variable_borrow_rate: u256,
        current_liquidity_rate: u256,
        borrow_usage_ratio: u256,
        supply_usage_ratio: u256,
        available_liquidity_plus_debt: u256
    }

    /// @notice Initializes the interest rate strategy
    /// @dev Only callable by the interest_rate_strategy module
    /// @param account The signer account of the caller
    public fun init_interest_rate_strategy(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_rate,
            error_config::get_enot_rate_owner()
        );

        move_to(
            account,
            ReserveInterestRateStrategyMap {
                value: smart_table::new<address, DefaultReserveInterestRateStrategy>()
            }
        );
    }

    /// @notice Sets the interest rate strategy of a reserve
    /// @param account The signer account of the caller
    /// @param asset The address of the reserve
    /// @param optimal_usage_ratio The optimal usage ratio
    /// @param base_variable_borrow_rate The base variable borrow rate
    /// @param variable_rate_slope1 The variable rate slope below optimal usage ratio
    /// @param variable_rate_slope2 The variable rate slope above optimal usage ratio
    public entry fun set_reserve_interest_rate_strategy(
        account: &signer,
        asset: address,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    ) acquires ReserveInterestRateStrategyMap {
        let account_address = signer::address_of(account);
        assert!(
            only_risk_or_pool_admins(account_address),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
        assert!(
            wad_ray_math::ray() >= optimal_usage_ratio,
            error_config::get_einvalid_optimal_usage_ratio()
        );

        let max_excess_usage_ratio = wad_ray_math::ray() - optimal_usage_ratio;
        let reserve_interest_rate_strategy = DefaultReserveInterestRateStrategy {
            optimal_usage_ratio,
            max_excess_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        };

        let rate_strategy = borrow_global_mut<ReserveInterestRateStrategyMap>(@aave_rate);
        smart_table::upsert(
            &mut rate_strategy.value, asset, reserve_interest_rate_strategy
        );

        event::emit(
            ReserveInterestRateStrategy {
                asset,
                optimal_usage_ratio,
                max_excess_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
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
    ): DefaultReserveInterestRateStrategy acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_rate);
        if (!smart_table::contains(&rate_strategy_map.value, asset)) {
            // If rate do not exist, return zero as default values, to be 1:1 with Solidity
            return DefaultReserveInterestRateStrategy {
                optimal_usage_ratio: 0,
                max_excess_usage_ratio: 0,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 0,
                variable_rate_slope2: 0
            }
        };

        *smart_table::borrow(&rate_strategy_map.value, asset)
    }

    #[view]
    public fun get_optimal_usage_ratio(asset: address): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(asset).optimal_usage_ratio
    }

    #[view]
    public fun get_max_excess_usage_ratio(
        asset: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(asset).max_excess_usage_ratio
    }

    #[view]
    public fun get_variable_rate_slope1(
        asset: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(asset).variable_rate_slope1
    }

    #[view]
    public fun get_variable_rate_slope2(
        asset: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(asset).variable_rate_slope2
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
        let rate_data = get_reserve_interest_rate_strategy(asset);

        rate_data.base_variable_borrow_rate + rate_data.variable_rate_slope1
            + rate_data.variable_rate_slope2
    }

    #[view]
    /// @notice Calculates the interest rates depending on the reserve's state and configurations
    /// @param unbacked The amount of unbacked liquidity
    /// @param liquidity_added The amount of liquidity added
    /// @param liquidity_taken The amount of liquidity taken
    /// @param total_variable_debt The total variable debt of the reserve
    /// @param reserve_factor The reserve factor
    /// @param reserve The address of the reserve
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
        a_token_underlying_balance: u256
    ): (u256, u256) acquires ReserveInterestRateStrategyMap {
        let rate_data = get_reserve_interest_rate_strategy(reserve);
        let vars = create_calc_interest_rates_local_vars();
        vars.total_debt = total_variable_debt;
        vars.current_liquidity_rate = 0;
        vars.current_variable_borrow_rate = rate_data.base_variable_borrow_rate;
        if (vars.total_debt != 0) {
            vars.available_liquidity = a_token_underlying_balance + liquidity_added
                - liquidity_taken;
            vars.available_liquidity_plus_debt = vars.available_liquidity
                + vars.total_debt;
            vars.borrow_usage_ratio = wad_ray_math::ray_div(
                vars.total_debt, vars.available_liquidity_plus_debt
            );
            vars.supply_usage_ratio = wad_ray_math::ray_div(
                vars.total_debt,
                (vars.available_liquidity_plus_debt + unbacked)
            );
        };

        if (vars.borrow_usage_ratio > rate_data.optimal_usage_ratio) {
            let excess_borrow_usage_ratio =
                wad_ray_math::ray_div(
                    (vars.borrow_usage_ratio - rate_data.optimal_usage_ratio),
                    rate_data.max_excess_usage_ratio
                );

            vars.current_variable_borrow_rate = vars.current_variable_borrow_rate
                + rate_data.variable_rate_slope1
                + wad_ray_math::ray_mul(
                    rate_data.variable_rate_slope2,
                    excess_borrow_usage_ratio
                );
        } else {
            vars.current_variable_borrow_rate = vars.current_variable_borrow_rate
                + wad_ray_math::ray_div(
                    wad_ray_math::ray_mul(
                        rate_data.variable_rate_slope1, vars.borrow_usage_ratio
                    ),
                    rate_data.optimal_usage_ratio
                );
        };

        vars.current_liquidity_rate = math_utils::percent_mul(
            wad_ray_math::ray_mul(
                get_overall_borrow_rate(
                    total_variable_debt, vars.current_variable_borrow_rate
                ),
                vars.supply_usage_ratio
            ),
            (math_utils::get_percentage_factor() - reserve_factor)
        );

        return (vars.current_liquidity_rate, vars.current_variable_borrow_rate)
    }

    fun create_calc_interest_rates_local_vars(): CalcInterestRatesLocalVars {
        CalcInterestRatesLocalVars {
            available_liquidity: 0,
            total_debt: 0,
            current_variable_borrow_rate: 0,
            current_liquidity_rate: 0,
            borrow_usage_ratio: 0,
            supply_usage_ratio: 0,
            available_liquidity_plus_debt: 0
        }
    }

    /// @dev Calculates the overall borrow rate as the weighted average between the total variable debt
    /// @param total_variable_debt The total borrowed from the reserve at a variable rate
    /// @param current_variable_borrow_rate The current variable borrow rate of the reserve
    /// @return The weighted averaged borrow rate
    fun get_overall_borrow_rate(
        total_variable_debt: u256, current_variable_borrow_rate: u256
    ): u256 {
        let totalDebt = total_variable_debt;
        if (totalDebt == 0) return 0;

        let weighted_variable_rate =
            wad_ray_math::ray_mul(
                wad_to_ray(total_variable_debt),
                current_variable_borrow_rate
            );

        let overall_borrow_rate =
            wad_ray_math::ray_div((weighted_variable_rate), wad_to_ray(totalDebt));

        overall_borrow_rate
    }

    fun only_risk_or_pool_admins(account: address): bool {
        acl_manage::is_risk_admin(account) || acl_manage::is_pool_admin(account)
    }
}
