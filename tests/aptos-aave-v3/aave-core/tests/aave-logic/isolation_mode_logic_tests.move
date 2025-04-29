#[test_only]
module aave_pool::isolation_mode_logic_tests {
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use std::features::change_feature_flags_for_testing;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(_pool = @aave_pool, aave_std = @std, aptos_framework = @0x1)]
    fun test_isolation_mode_logic(
        _pool: &signer, aave_std: &signer, aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

    }
}
