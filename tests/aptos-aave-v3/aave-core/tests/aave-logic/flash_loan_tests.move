#[test_only]
module aave_pool::flashloan_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option::Self;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage::Self;
    use aave_config::reserve_config::Self;
    use aave_config::user_config;
    use aave_math::math_utils::get_percentage_factor;
    use aave_math::wad_ray_math;
    use aave_rate::default_reserve_interest_rate_strategy::Self;
    use aave_rate::interest_rate_strategy;
    use aave_pool::a_token_factory::Self;
    use aave_pool::collector;
    use aave_pool::flashloan_logic::Self;
    use aave_pool::mock_underlying_token_factory::Self;
    use aave_pool::pool::{
        Self,
        get_reserve_liquidity_index,
        test_set_reserve_configuration
    };
    use aave_pool::pool::{get_reserve_data, get_reserve_id};
    use aave_pool::pool_configurator;
    use aave_pool::pool_tests::create_user_config_for_reserve;
    use aave_pool::supply_logic::Self;
    use aave_pool::token_base::Self;
    use aave_pool::variable_debt_token_factory;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            flashloan_user = @0x042,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    /// User takes and repays a single asset flashloan
    fun simple_flashloan_same_payer_receiver(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_user: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_std);

        // add the test events feature flag
        change_feature_flags_for_testing(aptos_std, vector[26], vector[]);

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

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // prepare pool reserves
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let num_assets = 3;
        for (i in 0..num_assets) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 2 + i;
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

            // prepare the data for reserve's atokens and variable tokens
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

        // create reserve configurations
        for (j in 0..num_assets) {
            let reserve_config_new = reserve_config::init();
            let decimals = (
                *vector::borrow(&underlying_asset_decimals, (j as u64)) as u256
            );
            reserve_config::set_decimals(&mut reserve_config_new, decimals);
            reserve_config::set_active(&mut reserve_config_new, true);
            reserve_config::set_frozen(&mut reserve_config_new, false);
            reserve_config::set_paused(&mut reserve_config_new, false);
            reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true);
            test_set_reserve_configuration(
                *vector::borrow(&underlying_assets, (j as u64)), reserve_config_new
            );
        };

        // get one underlying asset data
        let underlying_token_address = *vector::borrow(&underlying_assets, 0);

        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128), (flashloan_premium_to_protocol as u128)
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_user),
            (get_reserve_id(&reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for the flashloan user
        // mint 100 underlying tokens for the flashloan user
        let mint_receiver_address = signer::address_of(flashloan_user);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            mint_receiver_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == 100, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // ----> flashloan user supplies
        // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_user);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check flashloan user (supplier) balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // ----> flashloan user takes a flashloan
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                flashloan_user,
                signer::address_of(flashloan_user),
                underlying_token_address,
                (flashloan_amount as u256),
                0 // referral code
            );

        // check intermediate underlying balance
        let flashloan_taker_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        assert!(
            flashloan_taker_underlying_balance == supplier_balance + flashloan_amount,
            TEST_SUCCESS
        );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(flashloan_user, flashloan_receipt);

        // check intermediate underlying balance for flashloan user
        let flashloan_taken_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_taken_underlying_balance
                == supplier_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            aptos_std = @std,
            flashloan_payer = @0x042,
            flashloan_receiver = @0x043,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    /// User takes a flashloan which is received by someone else. Either user or taker then repays a single asset flashloan
    fun simple_flashloan_different_payer_receiver(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_payer: &signer,
        flashloan_receiver: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_std);

        // add the test events feature flag
        change_feature_flags_for_testing(aptos_std, vector[26], vector[]);

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

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // prepare pool reserves
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let num_assets = 3;
        for (i in 0..num_assets) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 2 + i;
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

            // prepare the data for reserve's atokens and variable tokens
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

        // create reserve configurations
        for (j in 0..num_assets) {
            let reserve_config_new = reserve_config::init();
            let decimals = (
                *vector::borrow(&underlying_asset_decimals, (j as u64)) as u256
            );
            reserve_config::set_decimals(&mut reserve_config_new, decimals);
            reserve_config::set_active(&mut reserve_config_new, true);
            reserve_config::set_frozen(&mut reserve_config_new, false);
            reserve_config::set_paused(&mut reserve_config_new, false);
            reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true);
            test_set_reserve_configuration(
                *vector::borrow(&underlying_assets, (j as u64)), reserve_config_new
            );
        };

        // get one underlying asset data
        let underlying_token_address = *vector::borrow(&underlying_assets, 0);

        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128), (flashloan_premium_to_protocol as u128)
        );

        // init user configs for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_payer),
            (get_reserve_id(&reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        create_user_config_for_reserve(
            signer::address_of(flashloan_receiver),
            (get_reserve_id(&reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for flashloan payer and receiver
        // mint 100 underlying tokens for flashloan payer and receiver
        let mint_amount: u64 = 100;
        let users = vector[
            signer::address_of(flashloan_payer),
            signer::address_of(flashloan_receiver)
        ];
        for (i in 0..vector::length(&users)) {
            mock_underlying_token_factory::mint(
                underlying_tokens_admin,
                *vector::borrow(&users, i),
                mint_amount,
                underlying_token_address
            );
            let initial_user_balance =
                mock_underlying_token_factory::balance_of(
                    *vector::borrow(&users, i), underlying_token_address
                );
            // assert user balance of underlying
            assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
        };

        // ----> flashloan payer supplies
        // flashloan payer supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_payer);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_payer,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check flashloan payer balance of underlying
        let initial_payer_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            initial_payer_balance == mint_amount - supplied_amount,
            TEST_SUCCESS
        );
        // > check flashloan payer a_token balance after supply
        let a_token_address =
            a_token_factory::token_address(
                signer::address_of(aave_pool),
                *vector::borrow(&atokens_symbols, 0)
            );
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(flashloan_payer), a_token_address
            );
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount as u256),
                (get_reserve_liquidity_index(&reserve_data) as u256)
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);

        let initial_receiver_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );

        // ----> flashloan payer takes a flashloan but receiver is different
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                flashloan_payer,
                signer::address_of(flashloan_receiver), // now the receiver expects to receive the flashloan
                underlying_token_address,
                (flashloan_amount as u256),
                0 // referral code
            );

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS
        ); // same balance as before

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance + flashloan_amount,
            TEST_SUCCESS
        ); // increased balance due to flashloan

        // ----> receiver repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(flashloan_receiver, flashloan_receipt);

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS
        );

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            flashloan_user = @0x042,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    /// User takes and repays a single asset flashloan
    fun complex_flashloan_same_payer_receiver(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_user: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_std);

        // add the test events feature flag
        change_feature_flags_for_testing(aptos_std, vector[26], vector[]);

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

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // prepare pool reserves
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let num_assets = 3;
        for (i in 0..num_assets) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 2 + i;
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

            // prepare the data for reserve's atokens and variable tokens
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

        // create reserve configurations
        for (j in 0..num_assets) {
            let reserve_config_new = reserve_config::init();
            let decimals = (
                *vector::borrow(&underlying_asset_decimals, (j as u64)) as u256
            );
            reserve_config::set_decimals(&mut reserve_config_new, decimals);
            reserve_config::set_active(&mut reserve_config_new, true);
            reserve_config::set_frozen(&mut reserve_config_new, false);
            reserve_config::set_paused(&mut reserve_config_new, false);
            reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true);
            test_set_reserve_configuration(
                *vector::borrow(&underlying_assets, (j as u64)), reserve_config_new
            );
        };

        // get one underlying asset data
        let underlying_token_address = *vector::borrow(&underlying_assets, 0);

        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128), (flashloan_premium_to_protocol as u128)
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_user),
            (get_reserve_id(&reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for the flashloan user
        // mint 100 underlying tokens for the flashloan user
        let mint_receiver_address = signer::address_of(flashloan_user);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            mint_receiver_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == 100, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // ----> flashloan user supplies
        // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_user);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check flashloan user (supplier) balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // ----> flashloan user takes a flashloan
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                flashloan_user,
                signer::address_of(flashloan_user),
                vector[underlying_token_address],
                vector[(flashloan_amount as u256)],
                vector[user_config::get_interest_rate_mode_none()], // interest rate modes
                signer::address_of(flashloan_user),
                0 // referral code
            );

        // check intermediate underlying balance
        let flashloan_taker_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        assert!(
            flashloan_taker_underlying_balance == supplier_balance + flashloan_amount,
            TEST_SUCCESS
        );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_complex(flashloan_user, flashloan_receipts);

        // check intermediate underlying balance for flashloan user
        let flashloan_taken_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_taken_underlying_balance
                == supplier_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_flashloan_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_flashloan_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            flashloan_user = @0x042,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    /// User takes and repays a single asset flashloan being authorized
    fun complex_flashloan_same_payer_receiver_authorized(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_user: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_std);

        // add the test events feature flag
        change_feature_flags_for_testing(aptos_std, vector[26], vector[]);

        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // grant the flashloan user an authorized borrower role
        acl_manage::add_flash_borrower(
            aave_role_super_admin, signer::address_of(flashloan_user)
        );

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

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // prepare pool reserves
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let num_assets = 3;
        for (i in 0..num_assets) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 2 + i;
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

            // prepare the data for reserve's atokens and variable tokens
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

        // create reserve configurations
        for (j in 0..num_assets) {
            let reserve_config_new = reserve_config::init();
            let decimals = (
                *vector::borrow(&underlying_asset_decimals, (j as u64)) as u256
            );
            reserve_config::set_decimals(&mut reserve_config_new, decimals);
            reserve_config::set_active(&mut reserve_config_new, true);
            reserve_config::set_frozen(&mut reserve_config_new, false);
            reserve_config::set_paused(&mut reserve_config_new, false);
            reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true);
            test_set_reserve_configuration(
                *vector::borrow(&underlying_assets, (j as u64)), reserve_config_new
            );
        };

        // get one underlying asset data
        let underlying_token_address = *vector::borrow(&underlying_assets, 0);

        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128), (flashloan_premium_to_protocol as u128)
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_user),
            (get_reserve_id(&reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for the flashloan user
        // mint 100 underlying tokens for the flashloan user
        let mint_receiver_address = signer::address_of(flashloan_user);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            mint_receiver_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == 100, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // ----> flashloan user supplies
        // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_user);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check flashloan user (supplier) balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // ----> flashloan user takes a flashloan
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                flashloan_user,
                signer::address_of(flashloan_user),
                vector[underlying_token_address],
                vector[(flashloan_amount as u256)],
                vector[user_config::get_interest_rate_mode_none()], // interest rate modes
                signer::address_of(flashloan_user),
                0 // referral code
            );

        // check intermediate underlying balance
        let flashloan_taker_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        assert!(
            flashloan_taker_underlying_balance == supplier_balance + flashloan_amount,
            TEST_SUCCESS
        );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_complex(flashloan_user, flashloan_receipts);

        // check intermediate underlying balance for flashloan user
        let flashloan_taken_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        let flashloan_paid_premium = 0; // because the user is authorized flash borrower
        assert!(
            flashloan_taken_underlying_balance
                == supplier_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_flashloan_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_flashloan_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_rate = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            aptos_std = @std,
            flashloan_payer = @0x042,
            flashloan_receiver = @0x043,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    /// User takes a complex flashloan which is received by someone else. Either user or taker then repays the complex flashloan
    fun complex_flashloan_different_payer_receiver(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_payer: &signer,
        flashloan_receiver: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_std);

        // add the test events feature flag
        change_feature_flags_for_testing(aptos_std, vector[26], vector[]);

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

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init rate
        interest_rate_strategy::test_init_module(aave_rate);

        // init input data for creating pool reserves
        let treasuries: vector<address> = vector[];

        // prepare pool reserves
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let num_assets = 3;
        for (i in 0..num_assets) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 2 + i;
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

            // prepare the data for reserve's atokens and variable tokens
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

        // create reserve configurations
        for (j in 0..num_assets) {
            let reserve_config_new = reserve_config::init();
            let decimals = (
                *vector::borrow(&underlying_asset_decimals, (j as u64)) as u256
            );
            reserve_config::set_decimals(&mut reserve_config_new, decimals);
            reserve_config::set_active(&mut reserve_config_new, true);
            reserve_config::set_frozen(&mut reserve_config_new, false);
            reserve_config::set_paused(&mut reserve_config_new, false);
            reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true);
            test_set_reserve_configuration(
                *vector::borrow(&underlying_assets, (j as u64)), reserve_config_new
            );
        };

        // get one underlying asset data
        let underlying_token_address = *vector::borrow(&underlying_assets, 0);

        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128), (flashloan_premium_to_protocol as u128)
        );

        // init user configs for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_payer),
            (get_reserve_id(&reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        create_user_config_for_reserve(
            signer::address_of(flashloan_receiver),
            (get_reserve_id(&reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for flashloan payer and receiver
        // mint 100 underlying tokens for flashloan payer and receiver
        let mint_amount: u64 = 100;
        let users = vector[
            signer::address_of(flashloan_payer),
            signer::address_of(flashloan_receiver)
        ];
        for (i in 0..vector::length(&users)) {
            mock_underlying_token_factory::mint(
                underlying_tokens_admin,
                *vector::borrow(&users, i),
                mint_amount,
                underlying_token_address
            );
            let initial_user_balance =
                mock_underlying_token_factory::balance_of(
                    *vector::borrow(&users, i), underlying_token_address
                );
            // assert user balance of underlying
            assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
        };

        // ----> flashloan payer supplies
        // flashloan payer supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_payer);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_payer,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check flashloan payer balance of underlying
        let initial_payer_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            initial_payer_balance == mint_amount - supplied_amount,
            TEST_SUCCESS
        );
        // > check flashloan payer a_token balance after supply
        let a_token_address =
            a_token_factory::token_address(
                signer::address_of(aave_pool),
                *vector::borrow(&atokens_symbols, 0)
            );
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(flashloan_payer), a_token_address
            );
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount as u256),
                (get_reserve_liquidity_index(&reserve_data) as u256)
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);

        let initial_receiver_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );

        // ----> flashloan payer takes a flashloan but receiver is different
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                flashloan_payer,
                signer::address_of(flashloan_receiver),
                vector[underlying_token_address],
                vector[(flashloan_amount as u256)],
                vector[user_config::get_interest_rate_mode_none()], // interest rate modes
                signer::address_of(flashloan_payer), // on behalf of
                0 // referral code
            );

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS
        ); // same balance as before

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance + flashloan_amount,
            TEST_SUCCESS
        ); // increased balance due to flashloan

        // ----> receiver repays flashloan + premium
        flashloan_logic::pay_flash_loan_complex(flashloan_receiver, flashloan_receipts);

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS
        );

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    }
}
