#[test_only]
module aave_config::reserve_tests {
    use aave_config::reserve_config::{
        get_borrow_cap,
        get_borrowing_enabled,
        get_caps,
        get_decimals,
        get_emode_category,
        get_flags,
        get_flash_loan_enabled,
        get_frozen,
        get_liquidation_bonus,
        get_liquidation_protocol_fee,
        get_liquidation_threshold,
        get_ltv,
        get_max_valid_decimals,
        get_max_valid_emode_category,
        get_max_valid_liquidation_protocol_fee,
        get_max_valid_liquidation_threshold,
        get_max_valid_ltv,
        get_max_valid_reserve_factor,
        get_params,
        get_reserve_factor,
        get_supply_cap,
        get_unbacked_mint_cap,
        init,
        ReserveConfigurationMap,
        set_borrow_cap,
        set_borrowing_enabled,
        set_decimals,
        set_emode_category,
        set_flash_loan_enabled,
        set_frozen,
        set_liquidation_bonus,
        set_liquidation_protocol_fee,
        set_liquidation_threshold,
        set_ltv,
        set_reserve_factor,
        set_supply_cap,
        set_unbacked_mint_cap
    };

    //
    // Test example reference link: https://github.com/aave/aave-v3-core/blob/master/test-suites/reserve-configuration.spec.ts
    // test functions
    //
    #[test_only]
    const ZERO: u256 = 0;
    const LTV: u256 = 8000;
    const LB: u256 = 500;
    const RESERVE_FACTOR: u256 = 1000;
    const DECIMALS: u256 = 18;
    const BORROW_CAP: u256 = 100;
    const SUPPLY_CAP: u256 = 200;
    const UNBACKED_MINT_CAP: u256 = 300;
    const EMODE_CATEGORY: u256 = 1;

    // error
    const SUCCESS: u64 = 1;
    const FAILED: u64 = 2;

    // enum
    const ENUM_LTV: u256 = 1;
    const ENUM_LIQUIDATION_THRESHOLD: u256 = 2;
    const ENUM_LIQUIDATION_BONUS: u256 = 3;
    const ENUM_DECIMALS: u256 = 4;
    const ENUM_RESERVE_FACTOR: u256 = 5;
    const ENUM_EMODE_CATEGORY: u256 = 6;

    // check params
    fun check_params(
        reserve_config: &ReserveConfigurationMap, param_key: u256, param_val: u256
    ) {
        let (
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            decimals,
            reserve_factor,
            emode_category
        ) = get_params(reserve_config);
        if (param_key == ENUM_LTV) {
            assert!(ltv == param_val, SUCCESS);
        } else {
            assert!(ltv == 0, SUCCESS);
        };

        if (param_key == ENUM_LIQUIDATION_THRESHOLD) {
            assert!(liquidation_threshold == param_val, SUCCESS);
        } else {
            assert!(liquidation_threshold == 0, SUCCESS);
        };

        if (param_key == ENUM_LIQUIDATION_BONUS) {
            assert!(liquidation_bonus == param_val, SUCCESS);
        } else {
            assert!(liquidation_bonus == 0, SUCCESS);
        };

        if (param_key == ENUM_DECIMALS) {
            assert!(decimals == param_val, SUCCESS);
        } else {
            assert!(decimals == 0, SUCCESS);
        };

        if (param_key == ENUM_RESERVE_FACTOR) {
            assert!(reserve_factor == param_val, SUCCESS);
        } else {
            assert!(reserve_factor == 0, SUCCESS);
        };

        if (param_key == ENUM_EMODE_CATEGORY) {
            assert!(emode_category == param_val, SUCCESS);
        } else {
            assert!(emode_category == 0, SUCCESS);
        };
    }

