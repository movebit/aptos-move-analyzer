
<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils"></a>

# Module `0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::math_utils`



-  [Constants](#@Constants_0)
-  [Function `u256_max`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_u256_max)
-  [Function `calculate_linear_interest`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_linear_interest)
-  [Function `calculate_compounded_interest`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_compounded_interest)
-  [Function `calculate_compounded_interest_now`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_compounded_interest_now)
-  [Function `get_percentage_factor`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_get_percentage_factor)
-  [Function `percent_mul`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_percent_mul)
-  [Function `percent_div`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_percent_div)
-  [Function `pow`](#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_pow)


<pre><code><b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="wad_ray_math.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_wad_ray_math">0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c::wad_ray_math</a>;
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_EDIVISION_BY_ZERO"></a>

Cannot divide by zero


<pre><code><b>const</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_EDIVISION_BY_ZERO">EDIVISION_BY_ZERO</a>: u64 = 2;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_EOVERFLOW"></a>

Calculation results in overflow


<pre><code><b>const</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_EOVERFLOW">EOVERFLOW</a>: u64 = 1;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_U256_MAX"></a>



<pre><code><b>const</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_U256_MAX">U256_MAX</a>: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_HALF_PERCENTAGE_FACTOR"></a>

Half percentage factor (50.00%)


<pre><code><b>const</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_HALF_PERCENTAGE_FACTOR">HALF_PERCENTAGE_FACTOR</a>: u256 = 5000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_PERCENTAGE_FACTOR"></a>

Maximum percentage factor (100.00%)


<pre><code><b>const</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_PERCENTAGE_FACTOR">PERCENTAGE_FACTOR</a>: u256 = 10000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_SECONDS_PER_YEAR"></a>

@dev Ignoring leap years


<pre><code><b>const</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_SECONDS_PER_YEAR">SECONDS_PER_YEAR</a>: u256 = 31536000;
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_u256_max"></a>

## Function `u256_max`



<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_u256_max">u256_max</a>(): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_linear_interest"></a>

## Function `calculate_linear_interest`

@dev Function to calculate the interest accumulated using a linear interest rate formula
@param rate The interest rate, in ray
@param last_update_timestamp The timestamp of the last update of the interest
@return The interest rate linearly accumulated during the timeDelta, in ray


<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_linear_interest">calculate_linear_interest</a>(rate: u256, last_update_timestamp: u64): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_compounded_interest"></a>

## Function `calculate_compounded_interest`

@dev Function to calculate the interest using a compounded interest rate formula
To avoid expensive exponentiation, the calculation is performed using a binomial approximation:

(1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...

The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
error per different time periods

@param rate The interest rate, in ray
@param last_update_timestamp The timestamp of the last update of the interest
@return The interest rate compounded during the timeDelta, in ray


<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_compounded_interest">calculate_compounded_interest</a>(rate: u256, last_update_timestamp: u64, current_timestamp: u64): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_compounded_interest_now"></a>

## Function `calculate_compounded_interest_now`

@dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
@param rate The interest rate (in ray)
@param last_update_timestamp The timestamp from which the interest accumulation needs to be calculated
@return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray


<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_calculate_compounded_interest_now">calculate_compounded_interest_now</a>(rate: u256, last_update_timestamp: u64): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_get_percentage_factor"></a>

## Function `get_percentage_factor`



<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_get_percentage_factor">get_percentage_factor</a>(): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_percent_mul"></a>

## Function `percent_mul`

@notice Executes a percentage multiplication
@param value The value of which the percentage needs to be calculated
@param percentage The percentage of the value to be calculated
@return result value percentmul percentage


<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_percent_mul">percent_mul</a>(value: u256, percentage: u256): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_percent_div"></a>

## Function `percent_div`

@notice Executes a percentage division
@param value The value of which the percentage needs to be calculated
@param percentage The percentage of the value to be calculated
@return result value percentdiv percentage


<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_percent_div">percent_div</a>(value: u256, percentage: u256): u256
</code></pre>



<a id="0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_pow"></a>

## Function `pow`



<pre><code><b>public</b> <b>fun</b> <a href="math_utils.md#0x9efefdec8fe22b7447931b81745048182594ef72653dfbf8e05b815ecc355f7c_math_utils_pow">pow</a>(base: u256, exponent: u256): u256
</code></pre>
