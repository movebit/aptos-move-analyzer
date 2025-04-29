/// @title liquidation_logic module
/// @author Aave
/// @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
module aave_pool::liquidation_logic {
    use std::signer;
    use aptos_framework::event;

    use aave_config::reserve_config;
    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_oracle::oracle;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::fungible_asset_manager;
    use aave_pool::generic_logic;
    use aave_pool::isolation_mode_logic;
    use aave_pool::pool::{Self, ReserveCache, ReserveData};
    use aave_pool::validation_logic;
    use aave_pool::variable_debt_token_factory;

    #[event]
    /// @dev Emitted on liquidate_a_tokens()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address of the user enabling the usage as collateral
    struct ReserveUsedAsCollateralEnabled has store, drop {
        reserve: address,
        user: address
    }

    #[event]
    /// @dev Emitted on liquidation_call()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address of the user disabling the usage as collateral
    struct ReserveUsedAsCollateralDisabled has store, drop {
        reserve: address,
        user: address
    }

    #[event]
    /// @dev Emitted when a borrower is liquidated.
    /// @param collateral_asset The address of the underlying asset used as collateral, to receive as result of the liquidation
    /// @param debt_asset The address of the underlying borrowed asset to be repaid with the liquidation
    /// @param user The address of the borrower getting liquidated
    /// @param debt_to_cover The debt amount of borrowed `asset` the liquidator wants to cover
    /// @param liquidated_collateral_amount The amount of collateral received by the liquidator
    /// @param liquidator The address of the liquidator
    /// @param receive_a_token True if the liquidators wants to receive the collateral aTokens, `false` if he wants
    /// to receive the underlying collateral asset directly
    struct LiquidationCall has store, drop {
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        liquidated_collateral_amount: u256,
        liquidator: address,
        receive_a_token: bool
    }

    /// @dev Default percentage of borrower's debt to be repaid in a liquidation.
    /// @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
    /// Expressed in bps, a value of 0.5e4 results in 50.00%
    /// 5 * 10 ** 3
    const DEFAULT_LIQUIDATION_CLOSE_FACTOR: u256 = 5000;

    /// @dev Maximum percentage of borrower's debt to be repaid in a liquidation
    /// @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
    /// Expressed in bps, a value of 1e4 results in 100.00%
    /// 1 * 10 ** 4
    const MAX_LIQUIDATION_CLOSE_FACTOR: u256 = 10000;

    /// @dev This constant represents below which health factor value it is possible to liquidate
    /// an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
    /// A value of 0.95e18 results in 0.95
    /// 0.95 * 10 ** 18
    const CLOSE_FACTOR_HF_THRESHOLD: u256 = 950000000000000000;

    struct LiquidationCallLocalVars has drop {
        user_collateral_balance: u256,
        user_variable_debt: u256,
        user_total_debt: u256,
        actual_debt_to_liquidate: u256,
        actual_collateral_to_liquidate: u256,
        liquidation_bonus: u256,
        health_factor: u256,
        liquidation_protocol_fee_amount: u256,
        collateral_price_source: address,
        debt_price_source: address,
        collateral_a_token: address
    }

    fun create_liquidation_call_local_vars(): LiquidationCallLocalVars {
        LiquidationCallLocalVars {
            user_collateral_balance: 0,
            user_variable_debt: 0,
            user_total_debt: 0,
            actual_debt_to_liquidate: 0,
            actual_collateral_to_liquidate: 0,
            liquidation_bonus: 0,
            health_factor: 0,
            liquidation_protocol_fee_amount: 0,
            collateral_price_source: @0x0,
            debt_price_source: @0x0,
            collateral_a_token: @0x0
        }
    }

    struct ExecuteLiquidationCallParams has drop {
        reserves_count: u256,
        debt_to_cover: u256,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        receive_a_token: bool,
        user_emode_category: u8
    }

    fun create_execute_liquidation_call_params(
        reserves_count: u256,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        receive_a_token: bool
    ): ExecuteLiquidationCallParams {
        ExecuteLiquidationCallParams {
            reserves_count,
            debt_to_cover,
            collateral_asset,
            debt_asset,
            user,
            receive_a_token,
            user_emode_category: (emode_logic::get_user_emode(user) as u8)
        }
    }

