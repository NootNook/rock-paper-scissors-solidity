// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract RockPaperScissors {

    error InsufficientBet(uint256 amountMin);

    event Game(
        address player1,
        address player2,
        Move movePlayer1,
        Move movePlayer2,
        address winner
    );

    address public owner;

    address public player1;
    address public player2;
    uint256 public nbrPlayer = 0;

    uint256 public intialBet;

    uint256 private startGame;
    uint256 private delayGame = 10 minutes;

    mapping(address => uint256) private _balances;
    bytes32 private hashMovePlayer1;
    bytes32 private hashMovePlayer2;

    bool public isLive;

    enum Move {
        None,
        Rock,
        Paper,
        Scissor
    }

    Move public movePlayer1;
    Move public movePlayer2;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier onlyPlayer() {
        require(
            msg.sender == player1 || msg.sender == player2,
            "ONLY_PLAYER"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function register() external payable {
        require(nbrPlayer < 2, "FULL_GAME");
        require(msg.sender != player1, "INVALID_PLAYER (only another address)");
        //require(tx.origin == msg.sender, "ILLEGAL_CALLER (you're contract)");
        if(nbrPlayer == 1 && msg.value < _balances[player1])
            revert InsufficientBet(_balances[player1]);

        isLive = true;

        unchecked {
            nbrPlayer++;
        }

        if (nbrPlayer == 1) {
            player1 = msg.sender;
            startGame = block.timestamp;
            intialBet = msg.value;
        } else player2 = msg.sender;

        _balances[msg.sender] = msg.value;
    }

    function play(bytes32 hashMove) external onlyPlayer {
        require(hashMove != 0, "ILLEGAL_MOVE");
        require(nbrPlayer == 2, "NO_FULL_GAME");
        require(
            hashMovePlayer1 == 0 || hashMovePlayer2 == 0,
            "END_PLAY_PHRASE"
        );

        if (msg.sender == player1) hashMovePlayer1 = hashMove;
        else hashMovePlayer2 = hashMove;
    }

    function revealMove(uint256 _move, string calldata _salt)
        external
        onlyPlayer
    {
        // Test with the lower and upper operation-> gas saving ?
        require(_move == 1 || _move == 2 || _move == 3, "ILLEGAL_REVEAL_MOVE");
        require(
            hashMovePlayer1 != 0 && hashMovePlayer2 != 0,
            "WAIT_REVEAL_PHASE"
        );

        bool isPlayer1 = msg.sender == player1; //gas saving ?
        bytes32 hashReveal = getHashMove(_move, _salt);
        bytes32 hashPlay = isPlayer1 ? hashMovePlayer1 : hashMovePlayer2;
        require(hashReveal == hashPlay, "INVALID_REVEAL");

        if (isPlayer1) movePlayer1 = Move(_move);
        else movePlayer2 = Move(_move);

        if (movePlayer1 != Move.None && movePlayer2 != Move.None) {
            address winner = revealWinner();
            address _player1 = player1;
            address _player2 = player2;
            emit Game(player1, player2, movePlayer1, movePlayer2, winner);
            resetGame();
            distributionProfits(_player1, _player2, winner);
            isLive = false;
        }
    }

    function distributionProfits(
        address _player1,
        address _player2,
        address _winner
    ) internal {
        uint256 amountPlayer1 = _balances[_player1];
        uint256 amountPlayer2 = _balances[_player2];
        uint256 amountWinner;
        unchecked {
            amountWinner = amountPlayer1 + amountPlayer2;
        }

        _balances[_player1] = 0;
        _balances[_player2] = 0;

        bool success;

        if (_winner == address(0)) {
            (success, ) = payable(_player1).call{value: amountPlayer1}("");
            require(success, "Invalid transfer withdraw");

            (success, ) = payable(_player2).call{value: amountPlayer2}("");
            require(success, "Invalid transfer withdraw");
        } else {
            (success, ) = payable(_winner).call{value: amountWinner}("");
            require(success, "Invalid transfer withdraw");
        }
    }

    function withdrawEmergency() external onlyPlayer {
        require(isLive);
        require(block.timestamp > startGame + delayGame);
        uint256 amount = _balances[msg.sender];
        _balances[msg.sender] = 0;

        bool success;
        address otherPlayer = (msg.sender == player1) ? player2 : address(0);

        resetGame();

        (success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Invalid transfer withdraw");

        if (otherPlayer == address(0)) return;

        amount = _balances[otherPlayer];
        _balances[otherPlayer] = 0;

        (success, ) = payable(otherPlayer).call{value: amount}("");
        require(success, "Invalid transfer withdraw");
    }

    function withdrawOwner(uint256 _amount) external onlyOwner {
        require(!isLive);

        (bool success, ) = payable(owner).call{value: _amount}("");

        require(success, "Invalid transfer withdraw");
    }

    // Internal functions

    function getHashMove(uint256 _move, string calldata _salt)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_move, _salt));
    }

    function revealWinner() internal view returns (address) {
        if (movePlayer1 == Move.Rock) {
            if (movePlayer2 == Move.Rock) return address(0);
            else if (movePlayer2 == Move.Paper) return player2;
            else return player1;
        } else if (movePlayer1 == Move.Paper) {
            if (movePlayer2 == Move.Rock) return player1;
            else if (movePlayer2 == Move.Paper) return address(0);
            else return player2;
        } else {
            if (movePlayer2 == Move.Rock) return player2;
            else if (movePlayer2 == Move.Paper) return player1;
            else return address(0);
        }
    }

    function resetGame() internal {
        player1 = address(0);
        player2 = address(0);

        hashMovePlayer1 = 0;
        hashMovePlayer2 = 0;

        movePlayer1 = Move.None;
        movePlayer2 = Move.None;

        startGame = 0;
        intialBet = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
