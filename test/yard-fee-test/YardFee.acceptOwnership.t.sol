// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./YardFee.t.sol";

contract TransferOwnershipTest is YardFeeTest {
    function transferOwnership() internal {
        vm.prank(owner);
        yardFee.transferOwnership(newOwner);
    }

    function testAcceptOwnershipByNonPendingOwner() public {
        transferOwnership();

        vm.expectRevert();
        vm.prank(hacker);
        yardFee.acceptOwnership();
    }

    function testAcceptOwnershipByPendingOwner() public {
        transferOwnership();

        vm.prank(newOwner);
        yardFee.acceptOwnership();

        assertTrue(yardFee.owner() == newOwner);
    }
}