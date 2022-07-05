// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import {RockPaperScissors} from '../RockPaperScissors.sol';

/*
contract PlayerContract {
    
    function goRegister(address addrContract) public returns (bool) {

        (bool status,) = payable(addrContract).call{value: 5 ether}(
            abi.encodeWithSignature("register()")
        );

        return status;
    }
}
*/

contract RockPaperScissorsTest is Test {
    event Game(
        address player1,
        address player2,
        Move movePlayer1,
        Move movePlayer2,
        address winner
    );

    uint256 intialBalance = 20 ether;

    address internal immutable owner = address(0);
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
        vm.prank(owner);
        rps = new RockPaperScissors();
        vm.deal(alice, intialBalance);
        vm.deal(bob, intialBalance);
    }

    function testNormalGame() public {
        vm.prank(alice);
        rps.register{value: 3 ether}();
        vm.prank(bob);
        rps.register{value: 3 ether}();

        moveAlice = uint256(Move.Scissor);
        moveBob = uint256(Move.Paper);

        saltAlice = 'zdqzdqdoqhj5gy3j5gj';
        saltBob = '654qzdqd65qzdqzd6qz5d1';

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

        assertEq(alice.balance, intialBalance + 3 ether);
        assertEq(bob.balance, intialBalance - 3 ether);

        assertEq(rps.isLive(), false);
        assertEq(rps.nbrPlayer(), 0);
        assertEq(rps.player1(), address(0));
        assertEq(rps.player2(), address(0));
        assertEq(uint256(rps.movePlayer1()), 0);
        assertEq(uint256(rps.movePlayer2()), 0);
    }

    function testTiedGame() public {
        vm.prank(alice);
        rps.register{value: 3 ether}();
        vm.prank(bob);
        rps.register{value: 3 ether}();

        moveAlice = uint256(Move.Scissor);
        moveBob = uint256(Move.Scissor);

        saltAlice = 'zdqzdqdoqhj5gy3j5gj';
        saltBob = '654qzdqd65qzdqzd6qz5d1';

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
        emit Game(alice, bob, Move(moveAlice), Move(moveBob), address(0));
        rps.revealMove(moveBob, saltBob);

        assertEq(alice.balance, intialBalance);
        assertEq(bob.balance, intialBalance);

        assertEq(rps.isLive(), false);
        assertEq(rps.nbrPlayer(), 0);
        assertEq(rps.player1(), address(0));
        assertEq(rps.player2(), address(0));
        assertEq(uint256(rps.movePlayer1()), 0);
        assertEq(uint256(rps.movePlayer2()), 0);
    }

    // Test of the register function

    function testThreePlayer() public {
        vm.deal(charlie, intialBalance);

        vm.prank(alice);
        rps.register{value: 3 ether}();
        vm.prank(bob);
        rps.register{value: 3 ether}();
        vm.prank(charlie);

        vm.expectRevert('FULL_GAME');
        rps.register{value: 3 ether}();
    }

    function testSamePlayer() public {
        vm.startPrank(alice);
        rps.register{value: 3 ether}();

        vm.expectRevert('INVALID_PLAYER (only another address)');
        rps.register{value: 3 ether}();
        vm.stopPrank();
    }

    function testInsufficientBet() public {
        uint256 initialBet = 3 ether;
        vm.prank(alice);
        rps.register{value: initialBet}();
        vm.prank(bob);

        vm.expectRevert(
            abi.encodeWithSelector(RockPaperScissors.InsufficientBet.selector, initialBet)
        );

        rps.register{value: 1 ether}();
    }

    /*function testContractPlayer() public {
        PlayerContract player = new PlayerContract();
        vm.deal(address(player), intialBalance);

        bool status = player.goRegister(address(rps));

        assertEq(rps.nbrPlayer(), 1);
        assertTrue(status, "allo why");
    }*/

    // Test of the play function

    function testEmptyChoice() public {
        registerTwoPlayer();
        vm.prank(alice);

        vm.expectRevert('ILLEGAL_MOVE');
        rps.play(0);
    }

    function testNotFullyGame() public {
        vm.startPrank(alice);
        rps.register{value: 3 ether}();

        vm.expectRevert('NO_FULL_GAME');
        rps.play('hello you');

        vm.stopPrank();
    }

    function testEndPlayPhase() public {
        registerTwoPlayer();

        vm.prank(alice);
        rps.play('f61656511551561615165');
        vm.startPrank(bob);
        rps.play('9843169848651164991');

        vm.expectRevert('END_PLAY_PHRASE');
        rps.play('656546465ae4a65e64ea645e');
        vm.stopPrank();
    }

    // Test of the revealMove function

    function testIllegalMove() public {
        registerTwoPlayer();

        vm.prank(alice);
        vm.expectRevert('ILLEGAL_REVEAL_MOVE');
        rps.revealMove(5, 'qzdqzdqzzq');
    }

    function testInvalidReveal() public {
        registerTwoPlayer();
        playTwoPlayer();

        vm.prank(alice);
        vm.expectRevert('INVALID_REVEAL');
        rps.revealMove(uint256(Move.Scissor), 'hello');
    }

    function testWaitPlayPhase() public {
        registerTwoPlayer();
        vm.startPrank(alice);
        rps.play('65654645ae4a65e64ea645e');

        vm.expectRevert('WAIT_REVEAL_PHASE');
        rps.revealMove(2, 'dqzdd');
        vm.stopPrank();
    }

    // Test fo withdraw function

    function testWithdrawOwnerGameLive() public {
        vm.deal(address(rps), intialBalance);
        registerTwoPlayer();

        vm.expectRevert('GAME_LIVE');
        vm.prank(address(0));
        rps.withdrawOwner(10 ether);
    }

    function testWithdrawOwnerNotOwner() public {
        vm.deal(address(rps), intialBalance);

        vm.expectRevert('ONLY_OWNER');
        vm.prank(alice);
        rps.withdrawOwner(10 ether);
    }

    function testWIthdrawOwnerSucess() public {
        vm.deal(address(rps), intialBalance);
        vm.prank(address(0));
        rps.withdrawOwner(10 ether);
    }

    function testWIthdrawOwnerAvid() public {
        vm.deal(address(rps), intialBalance);
        vm.prank(address(0));
        vm.expectRevert('INVALID_TRANSFER (withdrawOwner)');
        rps.withdrawOwner(30 ether);
    }

    // Test fo withdraw function

    function testwithdrawEmergencySuccess() public {
        registerTwoPlayer();

        vm.startPrank(alice);
        rps.play('65654645ae4a65e64ea645e');

        vm.warp(block.timestamp + 20 minutes);
        rps.withdrawEmergency();

        assertEq(alice.balance, intialBalance);
        assertEq(bob.balance, intialBalance);

        vm.stopPrank();
    }

    function withdrawEmergencyLive() public {
        vm.expectRevert('GAME_NOT_LIVE');
        vm.prank(alice);
        rps.withdrawEmergency();
    }

    // Helper functions

    function registerTwoPlayer() internal {
        vm.prank(alice);
        rps.register{value: 3 ether}();
        vm.prank(bob);
        rps.register{value: 3 ether}();
    }

    function playTwoPlayer() internal {
        moveAlice = uint256(Move.Scissor);
        moveBob = uint256(Move.Paper);

        saltAlice = 'zdqzdqdoqhj5gy3j5gj';
        saltBob = '654qzdqd65qzdqzd6qz5d1';

        hashAlice = getHash(moveAlice, saltAlice);
        hashBob = getHash(moveBob, saltBob);

        vm.prank(alice);
        rps.play(hashAlice);
        vm.prank(bob);
        rps.play(hashBob);
    }

    function getHash(uint256 _move, string memory _salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_move, _salt));
    }
}
