// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupraRouterContract {
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed) external returns(uint256);
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations) external returns(uint256);
}

contract BasicRNG {
    address supraAddr;
    constructor(address supraSC) {
        supraAddr = supraSC;
    }

    mapping (uint256 => string ) user;
    uint256[] _callbackResult;

    function getRNG(uint8 rngCount) external returns(uint256) {

        uint256 nonce =  ISupraRouterContract(supraAddr).generateRequest("myCallback(uint256,uint256[])", rngCount,0);
        return nonce;
    }


    function myCallback(uint256 nonce, uint256[] calldata rngList) external returns(uint256[] memory){

        uint8 i = 0;
        for(i=0; i<rngList.length; i++) {
            _callbackResult[i] = rngList[i];
        }

        return _callbackResult;

    }

    function getRNGForUser(uint8 rngCount, string memory username) external {

        uint256 nonce =  ISupraRouterContract(supraAddr).generateRequest("myCallbackUsername(uint256,uint256[])", rngCount,0);
        user[nonce] = username;

    }

    function myCallbackUsername(uint256 nonce, uint256[] calldata rngList) external returns(string memory, uint256[] memory){

        uint8 i = 0;
        for(i=0; i<rngList.length; i++) {
            _callbackResult[i] = rngList[i];
        }

        return (user[nonce], _callbackResult);
    }
}