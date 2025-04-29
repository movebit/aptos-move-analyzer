module aave_pool::a_token_factory {
    use std::option;
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_std::string_utils::format2;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::event::Self;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self, Object};

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_math::wad_ray_math;

    use aave_pool::fungible_asset_manager;
    use aave_pool::token_base;

    friend aave_pool::pool;
    friend aave_pool::flashloan_logic;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::bridge_logic;
    friend aave_pool::liquidation_logic;

    #[test_only]
    friend aave_pool::a_token_factory_tests;
    #[test_only]
    friend aave_pool::pool_configurator_tests;
    #[test_only]
    friend aave_pool::ui_incentive_data_provider_v3;
    #[test_only]
    friend aave_pool::ui_pool_data_provider_v3;
    // #[test_only]
    // friend aave_pool::emission_manager_tests;
    // #[test_only]
    // friend aave_pool::rewards_controller_tests;

    const ATOKEN_REVISION: u256 = 0x1;

    #[event]
    /// @dev Emitted when an aToken is initialized
    /// @param underlying_asset The address of the underlying asset
    /// @param treasury The address of the treasury
    /// @param a_token_decimals The decimals of the underlying
    /// @param a_token_name The name of the aToken
    /// @param a_token_symbol The symbol of the aToken
    struct Initialized has store, drop {
        underlying_asset: address,
        treasury: address,
        a_token_decimals: u8,
        a_token_name: String,
        a_token_symbol: String
    }

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

    struct TokenData has store, drop {
        underlying_asset: address,
        treasury: address,
        signer_cap: SignerCapability
    }

    // Atoken metadata_address => TokenData
    struct TokenMap has key {
        value: SmartTable<address, TokenData>,
        count: u256
    }

    fun init_module(signer: &signer) {
        token_base::only_token_admin(signer);
        move_to(
            signer,
            TokenMap {
                value: smart_table::new<address, TokenData>(),
                count: 0
            }
        )
    }

    fun assert_token_exists(metadata_address: address) acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        assert!(
            smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_not_exist()
        );
    }

    //
    // Entry Functions
    //
    /// @notice Creates a new aToken
    /// @dev Only callable by the pool module
    /// @param signer The signer of the caller
    /// @param name The name of the aToken
    /// @param symbol The symbol of the aToken
    /// @param decimals The decimals of the aToken
    /// @param icon_uri The icon URI of the aToken
    /// @param project_uri The project URI of the aToken
    /// @param underlying_asset The address of the underlying asset
    /// @param treasury The address of the treasury
    /// @return The address of the aToken
    public(friend) fun create_token(
        signer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        underlying_asset: address,
        treasury: address
    ): address acquires TokenMap {
        only_asset_listing_or_pool_admins(signer);

        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        validate_unique_token(token_map, name, symbol);

        let token_count = token_map.count + 1;
        let seed = *string::bytes(&format2(&b"{}_{}", symbol, token_count));
        let user_signer_addr = signer::address_of(signer);
        let metadata_address = object::create_object_address(&user_signer_addr, seed);

        assert!(
            !smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_already_exists()
        );

        let (_resource_signer, signer_cap) =
            account::create_resource_account(signer, seed);

        let token_data = TokenData { underlying_asset, treasury, signer_cap };
        smart_table::add(&mut token_map.value, metadata_address, token_data);

        let constructor_ref = &object::create_named_object(signer, seed);
        token_base::create_token(
            constructor_ref,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );

        token_map.count = token_count;

        event::emit(
            Initialized {
                underlying_asset,
                treasury,
                a_token_decimals: decimals,
                a_token_name: name,
                a_token_symbol: symbol
            }
        );

        metadata_address
    }

    /// @notice Rescue and transfer tokens locked in this contract
    /// @param account The account signer of the caller
    /// @param token The address of the underlying token
    /// @param to The address of the recipient
    /// @param amount The amount of token to transfer
    /// @param meadata_address The address of the aToken
    public entry fun rescue_tokens(
        account: &signer,
        token: address,
        to: address,
        amount: u256,
        metadata_address: address
    ) acquires TokenMap {
        token_base::only_pool_admin(account);
        assert_token_exists(metadata_address);

        assert!(
            token != get_underlying_asset_address(metadata_address),
            error_config::get_eunderlying_cannot_be_rescued()
        );

        let a_token_resource_account = get_token_account_with_signer(metadata_address);
        fungible_asset_manager::transfer(
            &a_token_resource_account,
            to,
            (amount as u64),
            token
        );
    }

    //
    //  Functions Call between contracts
    //

    /// @notice Mints `amount` aTokens to `on_behalf_of`
    /// @dev Only callable by the bridge_logic and supply_logic module
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted aTokens
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun mint(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::mint_scaled(
            caller,
            on_behalf_of,
            amount,
            index,
            metadata_address
        );
    }

    /// @notice Burns aTokens from `from` and sends the equivalent amount of underlying to `receiver_of_underlying`
    /// @dev Only callable by the supply_logic, borrow_logic and liquidation_logic module
    /// @dev In some instances, the mint event could be emitted from a burn transaction
    /// if the amount to burn is less than the interest that the user accrued
    /// @param from The address from which the aTokens will be burned
    /// @param receiver_of_underlying The address that will receive the underlying
    /// @param amount The amount being burned
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun burn(
        from: address,
        receiver_of_underlying: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);

        token_base::burn_scaled(
            from,
            receiver_of_underlying,
            amount,
            index,
            metadata_address
        );

        let a_token_resource_account = get_token_account_address(metadata_address);
        if (receiver_of_underlying != a_token_resource_account) {
            fungible_asset_manager::transfer(
                &get_token_account_with_signer(metadata_address),
                receiver_of_underlying,
                (amount as u64),
                get_underlying_asset_address(metadata_address)
            )
        }
    }

    /// @notice Mints aTokens to the reserve treasury
    /// @dev Only callable by the pool module
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun mint_to_treasury(
        amount: u256, index: u256, metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);
        if (amount != 0) {
            let token_data = get_token_data(metadata_address);
            token_base::mint_scaled(
                @aave_pool,
                token_data.treasury,
                amount,
                index,
                metadata_address
            )
        }
    }

    /// @notice Transfers the underlying asset to `to`.
    /// @dev Only callable by the borrow_logic and flashloan_logic module
    /// @param to The recipient of the underlying
    /// @param amount The amount getting transferred
    /// @param metadata_address The address of the aToken
    public(friend) fun transfer_underlying_to(
        to: address, amount: u256, metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);
        fungible_asset_manager::transfer(
            &get_token_account_with_signer(metadata_address),
            to,
            (amount as u64),
            get_underlying_asset_address(metadata_address)
        )
    }

    /// @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
    /// @dev Only callable by the liquidation_logic module
    /// @param from The address getting liquidated, current owner of the aTokens
    /// @param to The recipient
    /// @param amount The amount of tokens getting transferred
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun transfer_on_liquidation(
        from: address,
        to: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::transfer(from, to, amount, index, metadata_address);
        // send balance transfer event
        event::emit(
            BalanceTransfer { from, to, value: wad_ray_math::ray_div(amount, index), index }
        );
    }

    /// @notice Handles the underlying received by the aToken after the transfer has been completed.
    /// @dev The default implementation is empty, nothing needs to be done after the transfer is concluded.
    /// However in the future there may be aTokens that allow for example to stake the underlying
    /// to receive LM rewards. In that case, `handle_repayment()` would perform the staking of the underlying asset.
    /// @param _user The user executing the repayment
    /// @param _on_behalf_of The address of the user who will get his debt reduced/removed
    /// @param _amount The amount getting repaid
    /// @param _metadata_address The address of the aToken
    public fun handle_repayment(
        _user: address,
        _on_behalf_of: address,
        _amount: u256,
        _metadata_address: address
    ) {
        // Intentionally left blank
    }

    //
    //  View functions
    //

    inline fun get_token_data(metadata_address: address): &TokenData acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        assert!(
            smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_not_exist()
        );

        smart_table::borrow(&token_map.value, metadata_address)
    }

    #[view]
    public fun get_revision(): u256 {
        ATOKEN_REVISION
    }

    #[view]
    /// @notice Retrieves the account address of the managed fungible asset associated with a specific aToken.
    /// @dev Creates a signer capability for the resource account managing the fungible asset and then retrieves its address.
    /// @param metadata_address The address of the aToken
    /// @return The address of the managed fungible asset account.
    public fun get_token_account_address(metadata_address: address): address acquires TokenMap {
        let token_data = get_token_data(metadata_address);
        let account_signer =
            account::create_signer_with_capability(&token_data.signer_cap);
        signer::address_of(&account_signer)
    }

    /// @notice Retrieves the signer of the managed fungible asset associated with a specific aToken.
    /// @dev Creates a signer capability for the resource account that manages the fungible asset.
    /// @param metadata_address The address of the aToken.
    /// @return The signer of the managed fungible asset.
    fun get_token_account_with_signer(metadata_address: address): signer acquires TokenMap {
        let token_data = get_token_data(metadata_address);
        account::create_signer_with_capability(&token_data.signer_cap)
    }

    #[view]
    /// @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
    /// @param metadata_address The address of the aToken
    /// @return Address of the Aave treasury
    public fun get_reserve_treasury_address(metadata_address: address): address acquires TokenMap {
        let token_data = get_token_data(metadata_address);
        token_data.treasury
    }

    #[view]
    /// @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
    /// @param metadata_address The address of the aToken
    /// @return The address of the underlying asset
    public fun get_underlying_asset_address(metadata_address: address): address acquires TokenMap {
        let token_data = get_token_data(metadata_address);
        token_data.underlying_asset
    }

    #[view]
    /// @notice Returns last index interest was accrued to the user's balance
    /// @param user The address of the user
    /// @param metadata_address The address of the aToken
    /// @return The last index interest was accrued to the user's balance, expressed in ray
    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 {
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user and the scaled total supply.
    /// @param owner The address of the user
    /// @param metadata_address The address of the aToken
    /// @return The scaled balance of the user
    /// @return The scaled total supply
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) {
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user.
    /// @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
    /// at the moment of the update
    /// @param owner The user whose balance is calculated
    /// @param metadata_address The address of the aToken
    /// @return The scaled balance of the user
    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 {
        token_base::scaled_balance_of(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
    /// @param metadata_address The address of the aToken
    /// @return The scaled total supply
    public fun scaled_total_supply(metadata_address: address): u256 {
        token_base::scaled_total_supply(metadata_address)
    }

    #[view]
    public fun name(metadata_address: address): String {
        token_base::name(metadata_address)
    }

    #[view]
    public fun symbol(metadata_address: address): String {
        token_base::symbol(metadata_address)
    }

    #[view]
    public fun decimals(metadata_address: address): u8 {
        token_base::decimals(metadata_address)
    }

    /// @notice Validates that the aToken name and symbol are unique
    /// @param token_map The aToken map
    /// @param name The name of the aToken
    /// @param symbol The symbol of the aToken
    fun validate_unique_token(
        token_map: &TokenMap, name: String, symbol: String
    ) {
        smart_table::for_each_ref(
            &token_map.value,
            |metadata_address, _token_data| {
                let asset_name = name(*metadata_address);
                let asset_symbol = symbol(*metadata_address);
                assert!(
                    asset_name != name, error_config::get_etoken_name_already_exist()
                );
                assert!(
                    asset_symbol != symbol,
                    error_config::get_etoken_symbol_already_exist()
                );
            }
        );
    }

    /// @notice Drops the a token associated data
    /// @dev Only callable by the pool module
    /// @param metadata_address The address of the metadata object
    public(friend) fun drop_token(metadata_address: address) acquires TokenMap {
        assert_token_exists(metadata_address);
        // Remove metadata_address from token map
        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        smart_table::remove(&mut token_map.value, metadata_address);

        // Remove metadata_address from token_base module's token map
        token_base::drop_token(metadata_address);
    }

    fun only_asset_listing_or_pool_admins(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(
            acl_manage::is_asset_listing_admin(account_address)
                || acl_manage::is_pool_admin(account_address),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        )
    }

    #[view]
    public fun token_address(owner: address, symbol: String): address acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);

        let address_found = option::none<address>();
        smart_table::for_each_ref(
            &token_map.value,
            |metadata_address, _token_data| {
                let token_metadata =
                    object::address_to_object<Metadata>(*metadata_address);
                if (object::owner(token_metadata) == owner) {
                    let token_symbol = fungible_asset::symbol(token_metadata);
                    if (token_symbol == symbol) {
                        if (std::option::is_some(&address_found)) {
                            abort(error_config::get_etoken_already_exists())
                        };
                        std::option::fill(&mut address_found, *metadata_address);
                    };
                }
            }
        );

        if (std::option::is_none(&address_found)) {
            abort(error_config::get_etoken_not_exist())
        };
        std::option::destroy_some(address_found)
    }

    #[view]
    public fun asset_metadata(owner: address, symbol: String): Object<Metadata> acquires TokenMap {
        object::address_to_object<Metadata>(token_address(owner, symbol))
    }

    #[test_only]
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }
}
