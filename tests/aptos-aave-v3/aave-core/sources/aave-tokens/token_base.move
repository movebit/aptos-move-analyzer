module aave_pool::token_base {
    use std::option::Self;
    use std::signer;
    use std::string::String;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::string_utils::format2;
    use aptos_framework::event;
    use aptos_framework::fungible_asset::{Self, BurnRef, Metadata, MintRef, TransferRef};
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use aptos_framework::primary_fungible_store;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_math::wad_ray_math;

    friend aave_pool::a_token_factory;
    friend aave_pool::variable_debt_token_factory;
    friend aave_pool::user_logic;

    #[event]
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to
    /// another (`to`).
    ///
    /// Note that `value` may be zero.
    struct Transfer has store, drop {
        from: address,
        to: address,
        value: u256
    }

    #[event]
    /// @dev Emitted after the mint action
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted tokens
    /// @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
    /// @param balance_increase The increase in scaled-up balance since the last action of 'on_behalf_of'
    /// @param index The next liquidity index of the reserve
    struct Mint has store, drop {
        caller: address,
        on_behalf_of: address,
        value: u256,
        balance_increase: u256,
        index: u256
    }

    #[event]
    /// @dev Emitted after the burn action
    /// @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
    /// @param from The address from which the tokens will be burned
    /// @param target The address that will receive the underlying, if any
    /// @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
    /// @param balance_increase The increase in scaled-up balance since the last action of 'from'
    /// @param index The next liquidity index of the reserve
    struct Burn has store, drop {
        from: address,
        target: address,
        value: u256,
        balance_increase: u256,
        index: u256
    }

    struct UserState has store, copy, drop {
        balance: u128,
        additional_data: u128
    }

    // Map of users address and their state data (key = user_address_token_address => UserState)
    struct UserStateMap has key {
        value: SmartTable<String, UserState>
    }

    struct TokenData has store, copy, drop {
        scaled_total_supply: u256
    }

    // token metadata_address => TokenData
    struct TokenMap has key {
        value: SmartTable<address, TokenData>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef
    }

    fun init_module(signer: &signer) {
        only_token_admin(signer);
        move_to(
            signer,
            UserStateMap {
                value: smart_table::new<String, UserState>()
            }
        );
        move_to(
            signer,
            TokenMap {
                value: smart_table::new<address, TokenData>()
            }
        )
    }

    fun assert_token_exists(metadata_address: address) acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        assert!(
            smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_not_exist()
        );
    }

    public fun get_user_state(
        user: address, metadata_address: address
    ): UserState acquires UserStateMap {
        let user_state_map = borrow_global<UserStateMap>(@aave_pool);
        let key = format2(&b"{}_{}", user, metadata_address);
        if (!smart_table::contains(&user_state_map.value, key)) {
            return UserState { balance: 0, additional_data: 0 }
        };
        *smart_table::borrow(&user_state_map.value, key)
    }

    fun set_user_state(
        user: address,
        metadata_address: address,
        balance: u128,
        additional_data: u128
    ) acquires UserStateMap {
        let user_state_map = borrow_global_mut<UserStateMap>(@aave_pool);
        let key = format2(&b"{}_{}", user, metadata_address);

        smart_table::upsert(
            &mut user_state_map.value,
            key,
            UserState { balance, additional_data }
        );
    }

    public fun get_token_data(metadata_address: address): TokenData acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        assert!(
            smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_not_exist()
        );

        *smart_table::borrow(&token_map.value, metadata_address)
    }

    fun set_scaled_total_supply(
        metadata_address: address, scaled_total_supply: u256
    ) acquires TokenMap {
        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        let token_data = smart_table::borrow_mut(&mut token_map.value, metadata_address);
        token_data.scaled_total_supply = scaled_total_supply;
    }

    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 acquires UserStateMap {
        let user_state = get_user_state(user, metadata_address);
        (user_state.additional_data as u256)
    }

    public fun get_scaled_total_supply(token_data: &TokenData): u256 {
        token_data.scaled_total_supply
    }

    /// @notice Creates a new FA Token
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @param constructor_ref The constructor reference of the Token
    /// @param name The name of the Token
    /// @param symbol The symbol of the Token
    /// @param decimals The decimals of the Token
    /// @param icon_uri The icon URI of the Token
    /// @param project_uri The project URI of the Token
    public(friend) fun create_token(
        constructor_ref: &ConstructorRef,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String
    ) acquires TokenMap {
        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        let metadata_address = object::address_from_constructor_ref(constructor_ref);
        assert!(
            !smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_already_exists()
        );
        let token_data = TokenData { scaled_total_supply: 0 };
        smart_table::add(&mut token_map.value, metadata_address, token_data);

        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);

        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );
    }

    /// @notice Mints `amount` tokens to `on_behalf_of`
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted Tokens
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the Token
    public(friend) fun mint_scaled(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires ManagedFungibleAsset, UserStateMap, TokenMap {
        let amount_scaled = wad_ray_math::ray_div(amount, index);
        assert!(amount_scaled != 0, error_config::get_einvalid_mint_amount());
        let scaled_balance = scaled_balance_of(on_behalf_of, metadata_address);

        let user_state = get_user_state(on_behalf_of, metadata_address);
        let balance_increase =
            wad_ray_math::ray_mul(scaled_balance, index)
                - wad_ray_math::ray_mul(
                    scaled_balance, (user_state.additional_data as u256)
                );
        let new_balance = user_state.balance + (amount_scaled as u128);
        set_user_state(
            on_behalf_of,
            metadata_address,
            new_balance,
            (index as u128)
        );

        // update scale total supply
        let token_data = get_token_data(metadata_address);
        let scaled_total_supply = token_data.scaled_total_supply + amount_scaled;
        set_scaled_total_supply(metadata_address, scaled_total_supply);

        // fungible asset mint
        let asset = get_metadata(metadata_address);
        let managed_fungible_asset = obtain_managed_asset_refs(asset);
        let to_wallet =
            primary_fungible_store::ensure_primary_store_exists(on_behalf_of, asset);
        // freeze account
        if (!fungible_asset::is_frozen(to_wallet)) {
            fungible_asset::set_frozen_flag(
                &managed_fungible_asset.transfer_ref, to_wallet, true
            );
        };

        let fa =
            fungible_asset::mint(
                &managed_fungible_asset.mint_ref, (amount_scaled as u64)
            );
        fungible_asset::deposit_with_ref(
            &managed_fungible_asset.transfer_ref, to_wallet, fa
        );

        let amount_to_mint = amount + balance_increase;
        event::emit(Transfer { from: @0x0, to: on_behalf_of, value: amount_to_mint });
        event::emit(
            Mint {
                caller,
                on_behalf_of,
                value: amount_to_mint,
                balance_increase,
                index
            }
        );
    }

    /// @notice Burns Tokens from `user`
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @dev In some instances, the mint event could be emitted from a burn transaction
    /// if the amount to burn is less than the interest that the user accrued
    /// @param user The address from which the Tokens will be burned
    /// @param target The address that will receive the underlying
    /// @param amount The amount being burned
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the Token
    public(friend) fun burn_scaled(
        user: address,
        target: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires ManagedFungibleAsset, UserStateMap, TokenMap {
        let amount_scaled = wad_ray_math::ray_div(amount, index);
        assert!(amount_scaled != 0, error_config::get_einvalid_mint_amount());
        // get scale balance
        let scaled_balance = scaled_balance_of(user, metadata_address);

        let user_state = get_user_state(user, metadata_address);
        let balance_increase =
            wad_ray_math::ray_mul(scaled_balance, index)
                - wad_ray_math::ray_mul(
                    scaled_balance, (user_state.additional_data as u256)
                );
        let new_balance = user_state.balance - (amount_scaled as u128);
        set_user_state(
            user,
            metadata_address,
            new_balance,
            (index as u128)
        );

        // update scale total supply
        let token_data = get_token_data(metadata_address);
        let scaled_total_supply = token_data.scaled_total_supply - amount_scaled;
        set_scaled_total_supply(metadata_address, scaled_total_supply);

        // burn fungible asset
        let asset = get_metadata(metadata_address);
        let burn_ref = &obtain_managed_asset_refs(asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(user, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, (amount_scaled as u64));

        if (balance_increase > amount) {
            let amount_to_mint = balance_increase - amount;
            event::emit(Transfer { from: @0x0, to: user, value: amount_to_mint });
            event::emit(
                Mint {
                    caller: user,
                    on_behalf_of: user,
                    value: amount_to_mint,
                    balance_increase,
                    index
                }
            );
        } else {
            let amount_to_burn = amount - balance_increase;
            event::emit(Transfer { from: user, to: @0x0, value: amount_to_burn });
            event::emit(
                Burn {
                    from: user,
                    target,
                    value: amount_to_burn,
                    balance_increase,
                    index
                }
            );
        }
    }

    /// @notice Transfers Tokens from `sender` to `recipient`
    /// @dev Only callable by the a_token_factory and user_logic module
    /// @param sender The address from which the Tokens will be transferred
    /// @param recipient The address that will receive the Tokens
    /// @param amount The amount being transferred
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the Token
    public(friend) fun transfer(
        sender: address,
        recipient: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires ManagedFungibleAsset, UserStateMap {
        let sender_scaled_balance = scaled_balance_of(sender, metadata_address);
        let sender_user_state = get_user_state(sender, metadata_address);
        let sender_balance_increase =
            wad_ray_math::ray_mul(sender_scaled_balance, index)
                - wad_ray_math::ray_mul(
                    sender_scaled_balance, (sender_user_state.additional_data as u256)
                );

        let amount_ray_div = wad_ray_math::ray_div(amount, index);
        let new_sender_balance = sender_user_state.balance - (amount_ray_div as u128);
        set_user_state(
            sender,
            metadata_address,
            new_sender_balance,
            (index as u128)
        );

        let recipient_scaled_balance = scaled_balance_of(recipient, metadata_address);
        let recipient_user_state = get_user_state(recipient, metadata_address);
        let recipient_balance_increase =
            wad_ray_math::ray_mul(recipient_scaled_balance, index)
                - wad_ray_math::ray_mul(
                    recipient_scaled_balance,
                    (recipient_user_state.additional_data as u256)
                );

        let new_recipient_balance = recipient_user_state.balance
            + (amount_ray_div as u128);
        set_user_state(
            recipient,
            metadata_address,
            new_recipient_balance,
            (index as u128)
        );
        // transfer fungible asset
        let asset = get_metadata(metadata_address);
        let transfer_ref = &obtain_managed_asset_refs(asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(sender, asset);
        let to_wallet =
            primary_fungible_store::ensure_primary_store_exists(recipient, asset);

        // freeze account
        if (!fungible_asset::is_frozen(to_wallet)) {
            fungible_asset::set_frozen_flag(transfer_ref, to_wallet, true);
        };

        fungible_asset::transfer_with_ref(
            transfer_ref,
            from_wallet,
            to_wallet,
            (amount_ray_div as u64)
        );

        if (sender_balance_increase > 0) {
            event::emit(
                Transfer { from: @0x0, to: sender, value: sender_balance_increase }
            );
            event::emit(
                Mint {
                    caller: sender,
                    on_behalf_of: sender,
                    value: sender_balance_increase,
                    balance_increase: sender_balance_increase,
                    index
                }
            );
        };

        // if sender == recipient, the following logic will not execute, the event will not be emitted
        if (sender != recipient && recipient_balance_increase > 0) {
            event::emit(
                Transfer { from: @0x0, to: recipient, value: recipient_balance_increase }
            );
            event::emit(
                Mint {
                    caller: sender,
                    on_behalf_of: recipient,
                    value: recipient_balance_increase,
                    balance_increase: recipient_balance_increase,
                    index
                }
            );
        };

        event::emit(Transfer { from: sender, to: recipient, value: amount });
    }

    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 acquires UserStateMap {
        let user_state_map = get_user_state(owner, metadata_address);
        (user_state_map.balance as u256)
    }

    public fun scaled_total_supply(metadata_address: address): u256 acquires TokenMap {
        let token_data = get_token_data(metadata_address);
        token_data.scaled_total_supply
    }

    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) acquires UserStateMap, TokenMap {
        (scaled_balance_of(owner, metadata_address),
        scaled_total_supply(metadata_address))
    }

    public fun name(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::name(asset)
    }

    public fun symbol(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::symbol(asset)
    }

    public fun decimals(metadata_address: address): u8 {
        let asset = get_metadata(metadata_address);
        fungible_asset::decimals(asset)
    }

    fun get_metadata(metadata_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(metadata_address)
    }

    inline fun obtain_managed_asset_refs(
        asset: Object<Metadata>
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    /// @notice Drops the token data from the token map
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @param metadata_address The address of the Token
    public(friend) fun drop_token(metadata_address: address) acquires TokenMap {
        assert_token_exists(metadata_address);

        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        smart_table::remove(&mut token_map.value, metadata_address);
    }

    public fun only_pool_admin(account: &signer) {
        assert!(
            acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin()
        );
    }

    public fun only_token_admin(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_pool,
            error_config::get_enot_pool_owner()
        )
    }

    #[test_only]
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }
}
