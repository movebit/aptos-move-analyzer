#[test_only]
module aave_pool::borrow_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option::Self;
    use std::signer;
    use std::string::{utf8, String};
    use std::vector;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::{set_time_has_started_for_testing};
    use aave_acl::acl_manage::Self;
    use aave_config::reserve_config;
    use aave_config::user_config::is_using_as_collateral_or_borrowing;
    use aave_math::wad_ray_math;
    use aave_rate::default_reserve_interest_rate_strategy::Self;
    use aave_rate::interest_rate_strategy;
    use aave_pool::a_token_factory::Self;
    use aave_pool::borrow_logic::Self;
    use aave_pool::collector;
    use aave_pool::mock_underlying_token_factory::Self;
    use aave_pool::pool::{
        get_reserve_data,
        get_reserve_id,
        get_reserve_liquidity_index,
        get_user_configuration,
        test_set_reserve_configuration
    };
    use aave_pool::pool_configurator;
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
            supply_user = @0x042,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    /// Reserve allows borrowing and being used as collateral.
    /// User config allows only borrowing for the reserve.
    /// User supplies and withdraws parts of the supplied amount
    fun test_supply_borrow(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        aptos_std: &signer,
        supply_user: &signer,
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
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
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
        let underlying_assets_symbols: vector<String> = vector[];
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
            vector::push_back(&mut underlying_assets_symbols, symbol);
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
            reserve_config::set_ltv(&mut reserve_config_new, 5000); // NOTE: set ltv
            reserve_config::set_debt_ceiling(&mut reserve_config_new, 0); // NOTE: set no debt_ceiling
            reserve_config::set_borrowable_in_isolation(&mut reserve_config_new, false); // NOTE: no borrowing in isolation
            reserve_config::set_siloed_borrowing(&mut reserve_config_new, false); // NOTE: no siloed borrowing
            reserve_config::set_flash_loan_enabled(&mut reserve_config_new, false); // NOTE: no flashloans
            reserve_config::set_borrowing_enabled(&mut reserve_config_new, true); // NOTE: enable borrowing
            reserve_config::set_liquidation_threshold(&mut reserve_config_new, 4000); // NOTE: enable liq. threshold
            test_set_reserve_configuration(
                *vector::borrow(&underlying_assets, (j as u64)), reserve_config_new
            );
        };

        // =============== MINT UNDERLYING FOR USER & USER SUPPLIES ================= //
        // mint 100 underlying tokens for the user
        let mint_amount = 100;
        let supplied_amount: u64 = 10;
        let supply_receiver_address = signer::address_of(supply_user);
        let mint_receiver_address = signer::address_of(supply_user);
        for (i in 0..vector::length(&underlying_assets)) {
            let underlying_token_address = *vector::borrow(&underlying_assets, i);

            // mint tokens for the user
            mock_underlying_token_factory::mint(
                underlying_tokens_admin,
                mint_receiver_address,
                mint_amount,
                underlying_token_address
            );
            let initial_user_balance =
                mock_underlying_token_factory::balance_of(
                    mint_receiver_address, underlying_token_address
                );
            // assert user balance of underlying
            assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
            // assert underlying supply
            assert!(
                mock_underlying_token_factory::supply(underlying_token_address)
                    == option::some((mint_amount as u128)),
                TEST_SUCCESS
            );

            // init user config for reserve index
            let reserve_data = get_reserve_data(underlying_token_address);

            // let user supply
            supply_logic::supply(
                supply_user,
                underlying_token_address,
                (supplied_amount as u256),
                supply_receiver_address,
                0
            );

            let user_config_map = get_user_configuration(signer::address_of(supply_user));
            assert!(
                is_using_as_collateral_or_borrowing(
                    &user_config_map, (get_reserve_id(&reserve_data) as u256)
                ),
                TEST_SUCCESS
            );

            // check supplier balance of underlying
            let supplier_balance =
                mock_underlying_token_factory::balance_of(
                    mint_receiver_address, underlying_token_address
                );
            assert!(
                supplier_balance == initial_user_balance - supplied_amount,
                TEST_SUCCESS
            );

            // check underlying supply (must not have changed)
            assert!(
                mock_underlying_token_factory::supply(underlying_token_address)
                    == option::some((mint_amount as u128)),
                TEST_SUCCESS
            );

            // check a_token underlying balance
            let a_token_address =
                a_token_factory::token_address(
                    signer::address_of(aave_pool),
                    *vector::borrow(&atokens_symbols, i)
                );
            let atoken_account_address =
                a_token_factory::get_token_account_address(a_token_address);
            let underlying_account_balance =
                mock_underlying_token_factory::balance_of(
                    atoken_account_address, underlying_token_address
                );
            assert!(underlying_account_balance == supplied_amount, TEST_SUCCESS);
            // check user a_token balance after supply
            let supplied_amount_scaled =
                wad_ray_math::ray_div(
                    (supplied_amount as u256),
                    (get_reserve_liquidity_index(&reserve_data) as u256)
                );
            let supplier_a_token_balance =
                a_token_factory::scaled_balance_of(
                    signer::address_of(supply_user), a_token_address
                );
            assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);
        };

        // register assets with oracle feed_ids
        for (i in 0..vector::length(&underlying_assets)) {
            let underlying_token_address = *vector::borrow(&underlying_assets, i);
            aave_oracle::oracle::set_asset_feed_id(
                aave_pool,
                underlying_token_address,
                aave_oracle::oracle_tests::get_test_feed_id()
            );
        };

        // =============== USER BORROWS FIRST TWO ASSETS ================= //
        // user supplies the underlying token
        let borrow_receiver_address = signer::address_of(supply_user);
        let borrowed_amount: u64 = 1;
        for (i in 0..2) {
            let underlying_token_address = *vector::borrow(&underlying_assets, i);
            borrow_logic::borrow(
                supply_user,
                underlying_token_address,
                (borrowed_amount as u256),
                2, // variable interest rate mode
                0, // referral
                borrow_receiver_address
            );
        };

        // check emitted events
        let emitted_borrow_events = emitted_events<borrow_logic::Borrow>();
        assert!(vector::length(&emitted_borrow_events) == 2, TEST_SUCCESS);
    }
}
