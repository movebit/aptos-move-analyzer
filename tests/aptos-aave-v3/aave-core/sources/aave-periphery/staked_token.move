module aave_pool::staked_token {
    struct MockStakedToken has key, drop, store, copy {
        addr: address
    }

    public fun staked_token(mock_staked_token: &MockStakedToken): address {
        mock_staked_token.addr
    }

    public fun stake(
        _mock_staked_token: &MockStakedToken, _to: address, _amount: u256
    ) {}

    fun redeem(_to: address, _amount: u256) {}

    fun cooldown() {}

    fun claim_rewards(_to: address, _amount: u256) {}

    public fun create_mock_staked_token(addr: address): MockStakedToken {
        MockStakedToken { addr }
    }

    #[test_only]
    use std::signer;

    #[test(account = @aave_pool)]
    fun test_create_mock_staked_token(account: &signer) {
        let addr = signer::address_of(account);

        let mock_staked_token = create_mock_staked_token(addr);

        assert!(mock_staked_token.addr == addr, 0);
    }

    #[test(_account = @aave_pool)]
    fun test_cooldown(_account: &signer) {
        cooldown();
    }

    #[test(account = @aave_pool)]
    fun test_redeem(account: &signer) {
        let to = signer::address_of(account);
        let amount = 1;
        redeem(to, amount);
    }

    #[test(account = @aave_pool)]
    fun test_claim_rewards(account: &signer) {
        let to = signer::address_of(account);
        let amount = 1;
        claim_rewards(to, amount);
    }
}
