// #[test_only]
// module aave_pool::rewards_controller_tests {
//     use aave_acl::acl_manage::{Self};
//     use std::signer;
//     use std::vector;
//     use std::option::{Self, Option};
//     use std::string::utf8;
//     use aptos_std::string_utils::{Self};
//     use aptos_std::simple_map;
//     use aptos_framework::object::{Self, Object};
//     use aave_oracle::reward_oracle::{create_reward_oracle};
//     use aptos_framework::timestamp::set_time_has_started_for_testing;
//     use aave_pool::transfer_strategy::{
//         RewardsConfigInput,
//         create_staked_token_transfer_strategy,
//         create_pull_rewards_transfer_strategy,
//         create_rewards_config_input
//     };
//     use aave_pool::rewards_controller::{
//         initialize,
//         set_pull_rewards_transfer_strategy,
//         set_staked_token_transfer_strategy,
//         get_emission_manager,
//         get_rewards_list,
//         set_reward_oracle_internal,
//         get_asset_decimals,
//         add_asset,
//         create_asset_data,
//         configure_assets,
//         claim_rewards,
//         get_all_user_rewards,
//         claim_all_rewards,
//         rewards_controller_object,
//         rewards_controller_address,
//         RewardsControllerData,
//         get_revision,
//         get_reward_oracle,
//         get_pull_rewards_transfer_strategy,
//         get_staked_token_transfer_strategy,
//         set_reward_oracle,
//         set_emission_per_second,
//         get_asset_index,
//         set_claimer,
//         get_claimer,
//         test_claim_rewards_on_behalf,
//         test_claim_rewards_to_self,
//         get_user_rewards,
//         set_distribution_end,
//         get_distribution_end,
//         test_claim_all_rewards_on_behalf,
//         test_claim_all_rewards_to_self,
//         add_to_rewards_list,
//         test_handle_action
//     };
//
//     #[test(aave_role_super_admin = @aave_acl, _periphery_account = @aave_pool, _acl_fund_admin = @0x111, _user_account = @0x222, _creator = @0x1,)]
//     fun test_initialize(
//         aave_role_super_admin: &signer,
//         _periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         _user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         let rewards_addr = signer::address_of(aave_role_super_admin);
//
//         initialize(aave_role_super_admin, rewards_addr);
//
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_distribution_end(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//         aave_pool::token_base::test_init_module(periphery_account);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let new_distribution_end = 10;
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             asset_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         let rewards = simple_map::create();
//
//         let index = 0;
//         let last_update_timestamp = 1;
//         let emission_per_second = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         set_distribution_end(
//             periphery_account,
//             a_token_address,
//             a_token_address,
//             new_distribution_end,
//             rewards_addr,
//         );
//
//         assert!(
//             get_distribution_end(
//                 a_token_address,
//                 a_token_address,
//                 rewards_addr,
//             ) == 10,
//             1,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_set_pull_rewards_transfer_strategy(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let pull_rewards_transfer_strategy =
//             aave_pool::transfer_strategy::create_pull_rewards_transfer_strategy(
//                 user_account_addr, user_account_addr, user_account_addr
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         set_pull_rewards_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             pull_rewards_transfer_strategy,
//             rewards_addr,
//         );
//
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_pull_rewards_transfer_strategy(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let pull_rewards_transfer_strategy =
//             aave_pool::transfer_strategy::create_pull_rewards_transfer_strategy(
//                 user_account_addr, user_account_addr, user_account_addr
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         set_pull_rewards_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             pull_rewards_transfer_strategy,
//             rewards_addr,
//         );
//
//         assert!(
//             get_pull_rewards_transfer_strategy(
//                 signer::address_of(periphery_account), rewards_addr
//             ) == pull_rewards_transfer_strategy,
//             1,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_set_staked_token_transfer_strategy(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         set_staked_token_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             staked_token_transfer_strategy,
//             rewards_addr,
//         );
//
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_staked_token_transfer_strategy(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         set_staked_token_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             staked_token_transfer_strategy,
//             rewards_addr,
//         );
//
//         assert!(
//             get_staked_token_transfer_strategy(
//                 signer::address_of(periphery_account), rewards_addr
//             ) == staked_token_transfer_strategy,
//             1,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_emission_manager(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let emission_manager = get_emission_manager(rewards_addr);
//
//         assert!(emission_manager == signer::address_of(periphery_account), 1);
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_rewards_list(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let rewards_list = get_rewards_list(rewards_addr);
//
//         assert!(rewards_list == vector[], 1);
//
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_set_reward_oracle_internal(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//     }
//
//     #[test(aptos_framework = @0x1, aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_set_emission_per_second(
//         aptos_framework: &signer,
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//         aave_pool::token_base::test_init_module(periphery_account);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let rewards = simple_map::create();
//
//         let index = 0;
//         let last_update_timestamp = 1;
//         let emission_per_second = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             asset_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         set_emission_per_second(
//             periphery_account,
//             a_token_address,
//             vector[a_token_address],
//             vector[1],
//             rewards_addr,
//         )
//     }
//
//     #[test(aptos_framework = @0x1, aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_asset_index(
//         aptos_framework: &signer,
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//         aave_pool::token_base::test_init_module(periphery_account);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let rewards = simple_map::create();
//
//         let index = 0;
//         let last_update_timestamp = 1;
//         let emission_per_second = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             asset_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         get_asset_index(a_token_address, a_token_address, rewards_addr);
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_set_reward_oracle(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         aave_acl::acl_manage::add_rewards_controller_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         set_reward_oracle(periphery_account, rewards_addr, reward_oracle, rewards_addr);
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_asset_decimals(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let rewards = simple_map::create();
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, asset_addr, asset);
//
//         let res = get_asset_decimals(asset_addr, rewards_addr);
//
//         assert!(res == decimals, 1);
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_claim_rewards(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let rewards = simple_map::create();
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, asset_addr, asset);
//
//         let res = get_asset_decimals(asset_addr, rewards_addr);
//
//         assert!(res == decimals, 1);
//
//         claim_rewards(
//             periphery_account,
//             vector[asset_addr],
//             0,
//             signer::address_of(periphery_account),
//             signer::address_of(periphery_account),
//             signer::address_of(periphery_account),
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_of_handle_action(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let rewards = simple_map::create();
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, asset_addr, asset);
//
//         let res = get_asset_decimals(asset_addr, rewards_addr);
//
//         assert!(res == decimals, 1);
//
//         test_handle_action(
//             periphery_account,
//             signer::address_of(periphery_account),
//             0,
//             0,
//             rewards_addr,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_user_rewards(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let underlying_asset_address = @0x033;
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             // aave_role_super_admin,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_asset_address,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         let rewards = simple_map::create();
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let users_data = std::simple_map::new();
//
//         let user_data = aave_pool::rewards_controller::create_user_data(0, 0);
//
//         std::simple_map::upsert(
//             &mut users_data, signer::address_of(periphery_account), user_data
//         );
//
//         let index = 0;
//         let last_update_timestamp = 0;
//         let emission_per_second = 0;
//         let distribution_end = 0;
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         get_user_rewards(
//             vector[a_token_address],
//             signer::address_of(periphery_account),
//             a_token_address,
//             rewards_addr,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_all_user_rewards(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let underlying_asset_address = @0x033;
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             // aave_role_super_admin,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_asset_address,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         let rewards = simple_map::create();
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset_addr = signer::address_of(periphery_account);
//
//         let users_data = std::simple_map::new();
//
//         let user_data = aave_pool::rewards_controller::create_user_data(0, 0);
//
//         std::simple_map::upsert(&mut users_data, a_token_address, user_data);
//
//         let index = 0;
//         let last_update_timestamp = 0;
//         let emission_per_second = 0;
//         let distribution_end = 0;
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         add_to_rewards_list(a_token_address, rewards_addr);
//
//         let (addr_vec, amount_vec) =
//             get_all_user_rewards(
//                 vector[a_token_address],
//                 a_token_address,
//                 rewards_addr,
//             );
//
//         assert!(vector::length(&addr_vec) != 0, 1);
//         assert!(vector::length(&amount_vec) != 0, 1);
//     }
//
//     #[test(aptos_framework = @0x1, aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1, underlying_tokens_admin = @underlying_tokens,)]
//     fun test_configure_assets(
//         aptos_framework: &signer,
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//         underlying_tokens_admin: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let underlying_asset_address = @0x033;
//
//         let underlying_token = signer::address_of(underlying_tokens_admin);
//         let rewards_vault = signer::address_of(underlying_tokens_admin);
//         let rewards_admin = signer::address_of(underlying_tokens_admin);
//         let incentives_controller = signer::address_of(underlying_tokens_admin);
//         let treasury_address = @0x034;
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             // aave_role_super_admin,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_asset_address,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         let pull_rewards_transfer_strategy =
//             option::some(
//                 create_pull_rewards_transfer_strategy(
//                     rewards_admin, incentives_controller, rewards_vault
//                 ),
//             );
//
//         let staked_token_transfer_strategy = option::none();
//
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//         // let asset = underlying_token;
//         // let reward = underlying_token;
//         let asset = a_token_address;
//         let reward = a_token_address;
//
//         let id = 1;
//         let reward_oracle = aave_oracle::reward_oracle::create_reward_oracle(id);
//
//         let rewards_config_input =
//             create_rewards_config_input(
//                 emission_per_second,
//                 total_supply,
//                 distribution_end,
//                 asset,
//                 reward,
//                 staked_token_transfer_strategy,
//                 pull_rewards_transfer_strategy,
//                 reward_oracle,
//             );
//
//         let rewards = simple_map::create();
//
//         let users_data = std::simple_map::new();
//
//         let index = 0;
//         let last_update_timestamp = 0;
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset_data =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         // let asset_addr = signer::address_of(periphery_account);
//
//         add_asset(rewards_addr, a_token_address, asset_data);
//
//         aave_acl::acl_manage::add_rewards_controller_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//         aave_pool::rewards_controller::enable_reward(rewards_addr, reward);
//
//         configure_assets(periphery_account, vector[rewards_config_input], rewards_addr);
//     }
//
//     #[test(aptos_framework = @0x1, aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1, underlying_tokens_admin = @underlying_tokens,)]
//     fun test_set_claimer(
//         aptos_framework: &signer,
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//         underlying_tokens_admin: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let underlying_asset_address = @0x033;
//
//         let underlying_token = signer::address_of(underlying_tokens_admin);
//         let rewards_vault = signer::address_of(underlying_tokens_admin);
//         let rewards_admin = signer::address_of(underlying_tokens_admin);
//         let incentives_controller = signer::address_of(underlying_tokens_admin);
//         let treasury_address = @0x034;
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             // aave_role_super_admin,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_asset_address,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         let pull_rewards_transfer_strategy =
//             option::some(
//                 create_pull_rewards_transfer_strategy(
//                     rewards_admin, incentives_controller, rewards_vault
//                 ),
//             );
//
//         let staked_token_transfer_strategy = option::none();
//
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//         // let asset = underlying_token;
//         // let reward = underlying_token;
//         let asset = a_token_address;
//         let reward = a_token_address;
//
//         let id = 1;
//         let reward_oracle = aave_oracle::reward_oracle::create_reward_oracle(id);
//
//         let rewards_config_input =
//             create_rewards_config_input(
//                 emission_per_second,
//                 total_supply,
//                 distribution_end,
//                 asset,
//                 reward,
//                 staked_token_transfer_strategy,
//                 pull_rewards_transfer_strategy,
//                 reward_oracle,
//             );
//
//         let rewards = simple_map::create();
//
//         let users_data = std::simple_map::new();
//
//         let index = 0;
//         let last_update_timestamp = 0;
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset_data =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         // let asset_addr = signer::address_of(periphery_account);
//
//         add_asset(rewards_addr, a_token_address, asset_data);
//
//         aave_acl::acl_manage::add_rewards_controller_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//         aave_pool::rewards_controller::enable_reward(rewards_addr, reward);
//
//         acl_manage::add_emission_admin_role(aave_role_super_admin, a_token_address);
//
//         set_claimer(a_token_address, a_token_address, rewards_addr);
//     }
//
//     #[test(aptos_framework = @0x1, aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1, underlying_tokens_admin = @underlying_tokens,)]
//     fun test_get_claimer(
//         aptos_framework: &signer,
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//         underlying_tokens_admin: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         let underlying_asset_address = @0x033;
//
//         let underlying_token = signer::address_of(underlying_tokens_admin);
//         let rewards_vault = signer::address_of(underlying_tokens_admin);
//         let rewards_admin = signer::address_of(underlying_tokens_admin);
//         let incentives_controller = signer::address_of(underlying_tokens_admin);
//         let treasury_address = @0x034;
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             // aave_role_super_admin,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_asset_address,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol
//             );
//
//         let pull_rewards_transfer_strategy =
//             option::some(
//                 create_pull_rewards_transfer_strategy(
//                     rewards_admin, incentives_controller, rewards_vault
//                 ),
//             );
//
//         let staked_token_transfer_strategy = option::none();
//
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//         // let asset = underlying_token;
//         // let reward = underlying_token;
//         let asset = a_token_address;
//         let reward = a_token_address;
//
//         let id = 1;
//         let reward_oracle = aave_oracle::reward_oracle::create_reward_oracle(id);
//
//         let rewards_config_input =
//             create_rewards_config_input(
//                 emission_per_second,
//                 total_supply,
//                 distribution_end,
//                 asset,
//                 reward,
//                 staked_token_transfer_strategy,
//                 pull_rewards_transfer_strategy,
//                 reward_oracle,
//             );
//
//         let rewards = simple_map::create();
//
//         let users_data = std::simple_map::new();
//
//         let index = 0;
//         let last_update_timestamp = 0;
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset_data =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         // let asset_addr = signer::address_of(periphery_account);
//
//         add_asset(rewards_addr, a_token_address, asset_data);
//
//         aave_acl::acl_manage::add_rewards_controller_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//         aave_pool::rewards_controller::enable_reward(rewards_addr, reward);
//
//         acl_manage::add_emission_admin_role(aave_role_super_admin, a_token_address);
//
//         set_claimer(a_token_address, a_token_address, rewards_addr);
//
//         assert!(
//             get_claimer(a_token_address, rewards_addr) == a_token_address,
//             1,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_claim_all_rewards(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         let i = 0;
//
//         let name_2 = string_utils::format1(&b"APTOS_UNDERLYING_2_{}", i);
//         let symbol_2 = string_utils::format1(&b"U_2_{}", i);
//         let decimals_2 = 2 + i;
//         let max_supply_2 = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name_2,
//             symbol_2,
//             decimals_2,
//             utf8(b"2"),
//             utf8(b"2"),
//             rewards_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol_2
//             );
//
//         let index = 0;
//         let last_update_timestamp = 0;
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//         let rewards = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         claim_all_rewards(
//             periphery_account,
//             vector[a_token_address],
//             rewards_addr,
//             rewards_addr,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_of_claim_all_rewards_on_behalf(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         let i = 0;
//
//         let name_2 = string_utils::format1(&b"APTOS_UNDERLYING_2_{}", i);
//         let symbol_2 = string_utils::format1(&b"U_2_{}", i);
//         let decimals_2 = 2 + i;
//         let max_supply_2 = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name_2,
//             symbol_2,
//             decimals_2,
//             utf8(b"2"),
//             utf8(b"2"),
//             rewards_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol_2
//             );
//
//         let index = 0;
//         let last_update_timestamp = 0;
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//
//         let user_data = aave_pool::rewards_controller::create_user_data(0, 1);
//
//         std::simple_map::upsert(
//             &mut users_data, signer::address_of(periphery_account), user_data
//         );
//
//         let rewards = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         acl_manage::add_emission_admin_role(aave_role_super_admin, rewards_addr);
//
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         set_claimer(
//             signer::address_of(periphery_account),
//             signer::address_of(periphery_account),
//             rewards_addr,
//         );
//
//         add_to_rewards_list(a_token_address, rewards_addr);
//
//         test_claim_all_rewards_on_behalf(
//             periphery_account,
//             vector[a_token_address],
//             signer::address_of(periphery_account),
//             rewards_addr,
//             rewards_addr,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_of_test_claim_all_rewards_to_self(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         let i = 0;
//
//         let name_2 = string_utils::format1(&b"APTOS_UNDERLYING_2_{}", i);
//         let symbol_2 = string_utils::format1(&b"U_2_{}", i);
//         let decimals_2 = 2 + i;
//         let max_supply_2 = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name_2,
//             symbol_2,
//             decimals_2,
//             utf8(b"2"),
//             utf8(b"2"),
//             rewards_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol_2
//             );
//
//         let index = 0;
//         let last_update_timestamp = 0;
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//
//         let user_data = aave_pool::rewards_controller::create_user_data(0, 1);
//
//         std::simple_map::upsert(
//             &mut users_data, signer::address_of(periphery_account), user_data
//         );
//
//         let rewards = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         acl_manage::add_emission_admin_role(aave_role_super_admin, rewards_addr);
//
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         set_claimer(
//             signer::address_of(periphery_account),
//             signer::address_of(periphery_account),
//             rewards_addr,
//         );
//
//         add_to_rewards_list(a_token_address, rewards_addr);
//
//         test_claim_all_rewards_to_self(
//             periphery_account, vector[a_token_address], rewards_addr
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_of_claim_rewards_on_behalf(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         let i = 0;
//
//         let name_2 = string_utils::format1(&b"APTOS_UNDERLYING_2_{}", i);
//         let symbol_2 = string_utils::format1(&b"U_2_{}", i);
//         let decimals_2 = 2 + i;
//         let max_supply_2 = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name_2,
//             symbol_2,
//             decimals_2,
//             utf8(b"2"),
//             utf8(b"2"),
//             rewards_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol_2
//             );
//
//         let index = 0;
//         let last_update_timestamp = 0;
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//         let rewards = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         acl_manage::add_emission_admin_role(aave_role_super_admin, rewards_addr);
//
//         set_claimer(rewards_addr, signer::address_of(periphery_account), rewards_addr);
//
//         test_claim_rewards_on_behalf(
//             periphery_account,
//             vector[a_token_address],
//             0,
//             rewards_addr,
//             rewards_addr,
//             rewards_addr,
//             rewards_addr,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_of_claim_rewards_to_self(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//         aave_pool::token_base::test_init_module(periphery_account);
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(periphery_account)
//         );
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         let i = 0;
//
//         let name_2 = string_utils::format1(&b"APTOS_UNDERLYING_2_{}", i);
//         let symbol_2 = string_utils::format1(&b"U_2_{}", i);
//         let decimals_2 = 2 + i;
//         let max_supply_2 = 10000;
//         let treasury_address = @0x034;
//
//         aave_pool::a_token_factory::create_token(
//             periphery_account,
//             name_2,
//             symbol_2,
//             decimals_2,
//             utf8(b"2"),
//             utf8(b"2"),
//             rewards_addr,
//             treasury_address,
//         );
//
//         let a_token_address =
//             aave_pool::a_token_factory::token_address(
//                 signer::address_of(periphery_account), symbol_2
//             );
//
//         let index = 0;
//         let last_update_timestamp = 0;
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let users_data = std::simple_map::new();
//         let rewards = std::simple_map::new();
//
//         let reward_data =
//             aave_pool::rewards_controller::create_reward_data(
//                 index,
//                 emission_per_second,
//                 last_update_timestamp,
//                 distribution_end,
//                 users_data,
//             );
//
//         std::simple_map::upsert(&mut rewards, a_token_address, reward_data);
//         let available_rewards = simple_map::create();
//         let available_rewards_count = 0;
//         let decimals = 10;
//
//         let asset =
//             create_asset_data(
//                 rewards,
//                 available_rewards,
//                 available_rewards_count,
//                 decimals,
//             );
//
//         add_asset(rewards_addr, a_token_address, asset);
//
//         acl_manage::add_emission_admin_role(aave_role_super_admin, rewards_addr);
//
//         set_claimer(rewards_addr, signer::address_of(periphery_account), rewards_addr);
//
//         test_claim_rewards_to_self(
//             periphery_account,
//             vector[a_token_address],
//             0,
//             rewards_addr,
//             rewards_addr,
//         );
//     }
//
//     #[test(fa_creator = @aave_pool, aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, acl_fund_admin = @0x111, user_account = @0x222)]
//     fun test_rewards_controller_object(
//         fa_creator: &signer,
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         acl_fund_admin: &signer,
//         user_account: &signer,
//     ) {
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         assert!(
//             rewards_controller_object()
//                 == object::address_to_object<RewardsControllerData>(
//                     rewards_controller_address()
//                 ),
//             1,
//         );
//     }
//
//     #[test(fa_creator = @aave_pool, aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, acl_fund_admin = @0x111, user_account = @0x222)]
//     fun test_get_revision(
//         fa_creator: &signer,
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         acl_fund_admin: &signer,
//         user_account: &signer,
//     ) {
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         assert!(get_revision() == 1, 1);
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
//     fun test_get_reward_oracle(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         _acl_fund_admin: &signer,
//         user_account: &signer,
//         _creator: &signer,
//     ) {
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         aave_pool::rewards_controller::initialize(
//             periphery_account, signer::address_of(periphery_account)
//         );
//
//         let user_account_addr = signer::address_of(user_account);
//
//         let mock_staked_token =
//             aave_pool::staked_token::create_mock_staked_token(user_account_addr);
//
//         let _staked_token_transfer_strategy =
//             aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
//                 user_account_addr,
//                 user_account_addr,
//                 mock_staked_token,
//                 user_account_addr,
//             );
//
//         let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();
//
//         let reward_oracle = create_reward_oracle(1);
//
//         set_reward_oracle_internal(rewards_addr, reward_oracle);
//
//         assert!(
//             get_reward_oracle(rewards_addr, rewards_addr) == reward_oracle,
//             1,
//         );
//     }
// }
