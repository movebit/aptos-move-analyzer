module aave_oracle::reward_oracle {

    // TODO: this is unfinished
    struct RewardOracle has key, store, drop, copy {
        id: u256
    }

    public fun create_reward_oracle(id: u256): RewardOracle {
        // TODO
        RewardOracle { id }
    }

    public fun decimals(_reward_oracle: RewardOracle): u8 {
        // TODO
        0
    }

    public fun latest_answer(_reward_oracle: RewardOracle): u256 {
        1
    }

    public fun latest_timestamp(_reward_oracle: RewardOracle): u256 {
        // TODO
        0
    }

    public fun latest_round(_reward_oracle: RewardOracle): u256 {
        // TODO
        0
    }

    public fun get_answer(_reward_oracle: RewardOracle, _round_id: u256): u256 {
        // TODO
        0
    }

    public fun get_timestamp(
        _reward_oracle: RewardOracle, _round_id: u256
    ): u256 {
        // TODO
        0
    }

    public fun base_currency_unit(
        _reward_oracle: RewardOracle, _round_id: u256
    ): u64 {
        // TODO
        0
    }
}
