#[test_only]
module aave_pool::emode_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option::Self;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aave_acl::acl_manage;
    use aave_math::wad_ray_math;
    use aave_rate::default_reserve_interest_rate_strategy;
    use aave_rate::interest_rate_strategy;
    use aave_pool::a_token_factory;
    use aave_pool::collector;
    use aave_pool::emode_logic::{
        configure_emode_category,
        get_emode_category_data,
        get_emode_category_liquidation_bonus,
        get_emode_category_liquidation_threshold,
        get_emode_category_price_source,
        get_emode_configuration,
        get_user_emode,
        init_emode,
        is_in_emode_category,
        set_user_emode,
        UserEModeSet
    };
    use aave_pool::mock_underlying_token_factory;
    use aave_pool::pool::{get_reserve_data, get_reserve_id};
    use aave_pool::pool_configurator;
    use aave_pool::pool_tests::create_user_config_for_reserve;
    use aave_pool::token_base;
    use aave_pool::variable_debt_token_factory;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(pool = @aave_pool)]
    #[expected_failure(abort_code = 16)]
    fun zero_emode_id_failure(pool: &signer) {
        // init the emode
        init_emode(pool);

        // configure an illegal emode category
        let id: u8 = 0;
        let ltv: u16 = 100;
        let liquidation_threshold: u16 = 200;
        let liquidation_bonus: u16 = 300;
        let price_source: address = @0x01;
        let label = utf8(b"MODE1");
        configure_emode_category(
            id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            price_source,
            label
        );
    }

    #[test(pool = @aave_pool)]
    fun get_nonexisting_emode_category(pool: &signer) {
        // init the emode
        init_emode(pool);

        // get an non-existing emode category
        let id: u8 = 3;
        let (ltv, liquidation_threshold, emode_asset_price) = get_emode_configuration(id);
        assert!(ltv == 0, TEST_SUCCESS);
        assert!(liquidation_threshold == 0, TEST_SUCCESS);
        assert!(emode_asset_price == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform
        )
    ]
    fun test_emode_config(
        aave_pool: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer
    ) {
        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init the emode
        init_emode(aave_pool);

        // configure and assert two emode categories
        let id1: u8 = 1;
        let ltv1: u16 = 100;
        let liquidation_threshold1: u16 = 200;
        let liquidation_bonus1: u16 = 300;
        let price_source1: address = signer::address_of(aave_oracle);
        let label1 = utf8(b"MODE1");
        configure_emode_category(
            id1,
            ltv1,
            liquidation_threshold1,
            liquidation_bonus1,
            price_source1,
            label1
        );
        let emode_data1 = get_emode_category_data(id1);
        assert!(
            get_emode_category_liquidation_bonus(&emode_data1) == liquidation_bonus1,
            TEST_SUCCESS
        );
        assert!(
            get_emode_category_liquidation_threshold(&emode_data1)
                == liquidation_threshold1,
            TEST_SUCCESS
        );
        assert!(get_emode_category_price_source(&emode_data1) == @0x0, TEST_SUCCESS);
        let (ltv, liquidation_threshold, _emode_asset_price) =
            get_emode_configuration(id1);
        assert!(ltv == (ltv1 as u256), TEST_SUCCESS);
        assert!(liquidation_threshold == (liquidation_threshold1 as u256), TEST_SUCCESS);

        let id2: u8 = 2;
        let ltv2: u16 = 101;
        let liquidation_threshold2: u16 = 201;
        let liquidation_bonus2: u16 = 301;
        let price_source2: address = signer::address_of(aave_oracle);
        let label2 = utf8(b"MODE2");
        configure_emode_category(
            id2,
            ltv2,
            liquidation_threshold2,
            liquidation_bonus2,
            price_source2,
            label2
        );
        let emode_data2 = get_emode_category_data(id2);
        assert!(
            get_emode_category_liquidation_bonus(&emode_data2) == liquidation_bonus2,
            TEST_SUCCESS
        );
        assert!(
            get_emode_category_liquidation_threshold(&emode_data2)
                == liquidation_threshold2,
            TEST_SUCCESS
        );
        assert!(get_emode_category_price_source(&emode_data2) == @0x0, TEST_SUCCESS);
        let (ltv, liquidation_threshold, _emode_asset_price) =
            get_emode_configuration(id2);
        assert!(ltv == (ltv2 as u256), TEST_SUCCESS);
        assert!(liquidation_threshold == (liquidation_threshold2 as u256), TEST_SUCCESS);
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
            user = @0x042
        )
    ]
    fun test_legitimate_user_emode(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

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

        // create underlyings
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

            // create the underlying token
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

            // prepare a and var tokens
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

        // define an emode cat for reserve and user
        let emode_cat_id: u8 = 1;
        // configure an emode category
        let ltv: u16 = 100;
        let liquidation_threshold: u16 = 200;
        let liquidation_bonus: u16 = 300;
        let price_source: address = signer::address_of(aave_oracle);
        let label = utf8(b"MODE1");
        configure_emode_category(
            emode_cat_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            price_source,
            label
        );

        // get the reserve config
        let underlying_asset_addr = *vector::borrow(&underlying_assets, 0);
        let reserve_data = get_reserve_data(underlying_asset_addr);
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_asset_addr, emode_cat_id
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(user),
            (get_reserve_id(&reserve_data) as u256),
            option::some(true),
            option::some(true)
        );

        // set user emode
        set_user_emode(user, emode_cat_id);

        // get and assert user emode
        let user_emode = get_user_emode(signer::address_of(user));
        assert!(user_emode == (emode_cat_id as u256), TEST_SUCCESS);

        assert!(is_in_emode_category(user_emode, (emode_cat_id as u256)), TEST_SUCCESS);
        assert!(
            !is_in_emode_category(user_emode, (emode_cat_id + 1 as u256)), TEST_SUCCESS
        );

        // check emitted events
        let emitted_events = emitted_events<UserEModeSet>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
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
            user = @0x042
        )
    ]
    #[expected_failure(abort_code = 58)]
    fun test_user_emode_with_non_existing_user_emode(
        aave_pool: &signer,
        aave_rate: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

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

        // create underlyings
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

            // prep a and var tokens
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

        // define an emode cat for reserve and user
        let emode_cat_id: u8 = 1;
        // configure an emode category
        let ltv: u16 = 100;
        let liquidation_threshold: u16 = 200;
        let liquidation_bonus: u16 = 300;
        let price_source: address = signer::address_of(aave_oracle);
        let label = utf8(b"MODE1");
        configure_emode_category(
            emode_cat_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            price_source,
            label
        );

        // get the reserve config
        let underlying_asset_addr = *vector::borrow(&underlying_assets, 0);
        let reserve_data = get_reserve_data(underlying_asset_addr);
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_asset_addr, emode_cat_id
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(user),
            (get_reserve_id(&reserve_data) as u256),
            option::some(true),
            option::some(true)
        );

        // set user emode
        let non_existing_emode_id = emode_cat_id + 1;
        set_user_emode(user, non_existing_emode_id);
    }
}
