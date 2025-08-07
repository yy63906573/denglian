// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test, console} from "@forge-std/Test.sol";
import {MyVestingWalletWithCliff} from "../src/MyVestingWalletWithCliff.sol";
import {MyToken} from "../src/MyToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingTest is Test {
    MyVestingWalletWithCliff public vesting;
    MyToken public token;

    // 受益人地址
    address public beneficiary = address(0xbef745E4b89216F50f20A77D057604f007C30E86);
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 10 ** 18; // 1亿 ERC20 代币作为总供应量
    uint256 public constant VESTING_AMOUNT = 1_000_000 * 10 ** 18; // 100万 ERC20 代币
    uint256 public constant CLIFF_DURATION = 12 * 30 days; // 12个月的悬崖期
    uint256 public constant VESTING_DURATION = 24 * 30 days; // 24个月的线性释放期
    uint256 public startTime;

    function setUp() public {
        // 在每个测试函数运行之前执行
        token = new MyToken("yangyang","yy",TOTAL_SUPPLY);
        startTime = block.timestamp;
        vesting = new MyVestingWalletWithCliff(beneficiary, uint64(startTime), uint64(CLIFF_DURATION+VESTING_DURATION), uint64(CLIFF_DURATION));

        // 部署者将 100 万代币转入 Vesting 合约
        token.approve(address(vesting), VESTING_AMOUNT);
        vesting.depositTokens(IERC20(address(token)), VESTING_AMOUNT);
    }

/** Cliff 悬崖其之前无法提币 */
    function testCliffPeriod() public {
        // 模拟时间流逝到悬崖期结束前
        vm.warp(startTime + CLIFF_DURATION - 1 days);
        
        // 验证受益人在悬崖期内无法提取任何代币
        uint256 amount = vesting.releasable(address(token));
        assertEq(amount, 0);
        

        // 尝试调用 release() 应该会失败或释放 0 个代币
        uint256 beneficiaryBalanceBefore = token.balanceOf(beneficiary);
        vesting.release(address(token));
        assertEq(token.balanceOf(beneficiary), beneficiaryBalanceBefore);
    }
    
    function testAfterCliff() public {
        // 模拟时间流逝到悬崖期结束
        vm.warp(startTime + CLIFF_DURATION);

        // 验证悬崖期结束后可提取的代币为 0（因为线性释放从此刻才开始）
        assertEq(vesting.releasable(address(token)), 0);

        // 模拟时间再流逝 1 个月
        vm.warp(startTime + CLIFF_DURATION + 30 days);

        // 检查一个月后可释放的代币数量
        uint256 expectedRelease;
        expectedRelease = VESTING_AMOUNT / uint256(VESTING_DURATION+VESTING_DURATION);
        expectedRelease = expectedRelease * CLIFF_DURATION + expectedRelease;
        expectedRelease = expectedRelease - vesting.released();
        // expectedRelease = VESTING_AMOUNT * (uint256(block.timestamp - vesting.start())) / vesting.duration();
        uint256 releasableToken = vesting.releasable(address(token));
        console.log("releasableToken:",releasableToken);
        console.log("expectedRelease:",expectedRelease);
        assertEq(releasableToken, expectedRelease);

        // 调用 release() 释放代币
        vesting.release(address(token));

        // 验证受益人收到了代币
        assertEq(token.balanceOf(beneficiary), expectedRelease);
        
        // 再次调用 release()，因为没有新的代币解锁，所以不应该有新的代币转出
        uint256 beneficiaryBalanceAfter = token.balanceOf(beneficiary);
        vesting.release(address(token));
        assertEq(token.balanceOf(beneficiary), beneficiaryBalanceAfter);
    }

    // function testFullVesting() public {
    //     // 模拟时间流逝到整个 Vesting 周期结束
    //     vm.warp(startTime + CLIFF_DURATION + VESTING_DURATION);

    //     // 验证所有代币都可释放
    //     assertEq(vesting.releasable(IERC20(address(token))), VESTING_AMOUNT);

    //     // 调用 release() 释放所有代币
    //     vesting.release(IERC20(address(token)));

    //     // 验证受益人收到了所有代币
    //     assertEq(token.balanceOf(beneficiary), VESTING_AMOUNT);
    // }
}