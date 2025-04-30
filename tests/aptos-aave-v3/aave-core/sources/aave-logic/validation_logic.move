module aave_pool::validation_logic {
    use std::string;
    use std::vector;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_config::reserve_config::{Self, ReserveConfigurationMap};
    use aave_config::user_config::{Self, UserConfigurationMap};
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_oracle::oracle;

    use aave_pool::a_token_factory;
    use aave_pool::generic_logic;
    use aave_pool::pool::{Self, ReserveCache, ReserveData};

    /// @notice Validates a flashloan action.
    /// @param reserves_data The data of all the reserves
    /// @param assets The assets being flash-borrowed
    /// @param amounts The amounts for each asset being borrowed
    public fun validate_flashloan_complex(
        reserves_data: &vector<ReserveData>,
        assets: &vector<address>,
        amounts: &vector<u256>,
        interest_rate_modes: &vector<u8>
    ) {
        assert!(
            vector::length(assets) == vector::length(amounts)
                && vector::length(assets) == vector::length(interest_rate_modes),
            error_config::get_einconsistent_flashloan_params()
        );
        for (i in 0..vector::length(assets)) {
            validate_flashloan_simple(vector::borrow(reserves_data, i));
        }
    }

    /// @notice Validates a flashloan action.
    /// @param reserve_data The reserve data the reserve
    public fun validate_flashloan_simple(reserve_data: &ReserveData) {
        let reserve_configuration =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        let (is_active, _, _, is_paused) =
            reserve_config::get_flags(&reserve_configuration);
        assert!(!is_paused, error_config::get_ereserve_paused());
        assert!(is_active, error_config::get_ereserve_inactive());
        let is_flashloan_enabled =
            reserve_config::get_flash_loan_enabled(&reserve_configuration);
        assert!(is_flashloan_enabled, error_config::get_eflashloan_disabled());
    }

    /// @notice Validates a supply action.
    /// @param reserve_cache The reserve cache of the reserve
    /// @param reserve_data The reserve data of the reserve
    /// @param amount The amount to be supplied
    public fun validate_supply(
        reserve_cache: &ReserveCache, reserve_data: &ReserveData, amount: u256
    ) {
        assert!(amount != 0, error_config::get_einvalid_amount());

        let reserve_configuration_map =
            pool::get_reserve_cache_configuration(reserve_cache);
        let (is_active, is_frozen, _, is_paused) =
            reserve_config::get_flags(&reserve_configuration_map);

        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
        assert!(!is_frozen, error_config::get_ereserve_frozen());

        let supply_cap = reserve_config::get_supply_cap(&reserve_configuration_map);
        let a_token_scaled_total_supply =
            a_token_factory::scaled_total_supply(
                pool::get_a_token_address(reserve_cache)
            );

        let total_supply_liquidity =
            wad_ray_math::ray_mul(
                (
                    a_token_scaled_total_supply
                        + pool::get_reserve_accrued_to_treasury(reserve_data)
                ),
                pool::get_next_liquidity_index(reserve_cache)
            );

        let total_supply = total_supply_liquidity + amount;
        let max_supply_cap =
            supply_cap
                * (
                    math_utils::pow(
                        10,
                        reserve_config::get_decimals(&reserve_configuration_map)
                    )
                );

        assert!(
            supply_cap == 0 || total_supply <= max_supply_cap,
            error_config::get_esupply_cap_exceeded()
        );
    }

    /// @notice Validates a withdraw action.
    /// @param reserve_cache The reserve cache of the reserve
    /// @param amount The amount to be withdrawn
    /// @param user_balance The balance of the user
    public fun validate_withdraw(
        reserve_cache: &ReserveCache, amount: u256, user_balance: u256
    ) {
        assert!(amount != 0, error_config::get_einvalid_amount());
        assert!(
            amount <= user_balance,
            error_config::get_enot_enough_available_user_balance()
        );

        let reserve_configuration_map =
            pool::get_reserve_cache_configuration(reserve_cache);
        let (is_active, _, _, is_paused) =
            reserve_config::get_flags(&reserve_configuration_map);
        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
    }

    /// @notice Validates a transfer action.
    /// @param reserve_data The reserve data the reserve
    public fun validate_transfer(reserve_data: &ReserveData) {
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        assert!(
            !reserve_config::get_paused(&reserve_config_map),
            error_config::get_ereserve_paused()
        )
    }

    /// @notice Validates the action of setting an asset as collateral.
    /// @param reserve_cache The reserve cache of the reserve
    /// @param user_balance The balance of the user
    public fun validate_set_use_reserve_as_collateral(
        reserve_cache: &ReserveCache, user_balance: u256
    ) {
        assert!(user_balance != 0, error_config::get_eunderlying_balance_zero());
        let reserve_configuration_map =
            pool::get_reserve_cache_configuration(reserve_cache);
        let (is_active, _, _, is_paused) =
            reserve_config::get_flags(&reserve_configuration_map);
        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
    }

    /**
    * ----------------------------
    * Borrow Validate
    * ----------------------------
    */
    struct ValidateBorrowLocalVars has drop {
        current_ltv: u256,
        collateral_needed_in_base_currency: u256,
        user_collateral_in_base_currency: u256,
        user_debt_in_base_currency: u256,
        available_liquidity: u256,
        health_factor: u256,
        total_debt: u256,
        total_supply_variable_debt: u256,
        reserve_decimals: u256,
        borrow_cap: u256,
        amount_in_base_currency: u256,
        asset_unit: u256,
        emode_price_source: address,
        siloed_borrowing_address: address,
        is_active: bool,
        is_frozen: bool,
        is_paused: bool,
        borrowing_enabled: bool,
        siloed_borrowing_enabled: bool
    }

    fun create_validate_borrow_local_vars(): ValidateBorrowLocalVars {
        ValidateBorrowLocalVars {
            current_ltv: 0,
            collateral_needed_in_base_currency: 0,
            user_collateral_in_base_currency: 0,
            user_debt_in_base_currency: 0,
            available_liquidity: 0,
            health_factor: 0,
            total_debt: 0,
            total_supply_variable_debt: 0,
            reserve_decimals: 0,
            borrow_cap: 0,
            amount_in_base_currency: 0,
            asset_unit: 0,
            emode_price_source: @0x0,
            siloed_borrowing_address: @0x0,
            is_active: false,
            is_frozen: false,
            is_paused: false,
            borrowing_enabled: false,
            siloed_borrowing_enabled: false
        }
    }

    /// @notice Validates a borrow action.
    /// @param reserve_cache The reserve cache of the reserve
    /// @param user_config_map The UserConfigurationMap object
    /// @param asset The address of the asset to be borrowed
    /// @param user_address The address of the user
    /// @param amount The amount to be borrowed
    /// @param interest_rate_mode The interest rate mode
    /// @param reserves_count The number of reserves
    /// @param user_emode_category The user's eMode category
    /// @param emode_ltv The eMode LTV
    /// @param emode_liq_threshold The eMode liquidation threshold
    /// @param emode_asset_price The eMode asset price
    /// @param emode_source_price The eMode price source
    /// @param isolation_mode_active The isolation mode state
    /// @param isolation_mode_collateral_address The address of the collateral reserve in isolation mode
    /// @param isolation_mode_debt_ceiling The debt ceiling in isolation mode
    public fun validate_borrow(
        reserve_cache: &ReserveCache,
        user_config_map: &UserConfigurationMap,
        asset: address,
        user_address: address,
        amount: u256,
        interest_rate_mode: u8,
        reserves_count: u256,
        user_emode_category: u8,
        emode_ltv: u256,
        emode_liq_threshold: u256,
        emode_asset_price: u256,
        emode_source_price: address,
        isolation_mode_active: bool,
        isolation_mode_collateral_address: address,
        isolation_mode_debt_ceiling: u256
    ) {
        assert!(amount != 0, error_config::get_einvalid_amount());
        let vars = create_validate_borrow_local_vars();
        let reserve_configuration_map =
            pool::get_reserve_cache_configuration(reserve_cache);

        let (is_active, is_frozen, borrowing_enabled, is_paused) =
            reserve_config::get_flags(&reserve_configuration_map);

        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
        assert!(!is_frozen, error_config::get_ereserve_frozen());
        assert!(borrowing_enabled, error_config::get_eborrowing_not_enabled());

        // validate interest rate mode
        assert!(
            interest_rate_mode == user_config::get_interest_rate_mode_variable(),
            error_config::get_einvalid_interest_rate_mode_selected()
        );
        vars.reserve_decimals = reserve_config::get_decimals(&reserve_configuration_map);
        vars.borrow_cap = reserve_config::get_borrow_cap(&reserve_configuration_map);
        vars.asset_unit = math_utils::pow(10, vars.reserve_decimals);
        if (vars.borrow_cap != 0) {
            vars.total_supply_variable_debt = wad_ray_math::ray_mul(
                pool::get_curr_scaled_variable_debt(reserve_cache),
                pool::get_next_variable_borrow_index(reserve_cache)
            );
            vars.total_debt = vars.total_supply_variable_debt + amount;
            assert!(
                vars.total_debt <= vars.borrow_cap * vars.asset_unit,
                error_config::get_eborrow_cap_exceeded()
            );
        };

        if (isolation_mode_active) {
            // check that the asset being borrowed is borrowable in isolation mode AND
            // the total exposure is no bigger than the collateral debt ceiling
            assert!(
                reserve_config::get_borrowable_in_isolation(&reserve_configuration_map),
                error_config::get_easset_not_borrowable_in_isolation()
            );

            let mode_collateral_reserve_data =
                pool::get_reserve_data(isolation_mode_collateral_address);
            let isolation_mode_total_debt =
                (
                    pool::get_reserve_isolation_mode_total_debt(
                        &mode_collateral_reserve_data
                    ) as u256
                );
            let total_debt =
                isolation_mode_total_debt
                    + (
                        amount
                            / math_utils::pow(
                                10,
                                (
                                    vars.reserve_decimals
                                        - reserve_config::get_debt_ceiling_decimals()
                                )
                            )
                    );
            assert!(
                total_debt <= isolation_mode_debt_ceiling,
                error_config::get_edebt_ceiling_exceeded()
            );
        };

        if (user_emode_category != 0) {
            assert!(
                reserve_config::get_emode_category(&reserve_configuration_map)
                    == (user_emode_category as u256),
                error_config::get_einconsistent_emode_category()
            );
            vars.emode_price_source = emode_source_price;
        };

        let (
            user_collateral_in_base_currency,
            user_debt_in_base_currency,
            current_ltv,
            _,
            health_factor,
            _
        ) =
            generic_logic::calculate_user_account_data(
                user_config_map,
                reserves_count,
                user_address,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price
            );

        vars.user_collateral_in_base_currency = user_collateral_in_base_currency;
        vars.user_debt_in_base_currency = user_debt_in_base_currency;
        vars.current_ltv = current_ltv;
        vars.health_factor = health_factor;

        assert!(
            vars.user_collateral_in_base_currency != 0,
            error_config::get_ecollateral_balance_is_zero()
        );
        assert!(vars.current_ltv != 0, error_config::get_eltv_validation_failed());
        assert!(
            vars.health_factor > user_config::get_health_factor_liquidation_threshold(),
            error_config::get_ehealth_factor_lower_than_liquidation_threshold()
        );

        // Currently, custom oracle is not supported. Only a unified oracle is used. Therefore, the price is obtained by calling the oracle directly with the asset.
        let asset_address =
            if (vars.emode_price_source != @0x0) {
                vars.emode_price_source
            } else { asset };
        vars.amount_in_base_currency = oracle::get_asset_price(asset_address) * amount;
        vars.amount_in_base_currency = vars.amount_in_base_currency / vars.asset_unit;

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        vars.collateral_needed_in_base_currency = math_utils::percent_div(
            (vars.user_debt_in_base_currency + vars.amount_in_base_currency),
            vars.current_ltv //LTV is calculated in percentage
        );

        assert!(
            vars.collateral_needed_in_base_currency
                <= vars.user_collateral_in_base_currency,
            error_config::get_ecollateral_cannot_cover_new_borrow()
        );

        if (user_config::is_borrowing_any(user_config_map)) {
            let (siloed_borrowing_enabled, siloed_borrowing_address) =
                pool::get_siloed_borrowing_state(user_address);

            vars.siloed_borrowing_enabled = siloed_borrowing_enabled;
            vars.siloed_borrowing_address = siloed_borrowing_address;

            if (vars.siloed_borrowing_enabled) {
                assert!(
                    vars.siloed_borrowing_address == asset,
                    error_config::get_esiloed_borrowing_violation()
                )
            } else {
                assert!(
                    !reserve_config::get_siloed_borrowing(&reserve_configuration_map),
                    error_config::get_esiloed_borrowing_violation()
                )
            }
        }
    }

    /// @notice Validates a repay action.
    /// @param account_address The address of the user repaying the debt
    /// @param reserve_cache The reserve cache of the reserve
    /// @param amount_sent The amount sent for the repayment. Can be an actual value or uint(-1)
    /// @param interest_rate_mode The interest rate mode of the debt being repaid
    /// @param on_behalf_of The address of the user account_address is repaying for
    /// @param variable_debt The borrow balance of the user
    public fun validate_repay(
        account_address: address,
        reserve_cache: &ReserveCache,
        amount_sent: u256,
        interest_rate_mode: u8,
        on_behalf_of: address,
        variable_debt: u256
    ) {
        assert!(amount_sent != 0, error_config::get_einvalid_amount());
        assert!(
            amount_sent != math_utils::u256_max() || account_address == on_behalf_of,
            error_config::get_eno_explicit_amount_to_repay_on_behalf()
        );
        let reserve_configuration = pool::get_reserve_cache_configuration(
            reserve_cache
        );
        let (is_active, _, _, is_paused) =
            reserve_config::get_flags(&reserve_configuration);
        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());

        assert!(
            variable_debt != 0
                && interest_rate_mode == user_config::get_interest_rate_mode_variable(),
            error_config::get_eno_debt_of_selected_type()
        );
    }

    /// @notice Validates the liquidation action.
    /// @param user_config_map The user configuration mapping
    /// @param collateral_reserve The reserve data of the collateral
    /// @param debt_reserve_cache The reserve cache of the debt reserve
    /// @param total_debt The total debt of the user
    /// @param health_factor The health factor of the user
    public fun validate_liquidation_call(
        user_config_map: &UserConfigurationMap,
        collateral_reserve: &ReserveData,
        debt_reserve_cache: &ReserveCache,
        total_debt: u256,
        health_factor: u256
    ) {
        let collateral_reserve_config =
            pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
        let (collateral_reserve_active, _, _, collateral_reserve_paused) =
            reserve_config::get_flags(&collateral_reserve_config);

        let debt_reserve_config =
            pool::get_reserve_cache_configuration(debt_reserve_cache);
        let (principal_reserve_active, _, _, principal_reserve_paused) =
            reserve_config::get_flags(&debt_reserve_config);

        assert!(
            collateral_reserve_active && principal_reserve_active,
            error_config::get_ereserve_inactive()
        );
        assert!(
            !collateral_reserve_paused && !principal_reserve_paused,
            error_config::get_ereserve_paused()
        );

        assert!(
            health_factor
                < user_config::get_minimum_health_factor_liquidation_threshold(),
            error_config::get_ehealth_factor_lower_than_liquidation_threshold()
        );

        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            error_config::get_ehealth_factor_not_below_threshold()
        );

        let collateral_reserve_id = pool::get_reserve_id(collateral_reserve);
        let is_collateral_enabled =
            reserve_config::get_liquidation_threshold(&collateral_reserve_config) != 0
                && user_config::is_using_as_collateral(
                    user_config_map, (collateral_reserve_id as u256)
                );

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        assert!(
            is_collateral_enabled,
            error_config::get_ecollateral_cannot_be_liquidated()
        );
        assert!(
            total_debt != 0,
            error_config::get_especified_currency_not_borrowed_by_user()
        );
    }

    /// @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
    /// @param user_config_map the user configuration map
    /// @param asset The address of the underlying asset of the reserve
    /// @param from The user from which the aTokens are being transferred
    /// @param reserves_count The number of available reserves
    /// @param user_emode_category The users active efficiency mode category
    /// @param emode_ltv The ltv of the efficiency mode category
    /// @param emode_liq_threshold The liquidation threshold of the efficiency mode category
    /// @param emode_asset_price The price of the efficiency mode category
    public fun validate_hf_and_ltv(
        user_config_map: &UserConfigurationMap,
        asset: address,
        from: address,
        reserves_count: u256,
        user_emode_category: u8,
        emode_ltv: u256,
        emode_liq_threshold: u256,
        emode_asset_price: u256
    ) {
        let reserve_data = pool::get_reserve_data(asset);
        let (_, has_zero_ltv_collateral) =
            validate_health_factor(
                user_config_map,
                from,
                user_emode_category,
                reserves_count,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price
            );
        let reserve_configuration_map =
            pool::get_reserve_configuration_by_reserve_data(&reserve_data);
        assert!(
            !has_zero_ltv_collateral
                || reserve_config::get_ltv(&reserve_configuration_map) == 0,
            error_config::get_eltv_validation_failed()
        );
    }

    /// @notice Validates if an asset should be automatically activated as collateral in the following actions: supply,
    /// transfer, mint unbacked, and liquidate
    /// @dev This is used to ensure that isolated assets are not enabled as collateral automatically
    /// @param user_config_map the user configuration map
    /// @param reserve_config_map The reserve configuration map
    /// @return True if the asset can be activated as collateral, false otherwise
    public fun validate_automatic_use_as_collateral(
        account_address: address,
        user_config_map: &UserConfigurationMap,
        reserve_config_map: &ReserveConfigurationMap
    ): bool {
        if (reserve_config::get_debt_ceiling(reserve_config_map) != 0) {
            // ensures only the ISOLATED_COLLATERAL_SUPPLIER_ROLE can enable collateral as side-effect of an action
            if (!acl_manage::has_role(
                string::utf8(user_config::get_isolated_collateral_supplier_role()),
                account_address
            )) {
                return false
            };
        };

        return validate_use_as_collateral(user_config_map, reserve_config_map)
    }

    /// @notice Validates the action of activating the asset as collateral.
    /// @dev Only possible if the asset has non-zero LTV and the user is not in isolation mode
    /// @param user_config_map the user configuration map
    /// @param reserve_config_map The reserve configuration map
    /// @return True if the asset can be activated as collateral, false otherwise
    public fun validate_use_as_collateral(
        user_config_map: &UserConfigurationMap,
        reserve_config_map: &ReserveConfigurationMap
    ): bool {
        if (reserve_config::get_ltv(reserve_config_map) == 0) {
            return false
        };
        if (!user_config::is_using_as_collateral_any(user_config_map)) {
            return true
        };

        let (isolation_mode_active, _, _) =
            pool::get_isolation_mode_state(user_config_map);

        (
            !isolation_mode_active
                && reserve_config::get_debt_ceiling(reserve_config_map) == 0
        )
    }

    /// @notice Validates the health factor of a user.
    /// @param user_config_map the user configuration map
    /// @param user The user to validate health factor of
    /// @param user_emode_category The users active efficiency mode category
    /// @param reserves_count The number of available reserves
    /// @param emode_ltv The ltv of the efficiency mode category
    /// @param emode_liq_threshold The liquidation threshold of the efficiency mode category
    /// @param emode_asset_price The price of the efficiency mode category
    public fun validate_health_factor(
        user_config_map: &UserConfigurationMap,
        user: address,
        user_emode_category: u8,
        reserves_count: u256,
        emode_ltv: u256,
        emode_liq_threshold: u256,
        emode_asset_price: u256
    ): (u256, bool) {
        let (_, _, _, _, health_factor, has_zero_ltv_collateral) =
            generic_logic::calculate_user_account_data(
                user_config_map,
                reserves_count,
                user,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price
            );

        assert!(
            health_factor >= user_config::get_health_factor_liquidation_threshold(),
            error_config::get_ehealth_factor_lower_than_liquidation_threshold()
        );

        (health_factor, has_zero_ltv_collateral)
    }

    /// @notice Validates the action of setting efficiency mode.
    /// @param user_config_map the user configuration map
    /// @param reserves_count The total number of valid reserves
    /// @param category_id The id of the category
    /// @param liquidation_threshold The liquidation threshold
    public fun validate_set_user_emode(
        user_config_map: &UserConfigurationMap,
        reserves_count: u256,
        category_id: u8,
        liquidation_threshold: u16
    ) {
        // category is invalid if the liq threshold is not set
        assert!(
            category_id == 0 || liquidation_threshold != 0,
            error_config::get_einconsistent_emode_category()
        );

        // eMode can always be enabled if the user hasn't supplied anything
        if (!user_config::is_empty(user_config_map)) {
            // if user is trying to set another category than default we require that
            // either the user is not borrowing, or it's borrowing assets of category_id
            if (category_id != 0) {
                for (i in 0..reserves_count) {
                    if (user_config::is_borrowing(user_config_map, i)) {
                        let reserve_address = pool::get_reserve_address_by_id(i);
                        let reserve_configuration =
                            pool::get_reserve_configuration(reserve_address);
                        assert!(
                            reserve_config::get_emode_category(&reserve_configuration)
                                == (category_id as u256),
                            error_config::get_einconsistent_emode_category()
                        );
                    };
                }
            }
        }
    }
}
