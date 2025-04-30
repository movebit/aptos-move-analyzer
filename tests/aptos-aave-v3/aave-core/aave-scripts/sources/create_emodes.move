script {
    // std
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::debug::print;
    use aptos_std::smart_table;
    // locals
    use aave_pool::pool_configurator;
    use aave_acl::acl_manage::Self;
    use aave_config::error_config;
    use aave_oracle::oracle_base;

    const APTOS_MAINNET: vector<u8> = b"mainnet";
    const APTOS_TESTNET: vector<u8> = b"testnet";

    fun main(account: &signer, network: String) {
        assert!(
            acl_manage::is_risk_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );

        // get all underlying assets
        let emodes_map =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_emodes_mainnet()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_emodes_testnet()
            } else {
                print(&b"Unknown network");
                assert!(false, 1);
            };

        for (i in 0..smart_table::length(emodes_map)) {
            let emode_category_id = *vector::borrow(&smart_table::keys(emodes_map), i);
            let emode_config = *smart_table::borrow(emodes_map, emode_category_id);

            let emode_category_id =
                aave_data::v1_values::get_emode_category_id(&emode_config);
            let emode_liquidation_label =
                aave_data::v1_values::get_emode_liquidation_label(&emode_config);
            let emode_liquidation_threshold =
                aave_data::v1_values::get_emode_liquidation_threshold(&emode_config);
            let emode_liquidation_bonus =
                aave_data::v1_values::get_emode_liquidation_bonus(&emode_config);
            let emode_ltv = aave_data::v1_values::get_emode_ltv(&emode_config);

            // create the emode
            pool_configurator::set_emode_category(
                account,
                (emode_category_id as u8),
                (emode_ltv as u16),
                (emode_liquidation_threshold as u16),
                (emode_liquidation_bonus as u16),
                oracle_base::oracle_address(),
                emode_liquidation_label
            );
        };

    }
}
