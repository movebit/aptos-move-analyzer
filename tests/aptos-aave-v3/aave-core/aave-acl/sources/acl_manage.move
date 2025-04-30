/// @title ACLManager
/// @author Aave
/// @notice Access Control List Manager. Main registry of system roles and permissions.
///
/// Roles are referred to by their `vector<u8>` identifier. These should be exposed
/// in the external API and be unique. The best way to achieve this is by
/// using `const` hash digests:
/// ```
/// const MY_ROLE = b"MY_ROLE";
/// ```
/// Roles can be used to represent a set of permissions. To restrict access to a
/// function call, use {has_role}:
/// ```
/// public fun foo() {
///     assert!(has_role(MY_ROLE, error_code::ENOT_MANAGEMENT));
///     ...
/// }
/// ```
/// Roles can be granted and revoked dynamically via the {grant_role} and
/// {revoke_role} functions. Each role has an associated admin role, and only
/// accounts that have a role's admin role can call {grant_role} and {revoke_role}.
///
/// By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
/// that only accounts with this role will be able to grant or revoke other
/// roles. More complex role relationships can be created by using
/// {set_role_admin}.
///
/// WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
/// grant and revoke this role. Extra precautions should be taken to secure
/// accounts that have been granted it.
module aave_acl::acl_manage {
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;

    use aave_config::error_config;

    const DEFAULT_ADMIN_ROLE: vector<u8> = b"";
    const POOL_ADMIN_ROLE: vector<u8> = b"POOL_ADMIN";
    const EMERGENCY_ADMIN_ROLE: vector<u8> = b"EMERGENCY_ADMIN";
    const RISK_ADMIN_ROLE: vector<u8> = b"RISK_ADMIN";
    const FLASH_BORROWER_ROLE: vector<u8> = b"FLASH_BORROWER";
    const BRIDGE_ROLE: vector<u8> = b"BRIDGE";
    const ASSET_LISTING_ADMIN_ROLE: vector<u8> = b"ASSET_LISTING_ADMIN";
    const FUNDS_ADMIN_ROLE: vector<u8> = b"FUNDS_ADMIN";
    const EMISSION_ADMIN_ROLE: vector<u8> = b"EMISSION_ADMIN_ROLE";
    const ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE: vector<u8> = b"ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN";
    const REWARDS_CONTROLLER_ADMIN_ROLE: vector<u8> = b"REWARDS_CONTROLLER_ADMIN_ROLE";

    #[event]
    /// @dev Emitted when `new_admin_role` is set as ``role``'s admin role, replacing `previous_admin_role`
    ///
    /// `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
    /// {RoleAdminChanged} not being emitted signaling this.
    struct RoleAdminChanged has store, drop {
        role: String,
        previous_admin_role: String,
        new_admin_role: String
    }

    #[event]
    /// @dev Emitted when `account` is granted `role`.
    ///
    /// `sender` is the account that originated the contract call, an admin role
    struct RoleGranted has store, drop {
        role: String,
        account: address,
        sender: address
    }

    #[event]
    /// @dev Emitted when `account` is revoked `role`.
    ///
    /// `sender` is the account that originated the contract call:
    ///   - if using `revoke_role`, it is the admin role bearer
    ///   - if using `renounce_role`, it is the role bearer (i.e. `account`)
    struct RoleRevoked has store, drop {
        role: String,
        account: address,
        sender: address
    }

    struct RoleData has store {
        members: SmartTable<address, bool>,
        admin_role: String
    }

    struct Roles has key {
        acl_instance: SmartTable<String, RoleData>
    }

    #[test_only]
    public fun test_init_module(admin: &signer) acquires Roles {
        init_module(admin);
        grant_default_admin_role(admin);
    }

    fun init_module(admin: &signer) {
        let admin_address = signer::address_of(admin);
        check_super_admin(admin_address);
        move_to(
            admin,
            Roles {
                acl_instance: smart_table::new<String, RoleData>()
            }
        );
    }

