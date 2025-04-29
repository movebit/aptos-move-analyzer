#[test_only]
module aave_oracle::oracle_tests {
    use std::signer;
    use std::vector;
    use std::string::Self;
    use aave_oracle::oracle::Self;
    use aave_oracle::oracle_base::Self;
    use aave_acl::acl_manage::Self;
    use aptos_framework::timestamp::{set_time_has_started_for_testing};
    use data_feeds::registry::Self;
    use aptos_framework::event::emitted_events;
    use data_feeds::router;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;
    const TEST_ASSET: address = @0x444;
    const TEST_FEED_ID: vector<u8> = x"0003fbba4fce42f65d6032b18aee53efdf526cc734ad296cb57565979d883bdd";
    const TEST_FEED_PRICE: u256 = 63762090573356116000000;

    public fun get_test_feed_id(): vector<u8> {
        TEST_FEED_ID
    }

    public fun config_oracle(
        aave_oracle: &signer, data_feeds: &signer, platform: &signer
    ) {
        oracle::test_init_module(aave_oracle);
        set_up_chainlink_oracle(data_feeds, platform);
        set_chainlink_test_data(&oracle_base::get_resource_account_signer_for_testing());
    }

    fun set_up_chainlink_oracle(data_feeds: &signer, platform: &signer) {
        use aptos_framework::account::{Self};
        account::create_account_for_test(signer::address_of(data_feeds));
        account::create_account_for_test(signer::address_of(platform));

        platform::forwarder::init_module_for_testing(platform);
        platform::storage::init_module_for_testing(platform);
        router::init_module_for_testing(data_feeds);

        registry::init_module_for_testing(data_feeds);
    }

    fun set_chainlink_test_data(owner: &signer) {
        let report_data = TEST_FEED_ID;
        vector::append(
            &mut report_data,
            x"0000000000000000000000000000000000000000000000000000000066ed173e0000000000000000000000000000000000000000000000000000000066ed174200000000000000007fffffffffffffffffffffffffffffffffffffffffffffff00000000000000007fffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000066ee68c2000000000000000000000000000000000000000000000d808cc35e6ed670bd00000000000000000000000000000000000000000000000d808590c35425347980000000000000000000000000000000000000000000000d8093f5f989878e7c00"
        );
        let config_id = vector[1];
        registry::set_feeds(
            owner,
            vector[TEST_FEED_ID],
            vector[string::utf8(b"description")],
            config_id
        );
        registry::perform_update_for_testing(TEST_FEED_ID, report_data);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 3)]
    fun test_oracle_price_unknown_asset(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // check assets which are not known fail to return a price
        let undeclared_asset = @0x0;
        oracle::get_asset_price(undeclared_asset);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_set_single_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // now set a feed for a given token
        oracle::set_asset_feed_id(oracle_admin, TEST_ASSET, TEST_FEED_ID);

        // check for specific events
        let emitted_events = emitted_events<oracle_base::AssetPriceFeedUpdated>();
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // assert the set price
        assert!(oracle::get_asset_price(TEST_ASSET) == TEST_FEED_PRICE, TEST_SUCCESS);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_set_batch_prices(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feedids
        let asset_addresses = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_feed_ids = vector[TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_feed_ids(oracle_admin, asset_addresses, asset_feed_ids);

        // check for specific events
        let emitted_events = emitted_events<oracle_base::AssetPriceFeedUpdated>();
        assert!(
            vector::length(&emitted_events) == vector::length(&asset_addresses),
            TEST_SUCCESS
        );

        // get prices and ensure they are all > 0 since mocked
        let prices = oracle::get_assets_prices(asset_addresses);
        assert!(!vector::any(&prices, |price| *price != TEST_FEED_PRICE), TEST_SUCCESS);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 3)]
    fun test_oracle_remove_single_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // now set the chainlink feed for a given token
        let test_token_address = TEST_ASSET;
        oracle::set_asset_feed_id(oracle_admin, test_token_address, TEST_FEED_ID);

        // assert the set price
        assert!(
            oracle::get_asset_price(test_token_address) == TEST_FEED_PRICE,
            TEST_SUCCESS
        );

        // remove the feed for dai
        oracle::remove_asset_feed_id(oracle_admin, test_token_address);

        // check for specific events
        let emitted_events = emitted_events<oracle_base::AssetPriceFeedRemoved>();
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // try to query the price again
        oracle::get_asset_price(test_token_address);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 3)]
    fun test_oracle_remove_batch_prices(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feed ids which chainlink does not support
        let asset_addresses = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_feed_ids = vector[TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_feed_ids(oracle_admin, asset_addresses, asset_feed_ids);

        // remove assets as a batch
        oracle::batch_remove_asset_feed_ids(oracle_admin, asset_addresses);

        // check for specific events
        let emitted_events = emitted_events<oracle_base::AssetPriceFeedRemoved>();
        assert!(
            vector::length(&emitted_events) == vector::length(&asset_addresses),
            TEST_SUCCESS
        );

        // try to get prices - this would fail as a batch
        oracle::get_assets_prices(asset_addresses);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_remove_one_in_batch_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feed ids which chainlink does not support
        let asset_addresses = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_feed_ids = vector[TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_feed_ids(oracle_admin, asset_addresses, asset_feed_ids);

        // remove assets as a batch
        let end = vector::length(&asset_addresses);
        let truncated = vector::slice(&mut asset_addresses, 1, end);
        oracle::batch_remove_asset_feed_ids(oracle_admin, truncated);

        // check for specific events
        let emitted_events = emitted_events<oracle_base::AssetPriceFeedRemoved>();
        assert!(
            vector::length(&emitted_events) == vector::length(&truncated), TEST_SUCCESS
        );

        // try to get price for the unremoved asset, should work
        assert!(oracle::get_asset_price(@0x0) == TEST_FEED_PRICE, TEST_SUCCESS);
    }
}
