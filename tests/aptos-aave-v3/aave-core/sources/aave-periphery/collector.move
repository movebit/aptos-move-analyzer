module aave_pool::collector {
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore, FungibleAsset};
    use aptos_framework::object::{
        Self,
        Object,
        ObjectGroup,
        ExtendRef as ObjExtendRef,
        TransferRef as ObjectTransferRef
    };
    use aptos_framework::primary_fungible_store;
    use aave_acl::acl_manage::{Self};
    use aptos_std::smart_table::{Self, SmartTable};
    use std::signer;

    // Not an asset listing or a pool admin error
    const NOT_FUNDS_ADMIN: u64 = 1;
    /// Only fungible asset metadata owner can make changes.
    const ERR_NOT_OWNER: u64 = 1;
    /// Contract revision
    const REVISION: u64 = 1;
    /// Collector name
    const COLLECTOR_NAME: vector<u8> = b"AAVE_COLLECTOR";

    // mapping between metadata address - secondary fungible store for that asset
    #[resource_group_member(group = ObjectGroup)]
    struct CollectorData has key {
        // this smart table only keeps track of objects references (does not store them)
        fungible_assets: SmartTable<Object<Metadata>, Object<FungibleStore>>,
        extend_ref: ObjExtendRef,
        transfer_ref: ObjectTransferRef
    }

    fun is_funds_admin(account: address) {
        assert!(check_is_funds_admin(account), NOT_FUNDS_ADMIN);
    }

    #[view]
    public fun check_is_funds_admin(account: address): bool {
        acl_manage::is_funds_admin(account)
    }

    /// Initialize metadata object and store the refs specified by `ref_flags`.
    fun init_module(sender: &signer) {
        // 1, create the object and a generate a signer
        let state_object_constructor_ref =
            &object::create_named_object(sender, COLLECTOR_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        // 2. move the resources into it, incl. the references
        move_to(
            state_object_signer,
            CollectorData {
                fungible_assets: smart_table::new<Object<Metadata>, Object<FungibleStore>>(),
                transfer_ref: object::generate_transfer_ref(state_object_constructor_ref),
                extend_ref: object::generate_extend_ref(state_object_constructor_ref)
            }
        );
    }

    #[test_only]
    public fun init_module_test(sender: &signer) {
        init_module(sender);
    }

    #[view]
    /// Return the revision of the aave token implementation
    public fun get_revision(): u64 {
        REVISION
    }

    #[view]
    public fun collector_address(): address {
        object::create_object_address(&@aave_pool, COLLECTOR_NAME)
    }

    #[view]
    public fun collector_object(): Object<CollectorData> {
        object::address_to_object<CollectorData>(collector_address())
    }

    fun generate_secondary_collector_fungible_store(
        asset_metadata: Object<Metadata>
    ): Object<FungibleStore> {
        let asset_object_constructor_ref = object::create_object(collector_address()); // make the collector address be the owner
        let collector_fungible_store =
            fungible_asset::create_store(&asset_object_constructor_ref, asset_metadata);
        collector_fungible_store
    }

    public fun deposit(sender: &signer, fa: FungibleAsset) acquires CollectorData {
        // check sender is the fund admin
        is_funds_admin(signer::address_of(sender));

        let asset_metadata = fungible_asset::metadata_from_asset(&fa);
        // get mutably the resource CollectorData stored inside the named object
        let collector_data = borrow_global_mut<CollectorData>(collector_address());

        if (!smart_table::contains(&collector_data.fungible_assets, asset_metadata)) {
            // create fungible store (object) with the collector being its address(owner)
            let collector_fungible_store =
                generate_secondary_collector_fungible_store(asset_metadata);

            // deposit the fa
            fungible_asset::deposit(collector_fungible_store, fa);

            // update the resource
            smart_table::upsert(
                &mut collector_data.fungible_assets,
                asset_metadata,
                collector_fungible_store
            );
        } else {
            let collector_fungible_store =
                smart_table::borrow(&collector_data.fungible_assets, asset_metadata);
            fungible_asset::deposit(*collector_fungible_store, fa);
        }
    }

    public fun withdraw(
        sender: &signer,
        asset_metadata: Object<Metadata>,
        receiver: address,
        amount: u64
    ) acquires CollectorData {
        // check sender is the fund admin
        is_funds_admin(signer::address_of(sender));

        // borrow the global collector data
        let collector_data = borrow_global_mut<CollectorData>(collector_address());

        // check if we have a secondary fungible store for the asset, if now, throw an error
        if (smart_table::contains(&collector_data.fungible_assets, asset_metadata)) {
            let collector_fungible_store =
                smart_table::borrow(&collector_data.fungible_assets, asset_metadata);
            let collector_fungible_store_signer =
                object::generate_signer_for_extending(&collector_data.extend_ref);
            let receiver_fungible_store =
                primary_fungible_store::ensure_primary_store_exists(
                    receiver, asset_metadata
                );

            // transfer the amount from the collector's sec store to the receiver's store using the collectors signer which is also the owner of the sec.store
            fungible_asset::transfer(
                &collector_fungible_store_signer,
                *collector_fungible_store,
                receiver_fungible_store,
                amount
            );
        }
    }

    #[view]
    public fun get_collected_fees(asset_metadata: Object<Metadata>): u64 acquires CollectorData {
        // get mutably the resource CollectorData stored inside the named object
        let collector_data = borrow_global<CollectorData>(collector_address());
        if (smart_table::contains(&collector_data.fungible_assets, asset_metadata)) {
            let collector_fungible_store =
                smart_table::borrow(&collector_data.fungible_assets, asset_metadata);
            fungible_asset::balance<FungibleStore>(*collector_fungible_store)
        } else { 0 }
    }

    #[test_only]
    public fun get_collector_name(): vector<u8> {
        COLLECTOR_NAME
    }
}
