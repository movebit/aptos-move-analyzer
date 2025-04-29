// #[test_only]
// module aave_pool::emission_manager_tests {
//     use aave_acl::acl_manage::{Self};
//     use std::signer;
//     use aave_pool::emission_manager::{
//         initialize,
//         set_pull_rewards_transfer_strategy,
//         set_staked_token_transfer_strategy,
//         set_emission_admin,
//         get_emission_admin,
//         set_rewards_controller,
//         get_rewards_controller,
//         configure_assets,
//         set_distribution_end,
//         set_emission_per_second,
//         set_claimer
//     };
//     use std::vector;
//     use std::string;
//     use std::option::{Self, Option};
//     use aave_pool::token_base::Self;
//     use aave_pool::mock_underlying_token_factory::Self;
//     use std::string::utf8;
//     use aptos_std::string_utils::{Self};
//
//     const TEST_SUCCESS: u64 = 1;
//     const TEST_FAILED: u64 = 2;
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         set_pull_rewards_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             pull_rewards_transfer_strategy,
//         );
//
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         set_staked_token_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             staked_token_transfer_strategy,
//         );
//
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111, user_account = @0x222, new_admin = @0x1,)]
//     fun test_set_get_emission_admin(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         reward: &signer,
//         user_account: &signer,
//         new_admin: &signer,
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         set_staked_token_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             staked_token_transfer_strategy,
//         );
//
//         let new_admin = signer::address_of(new_admin);
//
//         set_emission_admin(aave_role_super_admin, rewards_addr, new_admin);
//
//         assert!(
//             get_emission_admin(rewards_addr) == new_admin,
//             TEST_SUCCESS,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111, user_account = @0x222, new_admin = @0x1,)]
//     fun test_set_get_rewards_controller(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         reward: &signer,
//         user_account: &signer,
//         new_admin: &signer,
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         set_staked_token_transfer_strategy(
//             periphery_account,
//             signer::address_of(periphery_account),
//             staked_token_transfer_strategy,
//         );
//
//         let rewards_controller = signer::address_of(reward);
//
//         set_rewards_controller(aave_role_super_admin, rewards_controller);
//
//         assert!(
//             get_rewards_controller() == rewards_controller,
//             TEST_SUCCESS,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111, user_account = @0x222, new_admin = @0x1, underlying_tokens_admin = @aave_acl, underlying_tokens_admin_2 = @underlying_tokens, aptos_framework = @0x1,)]
//     fun test_configure_assets(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         reward: &signer,
//         user_account: &signer,
//         new_admin: &signer,
//         underlying_tokens_admin: &signer,
//         underlying_tokens_admin_2: &signer,
//         aptos_framework: &signer,
//     ) {
//         aptos_framework::timestamp::set_time_has_started_for_testing(aptos_framework);
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         // mock_underlying_token_factory::test_init_module(periphery_account);
//         token_base::test_init_module(periphery_account);
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//
//         // create a tokens admin account
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(underlying_tokens_admin_2)
//         );
//
//         aave_pool::a_token_factory::create_token(
//             underlying_tokens_admin_2,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             signer::address_of(underlying_tokens_admin_2),
//             signer::address_of(underlying_tokens_admin_2),
//         );
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         let new_admin = signer::address_of(periphery_account);
//
//         set_emission_admin(aave_role_super_admin, rewards_addr, new_admin);
//
//         assert!(
//             get_emission_admin(rewards_addr) == new_admin,
//             TEST_SUCCESS,
//         );
//
//         let rewards_admin = signer::address_of(underlying_tokens_admin_2);
//         let incentives_controller = signer::address_of(underlying_tokens_admin_2);
//         let rewards_vault = signer::address_of(underlying_tokens_admin_2);
//
//         let underlying_token = signer::address_of(underlying_tokens_admin_2);
//
//         let stake_contract =
//             aave_pool::staked_token::create_mock_staked_token(underlying_token);
//
//         let pull_rewards_transfer_strategy =
//             option::some(
//                 aave_pool::transfer_strategy::create_pull_rewards_transfer_strategy(
//                     rewards_admin, incentives_controller, rewards_vault
//                 ),
//             );
//         // let staked_token_transfer_strategy = option::some(aave_pool::transfer_strategy::create_staked_token_transfer_strategy(rewards_admin, incentives_controller, stake_contract, underlying_token));
//         let staked_token_transfer_strategy = option::none();
//
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let reward = rewards_addr;
//
//         let rewards_map = std::simple_map::new();
//
//         let available_rewards_count = 0;
//
//         let index = 0;
//         let emission_per_second = 0;
//         let last_update_timestamp = 0;
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
//         std::simple_map::upsert(&mut rewards_map, reward, reward_data);
//
//         let asset_data =
//             aave_pool::rewards_controller::create_asset_data(
//                 rewards_map,
//                 std::simple_map::new(),
//                 available_rewards_count,
//                 decimals,
//             );
//         let asset =
//             aptos_framework::object::create_object_address(
//                 &signer::address_of(underlying_tokens_admin_2), *string::bytes(&symbol)
//             );
//
//         let id = 1;
//         let reward_oracle = aave_oracle::reward_oracle::create_reward_oracle(id);
//
//         let config = vector::empty<aave_pool::transfer_strategy::RewardsConfigInput>();
//         let rewards_config_input =
//             aave_pool::transfer_strategy::create_rewards_config_input(
//                 emission_per_second,
//                 total_supply,
//                 distribution_end,
//                 asset,
//                 reward,
//                 staked_token_transfer_strategy,
//                 pull_rewards_transfer_strategy,
//                 reward_oracle,
//             );
//         vector::push_back(&mut config, rewards_config_input);
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_rewards_controller_admin_role_for_testing(),
//             signer::address_of(periphery_account),
//         );
//
//         aave_pool::rewards_controller::add_asset(rewards_addr, asset, asset_data);
//         aave_pool::rewards_controller::enable_reward(rewards_addr, reward);
//
//         configure_assets(periphery_account, config);
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111, user_account = @0x222, new_admin = @0x1, underlying_tokens_admin = @aave_acl, underlying_tokens_admin_2 = @underlying_tokens, aptos_framework = @0x1,)]
//     fun test_set_distribution_end(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         reward: &signer,
//         user_account: &signer,
//         new_admin: &signer,
//         underlying_tokens_admin: &signer,
//         underlying_tokens_admin_2: &signer,
//         aptos_framework: &signer,
//     ) {
//         aptos_framework::timestamp::set_time_has_started_for_testing(aptos_framework);
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         // mock_underlying_token_factory::test_init_module(periphery_account);
//         token_base::test_init_module(periphery_account);
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//
//         // create a tokens admin account
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(underlying_tokens_admin_2)
//         );
//
//         aave_pool::a_token_factory::create_token(
//             underlying_tokens_admin_2,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             signer::address_of(underlying_tokens_admin_2),
//             signer::address_of(underlying_tokens_admin_2),
//         );
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         let new_admin = signer::address_of(periphery_account);
//
//         set_emission_admin(aave_role_super_admin, rewards_addr, new_admin);
//
//         let rewards_admin = signer::address_of(underlying_tokens_admin_2);
//         let incentives_controller = signer::address_of(underlying_tokens_admin_2);
//         let rewards_vault = signer::address_of(underlying_tokens_admin_2);
//
//         let underlying_token = signer::address_of(underlying_tokens_admin_2);
//
//         let stake_contract =
//             aave_pool::staked_token::create_mock_staked_token(underlying_token);
//
//         let pull_rewards_transfer_strategy =
//             option::some(
//                 aave_pool::transfer_strategy::create_pull_rewards_transfer_strategy(
//                     rewards_admin, incentives_controller, rewards_vault
//                 ),
//             );
//         // let staked_token_transfer_strategy = option::some(aave_pool::transfer_strategy::create_staked_token_transfer_strategy(rewards_admin, incentives_controller, stake_contract, underlying_token));
//         let staked_token_transfer_strategy = option::none();
//
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let reward = rewards_addr;
//
//         let rewards_map = std::simple_map::new();
//
//         let available_rewards_count = 0;
//
//         let index = 0;
//         let emission_per_second = 0;
//         let last_update_timestamp = 0;
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
//         std::simple_map::upsert(&mut rewards_map, reward, reward_data);
//
//         let asset_data =
//             aave_pool::rewards_controller::create_asset_data(
//                 rewards_map,
//                 std::simple_map::new(),
//                 available_rewards_count,
//                 decimals,
//             );
//         let asset =
//             aptos_framework::object::create_object_address(
//                 &signer::address_of(underlying_tokens_admin_2), *string::bytes(&symbol)
//             );
//
//         let id = 1;
//         let reward_oracle = aave_oracle::reward_oracle::create_reward_oracle(id);
//
//         let config = vector::empty<aave_pool::transfer_strategy::RewardsConfigInput>();
//         let rewards_config_input =
//             aave_pool::transfer_strategy::create_rewards_config_input(
//                 emission_per_second,
//                 total_supply,
//                 distribution_end,
//                 asset,
//                 reward,
//                 staked_token_transfer_strategy,
//                 pull_rewards_transfer_strategy,
//                 reward_oracle,
//             );
//         vector::push_back(&mut config, rewards_config_input);
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_rewards_controller_admin_role_for_testing(),
//             signer::address_of(periphery_account),
//         );
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_rewards_controller_admin_role_for_testing(),
//             reward,
//         );
//
//         aave_pool::rewards_controller::add_asset(rewards_addr, asset, asset_data);
//         aave_pool::rewards_controller::enable_reward(rewards_addr, rewards_addr);
//
//         set_emission_admin(aave_role_super_admin, rewards_addr, rewards_addr);
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_emission_admin_role(),
//             rewards_addr,
//         );
//
//         set_distribution_end(
//             periphery_account,
//             asset,
//             rewards_addr,
//             10,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111, user_account = @0x222, new_admin = @0x1, underlying_tokens_admin = @aave_acl, underlying_tokens_admin_2 = @underlying_tokens, aptos_framework = @0x1,)]
//     fun test_set_emission_per_second(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         reward: &signer,
//         user_account: &signer,
//         new_admin: &signer,
//         underlying_tokens_admin: &signer,
//         underlying_tokens_admin_2: &signer,
//         aptos_framework: &signer,
//     ) {
//         aptos_framework::timestamp::set_time_has_started_for_testing(aptos_framework);
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         // mock_underlying_token_factory::test_init_module(periphery_account);
//         token_base::test_init_module(periphery_account);
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//
//         // create a tokens admin account
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(underlying_tokens_admin_2)
//         );
//
//         aave_pool::a_token_factory::create_token(
//             underlying_tokens_admin_2,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             signer::address_of(underlying_tokens_admin_2),
//             signer::address_of(underlying_tokens_admin_2),
//         );
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         let new_admin = signer::address_of(periphery_account);
//
//         set_emission_admin(aave_role_super_admin, rewards_addr, new_admin);
//
//         let rewards_admin = signer::address_of(underlying_tokens_admin_2);
//         let incentives_controller = signer::address_of(underlying_tokens_admin_2);
//         let rewards_vault = signer::address_of(underlying_tokens_admin_2);
//
//         let underlying_token = signer::address_of(underlying_tokens_admin_2);
//
//         let stake_contract =
//             aave_pool::staked_token::create_mock_staked_token(underlying_token);
//
//         let pull_rewards_transfer_strategy =
//             option::some(
//                 aave_pool::transfer_strategy::create_pull_rewards_transfer_strategy(
//                     rewards_admin, incentives_controller, rewards_vault
//                 ),
//             );
//         // let staked_token_transfer_strategy = option::some(aave_pool::transfer_strategy::create_staked_token_transfer_strategy(rewards_admin, incentives_controller, stake_contract, underlying_token));
//         let staked_token_transfer_strategy = option::none();
//
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let reward = rewards_addr;
//
//         let rewards_map = std::simple_map::new();
//
//         let available_rewards_count = 0;
//
//         let index = 0;
//         let emission_per_second = 0;
//         let last_update_timestamp = 1;
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
//         std::simple_map::upsert(&mut rewards_map, reward, reward_data);
//
//         let asset_data =
//             aave_pool::rewards_controller::create_asset_data(
//                 rewards_map,
//                 std::simple_map::new(),
//                 available_rewards_count,
//                 decimals,
//             );
//         let asset =
//             aptos_framework::object::create_object_address(
//                 &signer::address_of(underlying_tokens_admin_2), *string::bytes(&symbol)
//             );
//
//         let id = 1;
//         let reward_oracle = aave_oracle::reward_oracle::create_reward_oracle(id);
//
//         let config = vector::empty<aave_pool::transfer_strategy::RewardsConfigInput>();
//         let rewards_config_input =
//             aave_pool::transfer_strategy::create_rewards_config_input(
//                 emission_per_second,
//                 total_supply,
//                 distribution_end,
//                 asset,
//                 reward,
//                 staked_token_transfer_strategy,
//                 pull_rewards_transfer_strategy,
//                 reward_oracle,
//             );
//         vector::push_back(&mut config, rewards_config_input);
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_rewards_controller_admin_role_for_testing(),
//             signer::address_of(periphery_account),
//         );
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_rewards_controller_admin_role_for_testing(),
//             reward,
//         );
//
//         aave_pool::rewards_controller::add_asset(rewards_addr, asset, asset_data);
//         aave_pool::rewards_controller::enable_reward(rewards_addr, rewards_addr);
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_emission_admin_role(),
//             rewards_addr,
//         );
//
//         let rewards_arg = vector[rewards_addr];
//         let new_emissions_per_second_arg = vector[0];
//
//         set_emission_per_second(
//             periphery_account,
//             asset,
//             rewards_arg,
//             new_emissions_per_second_arg,
//         );
//     }
//
//     #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111, user_account = @0x222, new_admin = @0x1, underlying_tokens_admin = @aave_acl, underlying_tokens_admin_2 = @underlying_tokens, aptos_framework = @0x1,)]
//     fun test_set_claimer(
//         aave_role_super_admin: &signer,
//         periphery_account: &signer,
//         reward: &signer,
//         user_account: &signer,
//         new_admin: &signer,
//         underlying_tokens_admin: &signer,
//         underlying_tokens_admin_2: &signer,
//         aptos_framework: &signer,
//     ) {
//         aptos_framework::timestamp::set_time_has_started_for_testing(aptos_framework);
//         // init acl
//         acl_manage::test_init_module(aave_role_super_admin);
//
//         // mock_underlying_token_factory::test_init_module(periphery_account);
//         token_base::test_init_module(periphery_account);
//
//         let i = 0;
//
//         let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
//         let symbol = string_utils::format1(&b"U_{}", i);
//         let decimals = 2 + i;
//         let max_supply = 10000;
//
//         // create a tokens admin account
//         aptos_framework::account::create_account_for_test(
//             signer::address_of(underlying_tokens_admin_2)
//         );
//
//         aave_pool::a_token_factory::create_token(
//             underlying_tokens_admin_2,
//             name,
//             symbol,
//             decimals,
//             utf8(b""),
//             utf8(b""),
//             signer::address_of(underlying_tokens_admin_2),
//             signer::address_of(underlying_tokens_admin_2),
//         );
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
//         acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(periphery_account)
//         );
//
//         initialize(periphery_account, rewards_addr);
//
//         let new_admin = signer::address_of(periphery_account);
//
//         set_emission_admin(aave_role_super_admin, rewards_addr, new_admin);
//
//         let rewards_admin = signer::address_of(underlying_tokens_admin_2);
//         let incentives_controller = signer::address_of(underlying_tokens_admin_2);
//         let rewards_vault = signer::address_of(underlying_tokens_admin_2);
//
//         let underlying_token = signer::address_of(underlying_tokens_admin_2);
//
//         let stake_contract =
//             aave_pool::staked_token::create_mock_staked_token(underlying_token);
//
//         let pull_rewards_transfer_strategy =
//             option::some(
//                 aave_pool::transfer_strategy::create_pull_rewards_transfer_strategy(
//                     rewards_admin, incentives_controller, rewards_vault
//                 ),
//             );
//         // let staked_token_transfer_strategy = option::some(aave_pool::transfer_strategy::create_staked_token_transfer_strategy(rewards_admin, incentives_controller, stake_contract, underlying_token));
//         let staked_token_transfer_strategy = option::none();
//
//         let emission_per_second = 0;
//         let total_supply = 0;
//         let distribution_end = 0;
//
//         let reward = rewards_addr;
//
//         let rewards_map = std::simple_map::new();
//
//         let available_rewards_count = 0;
//
//         let index = 0;
//         let emission_per_second = 0;
//         let last_update_timestamp = 1;
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
//         std::simple_map::upsert(&mut rewards_map, reward, reward_data);
//
//         let asset_data =
//             aave_pool::rewards_controller::create_asset_data(
//                 rewards_map,
//                 std::simple_map::new(),
//                 available_rewards_count,
//                 decimals,
//             );
//         let asset =
//             aptos_framework::object::create_object_address(
//                 &signer::address_of(underlying_tokens_admin_2), *string::bytes(&symbol)
//             );
//
//         let id = 1;
//         let reward_oracle = aave_oracle::reward_oracle::create_reward_oracle(id);
//
//         let config = vector::empty<aave_pool::transfer_strategy::RewardsConfigInput>();
//         let rewards_config_input =
//             aave_pool::transfer_strategy::create_rewards_config_input(
//                 emission_per_second,
//                 total_supply,
//                 distribution_end,
//                 asset,
//                 reward,
//                 staked_token_transfer_strategy,
//                 pull_rewards_transfer_strategy,
//                 reward_oracle,
//             );
//         vector::push_back(&mut config, rewards_config_input);
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_rewards_controller_admin_role_for_testing(),
//             signer::address_of(periphery_account),
//         );
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_rewards_controller_admin_role_for_testing(),
//             reward,
//         );
//
//         aave_pool::rewards_controller::add_asset(rewards_addr, asset, asset_data);
//         aave_pool::rewards_controller::enable_reward(rewards_addr, rewards_addr);
//
//         aave_acl::acl_manage::grant_role(
//             aave_role_super_admin,
//             aave_acl::acl_manage::get_emission_admin_role(),
//             rewards_addr,
//         );
//
//         let rewards_arg = vector[rewards_addr];
//         let new_emissions_per_second_arg = vector[0];
//
//         set_emission_per_second(
//             periphery_account,
//             asset,
//             rewards_arg,
//             new_emissions_per_second_arg,
//         );
//
//         aave_acl::acl_manage::add_emission_admin_role(
//             aave_role_super_admin, signer::address_of(aave_role_super_admin)
//         );
//
//         set_claimer(
//             aave_role_super_admin,
//             signer::address_of(aave_role_super_admin),
//             signer::address_of(aave_role_super_admin),
//         );
//     }
// }
