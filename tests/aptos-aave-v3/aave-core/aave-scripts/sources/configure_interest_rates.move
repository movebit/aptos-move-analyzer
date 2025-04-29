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
    use aave_rate::default_reserve_interest_rate_strategy::Self;
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

        // fetch for each underlying asset the ir strategy config
        for (i in 0..smart_table::length(underlying_assets_map)) {
            let underlying_asset_name =
                *vector::borrow(&smart_table::keys(underlying_assets_map), i);
            let underlying_asset_address =
                *smart_table::borrow(underlying_assets_map, underlying_asset_name);
            let underlying_asset_metadata =
                object::address_to_object<Metadata>(underlying_asset_address);
            let underlying_asset_symbol =
                fungible_asset::symbol(underlying_asset_metadata);

            let interest_rate_strategy_map =
                if (network == utf8(APTOS_MAINNET)) {
                    smart_table::borrow(
                        aave_data::v1::get_interest_rate_strategy_mainnet(),
                        underlying_asset_symbol
                    )
                } else if (network == utf8(APTOS_TESTNET)) {
                    smart_table::borrow(
                        aave_data::v1::get_interest_rate_strategy_testnet(),
                        underlying_asset_symbol
                    )
                } else {
                    smart_table::borrow(
                        aave_data::v1::get_interest_rate_strategy_testnet(),
                        underlying_asset_symbol
                    )
                };

            // init the default interest rate strategy for each underlying_asset_address
            let optimal_usage_ratio =
                aave_data::v1_values::get_optimal_usage_ratio(interest_rate_strategy_map);
            let base_variable_borrow_rate =
                aave_data::v1_values::get_base_variable_borrow_rate(
                    interest_rate_strategy_map
                );
            let variable_rate_slope1 =
                aave_data::v1_values::get_variable_rate_slope1(interest_rate_strategy_map);
            let variable_rate_slope2: u256 =
                aave_data::v1_values::get_variable_rate_slope2(interest_rate_strategy_map);

            // set the default ir strategy per underlying asset
            default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(
                account,
                underlying_asset_address,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );
        };
    }
}
