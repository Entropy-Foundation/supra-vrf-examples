// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface ISupraRouterContract {
    function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) external returns(uint256);
    function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external returns(uint256);
}
contract PlayingCards {
    // Supra VRF Smart contracts
    address supraAddr;
    mapping (uint256 => uint256[]) private myCard;
    uint256 public joker;
    uint256 public teen_patti_1;
    uint256 public teen_patti_2;
    uint256 public teen_patti_3;
    uint256 public lucky;
    address public clientWalletAddress;

    constructor(address supraSC) {
        supraAddr = supraSC;
        clientWalletAddress = msg.sender;
    }
    function findJoker() external {
        joker = fetchRandomNumber(1, 1);
    }
    function teenPatti() external {
        teen_patti_1 = fetchRandomNumber(1, 2);
        teen_patti_2 = fetchRandomNumber(1, 3);
        teen_patti_3 = fetchRandomNumber(1, 1);
    }
    function guessCards() external {
        lucky = fetchRandomNumberWithSeeds(1, 1, 256);
    }
    function fetchRandomNumber(uint8 _randomNumberSize, uint256 _numberOfConfirmation) internal returns(uint256){
        uint256 request = ISupraRouterContract(supraAddr).generateRequest("distribute(uint256,uint256[])", _randomNumberSize, _numberOfConfirmation, clientWalletAddress);
        return request;
    }
    function fetchRandomNumberWithSeeds(uint8 _randomNumberSize, uint256 _numberOfConfirmation, uint256 _clientSeeds) internal returns(uint256){
        uint256 request =  ISupraRouterContract(supraAddr).generateRequest("distribute(uint256,uint256[])", _randomNumberSize, _numberOfConfirmation, _clientSeeds, clientWalletAddress);
        return request;
    }
    function distribute(uint256 request, uint256[] memory rngList) external {
        myCard[request] = rngList;
    }
    function requestList(uint256 _requestId) external view returns(uint256[] memory) {
        return myCard[_requestId];
    }

    // Request <-> Index
    function requestResult(uint256 _requestId, uint256 index) external view returns(uint256) {
        uint256 _result = myCard[_requestId][index];
        return _result;
    }
}
