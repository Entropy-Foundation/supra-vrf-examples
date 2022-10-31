// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

interface ISupraRouterContract {
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed) external returns(uint256);
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations) external returns(uint256);
}

contract DrawCard {

    // Supra VRF Smart contracts
    address supraAddr;

    constructor(address supraSC) {
        supraAddr = supraSC;
    }

    mapping (uint256 => mapping(uint256 => uint256) ) myCards;
    uint8 rngCount = 3;
    uint256 numConfirmations = 1;
    uint256 generated_card_nonce;

    function distribute() external {
        generated_card_nonce  = ISupraRouterContract(supraAddr).generateRequest("distribute(uint256,uint256[])", rngCount, numConfirmations);

        console.log("Cards distributed %s", generated_card_nonce);

    }

    function distribute(uint256 nonce, uint256[] calldata rngList) external {
        // require(rngList.length == 1, 'invalid result');
        console.log("execute callback function of nonce %s ", nonce );
        require(generated_card_nonce == nonce, "Invalid Nonce");

        for(uint8 i =0 ; i < rngCount; i++) {
            myCards[nonce][i] = rngList[i];
        }

    }

    function flipResult(uint256 _requestId) external view returns(uint256) {
        require(_requestId >= 0 && _requestId < rngCount, "Invalid request id");

        console.log("calculating position from result %s ", myCards[generated_card_nonce][_requestId]);

        uint256 cardPosition = myCards[generated_card_nonce][_requestId] % 2;

        console.log("CARD POSITION %s ", cardPosition);

        return cardPosition;
    }

}