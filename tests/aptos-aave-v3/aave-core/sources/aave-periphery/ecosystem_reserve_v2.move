module aave_pool::ecosystem_reserve_v2 {
    use std::signer;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::timestamp;

    use aave_acl::acl_manage::Self;

    use aave_pool::admin_controlled_ecosystem_reserve::check_is_funds_admin;
    use aave_pool::stream::{Self, Stream};

    #[test_only]
    use aptos_framework::timestamp::fast_forward_seconds;
    #[test_only]
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    const EROLE_NOT_EXISTS: u64 = 1;
    const ESTREAM_NOT_EXISTS: u64 = 2;
    const NOT_FUNDS_ADMIN: u64 = 3;
    const ESTREAM_TO_THE_CONTRACT_ITSELF: u64 = 4;
    const ESTREAM_TO_THE_CALLER: u64 = 5;
    const EDEPOSIT_IS_ZERO: u64 = 6;
    const ESTART_TIME_BEFORE_BLOCK_TIMESTAMP: u64 = 7;
    const ESTOP_TIME_BEFORE_THE_START_TIME: u64 = 8;
    const EDEPOSIT_SMALLER_THAN_TIME_DELTA: u64 = 9;
    const EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA: u64 = 10;
    const EAMOUNT_IS_ZERO: u64 = 11;
    const EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE: u64 = 12;

    const ECOSYSTEM_RESERVE_V2_NAME: vector<u8> = b"AAVE_ECOSYSTEM_RESERVE_V2";

    struct EcosystemReserveV2Data has key {
        next_stream_id: u256,
        streams: SmartTable<u256, Stream>
    }

    #[event]
    struct CreateStream has store, drop {
        stream_id: u256,
        sender: address,
        recipient: address,
        deposit: u256,
        token_address: address,
        start_time: u256,
        stop_time: u256
    }

    #[event]
    struct WithdrawFromStream has store, drop {
        stream_id: u256,
        recipient: address,
        amount: u256
    }

    #[event]
    struct CancelStream has store, drop {
        stream_id: u256,
        sender: address,
        recipient: address,
        sender_balance: u256,
        recipient_balance: u256
    }

    fun only_admin_or_recipient(account: address, stream_id: u256) acquires EcosystemReserveV2Data {
        assert!(
            acl_manage::is_funds_admin(account) || is_recipient(account, stream_id),
            NOT_FUNDS_ADMIN
        );
    }

    fun is_recipient(account: address, stream_id: u256): bool acquires EcosystemReserveV2Data {
        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());

        if (!smart_table::contains(&ecosystem_reserve_v2_data.streams, stream_id)) {
            return false
        };
        let stream_item =
            smart_table::borrow(&ecosystem_reserve_v2_data.streams, stream_id);
        let recipient = stream::recipient(stream_item);

        recipient != account
    }

    fun stream_exists(stream_id: u256) acquires EcosystemReserveV2Data {
        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());

        assert!(
            smart_table::contains(&ecosystem_reserve_v2_data.streams, stream_id),
            ESTREAM_NOT_EXISTS
        );
        let stream_item =
            smart_table::borrow(&ecosystem_reserve_v2_data.streams, stream_id);
        assert!(stream::is_entity(stream_item), ESTREAM_NOT_EXISTS);
    }

    fun get_next_stream_id(): u256 acquires EcosystemReserveV2Data {
        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());
        ecosystem_reserve_v2_data.next_stream_id
    }

    public fun initialize(sender: &signer) {
        let state_object_constructor_ref =
            &object::create_named_object(sender, ECOSYSTEM_RESERVE_V2_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            EcosystemReserveV2Data {
                streams: smart_table::new<u256, Stream>(),
                next_stream_id: 1
            }
        );
    }

    #[view]
    public fun ecosystem_reserve_v2_data_address(): address {
        object::create_object_address(&@aave_pool, ECOSYSTEM_RESERVE_V2_NAME)
    }

    #[view]
    public fun ecosystem_reserve_v2_data_object(): Object<EcosystemReserveV2Data> {
        object::address_to_object<EcosystemReserveV2Data>(
            ecosystem_reserve_v2_data_address()
        )
    }

    fun get_stream(
        stream_id: u256
    ): (address, address, u256, address, u256, u256, u256, u256) acquires EcosystemReserveV2Data {
        stream_exists(stream_id);

        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());
        let stream_item =
            smart_table::borrow(&ecosystem_reserve_v2_data.streams, stream_id);
        stream::get_stream(stream_item)
    }

    #[view]
    public fun delta_of(stream_id: u256): u256 acquires EcosystemReserveV2Data {
        stream_exists(stream_id);

        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());
        let stream_item =
            smart_table::borrow(&ecosystem_reserve_v2_data.streams, stream_id);

        let (_, _, _, _, start_time, stop_time, _, _) = stream::get_stream(stream_item);

        let now = (timestamp::now_seconds() as u256);

        if (now <= start_time) {
            return 0
        };

        if (now < stop_time) {
            return now - start_time
        };
        stop_time - start_time
    }

    public fun balance_of(stream_id: u256, who: address): u256 acquires EcosystemReserveV2Data {
        stream_exists(stream_id);

        let delta = delta_of(stream_id);

        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());
        let stream_item =
            smart_table::borrow(&ecosystem_reserve_v2_data.streams, stream_id);

        let (sender, recipient, deposit, _, _, _, remaining_balance, rate_per_second) =
            stream::get_stream(stream_item);

        let recipient_balance = delta * rate_per_second;

        if (deposit > remaining_balance) {
            let withdrawal_amount = deposit - remaining_balance;
            recipient_balance = recipient_balance - withdrawal_amount;
        };

        if (who == recipient) {
            return recipient_balance
        };

        if (who == sender) {
            let sender_balance = remaining_balance - recipient_balance;
            return sender_balance
        };
        0
    }

    fun create_stream(
        sender: &signer,
        recipient: address,
        deposit: u256,
        token_address: address,
        start_time: u256,
        stop_time: u256
    ): u256 acquires EcosystemReserveV2Data {
        check_is_funds_admin(signer::address_of(sender));

        assert!(
            recipient != ecosystem_reserve_v2_data_address(),
            ESTREAM_TO_THE_CONTRACT_ITSELF
        );
        assert!(recipient != signer::address_of(sender), ESTREAM_TO_THE_CALLER);
        assert!(deposit > 0, EDEPOSIT_IS_ZERO);
        let now = (timestamp::now_seconds() as u256);
        assert!(start_time >= now, ESTART_TIME_BEFORE_BLOCK_TIMESTAMP);
        assert!(stop_time > start_time, ESTOP_TIME_BEFORE_THE_START_TIME);

        let duration = stop_time - start_time;

        assert!(deposit >= duration, EDEPOSIT_SMALLER_THAN_TIME_DELTA);

        assert!(
            deposit % duration == 0,
            EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA
        );

        let rate_per_second = deposit / duration;

        let stream_id = get_next_stream_id();

        let ecosystem_reserve_v2_data =
            borrow_global_mut<EcosystemReserveV2Data>(
                ecosystem_reserve_v2_data_address()
            );
        let stream_item =
            stream::create_stream(
                deposit,
                rate_per_second,
                deposit,
                start_time,
                stop_time,
                recipient,
                signer::address_of(sender),
                token_address,
                true
            );

        smart_table::upsert(
            &mut ecosystem_reserve_v2_data.streams, stream_id, stream_item
        );

        ecosystem_reserve_v2_data.next_stream_id = ecosystem_reserve_v2_data.next_stream_id
            + 1;

        event::emit(
            CreateStream {
                stream_id,
                sender: signer::address_of(sender),
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            }
        );

        stream_id
    }

    fun withdraw_from_stream(
        sender: &signer, stream_id: u256, amount: u256
    ): bool acquires EcosystemReserveV2Data {
        stream_exists(stream_id);
        check_is_funds_admin(signer::address_of(sender));

        assert!(amount > 0, EAMOUNT_IS_ZERO);
        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());
        let stream_item =
            smart_table::borrow(&ecosystem_reserve_v2_data.streams, stream_id);

        let (_, recipient, _, _, _, _, remaining_balance, _) =
            stream::get_stream(stream_item);

        let balance = balance_of(stream_id, recipient);
        assert!(balance >= amount, EAMOUNT_EXCEEDS_THE_AVAILABLE_BALANCE);

        let ecosystem_reserve_v2_data =
            borrow_global_mut<EcosystemReserveV2Data>(
                ecosystem_reserve_v2_data_address()
            );
        let stream_item =
            smart_table::borrow_mut(&mut ecosystem_reserve_v2_data.streams, stream_id);

        stream::set_remaining_balance(stream_item, remaining_balance - amount);

        let (_, recipient, _, _, _, _, remaining_balance, _) =
            stream::get_stream(stream_item);

        if (remaining_balance == 0) {
            smart_table::remove(&mut ecosystem_reserve_v2_data.streams, stream_id);
        };

        event::emit(WithdrawFromStream { stream_id, recipient, amount });
        true
    }

    fun cancel_stream(sender: &signer, stream_id: u256): bool acquires EcosystemReserveV2Data {
        stream_exists(stream_id);
        check_is_funds_admin(signer::address_of(sender));

        let ecosystem_reserve_v2_data =
            borrow_global<EcosystemReserveV2Data>(ecosystem_reserve_v2_data_address());
        let stream_item =
            smart_table::borrow(&ecosystem_reserve_v2_data.streams, stream_id);

        let (stream_sender, recipient, _, _token_address, _, _, _, _) =
            stream::get_stream(stream_item);

        let sender_balance = balance_of(stream_id, stream_sender);
        let recipient_balance = balance_of(stream_id, recipient);

        let ecosystem_reserve_v2_data =
            borrow_global_mut<EcosystemReserveV2Data>(
                ecosystem_reserve_v2_data_address()
            );

        smart_table::remove(&mut ecosystem_reserve_v2_data.streams, stream_id);

        if (recipient_balance > 0) {
            // mock_underlying_token_factory::transfer_from(
            //     stream_sender,
            //     recipient,
            //     (recipient_balance as u64),
            //     token_address
            // );
        };

        event::emit(
            CancelStream {
                stream_id,
                sender: stream_sender,
                recipient,
                sender_balance,
                recipient_balance
            }
        );

        true
    }

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_basic_flow(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let _sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_only_admin_or_recipient(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let _sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, TEST_SUCCESS);

        only_admin_or_recipient(token_address, 1);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_cancel_stream(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let _sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, 1);

        cancel_stream(periphery_account, stream_id);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_balance_of(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let _sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, 1);

        fast_forward_seconds(one_hour_in_secs);

        let res = balance_of(stream_id, signer::address_of(periphery_account));
        assert!(res == 7200, 1);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_withdraw_from_stream(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let _sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, 1);

        let amount = 1;

        fast_forward_seconds(2 * one_hour_in_secs);

        let res = withdraw_from_stream(periphery_account, stream_id, amount);
        assert!(res == true, 1);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_get_stream(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, 1);

        let (
            stream_sender,
            stream_recipient,
            stream_deposit,
            stream_token_address,
            stream_start_time,
            stream_stop_time,
            stream_remaining_balance,
            stream_rate_per_second
        ) = get_stream(stream_id);

        assert!(stream_sender == sender, 1);
        assert!(stream_recipient == recipient, 1);
        assert!(stream_deposit == deposit, 1);
        assert!(stream_token_address == token_address, 1);
        assert!(stream_start_time == start_time, 1);
        assert!(stream_stop_time == stop_time, 1);
        assert!(stream_remaining_balance == 7200, 1);
        assert!(stream_rate_per_second == 2, 1);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_delta_of(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let _sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, 1);

        let _amount = 1;

        fast_forward_seconds(2 * one_hour_in_secs);

        let res = delta_of(stream_id);

        assert!(res == 3600, 1);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222,
            creator = @0x1
        )
    ]
    fun test_get_next_stream_id(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer,
        creator: &signer
    ) acquires EcosystemReserveV2Data {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        set_time_has_started_for_testing(creator);

        let one_hour_in_secs = 1 * 60 * 60;

        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let _ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;

        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        acl_manage::is_funds_admin(signer::address_of(acl_fund_admin));

        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account);

        let _rate_per_second = 1;
        let _remaining_balance = 1;
        let start_time = (one_hour_in_secs as u256) * 2;
        let stop_time = (one_hour_in_secs as u256) * 3;
        let deposit = (one_hour_in_secs as u256) * 2;
        let recipient = signer::address_of(user_account);
        let _sender = signer::address_of(periphery_account);
        let token_address = signer::address_of(periphery_account);
        let _is_entity = true;

        let stream_id =
            create_stream(
                periphery_account,
                recipient,
                deposit,
                token_address,
                start_time,
                stop_time
            );

        assert!(stream_id == 1, 1);

        let _amount = 1;

        fast_forward_seconds(2 * one_hour_in_secs);

        let res = get_next_stream_id();

        assert!(res == 2, 1);
    }
}
