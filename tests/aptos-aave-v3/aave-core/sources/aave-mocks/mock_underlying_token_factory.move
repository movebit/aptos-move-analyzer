module aave_pool::mock_underlying_token_factory {
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::fungible_asset::{Self, BurnRef, Metadata, MintRef, TransferRef};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;

    use aave_pool::token_base;

    friend aave_pool::a_token_factory;
    friend aave_pool::pool;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;
    friend aave_pool::bridge_logic;
    friend aave_pool::flashloan_logic;
    friend aave_pool::transfer_strategy;
    friend aave_pool::ecosystem_reserve_v2;

    #[test_only]
    friend aave_pool::mock_underlying_token_factory_tests;

    /// Only fungible asset metadata owner can make changes.
    const ENOT_OWNER: u64 = 1;
    const E_TOKEN_ALREADY_EXISTS: u64 = 2;
    const E_ACCOUNT_NOT_EXISTS: u64 = 3;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef
    }

    /// mapping (underlying token address => bool)
    struct CoinList has key {
        value: SmartTable<address, bool>
    }

    fun init_module(signer: &signer) {
        token_base::only_token_admin(signer);
        move_to(signer, CoinList { value: smart_table::new() })
    }

    /// @notice Creates a new underlying token.
    /// @param signer The signer of the transaction
    /// @param name The name of the underlying token
    /// @param symbol The symbol of the underlying token
    /// @param decimals The decimals of the underlying token
    /// @param icon_uri The icon URI of the underlying token
    /// @param project_uri The project URI of the underlying token
    public entry fun create_token(
        signer: &signer,
        maximum_supply: u128,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String
    ) acquires CoinList {
        only_token_admin(signer);
        let token_metadata_address =
            object::create_object_address(
                &signer::address_of(signer),
                *string::bytes(&symbol)
            );
        let coin_list = borrow_global_mut<CoinList>(@aave_pool);

        assert!(
            !smart_table::contains(&coin_list.value, token_metadata_address),
            E_TOKEN_ALREADY_EXISTS
        );

        smart_table::add(&mut coin_list.value, token_metadata_address, true);

        let max_supply =
            if (maximum_supply != 0) {
                option::some(maximum_supply)
            } else {
                option::none()
            };

        let constructor_ref =
            &object::create_named_object(signer, *string::bytes(&symbol));
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            max_supply,
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

    public fun assert_token_exists(token_metadata_address: address) acquires CoinList {
        let coin_list = borrow_global<CoinList>(@aave_pool);
        assert!(
            smart_table::contains(&coin_list.value, token_metadata_address),
            E_TOKEN_ALREADY_EXISTS
        );
    }

    #[view]
    public fun get_metadata_by_symbol(symbol: String): Object<Metadata> {
        let metadata_address =
            object::create_object_address(&@underlying_tokens, *string::bytes(&symbol));
        object::address_to_object<Metadata>(metadata_address)
    }

    #[view]
    public fun get_token_account_address(): address {
        @underlying_tokens
    }

    /// Return the address of the managed fungible asset that's created when this module is deployed.
    inline fun get_metadata(metadata_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(metadata_address)
    }

    /// Mint as the owner of metadata object.
    public entry fun mint(
        admin: &signer,
        to: address,
        amount: u64,
        metadata_address: address
    ) acquires ManagedFungibleAsset {
        let asset = get_metadata(metadata_address);
        let managed_fungible_asset = authorized_borrow_refs(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(
            &managed_fungible_asset.transfer_ref, to_wallet, fa
        );
    }

    // <:!:mint
    public(friend) fun transfer_from(
        from: address,
        to: address,
        amount: u64,
        metadata_address: address
    ) acquires ManagedFungibleAsset {
        let asset = get_metadata(metadata_address);
        let transfer_ref = &authorized_borrow_refs_without_permission(asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::transfer_with_ref(transfer_ref, from_wallet, to_wallet, amount);
    }

    /// Burn fungible assets as the owner of metadata object.
    public(friend) fun burn(
        from: address, amount: u64, metadata_address: address
    ) acquires ManagedFungibleAsset {
        let asset = get_metadata(metadata_address);
        let burn_ref = &authorized_borrow_refs_without_permission(asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    #[view]
    /// Get the current supply from the `metadata` object.
    public fun supply(metadata_address: address): Option<u128> {
        let asset = get_metadata(metadata_address);
        fungible_asset::supply(asset)
    }

    #[view]
    /// Get the maximum supply from the `metadata` object.
    public fun maximum(metadata_address: address): Option<u128> {
        let asset = get_metadata(metadata_address);
        fungible_asset::maximum(asset)
    }

    #[view]
    /// Get the name of the fungible asset from the `metadata` object.
    public fun name(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::name(asset)
    }

    #[view]
    /// Get the symbol of the fungible asset from the `metadata` object.
    public fun symbol(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::symbol(asset)
    }

    #[view]
    /// Get the decimals from the `metadata` object.
    public fun decimals(metadata_address: address): u8 {
        let asset = get_metadata(metadata_address);
        fungible_asset::decimals(asset)
    }

    #[view]
    /// Get the balance of a given store.
    public fun balance_of(owner: address, metadata_address: address): u64 {
        let metadata = get_metadata(metadata_address);
        primary_fungible_store::balance(owner, metadata)
    }

    #[view]
    public fun token_address(symbol: String): address {
        object::create_object_address(&@underlying_tokens, *string::bytes(&symbol))
    }

    /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_refs(
        owner: &signer, asset: Object<Metadata>
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ENOT_OWNER)
        );

        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    inline fun authorized_borrow_refs_without_permission(
        asset: Object<Metadata>
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    fun only_token_admin(account: &signer) {
        assert!(signer::address_of(account) == @underlying_tokens, ENOT_OWNER)
    }

    #[test_only]
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }
}