    public entry fun grant_default_admin_role(admin: &signer) acquires Roles {
        let admin_address = signer::address_of(admin);
        check_super_admin(admin_address);
        grant_role_internal(admin, default_admin_role(), admin_address);
    }

    fun check_super_admin(admin: address) {
        assert!(admin == @aave_acl, error_config::get_enot_acl_owner());
    }

    fun only_role(role: String, user: address) acquires Roles {
        assert!(has_role(role, user), error_config::get_erole_missmatch());
    }

    #[view]
    public fun default_admin_role(): String {
        string::utf8(DEFAULT_ADMIN_ROLE)
    }

    #[view]
    /// @dev Returns the admin role that controls `role`.
    public fun get_role_admin(role: String): String acquires Roles {
        let roles = borrow_global<Roles>(@aave_acl);
        if (!smart_table::contains(&roles.acl_instance, role)) {
            return string::utf8(b"")
        };

        smart_table::borrow(&roles.acl_instance, role).admin_role
    }

    /// @dev Sets `admin_role` as ``role``'s admin role.
    /// Emits a {RoleAdminChanged} event.
    public entry fun set_role_admin(
        admin: &signer, role: String, admin_role: String
    ) acquires Roles {
        only_role(default_admin_role(), signer::address_of(admin));

        let previous_admin_role = get_role_admin(role);
        let roles = borrow_global_mut<Roles>(@aave_acl);

        if (!smart_table::contains(&mut roles.acl_instance, role)) {
            let members = smart_table::new<address, bool>();
            let role_data = RoleData { members, admin_role };
            smart_table::add(&mut roles.acl_instance, role, role_data);
        } else {
            let role_data = smart_table::borrow_mut(&mut roles.acl_instance, role);
            role_data.admin_role = admin_role;
        };

        event::emit(
            RoleAdminChanged { role, previous_admin_role, new_admin_role: admin_role }
        );
    }

    #[view]
    /// @dev Returns `true` if `user` has been granted `role`.
    /// @param role The role identifier
    /// @param user The account to check
    public fun has_role(role: String, user: address): bool acquires Roles {
        let role_res = borrow_global<Roles>(@aave_acl);
        if (!smart_table::contains(&role_res.acl_instance, role)) {
            return false
        };
        let role_data = smart_table::borrow(&role_res.acl_instance, role);
        if (!smart_table::contains(&role_data.members, user)) {
            return false
        };

        *smart_table::borrow(&role_data.members, user)
    }

    /// @dev Grants `role` to `account`.
    ///
    /// If `account` had not been already granted `role`, emits a {RoleGranted}
    /// event.
    ///
    /// Requirements:
    ///
    /// - the caller must have ``role``'s admin role.
    public entry fun grant_role(
        admin: &signer, role: String, user: address
    ) acquires Roles {
        let admin_address = signer::address_of(admin);
        only_role(get_role_admin(role), admin_address);
        grant_role_internal(admin, role, user);
    }

    fun grant_role_internal(admin: &signer, role: String, user: address) acquires Roles {
        if (!has_role(role, user)) {
            let role_res = borrow_global_mut<Roles>(@aave_acl);
            if (!smart_table::contains(&role_res.acl_instance, role)) {
                let members = smart_table::new<address, bool>();
                smart_table::add(&mut members, user, true);
                let role_data = RoleData { members, admin_role: string::utf8(b"") };
                smart_table::add(&mut role_res.acl_instance, role, role_data);
            } else {
                let role_data = smart_table::borrow_mut(&mut role_res.acl_instance, role);
                smart_table::upsert(&mut role_data.members, user, true);
            };

            event::emit(
                RoleGranted { role, account: user, sender: signer::address_of(admin) }
            );
        }
    }

