module aave_pool::admin_controlled_ecosystem_reserve {
    use aptos_std::smart_table::{Self, SmartTable};
    use aave_acl::acl_manage::{Self};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::primary_fungible_store;
    use std::signer;
    use aptos_framework::object::{
        Self,
        Object,
        ExtendRef as ObjExtendRef,
        TransferRef as ObjectTransferRef
    };
    use aptos_framework::event;

    const NOT_FUNDS_ADMIN: u64 = 1;

    const REVISION: u256 = 2;

    const ONLY_BY_FUNDS_ADMIN: u64 = 3;

    const ADMIN_CONTROLLED_ECOSYSTEM_RESERVE: vector<u8> = b"ADMIN_CONTROLLED_ECOSYSTEM_RESERVE";

    #[event]
    struct NewFundsAdmin has store, drop {
        funds_admin: address
    }

    struct AdminControlledEcosystemReserveData has key {
        fungible_assets: SmartTable<Object<Metadata>, Object<FungibleStore>>,
        extend_ref: ObjExtendRef,
        transfer_ref: ObjectTransferRef,
        funds_admin: address
    }

    public fun initialize(sender: &signer) {
        let state_object_constructor_ref =
            &object::create_named_object(sender, ADMIN_CONTROLLED_ECOSYSTEM_RESERVE);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            AdminControlledEcosystemReserveData {
                fungible_assets: smart_table::new<Object<Metadata>, Object<FungibleStore>>(),
                transfer_ref: object::generate_transfer_ref(state_object_constructor_ref),
                extend_ref: object::generate_extend_ref(state_object_constructor_ref),
                funds_admin: signer::address_of(sender)
            }
        );
    }

    public fun check_is_funds_admin(account: address) {
        assert!(
            acl_manage::is_admin_controlled_ecosystem_reserve_funds_admin(account),
            NOT_FUNDS_ADMIN
        );
    }

    public fun get_revision(): u256 {
        REVISION
    }

    public fun get_funds_admin(): address acquires AdminControlledEcosystemReserveData {
        let admin_controlled_ecosystem_reserve_data =
            borrow_global_mut<AdminControlledEcosystemReserveData>(
                admin_controlled_ecosystem_reserve_address()
            );
        let account = admin_controlled_ecosystem_reserve_data.funds_admin;
        check_is_funds_admin(account);
        account
    }

    #[view]
    public fun admin_controlled_ecosystem_reserve_address(): address {
        object::create_object_address(&@aave_pool, ADMIN_CONTROLLED_ECOSYSTEM_RESERVE)
    }

    #[view]
    public fun admin_controlled_ecosystem_reserve_object():
        Object<AdminControlledEcosystemReserveData> {
        object::address_to_object<AdminControlledEcosystemReserveData>(
            admin_controlled_ecosystem_reserve_address()
        )
    }

    fun set_funds_admin_internal(
        admin: &signer, account: address
    ) acquires AdminControlledEcosystemReserveData {
        let admin_controlled_ecosystem_reserve_data =
            borrow_global_mut<AdminControlledEcosystemReserveData>(
                admin_controlled_ecosystem_reserve_address()
            );
        acl_manage::remove_admin_controlled_ecosystem_reserve_funds_admin(
            admin, admin_controlled_ecosystem_reserve_data.funds_admin
        );
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(admin, account);
        admin_controlled_ecosystem_reserve_data.funds_admin = account;

        event::emit(NewFundsAdmin { funds_admin: account });
    }

    public fun transfer_out(
        sender: &signer,
        asset_metadata: Object<Metadata>,
        receiver: address,
        amount: u64
    ) acquires AdminControlledEcosystemReserveData {
        check_is_funds_admin(signer::address_of(sender));

        let admin_controlled_ecosystem_reserve_data =
            borrow_global_mut<AdminControlledEcosystemReserveData>(
                admin_controlled_ecosystem_reserve_address()
            );

        if (smart_table::contains(
            &admin_controlled_ecosystem_reserve_data.fungible_assets, asset_metadata
        )) {
            let collector_fungible_store =
                smart_table::borrow(
                    &admin_controlled_ecosystem_reserve_data.fungible_assets,
                    asset_metadata
                );
            let collector_fungible_store_signer =
                object::generate_signer_for_extending(
                    &admin_controlled_ecosystem_reserve_data.extend_ref
                );
            let receiver_fungible_store =
                primary_fungible_store::ensure_primary_store_exists(
                    receiver, asset_metadata
                );

            fungible_asset::transfer(
                &collector_fungible_store_signer,
                *collector_fungible_store,
                receiver_fungible_store,
                amount
            );
        }
    }

    #[test_only]
    use aave_pool::standard_token::{Self};
    #[test_only]
    use std::string::utf8;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test_only]
    fun create_test_fa(creator: &signer): Object<Metadata> {
        let test_symbol = b"TEST";
        standard_token::initialize(
            creator,
            0,
            utf8(b"Test Token"),
            utf8(test_symbol),
            8,
            utf8(b"http://example.com/favicon.ico"),
            utf8(b"http://example.com"),
            vector[true, true, true],
            @0x1,
            false
        );
        let metadata_address =
            object::create_object_address(&signer::address_of(creator), test_symbol);
        object::address_to_object<Metadata>(metadata_address)
    }

    #[
        test(
            fa_creator = @aave_pool,
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222
        )
    ]
    fun test_basic_flow(
        fa_creator: &signer,
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer
    ) acquires AdminControlledEcosystemReserveData {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);
        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        check_is_funds_admin(signer::address_of(acl_fund_admin));

        // create test token
        let metadata = create_test_fa(fa_creator);

        // mint coins to user
        let _creator_address = signer::address_of(fa_creator);
        let user_address = signer::address_of(user_account);
        standard_token::mint_to_primary_stores(
            fa_creator,
            metadata,
            vector[user_address],
            vector[100]
        );
        assert!(
            primary_fungible_store::balance(user_address, metadata) == 100, TEST_SUCCESS
        );

        // user withdraws all fas he has
        let fa =
            standard_token::withdraw_from_primary_stores(
                fa_creator,
                metadata,
                vector[user_address],
                vector[100]
            );
        assert!(fungible_asset::amount(&fa) == 100, TEST_SUCCESS);

        initialize(periphery_account);

        let asset_metadata = fungible_asset::metadata_from_asset(&fa);

        let admin_controlled_ecosystem_reserve_data =
            borrow_global_mut<AdminControlledEcosystemReserveData>(
                admin_controlled_ecosystem_reserve_address()
            );

        let asset_object_constructor_ref =
            object::create_object(admin_controlled_ecosystem_reserve_address());
        let collector_fungible_store =
            fungible_asset::create_store(&asset_object_constructor_ref, asset_metadata);

        fungible_asset::deposit(collector_fungible_store, fa);

        smart_table::upsert(
            &mut admin_controlled_ecosystem_reserve_data.fungible_assets,
            asset_metadata,
            collector_fungible_store
        );

        transfer_out(acl_fund_admin, metadata, user_address, 50);
    }

    #[
        test(
            fa_creator = @aave_pool,
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222
        )
    ]
    fun test_set_funds_admin_internal(
        fa_creator: &signer,
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer
    ) acquires AdminControlledEcosystemReserveData {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);
        // set fund admin
        acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );
        // assert role is granted
        check_is_funds_admin(signer::address_of(acl_fund_admin));

        // create test token
        let metadata = create_test_fa(fa_creator);

        // mint coins to user
        let _creator_address = signer::address_of(fa_creator);
        let user_address = signer::address_of(user_account);
        standard_token::mint_to_primary_stores(
            fa_creator,
            metadata,
            vector[user_address],
            vector[100]
        );
        assert!(
            primary_fungible_store::balance(user_address, metadata) == 100, TEST_SUCCESS
        );

        // user withdraws all fas he has
        let fa =
            standard_token::withdraw_from_primary_stores(
                fa_creator,
                metadata,
                vector[user_address],
                vector[100]
            );
        assert!(fungible_asset::amount(&fa) == 100, TEST_SUCCESS);

        initialize(periphery_account);

        let asset_metadata = fungible_asset::metadata_from_asset(&fa);

        let admin_controlled_ecosystem_reserve_data =
            borrow_global_mut<AdminControlledEcosystemReserveData>(
                admin_controlled_ecosystem_reserve_address()
            );

        let asset_object_constructor_ref =
            object::create_object(admin_controlled_ecosystem_reserve_address());
        let collector_fungible_store =
            fungible_asset::create_store(&asset_object_constructor_ref, asset_metadata);

        fungible_asset::deposit(collector_fungible_store, fa);

        smart_table::upsert(
            &mut admin_controlled_ecosystem_reserve_data.fungible_assets,
            asset_metadata,
            collector_fungible_store
        );

        transfer_out(acl_fund_admin, metadata, user_address, 50);

        set_funds_admin_internal(aave_role_super_admin, user_address);
    }
}
