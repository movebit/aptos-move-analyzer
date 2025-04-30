#[test_only]
module aave_pool::standard_token_tests {
    use std::signer::Self;
    use std::string::utf8;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;

    use aave_pool::standard_token::{
        burn_from_primary_stores,
        deposit_to_primary_stores,
        initialize,
        mint_to_primary_stores,
        set_primary_stores_frozen_status,
        transfer_between_primary_stores,
        withdraw_from_primary_stores
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    fun create_test_mfa(creator: &signer): Object<Metadata> {
        let test_symbol = b"TEST";
        initialize(
            creator,
            0,
            utf8(b"Test Token"), /* name */
            utf8(test_symbol), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com"), /* project */
            vector[true, true, true],
            @0x123,
            false
        );
        let metadata_address =
            object::create_object_address(&signer::address_of(creator), test_symbol);
        object::address_to_object<Metadata>(metadata_address)
    }

    #[test(creator = @aave_pool)]
    fun test_basic_flow(creator: &signer) {
        let metadata = create_test_mfa(creator);
        let creator_address = signer::address_of(creator);
        let aaron_address = @0x111;

        mint_to_primary_stores(
            creator,
            metadata,
            vector[creator_address, aaron_address],
            vector[100, 50]
        );
        assert!(
            primary_fungible_store::balance(creator_address, metadata) == 100,
            TEST_SUCCESS
        );
        assert!(
            primary_fungible_store::balance(aaron_address, metadata) == 50, TEST_SUCCESS
        );

        set_primary_stores_frozen_status(
            creator,
            metadata,
            vector[creator_address, aaron_address],
            true
        );
        assert!(
            primary_fungible_store::is_frozen(creator_address, metadata), TEST_SUCCESS
        );
        assert!(
            primary_fungible_store::is_frozen(aaron_address, metadata), TEST_SUCCESS
        );

        transfer_between_primary_stores(
            creator,
            metadata,
            vector[creator_address, aaron_address],
            vector[aaron_address, creator_address],
            vector[10, 5]
        );
        assert!(
            primary_fungible_store::balance(creator_address, metadata) == 95,
            TEST_SUCCESS
        );
        assert!(
            primary_fungible_store::balance(aaron_address, metadata) == 55, TEST_SUCCESS
        );

        set_primary_stores_frozen_status(
            creator,
            metadata,
            vector[creator_address, aaron_address],
            false
        );
        assert!(
            !primary_fungible_store::is_frozen(creator_address, metadata),
            TEST_SUCCESS
        );
        assert!(
            !primary_fungible_store::is_frozen(aaron_address, metadata), TEST_SUCCESS
        );

        let fa =
            withdraw_from_primary_stores(
                creator,
                metadata,
                vector[creator_address, aaron_address],
                vector[25, 15]
            );
        assert!(fungible_asset::amount(&fa) == 40, TEST_SUCCESS);
        deposit_to_primary_stores(
            creator,
            &mut fa,
            vector[creator_address, aaron_address],
            vector[30, 10]
        );
        fungible_asset::destroy_zero(fa);

        burn_from_primary_stores(
            creator,
            metadata,
            vector[creator_address, aaron_address],
            vector[100, 50]
        );
        assert!(
            primary_fungible_store::balance(creator_address, metadata) == 0,
            TEST_SUCCESS
        );
        assert!(
            primary_fungible_store::balance(aaron_address, metadata) == 0, TEST_SUCCESS
        );
    }

    #[test(creator = @aave_pool, aaron = @0x111)]
    #[expected_failure(abort_code = 0x50001, location = aave_pool::standard_token)]
    fun test_permission_denied(creator: &signer, aaron: &signer) {
        let metadata = create_test_mfa(creator);
        let creator_address = signer::address_of(creator);
        mint_to_primary_stores(
            aaron,
            metadata,
            vector[creator_address],
            vector[100]
        );
    }
}
