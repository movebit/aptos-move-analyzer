#[test_only]
module aave_pool::variable_debt_token_factory_tests {
    use std::features::change_feature_flags_for_testing;
    use std::signer::Self;
    use std::string::utf8;
    use std::vector::Self;
    use aptos_framework::event::emitted_events;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Self;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage::Self;
    use aave_math::wad_ray_math;

    use aave_pool::token_base::Self;
    use aave_pool::token_base::{Burn, Mint, Transfer};
    use aave_pool::variable_debt_token_factory::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(
        aave_pool = @aave_pool, variable_tokens_admin = @aave_pool, aave_acl = @aave_acl
    )]
    fun test_variable_token_initialization(
        aave_pool: &signer, variable_tokens_admin: &signer, aave_acl: &signer
    ) {
        // init token base
        token_base::test_init_module(aave_pool);

        // init debt token
        variable_debt_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(variable_tokens_admin)
        );

        // create variable tokens
        let name = utf8(b"TEST_VAR_TOKEN_1");
        let symbol = utf8(b"VAR1");
        let decimals = 3;
        variable_debt_token_factory::create_token(
            variable_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            @0x033
        );
        // check emitted events
        let emitted_events = emitted_events<variable_debt_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
        let variable_token_address =
            variable_debt_token_factory::token_address(
                signer::address_of(variable_tokens_admin), symbol
            );
        let variable_token_metadata =
            variable_debt_token_factory::asset_metadata(
                signer::address_of(variable_tokens_admin), symbol
            );
        assert!(
            object::address_to_object<Metadata>(variable_token_address)
                == variable_token_metadata,
            TEST_SUCCESS
        );
        assert!(variable_debt_token_factory::get_revision() == 1, TEST_SUCCESS);
        assert!(
            variable_debt_token_factory::scaled_total_supply(variable_token_address)
                == 0,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::decimals(variable_token_address) == decimals,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::symbol(variable_token_address) == symbol,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::name(variable_token_address) == name,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            variable_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41
        )
    ]
    fun test_variable_token_mint_burn(
        aave_pool: &signer,
        variable_tokens_admin: &signer,
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

        // init debt token
        variable_debt_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(variable_tokens_admin)
        );

        // create var tokens
        let name = utf8(b"TEST_VAR_TOKEN_1");
        let symbol = utf8(b"VAR1");
        let decimals = 3;
        let underlying_asset_address = @0x033;
        variable_debt_token_factory::create_token(
            variable_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset_address
        );
        // check emitted events
        let emitted_events = emitted_events<variable_debt_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
        let var_token_address =
            variable_debt_token_factory::token_address(
                signer::address_of(variable_tokens_admin), symbol
            );
        let _var_token_metadata =
            variable_debt_token_factory::asset_metadata(
                signer::address_of(variable_tokens_admin), symbol
            );

        // ============= MINT ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        variable_debt_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(token_receiver),
            amount_to_mint,
            reserve_index,
            var_token_address
        );

        // assert a token supply
        assert!(
            variable_debt_token_factory::scaled_total_supply(var_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // assert var_tokens receiver balance
        let var_token_amount_scaled = wad_ray_math::ray_div(
            amount_to_mint, reserve_index
        );
        assert!(
            variable_debt_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), var_token_address
            ) == var_token_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= BURN ============== //
        // now burn the variable tokens
        let amount_to_burn = amount_to_mint / 2;
        variable_debt_token_factory::burn(
            signer::address_of(token_receiver),
            amount_to_burn,
            reserve_index,
            var_token_address
        );

        // assert var token supply
        let expected_var_token_scaled_total_supply =
            wad_ray_math::ray_div(amount_to_mint - amount_to_burn, reserve_index);
        assert!(
            variable_debt_token_factory::scaled_total_supply(var_token_address)
                == expected_var_token_scaled_total_supply,
            TEST_SUCCESS
        );

        // assert var_tokens receiver balance
        let var_token_amount_scaled = wad_ray_math::ray_div(
            amount_to_burn, reserve_index
        );
        assert!(
            variable_debt_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), var_token_address
            ) == var_token_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 2, TEST_SUCCESS);
        let emitted_burn_events = emitted_events<Burn>();
        assert!(vector::length(&emitted_burn_events) == 1, TEST_SUCCESS);
    }
}
