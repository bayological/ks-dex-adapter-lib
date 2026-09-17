// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './IMentoRouter.sol';

import '../../libraries/CalldataDecoder.sol';
import '../../libraries/TokenHelper.sol';

/// @title MentoV3Adapter
/// @notice KyberSwap DEX adapter for Mento V3 fixed-price market makers.
///         Swaps are executed through Mento's exact-input Router entry point.
/// @dev The Mento Router resolves the FPMM for a token pair through its
///      FactoryRegistry and supports a zero factory address for its default
///      factory. FPMM swaps consume the complete input amount.
contract MentoV3Adapter {
  using CalldataDecoder for bytes;
  using TokenHelper for address;

  /// @notice Execute a single-hop Mento V3 swap.
  /// @param data ABI-encoded: (address router, address factory, uint256 amountOutMin, uint256 deadline)
  /// @param amountIn Amount of tokenIn already held by this adapter
  /// @param tokenIn Input token address
  /// @param tokenOut Output token address
  /// @param recipient Recipient of the output tokens
  /// @return amountUnused Unused input amount; always zero for exact-input FPMM swaps
  /// @return amountOut Amount of tokenOut received according to the Router quote
  function executeMentoV3(
    bytes calldata data,
    uint256 amountIn,
    address tokenIn,
    address tokenOut,
    address recipient
  ) external payable returns (uint256 amountUnused, uint256 amountOut) {
    (address router, address factory, uint256 amountOutMin, uint256 deadline) = _decodeData(data);

    tokenIn.forceApprove(router, amountIn);

    IMentoRouter.Route[] memory routes = new IMentoRouter.Route[](1);
    routes[0] = IMentoRouter.Route({from: tokenIn, to: tokenOut, factory: factory});

    uint256[] memory amounts = IMentoRouter(router)
      .swapExactTokensForTokens(amountIn, amountOutMin, routes, recipient, deadline);

    amountUnused = 0;
    amountOut = amounts[amounts.length - 1];
  }

  function _decodeData(bytes calldata data)
    internal
    pure
    returns (address router, address factory, uint256 amountOutMin, uint256 deadline)
  {
    router = data.decodeAddress(0);
    factory = data.decodeAddress(1);
    amountOutMin = data.decodeUint256(2);
    deadline = data.decodeUint256(3);
  }
}
