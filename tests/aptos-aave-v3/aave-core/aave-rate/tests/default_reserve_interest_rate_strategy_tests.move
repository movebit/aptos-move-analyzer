#[test_only]
module aave_rate::default_reserve_interest_rate_strategy_tests {
    use std::features::change_feature_flags_for_testing;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage::Self;
    use aave_math::wad_ray_math::Self;

    use aave_rate::default_reserve_interest_rate_strategy::{
        get_base_variable_borrow_rate,
        get_max_excess_usage_ratio,
        get_max_variable_borrow_rate,
        get_optimal_usage_ratio,
        get_variable_rate_slope1,
        get_variable_rate_slope2,
        init_interest_rate_strategy,
        set_reserve_interest_rate_strategy
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            pool = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_default_reserve_interest_rate_strategy(
        pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_risk_admin(aave_role_super_admin, @aave_rate);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_rate);

        // init the interest rate strategy module
        init_interest_rate_strategy(pool);

        // init the strategy
        let asset_address = @0x42;
        let optimal_usage_ratio: u256 = wad_ray_math::ray() / 4;
        let base_variable_borrow_rate: u256 = 100;
        let variable_rate_slope1: u256 = 200;
        let variable_rate_slope2: u256 = 300;
        let max_excess_usage_ratio = wad_ray_math::ray() - optimal_usage_ratio;
        set_reserve_interest_rate_strategy(
            pool,
            asset_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // assertions on getters
        assert!(
            get_max_excess_usage_ratio(asset_address) == max_excess_usage_ratio,
            TEST_SUCCESS
        );
        assert!(
            get_optimal_usage_ratio(asset_address) == optimal_usage_ratio,
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope1(asset_address) == variable_rate_slope1,
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope2(asset_address) == variable_rate_slope2,
            TEST_SUCCESS
        );
        assert!(
            get_base_variable_borrow_rate(asset_address) == base_variable_borrow_rate,
            TEST_SUCCESS
        );
        assert!(
            get_max_variable_borrow_rate(asset_address)
                == base_variable_borrow_rate + variable_rate_slope1
                    + variable_rate_slope2,
            TEST_SUCCESS
        );
    }

    #[
        test(
            pool = @aave_rate,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_interest_rate_strategy_for_unset_asset(
        pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_risk_admin(aave_role_super_admin, @aave_rate);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_rate);

        // init the interest rate strategy module
        init_interest_rate_strategy(pool);

        // get strategy elements without having initialized the strategy
        let asset_address = @0x42;
        assert!(get_max_excess_usage_ratio(asset_address) == 0, TEST_SUCCESS);
        assert!(get_optimal_usage_ratio(asset_address) == 0, TEST_SUCCESS);
        assert!(get_variable_rate_slope1(asset_address) == 0, TEST_SUCCESS);
        assert!(get_variable_rate_slope2(asset_address) == 0, TEST_SUCCESS);
        assert!(get_base_variable_borrow_rate(asset_address) == 0, TEST_SUCCESS);
        assert!(get_max_variable_borrow_rate(asset_address) == 0, TEST_SUCCESS);
    }
}
