// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../Contract.sol";
import "./mocks/MockVRFCoordinatorV2.sol";
import "./mocks/LinkToken.sol";
import "./utils/Cheats.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract ContractTest is DSTest, ERC721Holder {
    TLCNFT public c;
    LinkToken public linkToken;
    MockVRFCoordinatorV2 public vrfCoordinator;
    Cheats internal constant cheats = Cheats(HEVM_ADDRESS);

    uint96 constant FUND_AMOUNT = 1 * 10**18;
    // Initialized as blank, fine for testing
    uint64 subId;
    bytes32 keyHash; // gasLane

    event ReturnedRandomness(uint256[] randomWords);

    function setUp() public {
        linkToken = new LinkToken();
        vrfCoordinator = new MockVRFCoordinatorV2();
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);
        c = new TLCNFT(
            subId,
            address(vrfCoordinator),
            address(linkToken),
            keyHash
        );
        vrfCoordinator.addConsumer(subId, address(c));
        c.mintNFT(address(this));
    }

    function testSetup() public {}

    function testCanGetRandomResponse() public {
        c.claimYourSpot();
        uint256 requestId = c.s_requestId();

        uint256[] memory words = getWords(requestId);

        vrfCoordinator.fulfillRandomWords(requestId, address(c));
        assertTrue(c.s_randomWords(0) == words[0]);
        assertTrue(c.s_randomWords(1) == words[1]);
    }

    function getWords(uint256 requestId)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory words = new uint256[](c.numWords());
        for (uint256 i = 0; i < c.numWords(); i++) {
            words[i] = uint256(keccak256(abi.encode(requestId, i)));
        }
        return words;
    }

    function testClaim() public {
        c.claimYourSpot();
        uint256 requestId = c.s_requestId();
        uint256 totalValues = c.totalValues();
        vrfCoordinator.fulfillRandomWords(requestId, address(c));
        assertTrue(c.totalValues() == totalValues + 1);
    }

    function testMulitClaim() public {
        c.claimYourSpot();
        uint256 requestId = c.s_requestId();
        uint256 totalValues = c.totalValues();
        vrfCoordinator.fulfillRandomWords(requestId, address(c));
        assertTrue(c.totalValues() == totalValues + 1);
        c.claimYourSpot();
        requestId = c.s_requestId();
        totalValues = c.totalValues();
        vrfCoordinator.fulfillRandomWords(requestId, address(c));
        assertTrue(c.totalValues() == totalValues + 1);
        c.claimYourSpot();
        requestId = c.s_requestId();
        totalValues = c.totalValues();
        vrfCoordinator.fulfillRandomWords(requestId, address(c));
        assertTrue(c.totalValues() == totalValues + 1);
    }

    function testURI() public {
        string memory uri = c.tokenURI(0);
        c.claimYourSpot();
        uint256 requestId = c.s_requestId();
        vrfCoordinator.fulfillRandomWords(requestId, address(c));
        assertTrue(
            keccak256(abi.encodePacked(uri)) !=
                keccak256(abi.encodePacked(c.tokenURI(0)))
        );
    }
}
