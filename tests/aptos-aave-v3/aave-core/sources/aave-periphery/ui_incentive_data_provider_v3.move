module aave_pool::ui_incentive_data_provider_v3 {
    use std::string::String;
    use std::vector;
    use aptos_framework::object::{Self, Object};
    use aave_pool::rewards_controller::Self;
    use aave_pool::eac_aggregator_proxy::Self;
    use aave_pool::pool::{Self};
    use aave_pool::a_token_factory::Self;

    const EMPTY_ADDRESS: address = @0x0;

    const UI_INCENTIVE_DATA_PROVIDER_V3_NAME: vector<u8> = b"AAVE_UI_INCENTIVE_DATA_PROVIDER_V3";

    struct UiIncentiveDataProviderV3Data has key {}

    struct AggregatedReserveIncentiveData has store, drop {
        underlying_asset: address,
        a_incentive_data: IncentiveData,
        v_incentive_data: IncentiveData
    }

    struct IncentiveData has store, drop {
        token_address: address,
        incentive_controller_address: address,
        rewards_token_information: vector<RewardInfo>
    }

    struct RewardInfo has store, drop {
        reward_token_symbol: String,
        reward_token_address: address,
        reward_oracle_address: address,
        emission_per_second: u256,
        incentives_last_update_timestamp: u256,
        token_incentives_index: u256,
        emission_end_timestamp: u256,
        reward_price_feed: u256,
        reward_token_decimals: u8,
        precision: u8,
        price_feed_decimals: u8
    }

    struct UserReserveIncentiveData has store, drop {
        underlying_asset: address,
        a_token_incentives_user_data: UserIncentiveData,
        v_token_incentives_user_data: UserIncentiveData
    }

    struct UserIncentiveData has store, drop {
        token_address: address,
        incentive_controller_address: address,
        user_rewards_information: vector<UserRewardInfo>
    }

    struct UserRewardInfo has store, drop {
        reward_token_symbol: String,
        reward_oracle_address: address,
        reward_token_address: address,
        user_unclaimed_rewards: u256,
        token_incentives_user_index: u256,
        reward_price_feed: u256,
        price_feed_decimals: u8,
        reward_token_decimals: u8
    }

    fun init_module(sender: &signer) {
        let state_object_constructor_ref =
            &object::create_named_object(sender, UI_INCENTIVE_DATA_PROVIDER_V3_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            UiIncentiveDataProviderV3Data {}
        );
    }

    #[test_only]
    public fun init_module_test(sender: &signer) {
        init_module(sender);
    }

    #[view]
    public fun ui_incentive_data_provider_v3_data_address(): address {
        object::create_object_address(&@aave_pool, UI_INCENTIVE_DATA_PROVIDER_V3_NAME)
    }

    #[view]
    public fun ui_incentive_data_provider_v3_data_object():
        Object<UiIncentiveDataProviderV3Data> {
        object::address_to_object<UiIncentiveDataProviderV3Data>(
            ui_incentive_data_provider_v3_data_address()
        )
    }

    #[view]
    public fun get_full_reserves_incentive_data(
        user: address
    ): (vector<AggregatedReserveIncentiveData>, vector<UserReserveIncentiveData>) {
        (get_reserves_incentives_data(), get_user_reserves_incentives_data(user))
    }

    #[view]
    public fun get_reserves_incentives_data(): vector<AggregatedReserveIncentiveData> {
        let reserves = pool::get_reserves_list();
        let reserves_incentives_data = vector::empty<AggregatedReserveIncentiveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let base_data = pool::get_reserve_data(underlying_asset);
            let rewards_controller_address =
                rewards_controller::rewards_controller_address();
            // TODO Waiting for Chainlink oracle functionality
            let reward_oracle_address = @aave_oracle;

            if (rewards_controller_address != EMPTY_ADDRESS) {

                // ===================== a token ====================
                let a_token_address = pool::get_reserve_a_token_address(&base_data);
                let a_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        a_token_address, rewards_controller_address
                    );
                let reward_information: vector<RewardInfo> = vector[];

                for (j in 0..vector::length(&a_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&a_token_reward_addresses, j);

                    let (
                        token_incentives_index,
                        emission_per_second,
                        incentives_last_update_timestamp,
                        emission_end_timestamp
                    ) =
                        rewards_controller::get_rewards_data(
                            a_token_address,
                            reward_token_address,
                            rewards_controller_address
                        );

                    let precision =
                        rewards_controller::get_asset_decimals(
                            a_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut reward_information,
                        RewardInfo {
                            reward_token_symbol,
                            reward_token_address,
                            reward_oracle_address,
                            emission_per_second,
                            incentives_last_update_timestamp,
                            token_incentives_index,
                            emission_end_timestamp,
                            reward_price_feed,
                            reward_token_decimals,
                            precision,
                            price_feed_decimals
                        }
                    );
                };

                let a_incentive_data = IncentiveData {
                    token_address: a_token_address,
                    incentive_controller_address: rewards_controller_address,
                    rewards_token_information: reward_information
                };

                // ===================== variable debt token ====================
                let variable_debt_token_address =
                    pool::get_reserve_variable_debt_token_address(&base_data);
                let var_debt_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        variable_debt_token_address,
                        rewards_controller_address
                    );
                let reward_information: vector<RewardInfo> = vector[];

                for (j in 0..vector::length(&var_debt_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&var_debt_token_reward_addresses, j);

                    let (
                        token_incentives_index,
                        emission_per_second,
                        incentives_last_update_timestamp,
                        emission_end_timestamp
                    ) =
                        rewards_controller::get_rewards_data(
                            variable_debt_token_address,
                            reward_token_address,
                            rewards_controller_address
                        );

                    let precision =
                        rewards_controller::get_asset_decimals(
                            variable_debt_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut reward_information,
                        RewardInfo {
                            reward_token_symbol,
                            reward_token_address,
                            reward_oracle_address,
                            emission_per_second,
                            incentives_last_update_timestamp,
                            token_incentives_index,
                            emission_end_timestamp,
                            reward_price_feed,
                            reward_token_decimals,
                            precision,
                            price_feed_decimals
                        }
                    );
                };

                let v_incentive_data = IncentiveData {
                    token_address: variable_debt_token_address,
                    incentive_controller_address: rewards_controller_address,
                    rewards_token_information: reward_information
                };

                vector::push_back(
                    &mut reserves_incentives_data,
                    AggregatedReserveIncentiveData {
                        underlying_asset,
                        a_incentive_data,
                        v_incentive_data
                    }
                )
            };
        };
        reserves_incentives_data
    }

    #[view]
    public fun get_user_reserves_incentives_data(user: address):
        vector<UserReserveIncentiveData> {
        let reserves = pool::get_reserves_list();
        let user_reserves_incentives_data = vector::empty<UserReserveIncentiveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let base_data = pool::get_reserve_data(underlying_asset);
            let rewards_controller_address =
                rewards_controller::rewards_controller_address();
            // TODO Waiting for Chainlink oracle functionality
            let reward_oracle_address = @aave_oracle;

            if (rewards_controller_address != EMPTY_ADDRESS) {

                // ===================== a token ====================
                let a_token_address = pool::get_reserve_a_token_address(&base_data);
                let a_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        a_token_address, rewards_controller_address
                    );
                let user_rewards_information: vector<UserRewardInfo> = vector[];

                for (j in 0..vector::length(&a_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&a_token_reward_addresses, j);

                    let token_incentives_user_index =
                        rewards_controller::get_user_asset_index(
                            user,
                            a_token_address,
                            reward_token_address,
                            rewards_controller_address
                        );

                    let user_unclaimed_rewards =
                        rewards_controller::get_user_accrued_rewards(
                            user, reward_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut user_rewards_information,
                        UserRewardInfo {
                            reward_token_symbol,
                            reward_oracle_address,
                            reward_token_address,
                            user_unclaimed_rewards,
                            token_incentives_user_index,
                            reward_price_feed,
                            price_feed_decimals,
                            reward_token_decimals
                        }
                    );
                };

                let a_incentive_data = UserIncentiveData {
                    token_address: a_token_address,
                    incentive_controller_address: rewards_controller_address,
                    user_rewards_information
                };

                // ===================== variable debt token ====================
                let variable_debt_token_address =
                    pool::get_reserve_variable_debt_token_address(&base_data);
                let var_debt_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        variable_debt_token_address,
                        rewards_controller_address
                    );
                let user_rewards_information: vector<UserRewardInfo> = vector[];

                for (j in 0..vector::length(&var_debt_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&var_debt_token_reward_addresses, j);

                    let token_incentives_user_index =
                        rewards_controller::get_user_asset_index(
                            user,
                            variable_debt_token_address,
                            reward_token_address,
                            rewards_controller_address
                        );

                    let user_unclaimed_rewards =
                        rewards_controller::get_user_accrued_rewards(
                            user, reward_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut user_rewards_information,
                        UserRewardInfo {
                            reward_token_symbol,
                            reward_oracle_address,
                            reward_token_address,
                            user_unclaimed_rewards,
                            token_incentives_user_index,
                            reward_price_feed,
                            price_feed_decimals,
                            reward_token_decimals
                        }
                    );
                };

                let v_incentive_data = UserIncentiveData {
                    token_address: variable_debt_token_address,
                    incentive_controller_address: rewards_controller_address,
                    user_rewards_information
                };

                vector::push_back(
                    &mut user_reserves_incentives_data,
                    UserReserveIncentiveData {
                        underlying_asset,
                        a_token_incentives_user_data: a_incentive_data,
                        v_token_incentives_user_data: v_incentive_data
                    }
                )
            };
        };
        user_reserves_incentives_data
    }

    #[test_only]
    use std::signer;
    #[test_only]
    use std::string::{Self, utf8};
    #[test_only]
    use aptos_std::string_utils::{Self};

    #[test_only]
    const TEST_SUCCESS: u64 = 1;
    #[test_only]
    const TEST_FAILED: u64 = 2;

    #[test(aave_pool = @aave_pool)]
    fun test_ui_incentive_data_provider_v3_data_address(
        aave_pool: &signer
    ) {
        init_module_test(aave_pool);
        assert!(
            ui_incentive_data_provider_v3_data_address()
                == object::create_object_address(
                    &@aave_pool, UI_INCENTIVE_DATA_PROVIDER_V3_NAME
                ),
            TEST_SUCCESS
        );
    }

    #[test(aave_pool = @aave_pool)]
    fun test_ui_incentive_data_provider_v3_data_object(
        aave_pool: &signer
    ) {
        // init acl
        init_module_test(aave_pool);
        assert!(
            ui_incentive_data_provider_v3_data_object()
                == object::address_to_object<UiIncentiveDataProviderV3Data>(
                    ui_incentive_data_provider_v3_data_address()
                ),
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            underlying_tokens = @underlying_tokens,
            aave_rate = @aave_rate
        )
    ]
    fun test_get_full_reserves_incentive_data(
        aave_pool: &signer,
        aave_acl: &signer,
        underlying_tokens: &signer,
        aave_rate: &signer
    ) {
        aptos_framework::account::create_account_for_test(
            signer::address_of(aave_pool)
        );

        // init current module
        init_module_test(aave_pool);

        // init rewards controller
        aave_pool::rewards_controller::initialize(
            aave_pool, signer::address_of(aave_pool)
        );

        // init acl
        aave_acl::acl_manage::test_init_module(aave_acl);

        let role_admin = aave_acl::acl_manage::get_pool_admin_role();
        aave_acl::acl_manage::grant_role(
            aave_acl,
            aave_acl::acl_manage::get_pool_admin_role_for_testing(),
            signer::address_of(aave_pool)
        );
        aave_acl::acl_manage::grant_role(
            aave_acl,
            aave_acl::acl_manage::get_pool_admin_role_for_testing(),
            signer::address_of(aave_acl)
        );
        aave_acl::acl_manage::set_role_admin(
            aave_acl,
            aave_acl::acl_manage::get_pool_admin_role_for_testing(),
            role_admin
        );

        // init the rate module - default strategy
        aave_rate::default_reserve_interest_rate_strategy::init_interest_rate_strategy(
            aave_rate
        );

        // init tokens base
        aave_pool::token_base::test_init_module(aave_pool);

        // init a token factory
        aave_pool::a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        aave_pool::variable_debt_token_factory::test_init_module(aave_pool);

        // init underlyings token factory
        aave_pool::mock_underlying_token_factory::test_init_module(aave_pool);

        // create mocked underlying tokens
        let i = 0;
        let treasury = signer::address_of(underlying_tokens);
        let a_token_name = string::utf8(b"a");
        let a_token_symbol = string::utf8(b"a");
        let variable_debt_token_name = string::utf8(b"BTC");
        let variable_debt_token_symbol = string::utf8(b"BTC");

        let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
        let symbol = string_utils::format1(&b"U_{}", i);
        let decimals = 6;
        let max_supply = 10000;
        aave_pool::mock_underlying_token_factory::create_token(
            underlying_tokens,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );

        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;

        // create atokens
        aave_pool::a_token_factory::create_token(
            aave_pool,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset_address,
            treasury_address
        );

        let underlying_token_address =
            aave_pool::mock_underlying_token_factory::token_address(symbol);

        // init the pool
        aave_pool::pool::test_init_pool(aave_pool);

        // set reserve interest rate using the pool admin
        let optimal_usage_ratio: u256 =
            aave_math::wad_ray_math::get_half_ray_for_testing();
        let base_variable_borrow_rate: u256 = 0;
        let variable_rate_slope1: u256 = 0;
        let variable_rate_slope2: u256 = 0;
        aave_rate::default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(
            aave_pool,
            underlying_token_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // create reserves using the pool admin
        aave_pool::pool::init_reserve(
            aave_pool,
            underlying_token_address,
            treasury,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol
        );

        let index = 0;
        let emission_per_second = 0;
        let last_update_timestamp = 0;
        let distribution_end = 0;

        let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();

        let name_2 = string_utils::format1(&b"APTOS_UNDERLYING_2_{}", i);
        let symbol_2 = string_utils::format1(&b"U_2_{}", i);
        let decimals_2 = 2 + i;

        aave_pool::a_token_factory::create_token(
            aave_pool,
            name_2,
            symbol_2,
            decimals_2,
            utf8(b"2"),
            utf8(b"2"),
            rewards_addr,
            treasury_address
        );

        let a_token_address_2 =
            a_token_factory::token_address(signer::address_of(aave_pool), symbol_2);

        let users_data = std::simple_map::new();

        let reward_data =
            aave_pool::rewards_controller::create_reward_data(
                index,
                emission_per_second,
                last_update_timestamp,
                distribution_end,
                users_data
            );

        let rewards_map = std::simple_map::new();

        std::simple_map::upsert(&mut rewards_map, a_token_address_2, reward_data);

        let available_rewards_count = 1;
        let decimals = 2;
        let available_rewards = std::simple_map::new();
        std::simple_map::upsert(&mut available_rewards, 0, a_token_address_2);

        let asset_data =
            aave_pool::rewards_controller::create_asset_data(
                rewards_map,
                available_rewards,
                available_rewards_count,
                decimals
            );

        let base_data = aave_pool::pool::get_reserve_data(underlying_token_address);
        let asset = aave_pool::pool::get_reserve_a_token_address(&base_data);

        aave_pool::rewards_controller::add_asset(rewards_addr, asset, asset_data);

        aave_pool::rewards_controller::add_rewards_by_asset(
            asset, rewards_addr, 0, a_token_address_2
        );

        let rewards_map_2 = std::simple_map::new();
        let reward_data_2 =
            aave_pool::rewards_controller::create_reward_data(
                index,
                emission_per_second,
                last_update_timestamp,
                distribution_end,
                users_data
            );
        std::simple_map::upsert(&mut rewards_map_2, a_token_address_2, reward_data_2);

        let available_rewards_2 = std::simple_map::new();
        std::simple_map::upsert(&mut available_rewards_2, 0, a_token_address_2);

        let asset_data_2 =
            aave_pool::rewards_controller::create_asset_data(
                rewards_map_2,
                available_rewards_2,
                available_rewards_count,
                decimals
            );

        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(&base_data);
        aave_pool::rewards_controller::add_asset(
            rewards_addr, variable_debt_token_address, asset_data_2
        );
        aave_pool::rewards_controller::add_rewards_by_asset(
            variable_debt_token_address,
            rewards_addr,
            0,
            a_token_address_2
        );

        let user_data = aave_pool::rewards_controller::create_user_data(0, 0);
        aave_pool::rewards_controller::add_user_asset_index(
            rewards_addr,
            asset,
            a_token_address_2,
            rewards_addr,
            user_data
        );

        aave_pool::rewards_controller::add_user_asset_index(
            rewards_addr,
            variable_debt_token_address,
            a_token_address_2,
            rewards_addr,
            user_data
        );

        aave_pool::rewards_controller::add_to_assets_list(asset, rewards_addr);

        let (reserves_incentives_data, _user_reserves_incentives_data) =
            get_full_reserves_incentive_data(rewards_addr);
        assert!(
            vector::length(&reserves_incentives_data) != 0,
            TEST_SUCCESS
        );
    }
}
