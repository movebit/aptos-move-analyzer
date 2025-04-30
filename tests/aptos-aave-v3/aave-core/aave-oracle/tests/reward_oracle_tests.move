#[test_only]
module aave_oracle::reward_oracle_tests {
    use aave_oracle::reward_oracle::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test()]
    fun test_mocked_reward_oracle_decimals() {
        let reward_oracle = reward_oracle::create_reward_oracle(1);
        // check the decimals which should now be 0
        assert!(reward_oracle::decimals(reward_oracle) == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_mocked_reward_oracle_latest_answer() {
        let reward_oracle = reward_oracle::create_reward_oracle(1);
        // check the latest_answer which should now be 1
        assert!(reward_oracle::latest_answer(reward_oracle) == 1, TEST_SUCCESS);
    }

    #[test()]
    fun test_mocked_reward_oracle_latest_timestamp() {
        let reward_oracle = reward_oracle::create_reward_oracle(1);
        // check the latest_timestamp which should now be 0
        assert!(reward_oracle::latest_timestamp(reward_oracle) == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_mocked_reward_oracle_latest_round() {
        let reward_oracle = reward_oracle::create_reward_oracle(1);
        // check the latest_round which should now be 0
        assert!(reward_oracle::latest_round(reward_oracle) == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_mocked_reward_oracle_get_answer() {
        let reward_oracle = reward_oracle::create_reward_oracle(1);
        // check the get_answer which should now be 0
        assert!(reward_oracle::get_answer(reward_oracle, 1) == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_mocked_reward_oracle_get_timestamp() {
        let reward_oracle = reward_oracle::create_reward_oracle(1);
        // check the get_timestamp which should now be 0
        assert!(reward_oracle::get_timestamp(reward_oracle, 1) == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_mocked_reward_oracle_base_currency_unit() {
        let reward_oracle = reward_oracle::create_reward_oracle(1);
        // check the base_currency_unit which should now be 0
        assert!(reward_oracle::base_currency_unit(reward_oracle, 1) == 0, TEST_SUCCESS);
    }
}
