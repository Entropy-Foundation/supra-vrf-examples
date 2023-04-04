// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupraRouter {
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed) external returns(uint256);
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations) external returns(uint256);
}

contract Interaction {
    address supraAddr;
    constructor(address supraSC) {
        supraAddr = supraSC;
    }

    mapping (uint256 => string ) result;
    mapping (string => uint256[] ) rngForUser;

    function getRNGForUser(uint8 rngCount, string memory username) external {
        uint256 nonce =  ISupraRouter(supraAddr).generateRequest("myCallbackUsername(uint256,uint256[])", rngCount, 1, 123);
        result[nonce] = username;
    }

    function myCallbackUsername(uint256 nonce, uint256[] calldata rngList) external {
        require(msg.sender == supraAddr, "only supra router can call this function");
        uint8 i = 0;
        uint256[] memory x = new uint256[](rngList.length);
        rngForUser[result[nonce]] = x;
        for(i=0; i<rngList.length;i++){
            rngForUser[result[nonce]][i] = rngList[i] % 100;
        }
    }

    function viewUserName(string memory username) external view returns (uint256[] memory) {
        return rngForUser[username];
    }
}