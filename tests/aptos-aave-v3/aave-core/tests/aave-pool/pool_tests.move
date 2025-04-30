#[test_only]
module aave_pool::pool_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::option::Option;
    use std::signer::Self;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;

    use aave_acl::acl_manage::Self;
    use aave_config::reserve_config::{
        get_active,
        get_borrow_cap,
        get_borrowable_in_isolation,
        get_borrowing_enabled,
        get_debt_ceiling,
        get_decimals,
        get_emode_category,
        get_flash_loan_enabled,
        get_frozen,
        get_liquidation_bonus,
        get_liquidation_protocol_fee,
        get_liquidation_threshold,
        get_ltv,
        get_paused,
        get_reserve_factor,
        get_siloed_borrowing,
        get_supply_cap,
        get_unbacked_mint_cap,
        init,
        set_active,
        set_borrow_cap,
        set_borrowable_in_isolation,
        set_borrowing_enabled,
        set_debt_ceiling,
        set_decimals,
        set_emode_category,
        set_flash_loan_enabled,
        set_frozen,
        set_liquidation_bonus,
        set_liquidation_protocol_fee,
        set_liquidation_threshold,
        set_ltv,
        set_paused,
        set_reserve_factor,
        set_siloed_borrowing,
        set_supply_cap,
        set_unbacked_mint_cap
    };
    use aave_config::user_config::{
        is_borrowing,
        is_borrowing_any,
        is_borrowing_one,
        is_empty,
        is_using_as_collateral,
        is_using_as_collateral_any,
        is_using_as_collateral_one,
        is_using_as_collateral_or_borrowing,
        set_borrowing,
        set_using_as_collateral
    };
    use aave_math::wad_ray_math;
    use aave_rate::default_reserve_interest_rate_strategy;
    use aave_rate::interest_rate_strategy;
    use aave_pool::a_token_factory::Self;
    use aave_pool::collector;
    use aave_pool::mock_underlying_token_factory::Self;
    use aave_pool::pool::{
        get_bridge_protocol_fee,
        get_flashloan_premium_to_protocol,
        get_flashloan_premium_total,
        get_reserve_a_token_address,
        get_reserve_accrued_to_treasury,
        get_reserve_address_by_id,
        get_reserve_configuration,
        get_reserve_configuration_by_reserve_data,
        get_reserve_current_liquidity_rate,
        get_reserve_current_variable_borrow_rate,
        get_reserve_data,
        get_reserve_data_and_reserves_count,
        get_reserve_id,
        get_reserve_isolation_mode_total_debt,
        get_reserve_liquidity_index,
        get_reserve_unbacked,
        get_reserve_variable_borrow_index,
        get_reserve_variable_debt_token_address,
        get_reserves_count,
        get_reserves_list,
        get_user_configuration,
        ReserveInitialized,
        set_bridge_protocol_fee,
        set_reserve_accrued_to_treasury,
        set_reserve_current_liquidity_rate_for_testing,
        set_reserve_current_variable_borrow_rate_for_testing,
        set_reserve_isolation_mode_total_debt,
        set_reserve_liquidity_index_for_testing,
        set_reserve_unbacked,
        set_reserve_variable_borrow_index_for_testing,
        set_user_configuration,
        test_init_reserve,
        test_set_reserve_configuration,
        update_flashloan_premiums
    };
    use aave_pool::pool_configurator;
    use aave_pool::token_base::Self;
    use aave_pool::variable_debt_token_factory::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;
    const TEST_ASSETS_COUNT: u8 = 3;

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            underlying_tokens = @underlying_tokens
        )
    ]
    fun test_default_state(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens: &signer
    ) {
        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init collector
        collector::init_module_test(aave_pool);
        let collector_address = collector::collector_address();

        // init token base (a tokens and var tokens)
        token_base::test_init_module(aave_pool);

        // init a token factory
        a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        variable_debt_token_factory::test_init_module(aave_pool);

        // init underlying tokens
        mock_underlying_token_factory::test_init_module(aave_pool);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        assert!(pool_configurator::get_revision() == 1, TEST_SUCCESS);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // create underlyings
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        for (i in 0..TEST_ASSETS_COUNT) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 6;
            let max_supply = 10000;
            mock_underlying_token_factory::create_token(
                underlying_tokens,
                max_supply,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b"")
            );

            let underlying_token_address =
                mock_underlying_token_factory::token_address(symbol);

            // init the default interest rate strategy for the underlying_token_address
            let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
            let base_variable_borrow_rate: u256 = 0;
            let variable_rate_slope1: u256 = 0;
            let variable_rate_slope2: u256 = 0;
            default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(
                aave_pool,
                underlying_token_address,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );

            vector::push_back(&mut underlying_assets, underlying_token_address);
            vector::push_back(&mut underlying_asset_decimals, decimals);
            vector::push_back(&mut treasuries, collector_address);
            vector::push_back(
                &mut atokens_names, string_utils::format1(&b"APTOS_A_TOKEN_{}", i)
            );
            vector::push_back(&mut atokens_symbols, string_utils::format1(&b"A_{}", i));
            vector::push_back(
                &mut var_tokens_names, string_utils::format1(&b"APTOS_VAR_TOKEN_{}", i)
            );
            vector::push_back(
                &mut var_tokens_symbols, string_utils::format1(&b"V_{}", i)
            );
        };

        // create pool reserves
        pool_configurator::init_reserves(
            aave_pool,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols
        );
        // check emitted events
        let emitted_events = emitted_events<ReserveInitialized>();
        // make sure event of type was emitted
        assert!(
            vector::length(&emitted_events) == (TEST_ASSETS_COUNT as u64), TEST_SUCCESS
        );
        // test reserves count
        assert!(get_reserves_count() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        // get the reserve config for the first underlying and assert
        let underlying_asset_addr = *vector::borrow(&underlying_assets, 0);
        let underlying_asset_decimals = *vector::borrow(&underlying_asset_decimals, 0);
        let reserve_config_map = get_reserve_configuration(underlying_asset_addr);

        // test reserve config
        assert!(get_ltv(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_liquidation_threshold(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_liquidation_bonus(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(
            get_decimals(&reserve_config_map) == (underlying_asset_decimals as u256),
            TEST_SUCCESS
        );
        assert!(get_active(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(get_frozen(&reserve_config_map) == false, TEST_SUCCESS);
        assert!(get_paused(&reserve_config_map) == false, TEST_SUCCESS);
        assert!(get_borrowable_in_isolation(&reserve_config_map) == false, TEST_SUCCESS);
        assert!(get_siloed_borrowing(&reserve_config_map) == false, TEST_SUCCESS);
        assert!(get_borrowing_enabled(&reserve_config_map) == false, TEST_SUCCESS);
        assert!(get_reserve_factor(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_borrow_cap(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_supply_cap(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_debt_ceiling(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_liquidation_protocol_fee(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_unbacked_mint_cap(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_emode_category(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(get_flash_loan_enabled(&reserve_config_map) == false, TEST_SUCCESS);

        // get the reserve data
        let reserve_data = get_reserve_data(underlying_asset_addr);
        let reserve_config = get_reserve_configuration_by_reserve_data(&reserve_data);
        assert!(reserve_config_map == reserve_config, TEST_SUCCESS);
        let (reserve_data1, count) =
            get_reserve_data_and_reserves_count(underlying_asset_addr);
        assert!(count == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);
        let reserve_id = get_reserve_id(&reserve_data);
        let reserve_data2 = get_reserve_address_by_id((reserve_id as u256));
        // assert counts
        assert!(reserve_data == reserve_data1, TEST_SUCCESS);
        assert!(reserve_data2 == underlying_asset_addr, TEST_SUCCESS);
        assert!(count == get_reserves_count(), TEST_SUCCESS);
        // assert reserves list
        let reserves_list = get_reserves_list();
        assert!(vector::length(&reserves_list) == (TEST_ASSETS_COUNT as u64), TEST_SUCCESS);
        assert!(vector::contains(&reserves_list, &underlying_asset_addr), TEST_SUCCESS);

        // test reserve data
        let a_token_symbol = *vector::borrow(&atokens_symbols, 0);
        let a_token_address =
            a_token_factory::token_address(
                signer::address_of(aave_pool), a_token_symbol
            );

        let var_token_symbol = *vector::borrow(&var_tokens_symbols, 0);
        let var_token_address =
            variable_debt_token_factory::token_address(
                signer::address_of(aave_pool), var_token_symbol
            );
        assert!(
            get_reserve_a_token_address(&reserve_data) == a_token_address, TEST_SUCCESS
        );
        assert!(get_reserve_accrued_to_treasury(&reserve_data) == 0, TEST_SUCCESS);
        assert!(
            get_reserve_variable_borrow_index(&reserve_data)
                == (wad_ray_math::ray() as u128),
            TEST_SUCCESS
        );
        assert!(
            get_reserve_liquidity_index(&reserve_data) == (wad_ray_math::ray() as u128),
            TEST_SUCCESS
        );
        assert!(get_reserve_current_liquidity_rate(&reserve_data) == 0, TEST_SUCCESS);
        assert!(
            get_reserve_current_variable_borrow_rate(&reserve_data) == 0, TEST_SUCCESS
        );
        assert!(
            get_reserve_variable_debt_token_address(&reserve_data) == var_token_address,
            TEST_SUCCESS
        );
        assert!(get_reserve_unbacked(&reserve_data) == 0, TEST_SUCCESS);
        assert!(get_reserve_isolation_mode_total_debt(&reserve_data) == 0, TEST_SUCCESS);

        // test default extended config
        assert!(get_flashloan_premium_total() == 0, TEST_SUCCESS);
        assert!(get_bridge_protocol_fee() == 0, TEST_SUCCESS);
        assert!(get_flashloan_premium_to_protocol() == 0, TEST_SUCCESS);

        // test default user config
        let random_user = @0x42;
        let user_config_map = get_user_configuration(random_user);
        assert!(is_empty(&user_config_map), TEST_SUCCESS);
        assert!(!is_borrowing_any(&user_config_map), TEST_SUCCESS);
        assert!(!is_using_as_collateral_any(&user_config_map), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            underlying_tokens = @underlying_tokens
        )
    ]
    fun test_modified_state(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens: &signer
    ) {
        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init collector
        collector::init_module_test(aave_pool);
        let collector_address = collector::collector_address();

        // init token base (a tokens and var tokens)
        token_base::test_init_module(aave_pool);

        // init a token factory
        a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        variable_debt_token_factory::test_init_module(aave_pool);

        // init underlying tokens
        mock_underlying_token_factory::test_init_module(aave_pool);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        assert!(pool_configurator::get_revision() == 1, TEST_SUCCESS);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // create underlyings
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        for (i in 0..TEST_ASSETS_COUNT) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 2 + i;
            let max_supply = 10000;
            mock_underlying_token_factory::create_token(
                underlying_tokens,
                max_supply,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b"")
            );

            let underlying_token_address =
                mock_underlying_token_factory::token_address(symbol);

            // init the default interest rate strategy for the underlying_token_address
            let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
            let base_variable_borrow_rate: u256 = 0;
            let variable_rate_slope1: u256 = 0;
            let variable_rate_slope2: u256 = 0;
            default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(
                aave_pool,
                underlying_token_address,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );

            vector::push_back(&mut underlying_assets, underlying_token_address);
            vector::push_back(&mut underlying_asset_decimals, decimals);
            vector::push_back(&mut treasuries, collector_address);
            vector::push_back(
                &mut atokens_names, string_utils::format1(&b"APTOS_A_TOKEN_{}", i)
            );
            vector::push_back(&mut atokens_symbols, string_utils::format1(&b"A_{}", i));
            vector::push_back(
                &mut var_tokens_names, string_utils::format1(&b"APTOS_VAR_TOKEN_{}", i)
            );
            vector::push_back(
                &mut var_tokens_symbols, string_utils::format1(&b"V_{}", i)
            );
        };

        // create pool reserves
        pool_configurator::init_reserves(
            aave_pool,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols
        );

        // get tokens data
        let underlying_asset_addr = *vector::borrow(&underlying_assets, 0);
        let a_token_symbol = *vector::borrow(&atokens_symbols, 0);
        let a_token_address =
            a_token_factory::token_address(
                signer::address_of(aave_pool), a_token_symbol
            );

        let var_token_symbol = *vector::borrow(&var_tokens_symbols, 0);
        let var_token_address =
            variable_debt_token_factory::token_address(
                signer::address_of(aave_pool), var_token_symbol
            );

        // test reserve config
        let reserve_config_new = init();
        set_ltv(&mut reserve_config_new, 100);
        set_liquidation_threshold(&mut reserve_config_new, 101);
        set_liquidation_bonus(&mut reserve_config_new, 102);
        set_decimals(&mut reserve_config_new, 103);
        set_active(&mut reserve_config_new, true);
        set_frozen(&mut reserve_config_new, true);
        set_paused(&mut reserve_config_new, true);
        set_borrowable_in_isolation(&mut reserve_config_new, true);
        set_siloed_borrowing(&mut reserve_config_new, true);
        set_borrowing_enabled(&mut reserve_config_new, true);
        set_reserve_factor(&mut reserve_config_new, 104);
        set_borrow_cap(&mut reserve_config_new, 105);
        set_supply_cap(&mut reserve_config_new, 106);
        set_debt_ceiling(&mut reserve_config_new, 107);
        set_liquidation_protocol_fee(&mut reserve_config_new, 108);
        set_unbacked_mint_cap(&mut reserve_config_new, 109);
        set_emode_category(&mut reserve_config_new, 110);
        set_flash_loan_enabled(&mut reserve_config_new, true);

        // set the reserve configuration
        test_set_reserve_configuration(underlying_asset_addr, reserve_config_new);

        let reserve_data = get_reserve_data(underlying_asset_addr);
        let reserve_config_map = get_reserve_configuration_by_reserve_data(&reserve_data);

        assert!(get_ltv(&reserve_config_map) == 100, TEST_SUCCESS);
        assert!(get_liquidation_threshold(&reserve_config_map) == 101, TEST_SUCCESS);
        assert!(get_liquidation_bonus(&reserve_config_map) == 102, TEST_SUCCESS);
        assert!(get_decimals(&reserve_config_map) == 103, TEST_SUCCESS);
        assert!(get_active(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(get_frozen(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(get_paused(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(get_borrowable_in_isolation(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(get_siloed_borrowing(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(get_borrowing_enabled(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(get_reserve_factor(&reserve_config_map) == 104, TEST_SUCCESS);
        assert!(get_borrow_cap(&reserve_config_map) == 105, TEST_SUCCESS);
        assert!(get_supply_cap(&reserve_config_map) == 106, TEST_SUCCESS);
        assert!(get_debt_ceiling(&reserve_config_map) == 107, TEST_SUCCESS);
        assert!(get_liquidation_protocol_fee(&reserve_config_map) == 108, TEST_SUCCESS);
        assert!(get_unbacked_mint_cap(&reserve_config_map) == 109, TEST_SUCCESS);
        assert!(get_emode_category(&reserve_config_map) == 110, TEST_SUCCESS);
        assert!(get_flash_loan_enabled(&reserve_config_map) == true, TEST_SUCCESS);

        // test reserve data
        set_reserve_isolation_mode_total_debt(
            underlying_asset_addr, &mut reserve_data, 200
        );
        set_reserve_unbacked(underlying_asset_addr, &mut reserve_data, 201);
        set_reserve_current_variable_borrow_rate_for_testing(underlying_asset_addr, 202);
        set_reserve_current_liquidity_rate_for_testing(underlying_asset_addr, 204);
        set_reserve_liquidity_index_for_testing(underlying_asset_addr, 205);
        set_reserve_variable_borrow_index_for_testing(underlying_asset_addr, 206);
        set_reserve_accrued_to_treasury(underlying_asset_addr, &mut reserve_data, 207);
        let reserve_data = get_reserve_data(underlying_asset_addr);
        assert!(
            get_reserve_isolation_mode_total_debt(&reserve_data) == 200, TEST_SUCCESS
        );
        assert!(get_reserve_unbacked(&reserve_data) == 201, TEST_SUCCESS);
        assert!(
            get_reserve_current_variable_borrow_rate(&reserve_data) == 202,
            TEST_SUCCESS
        );
        assert!(get_reserve_current_liquidity_rate(&reserve_data) == 204, TEST_SUCCESS);
        assert!(get_reserve_liquidity_index(&reserve_data) == 205, TEST_SUCCESS);
        assert!(get_reserve_variable_borrow_index(&reserve_data) == 206, TEST_SUCCESS);
        assert!(get_reserve_accrued_to_treasury(&reserve_data) == 207, TEST_SUCCESS);
        assert!(
            get_reserve_a_token_address(&reserve_data) == a_token_address, TEST_SUCCESS
        );
        assert!(
            get_reserve_variable_debt_token_address(&reserve_data) == var_token_address,
            TEST_SUCCESS
        );

        // test reserve extended config
        update_flashloan_premiums(1000, 2000);
        assert!(get_flashloan_premium_total() == 1000, TEST_SUCCESS);
        assert!(get_flashloan_premium_to_protocol() == 2000, TEST_SUCCESS);
        set_bridge_protocol_fee(4000);
        assert!(get_bridge_protocol_fee() == 4000, TEST_SUCCESS);

        // test reserve user config
        let random_user = @0x42;
        let reserve_index = get_reserve_id(&reserve_data);
        let user_config_map = get_user_configuration(random_user);
        set_borrowing(&mut user_config_map, (reserve_index as u256), true);
        set_using_as_collateral(&mut user_config_map, (reserve_index as u256), true);
        set_user_configuration(random_user, user_config_map);
        assert!(
            is_borrowing(&user_config_map, (reserve_index as u256)) == true, TEST_SUCCESS
        );
        assert!(is_borrowing_any(&user_config_map) == true, TEST_SUCCESS);
        assert!(is_borrowing_one(&user_config_map) == true, TEST_SUCCESS);
        assert!(
            is_using_as_collateral_or_borrowing(&user_config_map, (reserve_index as u256))
                == true,
            TEST_SUCCESS
        );
        assert!(
            is_using_as_collateral(&user_config_map, (reserve_index as u256)) == true,
            TEST_SUCCESS
        );
        assert!(is_using_as_collateral_any(&user_config_map) == true, TEST_SUCCESS);
        assert!(is_using_as_collateral_one(&user_config_map) == true, TEST_SUCCESS);
        assert!(
            is_using_as_collateral_or_borrowing(&user_config_map, (reserve_index as u256))
                == true,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            underlying_tokens = @underlying_tokens
        )
    ]
    fun test_add_drop_reserves(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens: &signer
    ) {
        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init collector
        collector::init_module_test(aave_pool);
        let collector_address = collector::collector_address();

        // init token base (a tokens and var tokens)
        token_base::test_init_module(aave_pool);

        // init a token factory
        a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        variable_debt_token_factory::test_init_module(aave_pool);

        // init underlying tokens
        mock_underlying_token_factory::test_init_module(aave_pool);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        assert!(pool_configurator::get_revision() == 1, TEST_SUCCESS);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // create underlyings
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let num_reserves = 3;
        for (i in 0..num_reserves) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 2 + i;
            let max_supply = 10000;
            mock_underlying_token_factory::create_token(
                underlying_tokens,
                max_supply,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b"")
            );

            let underlying_token_address =
                mock_underlying_token_factory::token_address(symbol);

            // init the default interest rate strategy for the underlying_token_address
            let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
            let base_variable_borrow_rate: u256 = 0;
            let variable_rate_slope1: u256 = 0;
            let variable_rate_slope2: u256 = 0;
            default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(
                aave_pool,
                underlying_token_address,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );

            vector::push_back(&mut underlying_assets, underlying_token_address);
            vector::push_back(&mut underlying_asset_decimals, decimals);
            vector::push_back(&mut treasuries, collector_address);
            vector::push_back(
                &mut atokens_names, string_utils::format1(&b"APTOS_A_TOKEN_{}", i)
            );
            vector::push_back(&mut atokens_symbols, string_utils::format1(&b"A_{}", i));
            vector::push_back(
                &mut var_tokens_names, string_utils::format1(&b"APTOS_VAR_TOKEN_{}", i)
            );
            vector::push_back(
                &mut var_tokens_symbols, string_utils::format1(&b"V_{}", i)
            );
        };

        // create pool reserves
        pool_configurator::init_reserves(
            aave_pool,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols
        );
        // test reserves count
        assert!(get_reserves_count() == (num_reserves as u256), TEST_SUCCESS);

        // drop some reserves
        //test_drop_reserve(*vector::borrow(&underlying_assets, 0));
        pool_configurator::drop_reserve(
            aave_pool, *vector::borrow(&underlying_assets, 0)
        );
        pool_configurator::drop_reserve(
            aave_pool, *vector::borrow(&underlying_assets, 1)
        );

        // check emitted events
        let emitted_events = emitted_events<pool_configurator::ReserveDropped>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);
    }

    public fun create_reserve_with_config(
        account: &signer,
        underlying_asset_addr: address,
        underlying_asset_decimals: u256,
        treasury: address,
        a_token_name: String,
        a_token_symbol: String,
        variable_debt_token_name: String,
        variable_debt_token_symbol: String,
        ltv: Option<u256>,
        liquidation_threshold: Option<u256>,
        liquidation_bonus: Option<u256>,
        decimals: Option<u256>,
        active: Option<bool>,
        frozen: Option<bool>,
        paused: Option<bool>,
        borrowable_in_isolation: Option<bool>,
        siloed_borrowing: Option<bool>,
        borrowing_enabled: Option<bool>,
        reserve_factor: Option<u256>,
        borrow_cap: Option<u256>,
        supply_cap: Option<u256>,
        debt_ceiling: Option<u256>,
        liquidation_protocol_fee: Option<u256>,
        unbacked_mint_cap: Option<u256>,
        e_mode_category: Option<u256>,
        flash_loan_enabled: Option<bool>
    ): u256 {
        // create a brand new reserve
        test_init_reserve(
            account,
            underlying_asset_addr,
            treasury,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol
        );

        // create reserve configuration
        let reserve_config_new = init();
        set_ltv(&mut reserve_config_new, option::get_with_default(&ltv, 100));
        set_liquidation_threshold(
            &mut reserve_config_new,
            option::get_with_default(&liquidation_threshold, 101)
        );
        set_liquidation_bonus(
            &mut reserve_config_new, option::get_with_default(&liquidation_bonus, 102)
        );
        set_decimals(&mut reserve_config_new, option::get_with_default(&decimals, 103));
        set_active(&mut reserve_config_new, option::get_with_default(&active, true));
        set_frozen(&mut reserve_config_new, option::get_with_default(&frozen, false));
        set_paused(&mut reserve_config_new, option::get_with_default(&paused, false));
        set_borrowable_in_isolation(
            &mut reserve_config_new,
            option::get_with_default(&borrowable_in_isolation, false)
        );
        set_siloed_borrowing(
            &mut reserve_config_new, option::get_with_default(&siloed_borrowing, false)
        );
        set_borrowing_enabled(
            &mut reserve_config_new,
            option::get_with_default(&borrowing_enabled, false)
        );
        set_reserve_factor(
            &mut reserve_config_new, option::get_with_default(&reserve_factor, 104)
        );
        set_borrow_cap(
            &mut reserve_config_new, option::get_with_default(&borrow_cap, 105)
        );
        set_supply_cap(
            &mut reserve_config_new, option::get_with_default(&supply_cap, 106)
        );
        set_debt_ceiling(
            &mut reserve_config_new, option::get_with_default(&debt_ceiling, 107)
        );
        set_liquidation_protocol_fee(
            &mut reserve_config_new,
            option::get_with_default(&liquidation_protocol_fee, 108)
        );
        set_unbacked_mint_cap(
            &mut reserve_config_new, option::get_with_default(&unbacked_mint_cap, 109)
        );
        set_emode_category(
            &mut reserve_config_new, option::get_with_default(&e_mode_category, 0)
        );
        set_flash_loan_enabled(
            &mut reserve_config_new,
            option::get_with_default(&flash_loan_enabled, true)
        );

        // set the reserve configuration
        test_set_reserve_configuration(underlying_asset_addr, reserve_config_new);

        let reserve_data = get_reserve_data(underlying_asset_addr);

        (get_reserve_liquidity_index(&reserve_data) as u256)
    }

    public fun create_user_config_for_reserve(
        user: address,
        reserve_index: u256,
        is_borrowing: Option<bool>,
        is_using_as_collateral: Option<bool>
    ) {
        let user_config_map = get_user_configuration(user);
        set_borrowing(
            &mut user_config_map,
            reserve_index,
            option::get_with_default(&is_borrowing, false)
        );
        set_using_as_collateral(
            &mut user_config_map,
            reserve_index,
            option::get_with_default(&is_using_as_collateral, false)
        );
        // set the user configuration
        set_user_configuration(user, user_config_map);
    }
}
