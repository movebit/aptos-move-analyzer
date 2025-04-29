module aave_pool::coin_migrator {
    use std::signer;
    use std::option;
    use std::string::String;
    use aptos_std::type_info::Self;
    use aptos_framework::fungible_asset::Self;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::object;
    use aptos_framework::coin::{Self};
    use aptos_framework::event;
    use aave_config::error_config;

    #[event]
    struct CointToFaConvertion has store, drop {
        user: address,
        amount: u64,
        name: String,
        symbol: String,
        decimals: u8,
        coin_address: address,
        fa_address: address
    }

    #[event]
    struct FaToCointConvertion has store, drop {
        user: address,
        amount: u64,
        name: String,
        symbol: String,
        decimals: u8,
        coin_address: address,
        fa_address: address
    }

    public entry fun coin_to_fa<CoinType>(account: &signer, amount: u64) {
        assert!(
            coin::balance<CoinType>(signer::address_of(account)) >= amount,
            error_config::get_einsufficient_coins_to_wrap()
        );
        let coin_type = type_info::type_of<CoinType>();
        let coin_to_wrap = coin::withdraw<CoinType>(account, amount);
        let wrapped_fa = coin::coin_to_fungible_asset<CoinType>(coin_to_wrap);
        let wrapped_fa_meta = fungible_asset::metadata_from_asset(&wrapped_fa);
        let wrapped_fa_address = object::object_address(&wrapped_fa_meta);
        let account_wallet =
            primary_fungible_store::ensure_primary_store_exists(
                signer::address_of(account), wrapped_fa_meta
            );
        fungible_asset::deposit(account_wallet, wrapped_fa);

        event::emit(
            CointToFaConvertion {
                user: signer::address_of(account),
                amount,
                name: fungible_asset::name(wrapped_fa_meta),
                symbol: fungible_asset::symbol(wrapped_fa_meta),
                decimals: fungible_asset::decimals(wrapped_fa_meta),
                coin_address: type_info::account_address(&coin_type),
                fa_address: wrapped_fa_address
            }
        );
    }

    public entry fun fa_to_coin<CoinType>(user: &signer, amount: u64) {
        let coin_type = type_info::type_of<CoinType>();
        let wrapped_fa_meta = coin::paired_metadata<CoinType>();
        assert!(
            option::is_some(&wrapped_fa_meta),
            error_config::get_eunmapped_coin_to_fa()
        );
        let wrapped_fa_meta = option::destroy_some(wrapped_fa_meta);
        let user_fa_store =
            primary_fungible_store::ensure_primary_store_exists(
                signer::address_of(user), wrapped_fa_meta
            );
        assert!(
            fungible_asset::balance(user_fa_store) >= amount,
            error_config::get_einsufficient_fas_to_unwrap()
        );
        let wrapped_fa_address = object::object_address(&wrapped_fa_meta);
        let withdrawn_coins = coin::withdraw<CoinType>(user, amount);
        coin::deposit<CoinType>(signer::address_of(user), withdrawn_coins);

        event::emit(
            FaToCointConvertion {
                user: signer::address_of(user),
                amount,
                name: fungible_asset::name(wrapped_fa_meta),
                symbol: fungible_asset::symbol(wrapped_fa_meta),
                decimals: fungible_asset::decimals(wrapped_fa_meta),
                coin_address: type_info::account_address(&coin_type),
                fa_address: wrapped_fa_address
            }
        );
    }

    #[view]
    public fun get_fa_address<CoinType>(): address {
        let wrapped_fa_meta = coin::paired_metadata<CoinType>();
        assert!(
            option::is_some(&wrapped_fa_meta),
            error_config::get_eunmapped_coin_to_fa()
        );
        let wrapped_fa_meta = option::destroy_some(wrapped_fa_meta);
        object::object_address(&wrapped_fa_meta)
    }
}
