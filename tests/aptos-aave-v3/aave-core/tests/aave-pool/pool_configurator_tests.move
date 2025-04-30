#[test_only]
module aave_pool::pool_configurator_tests {
    use std::features::change_feature_flags_for_testing;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage;
    use aave_math::wad_ray_math;
    use aave_rate::default_reserve_interest_rate_strategy;
    use aave_rate::interest_rate_strategy;
    use aave_pool::a_token_factory::Self;
    use aave_pool::collector::Self;
    use aave_pool::mock_underlying_token_factory::Self;
    use aave_pool::pool::{get_reserves_count, ReserveInitialized};
    use aave_pool::pool_configurator::Self;
    use aave_pool::token_base;
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
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    fun test_add_reserves(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer
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
                underlying_tokens_admin,
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
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    #[expected_failure(abort_code = 5)]
    fun test_add_reserves_wrong_sender(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer
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
                underlying_tokens_admin,
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

        pool_configurator::init_reserves(
            aave_oracle,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols
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
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    #[expected_failure(abort_code = 1)]
    fun test_drop_reserves_bad_signer(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer
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
                underlying_tokens_admin,
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

        assert!(get_reserves_count() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        // drop the first reserve
        pool_configurator::drop_reserve(
            aave_oracle, *vector::borrow(&underlying_assets, 0)
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
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    #[expected_failure(abort_code = 1)]
    fun test_drop_reserves_with_0_supply(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer
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
                underlying_tokens_admin,
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
        assert!(get_reserves_count() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        // drop the first reserve
        pool_configurator::drop_reserve(
            aave_pool, *vector::borrow(&underlying_assets, 0)
        );
        // check emitted events
        let emitted_events = emitted_events<pool_configurator::ReserveDropped>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
        // test reserves count
        assert!(
            get_reserves_count() == ((TEST_ASSETS_COUNT as u256) - 1),
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_acl = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @underlying_tokens,
            caller = @0x42
        )
    ]
    #[expected_failure(abort_code = 54)]
    fun test_drop_reserves_with_nonzero_supply_atokens_failure(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(aave_acl, @aave_pool);
        acl_manage::add_pool_admin(aave_acl, @aave_pool);

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
                underlying_tokens_admin,
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
        assert!(get_reserves_count() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        // ============= MINT ATOKENS ============== //
        let a_token_symbol = *vector::borrow(&atokens_symbols, 0);
        let a_token_address =
            a_token_factory::token_address(
                signer::address_of(aave_pool), a_token_symbol
            );
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(caller),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // drop the first reserve
        pool_configurator::drop_reserve(
            aave_pool, *vector::borrow(&underlying_assets, 0)
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
            underlying_tokens_admin = @underlying_tokens,
            caller = @0x42
        )
    ]
    #[expected_failure(abort_code = 56)]
    fun test_drop_reserves_with_nonzero_supply_variable_tokens_failure(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

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
                underlying_tokens_admin,
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
        assert!(get_reserves_count() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        // ============= MINT VARIABLE TOKENS ============== //
        let var_token_symbol = *vector::borrow(&var_tokens_symbols, 0);
        let var_token_address =
            variable_debt_token_factory::token_address(
                signer::address_of(aave_pool), var_token_symbol
            );
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        variable_debt_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(caller),
            amount_to_mint,
            reserve_index,
            var_token_address
        );

        // assert var token supply
        assert!(
            variable_debt_token_factory::scaled_total_supply(var_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // drop the first reserve
        pool_configurator::drop_reserve(
            aave_pool, *vector::borrow(&underlying_assets, 0)
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            underlying_tokens = @underlying_tokens,
            aave_rate = @aave_rate
        )
    ]
    fun test_reserve_setters_getters(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens: &signer,
        aave_rate: &signer
    ) {
        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(aave_acl, @aave_pool);
        acl_manage::add_pool_admin(aave_acl, @aave_pool);

        // init collector
        collector::init_module_test(aave_pool);
        let collector_address = collector::collector_address();

        // init token base (a tokens and var tokens)
        token_base::test_init_module(aave_pool);

        // init a token factory
        aave_pool::a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        aave_pool::variable_debt_token_factory::test_init_module(aave_pool);

        // init underlyings token factory
        aave_pool::mock_underlying_token_factory::test_init_module(aave_pool);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init rates - default strategy
        aave_rate::default_reserve_interest_rate_strategy::init_interest_rate_strategy(
            aave_rate
        );

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

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

        // create reserves using the pool admin
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
    }
}