    /// @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
    /// - The caller (liquidator) covers `debt_to_cover` amount of debt of the user getting liquidated, and receives
    /// a proportionally amount of the `collateral_asset` plus a bonus to cover market risk
    /// @dev Emits the `LiquidationCall()` event
    /// @param account The account signer of the caller
    /// @param collateral_asset The address of the underlying asset used as collateral, to receive as result of the liquidation
    /// @param debt_asset The address of the underlying borrowed asset to be repaid with the liquidation
    /// @param user The address of the borrower getting liquidated
    /// @param debt_to_cover The debt amount of borrowed `asset` the liquidator wants to cover
    /// @param receive_a_token True if the liquidators wants to receive the collateral aTokens, `false` if he wants
    /// to receive the underlying collateral asset directly
    public entry fun liquidation_call(
        account: &signer,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        receive_a_token: bool
    ) {
        let reserves_count = pool::get_reserves_count();
        let account_address = signer::address_of(account);
        let vars = create_liquidation_call_local_vars();
        let params =
            create_execute_liquidation_call_params(
                reserves_count,
                collateral_asset,
                debt_asset,
                user,
                debt_to_cover,
                receive_a_token
            );
        let collateral_reserve = pool::get_reserve_data(params.collateral_asset);
        let debt_reserve = pool::get_reserve_data(params.debt_asset);
        let debt_reserve_cache = pool::cache(&debt_reserve);
        // update debt reserve state
        pool::update_state(debt_asset, &mut debt_reserve, &mut debt_reserve_cache);

        let user_config_map = pool::get_user_configuration(user);
        let (emode_ltv, emode_liq_threshold, emode_asset_price) =
            emode_logic::get_emode_configuration(params.user_emode_category);

        let (_, _, _, _, health_factor, _) =
            generic_logic::calculate_user_account_data(
                &user_config_map,
                params.reserves_count,
                params.user,
                params.user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price
            );
        vars.health_factor = health_factor;

        let (user_variable_debt, user_total_debt, actual_debt_to_liquidate) =
            calculate_debt(&debt_reserve_cache, &params, health_factor);
        vars.user_variable_debt = user_variable_debt;
        vars.user_total_debt = user_total_debt;
        vars.actual_debt_to_liquidate = actual_debt_to_liquidate;

        // validate liquidation call
        validation_logic::validate_liquidation_call(
            &user_config_map,
            &collateral_reserve,
            &debt_reserve_cache,
            vars.user_total_debt,
            vars.health_factor
        );

        // get configuration data
        let (
            collateral_a_token,
            collateral_price_source,
            debt_price_source,
            liquidation_bonus
        ) = get_configuration_data(&collateral_reserve, &params);

        vars.collateral_a_token = collateral_a_token;
        vars.collateral_price_source = collateral_price_source;
        vars.debt_price_source = debt_price_source;
        vars.liquidation_bonus = liquidation_bonus;

        vars.user_collateral_balance = pool::a_token_balance_of(
            params.user, collateral_a_token
        );

        let (
            actual_collateral_to_liquidate,
            actual_debt_to_liquidate,
            liquidation_protocol_fee_amount
        ) =
            calculate_available_collateral_to_liquidate(
                &collateral_reserve,
                &debt_reserve_cache,
                vars.collateral_price_source, // Currently, custom oracle is not supported. Only a unified oracle is used. Therefore, the price is obtained by calling the oracle directly with the collateral_asset.
                vars.debt_price_source, // Currently, custom oracle is not supported. Only a unified oracle is used. Therefore, the price is obtained by calling the oracle directly with the debt_asset.
                vars.actual_debt_to_liquidate,
                vars.user_collateral_balance,
                vars.liquidation_bonus
            );
        vars.actual_collateral_to_liquidate = actual_collateral_to_liquidate;
        vars.actual_debt_to_liquidate = actual_debt_to_liquidate;
        vars.liquidation_protocol_fee_amount = liquidation_protocol_fee_amount;

        if (vars.user_total_debt == vars.actual_debt_to_liquidate) {
            let debt_reserve_id = pool::get_reserve_id(&debt_reserve);
            user_config::set_borrowing(
                &mut user_config_map, (debt_reserve_id as u256), false
            );
            pool::set_user_configuration(params.user, user_config_map);
        };

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.actual_collateral_to_liquidate + vars.liquidation_protocol_fee_amount
            == vars.user_collateral_balance) {
            let collateral_reserve_id = pool::get_reserve_id(&collateral_reserve);
            user_config::set_using_as_collateral(
                &mut user_config_map,
                (collateral_reserve_id as u256),
                false
            );
            pool::set_user_configuration(params.user, user_config_map);
            event::emit(
                ReserveUsedAsCollateralDisabled {
                    reserve: params.collateral_asset,
                    user: params.user
                }
            );
        };

