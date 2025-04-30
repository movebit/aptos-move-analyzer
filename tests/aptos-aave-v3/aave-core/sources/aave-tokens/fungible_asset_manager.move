module aave_pool::fungible_asset_manager {
    use std::option::Option;
    use std::string::String;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;

    use aave_config::error_config;

    friend aave_pool::a_token_factory;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;
    friend aave_pool::bridge_logic;
    friend aave_pool::flashloan_logic;

    /// @notice Transfer a given amount of the asset to a recipient.
    /// @dev Only callable by the supply_logic, borrow_logic, liquidation_logic, bridge_logic, flashloan_logic and a_token_factory module.
    /// @param from The account signer of the caller
    /// @param to The recipient of the asset
    /// @param amount The amount to transfer
    /// @param metadata_address The address of the metadata object
    public(friend) fun transfer(
        from: &signer,
        to: address,
        amount: u64,
        metadata_address: address
    ) {
        let asset_metadata = get_metadata(metadata_address);
        primary_fungible_store::transfer(from, asset_metadata, to, amount);
    }

    /// Return the address of the managed fungible asset that's created when this module is deployed.
    fun get_metadata(metadata_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(metadata_address)
    }

    public fun assert_token_exists(metadata_address: address) {
        assert!(
            object::object_exists<Metadata>(metadata_address),
            error_config::get_eresource_not_exist()
        )
    }

    #[view]
    /// Get the balance of a given store.
    public fun balance_of(owner: address, metadata_address: address): u64 {
        let metadata = get_metadata(metadata_address);
        primary_fungible_store::balance(owner, metadata)
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
}
