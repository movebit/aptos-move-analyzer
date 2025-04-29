module aave_pool::emission_manager {
    use std::signer;
    use std::vector;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;
    use aptos_framework::object::{
        Self,
        ExtendRef as ObjExtendRef,
        Object,
        ObjectGroup,
        TransferRef as ObjectTransferRef
    };
    use aave_oracle::reward_oracle::RewardOracle;
    use aave_pool::rewards_controller::Self;
    use aave_pool::transfer_strategy::{
        check_is_emission_admin,
        get_reward,
        PullRewardsTransferStrategy,
        RewardsConfigInput,
        StakedTokenTransferStrategy
    };

    const ENOT_MANAGEMENT: u64 = 1;
    const NOT_EMISSION_ADMIN: u64 = 2;
    const ONLY_EMISSION_ADMIN: u64 = 3;

    const EMISSION_MANAGER_NAME: vector<u8> = b"EMISSION_MANAGER";

    #[resource_group_member(group = ObjectGroup)]
    struct EmissionManagerData has key {
        emission_admins: SmartTable<address, address>,
        extend_ref: ObjExtendRef,
        transfer_ref: ObjectTransferRef,
        rewards_controller: address
    }

    #[event]
    struct EmissionAdminUpdated has store, drop {
        reward: address,
        old_admin: address,
        new_admin: address
    }

    fun check_admin(account: address) {
        assert!(account == @aave_acl, ENOT_MANAGEMENT);
    }

    public fun initialize(sender: &signer, rewards_controller: address) {
        let state_object_constructor_ref =
            &object::create_named_object(sender, EMISSION_MANAGER_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            EmissionManagerData {
                emission_admins: smart_table::new<address, address>(),
                transfer_ref: object::generate_transfer_ref(state_object_constructor_ref),
                extend_ref: object::generate_extend_ref(state_object_constructor_ref),
                rewards_controller
            }
        );
    }

    #[view]
    public fun emission_manager_address(): address {
        object::create_object_address(&@aave_pool, EMISSION_MANAGER_NAME)
    }

    #[view]
    public fun emission_manager_object(): Object<EmissionManagerData> {
        object::address_to_object<EmissionManagerData>(emission_manager_address())
    }

    public fun configure_assets(
        account: &signer, config: vector<RewardsConfigInput>
    ) acquires EmissionManagerData {
        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());

        for (i in 0..vector::length(&config)) {
            let reward = get_reward(vector::borrow(&config, i));
            assert!(
                *smart_table::borrow(&emission_manager_data.emission_admins, reward)
                    == signer::address_of(account),
                ONLY_EMISSION_ADMIN
            );
        };
        rewards_controller::configure_assets(
            account, config, emission_manager_data.rewards_controller
        );
    }

    public fun set_pull_rewards_transfer_strategy(
        caller: &signer,
        reward: address,
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy
    ) acquires EmissionManagerData {
        check_is_emission_admin(reward);

        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());
        rewards_controller::set_pull_rewards_transfer_strategy(
            caller,
            reward,
            pull_rewards_transfer_strategy,
            emission_manager_data.rewards_controller
        );
    }

    public fun set_staked_token_transfer_strategy(
        caller: &signer,
        reward: address,
        staked_token_transfer_strategy: StakedTokenTransferStrategy
    ) acquires EmissionManagerData {
        check_is_emission_admin(reward);

        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());
        rewards_controller::set_staked_token_transfer_strategy(
            caller,
            reward,
            staked_token_transfer_strategy,
            emission_manager_data.rewards_controller
        );
    }

    public fun set_reward_oracle(
        caller: &signer, reward: address, reward_oracle: RewardOracle
    ) acquires EmissionManagerData {
        check_is_emission_admin(reward);
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());
        rewards_controller::set_reward_oracle(
            caller,
            reward,
            reward_oracle,
            emission_manager_data.rewards_controller
        );
    }

    public fun set_distribution_end(
        caller: &signer,
        asset: address,
        reward: address,
        new_distribution_end: u32
    ) acquires EmissionManagerData {
        check_is_emission_admin(reward);

        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());
        rewards_controller::set_distribution_end(
            caller,
            asset,
            reward,
            new_distribution_end,
            emission_manager_data.rewards_controller
        );
    }

    public fun set_emission_per_second(
        caller: &signer,
        asset: address,
        rewards: vector<address>,
        new_emissions_per_second: vector<u128>
    ) acquires EmissionManagerData {
        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());
        for (i in 0..vector::length(&rewards)) {
            assert!(
                *smart_table::borrow(
                    &emission_manager_data.emission_admins,
                    *vector::borrow(&rewards, i)
                ) == signer::address_of(caller),
                ONLY_EMISSION_ADMIN
            );
        };
        rewards_controller::set_emission_per_second(
            caller,
            asset,
            rewards,
            new_emissions_per_second,
            emission_manager_data.rewards_controller
        );
    }

    public fun set_claimer(
        account: &signer, user: address, claimer: address
    ) acquires EmissionManagerData {
        check_admin(signer::address_of(account));
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());
        rewards_controller::set_claimer(
            user, claimer, emission_manager_data.rewards_controller
        );
    }

    public fun set_emission_admin(
        account: &signer, reward: address, new_admin: address
    ) acquires EmissionManagerData {
        check_admin(signer::address_of(account));

        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());

        let old_admin =
            *smart_table::borrow_with_default(
                &emission_manager_data.emission_admins, reward, &new_admin
            );
        smart_table::upsert(
            &mut emission_manager_data.emission_admins, reward, new_admin
        );
        event::emit(EmissionAdminUpdated { reward, old_admin, new_admin });
    }

    public fun set_rewards_controller(
        account: &signer, controller: address
    ) acquires EmissionManagerData {
        check_admin(signer::address_of(account));
        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());
        emission_manager_data.rewards_controller = controller;
    }

    public fun get_rewards_controller(): address acquires EmissionManagerData {
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());
        emission_manager_data.rewards_controller
    }

    public fun get_emission_admin(reward: address): address acquires EmissionManagerData {
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());
        let emission_admin =
            smart_table::borrow(&emission_manager_data.emission_admins, reward);
        *emission_admin
    }
}
