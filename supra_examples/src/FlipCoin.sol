// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupraRouterContract {
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 flags) external returns(uint256);
}

contract FlipCoin {

    // Supra VRF Smart contracts
    address supraAddr;

    constructor(address supraSC) {
        supraAddr = supraSC;
    }

    mapping (uint256 => uint256 ) flipRecord;

    function flipCoin(uint8 rngCount) external {
        ISupraRouterContract(supraAddr).generateRequest("myCallback(uint256,uint256[])", rngCount,0);

    }

    function myCallback(uint256 nonce, uint256[] calldata rngList) external {
        require(rngList.length == 1, 'invalid result');
        flipRecord[nonce] = rngList[0];
    }

    function flipResult(uint256 _requestId) external view returns(bool) {
        require(flipRecord[_requestId] > 0, 'invalid request');
        return flipRecord[_requestId] % 2 == 0 ? true : false;
    }

}