    /// @dev Revokes `role` from the calling account.
    /// Roles are often managed via {grant_role} and {revoke_role}: this function's
    /// purpose is to provide a mechanism for accounts to lose their privileges
    /// if they are compromised (such as when a trusted device is misplaced).
    ///
    /// If the calling account had been granted `role`, emits a {role_revoked}
    /// event.
    ///
    /// Requirements:
    ///
    /// - the caller must be `account`.
    public entry fun renounce_role(
        admin: &signer, role: String, user: address
    ) acquires Roles {
        assert!(
            signer::address_of(admin) == user,
            error_config::get_erole_can_only_renounce_self()
        );
        revoke_role_internal(admin, role, user);
    }

    /// @dev Revokes `role` from `account`.
    ///
    /// If `account` had been granted `role`, emits a {RoleRevoked} event.
    ///
    /// Requirements:
    ///
    /// - the caller must have ``role``'s admin role.
    ///
    public entry fun revoke_role(
        admin: &signer, role: String, user: address
    ) acquires Roles {
        let admin_address = signer::address_of(admin);
        only_role(get_role_admin(role), admin_address);
        revoke_role_internal(admin, role, user);
    }

    fun revoke_role_internal(admin: &signer, role: String, user: address) acquires Roles {
        if (has_role(role, user)) {
            let role_res = borrow_global_mut<Roles>(@aave_acl);
            let role_data = smart_table::borrow_mut(&mut role_res.acl_instance, role);
            smart_table::upsert(&mut role_data.members, user, false);

            event::emit(
                RoleRevoked { role, account: user, sender: signer::address_of(admin) }
            );
        }
    }

