// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupraRouterContract {
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed) external returns(uint256);
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations) external returns(uint256);
}

contract LotteryContract {

    address public manager;
    address[] public players;
    address public winner;
    address supra = 0xe88cFbEBc6a453fbD340a7bd82611Ad01c1f77eA;
    ISupraRouterContract internal supraRouter;
    uint8 rngCount;

    constructor() {
        supraRouter = ISupraRouterContract(supra);
    }


    function createLottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .001 ether, "Value must be greater than .001 ether");
        players.push(msg.sender);
    }

    function requestRandomNumber(uint8 _rngCount) public {

        require(msg.sender == manager, "Caller is not the owner");
        rngCount = _rngCount;
        supraRouter.generateRequest("pickWinner(uint256, uint256[])", _rngCount, 1);
    }

    function pickWinner(uint256 _nonce, uint256[] memory _rngList) external {
        require(msg.sender == supra, "Caller is not allowed");
        if(rngCount == 1) {
            uint index = _rngList[0] % players.length;
            winner = players[index];
            payable (players[index]).transfer(address(this).balance);

        } else {
            for(uint8 i = 0; i < rngCount; i++) {
                uint index = _rngList[i] % players.length;
                winner = players[index];
                payable (players[index]).transfer(address(this).balance);

            }
        }
        players = new address[](0);
    }
}