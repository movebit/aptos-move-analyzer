#[test_only]
module aave_pool::a_token_factory_tests {
    use std::features::change_feature_flags_for_testing;
    use std::signer;
    use std::string;
    use std::string::utf8;
    use std::vector::Self;
    use aptos_std::string_utils::format2;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Self;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage::{Self, test_init_module};
    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory::Self;
    use aave_pool::mock_underlying_token_factory::Self;
    use aave_pool::token_base;
    use aave_pool::token_base::{Burn, Mint, Transfer};

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_atoken_initialization(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init token base
        token_base::test_init_module(aave_pool);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        // create a tokens
        let name = utf8(b"TEST_A_TOKEN_1");
        let symbol = utf8(b"A1");
        let decimals = 3;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;
        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset_address,
            treasury_address
        );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let a_token_address =
            a_token_factory::token_address(signer::address_of(a_tokens_admin), symbol);
        let a_token_metadata =
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol);
        let seed = *string::bytes(&format2(&b"{}_{}", symbol, 1));
        let resource_account =
            account::create_resource_address(&signer::address_of(a_tokens_admin), seed);
        assert!(
            object::address_to_object<Metadata>(a_token_address) == a_token_metadata,
            TEST_SUCCESS
        );
        assert!(a_token_factory::get_revision() == 1, TEST_SUCCESS);
        assert!(a_token_factory::decimals(a_token_address) == decimals, TEST_SUCCESS);
        assert!(a_token_factory::symbol(a_token_address) == symbol, TEST_SUCCESS);
        assert!(a_token_factory::name(a_token_address) == name, TEST_SUCCESS);
        assert!(
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol)
                == a_token_metadata,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    fun test_atoken_mint_burn_transfer(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer,
        caller: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init token base
        mock_underlying_token_factory::test_init_module(aave_pool);
        token_base::test_init_module(aave_pool);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 3;
        let max_supply = 10000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_2");
        let symbol = utf8(b"A2");
        let decimals = 3;
        let treasury_address = @0x034;

        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset_address,
            treasury_address
        );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let a_token_address =
            a_token_factory::token_address(signer::address_of(a_tokens_admin), symbol);
        let a_token_metadata =
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol);
        let seed = *string::bytes(&format2(&b"{}_{}", symbol, 1));
        let resource_account =
            account::create_resource_address(&signer::address_of(a_tokens_admin), seed);

        assert!(
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol)
                == a_token_metadata,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // mint resource_account
        let amount_to_mint: u256 = 100;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            a_token_factory::get_token_account_address(a_token_address),
            (amount_to_mint as u64),
            underlying_asset_address
        );

        // ============= MINT ATOKENS ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(token_receiver),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // get atoken scaled amount
        let atoken_amount_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= BURN ATOKENS ============== //
        // now burn the atokens
        let amount_to_burn = amount_to_mint / 2;

        // burn
        a_token_factory::burn(
            signer::address_of(token_receiver),
            signer::address_of(token_receiver),
            amount_to_burn,
            reserve_index,
            a_token_address
        );

        let remaining_amount = amount_to_mint - amount_to_burn;
        let remaining_amount_scaled =
            wad_ray_math::ray_div(remaining_amount, reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == remaining_amount_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == remaining_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 2, TEST_SUCCESS);
        let emitted_burn_events = emitted_events<Burn>();
        assert!(vector::length(&emitted_burn_events) == 1, TEST_SUCCESS);

        // ============= TRANSFER ATOKENS ============== //
        let transfer_receiver = @0x45;
        let transfer_amount: u256 = 20;
        let transfer_receiver_amount_scaled =
            wad_ray_math::ray_div(transfer_amount, reserve_index);

        // assert transfer receiver
        a_token_factory::transfer_on_liquidation(
            signer::address_of(token_receiver),
            transfer_receiver,
            20,
            reserve_index,
            a_token_address
        );
        assert!(
            a_token_factory::scaled_balance_of(transfer_receiver, a_token_address)
                == transfer_receiver_amount_scaled,
            TEST_SUCCESS
        );

        // assert token sender
        let transfer_sender_scaled_balance =
            wad_ray_math::ray_div(amount_to_burn - transfer_amount, reserve_index);
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == transfer_sender_scaled_balance,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 3, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41
        )
    ]
    fun test_atoken_transfer_on_liquidation(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init token base
        token_base::test_init_module(aave_pool);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );
        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_3");
        let symbol = utf8(b"A3");
        let decimals = 3;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;
        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset_address,
            treasury_address
        );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // check addresses
        let a_token_metadata =
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol);
        let a_token_address =
            a_token_factory::token_address(signer::address_of(a_tokens_admin), symbol);
        let seed = *string::bytes(&format2(&b"{}_{}", symbol, 1));
        let resource_account =
            account::create_resource_address(&signer::address_of(a_tokens_admin), seed);

        assert!(
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol)
                == a_token_metadata,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= MINT ATOKENS ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(token_receiver),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == amount_to_mint_scaled,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= TRANSFER ATOKENS ON LIQUIDATION ============== //
        let transfer_receiver = @0x45;
        let transfer_amount: u256 = 20;
        let transfer_receiver_amount_scaled =
            wad_ray_math::ray_div(transfer_amount, reserve_index);
        // assert transfer receiver
        a_token_factory::transfer_on_liquidation(
            signer::address_of(token_receiver),
            transfer_receiver,
            transfer_amount,
            reserve_index,
            a_token_address
        );
        assert!(
            a_token_factory::scaled_balance_of(transfer_receiver, a_token_address)
                == transfer_receiver_amount_scaled,
            TEST_SUCCESS
        );

        // assert token sender
        let transfer_sender_scaled_balance =
            wad_ray_math::ray_div(amount_to_mint - transfer_amount, reserve_index);
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == transfer_sender_scaled_balance,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 2, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_atoken_mint_to_treasury(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init token base
        token_base::test_init_module(aave_pool);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        // create a tokens
        let name = utf8(b"TEST_A_TOKEN_4");
        let symbol = utf8(b"A4");
        let decimals = 3;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;
        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset_address,
            treasury_address
        );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
        let a_token_address =
            a_token_factory::token_address(signer::address_of(a_tokens_admin), symbol);
        let _a_token_metadata =
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol);

        // ============= MINT TO TREASURY ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // mint to treasury
        a_token_factory::mint_to_treasury(
            amount_to_mint, reserve_index, a_token_address
        );

        // check balances
        assert!(
            a_token_factory::scaled_balance_of(treasury_address, a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        assert!(
            a_token_factory::scaled_balance_of(treasury_address, a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    fun test_atoken_transfer_underlying_to(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init underlying tokens
        mock_underlying_token_factory::test_init_module(aave_pool);

        // create underlying token
        let underlying_token_name = utf8(b"TOKEN_5");
        let underlying_token_symbol = utf8(b"T5");
        let underlying_token_decimals = 3;
        let underlying_token_max_supply = 10000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            underlying_token_max_supply,
            underlying_token_name,
            underlying_token_symbol,
            underlying_token_decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        // init token base
        token_base::test_init_module(aave_pool);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        // create a tokens
        let name = utf8(b"TEST_A_TOKEN_6");
        let symbol = utf8(b"A6");
        let decimals = 3;
        let treasury_address = @0x034;
        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_token_address,
            treasury_address
        );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
        let a_token_address =
            a_token_factory::token_address(signer::address_of(a_tokens_admin), symbol);
        let _a_token_metadata =
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol);

        // =============== MINT UNDERLYING FOR ACCOUNT ================= //
        // mint 100 underlying tokens for some address
        let underlying_amount: u256 = 100;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            a_token_factory::get_token_account_address(a_token_address),
            (underlying_amount as u64),
            underlying_token_address
        );

        // ============= TRANSFER THE UNDERLYING TIED TO THE ATOKENS ACCOUNT TO ANOTHER ACCOUNT ============== //
        let underlying_receiver_address = @0x7;
        let transfer_amount: u256 = 40;
        a_token_factory::transfer_underlying_to(
            underlying_receiver_address, transfer_amount, a_token_address
        );

        // check the receiver balance
        assert!(
            (
                mock_underlying_token_factory::balance_of(
                    underlying_receiver_address, underlying_token_address
                ) as u256
            ) == transfer_amount,
            TEST_SUCCESS
        );

        // check the underlying account
        assert!(
            (
                mock_underlying_token_factory::balance_of(
                    a_token_factory::get_token_account_address(a_token_address),
                    underlying_token_address
                ) as u256
            ) == underlying_amount - transfer_amount,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            rescue_receiver = @0x42,
            caller = @0x41,
            underlying_tokens_admin = @underlying_tokens
        )
    ]
    fun test_atoken_rescue(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        rescue_receiver: &signer,
        caller: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init the acl module and make aave_pool the asset listing/pool admin
        test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        // init mock underlying token
        mock_underlying_token_factory::test_init_module(aave_pool);

        // init token base
        token_base::test_init_module(aave_pool);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN");
        let symbol = utf8(b"A");
        let decimals = 3;
        let treasury_address = @0x034;
        let underlying_asset_address = @0x033;
        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset_address,
            treasury_address
        );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
        let a_token_address =
            a_token_factory::token_address(signer::address_of(a_tokens_admin), symbol);
        let a_token_metadata =
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol);
        let seed = *string::bytes(&format2(&b"{}_{}", symbol, 1));
        let resource_account =
            account::create_resource_address(&signer::address_of(a_tokens_admin), seed);

        // check addresses
        assert!(
            a_token_factory::asset_metadata(signer::address_of(a_tokens_admin), symbol)
                == a_token_metadata,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= RESCUE TRANSFER ATOKENS ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let _amount_to_mint_scaled = wad_ray_math::ray_div(
            amount_to_mint, reserve_index
        );

        let rescue_amount: u256 = 20;
        let _rescue_amount_scaled = wad_ray_math::ray_div(rescue_amount, reserve_index);

        // mint some tokens to the pool
        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(aave_pool),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // check events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // Create a new token
        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 3;
        let max_supply = 10000000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        // Transfer some tokens to the resource account
        let new_underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);
        let mint_amount = 1000000;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            a_token_factory::get_token_account_address(a_token_address),
            mint_amount,
            new_underlying_asset_address
        );

        // do rescue transfer. Singer is pool admin = aave_pool
        a_token_factory::rescue_tokens(
            aave_pool,
            new_underlying_asset_address,
            signer::address_of(rescue_receiver),
            (mint_amount as u256),
            a_token_address
        );

        // assert rescue receiver balance
        // assert!(a_token_factory::scaled_balance_of(signer::address_of(rescue_receiver), a_token_address) == rescue_amount_scaled,
        //     TEST_SUCCESS);
    }
}
