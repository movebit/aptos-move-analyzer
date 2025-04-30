script {
    // std
    use std::option::{Self, Option};
    use std::signer;
    use std::vector;
    // locals
    use aave_acl::acl_manage::Self;

    fun main(
        account: &signer,
        pool_admins: vector<Option<address>>,
        asset_listing_admins: vector<Option<address>>,
        risk_admins: vector<Option<address>>,
        fund_admins: vector<Option<address>>,
        emergency_admins: vector<Option<address>>,
        flash_borrower_admins: vector<Option<address>>,
        bridge_admins: vector<Option<address>>,
        emission_admins: vector<Option<address>>,
        admin_controlled_ecosystem_reserve_funds_admins: vector<Option<address>>,
        rewards_controller_admins: vector<Option<address>>
    ) {
        assert!(signer::address_of(account) == @aave_acl);

        acl_manage::grant_default_admin_role(account);
        vector::for_each(
            pool_admins,
            |admin| {
                acl_manage::add_pool_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            asset_listing_admins,
            |admin| {
                acl_manage::add_asset_listing_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            risk_admins,
            |admin| {
                acl_manage::add_risk_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            fund_admins,
            |admin| {
                acl_manage::add_funds_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            emergency_admins,
            |admin| {
                acl_manage::add_emergency_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            flash_borrower_admins,
            |admin| {
                acl_manage::add_flash_borrower(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            bridge_admins,
            |admin| {
                acl_manage::add_bridge(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            emission_admins,
            |admin| {
                acl_manage::add_emission_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            admin_controlled_ecosystem_reserve_funds_admins,
            |admin| {
                acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );

        vector::for_each(
            rewards_controller_admins,
            |admin| {
                acl_manage::add_rewards_controller_admin(
                    account, option::destroy_with_default(admin, @aave_pool)
                );
            }
        );
    }
}
