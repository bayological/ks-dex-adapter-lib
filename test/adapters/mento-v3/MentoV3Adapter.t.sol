// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'src/adapters/mento-v3/IMentoRouter.sol';
import 'src/adapters/mento-v3/MentoV3Adapter.sol';

contract MentoV3TestToken is ERC20 {
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }
}

contract MentoV3MockRouter is IMentoRouter {
  uint256 public outputNumerator;
  uint256 public outputDenominator;
  uint256 public lastAmountIn;
  uint256 public lastAmountOutMin;
  uint256 public lastDeadline;
  address public lastRecipient;
  address public lastFactory;
  address public lastFrom;
  address public lastTo;

  constructor(uint256 outputNumerator_, uint256 outputDenominator_) {
    outputNumerator = outputNumerator_;
    outputDenominator = outputDenominator_;
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    Route[] calldata routes,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts) {
    lastAmountIn = amountIn;
    lastAmountOutMin = amountOutMin;
    lastDeadline = deadline;
    lastRecipient = to;
    lastFactory = routes[0].factory;
    lastFrom = routes[0].from;
    lastTo = routes[0].to;

    IERC20(routes[0].from).transferFrom(msg.sender, address(this), amountIn);
    uint256 amountOut = (amountIn * outputNumerator) / outputDenominator;
    IERC20(routes[0].to).transfer(to, amountOut);

    amounts = new uint256[](2);
    amounts[0] = amountIn;
    amounts[1] = amountOut;
  }
}

contract MentoV3AdapterTest is Test {
  MentoV3Adapter adapter;
  MentoV3MockRouter router;
  MentoV3TestToken tokenIn;
  MentoV3TestToken tokenOut;

  address recipient = makeAddr('recipient');
  address factory = makeAddr('factory');

  function setUp() public {
    adapter = new MentoV3Adapter();
    router = new MentoV3MockRouter(997, 1000);
    tokenIn = new MentoV3TestToken('Input', 'IN');
    tokenOut = new MentoV3TestToken('Output', 'OUT');
    tokenOut.mint(address(router), 1_000_000 ether);
  }

  function test_executeMentoV3() public {
    uint256 amountIn = 10 ether;
    uint256 amountOutMin = 9 ether;
    uint256 deadline = 1_700_000_000;
    tokenIn.mint(address(adapter), amountIn);

    bytes memory data = abi.encode(address(router), factory, amountOutMin, deadline);
    (uint256 amountUnused, uint256 amountOut) =
      adapter.executeMentoV3(data, amountIn, address(tokenIn), address(tokenOut), recipient);

    assertEq(amountUnused, 0);
    assertEq(amountOut, 9.97 ether);
    assertEq(tokenOut.balanceOf(recipient), amountOut);
    assertEq(tokenIn.balanceOf(address(adapter)), 0);
    assertEq(router.lastAmountIn(), amountIn);
    assertEq(router.lastAmountOutMin(), amountOutMin);
    assertEq(router.lastDeadline(), deadline);
    assertEq(router.lastRecipient(), recipient);
    assertEq(router.lastFactory(), factory);
    assertEq(router.lastFrom(), address(tokenIn));
    assertEq(router.lastTo(), address(tokenOut));
  }

  function test_executeMentoV3UsesDefaultFactory() public {
    uint256 amountIn = 1 ether;
    tokenIn.mint(address(adapter), amountIn);

    bytes memory data = abi.encode(address(router), address(0), 0, block.timestamp + 300);
    adapter.executeMentoV3(data, amountIn, address(tokenIn), address(tokenOut), recipient);

    assertEq(router.lastFactory(), address(0));
  }
}
