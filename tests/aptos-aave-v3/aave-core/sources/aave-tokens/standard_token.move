module aave_pool::standard_token {
    use aptos_framework::fungible_asset::{
        Self,
        MintRef,
        TransferRef,
        BurnRef,
        Metadata,
        FungibleStore,
        FungibleAsset
    };
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::event::{Self};
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::option;
    use std::vector;
    use std::option::Option;

    /// Only fungible asset metadata owner can make changes.
    const ERR_NOT_OWNER: u64 = 1;
    /// The length of ref_flags is not 3.
    const ERR_INVALID_REF_FLAGS_LENGTH: u64 = 2;
    /// The lengths of two vector do not equal.
    const ERR_VECTORS_LENGTH_MISMATCH: u64 = 3;
    /// MintRef error.
    const ERR_MINT_REF: u64 = 4;
    /// TransferRef error.
    const ERR_TRANSFER_REF: u64 = 5;
    /// BurnRef error.
    const ERR_BURN_REF: u64 = 6;
    // error config
    const E_NOT_A_TOKEN_ADMIN: u64 = 1;

    const REVISION: u64 = 1;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagingRefs has key {
        mint_ref: Option<MintRef>,
        transfer_ref: Option<TransferRef>,
        burn_ref: Option<BurnRef>
    }

    #[event]
    struct AaveTokenInitialized has store, drop {
        supply: Option<u128>,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        underlying_asset_address: address,
        is_coin_underlying: bool
    }

    /// Initialize metadata object and store the refs specified by `ref_flags`.
    public fun initialize(
        creator: &signer,
        maximum_supply: u128,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        ref_flags: vector<bool>,
        underlying_asset_address: address,
        is_coin_underlying: bool
    ) {
        only_token_admin(creator);
        assert!(
            vector::length(&ref_flags) == 3,
            error::invalid_argument(ERR_INVALID_REF_FLAGS_LENGTH)
        );
        let supply =
            if (maximum_supply != 0) {
                option::some(maximum_supply)
            } else {
                option::none()
            };

        let constructor_ref =
            &object::create_named_object(creator, *string::bytes(&symbol));
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );

        // Optionally create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref =
            if (*vector::borrow(&ref_flags, 0)) {
                option::some(fungible_asset::generate_mint_ref(constructor_ref))
            } else {
                option::none()
            };
        let transfer_ref =
            if (*vector::borrow(&ref_flags, 1)) {
                option::some(fungible_asset::generate_transfer_ref(constructor_ref))
            } else {
                option::none()
            };
        let burn_ref =
            if (*vector::borrow(&ref_flags, 2)) {
                option::some(fungible_asset::generate_burn_ref(constructor_ref))
            } else {
                option::none()
            };
        let metadata_object_signer = object::generate_signer(constructor_ref);

        // save the managing refs
        move_to(
            &metadata_object_signer,
            ManagingRefs { mint_ref, transfer_ref, burn_ref }
        );

        event::emit(
            AaveTokenInitialized {
                supply,
                name,
                symbol,
                decimals,
                icon_uri,
                project_uri,
                underlying_asset_address,
                is_coin_underlying
            }
        )
    }

    #[view]
    /// Return the revision of the aave token implementation
    public fun get_revision(): u64 {
        REVISION
    }

    /// Mint as the owner of metadata object to the primary fungible stores of the accounts with amounts of FAs.
    public entry fun mint_to_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        to: vector<address>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let receiver_primary_stores = vector::map(
            to, |addr| primary_fungible_store::ensure_primary_store_exists(addr, asset)
        );
        mint(admin, asset, receiver_primary_stores, amounts);
    }

    /// Mint as the owner of metadata object to multiple fungible stores with amounts of FAs.
    public entry fun mint(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(
            length == vector::length(&amounts),
            error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH)
        );
        let mint_ref = authorized_borrow_mint_ref(admin, asset);
        for (i in 0..length) {
            fungible_asset::mint_to(
                mint_ref,
                *vector::borrow(&stores, i),
                *vector::borrow(&amounts, i)
            );
        }
    }

    /// Transfer as the owner of metadata object ignoring `frozen` field from primary stores to primary stores of
    /// accounts.
    public entry fun transfer_between_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        from: vector<address>,
        to: vector<address>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let sender_primary_stores = vector::map(
            from, |addr| primary_fungible_store::primary_store(addr, asset)
        );
        let receiver_primary_stores = vector::map(
            to, |addr| primary_fungible_store::ensure_primary_store_exists(addr, asset)
        );
        transfer(
            admin,
            asset,
            sender_primary_stores,
            receiver_primary_stores,
            amounts
        );
    }

    /// Transfer as the owner of metadata object ignoring `frozen` field between fungible stores.
    public entry fun transfer(
        admin: &signer,
        asset: Object<Metadata>,
        sender_stores: vector<Object<FungibleStore>>,
        receiver_stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let length = vector::length(&sender_stores);
        assert!(
            length == vector::length(&receiver_stores),
            error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH)
        );
        assert!(
            length == vector::length(&amounts),
            error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH)
        );
        let transfer_ref = authorized_borrow_transfer_ref(admin, asset);
        for (i in 0..length) {
            fungible_asset::transfer_with_ref(
                transfer_ref,
                *vector::borrow(&sender_stores, i),
                *vector::borrow(&receiver_stores, i),
                *vector::borrow(&amounts, i)
            );
        }
    }

    /// Burn fungible assets as the owner of metadata object from the primary stores of accounts.
    public entry fun burn_from_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        from: vector<address>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let primary_stores = vector::map(
            from, |addr| primary_fungible_store::primary_store(addr, asset)
        );
        burn(admin, asset, primary_stores, amounts);
    }

    /// Burn fungible assets as the owner of metadata object from fungible stores.
    public entry fun burn(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(
            length == vector::length(&amounts),
            error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH)
        );
        let burn_ref = authorized_borrow_burn_ref(admin, asset);
        for (i in 0..length) {
            fungible_asset::burn_from(
                burn_ref,
                *vector::borrow(&stores, i),
                *vector::borrow(&amounts, i)
            );
        };
    }

    /// Freeze/unfreeze the primary stores of accounts so they cannot transfer or receive fungible assets.
    public entry fun set_primary_stores_frozen_status(
        admin: &signer,
        asset: Object<Metadata>,
        accounts: vector<address>,
        frozen: bool
    ) acquires ManagingRefs {
        let primary_stores = vector::map(
            accounts,
            |acct| { primary_fungible_store::ensure_primary_store_exists(acct, asset) }
        );
        set_frozen_status(admin, asset, primary_stores, frozen);
    }

    /// Freeze/unfreeze the fungible stores so they cannot transfer or receive fungible assets.
    public entry fun set_frozen_status(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        frozen: bool
    ) acquires ManagingRefs {
        let transfer_ref = authorized_borrow_transfer_ref(admin, asset);
        vector::for_each(
            stores,
            |store| {
                fungible_asset::set_frozen_flag(transfer_ref, store, frozen);
            }
        );
    }

    /// Withdraw as the owner of metadata object ignoring `frozen` field from primary fungible stores of accounts.
    public fun withdraw_from_primary_stores(
        admin: &signer,
        asset: Object<Metadata>,
        from: vector<address>,
        amounts: vector<u64>
    ): FungibleAsset acquires ManagingRefs {
        let primary_stores = vector::map(
            from, |addr| primary_fungible_store::primary_store(addr, asset)
        );
        withdraw(admin, asset, primary_stores, amounts)
    }

    /// Withdraw as the owner of metadata object ignoring `frozen` field from fungible stores.
    /// return a fungible asset `fa` where `fa.amount = sum(amounts)`.
    public fun withdraw(
        admin: &signer,
        asset: Object<Metadata>,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ): FungibleAsset acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(
            length == vector::length(&amounts),
            error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH)
        );
        let transfer_ref = authorized_borrow_transfer_ref(admin, asset);
        let sum = fungible_asset::zero(asset);
        for (i in 0..length) {
            let fa =
                fungible_asset::withdraw_with_ref(
                    transfer_ref,
                    *vector::borrow(&stores, i),
                    *vector::borrow(&amounts, i)
                );
            fungible_asset::merge(&mut sum, fa);
        };
        sum
    }

    /// Deposit as the owner of metadata object ignoring `frozen` field to primary fungible stores of accounts from a
    /// single source of fungible asset.
    public fun deposit_to_primary_stores(
        admin: &signer,
        fa: &mut FungibleAsset,
        from: vector<address>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let primary_stores = vector::map(
            from,
            |addr| primary_fungible_store::ensure_primary_store_exists(
                addr, fungible_asset::asset_metadata(fa)
            )
        );
        deposit(admin, fa, primary_stores, amounts);
    }

    /// Deposit as the owner of metadata object ignoring `frozen` field from fungible stores. The amount left in `fa`
    /// is `fa.amount - sum(amounts)`.
    public fun deposit(
        admin: &signer,
        fa: &mut FungibleAsset,
        stores: vector<Object<FungibleStore>>,
        amounts: vector<u64>
    ) acquires ManagingRefs {
        let length = vector::length(&stores);
        assert!(
            length == vector::length(&amounts),
            error::invalid_argument(ERR_VECTORS_LENGTH_MISMATCH)
        );
        let transfer_ref =
            authorized_borrow_transfer_ref(admin, fungible_asset::asset_metadata(fa));
        for (i in 0..length) {
            let split_fa = fungible_asset::extract(fa, *vector::borrow(&amounts, i));
            fungible_asset::deposit_with_ref(
                transfer_ref,
                *vector::borrow(&stores, i),
                split_fa
            );
        };
    }

    /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_refs(
        owner: &signer, asset: Object<Metadata>
    ): &ManagingRefs acquires ManagingRefs {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ERR_NOT_OWNER)
        );
        borrow_global<ManagingRefs>(object::object_address(&asset))
    }

    /// Check the existence and borrow `MintRef`.
    inline fun authorized_borrow_mint_ref(
        owner: &signer, asset: Object<Metadata>
    ): &MintRef acquires ManagingRefs {
        let refs = authorized_borrow_refs(owner, asset);
        assert!(option::is_some(&refs.mint_ref), error::not_found(ERR_MINT_REF));
        option::borrow(&refs.mint_ref)
    }

    /// Check the existence and borrow `TransferRef`.
    inline fun authorized_borrow_transfer_ref(
        owner: &signer, asset: Object<Metadata>
    ): &TransferRef acquires ManagingRefs {
        let refs = authorized_borrow_refs(owner, asset);
        assert!(
            option::is_some(&refs.transfer_ref), error::not_found(ERR_TRANSFER_REF)
        );
        option::borrow(&refs.transfer_ref)
    }

    /// Check the existence and borrow `BurnRef`.
    inline fun authorized_borrow_burn_ref(
        owner: &signer, asset: Object<Metadata>
    ): &BurnRef acquires ManagingRefs {
        let refs = authorized_borrow_refs(owner, asset);
        assert!(option::is_some(&refs.mint_ref), error::not_found(ERR_BURN_REF));
        option::borrow(&refs.burn_ref)
    }

    fun only_token_admin(account: &signer) {
        assert!(signer::address_of(account) == @aave_pool, E_NOT_A_TOKEN_ADMIN)
    }
}