    #[test]
    fun test_get_ltv() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_ltv(&reserve_config) == ZERO, SUCCESS);

        set_ltv(&mut reserve_config, LTV);
        check_params(&reserve_config, ENUM_LTV, LTV);
        assert!(get_ltv(&reserve_config) == LTV, SUCCESS);

        set_ltv(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_LTV, ZERO);
        assert!(get_ltv(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_liquidation_bonus() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_liquidation_bonus(&reserve_config) == ZERO, SUCCESS);

        set_liquidation_bonus(&mut reserve_config, LB);
        check_params(&reserve_config, ENUM_LIQUIDATION_BONUS, LB);
        assert!(get_liquidation_bonus(&reserve_config) == LB, SUCCESS);

        set_liquidation_bonus(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_LIQUIDATION_BONUS, ZERO);
        assert!(get_liquidation_bonus(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_decimals() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_decimals(&reserve_config) == ZERO, SUCCESS);

        set_decimals(&mut reserve_config, DECIMALS);
        check_params(&reserve_config, ENUM_DECIMALS, DECIMALS);
        assert!(get_decimals(&reserve_config) == DECIMALS, SUCCESS);

        set_decimals(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_DECIMALS, ZERO);
        assert!(get_decimals(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_emode_category() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_emode_category(&reserve_config) == ZERO, SUCCESS);

        set_emode_category(&mut reserve_config, EMODE_CATEGORY);
        check_params(&reserve_config, ENUM_EMODE_CATEGORY, EMODE_CATEGORY);
        assert!(get_emode_category(&reserve_config) == EMODE_CATEGORY, SUCCESS);

        set_emode_category(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_EMODE_CATEGORY, ZERO);
        assert!(get_emode_category(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_reserve_factor() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_reserve_factor(&reserve_config) == ZERO, SUCCESS);

        set_reserve_factor(&mut reserve_config, RESERVE_FACTOR);
        check_params(&reserve_config, ENUM_RESERVE_FACTOR, RESERVE_FACTOR);
        assert!(get_reserve_factor(&reserve_config) == RESERVE_FACTOR, SUCCESS);

        set_reserve_factor(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_RESERVE_FACTOR, ZERO);
        assert!(get_reserve_factor(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_frozen() {
        let reserve_config = init();
        let (active, frozen, borrowing_enabled, paused) = get_flags(&reserve_config);
        assert!(active == false, SUCCESS);
        assert!(frozen == false, SUCCESS);
        assert!(borrowing_enabled == false, SUCCESS);
        assert!(paused == false, SUCCESS);
        assert!(get_frozen(&reserve_config) == false, SUCCESS);

        set_frozen(&mut reserve_config, true);
        let (active, frozen, borrowing_enabled, paused) = get_flags(&reserve_config);
        assert!(active == false, SUCCESS);
        assert!(frozen == true, SUCCESS);
        assert!(borrowing_enabled == false, SUCCESS);
        assert!(paused == false, SUCCESS);
        assert!(get_frozen(&reserve_config) == true, SUCCESS);

        set_frozen(&mut reserve_config, false);
        let (active, frozen, borrowing_enabled, paused) = get_flags(&reserve_config);
        assert!(active == false, SUCCESS);
        assert!(frozen == false, SUCCESS);
        assert!(borrowing_enabled == false, SUCCESS);
        assert!(paused == false, SUCCESS);
        assert!(get_frozen(&reserve_config) == false, SUCCESS);
    }

    #[test]
    fun test_get_borrowing_enabled() {
        let reserve_config = init();
        let (active, frozen, borrowing_enabled, paused) = get_flags(&reserve_config);
        assert!(active == false, SUCCESS);
        assert!(frozen == false, SUCCESS);
        assert!(borrowing_enabled == false, SUCCESS);
        assert!(paused == false, SUCCESS);
        assert!(get_borrowing_enabled(&reserve_config) == false, SUCCESS);

        set_borrowing_enabled(&mut reserve_config, true);
        let (active, frozen, borrowing_enabled, paused) = get_flags(&reserve_config);
        assert!(active == false, SUCCESS);
        assert!(frozen == false, SUCCESS);
        assert!(borrowing_enabled == true, SUCCESS);
        assert!(paused == false, SUCCESS);
        assert!(get_borrowing_enabled(&reserve_config) == true, SUCCESS);

        set_borrowing_enabled(&mut reserve_config, false);
        let (active, frozen, borrowing_enabled, paused) = get_flags(&reserve_config);
        assert!(active == false, SUCCESS);
        assert!(frozen == false, SUCCESS);
        assert!(borrowing_enabled == false, SUCCESS);
        assert!(paused == false, SUCCESS);
        assert!(get_borrowing_enabled(&reserve_config) == false, SUCCESS);
    }

    #[test]
    // set_reserve_factor() with reserve_factor == MAX_VALID_RESERVE_FACTOR
    fun test_set_reserve_factor() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);

        set_reserve_factor(&mut reserve_config, get_max_valid_reserve_factor());
        check_params(
            &reserve_config, ENUM_RESERVE_FACTOR, get_max_valid_reserve_factor()
        );
    }

    #[test]
    // set_reserve_factor() with reserve_factor > MAX_VALID_RESERVE_FACTOR
    #[expected_failure(abort_code = 67, location = aave_config::reserve_config)]
    fun test_set_reserve_factor_expected_failure() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        set_reserve_factor(&mut reserve_config, get_max_valid_reserve_factor() + 1);

        check_params(&reserve_config, ZERO, ZERO);
    }

    #[test]
    fun test_get_borrow_cap() {
        let reserve_config = init();
        let (borrow_cap, supply_cap) = get_caps(&reserve_config);
        assert!(borrow_cap == ZERO, SUCCESS);
        assert!(supply_cap == ZERO, SUCCESS);
        assert!(get_borrow_cap(&reserve_config) == ZERO, SUCCESS);

        set_borrow_cap(&mut reserve_config, BORROW_CAP);
        // borrow cap is the 1st cap
        let (borrow_cap, supply_cap) = get_caps(&reserve_config);
        assert!(borrow_cap == BORROW_CAP, SUCCESS);
        assert!(supply_cap == ZERO, SUCCESS);
        assert!(get_borrow_cap(&reserve_config) == BORROW_CAP, SUCCESS);

        set_borrow_cap(&mut reserve_config, ZERO);
        let (borrow_cap, supply_cap) = get_caps(&reserve_config);
        assert!(borrow_cap == ZERO, SUCCESS);
        assert!(supply_cap == ZERO, SUCCESS);
        assert!(get_borrow_cap(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_supply_cap() {
        let reserve_config = init();
        let (borrow_cap, supply_cap) = get_caps(&reserve_config);
        assert!(borrow_cap == ZERO, SUCCESS);
        assert!(supply_cap == ZERO, SUCCESS);
        assert!(get_supply_cap(&reserve_config) == ZERO, SUCCESS);

        set_supply_cap(&mut reserve_config, SUPPLY_CAP);
        // borrow cap is the 1st cap
        let (borrow_cap, supply_cap) = get_caps(&reserve_config);
        assert!(borrow_cap == ZERO, SUCCESS);
        assert!(supply_cap == SUPPLY_CAP, SUCCESS);
        assert!(get_supply_cap(&reserve_config) == SUPPLY_CAP, SUCCESS);

        set_supply_cap(&mut reserve_config, ZERO);
        let (borrow_cap, supply_cap) = get_caps(&reserve_config);
        assert!(borrow_cap == ZERO, SUCCESS);
        assert!(supply_cap == ZERO, SUCCESS);
        assert!(get_supply_cap(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_unbacked_mint_cap() {
        let reserve_config = init();
        assert!(get_unbacked_mint_cap(&reserve_config) == ZERO, SUCCESS);

        set_unbacked_mint_cap(&mut reserve_config, UNBACKED_MINT_CAP);
        assert!(get_unbacked_mint_cap(&reserve_config) == UNBACKED_MINT_CAP, SUCCESS);

        set_unbacked_mint_cap(&mut reserve_config, ZERO);
        assert!(get_unbacked_mint_cap(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    fun test_get_flash_loan_enabled() {
        let reserve_config = init();
        assert!(get_flash_loan_enabled(&reserve_config) == false, SUCCESS);

        set_flash_loan_enabled(&mut reserve_config, true);
        assert!(get_flash_loan_enabled(&reserve_config) == true, SUCCESS);

        set_flash_loan_enabled(&mut reserve_config, false);
        assert!(get_flash_loan_enabled(&reserve_config) == false, SUCCESS);
    }

    #[test]
    // set_ltv() with ltv = MAX_VALID_LTV
    fun test_set_ltv() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_ltv(&reserve_config) == ZERO, SUCCESS);

        set_ltv(&mut reserve_config, get_max_valid_ltv());
        check_params(&reserve_config, ENUM_LTV, get_max_valid_ltv());
        assert!(get_ltv(&reserve_config) == get_max_valid_ltv(), SUCCESS);

        set_ltv(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_LTV, ZERO);
        assert!(get_ltv(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_ltv() with ltv > MAX_VALID_LTV (revert expected)
    #[expected_failure(abort_code = 63, location = aave_config::reserve_config)]
    fun test_set_ltv_expected_failure() {
        let reserve_config = init();
        assert!(get_ltv(&reserve_config) == ZERO, SUCCESS);

        set_ltv(&mut reserve_config, get_max_valid_ltv() + 1);
        assert!(get_ltv(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_liquidation_threshold() with threshold = MAX_VALID_LIQUIDATION_THRESHOLD
    fun test_set_liquidation_threshold() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_liquidation_threshold(&reserve_config) == ZERO, SUCCESS);

        set_liquidation_threshold(
            &mut reserve_config, get_max_valid_liquidation_threshold()
        );
        check_params(
            &reserve_config,
            ENUM_LIQUIDATION_THRESHOLD,
            get_max_valid_liquidation_threshold()
        );
        assert!(
            get_liquidation_threshold(&reserve_config)
                == get_max_valid_liquidation_threshold(),
            SUCCESS
        );

        set_liquidation_threshold(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_LIQUIDATION_THRESHOLD, ZERO);
        assert!(get_liquidation_threshold(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_liquidation_threshold() with threshold > MAX_VALID_LIQUIDATION_THRESHOLD (revert expected)
    #[expected_failure(abort_code = 64, location = aave_config::reserve_config)]
    fun test_set_liquidation_threshold_expected_failure() {
        let reserve_config = init();
        assert!(get_liquidation_threshold(&reserve_config) == ZERO, SUCCESS);

        set_liquidation_threshold(
            &mut reserve_config, get_max_valid_liquidation_threshold() + 1
        );
        assert!(get_liquidation_threshold(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_decimals() with decimals = MAX_VALID_DECIMALS
    fun test_set_decimals() {
        let reserve_config = init();
        check_params(&reserve_config, ZERO, ZERO);
        assert!(get_decimals(&reserve_config) == ZERO, SUCCESS);

        set_decimals(&mut reserve_config, get_max_valid_decimals());
        check_params(&reserve_config, ENUM_DECIMALS, get_max_valid_decimals());
        assert!(get_decimals(&reserve_config) == get_max_valid_decimals(), SUCCESS);

        set_decimals(&mut reserve_config, ZERO);
        check_params(&reserve_config, ENUM_DECIMALS, ZERO);
        assert!(get_decimals(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_decimals() with decimals > MAX_VALID_DECIMALS (revert expected)
    #[expected_failure(abort_code = 66, location = aave_config::reserve_config)]
    fun test_set_decimals_expected_failure() {
        let reserve_config = init();
        assert!(get_decimals(&reserve_config) == ZERO, SUCCESS);

        set_decimals(&mut reserve_config, get_max_valid_decimals() + 1);
        assert!(get_decimals(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_emode_category() with categoryID = MAX_VALID_EMODE_CATEGORY
    fun test_set_emode_category() {
        let reserve_config = init();
        assert!(get_emode_category(&reserve_config) == ZERO, SUCCESS);

        set_emode_category(&mut reserve_config, get_max_valid_emode_category());
        assert!(
            get_emode_category(&reserve_config) == get_max_valid_emode_category(),
            SUCCESS
        );

        set_emode_category(&mut reserve_config, ZERO);
        assert!(get_emode_category(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_emode_category() with category_id > MAX_VALID_EMODE_CATEGORY (revert expected)
    #[expected_failure(abort_code = 71, location = aave_config::reserve_config)]
    fun test_set_emode_category_expected_failure() {
        let reserve_config = init();
        assert!(get_emode_category(&reserve_config) == ZERO, SUCCESS);

        set_emode_category(&mut reserve_config, get_max_valid_decimals() + 1);
        assert!(get_emode_category(&reserve_config) == ZERO, SUCCESS);
    }

    #[test]
    // set_liquidation_protocol_fee() with liquidation_protocol_fee == MAX_VALID_LIQUIDATION_PROTOCOL_FEE
    fun test_set_liquidation_protocol_fee() {
        let reserve_config = init();
        assert!(get_liquidation_protocol_fee(&reserve_config) == ZERO, SUCCESS);

        set_liquidation_protocol_fee(
            &mut reserve_config, get_max_valid_liquidation_protocol_fee()
        );
        assert!(
            get_liquidation_protocol_fee(&reserve_config)
                == get_max_valid_liquidation_protocol_fee(),
            SUCCESS
        );
    }

    #[test]
    // setLiquidationProtocolFee() with liquidationProtocolFee > MAX_VALID_LIQUIDATION_PROTOCOL_FEE (revert expected)
    #[expected_failure(abort_code = 70, location = aave_config::reserve_config)]
    fun test_set_liquidation_protocol_fee_expected_failure() {
        let reserve_config = init();
        assert!(get_liquidation_protocol_fee(&reserve_config) == ZERO, SUCCESS);

        set_liquidation_protocol_fee(
            &mut reserve_config, get_max_valid_liquidation_protocol_fee() + 1
        );
        assert!(get_liquidation_protocol_fee(&reserve_config) == ZERO, SUCCESS);
    }
}
