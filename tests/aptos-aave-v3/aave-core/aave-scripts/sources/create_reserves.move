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
    use aave_pool::collector;
    use aave_pool::pool_configurator;
    use aave_acl::acl_manage::Self;
    use aave_config::error_config;

    const APTOS_MAINNET: vector<u8> = b"mainnet";
    const APTOS_TESTNET: vector<u8> = b"testnet";

    fun main(account: &signer, network: String) {
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(account))
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

        // prepare pool reserves
        let treasuries: vector<address> = vector[];
        let underlying_assets: vector<address> = vector[];
        let underlying_asset_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let collector_address = collector::collector_address();

        for (i in 0..smart_table::length(underlying_assets_map)) {
            // get underlying asset data
            let underlying_asset_name =
                *vector::borrow(&smart_table::keys(underlying_assets_map), i);
            let underlying_asset_address =
                *smart_table::borrow(underlying_assets_map, underlying_asset_name);
            let underlying_asset_metadata =
                object::address_to_object<Metadata>(underlying_asset_address);
            let underlying_asset_symbol =
                fungible_asset::symbol(underlying_asset_metadata);

            // prepare the data for reserves' atokens and variable tokens
            vector::push_back(&mut underlying_assets, underlying_asset_address);
            vector::push_back(
                &mut underlying_asset_decimals,
                fungible_asset::decimals(underlying_asset_metadata)
            );
            vector::push_back(&mut treasuries, collector_address);
            vector::push_back(
                &mut atokens_names,
                aave_data::v1::get_atoken_name(underlying_asset_symbol)
            );
            vector::push_back(
                &mut atokens_symbols,
                aave_data::v1::get_atoken_symbol(underlying_asset_symbol)
            );
            vector::push_back(
                &mut var_tokens_names,
                aave_data::v1::get_vartoken_name(underlying_asset_symbol)
            );
            vector::push_back(
                &mut var_tokens_symbols,
                aave_data::v1::get_vartoken_symbol(underlying_asset_symbol)
            );
        };
        // create pool reserves in one go
        pool_configurator::init_reserves(
            account,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols
        );
    }
}
