module aave_pool::stream {

    struct Stream has key, store, drop {
        deposit: u256,
        rate_per_second: u256,
        remaining_balance: u256,
        start_time: u256,
        stop_time: u256,
        recipient: address,
        sender: address,
        token_address: address,
        is_entity: bool
    }

    public fun recipient(stream: &Stream): address {
        stream.recipient
    }

    public fun is_entity(stream: &Stream): bool {
        stream.is_entity
    }

    public fun get_stream(stream: &Stream):
        (
        address, address, u256, address, u256, u256, u256, u256
    ) {
        (
            stream.sender,
            stream.recipient,
            stream.deposit,
            stream.token_address,
            stream.start_time,
            stream.stop_time,
            stream.remaining_balance,
            stream.rate_per_second
        )
    }

    public fun set_remaining_balance(
        stream: &mut Stream, remaining_balance: u256
    ) {
        stream.remaining_balance = remaining_balance;
    }

    public fun create_stream(
        deposit: u256,
        rate_per_second: u256,
        remaining_balance: u256,
        start_time: u256,
        stop_time: u256,
        recipient: address,
        sender: address,
        token_address: address,
        is_entity: bool
    ): Stream {
        Stream {
            deposit,
            rate_per_second,
            remaining_balance,
            start_time,
            stop_time,
            recipient,
            sender,
            token_address,
            is_entity
        }
    }

    #[test_only]
    use std::signer;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(account = @aave_pool)]
    fun test_create_stream(account: &signer) {
        let deposit = 1;
        let rate_per_second = 1;
        let remaining_balance = 1;
        let start_time = 1;
        let stop_time = 1;
        let recipient = signer::address_of(account);
        let sender = signer::address_of(account);
        let token_address = signer::address_of(account);
        let is_entity = true;

        let stream =
            create_stream(
                deposit,
                rate_per_second,
                remaining_balance,
                start_time,
                stop_time,
                recipient,
                sender,
                token_address,
                is_entity
            );

        assert!(stream.deposit == deposit, TEST_SUCCESS);
        assert!(stream.rate_per_second == rate_per_second, TEST_SUCCESS);
        assert!(stream.remaining_balance == remaining_balance, TEST_SUCCESS);
        assert!(stream.start_time == start_time, TEST_SUCCESS);
        assert!(stream.stop_time == stop_time, TEST_SUCCESS);
        assert!(stream.recipient == recipient, TEST_SUCCESS);
        assert!(stream.sender == sender, TEST_SUCCESS);
        assert!(stream.token_address == token_address, TEST_SUCCESS);
        assert!(stream.is_entity == is_entity, TEST_SUCCESS);
    }

    #[test(account = @aave_pool)]
    fun test_is_entity(account: &signer) {
        let deposit = 1;
        let rate_per_second = 1;
        let remaining_balance = 1;
        let start_time = 1;
        let stop_time = 1;
        let recipient = signer::address_of(account);
        let sender = signer::address_of(account);
        let token_address = signer::address_of(account);
        let _is_entity = true;

        let stream_true =
            create_stream(
                deposit,
                rate_per_second,
                remaining_balance,
                start_time,
                stop_time,
                recipient,
                sender,
                token_address,
                true
            );

        assert!(is_entity(&stream_true) == true, TEST_SUCCESS);

        let stream_false =
            create_stream(
                deposit,
                rate_per_second,
                remaining_balance,
                start_time,
                stop_time,
                recipient,
                sender,
                token_address,
                false
            );

        assert!(is_entity(&stream_false) == false, TEST_SUCCESS);
    }

    #[test(account = @aave_pool)]
    fun test_recipient(account: &signer) {
        let deposit = 1;
        let rate_per_second = 1;
        let remaining_balance = 1;
        let start_time = 1;
        let stop_time = 1;
        let recipient = signer::address_of(account);
        let sender = signer::address_of(account);
        let token_address = signer::address_of(account);
        let is_entity = true;

        let stream_true =
            create_stream(
                deposit,
                rate_per_second,
                remaining_balance,
                start_time,
                stop_time,
                recipient,
                sender,
                token_address,
                is_entity
            );

        assert!(recipient(&stream_true) == recipient, TEST_SUCCESS);
    }

    #[test(account = @aave_pool)]
    fun test_get_stream(account: &signer) {
        let arg_deposit = 1;
        let arg_rate_per_second = 1;
        let arg_remaining_balance = 1;
        let arg_start_time = 1;
        let arg_stop_time = 1;
        let arg_recipient = signer::address_of(account);
        let arg_sender = signer::address_of(account);
        let arg_token_address = signer::address_of(account);
        let arg_is_entity = true;

        let stream =
            create_stream(
                arg_deposit,
                arg_rate_per_second,
                arg_remaining_balance,
                arg_start_time,
                arg_stop_time,
                arg_recipient,
                arg_sender,
                arg_token_address,
                arg_is_entity
            );

        let (
            _sender,
            _recipient,
            _deposit,
            _token_address,
            _start_time,
            _stop_time,
            _remaining_balance,
            _rate_per_second
        ) = get_stream(&stream);

        assert!(stream.deposit == arg_deposit, TEST_SUCCESS);
        assert!(stream.rate_per_second == arg_rate_per_second, TEST_SUCCESS);
        assert!(stream.remaining_balance == arg_remaining_balance, TEST_SUCCESS);
        assert!(stream.start_time == arg_start_time, TEST_SUCCESS);
        assert!(stream.stop_time == arg_stop_time, TEST_SUCCESS);
        assert!(stream.recipient == arg_recipient, TEST_SUCCESS);
        assert!(stream.sender == arg_sender, TEST_SUCCESS);
        assert!(stream.token_address == arg_token_address, TEST_SUCCESS);
        assert!(stream.is_entity == arg_is_entity, TEST_SUCCESS);
    }

    #[test(account = @aave_pool)]
    fun test_set_remaining_balance(account: &signer) {
        let arg_deposit = 1;
        let arg_rate_per_second = 1;
        let arg_remaining_balance = 1;
        let arg_start_time = 1;
        let arg_stop_time = 1;
        let arg_recipient = signer::address_of(account);
        let arg_sender = signer::address_of(account);
        let arg_token_address = signer::address_of(account);
        let arg_is_entity = true;

        let stream =
            create_stream(
                arg_deposit,
                arg_rate_per_second,
                arg_remaining_balance,
                arg_start_time,
                arg_stop_time,
                arg_recipient,
                arg_sender,
                arg_token_address,
                arg_is_entity
            );

        let (
            _sender,
            _recipient,
            _deposit,
            _token_address,
            _start_time,
            _stop_time,
            _remaining_balance,
            _rate_per_second
        ) = get_stream(&stream);

        assert!(stream.remaining_balance == arg_remaining_balance, TEST_SUCCESS);

        let new_remaining_balance = 10;

        set_remaining_balance(&mut stream, new_remaining_balance);

        assert!(stream.remaining_balance == new_remaining_balance, TEST_SUCCESS);
    }
}
