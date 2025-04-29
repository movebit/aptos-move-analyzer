module aave_oracle::price_cap_stable_adapter {
    use aptos_framework::event::Self;
    use std::signer;
    use aave_acl::acl_manage;
    use aave_config::error_config::Self;
    use std::string::String;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::address_to_object;
    use aave_oracle::oracle::Self;

    // errors
    const E_ORACLE_NOT_ADMIN: u64 = 1;
    const E_CAP_LOWER_THAN_ACTUAL_PRICE: u64 = 2;

    // events
    #[event]
    struct PriceCapUpdated has store, drop {
        price_cap: u256
    }

    struct InternalData has key {
        asset: address,
        decimals: u8,
        description: String,
        price_cap: u256
    }

    fun only_oracle_admin(account: &signer) {
        assert!(signer::address_of(account) == @aave_oracle, E_ORACLE_NOT_ADMIN);
    }

    fun only_risk_or_pool_admin(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(
            acl_manage::is_pool_admin(account_address)
                || acl_manage::is_risk_admin(account_address),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
    }

    public fun init_price_cap_stable_adaptor(
        account: &signer,
        asset: address,
        description: String,
        price_cap: u256
    ) {
        only_oracle_admin(account);
        let base_price = oracle::get_asset_price(asset);
        assert!(price_cap >= base_price, E_CAP_LOWER_THAN_ACTUAL_PRICE);
        event::emit(PriceCapUpdated { price_cap });

        move_to(
            account,
            InternalData {
                asset,
                decimals: fungible_asset::decimals(address_to_object<Metadata>(asset)),
                description,
                price_cap
            }
        )
    }

    public entry fun set_price_cap(account: &signer, price_cap: u256) acquires InternalData {
        only_risk_or_pool_admin(account);
        set_price_cap_internal(price_cap);
    }

    fun set_price_cap_internal(price_cap: u256) acquires InternalData {
        let internal_data = borrow_global_mut<InternalData>(@aave_oracle);
        let base_price = oracle::get_asset_price(internal_data.asset);
        assert!(price_cap >= base_price, E_CAP_LOWER_THAN_ACTUAL_PRICE);
        internal_data.price_cap = price_cap;
        event::emit(PriceCapUpdated { price_cap })
    }

    #[view]
    public fun is_capped(): bool acquires InternalData {
        let internal_data = borrow_global<InternalData>(@aave_oracle);
        oracle::get_asset_price(internal_data.asset) > latestAnswer()
    }

    #[view]
    public fun latestAnswer(): u256 acquires InternalData {
        let internal_data = borrow_global<InternalData>(@aave_oracle);
        let base_price = oracle::get_asset_price(internal_data.asset);
        if (base_price > internal_data.price_cap) {
            return internal_data.price_cap
        };
        base_price
    }

    #[view]
    public fun get_price_cap(): u256 acquires InternalData {
        borrow_global<InternalData>(@aave_oracle).price_cap
    }
}
