script {
    // std
    use std::option;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::debug::print;
    use aptos_std::smart_table;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Self;
    // locals
    use aave_config::reserve_config;
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

        // assemble each reserve's configuration
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
            let underlying_asset_decimals =
                fungible_asset::decimals(underlying_asset_metadata);

            let reserve_config =
                if (network == utf8(APTOS_MAINNET)) {
                    smart_table::borrow(
                        aave_data::v1::get_reserves_config_mainnet(),
                        underlying_asset_symbol
                    )
                } else if (network == utf8(APTOS_TESTNET)) {
                    smart_table::borrow(
                        aave_data::v1::get_reserves_config_testnet(),
                        underlying_asset_symbol
                    )
                } else {
                    smart_table::borrow(
                        aave_data::v1::get_reserves_config_testnet(),
                        underlying_asset_symbol
                    )
                };
            let debt_ceiling = aave_data::v1_values::get_debt_ceiling(reserve_config);
            let flashLoan_enabled =
                aave_data::v1_values::get_flashLoan_enabled(reserve_config);
            let borrowable_isolation =
                aave_data::v1_values::get_borrowable_isolation(reserve_config);
            let supply_cap = aave_data::v1_values::get_supply_cap(reserve_config);
            let borrow_cap = aave_data::v1_values::get_borrow_cap(reserve_config);
            let ltv = aave_data::v1_values::get_base_ltv_as_collateral(reserve_config);
            let borrowing_enabled =
                aave_data::v1_values::get_borrowing_enabled(reserve_config);
            let reserve_factor = aave_data::v1_values::get_reserve_factor(reserve_config);
            let liquidation_threshold =
                aave_data::v1_values::get_liquidation_threshold(reserve_config);
            let liquidation_bonus =
                aave_data::v1_values::get_liquidation_bonus(reserve_config);
            let liquidation_protocol_fee =
                aave_data::v1_values::get_liquidation_protocol_fee(reserve_config);
            let siloed_borrowing =
                aave_data::v1_values::get_siloed_borrowing(reserve_config);

            let reserve_config_new = reserve_config::init();
            reserve_config::set_decimals(
                &mut reserve_config_new, (underlying_asset_decimals as u256)
            );
            reserve_config::set_liquidation_threshold(
                &mut reserve_config_new, liquidation_threshold
            );
            reserve_config::set_liquidation_bonus(
                &mut reserve_config_new, liquidation_bonus
            );
            reserve_config::set_liquidation_protocol_fee(
                &mut reserve_config_new, liquidation_protocol_fee
            );
            reserve_config::set_frozen(&mut reserve_config_new, false);
            reserve_config::set_paused(&mut reserve_config_new, false);
            reserve_config::set_reserve_factor(&mut reserve_config_new, reserve_factor);
            reserve_config::set_active(&mut reserve_config_new, true);
            reserve_config::set_flash_loan_enabled(
                &mut reserve_config_new, flashLoan_enabled
            );
            reserve_config::set_ltv(&mut reserve_config_new, ltv);
            reserve_config::set_debt_ceiling(&mut reserve_config_new, debt_ceiling);
            reserve_config::set_supply_cap(&mut reserve_config_new, supply_cap);
            reserve_config::set_borrow_cap(&mut reserve_config_new, borrow_cap);
            reserve_config::set_borrowable_in_isolation(
                &mut reserve_config_new, borrowable_isolation
            );
            reserve_config::set_siloed_borrowing(
                &mut reserve_config_new, siloed_borrowing
            );
            reserve_config::set_borrowing_enabled(
                &mut reserve_config_new, borrowing_enabled
            );
            let emode_category = aave_data::v1_values::get_emode_category(reserve_config);
            if (option::is_some(&emode_category)) {
                reserve_config::set_emode_category(
                    &mut reserve_config_new, *option::borrow(&emode_category)
                )
            };
            // attach the config to the reserve
            aave_pool::pool::set_reserve_configuration_with_guard(
                account, underlying_asset_address, reserve_config_new
            );
        };
    }
}
