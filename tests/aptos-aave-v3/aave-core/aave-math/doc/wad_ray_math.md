
<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math"></a>

# Module `0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math`

@title WadRayMath library
@author Aave
@notice Provides functions to perform calculations with Wad and Ray units
@dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
with 27 digits of precision)
@dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.


-  [Constants](#@Constants_0)
-  [Function `wad`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad)
-  [Function `half_wad`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_half_wad)
-  [Function `ray`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray)
-  [Function `half_ray`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_half_ray)
-  [Function `wad_mul`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_mul)
-  [Function `wad_div`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_div)
-  [Function `ray_mul`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_mul)
-  [Function `ray_div`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_div)
-  [Function `ray_to_wad`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_to_wad)
-  [Function `wad_to_ray`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_to_ray)


<pre><code></code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_EDIVISION_BY_ZERO"></a>

Cannot divide by 0


<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_EDIVISION_BY_ZERO">EDIVISION_BY_ZERO</a>: u64 = 2;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_EOVERFLOW"></a>

Overflow resulting from a calculation


<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_EOVERFLOW">EOVERFLOW</a>: u64 = 1;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_HALF_RAY"></a>



<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_HALF_RAY">HALF_RAY</a>: u256 = 500000000000000000000000000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_HALF_WAD"></a>



<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_HALF_WAD">HALF_WAD</a>: u256 = 500000000000000000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_RAY"></a>



<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_RAY">RAY</a>: u256 = 1000000000000000000000000000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_U256_MAX"></a>



<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_U256_MAX">U256_MAX</a>: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_WAD"></a>



<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_WAD">WAD</a>: u256 = 1000000000000000000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_WAD_RAY_RATIO"></a>



<pre><code><b>const</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_WAD_RAY_RATIO">WAD_RAY_RATIO</a>: u256 = 1000000000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad"></a>

## Function `wad`



<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad">wad</a>(): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_half_wad"></a>

## Function `half_wad`



<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_half_wad">half_wad</a>(): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray"></a>

## Function `ray`



<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray">ray</a>(): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_half_ray"></a>

## Function `half_ray`



<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_half_ray">half_ray</a>(): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_mul"></a>

## Function `wad_mul`

@dev Multiplies two wad, rounding half up to the nearest wad
@param a Wad
@param b Wad
@return c = a*b, in wad


<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_mul">wad_mul</a>(a: u256, b: u256): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_div"></a>

## Function `wad_div`

@dev Divides two wad, rounding half up to the nearest wad
@param a Wad
@param b Wad
@return c = a/b, in wad


<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_div">wad_div</a>(a: u256, b: u256): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_mul"></a>

## Function `ray_mul`

@notice Multiplies two ray, rounding half up to the nearest ray
@param a Ray
@param b Ray
@return c = a raymul b


<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_mul">ray_mul</a>(a: u256, b: u256): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_div"></a>

## Function `ray_div`

@notice Divides two ray, rounding half up to the nearest ray
@param a Ray
@param b Ray
@return c = a raydiv b


<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_div">ray_div</a>(a: u256, b: u256): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_to_wad"></a>

## Function `ray_to_wad`

@dev Casts ray down to wad
@param a Ray
@return b = a converted to wad, rounded half up to the nearest wad


<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_ray_to_wad">ray_to_wad</a>(a: u256): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_to_ray"></a>

## Function `wad_to_ray`

@dev Converts wad up to ray
@param a Wad
@return b = a converted in ray


<pre><code><b>public</b> <b>fun</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math_wad_to_ray">wad_to_ray</a>(a: u256): u256
</code></pre>
