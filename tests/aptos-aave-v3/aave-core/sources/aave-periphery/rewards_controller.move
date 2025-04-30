module aave_pool::rewards_controller {
    use std::signer;
    use std::simple_map::{Self, SimpleMap};
    use std::vector;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;
    use aptos_framework::object::{Self, Object, ObjectGroup};
    use aptos_framework::timestamp;

    use aave_acl::acl_manage::Self;
    use aave_math::math_utils;
    use aave_oracle::reward_oracle::{Self, RewardOracle};

    use aave_pool::a_token_factory;
    use aave_pool::transfer_strategy::check_is_emission_admin;
    use aave_pool::transfer_strategy::{
        get_asset,
        get_emission_per_second,
        get_reward,
        get_total_supply,
        has_pull_rewards_transfer_strategy,
        pull_rewards_transfer_strategy_get_strategy,
        PullRewardsTransferStrategy,
        RewardsConfigInput,
        set_total_supply,
        staked_token_transfer_strategy_get_strategy,
        StakedTokenTransferStrategy,
        validate_rewards_config_input
    };

    const REVISION: u64 = 1;

    const CLAIMER_UNAUTHORIZED: u64 = 1;
    const INDEX_OVERFLOW: u64 = 2;
    const ONLY_EMISSION_MANAGER: u64 = 3;
    const INVALID_INPUT: u64 = 4;
    const DISTRIBUTION_DOES_NOT_EXIST: u64 = 5;
    const ORACLE_MUST_RETURN_PRICE: u64 = 6;
    const TRANSFER_ERROR: u64 = 7;

    const NOT_REWARDS_CONTROLLER_ADMIN: u64 = 8;

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_NAME";

    #[resource_group_member(group = ObjectGroup)]
    struct RewardsControllerData has key {
        authorized_claimers: SmartTable<address, address>,
        pull_rewards_transfer_strategy_table: SmartTable<address, PullRewardsTransferStrategy>,
        staked_token_transfer_strategy_table: SmartTable<address, StakedTokenTransferStrategy>,
        reward_oracle: SmartTable<address, RewardOracle>,
        emission_manager: address,
        assets: SmartTable<address, AssetData>,
        is_reward_enabled: SmartTable<address, bool>,
        rewards_list: vector<address>,
        assets_list: vector<address>
    }

    fun assert_access(account: address) {
        assert!(
            acl_manage::is_rewards_controller_admin(account),
            NOT_REWARDS_CONTROLLER_ADMIN
        );
    }

    public fun initialize(sender: &signer, emission_manager: address) {
        let state_object_constructor_ref =
            &object::create_named_object(sender, REWARDS_CONTROLLER_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            RewardsControllerData {
                authorized_claimers: smart_table::new<address, address>(),
                pull_rewards_transfer_strategy_table: smart_table::new<address, PullRewardsTransferStrategy>(),
                staked_token_transfer_strategy_table: smart_table::new<address, StakedTokenTransferStrategy>(),
                reward_oracle: smart_table::new<address, RewardOracle>(),
                emission_manager,
                assets: smart_table::new<address, AssetData>(),
                is_reward_enabled: smart_table::new<address, bool>(),
                rewards_list: vector[],
                assets_list: vector[]
            }
        );
    }

    struct AssetData has key, store, drop {
        rewards: std::simple_map::SimpleMap<address, RewardData>,
        available_rewards: std::simple_map::SimpleMap<u128, address>,
        available_rewards_count: u128,
        decimals: u8
    }

    public fun create_asset_data(
        rewards: SimpleMap<address, RewardData>,
        available_rewards: SimpleMap<u128, address>,
        available_rewards_count: u128,
        decimals: u8
    ): AssetData {
        AssetData { rewards, available_rewards, available_rewards_count, decimals }
    }

    struct RewardData has key, store, drop, copy {
        index: u128,
        emission_per_second: u128,
        last_update_timestamp: u32,
        distribution_end: u32,
        users_data: std::simple_map::SimpleMap<address, UserData>
    }

    public fun create_reward_data(
        index: u128,
        emission_per_second: u128,
        last_update_timestamp: u32,
        distribution_end: u32,
        users_data: std::simple_map::SimpleMap<address, UserData>
    ): RewardData {
        RewardData {
            index,
            emission_per_second,
            last_update_timestamp,
            distribution_end,
            users_data
        }
    }

    struct UserData has key, store, copy, drop {
        index: u128,
        accrued: u128
    }

    #[test_only]
    public fun create_user_data(index: u128, accrued: u128): UserData {
        UserData { index, accrued }
    }

    struct UserAssetBalance has store, drop, copy {
        asset: address,
        user_balance: u256,
        total_supply: u256
    }

    #[event]
    struct ClaimerSet has store, drop {
        user: address,
        claimer: address
    }

    #[event]
    struct Accrued has store, drop {
        asset: address,
        reward: address,
        user: address,
        asset_index: u256,
        user_index: u256,
        rewards_accrued: u256
    }

    #[event]
    struct AssetConfigUpdated has store, drop {
        asset: address,
        reward: address,
        old_emission: u256,
        new_emission: u256,
        old_distribution_end: u256,
        new_distribution_end: u256,
        asset_index: u256
    }

    #[event]
    struct RewardsClaimed has store, drop {
        user: address,
        reward: address,
        to: address,
        claimer: address,
        amount: u256
    }

    #[event]
    struct RewardOracleUpdated has store, drop {
        reward: address,
        reward_oracle: RewardOracle
    }

    #[event]
    struct PullRewardsTransferStrategyInstalled has store, drop {
        reward: address,
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy
    }

    #[event]
    struct StakedTokenTransferStrategyInstalled has store, drop {
        reward: address,
        staked_token_transfer_strategy: StakedTokenTransferStrategy
    }

    #[view]
    public fun rewards_controller_address(): address {
        object::create_object_address(&@aave_pool, REWARDS_CONTROLLER_NAME)
    }

    #[view]
    public fun rewards_controller_object(): Object<RewardsControllerData> {
        object::address_to_object<RewardsControllerData>(rewards_controller_address())
    }

    fun only_authorized_claimers(
        claimer: address, user: address, rewards_controller_address: address
    ) acquires RewardsControllerData {
        assert!(
            get_claimer(user, rewards_controller_address) == claimer,
            CLAIMER_UNAUTHORIZED
        );
    }

    #[test_only]
    public fun add_asset(
        rewards_controller_address: address, asset_addr: address, asset: AssetData
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::add(&mut rewards_controller_data.assets, asset_addr, asset);
    }

    #[test_only]
    public fun enable_reward(
        rewards_controller_address: address, reward: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::add(&mut rewards_controller_data.is_reward_enabled, reward, true);
    }

    #[view]
    public fun get_claimer(
        user: address, rewards_controller_address: address
    ): address acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let claimer =
            smart_table::borrow(&rewards_controller_data.authorized_claimers, user);
        *claimer
    }

    #[view]
    public fun get_revision(): u64 {
        REVISION
    }

    #[view]
    public fun get_reward_oracle(
        reward: address, rewards_controller_address: address
    ): RewardOracle acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        *smart_table::borrow(&rewards_controller_data.reward_oracle, reward)
    }

    public fun get_pull_rewards_transfer_strategy(
        reward: address, rewards_controller_address: address
    ): PullRewardsTransferStrategy acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        *smart_table::borrow(
            &rewards_controller_data.pull_rewards_transfer_strategy_table, reward
        )
    }

    public fun get_staked_token_transfer_strategy(
        reward: address, rewards_controller_address: address
    ): StakedTokenTransferStrategy acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        *smart_table::borrow(
            &rewards_controller_data.staked_token_transfer_strategy_table, reward
        )
    }

    public fun configure_assets(
        caller: &signer,
        config: vector<RewardsConfigInput>,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        only_emission_manager(caller, rewards_controller_address);
        for (i in 0..vector::length(&config)) {
            let config_el = vector::borrow_mut(&mut config, i);

            validate_rewards_config_input(config_el);

            let asset = get_asset(config_el);
            set_total_supply(config_el, a_token_factory::scaled_total_supply(asset));

            let reward = aave_pool::transfer_strategy::get_reward(config_el);

            if (has_pull_rewards_transfer_strategy(config_el)) {
                install_pull_rewards_transfer_strategy(
                    reward,
                    pull_rewards_transfer_strategy_get_strategy(config_el),
                    rewards_controller_address
                );
            } else {
                install_staked_token_transfer_strategy(
                    reward,
                    staked_token_transfer_strategy_get_strategy(config_el),
                    rewards_controller_address
                );
            };

            set_reward_oracle(
                caller,
                reward,
                aave_pool::transfer_strategy::get_reward_oracle(
                    vector::borrow(&config, i)
                ),
                rewards_controller_address
            );
        };
        configure_assets_internal(config, rewards_controller_address);
    }

    public fun set_pull_rewards_transfer_strategy(
        caller: &signer,
        reward: address,
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        only_emission_manager(caller, rewards_controller_address);
        install_pull_rewards_transfer_strategy(
            reward, pull_rewards_transfer_strategy, rewards_controller_address
        );
    }

    public fun set_staked_token_transfer_strategy(
        caller: &signer,
        reward: address,
        staked_token_transfer_strategy: StakedTokenTransferStrategy,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        only_emission_manager(caller, rewards_controller_address);
        install_staked_token_transfer_strategy(
            reward, staked_token_transfer_strategy, rewards_controller_address
        );
    }

    public fun set_reward_oracle(
        caller: &signer,
        reward: address,
        reward_oracle: RewardOracle,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        assert_access(signer::address_of(caller));
        only_emission_manager(caller, rewards_controller_address);
        set_reward_oracle_internal(reward, reward_oracle);
    }

    #[test_only]
    public fun test_handle_action(
        caller: &signer,
        user: address,
        total_supply: u256,
        user_balance: u256,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        handle_action(
            caller,
            user,
            total_supply,
            user_balance,
            rewards_controller_address
        )
    }

    fun handle_action(
        caller: &signer,
        user: address,
        total_supply: u256,
        user_balance: u256,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        let addr = signer::address_of(caller);
        update_data(
            addr,
            user,
            user_balance,
            total_supply,
            rewards_controller_address
        );
    }

    public fun claim_rewards(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let addr = signer::address_of(caller);
        claim_rewards_internal(
            caller,
            assets,
            amount,
            addr,
            addr,
            to,
            reward,
            rewards_controller_address
        )
    }

    #[test_only]
    public fun test_claim_rewards_on_behalf(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        user: address,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        claim_rewards_on_behalf(
            caller,
            assets,
            amount,
            user,
            to,
            reward,
            rewards_controller_address
        )
    }

    fun claim_rewards_on_behalf(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        user: address,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let addr = signer::address_of(caller);

        only_authorized_claimers(addr, user, rewards_controller_address);
        claim_rewards_internal(
            caller,
            assets,
            amount,
            addr,
            user,
            to,
            reward,
            rewards_controller_address
        )
    }

    #[test_only]
    public fun test_claim_rewards_to_self(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        claim_rewards_to_self(
            caller,
            assets,
            amount,
            reward,
            rewards_controller_address
        )
    }

    fun claim_rewards_to_self(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let addr = signer::address_of(caller);
        claim_rewards_internal(
            caller,
            assets,
            amount,
            addr,
            addr,
            addr,
            reward,
            rewards_controller_address
        )
    }

    public fun claim_all_rewards(
        caller: &signer,
        assets: vector<address>,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        let addr = signer::address_of(caller);
        claim_all_rewards_internal(
            caller,
            assets,
            addr,
            addr,
            to,
            rewards_controller_address
        )
    }

    #[test_only]
    public fun test_claim_all_rewards_on_behalf(
        caller: &signer,
        assets: vector<address>,
        user: address,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        claim_all_rewards_on_behalf(
            caller,
            assets,
            user,
            to,
            rewards_controller_address
        )
    }

    fun claim_all_rewards_on_behalf(
        caller: &signer,
        assets: vector<address>,
        user: address,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        let addr = signer::address_of(caller);

        only_authorized_claimers(addr, user, rewards_controller_address);
        claim_all_rewards_internal(
            caller,
            assets,
            addr,
            user,
            to,
            rewards_controller_address
        )
    }

    #[test_only]
    public fun test_claim_all_rewards_to_self(
        caller: &signer, assets: vector<address>, rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        claim_all_rewards_to_self(caller, assets, rewards_controller_address)
    }

    fun claim_all_rewards_to_self(
        caller: &signer, assets: vector<address>, rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        let addr = signer::address_of(caller);
        claim_all_rewards_internal(
            caller,
            assets,
            addr,
            addr,
            addr,
            rewards_controller_address
        )
    }

    public fun set_claimer(
        user: address, claimer: address, rewards_controller_address: address
    ) acquires RewardsControllerData {
        check_is_emission_admin(user);

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::upsert(
            &mut rewards_controller_data.authorized_claimers, user, claimer
        );
        event::emit(ClaimerSet { user, claimer });
    }

    fun get_user_asset_balances(assets: vector<address>, user: address):
        vector<UserAssetBalance> {
        let user_asset_balances = vector[];
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let user_balance = a_token_factory::scaled_balance_of(user, asset);
            let total_supply = a_token_factory::scaled_total_supply(asset);

            vector::push_back(
                &mut user_asset_balances,
                UserAssetBalance { asset, user_balance, total_supply }
            );
        };
        user_asset_balances
    }

    fun claim_rewards_internal(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        claimer: address,
        user: address,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        if (amount == 0) {
            return 0
        };
        let total_rewards = 0;

        update_data_multiple(
            user,
            get_user_asset_balances(assets, user),
            rewards_controller_address
        );

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);

            let asset_el =
                smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
            let reward_data: &mut RewardData =
                simple_map::borrow_mut(&mut asset_el.rewards, &reward);
            let user_data: &mut UserData =
                simple_map::borrow_mut(&mut reward_data.users_data, &user);
            total_rewards = total_rewards + (user_data.accrued as u256);

            if (total_rewards <= amount) {
                user_data.accrued = 0;
            } else {
                let difference = total_rewards - amount;
                total_rewards = total_rewards - difference;
                user_data.accrued = (difference as u128);
                break
            };
        };

        if (total_rewards == 0) {
            return 0
        };

        if (smart_table::contains(
            &rewards_controller_data.pull_rewards_transfer_strategy_table, reward
        )) {
            transfer_pull_rewards_transfer_strategy_rewards(
                caller,
                to,
                reward,
                total_rewards,
                rewards_controller_data
            )
        } else if (smart_table::contains(
            &rewards_controller_data.pull_rewards_transfer_strategy_table, reward
        )) {
            transfer_staked_token_transfer_strategy_rewards(
                caller,
                to,
                reward,
                total_rewards,
                rewards_controller_data
            )
        };
        event::emit(
            RewardsClaimed { user, reward: claimer, to, claimer, amount: total_rewards }
        );

        total_rewards
    }

    fun claim_all_rewards_internal(
        caller: &signer,
        assets: vector<address>,
        claimer: address,
        user: address,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        update_data_multiple(
            user,
            get_user_asset_balances(assets, user),
            rewards_controller_address
        );

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let rewards_list_length = vector::length(&rewards_controller_data.rewards_list);

        let rewards_list = rewards_controller_data.rewards_list;
        let claimed_amounts = vector[];

        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let asset_el =
                smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);

            for (j in 0..rewards_list_length) {
                let reward_data: &mut RewardData =
                    simple_map::borrow_mut(
                        &mut asset_el.rewards, vector::borrow(&rewards_list, j)
                    );
                let user_data: &mut UserData =
                    simple_map::borrow_mut(&mut reward_data.users_data, &user);

                let reward_amount = (user_data.accrued as u256);
                if (reward_amount != 0) {
                    if (vector::length(&claimed_amounts) > 0) {
                        let claimed_amounts_j =
                            *vector::borrow_mut(&mut claimed_amounts, j);
                        vector::insert(
                            &mut claimed_amounts, j, claimed_amounts_j + reward_amount
                        );
                    } else {
                        vector::insert(&mut claimed_amounts, j, reward_amount);
                    };
                    user_data.accrued = 0;
                };
            };
        };

        for (i in 0..rewards_list_length) {
            if (smart_table::contains(
                &rewards_controller_data.pull_rewards_transfer_strategy_table,
                *vector::borrow(&rewards_list, i)
            )) {
                transfer_pull_rewards_transfer_strategy_rewards(
                    caller,
                    to,
                    *vector::borrow(&rewards_list, i),
                    *vector::borrow(&claimed_amounts, i),
                    rewards_controller_data
                )
            } else if (smart_table::contains(
                &rewards_controller_data.pull_rewards_transfer_strategy_table,
                *vector::borrow(&rewards_list, i)
            )) {
                transfer_staked_token_transfer_strategy_rewards(
                    caller,
                    to,
                    *vector::borrow(&rewards_list, i),
                    *vector::borrow(&claimed_amounts, i),
                    rewards_controller_data
                )
            };
            event::emit(
                RewardsClaimed {
                    user,
                    reward: *vector::borrow(&rewards_list, i),
                    to,
                    claimer,
                    amount: *vector::borrow(&claimed_amounts, i)
                }
            );
        };
        (rewards_list, claimed_amounts)
    }

    fun transfer_pull_rewards_transfer_strategy_rewards(
        caller: &signer,
        to: address,
        reward: address,
        amount: u256,
        rewards_controller_data: &mut RewardsControllerData
    ) {
        let pull_rewards_transfer_strategy =
            *smart_table::borrow(
                &rewards_controller_data.pull_rewards_transfer_strategy_table, reward
            );
        let success =
            aave_pool::transfer_strategy::pull_rewards_transfer_strategy_perform_transfer(
                caller,
                to,
                reward,
                amount,
                pull_rewards_transfer_strategy
            );

        assert!(success, TRANSFER_ERROR);
    }

    fun transfer_staked_token_transfer_strategy_rewards(
        caller: &signer,
        to: address,
        reward: address,
        amount: u256,
        rewards_controller_data: &mut RewardsControllerData
    ) {
        let staked_token_transfer_strategy =
            *smart_table::borrow(
                &rewards_controller_data.staked_token_transfer_strategy_table, reward
            );
        let success =
            aave_pool::transfer_strategy::staked_token_transfer_strategy_perform_transfer(
                caller,
                to,
                reward,
                amount,
                staked_token_transfer_strategy
            );

        assert!(success, TRANSFER_ERROR);
    }

    fun install_pull_rewards_transfer_strategy(
        reward: address,
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::upsert(
            &mut rewards_controller_data.pull_rewards_transfer_strategy_table,
            reward,
            pull_rewards_transfer_strategy
        );

        event::emit(
            PullRewardsTransferStrategyInstalled { reward, pull_rewards_transfer_strategy }
        );
    }

    fun install_staked_token_transfer_strategy(
        reward: address,
        staked_token_transfer_strategy: StakedTokenTransferStrategy,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::upsert(
            &mut rewards_controller_data.staked_token_transfer_strategy_table,
            reward,
            staked_token_transfer_strategy
        );

        event::emit(
            StakedTokenTransferStrategyInstalled { reward, staked_token_transfer_strategy }
        );
    }

    public fun set_reward_oracle_internal(
        reward: address, reward_oracle: RewardOracle
    ) acquires RewardsControllerData {
        assert!(
            reward_oracle::latest_answer(reward_oracle) > 0, ORACLE_MUST_RETURN_PRICE
        );

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address());
        smart_table::upsert(
            &mut rewards_controller_data.reward_oracle, reward, reward_oracle
        );

        event::emit(RewardOracleUpdated { reward, reward_oracle });
    }

    fun only_emission_manager(
        sender: &signer, rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        assert!(
            signer::address_of(sender) == rewards_controller_data.emission_manager,
            ONLY_EMISSION_MANAGER
        );
    }

    #[view]
    public fun get_rewards_data(
        asset: address, reward: address, rewards_controller_address: address
    ): (u256, u256, u256, u256) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow(&rewards_controller_data.assets, asset);
        let rewards_data: &RewardData = simple_map::borrow(&asset.rewards, &reward);
        (
            (rewards_data.index as u256),
            (rewards_data.emission_per_second as u256),
            (rewards_data.last_update_timestamp as u256),
            (rewards_data.distribution_end as u256)
        )
    }

    #[test_only]
    public fun add_rewards_data(
        asset: address,
        reward: address,
        rewards_controller_address: address,
        reward_data: RewardData
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        simple_map::upsert(&mut asset.rewards, reward, reward_data);
    }

    #[view]
    public fun get_asset_index(
        asset: address, reward: address, rewards_controller_address: address
    ): (u256, u256) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let asset_el = smart_table::borrow(&rewards_controller_data.assets, asset);
        let rewards_data: &RewardData = simple_map::borrow(&asset_el.rewards, &reward);
        get_asset_index_internal(
            rewards_data,
            a_token_factory::scaled_total_supply(asset),
            math_utils::pow(10, (asset_el.decimals as u256))
        )
    }

    #[view]
    public fun get_distribution_end(
        asset: address, reward: address, rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow(&rewards_controller_data.assets, asset);
        let reward_data: &RewardData = simple_map::borrow(&asset.rewards, &reward);
        (reward_data.distribution_end as u256)
    }

    #[view]
    public fun get_rewards_by_asset(
        asset: address, rewards_controller_address: address
    ): vector<address> acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow(&rewards_controller_data.assets, asset);

        let rewards_count = asset.available_rewards_count;
        let available_rewards: vector<address> = vector[];

        for (i in 0..rewards_count) {
            let el = simple_map::borrow(&asset.available_rewards, &i);
            vector::push_back(&mut available_rewards, *el);
        };
        available_rewards
    }

    #[test_only]
    public fun add_rewards_by_asset(
        asset: address,
        rewards_controller_address: address,
        i: u128,
        addr: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        // asset.available_rewards_count = asset.available_rewards_count + 1;

        simple_map::upsert(&mut asset.available_rewards, i, addr);
    }

    #[view]
    public fun get_rewards_list(
        rewards_controller_address: address
    ): vector<address> acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        rewards_controller_data.rewards_list
    }

    #[view]
    public fun get_user_asset_index(
        user: address,
        asset: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow(&rewards_controller_data.assets, asset);
        let reward_data: &RewardData = simple_map::borrow(&asset.rewards, &reward);
        let user_data: &UserData = simple_map::borrow(&reward_data.users_data, &user);
        (user_data.index as u256)
    }

    public fun add_user_asset_index(
        user: address,
        asset: address,
        reward: address,
        rewards_controller_address: address,
        user_data: UserData
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        let reward_data: &mut RewardData =
            simple_map::borrow_mut(&mut asset.rewards, &reward);
        simple_map::upsert(&mut reward_data.users_data, user, user_data);
    }

    #[view]
    public fun get_user_accrued_rewards(
        user: address, reward: address, rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let total_accrued = 0;

        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);

        let assets_list = rewards_controller_data.assets_list;

        for (i in 0..vector::length(&assets_list)) {
            let asset =
                smart_table::borrow(
                    &rewards_controller_data.assets,
                    *vector::borrow(&assets_list, i)
                );
            let reward_data: &RewardData = simple_map::borrow(&asset.rewards, &reward);
            let user_data: &UserData = simple_map::borrow(
                &reward_data.users_data, &user
            );

            total_accrued = total_accrued + (user_data.accrued as u256);
        };

        total_accrued
    }

    #[view]
    public fun get_user_rewards(
        assets: vector<address>,
        user: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        get_user_reward(
            user,
            reward,
            get_user_asset_balances(assets, user),
            rewards_controller_address
        )
    }

    #[test_only]
    public fun add_to_rewards_list(
        reward: address, rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        vector::push_back(
            &mut rewards_controller_data.rewards_list,
            reward
        );
    }

    #[test_only]
    public fun add_to_assets_list(
        asset: address, rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        vector::push_back(
            &mut rewards_controller_data.assets_list,
            asset
        );
    }

    #[view]
    public fun get_all_user_rewards(
        assets: vector<address>, user: address, rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        let user_asset_balances = get_user_asset_balances(assets, user);
        let rewards_list = vector[];
        let unclaimed_amounts = vector[];

        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let rewards_list_len = vector::length(&rewards_controller_data.rewards_list);

        for (i in 0..rewards_list_len) {
            for (r in 0..rewards_list_len) {
                vector::push_back(
                    &mut rewards_list,
                    *vector::borrow(&rewards_controller_data.rewards_list, r)
                );
                let asset_el =
                    smart_table::borrow(
                        &rewards_controller_data.assets,
                        vector::borrow(&user_asset_balances, r).asset
                    );
                let rewards_el =
                    simple_map::borrow(
                        &asset_el.rewards, vector::borrow(&rewards_list, r)
                    );
                let user_data = simple_map::borrow(&rewards_el.users_data, &user);
                vector::push_back(&mut unclaimed_amounts, (user_data.accrued as u256));

                if (vector::borrow(&user_asset_balances, i).user_balance == 0) {
                    continue
                };
                let prev = vector::pop_back(&mut unclaimed_amounts);
                vector::push_back(
                    &mut unclaimed_amounts,
                    prev
                        + get_pending_rewards(
                            user,
                            *vector::borrow(&rewards_list, r),
                            vector::borrow(&user_asset_balances, i),
                            rewards_controller_data
                        )
                );
            };
        };
        (rewards_list, unclaimed_amounts)
    }

    public fun set_distribution_end(
        caller: &signer,
        asset: address,
        reward: address,
        new_distribution_end: u32,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        only_emission_manager(caller, rewards_controller_address);

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let asset_el: &mut AssetData =
            smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        let reward_data: &mut RewardData =
            simple_map::borrow_mut(&mut asset_el.rewards, &reward);

        let old_distribution_end = (reward_data.distribution_end as u256);
        reward_data.distribution_end = new_distribution_end;

        event::emit(
            AssetConfigUpdated {
                asset,
                reward,
                old_emission: (reward_data.emission_per_second as u256),
                new_emission: (reward_data.emission_per_second as u256),
                old_distribution_end,
                new_distribution_end: (new_distribution_end as u256),
                asset_index: (reward_data.index as u256)
            }
        );
    }

    public fun set_emission_per_second(
        caller: &signer,
        asset: address,
        rewards: vector<address>,
        new_emissions_per_second: vector<u128>,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        only_emission_manager(caller, rewards_controller_address);

        let rewards_len = vector::length(&rewards);

        assert!(rewards_len == vector::length(&new_emissions_per_second), INVALID_INPUT);

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        for (i in 0..rewards_len) {
            let asset_config: &mut AssetData =
                smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
            let reward_config: &mut RewardData =
                simple_map::borrow_mut(
                    &mut asset_config.rewards, vector::borrow(&rewards, i)
                );

            let decimals = asset_config.decimals;
            assert!(
                decimals != 0 && reward_config.last_update_timestamp != 0,
                DISTRIBUTION_DOES_NOT_EXIST
            );

            let (new_index, _) =
                update_reward_data(
                    reward_config,
                    a_token_factory::scaled_total_supply(asset),
                    math_utils::pow(10, (decimals as u256))
                );

            let old_emission_per_second = (reward_config.emission_per_second as u256);
            reward_config.emission_per_second = *vector::borrow(
                &new_emissions_per_second, i
            );

            event::emit(
                AssetConfigUpdated {
                    asset,
                    reward: *vector::borrow(&rewards, i),
                    old_emission: old_emission_per_second,
                    new_emission: (*vector::borrow(&new_emissions_per_second, i) as u256),
                    old_distribution_end: (reward_config.distribution_end as u256),
                    new_distribution_end: (reward_config.distribution_end as u256),
                    asset_index: new_index
                }
            );
        }
    }

    fun configure_assets_internal(
        rewards_input: vector<RewardsConfigInput>, rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        for (i in 0..vector::length(&rewards_input)) {
            let reward_input = vector::borrow(&rewards_input, i);
            let asset = get_asset(reward_input);
            let asset_el: &mut AssetData =
                smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
            if (asset_el.decimals == 0) {
                vector::push_back(&mut rewards_controller_data.assets_list, asset);
            };

            asset_el.decimals = a_token_factory::decimals(asset);

            let decimals = asset_el.decimals;

            let reward = get_reward(reward_input);

            let reward_config = simple_map::borrow_mut(&mut asset_el.rewards, &reward);

            if (reward_config.last_update_timestamp == 0) {
                //let update_el = *simple_map::borrow_mut(&mut asset_el.available_rewards, &asset_el.available_rewards_count);
                //update_el = reward;
                asset_el.available_rewards_count = asset_el.available_rewards_count + 1;
            };

            let is_reward_enabled_reward =
                *smart_table::borrow_mut(
                    &mut rewards_controller_data.is_reward_enabled, reward
                );
            if (is_reward_enabled_reward == false) {
                //is_reward_enabled_reward = true;
                vector::push_back(&mut rewards_controller_data.rewards_list, reward);
            };

            let total_supply = get_total_supply(reward_input);

            let (new_index, _) =
                update_reward_data(
                    reward_config,
                    total_supply,
                    math_utils::pow(10, (decimals as u256))
                );

            let old_emissions_per_second = reward_config.emission_per_second;
            let old_distribution_end = reward_config.distribution_end;
            reward_config.emission_per_second = get_emission_per_second(reward_input);
            reward_config.distribution_end = aave_pool::transfer_strategy::get_distribution_end(
                reward_input
            );

            event::emit(
                AssetConfigUpdated {
                    asset,
                    reward,
                    old_emission: (old_emissions_per_second as u256),
                    new_emission: (get_emission_per_second(reward_input) as u256),
                    old_distribution_end: (old_distribution_end as u256),
                    new_distribution_end: (reward_config.distribution_end as u256),
                    asset_index: new_index
                }
            );
        }
    }

    fun update_reward_data(
        reward_data: &mut RewardData, total_supply: u256, asset_unit: u256
    ): (u256, bool) {
        let (old_index, new_index) =
            get_asset_index_internal(reward_data, total_supply, asset_unit);
        let index_updated = false;
        if (new_index != old_index) {
            assert!(new_index <= math_utils::pow(2, 104), INDEX_OVERFLOW);
            index_updated = true;

            reward_data.index = (new_index as u128);
            reward_data.last_update_timestamp = (timestamp::now_seconds() as u32);
        } else {
            reward_data.last_update_timestamp = (timestamp::now_seconds() as u32);
        };

        (new_index, index_updated)
    }

    fun update_user_data(
        reward_data: &mut RewardData,
        user: address,
        user_balance: u256,
        new_asset_index: u256,
        asset_unit: u256
    ): (u256, bool) {
        let user = simple_map::borrow_mut(&mut reward_data.users_data, &user);
        let user_index = user.index;
        let rewards_accrued = 0;
        let data_updated = user_index != (new_asset_index as u128);
        if (data_updated) {
            user.index = (new_asset_index as u128);
            if (user_balance != 0) {
                rewards_accrued = get_rewards(
                    user_balance,
                    new_asset_index,
                    (user_index as u256),
                    asset_unit
                );

                user.accrued = user.accrued + (rewards_accrued as u128);
            };
        };
        (rewards_accrued, data_updated)
    }

    fun update_data(
        asset: address,
        user: address,
        user_balance: u256,
        total_supply: u256,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let asset_el = smart_table::borrow_mut(
            &mut rewards_controller_data.assets, asset
        );
        let num_available_rewards = asset_el.available_rewards_count;
        let asset_unit = math_utils::pow(10, (asset_el.decimals as u256));

        if (num_available_rewards == 0) { return };

        for (r in 0..num_available_rewards) {
            let reward: address = *simple_map::borrow(
                &mut asset_el.available_rewards, &r
            );
            let reward_data: &mut RewardData =
                simple_map::borrow_mut(&mut asset_el.rewards, &reward);

            let (new_asset_index, reward_data_updated) =
                update_reward_data(reward_data, total_supply, asset_unit);

            let (rewards_accrued, user_data_updated) =
                update_user_data(
                    reward_data,
                    user,
                    user_balance,
                    new_asset_index,
                    asset_unit
                );

            if (reward_data_updated || user_data_updated) {
                event::emit(
                    Accrued {
                        asset,
                        reward,
                        user,
                        asset_index: new_asset_index,
                        user_index: new_asset_index,
                        rewards_accrued
                    }
                )
            };
        };
    }

    fun update_data_multiple(
        user: address,
        user_asset_balances: vector<UserAssetBalance>,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        for (i in 0..vector::length(&user_asset_balances)) {
            let user_asset_balances_i = vector::borrow(&user_asset_balances, i);
            update_data(
                user_asset_balances_i.asset,
                user,
                user_asset_balances_i.user_balance,
                user_asset_balances_i.total_supply,
                rewards_controller_address
            );
        };
    }

    fun get_user_reward(
        user: address,
        reward: address,
        user_asset_balances: vector<UserAssetBalance>,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);

        let unclaimed_rewards = 0;
        for (i in 0..vector::length(&user_asset_balances)) {
            let user_asset_balances_i = vector::borrow(&user_asset_balances, i);
            let asset =
                smart_table::borrow(
                    &rewards_controller_data.assets, user_asset_balances_i.asset
                );
            let reward_data: &RewardData = simple_map::borrow(&asset.rewards, &reward);
            let user_data: &UserData = simple_map::borrow(
                &reward_data.users_data, &user
            );

            if (user_asset_balances_i.user_balance == 0) {
                unclaimed_rewards = unclaimed_rewards + (user_data.accrued as u256);
            } else {
                let pending_rewards =
                    get_pending_rewards(
                        user,
                        reward,
                        user_asset_balances_i,
                        rewards_controller_data
                    );
                unclaimed_rewards = unclaimed_rewards + pending_rewards
                    + (user_data.accrued as u256);
            };
        };

        unclaimed_rewards
    }

    fun get_pending_rewards(
        user: address,
        reward: address,
        user_asset_balance: &UserAssetBalance,
        rewards_controller_data: &RewardsControllerData
    ): u256 {
        let asset: &AssetData =
            smart_table::borrow(
                &rewards_controller_data.assets, user_asset_balance.asset
            );
        let reward_data: &RewardData = simple_map::borrow(&asset.rewards, &reward);

        let user_asset =
            smart_table::borrow(
                &rewards_controller_data.assets, user_asset_balance.asset
            );

        let asset_unit = math_utils::pow(10, (user_asset.decimals as u256));
        let (_, next_index) =
            get_asset_index_internal(
                reward_data, user_asset_balance.total_supply, asset_unit
            );

        let user_data: &UserData = simple_map::borrow(&reward_data.users_data, &user);
        let index = (user_data.index as u256);

        get_rewards(
            user_asset_balance.user_balance,
            next_index,
            index,
            asset_unit
        )
    }

    fun get_rewards(
        user_balance: u256,
        reserve_index: u256,
        user_index: u256,
        asset_unit: u256
    ): u256 {
        let result = user_balance * (reserve_index - user_index);
        result / asset_unit
    }

    fun get_asset_index_internal(
        reward_data: &RewardData, total_supply: u256, asset_unit: u256
    ): (u256, u256) {
        let old_index = (reward_data.index as u256);
        let distribution_end = (reward_data.distribution_end as u256);
        let emission_per_second = (reward_data.emission_per_second as u256);
        let last_update_timestamp = (reward_data.last_update_timestamp as u256);

        if (emission_per_second == 0
            || total_supply == 0
            || last_update_timestamp == (timestamp::now_seconds() as u256)
            || last_update_timestamp >= distribution_end) {
            return (old_index, old_index)
        };

        let current_timestamp = (timestamp::now_seconds() as u256);

        if ((timestamp::now_seconds() as u256) > distribution_end) {
            current_timestamp = distribution_end;
        };

        let time_delta = current_timestamp - last_update_timestamp;
        let first_term = emission_per_second * time_delta * asset_unit;
        first_term = first_term / total_supply;
        (old_index, (first_term + old_index))
    }

    #[view]
    public fun get_asset_decimals(
        asset: address, rewards_controller_address: address
    ): u8 acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow(&rewards_controller_data.assets, asset);
        asset.decimals
    }

    #[view]
    public fun get_emission_manager(
        rewards_controller_address: address
    ): address acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        rewards_controller_data.emission_manager
    }
}
