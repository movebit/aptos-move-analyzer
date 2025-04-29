// #[test_only]
// module aave_pool::collector_tests {
//     use aptos_framework::fungible_asset::{Self, Metadata};
//     use aptos_framework::object::{Self, Object};
//     use aptos_framework::primary_fungible_store;
//     use aave_acl::acl_manage::{Self};
//     use std::string::utf8;
//     use aave_pool::standard_token::{Self};
//     use std::signer;
//     use aave_pool::collector::{
//         Self,
//         withdraw,
//         init_module_test,
//         deposit,
//         get_collected_fees,
//     };
//
//     const TEST_SUCCESS: u64 = 1;
//     const TEST_FAILED: u64 = 2;
//
//     fun create_test_fa(creator: &signer): Object<Metadata> {
//         let test_symbol = b"TEST";
//         standard_token::initialize(
//             creator,
//             0,
//             utf8(b"Test Token"),
//             utf8(test_symbol),
//             8,
//             utf8(b"http://example.com/favicon.ico"),
//             utf8(b"http://example.com"),
//             vector[true, true, true],
//             @0x1,
//             false,
//         );
//         let metadata_address =
//             object::create_object_address(&signer::address_of(creator), test_symbol);
//         object::address_to_object<Metadata>(metadata_address)
//     }
//
//     #[test(fa_creator = @aave_pool, aave_role_super_admin = @aave_acl, collector_account = @aave_pool, acl_fund_admin = @0x111, user_account = @0x222)]
//     fun test_basic_flow(
//         fa_creator: &signer,
//         aave_role_super_admin: &signer,
//         collector_account: &signer,
//         acl_fund_admin: &signer,
//         user_account: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         // set fund admin
//         acl_manage::add_funds_admin(
//             aave_role_super_admin, signer::address_of(acl_fund_admin)
//         );
//         // assert role is granted
//         assert!(
//             acl_manage::is_funds_admin(signer::address_of(acl_fund_admin)), TEST_SUCCESS
//         );
//
//         // create test token
//         let metadata = create_test_fa(fa_creator);
//
//         // mint coins to user
//         let _creator_address = signer::address_of(fa_creator);
//         let user_address = signer::address_of(user_account);
//         standard_token::mint_to_primary_stores(
//             fa_creator, metadata, vector[user_address], vector[100]
//         );
//         assert!(
//             primary_fungible_store::balance(user_address, metadata) == 100, TEST_SUCCESS
//         );
//
//         // user withdraws all fees he has
//         let fa =
//             standard_token::withdraw_from_primary_stores(
//                 fa_creator,
//                 metadata,
//                 vector[user_address],
//                 vector[100],
//             );
//         assert!(fungible_asset::amount(&fa) == 100, TEST_SUCCESS);
//
//         // initialize the collector
//         init_module_test(collector_account);
//
//         // deposit the fee
//         deposit(acl_fund_admin, fa);
//
//         // assert the fees are in the secondary store
//         assert!(get_collected_fees(metadata) == 100, TEST_SUCCESS);
//
//         // transfer back half of the fees to the user
//         withdraw(acl_fund_admin, metadata, user_address, 50);
//
//         // check user and collectpr's store balances
//         assert!(get_collected_fees(metadata) == 50, 5);
//         assert!(
//             primary_fungible_store::balance(user_address, metadata) == 50, TEST_SUCCESS
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, collector_account = @aave_pool, acl_fund_admin = @0x111)]
//     fun test_is_funds_admin_pass(
//         aave_role_super_admin: &signer,
//         collector_account: &signer,
//         acl_fund_admin: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         // set fund admin
//         acl_manage::add_funds_admin(
//             aave_role_super_admin, signer::address_of(acl_fund_admin)
//         );
//         // assert role is granted
//         assert!(
//             acl_manage::is_funds_admin(signer::address_of(acl_fund_admin)), TEST_SUCCESS
//         );
//
//         // initialize the collector
//         init_module_test(collector_account);
//
//         // assert funds admin role is granted
//         assert!(
//             collector::check_is_funds_admin(signer::address_of(acl_fund_admin)),
//             TEST_SUCCESS,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, collector_account = @aave_pool, acl_fund_admin = @0x111)]
//     fun test_is_funds_admin_fail(
//         aave_role_super_admin: &signer,
//         collector_account: &signer,
//         acl_fund_admin: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         // set fund admin
//         let some_acl_funds_admin = @0x222;
//         acl_manage::add_funds_admin(aave_role_super_admin, some_acl_funds_admin);
//         // assert role is granted
//         assert!(acl_manage::is_funds_admin(some_acl_funds_admin), TEST_SUCCESS);
//
//         // initialize the collector
//         init_module_test(collector_account);
//
//         // assert funds admin role is granted
//         assert!(
//             !collector::check_is_funds_admin(signer::address_of(acl_fund_admin)),
//             TEST_SUCCESS,
//         );
//     }
// }
