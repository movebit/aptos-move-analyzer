
<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage"></a>

# Module `0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9::acl_manage`

@title ACLManager
@author Aave
@notice Access Control List Manager. Main registry of system roles and permissions.

Roles are referred to by their <code><a href="">vector</a>&lt;u8&gt;</code> identifier. These should be exposed
in the external API and be unique. The best way to achieve this is by
using <code><b>const</b></code> hash digests:
```
const MY_ROLE = b"MY_ROLE";
```
Roles can be used to represent a set of permissions. To restrict access to a
function call, use {has_role}:
```
public fun foo() {
assert!(has_role(MY_ROLE, error_code::ENOT_MANAGEMENT));
...
}
```
Roles can be granted and revoked dynamically via the {grant_role} and
{revoke_role} functions. Each role has an associated admin role, and only
accounts that have a role's admin role can call {grant_role} and {revoke_role}.

By default, the admin role for all roles is <code><a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_DEFAULT_ADMIN_ROLE">DEFAULT_ADMIN_ROLE</a></code>, which means
that only accounts with this role will be able to grant or revoke other
roles. More complex role relationships can be created by using
{set_role_admin}.

WARNING: The <code><a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_DEFAULT_ADMIN_ROLE">DEFAULT_ADMIN_ROLE</a></code> is also its own admin: it has permission to
grant and revoke this role. Extra precautions should be taken to secure
accounts that have been granted it.


