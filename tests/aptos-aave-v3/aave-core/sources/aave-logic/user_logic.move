module aave_pool::user_logic {

    use std::signer;
    use aptos_framework::event;

    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::generic_logic;
    use aave_pool::pool;
    use aave_pool::supply_logic;
    use aave_pool::token_base;

    #[event]
    /// @dev Emitted during the transfer action
    /// @param from The user whose tokens are being transferred
    /// @param to The recipient
    /// @param value The scaled amount being transferred
    /// @param index The next liquidity index of the reserve
    struct BalanceTransfer has store, drop {
        from: address,
        to: address,
        value: u256,
        index: u256
    }

    /// @notice Transfers aTokens from the user to the recipient
    /// @param account The account signer of the caller
    /// @param to The recipient of the aTokens
    /// @param amount The amount of aTokens to transfer
    /// @param a_token_address The address of the aToken
    public entry fun transfer_a_token(
        account: &signer,
        to: address,
        amount: u256,
        a_token_address: address
    ) {
        let account_address = signer::address_of(account);

        let underlying_asset =
            a_token_factory::get_underlying_asset_address(a_token_address);
        let index = pool::get_reserve_normalized_income(underlying_asset);
        let from_balance_before =
            wad_ray_math::ray_mul(
                a_token_factory::scaled_balance_of(account_address, a_token_address),
                index
            );
        let to_balance_before =
            wad_ray_math::ray_mul(
                a_token_factory::scaled_balance_of(to, a_token_address),
                index
            );
        token_base::transfer(
            account_address,
            to,
            amount,
            index,
            a_token_address
        );

        // finalize transfer validate
        supply_logic::finalize_transfer(
            account,
            underlying_asset,
            account_address,
            to,
            amount,
            from_balance_before,
            to_balance_before
        );

        // send balance transfer event
        event::emit(
            BalanceTransfer {
                from: account_address,
                to,
                value: wad_ray_math::ray_div(amount, index),
                index
            }
        );
    }

    #[view]
    /// @notice Returns the user account data across all the reserves
    /// @param user The address of the user
    /// @return total_collateral_base The total collateral of the user in the base currency used by the price feed
    /// @return total_debt_base The total debt of the user in the base currency used by the price feed
    /// @return available_borrows_base The borrowing power left of the user in the base currency used by the price feed
    /// @return current_liquidation_threshold The liquidation threshold of the user
    /// @return ltv The loan to value of The user
    /// @return health_factor The current health factor of the user
    public fun get_user_account_data(user: address): (u256, u256, u256, u256, u256, u256) {
        let user_config_map = pool::get_user_configuration(user);
        let reserves_count = pool::get_reserves_count();
        let user_emode_category = (emode_logic::get_user_emode(user) as u8);
        let (emode_ltv, emode_liq_threshold, emode_asset_price) =
            emode_logic::get_emode_configuration(user_emode_category);
        let (
            total_collateral_base,
            total_debt_base,
            ltv,
            current_liquidation_threshold,
            health_factor,
            _
        ) =
            generic_logic::calculate_user_account_data(
                &user_config_map,
                reserves_count,
                user,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price
            );

        let available_borrows_base =
            generic_logic::calculate_available_borrows(
                total_collateral_base, total_debt_base, ltv
            );

        (
            total_collateral_base,
            total_debt_base,
            available_borrows_base,
            current_liquidation_threshold,
            ltv,
            health_factor
        )
    }
}
