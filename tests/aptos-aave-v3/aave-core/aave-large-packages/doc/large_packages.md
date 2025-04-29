
<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages"></a>

# Module `0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea::large_packages`

This provides a framework for uploading large packages to standard accounts or objects.
In each pass, the caller pushes more code by calling <code>stage_code_chunk</code>.
In the final call, the caller can use <code>stage_code_chunk_and_publish_to_account</code>, <code>stage_code_chunk_and_publish_to_object</code>, or
<code>stage_code_chunk_and_upgrade_object_code</code> to upload the final data chunk and publish or upgrade the package on-chain.

Note that <code>code_indices</code> must not have gaps. For example, if <code>code_indices</code> are provided as [0, 1, 3]
(skipping index 2), the inline function <code>assemble_module_code</code> will abort. This is because <code><a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_StagingArea">StagingArea</a>.last_module_idx</code>
is set to the maximum value from <code>code_indices</code>. When <code>assemble_module_code</code> iterates over the range from 0 to
<code><a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_StagingArea">StagingArea</a>.last_module_idx</code>, it expects each index to be present in the <code><a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_StagingArea">StagingArea</a>.<a href="">code</a></code> SmartTable.
Any missing index in this range will cause the function to fail.


-  [Resource `StagingArea`](#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_StagingArea)
-  [Constants](#@Constants_0)
-  [Function `stage_code_chunk`](#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk)
-  [Function `stage_code_chunk_and_publish_to_account`](#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_publish_to_account)
-  [Function `stage_code_chunk_and_publish_to_object`](#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_publish_to_object)
-  [Function `stage_code_chunk_and_upgrade_object_code`](#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_upgrade_object_code)
-  [Function `cleanup_staging_area`](#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_cleanup_staging_area)


<pre><code><b>use</b> <a href="">0x1::code</a>;
<b>use</b> <a href="">0x1::error</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::object_code_deployment</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_StagingArea"></a>

## Resource `StagingArea`



<pre><code><b>struct</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_StagingArea">StagingArea</a> <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_ECODE_MISMATCH"></a>

code_indices and code_chunks should be the same length.


<pre><code><b>const</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_ECODE_MISMATCH">ECODE_MISMATCH</a>: u64 = 1;
</code></pre>



<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_EMISSING_OBJECT_REFERENCE"></a>

Object reference should be provided when upgrading object code.


<pre><code><b>const</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_EMISSING_OBJECT_REFERENCE">EMISSING_OBJECT_REFERENCE</a>: u64 = 2;
</code></pre>



<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk"></a>

## Function `stage_code_chunk`



<pre><code><b>public</b> entry <b>fun</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk">stage_code_chunk</a>(owner: &<a href="">signer</a>, metadata_chunk: <a href="">vector</a>&lt;u8&gt;, code_indices: <a href="">vector</a>&lt;u16&gt;, code_chunks: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_publish_to_account"></a>

## Function `stage_code_chunk_and_publish_to_account`



<pre><code><b>public</b> entry <b>fun</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_publish_to_account">stage_code_chunk_and_publish_to_account</a>(owner: &<a href="">signer</a>, metadata_chunk: <a href="">vector</a>&lt;u8&gt;, code_indices: <a href="">vector</a>&lt;u16&gt;, code_chunks: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_publish_to_object"></a>

## Function `stage_code_chunk_and_publish_to_object`



<pre><code><b>public</b> entry <b>fun</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_publish_to_object">stage_code_chunk_and_publish_to_object</a>(owner: &<a href="">signer</a>, metadata_chunk: <a href="">vector</a>&lt;u8&gt;, code_indices: <a href="">vector</a>&lt;u16&gt;, code_chunks: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_upgrade_object_code"></a>

## Function `stage_code_chunk_and_upgrade_object_code`



<pre><code><b>public</b> entry <b>fun</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_stage_code_chunk_and_upgrade_object_code">stage_code_chunk_and_upgrade_object_code</a>(owner: &<a href="">signer</a>, metadata_chunk: <a href="">vector</a>&lt;u8&gt;, code_indices: <a href="">vector</a>&lt;u16&gt;, code_chunks: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;, code_object: <a href="_Option">option::Option</a>&lt;<a href="_Object">object::Object</a>&lt;<a href="_PackageRegistry">code::PackageRegistry</a>&gt;&gt;)
</code></pre>



<a id="0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_cleanup_staging_area"></a>

## Function `cleanup_staging_area`



<pre><code><b>public</b> entry <b>fun</b> <a href="large_packages.md#0x7ec90154fa3c01e400effb2c4f73223b8cbe3af63a087cceca7a381c8818c4ea_large_packages_cleanup_staging_area">cleanup_staging_area</a>(owner: &<a href="">signer</a>)
</code></pre>
