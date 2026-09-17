// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMentoRouter {
  struct Route {
    address from;
    address to;
    address factory;
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    Route[] calldata routes,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}