        // burn debt tokens
        burn_debt_tokens(&mut debt_reserve_cache, &params, &vars);

        // update pool interest rates
        pool::update_interest_rates(
            &mut debt_reserve,
            &debt_reserve_cache,
            params.debt_asset,
            vars.actual_debt_to_liquidate,
            0
        );

        isolation_mode_logic::update_isolated_debt_if_isolated(
            &user_config_map,
            &debt_reserve_cache,
            vars.actual_debt_to_liquidate
        );

        let collateral_reserve = pool::get_reserve_data(params.collateral_asset);
        if (params.receive_a_token) {
            liquidate_a_tokens(
                account_address,
                &collateral_reserve,
                &params,
                &vars
            );
        } else {
            burn_collateral_a_tokens(
                account_address,
                &mut collateral_reserve,
                &params,
                &vars
            )
        };

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidation_protocol_fee_amount != 0) {
            let liquidity_index =
                pool::get_normalized_income_by_reserve_data(&collateral_reserve);
            let scaled_down_liquidation_protocol_fee =
                wad_ray_math::ray_div(
                    vars.liquidation_protocol_fee_amount,
                    liquidity_index
                );

            let scaled_down_user_balance =
                a_token_factory::scaled_balance_of(params.user, vars.collateral_a_token);
            // To avoid trying to send more aTokens than available on balance, due to 1 wei imprecision
            if (scaled_down_liquidation_protocol_fee > scaled_down_user_balance) {
                vars.liquidation_protocol_fee_amount = wad_ray_math::ray_mul(
                    scaled_down_user_balance, liquidity_index
                )
            };

            let a_token_treasury =
                a_token_factory::get_reserve_treasury_address(vars.collateral_a_token);
            a_token_factory::transfer_on_liquidation(
                params.user,
                a_token_treasury,
                vars.liquidation_protocol_fee_amount,
                liquidity_index,
                vars.collateral_a_token
            );
        };

        // Transfers the debt asset being repaid to the aToken, where the liquidity is kept
        let a_token_address = pool::get_a_token_address(&debt_reserve_cache);
        fungible_asset_manager::transfer(
            account,
            a_token_factory::get_token_account_address(a_token_address),
            (vars.actual_debt_to_liquidate as u64),
            debt_asset
        );

        a_token_factory::handle_repayment(
            account_address,
            params.user,
            vars.actual_debt_to_liquidate,
            a_token_address
        );

        event::emit(
            LiquidationCall {
                collateral_asset,
                debt_asset,
                user,
                debt_to_cover: vars.actual_debt_to_liquidate,
                liquidated_collateral_amount: vars.actual_collateral_to_liquidate,
                liquidator: account_address,
                receive_a_token
            }
        );
    }

    /// @notice Burns the collateral aTokens and transfers the underlying to the liquidator.
    /// @param account_address The liquidator account address
    /// @param collateral_reserve The data of the collateral reserve
    /// @param params The additional parameters needed to execute the liquidation function
    /// @param vars The liquidation_call() function local vars
    fun burn_collateral_a_tokens(
        account_address: address,
        collateral_reserve: &mut ReserveData,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        let collateral_reserve_cache = pool::cache(collateral_reserve);
        // update pool state
        pool::update_state(
            params.collateral_asset, collateral_reserve, &mut collateral_reserve_cache
        );

        // update pool interest rates
        pool::update_interest_rates(
            collateral_reserve,
            &collateral_reserve_cache,
            params.collateral_asset,
            0,
            vars.actual_collateral_to_liquidate
        );

        // Burn the equivalent amount of aToken, sending the underlying to the liquidator
        a_token_factory::burn(
            params.user,
            account_address,
            vars.actual_collateral_to_liquidate,
            pool::get_next_liquidity_index(&collateral_reserve_cache),
            pool::get_a_token_address(&collateral_reserve_cache)
        )
    }

    /// @notice Liquidates the user aTokens by transferring them to the liquidator.
    /// @dev The function also checks the state of the liquidator and activates the aToken as collateral
    /// as in standard transfers if the isolation mode constraints are respected.
    /// @param account_address The liquidator account address
    /// @param collateral_reserve The data of the collateral reserve
    /// @param params The additional parameters needed to execute the liquidation function
    /// @param vars The liquidation_call() function local vars
    fun liquidate_a_tokens(
        account_address: address,
        collateral_reserve: &ReserveData,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        let liquidator_previous_a_token_balance =
            pool::a_token_balance_of(account_address, vars.collateral_a_token);

        let underlying_asset =
            a_token_factory::get_underlying_asset_address(vars.collateral_a_token);
        let index = pool::get_reserve_normalized_income(underlying_asset);

        a_token_factory::transfer_on_liquidation(
            params.user,
            account_address,
            vars.actual_collateral_to_liquidate,
            index,
            vars.collateral_a_token
        );

        if (liquidator_previous_a_token_balance == 0) {
            let liquidator_config = pool::get_user_configuration(account_address);
            let reserve_config_map =
                pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
            if (validation_logic::validate_automatic_use_as_collateral(
                account_address,
                &liquidator_config,
                &reserve_config_map
            )) {
                user_config::set_using_as_collateral(
                    &mut liquidator_config,
                    (pool::get_reserve_id(collateral_reserve) as u256),
                    true
                );
                pool::set_user_configuration(account_address, liquidator_config);

                event::emit(
                    ReserveUsedAsCollateralEnabled {
                        reserve: params.collateral_asset,
                        user: account_address
                    }
                );
            };
        }
    }

    /// @notice Burns the debt tokens of the user up to the amount being repaid by the liquidator.
    /// @param debt_reserve_cache The reserve cache object of the debt reserve cache
    /// @param params The additional parameters needed to execute the liquidation function
    /// @param vars the liquidation_call() function local vars
    fun burn_debt_tokens(
        debt_reserve_cache: &mut ReserveCache,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        let variable_debt_token_address =
            pool::get_variable_debt_token_address(debt_reserve_cache);
        let next_variable_borrow_index =
            pool::get_next_variable_borrow_index(debt_reserve_cache);
        if (vars.user_variable_debt >= vars.actual_debt_to_liquidate) {
            variable_debt_token_factory::burn(
                params.user,
                vars.actual_debt_to_liquidate,
                next_variable_borrow_index,
                variable_debt_token_address
            );
            let next_scaled_variable_debt =
                variable_debt_token_factory::scaled_total_supply(
                    variable_debt_token_address
                );
            pool::set_next_scaled_variable_debt(
                debt_reserve_cache,
                next_scaled_variable_debt
            );
        } else {
            // If the user doesn't have variable debt, no need to try to burn variable debt tokens
            if (vars.user_variable_debt != 0) {
                variable_debt_token_factory::burn(
                    params.user,
                    vars.user_variable_debt,
                    next_variable_borrow_index,
                    variable_debt_token_address
                );
                let next_scaled_variable_debt =
                    variable_debt_token_factory::scaled_total_supply(
                        variable_debt_token_address
                    );
                pool::set_next_scaled_variable_debt(
                    debt_reserve_cache,
                    next_scaled_variable_debt
                );
            }
        }
    }

    /// @notice Calculates the total debt of the user and the actual amount to liquidate depending on the health factor
    /// and corresponding close factor.
    /// @dev If the Health Factor is below CLOSE_FACTOR_HF_THRESHOLD, the close factor is increased to MAX_LIQUIDATION_CLOSE_FACTOR
    /// @param debt_reserve_cache The reserve cache object of the debt reserve cache
    /// @param params The additional parameters needed to execute the liquidation function
    /// @param health_factor The health factor of the position
    /// @return The variable debt of the user
    /// @return The total debt of the user
    /// @return The actual debt to liquidate as a function of the closeFactor
    fun calculate_debt(
        debt_reserve_cache: &ReserveCache,
        params: &ExecuteLiquidationCallParams,
        health_factor: u256
    ): (u256, u256, u256) {
        let user_variable_debt =
            pool::variable_debt_token_balance_of(
                params.user,
                pool::get_variable_debt_token_address(debt_reserve_cache)
            );
        let user_total_debt = user_variable_debt;

        let close_factor =
            if (health_factor > CLOSE_FACTOR_HF_THRESHOLD) {
                DEFAULT_LIQUIDATION_CLOSE_FACTOR
            } else {
                MAX_LIQUIDATION_CLOSE_FACTOR
            };

        let max_liquidatable_debt = math_utils::percent_mul(
            user_total_debt, close_factor
        );

        let actual_debt_to_liquidate =
            if (params.debt_to_cover > max_liquidatable_debt) {
                max_liquidatable_debt
            } else {
                params.debt_to_cover
            };

        (user_variable_debt, user_total_debt, actual_debt_to_liquidate)
    }

    /// @notice Returns the configuration data for the debt and the collateral reserves.
    /// @param collateral_reserve The data of the collateral reserve
    /// @param params The additional parameters needed to execute the liquidation function
    /// @return The collateral aToken
    /// @return The address to use as price source for the collateral
    /// @return The address to use as price source for the debt
    /// @return The liquidation bonus to apply to the collateral
    fun get_configuration_data(
        collateral_reserve: &ReserveData, params: &ExecuteLiquidationCallParams
    ): (address, address, address, u256) {
        let collateral_a_token = pool::get_reserve_a_token_address(collateral_reserve);
        let collateral_config_map =
            pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
        let liquidation_bonus =
            reserve_config::get_liquidation_bonus(&collateral_config_map);

        let collateral_price_source = params.collateral_asset;
        let debt_price_source = params.debt_asset;

        if (params.user_emode_category != 0) {
            let emode_category_data =
                emode_logic::get_emode_category_data(params.user_emode_category);
            let emode_price_source =
                emode_logic::get_emode_category_price_source(&emode_category_data);

            if (emode_logic::is_in_emode_category(
                (params.user_emode_category as u256),
                reserve_config::get_emode_category(&collateral_config_map)
            )) {
                liquidation_bonus = (
                    emode_logic::get_emode_category_liquidation_bonus(
                        &emode_category_data
                    ) as u256
                );
                if (emode_price_source != @0x0) {
                    collateral_price_source = emode_price_source;
                };
            };

            // when in eMode, debt will always be in the same eMode category, can skip matching category check
            if (emode_price_source != @0x0) {
                debt_price_source = emode_price_source;
            };
        };
        (
            collateral_a_token,
            collateral_price_source,
            debt_price_source,
            liquidation_bonus
        )
    }

    struct AvailableCollateralToLiquidateLocalVars has drop {
        collateral_price: u256,
        debt_asset_price: u256,
        max_collateral_to_liquidate: u256,
        base_collateral: u256,
        bonus_collateral: u256,
        debt_asset_decimals: u256,
        collateral_decimals: u256,
        collateral_asset_unit: u256,
        debt_asset_unit: u256,
        collateral_amount: u256,
        debt_amount_needed: u256,
        liquidation_protocol_fee_percentage: u256,
        liquidation_protocol_fee: u256
    }

    fun create_available_collateral_to_liquidate_local_vars():
        AvailableCollateralToLiquidateLocalVars {
        AvailableCollateralToLiquidateLocalVars {
            collateral_price: 0,
            debt_asset_price: 0,
            max_collateral_to_liquidate: 0,
            base_collateral: 0,
            bonus_collateral: 0,
            debt_asset_decimals: 0,
            collateral_decimals: 0,
            collateral_asset_unit: 0,
            debt_asset_unit: 0,
            collateral_amount: 0,
            debt_amount_needed: 0,
            liquidation_protocol_fee_percentage: 0,
            liquidation_protocol_fee: 0
        }
    }

    /// @notice Calculates how much of a specific collateral can be liquidated, given
    /// a certain amount of debt asset.
    /// @dev This function needs to be called after all the checks to validate the liquidation have been performed,
    /// otherwise it might fail.
    /// @param collateral_reserve The data of the collateral reserve
    /// @param debt_reserve_cache The data of the debt reserve cache
    /// @param collateral_asset The address of the underlying asset used as collateral, to receive as result of the liquidation
    /// @param debt_asset The address of the underlying borrowed asset to be repaid with the liquidation
    /// @param debt_to_cover The debt amount of borrowed `asset` the liquidator wants to cover
    /// @param user_collateral_balance The collateral balance for the specific `collateralAsset` of the user being liquidated
    /// @param liquidation_bonus The collateral bonus percentage to receive as result of the liquidation
    /// @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
    /// @return The amount to repay with the liquidation
    /// @return The fee taken from the liquidation bonus amount to be paid to the protocol
    fun calculate_available_collateral_to_liquidate(
        collateral_reserve: &ReserveData,
        debt_reserve_cache: &ReserveCache,
        collateral_asset: address,
        debt_asset: address,
        debt_to_cover: u256,
        user_collateral_balance: u256,
        liquidation_bonus: u256
    ): (u256, u256, u256) {
        let vars = create_available_collateral_to_liquidate_local_vars();
        // TODO Waiting for Chainlink oracle functionality
        vars.collateral_price = oracle::get_asset_price(collateral_asset);
        vars.debt_asset_price = oracle::get_asset_price(debt_asset);

        let collateral_reserve_config =
            pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
        vars.collateral_decimals = reserve_config::get_decimals(
            &collateral_reserve_config
        );

        let debt_reserve_config =
            pool::get_reserve_cache_configuration(debt_reserve_cache);
        vars.debt_asset_decimals = reserve_config::get_decimals(&debt_reserve_config);

        vars.collateral_asset_unit = math_utils::pow(10, vars.collateral_decimals);
        vars.debt_asset_unit = math_utils::pow(10, vars.debt_asset_decimals);

        vars.liquidation_protocol_fee_percentage = reserve_config::get_liquidation_protocol_fee(
            &collateral_reserve_config
        );

        // This is the base collateral to liquidate based on the given debt to cover
        vars.base_collateral = (
            vars.debt_asset_price * debt_to_cover * vars.collateral_asset_unit
        ) / (vars.collateral_price * vars.debt_asset_unit);

        vars.max_collateral_to_liquidate = math_utils::percent_mul(
            vars.base_collateral, liquidation_bonus
        );

        if (vars.max_collateral_to_liquidate > user_collateral_balance) {
            vars.collateral_amount = user_collateral_balance;
            vars.debt_amount_needed = math_utils::percent_div(
                ((vars.collateral_price * vars.collateral_amount * vars.debt_asset_unit)
                    / (vars.debt_asset_price * vars.collateral_asset_unit)),
                liquidation_bonus
            );
        } else {
            vars.collateral_amount = vars.max_collateral_to_liquidate;
            vars.debt_amount_needed = debt_to_cover;
        };

        if (vars.liquidation_protocol_fee_percentage != 0) {
            vars.bonus_collateral = vars.collateral_amount
                - math_utils::percent_div(vars.collateral_amount, liquidation_bonus);

            vars.liquidation_protocol_fee = math_utils::percent_mul(
                vars.bonus_collateral,
                vars.liquidation_protocol_fee_percentage
            );

            (
                vars.collateral_amount - vars.liquidation_protocol_fee,
                vars.debt_amount_needed,
                vars.liquidation_protocol_fee
            )
        } else {
            (vars.collateral_amount, vars.debt_amount_needed, 0)
        }
    }
}
