// #[test_only]
// module aave_pool::coin_wrapper_tests {
//     use std::signer;
//     use aptos_framework::account::{Self};
//     use aptos_framework::aptos_account;
//     use aptos_framework::coin::{Self};
//     use aptos_framework::fungible_asset::{Self};
//     use aptos_framework::aggregator_factory::initialize_aggregator_factory_for_test;
//     use std::string::{Self, String};
//     use aave_pool::package_manager::Self;
//     use std::option;
//     use aave_pool::coin_wrapper::{
//         initialize,
//         test_unwrap,
//         test_wrap,
//         wrapper_address,
//         test_get_original,
//     };
//
//     const TEST_SUCCESS: u64 = 1;
//     const TEST_FAILED: u64 = 2;
//
//     struct GenericAptosCoin {}
//
//     struct GenericAptosCoinRefs has key {
//         burn_ref: coin::BurnCapability<GenericAptosCoin>,
//         freeze_ref: coin::FreezeCapability<GenericAptosCoin>,
//         mint_ref: coin::MintCapability<GenericAptosCoin>,
//     }
//
//     public fun initialize_aptos_coin(
//         framework: &signer,
//         coin_creator: &signer,
//         decimals: u8,
//         monitor_supply: bool,
//         _coin_name: String,
//         _coin_symbol: String,
//     ) {
//         initialize_aggregator_factory_for_test(framework);
//
//         let (burn_ref, freeze_ref, mint_ref) =
//             coin::initialize<GenericAptosCoin>(
//                 coin_creator,
//                 string::utf8(b"Generic Coin"),
//                 string::utf8(b"GCC"),
//                 decimals,
//                 monitor_supply,
//             );
//         move_to(
//             coin_creator,
//             GenericAptosCoinRefs { burn_ref, freeze_ref, mint_ref, },
//         );
//     }
//
//     inline fun get_coin_refs(account: &signer,): &GenericAptosCoinRefs {
//         borrow_global<GenericAptosCoinRefs>(signer::address_of(account))
//     }
//
//     #[test(deployer = @resource_pm)]
//     fun test_can_get_signer_package_manager(deployer: &signer) {
//         package_manager::initialize_for_test(deployer);
//         let package_deployer_address =
//             signer::address_of(&package_manager::get_signer_test());
//         assert!(package_deployer_address == signer::address_of(deployer), TEST_SUCCESS);
//     }
//
//     #[test(deployer = @resource_pm)]
//     public fun test_can_set_get_signer_package_manager(deployer: &signer) {
//         package_manager::initialize_for_test(deployer);
//         package_manager::add_address_test(string::utf8(b"test"), @0xdeadbeef);
//         assert!(
//             package_manager::get_address_test(string::utf8(b"test")) == @0xdeadbeef,
//             TEST_SUCCESS,
//         );
//     }
//
//     #[test(framework = @aptos_framework, aave_periphery = @aave_pool, deployer = @resource_pm, _aave_pool = @aave_pool, coin_holder = @0x123, _receiver = @0x234)]
//     fun test_coin_wrapper(
//         framework: &signer,
//         aave_periphery: &signer,
//         deployer: &signer,
//         _aave_pool: &signer,
//         coin_holder: &signer,
//         _receiver: &signer
//     ) acquires GenericAptosCoinRefs {
//         // init the package manager
//         package_manager::initialize_for_test(deployer);
//
//         // init the coin wrapper package
//         initialize();
//
//         // initialize old-style aptos coin
//         let coinholder_addr = signer::address_of(coin_holder);
//         account::create_account_for_test(coinholder_addr);
//         let coin_name = string::utf8(b"Generic Coin");
//         let coin_symbol = string::utf8(b"GCC");
//         let coin_decimals = 2;
//
//         initialize_aptos_coin(
//             framework,
//             aave_periphery,
//             coin_decimals,
//             true,
//             coin_name,
//             coin_symbol,
//         );
//
//         // register the holder
//         coin::register<GenericAptosCoin>(coin_holder);
//
//         // mint some coins
//         let token_holder_initial_balance = 100;
//         let coins_minted =
//             coin::mint<GenericAptosCoin>(
//                 token_holder_initial_balance, &get_coin_refs(aave_periphery).mint_ref
//             );
//
//         // deposit to holder
//         coin::deposit(coinholder_addr, coins_minted);
//
//         // withdraw some of the generic coin
//         let coin_withdraw_amount = 20;
//         let withdrawn_coins =
//             coin::withdraw<GenericAptosCoin>(coin_holder, coin_withdraw_amount);
//         // check the coin balance
//         assert!(coin::value(&withdrawn_coins) == coin_withdraw_amount, TEST_SUCCESS);
//         assert!(
//             coin::balance<GenericAptosCoin>(signer::address_of(coin_holder))
//                 == token_holder_initial_balance - coin_withdraw_amount,
//             TEST_SUCCESS,
//         );
//
//         // coin holder now warps the coin using the wrapper and gets an equivalent fa
//         let wrapped_fa = test_wrap<GenericAptosCoin>(withdrawn_coins);
//         // check the wrapper address balance
//         assert!(
//             coin::balance<GenericAptosCoin>(wrapper_address()) == coin_withdraw_amount,
//             TEST_SUCCESS,
//         );
//
//         // run assertions on the generated equivalent fa
//         assert!(fungible_asset::amount(&wrapped_fa) == coin_withdraw_amount, TEST_SUCCESS);
//         let fa_metadata = fungible_asset::metadata_from_asset(&wrapped_fa);
//         let fa_supply = fungible_asset::supply(fa_metadata);
//         let fa_decimals = fungible_asset::decimals(fa_metadata);
//         let fa_symbol = fungible_asset::symbol(fa_metadata);
//         assert!(fa_supply == option::some((coin_withdraw_amount as u128)), TEST_SUCCESS);
//         assert!(fa_decimals == coin_decimals, TEST_SUCCESS);
//         assert!(fa_symbol == coin_symbol, TEST_SUCCESS);
//
//         // now unwrap the fa and get back the coin
//         let unwrapped_coins = test_unwrap<GenericAptosCoin>(wrapped_fa);
//
//         // check the wrapper address balance
//         assert!(coin::balance<GenericAptosCoin>(wrapper_address()) == 0, TEST_SUCCESS);
//
//         // run assertions on the coin
//         assert!(coin::value(&unwrapped_coins) == coin_withdraw_amount, TEST_SUCCESS);
//         assert!(coin::decimals<GenericAptosCoin>() == coin_decimals, TEST_SUCCESS);
//         assert!(coin::symbol<GenericAptosCoin>() == coin_symbol, TEST_SUCCESS);
//         assert!(
//             coin::supply<GenericAptosCoin>()
//                 == option::some((token_holder_initial_balance as u128)),
//             TEST_SUCCESS,
//         );
//
//         // send the coins back to the original coin holder
//         aptos_account::deposit_coins(signer::address_of(coin_holder), unwrapped_coins);
//         // check the original coin holder balance
//         assert!(
//             coin::balance<GenericAptosCoin>(signer::address_of(coin_holder))
//                 == token_holder_initial_balance,
//             TEST_SUCCESS,
//         );
//     }
//
//     #[test(framework = @aptos_framework, aave_periphery = @aave_pool, deployer = @resource_pm, _aave_pool = @aave_pool, coin_holder = @0x123, _receiver = @0x234)]
//     fun test_get_orig(
//         framework: &signer,
//         aave_periphery: &signer,
//         deployer: &signer,
//         _aave_pool: &signer,
//         coin_holder: &signer,
//         _receiver: &signer
//     ) acquires GenericAptosCoinRefs {
//         // init the package manager
//         package_manager::initialize_for_test(deployer);
//
//         // init the coin wrapper package
//         initialize();
//
//         // initialize old-style aptos coin
//         let coinholder_addr = signer::address_of(coin_holder);
//         account::create_account_for_test(coinholder_addr);
//         let coin_name = string::utf8(b"Generic Coin");
//         let coin_symbol = string::utf8(b"GCC");
//         let coin_decimals = 2;
//
//         initialize_aptos_coin(
//             framework,
//             aave_periphery,
//             coin_decimals,
//             true,
//             coin_name,
//             coin_symbol,
//         );
//
//         // register the holder
//         coin::register<GenericAptosCoin>(coin_holder);
//
//         // mint some coins
//         let token_holder_initial_balance = 100;
//         let coins_minted =
//             coin::mint<GenericAptosCoin>(
//                 token_holder_initial_balance,
//                 &get_coin_refs(aave_periphery).mint_ref,
//             );
//
//         // deposit to holder
//         coin::deposit(coinholder_addr, coins_minted);
//
//         // withdraw some of the generic coin
//         let coin_withdraw_amount = 20;
//         let withdrawn_coins =
//             coin::withdraw<GenericAptosCoin>(coin_holder, coin_withdraw_amount);
//         // check the coin balance
//         assert!(coin::value(&withdrawn_coins) == coin_withdraw_amount, TEST_SUCCESS);
//         assert!(
//             coin::balance<GenericAptosCoin>(signer::address_of(coin_holder))
//                 == token_holder_initial_balance - coin_withdraw_amount,
//             TEST_SUCCESS,
//         );
//
//         // coin holder now warps the coin using the wrapper and gets an equivalent fa
//         let wrapped_fa = test_wrap<GenericAptosCoin>(withdrawn_coins);
//         let fa_metadata = fungible_asset::metadata_from_asset(&wrapped_fa);
//
//         test_get_original(fa_metadata);
//         let unwrapped_coins = test_unwrap<GenericAptosCoin>(wrapped_fa);
//         aptos_account::deposit_coins(signer::address_of(coin_holder), unwrapped_coins);
//     }
// }