-  [Struct `RoleAdminChanged`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleAdminChanged)
-  [Struct `RoleGranted`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleGranted)
-  [Struct `RoleRevoked`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleRevoked)
-  [Struct `RoleData`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleData)
-  [Resource `Roles`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_Roles)
-  [Constants](#@Constants_0)
-  [Function `grant_default_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_grant_default_admin_role)
-  [Function `default_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_default_admin_role)
-  [Function `get_role_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_role_admin)
-  [Function `set_role_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_set_role_admin)
-  [Function `has_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_has_role)
-  [Function `grant_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_grant_role)
-  [Function `renounce_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_renounce_role)
-  [Function `revoke_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_revoke_role)
-  [Function `add_pool_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_pool_admin)
-  [Function `remove_pool_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_pool_admin)
-  [Function `is_pool_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_pool_admin)
-  [Function `add_emergency_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_emergency_admin)
-  [Function `remove_emergency_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_emergency_admin)
-  [Function `is_emergency_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_emergency_admin)
-  [Function `add_risk_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_risk_admin)
-  [Function `remove_risk_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_risk_admin)
-  [Function `is_risk_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_risk_admin)
-  [Function `add_flash_borrower`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_flash_borrower)
-  [Function `remove_flash_borrower`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_flash_borrower)
-  [Function `is_flash_borrower`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_flash_borrower)
-  [Function `add_bridge`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_bridge)
-  [Function `remove_bridge`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_bridge)
-  [Function `is_bridge`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_bridge)
-  [Function `add_asset_listing_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_asset_listing_admin)
-  [Function `remove_asset_listing_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_asset_listing_admin)
-  [Function `is_asset_listing_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_asset_listing_admin)
-  [Function `add_funds_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_funds_admin)
-  [Function `remove_funds_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_funds_admin)
-  [Function `is_funds_admin`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_funds_admin)
-  [Function `add_emission_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_emission_admin_role)
-  [Function `remove_emission_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_emission_admin_role)
-  [Function `is_emission_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_emission_admin_role)
-  [Function `add_admin_controlled_ecosystem_reserve_funds_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `remove_admin_controlled_ecosystem_reserve_funds_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `is_admin_controlled_ecosystem_reserve_funds_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `add_rewards_controller_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_rewards_controller_admin_role)
-  [Function `remove_rewards_controller_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_rewards_controller_admin_role)
-  [Function `is_rewards_controller_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_rewards_controller_admin_role)
-  [Function `get_pool_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_pool_admin_role)
-  [Function `get_emergency_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_emergency_admin_role)
-  [Function `get_risk_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_risk_admin_role)
-  [Function `get_flash_borrower_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_flash_borrower_role)
-  [Function `get_bridge_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_bridge_role)
-  [Function `get_asset_listing_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_asset_listing_admin_role)
-  [Function `get_funds_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_funds_admin_role)
-  [Function `get_emission_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_emission_admin_role)
-  [Function `get_admin_controlled_ecosystem_reserve_funds_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_admin_controlled_ecosystem_reserve_funds_admin_role)
-  [Function `get_rewards_controller_admin_role`](#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_rewards_controller_admin_role)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::string</a>;
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleAdminChanged"></a>

## Struct `RoleAdminChanged`

@dev Emitted when <code>newAdminRole</code> is set as ```role```'s admin role, replacing <code>previousAdminRole</code>

<code><a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_DEFAULT_ADMIN_ROLE">DEFAULT_ADMIN_ROLE</a></code> is the starting admin for all roles, despite
{RoleAdminChanged} not being emitted signaling this.


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleAdminChanged">RoleAdminChanged</a> <b>has</b> drop, store
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleGranted"></a>

## Struct `RoleGranted`

@dev Emitted when <code><a href="">account</a></code> is granted <code>role</code>.

<code>sender</code> is the account that originated the contract call, an admin role


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleGranted">RoleGranted</a> <b>has</b> drop, store
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleRevoked"></a>

## Struct `RoleRevoked`

@dev Emitted when <code><a href="">account</a></code> is revoked <code>role</code>.

<code>sender</code> is the account that originated the contract call:
- if using <code>revoke_role</code>, it is the admin role bearer
- if using <code>renounce_role</code>, it is the role bearer (i.e. <code><a href="">account</a></code>)


<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleRevoked">RoleRevoked</a> <b>has</b> drop, store
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleData"></a>

## Struct `RoleData`



<pre><code><b>struct</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RoleData">RoleData</a> <b>has</b> store
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_Roles"></a>

## Resource `Roles`



<pre><code><b>struct</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_Roles">Roles</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE">ADMIN_CONTROLLED_ECOSYSTEM_RESERVE_FUNDS_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [65, 68, 77, 73, 78, 95, 67, 79, 78, 84, 82, 79, 76, 76, 69, 68, 95, 69, 67, 79, 83, 89, 83, 84, 69, 77, 95, 82, 69, 83, 69, 82, 86, 69, 95, 70, 85, 78, 68, 83, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_ASSET_LISTING_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_ASSET_LISTING_ADMIN_ROLE">ASSET_LISTING_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [65, 83, 83, 69, 84, 95, 76, 73, 83, 84, 73, 78, 71, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_BRIDGE_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_BRIDGE_ROLE">BRIDGE_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [66, 82, 73, 68, 71, 69];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_DEFAULT_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_DEFAULT_ADMIN_ROLE">DEFAULT_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [68, 69, 70, 65, 85, 76, 84, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EMERGENCY_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EMERGENCY_ADMIN_ROLE">EMERGENCY_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [69, 77, 69, 82, 71, 69, 78, 67, 89, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EMISSION_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EMISSION_ADMIN_ROLE">EMISSION_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [69, 77, 73, 83, 83, 73, 79, 78, 95, 65, 68, 77, 73, 78, 95, 82, 79, 76, 69];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_ENOT_MANAGEMENT"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_ENOT_MANAGEMENT">ENOT_MANAGEMENT</a>: u64 = 1;
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EROLE_CAN_ONLY_RENOUNCE_SELF"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EROLE_CAN_ONLY_RENOUNCE_SELF">EROLE_CAN_ONLY_RENOUNCE_SELF</a>: u64 = 4;
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EROLE_NOT_ADMIN"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EROLE_NOT_ADMIN">EROLE_NOT_ADMIN</a>: u64 = 3;
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EROLE_NOT_EXISTS"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_EROLE_NOT_EXISTS">EROLE_NOT_EXISTS</a>: u64 = 2;
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_FLASH_BORROWER_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_FLASH_BORROWER_ROLE">FLASH_BORROWER_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [70, 76, 65, 83, 72, 95, 66, 79, 82, 82, 79, 87, 69, 82];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_FUNDS_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_FUNDS_ADMIN_ROLE">FUNDS_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [70, 85, 78, 68, 83, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_POOL_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_POOL_ADMIN_ROLE">POOL_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [80, 79, 79, 76, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_REWARDS_CONTROLLER_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_REWARDS_CONTROLLER_ADMIN_ROLE">REWARDS_CONTROLLER_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [82, 69, 87, 65, 82, 68, 83, 95, 67, 79, 78, 84, 82, 79, 76, 76, 69, 82, 95, 65, 68, 77, 73, 78, 95, 82, 79, 76, 69];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RISK_ADMIN_ROLE"></a>



<pre><code><b>const</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_RISK_ADMIN_ROLE">RISK_ADMIN_ROLE</a>: <a href="">vector</a>&lt;u8&gt; = [82, 73, 83, 75, 95, 65, 68, 77, 73, 78];
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_grant_default_admin_role"></a>

## Function `grant_default_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_grant_default_admin_role">grant_default_admin_role</a>(admin: &<a href="">signer</a>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_default_admin_role"></a>

## Function `default_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_default_admin_role">default_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_role_admin"></a>

## Function `get_role_admin`

@dev Returns the admin role that controls <code>role</code>.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_role_admin">get_role_admin</a>(role: <a href="_String">string::String</a>): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_set_role_admin"></a>

## Function `set_role_admin`

@dev Sets <code>adminRole</code> as ```role```'s admin role.
Emits a {RoleAdminChanged} event.


<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_set_role_admin">set_role_admin</a>(admin: &<a href="">signer</a>, role: <a href="_String">string::String</a>, admin_role: <a href="_String">string::String</a>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_has_role"></a>

## Function `has_role`

@dev Returns <code><b>true</b></code> if <code><a href="">account</a></code> has been granted <code>role</code>.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_has_role">has_role</a>(role: <a href="_String">string::String</a>, user: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_grant_role"></a>

## Function `grant_role`

@dev Grants <code>role</code> to <code><a href="">account</a></code>.

If <code><a href="">account</a></code> had not been already granted <code>role</code>, emits a {RoleGranted}
event.

Requirements:

- the caller must have ```role```'s admin role.


<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_grant_role">grant_role</a>(admin: &<a href="">signer</a>, role: <a href="_String">string::String</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_renounce_role"></a>

## Function `renounce_role`

@dev Revokes <code>role</code> from the calling account.
Roles are often managed via {grant_role} and {revoke_role}: this function's
purpose is to provide a mechanism for accounts to lose their privileges
if they are compromised (such as when a trusted device is misplaced).

If the calling account had been granted <code>role</code>, emits a {role_revoked}
event.

Requirements:

- the caller must be <code><a href="">account</a></code>.


<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_renounce_role">renounce_role</a>(admin: &<a href="">signer</a>, role: <a href="_String">string::String</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_revoke_role"></a>

## Function `revoke_role`

@dev Revokes <code>role</code> from <code><a href="">account</a></code>.

If <code><a href="">account</a></code> had been granted <code>role</code>, emits a {RoleRevoked} event.

Requirements:

- the caller must have ```role```'s admin role.


<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_revoke_role">revoke_role</a>(admin: &<a href="">signer</a>, role: <a href="_String">string::String</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_pool_admin"></a>

## Function `add_pool_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_pool_admin">add_pool_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_pool_admin"></a>

## Function `remove_pool_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_pool_admin">remove_pool_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_pool_admin"></a>

## Function `is_pool_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_pool_admin">is_pool_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_emergency_admin"></a>

## Function `add_emergency_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_emergency_admin">add_emergency_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_emergency_admin"></a>

## Function `remove_emergency_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_emergency_admin">remove_emergency_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_emergency_admin"></a>

## Function `is_emergency_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_emergency_admin">is_emergency_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_risk_admin"></a>

## Function `add_risk_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_risk_admin">add_risk_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_risk_admin"></a>

## Function `remove_risk_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_risk_admin">remove_risk_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_risk_admin"></a>

## Function `is_risk_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_risk_admin">is_risk_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_flash_borrower"></a>

## Function `add_flash_borrower`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_flash_borrower">add_flash_borrower</a>(admin: &<a href="">signer</a>, borrower: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_flash_borrower"></a>

## Function `remove_flash_borrower`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_flash_borrower">remove_flash_borrower</a>(admin: &<a href="">signer</a>, borrower: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_flash_borrower"></a>

## Function `is_flash_borrower`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_flash_borrower">is_flash_borrower</a>(borrower: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_bridge"></a>

## Function `add_bridge`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_bridge">add_bridge</a>(admin: &<a href="">signer</a>, bridge: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_bridge"></a>

## Function `remove_bridge`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_bridge">remove_bridge</a>(admin: &<a href="">signer</a>, bridge: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_bridge"></a>

## Function `is_bridge`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_bridge">is_bridge</a>(bridge: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_asset_listing_admin"></a>

## Function `add_asset_listing_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_asset_listing_admin">add_asset_listing_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_asset_listing_admin"></a>

## Function `remove_asset_listing_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_asset_listing_admin">remove_asset_listing_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_asset_listing_admin"></a>

## Function `is_asset_listing_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_asset_listing_admin">is_asset_listing_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_funds_admin"></a>

## Function `add_funds_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_funds_admin">add_funds_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_funds_admin"></a>

## Function `remove_funds_admin`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_funds_admin">remove_funds_admin</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_funds_admin"></a>

## Function `is_funds_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_funds_admin">is_funds_admin</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_emission_admin_role"></a>

## Function `add_emission_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_emission_admin_role">add_emission_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_emission_admin_role"></a>

## Function `remove_emission_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_emission_admin_role">remove_emission_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_emission_admin_role"></a>

## Function `is_emission_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_emission_admin_role">is_emission_admin_role</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `add_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_admin_controlled_ecosystem_reserve_funds_admin_role">add_admin_controlled_ecosystem_reserve_funds_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `remove_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_admin_controlled_ecosystem_reserve_funds_admin_role">remove_admin_controlled_ecosystem_reserve_funds_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `is_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_admin_controlled_ecosystem_reserve_funds_admin_role">is_admin_controlled_ecosystem_reserve_funds_admin_role</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_rewards_controller_admin_role"></a>

## Function `add_rewards_controller_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_add_rewards_controller_admin_role">add_rewards_controller_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_rewards_controller_admin_role"></a>

## Function `remove_rewards_controller_admin_role`



<pre><code><b>public</b> entry <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_remove_rewards_controller_admin_role">remove_rewards_controller_admin_role</a>(admin: &<a href="">signer</a>, user: <b>address</b>)
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_rewards_controller_admin_role"></a>

## Function `is_rewards_controller_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_is_rewards_controller_admin_role">is_rewards_controller_admin_role</a>(admin: <b>address</b>): bool
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_pool_admin_role"></a>

## Function `get_pool_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_pool_admin_role">get_pool_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_emergency_admin_role"></a>

## Function `get_emergency_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_emergency_admin_role">get_emergency_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_risk_admin_role"></a>

## Function `get_risk_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_risk_admin_role">get_risk_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_flash_borrower_role"></a>

## Function `get_flash_borrower_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_flash_borrower_role">get_flash_borrower_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_bridge_role"></a>

## Function `get_bridge_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_bridge_role">get_bridge_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_asset_listing_admin_role"></a>

## Function `get_asset_listing_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_asset_listing_admin_role">get_asset_listing_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_funds_admin_role"></a>

## Function `get_funds_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_funds_admin_role">get_funds_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_emission_admin_role"></a>

## Function `get_emission_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_emission_admin_role">get_emission_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_admin_controlled_ecosystem_reserve_funds_admin_role"></a>

## Function `get_admin_controlled_ecosystem_reserve_funds_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_admin_controlled_ecosystem_reserve_funds_admin_role">get_admin_controlled_ecosystem_reserve_funds_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>



<a id="0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_rewards_controller_admin_role"></a>

## Function `get_rewards_controller_admin_role`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="acl_manage.md#0xd329b8b371bf56fdbfbb66f441a8463f3605ecb27ee0c484f85a4cf88883d2f9_acl_manage_get_rewards_controller_admin_role">get_rewards_controller_admin_role</a>(): <a href="_String">string::String</a>
</code></pre>
