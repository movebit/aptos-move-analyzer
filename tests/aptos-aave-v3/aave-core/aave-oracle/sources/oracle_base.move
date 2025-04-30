module aave_oracle::oracle_base {

    use std::signer;
    use aptos_std::smart_table;
    use aptos_framework::event;
    use std::option::{Self, Option};
    use std::string::String;
    use aave_acl::acl_manage;
    use aptos_framework::account::{Self, SignerCapability};
    use aave_config::error_config::Self;

    // friends
    friend aave_oracle::price_cap_stable_adapter;
    friend aave_oracle::oracle;

    // consts
    const AAVE_ORACLE_SEED: vector<u8> = b"AAVE_ORACLE";

    // errors
    const E_ORACLE_NOT_ADMIN: u64 = 1;
    const E_ASSET_ALREADY_EXISTS: u64 = 2;
    const E_NO_ASSET_FEED: u64 = 3;
    const E_ORACLE_BENCHMARK_LENGHT_MISMATCH: u64 = 4;

    #[event]
    struct AssetPriceFeedUpdated has store, drop {
        asset: address,
        feed_id: vector<u8>
    }

    #[event]
    struct AssetPriceFeedRemoved has store, drop {
        asset: address,
        feed_id: vector<u8>
    }

    struct BaseCurrency has copy, key, store, drop {
        asset: String,
        unit: u64
    }

    struct PriceOracleData has key {
        asset_feed_ids: smart_table::SmartTable<address, vector<u8>>,
        signer_cap: SignerCapability,
        base_currency: Option<BaseCurrency>
    }

    public fun only_oracle_admin(account: &signer) {
        assert!(signer::address_of(account) == @aave_oracle, E_ORACLE_NOT_ADMIN);
    }

    /// @dev Only risk or pool admin can call functions marked by this modifier.
    public(friend) fun only_risk_or_pool_admin(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(
            acl_manage::is_pool_admin(account_address)
                || acl_manage::is_risk_admin(account_address),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
    }

    #[test_only]
    public fun test_only_risk_or_pool_admin(account: &signer) {
        only_risk_or_pool_admin(account);
    }

    #[test_only]
    public fun test_init_oracle(account: &signer) {
        init_oracle(account);
    }

    public(friend) fun init_oracle(account: &signer) {
        only_oracle_admin(account);

        // create a resource account
        let (resource_signer, signer_cap) =
            account::create_resource_account(account, AAVE_ORACLE_SEED);

        move_to(
            &resource_signer,
            PriceOracleData {
                asset_feed_ids: smart_table::new(),
                signer_cap,
                base_currency: option::none()
            }
        )
    }

    public fun get_base_currency_unit(base_currency: &BaseCurrency): u64 {
        base_currency.unit
    }

    public fun get_base_currency_asset(base_currency: &BaseCurrency): String {
        base_currency.asset
    }

    #[view]
    public fun get_oracle_base_currency(): Option<BaseCurrency> acquires PriceOracleData {
        // get the oracle data
        let oracle_data = borrow_global_mut<PriceOracleData>(oracle_address());
        // check and return if exists
        if (option::is_some(&oracle_data.base_currency)) {
            option::some(*option::borrow(&oracle_data.base_currency))
        } else {
            option::none<BaseCurrency>()
        }
    }

    #[view]
    public fun get_oracle_resource_account(): address acquires PriceOracleData {
        let collector_data = borrow_global<PriceOracleData>(oracle_address());
        let account_signer =
            account::create_signer_with_capability(&collector_data.signer_cap);
        signer::address_of(&account_signer)
    }

    #[view]
    public fun oracle_address(): address {
        account::create_resource_address(&@aave_oracle, AAVE_ORACLE_SEED)
    }

    public(friend) fun get_resource_account_signer(): signer acquires PriceOracleData {
        let oracle_data = borrow_global<PriceOracleData>(oracle_address());
        account::create_signer_with_capability(&oracle_data.signer_cap)
    }

    #[test_only]
    public fun get_resource_account_signer_for_testing(): signer acquires PriceOracleData {
        get_resource_account_signer()
    }

    public(friend) fun set_asset_feed_id(
        asset: address, feed_id: vector<u8>
    ) acquires PriceOracleData {
        let asset_price_list = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::upsert(&mut asset_price_list.asset_feed_ids, asset, feed_id);
    }

    #[test_only]
    public fun test_set_asset_feed_id(
        asset: address, feed_id: vector<u8>
    ) acquires PriceOracleData {
        set_asset_feed_id(asset, feed_id);
    }

    public(friend) fun assert_asset_feed_id_exists(
        asset: address
    ): vector<u8> acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        assert!(
            smart_table::contains(&asset_price_list.asset_feed_ids, asset),
            E_NO_ASSET_FEED
        );
        *smart_table::borrow(&asset_price_list.asset_feed_ids, asset)
    }

    public(friend) fun get_feed_id(asset: address): vector<u8> acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        let feed_id = *smart_table::borrow(&asset_price_list.asset_feed_ids, asset);
        feed_id
    }

    #[test_only]
    public fun test_get_feed_id(asset: address): vector<u8> acquires PriceOracleData {
        get_feed_id(asset)
    }

    public(friend) fun remove_feed_id(asset: address) acquires PriceOracleData {
        let asset_price_list = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::remove(&mut asset_price_list.asset_feed_ids, asset);
    }

    #[test_only]
    public fun test_remove_feed_id(asset: address) acquires PriceOracleData {
        remove_feed_id(asset)
    }

    public(friend) fun emit_asset_price_feed_updated(
        asset: address, feed_id: vector<u8>
    ) {
        event::emit(AssetPriceFeedUpdated { asset, feed_id })
    }

    public(friend) fun emit_asset_price_feed_removed(
        asset: address, feed_id: vector<u8>
    ) {
        event::emit(AssetPriceFeedRemoved { asset, feed_id })
    }

    public(friend) fun assert_benchmarks_match_assets(
        benchmarks_len: u64, requested_assets: u64
    ) {
        assert!(
            benchmarks_len == requested_assets,
            E_ORACLE_BENCHMARK_LENGHT_MISMATCH
        );
    }
}
