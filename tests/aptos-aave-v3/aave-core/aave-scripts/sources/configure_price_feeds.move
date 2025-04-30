script {
    // std
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::debug::print;
    use aptos_std::smart_table;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Self;
    // locals
    use aave_acl::acl_manage::Self;
    use aave_config::error_config;
    use aave_oracle::oracle::Self;
    use aave_pool::pool;

    const APTOS_MAINNET: vector<u8> = b"mainnet";
    const APTOS_TESTNET: vector<u8> = b"testnet";

    fun main(account: &signer, network: String) {
        assert!(
            acl_manage::is_risk_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );

        // get all underlying assets
        let underlying_assets_map =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_underlying_assets_mainnet()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_underlying_assets_testnet()
            } else {
                print(&b"Unknown network");
                assert!(false, 1);
            };

        // set feed ids for underlying assets, atokens and vartokens
        for (i in 0..smart_table::length(underlying_assets_map)) {
            // get all underlying data
            let underlying_asset_name =
                *vector::borrow(&smart_table::keys(underlying_assets_map), i);
            let underlying_asset_address =
                *smart_table::borrow(underlying_assets_map, underlying_asset_name);
            let underlying_asset_metadata =
                object::address_to_object<Metadata>(underlying_asset_address);
            let underlying_asset_symbol =
                fungible_asset::symbol(underlying_asset_metadata);
            let reserve_data = pool::get_reserve_data(underlying_asset_address);

            let price_feed =
                if (network == utf8(APTOS_MAINNET)) {
                    smart_table::borrow(
                        aave_data::v1::get_price_feeds_mainnet(),
                        underlying_asset_symbol
                    )
                } else if (network == utf8(APTOS_TESTNET)) {
                    smart_table::borrow(
                        aave_data::v1::get_price_feeds_tesnet(),
                        underlying_asset_symbol
                    )
                } else {
                    smart_table::borrow(
                        aave_data::v1::get_price_feeds_tesnet(),
                        underlying_asset_symbol
                    )
                };
            oracle::set_asset_feed_id(account, underlying_asset_address, *price_feed);
            oracle::set_asset_feed_id(
                account, pool::get_reserve_a_token_address(&reserve_data), *price_feed
            );
            oracle::set_asset_feed_id(
                account,
                pool::get_reserve_variable_debt_token_address(&reserve_data),
                *price_feed
            );
        };
    }
}