    public entry fun add_pool_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_pool_admin_role(), user);
    }

    public entry fun remove_pool_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_pool_admin_role(), user);
    }

    #[view]
    public fun is_pool_admin(admin: address): bool acquires Roles {
        has_role(get_pool_admin_role(), admin)
    }

    public entry fun add_emergency_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_emergency_admin_role(), user);
    }

    public entry fun remove_emergency_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_emergency_admin_role(), user);
    }

    #[view]
    public fun is_emergency_admin(admin: address): bool acquires Roles {
        has_role(get_emergency_admin_role(), admin)
    }

    public entry fun add_risk_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_risk_admin_role(), user);
    }

    public entry fun remove_risk_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_risk_admin_role(), user);
    }

    #[view]
    public fun is_risk_admin(admin: address): bool acquires Roles {
        has_role(get_risk_admin_role(), admin)
    }

    public entry fun add_flash_borrower(admin: &signer, borrower: address) acquires Roles {
        grant_role(admin, get_flash_borrower_role(), borrower);
    }

    public entry fun remove_flash_borrower(
        admin: &signer, borrower: address
    ) acquires Roles {
        revoke_role(admin, get_flash_borrower_role(), borrower);
    }

    #[view]
    public fun is_flash_borrower(borrower: address): bool acquires Roles {
        has_role(get_flash_borrower_role(), borrower)
    }

    public entry fun add_bridge(admin: &signer, bridge: address) acquires Roles {
        grant_role(admin, get_bridge_role(), bridge);
    }

    public entry fun remove_bridge(admin: &signer, bridge: address) acquires Roles {
        revoke_role(admin, get_bridge_role(), bridge);
    }

    #[view]
    public fun is_bridge(bridge: address): bool acquires Roles {
        has_role(get_bridge_role(), bridge)
    }

    public entry fun add_asset_listing_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_asset_listing_admin_role(), user);
    }

    public entry fun remove_asset_listing_admin(
        admin: &signer, user: address
    ) acquires Roles {
        revoke_role(admin, get_asset_listing_admin_role(), user);
    }

    #[view]
    public fun is_asset_listing_admin(admin: address): bool acquires Roles {
        has_role(get_asset_listing_admin_role(), admin)
    }

    public entry fun add_funds_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_funds_admin_role(), user);
    }

    public entry fun remove_funds_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_funds_admin_role(), user);
    }

    #[view]
    public fun is_funds_admin(admin: address): bool acquires Roles {
        has_role(get_funds_admin_role(), admin)
    }

    public entry fun add_emission_admin(admin: &signer, user: address) acquires Roles {
        grant_role(admin, get_emission_admin_role(), user);
    }

    public entry fun remove_emission_admin(admin: &signer, user: address) acquires Roles {
        revoke_role(admin, get_emission_admin_role(), user);
    }

    #[view]
    public fun is_emission_admin(admin: address): bool acquires Roles {
        has_role(get_emission_admin_role(), admin)
    }

    public entry fun add_admin_controlled_ecosystem_reserve_funds_admin(
        admin: &signer, user: address
    ) acquires Roles {
        grant_role(
            admin, get_admin_controlled_ecosystem_reserve_funds_admin_role(), user
        );
    }

    public entry fun remove_admin_controlled_ecosystem_reserve_funds_admin(
        admin: &signer, user: address
    ) acquires Roles {
        revoke_role(
            admin, get_admin_controlled_ecosystem_reserve_funds_admin_role(), user
        );
    }

    #[view]
    public fun is_admin_controlled_ecosystem_reserve_funds_admin(
        admin: address
    ): bool acquires Roles {
        has_role(get_admin_controlled_ecosystem_reserve_funds_admin_role(), admin)
    }

    public entry fun add_rewards_controller_admin(
        admin: &signer, user: address
    ) acquires Roles {
        grant_role(admin, get_rewards_controller_admin_role(), user);
    }

    public entry fun remove_rewards_controller_admin(
        admin: &signer, user: address
    ) acquires Roles {
        revoke_role(admin, get_rewards_controller_admin_role(), user);
    }

    #[view]
    public fun is_rewards_controller_admin(admin: address): bool acquires Roles {
        has_role(get_rewards_controller_admin_role(), admin)
    }

    #[view]
    public fun get_pool_admin_role(): String {
        string::utf8(POOL_ADMIN_ROLE)
    }

    #[view]
    public fun get_emergency_admin_role(): String {
        string::utf8(EMERGENCY_ADMIN_ROLE)
    }

    #[view]
    public fun get_risk_admin_role(): String {
        string::utf8(RISK_ADMIN_ROLE)
    }

    #[view]
    public fun get_flash_borrower_role(): String {
        string::utf8(FLASH_BORROWER_ROLE)
    }

    #[view]
    public fun get_bridge_role(): String {
        string::utf8(BRIDGE_ROLE)
    }

    #[view]
    public fun get_asset_listing_admin_role(): String {
        string::utf8(ASSET_LISTING_ADMIN_ROLE)
    }

    #[view]
    public fun get_funds_admin_role(): String {
        string::utf8(FUNDS_ADMIN_ROLE)
    }

    #[view]
    public fun get_emission_admin_role(): String {
        string::utf8(EMISSION_ADMIN_ROLE)
    }

    #[view]
    public fun get_admin_controlled_ecosystem_reserve_funds_admin_role(): String {
        string::utf8(ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE)
    }

    #[view]
    public fun get_rewards_controller_admin_role(): String {
        string::utf8(REWARDS_CONTROLLER_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_pool_admin_role_for_testing(): String {
        string::utf8(POOL_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_emergency_admin_role_for_testing(): String {
        string::utf8(EMERGENCY_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_risk_admin_role_for_testing(): String {
        string::utf8(RISK_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_flash_borrower_role_for_testing(): String {
        string::utf8(FLASH_BORROWER_ROLE)
    }

    #[test_only]
    public fun get_bridge_role_for_testing(): String {
        string::utf8(BRIDGE_ROLE)
    }

    #[test_only]
    public fun get_asset_listing_admin_role_for_testing(): String {
        string::utf8(ASSET_LISTING_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_funds_admin_role_for_testing(): String {
        string::utf8(FUNDS_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_emissions_admin_role_for_testing(): String {
        string::utf8(EMISSION_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_admin_controlled_ecosystem_reserve_funds_admin_role_for_testing(): String {
        string::utf8(ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE)
    }

    #[test_only]
    public fun get_rewards_controller_admin_role_for_testing(): String {
        string::utf8(REWARDS_CONTROLLER_ADMIN_ROLE)
    }
}
