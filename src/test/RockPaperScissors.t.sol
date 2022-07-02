// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {RockPaperScissors} from "../RockPaperScissors.sol";

contract RockPaperScissorsTest is Test {

    event Game(
        address player1,
        address player2,
        Move movePlayer1,
        Move movePlayer2,
        address winner
    );

    address internal immutable alice = address(1);
    address internal immutable bob = address(2);
    address internal immutable charlie = address(3);

    RockPaperScissors internal rps;

    enum Move {
        None,
        Rock,
        Paper,
        Scissor
    }

    uint256 internal moveAlice;
    uint256 internal moveBob;

    bytes32 internal hashAlice;
    bytes32 internal hashBob;

    string internal saltAlice;
    string internal saltBob;

    function setUp() public {
        rps = new RockPaperScissors();
        vm.deal(alice, 20 ether);
        vm.deal(bob, 20 ether);
    }

    function testNormalGame() public {
        vm.prank(alice);
        rps.register{value: 3 ether}();
        vm.prank(bob);
        rps.register{value: 3 ether}();

        moveAlice = uint256(Move.Scissor);
        moveBob = uint256(Move.Paper);

        saltAlice = "zdqzdqdoqhj5gy3j5gj";
        saltBob = "654qzdqd65qzdqzd6qz5d1";

        hashAlice = getHash(moveAlice, saltAlice);
        hashBob = getHash(moveBob, saltBob);

        vm.prank(alice);
        rps.play(hashAlice);
        vm.prank(bob);
        rps.play(hashBob);

        vm.prank(alice);
        rps.revealMove(moveAlice, saltAlice);

        vm.prank(bob);

        vm.expectEmit(true, true, true, true);
        emit Game(alice, bob, Move(moveAlice), Move(moveBob), alice);
        rps.revealMove(moveBob, saltBob);

    }

    function getHash(uint256 _move, string memory _salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_move, _salt));
    }
}
