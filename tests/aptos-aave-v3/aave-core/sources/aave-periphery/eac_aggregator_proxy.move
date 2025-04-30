module aave_pool::eac_aggregator_proxy {
    struct MockEacAggregatorProxy has key, drop, store, copy {}

    #[event]
    struct AnswerUpdated has store, drop {
        current: u256,
        round_id: u256,
        timestamp: u256
    }

    #[event]
    struct NewRound has store, drop {
        round_id: u256,
        started_by: address
    }

    public fun decimals(): u8 {
        0
    }

    public fun latest_answer(): u256 {
        0
    }

    fun latest_timestamp(): u256 {
        0
    }

    fun latest_round(): u256 {
        0
    }

    fun get_answer(_round_id: u256): u256 {
        0
    }

    fun get_timestamp(_round_id: u256): u256 {
        0
    }

    public fun create_eac_aggregator_proxy(): MockEacAggregatorProxy {
        MockEacAggregatorProxy {}
    }

    #[test_only]
    const TEST_SUCCESS: u64 = 1;
    #[test_only]
    const TEST_FAILED: u64 = 2;

    #[test()]
    fun test_decimals() {
        // check the decimals which should now be 0
        assert!(decimals() == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_latest_answer() {
        // check the latest_answer which should now be 0
        assert!(latest_answer() == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_latest_timestamp() {
        // check the latest_timestamp which should now be 0
        assert!(latest_timestamp() == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_latest_round() {
        // check the latest_round which should now be 0
        assert!(latest_round() == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_get_answer() {
        let round_id = 0;
        // check the get_answer which should now be 0
        assert!(get_answer(round_id) == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_get_timestamp() {
        let round_id = 0;
        // check the get_timestamp which should now be 0
        assert!(get_timestamp(round_id) == 0, TEST_SUCCESS);
    }

    #[test()]
    fun test_create_eac_aggregator_proxy() {
        // check the create_eac_aggregator_proxy which should now return MockEacAggregatorProxy {}
        assert!(create_eac_aggregator_proxy() == MockEacAggregatorProxy {}, TEST_SUCCESS);
    }
}
