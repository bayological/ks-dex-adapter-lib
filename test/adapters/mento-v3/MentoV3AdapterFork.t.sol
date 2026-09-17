// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'openzeppelin-contracts/contracts/interfaces/IERC20.sol';

import 'src/adapters/mento-v3/MentoV3Adapter.sol';

/// @notice Fork integration test for the deployed Mento V3 Router on Monad.
/// @dev Requires RPC_143 (the `monad_mainnet` alias in foundry.toml). Mento's oracle and
///      market-hours checks must be valid at the forked block for the swap to execute.
contract MentoV3AdapterForkTest is Test {
  MentoV3Adapter adapter;

  address constant ROUTER = 0x4861840C2EfB2b98312B0aE34d86fD73E8f9B6f6;
  address constant FACTORY = 0xa849b475FE5a4B5C9C3280152c7a1945b907613b;
  address constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
  address constant USDm = 0xBC69212B8E4d445b2307C9D32dD68E2A4Df00115;

  address recipient = makeAddr('recipient');

  function setUp() public {
    vm.createSelectFork('monad_mainnet');
    adapter = new MentoV3Adapter();
  }

  function test_executeMentoV3AgainstMonadDeployment() public {
    uint256 amountIn = 1_000_000; // 1 USDC (6 decimals)
    deal(USDC, address(adapter), amountIn);

    uint256 balanceBefore = IERC20(USDm).balanceOf(recipient);
    bytes memory data = abi.encode(ROUTER, FACTORY, 0, block.timestamp + 300);

    (uint256 amountUnused, uint256 amountOut) =
      adapter.executeMentoV3(data, amountIn, USDC, USDm, recipient);

    assertEq(amountUnused, 0);
    assertGt(amountOut, 0);
    assertEq(IERC20(USDm).balanceOf(recipient) - balanceBefore, amountOut);
    assertEq(IERC20(USDC).balanceOf(address(adapter)), 0);
  }
}
